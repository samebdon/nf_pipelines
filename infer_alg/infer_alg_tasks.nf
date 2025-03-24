process get_taxon_info{

        input:
        tuple val(meta), val(taxid)

        output:
        tuple val(meta), path("${taxid}.taxonomy.tsv")

        script:
        """
        get_taxon_info.sh ${taxid}
        """
}

process collate_taxon_info{
        publishDir params.outdir, mode:'copy'

        input:
        val(meta)
        path(collected_taxonomy_tsvs, stageAs: "tsvs/*")

        output:
        path("${meta}.taxonomy_info.tsv")

        script:
        """
        cat tsvs/* > ${meta}.taxonomy_info.tsv
        """
}
process download_genomes{
        publishDir params.outdir, mode:'copy'

        input:
        val(meta)
        val(accessions_file)

        output:
        tuple val(meta), path("${meta}_genomes/*")

        script:
        """
        mkdir ${meta}_genomes
        mkdir ncbi
        datasets download genome accession --dehydrated --inputfile ${accessions_file}
        unzip ncbi_dataset.zip
        mv ncbi_dataset ncbi
        datasets rehydrate --directory ncbi
        mv ncbi/ncbi_dataset/data/*/* ${meta}_genomes
        """
}

process get_chromosome_names{
        publishDir params.outdir, mode:'copy'

        input:
        val(meta)
        val(accessions_file)

        output:
        tuple val(meta), path("${meta}_chromosome_files/*")

        script:
        """
        mkdir ${meta}_chromosome_files
        mkdir sequence_jsons

        parallel -j1 'datasets summary genome --report sequence  --assembly-level chromosome accession {} > sequence_jsons/{}.json' :::: ${accessions_file}
        parallel -j1 'parse_json.py sequence_jsons/{}.json > ${meta}_chromosome_files/{}.chromosomes.txt' :::: ${accessions_file}
        """
}

process busco{
        cpus 8
        memory '16G'

        input:
        tuple val(meta), path(genome)
        val(busco_db)
        path(busco_download_path)

        output:
        tuple val(meta), path("busco_results/${meta}")

        script:
        """
        busco -i ${genome} -m genome -l ${busco_db} -c ${task.cpus} -f -o busco_results/${meta} --download_path ${busco_download_path} --metaeuk --offline
        """
}

process busco2fasta{
        cpus 20
        memory '16G'

        input:
        val(meta)
        path(busco_results, stageAs: "busco_dirs/*")

        output:
        tuple val(meta), path("busco2fasta_results/*")

        script:
        """
        busco2fasta.py -b busco_dirs -o busco2fasta_results -s protein -p 0.9
        """
}

process mafft{
        cpus 12
        memory '10G'

        input:
        tuple val(meta), path(fastas, stageAs: "*")

        output:
        tuple val(meta), path("output_fastas/*")

        script:
        """
        mkdir output_fastas
        parallel -j${task.cpus} 'mafft --maxiterate 1000 --localpair {} > output_fastas/{.}.aligned.faa' ::: *.faa
        """
}

process trimal{
        cpus 10
        memory '5G'

        input:
        tuple val(meta), path(fastas, stageAs: "*")

        output:
        tuple val(meta), path("output_fastas/*")

        script:
        """
        mkdir output_fastas
        parallel -j${task.cpus} 'trimal -in {} -gt 0.8 -st 0.001 -resoverlap 0.75 -seqoverlap 80 -out output_fastas/{.}.trimmed.faa' ::: *.faa
        """
}

// this needs to write new files
process trimal_array_clean{
        cpus 8
        memory '3G'

        input:
        tuple val(meta), path(fastas, stageAs: "trimal/*")

        output:
        tuple val(meta), path("trimal_cleaned/*")

        script:
        """
        mkdir trimal_cleaned
        trimal_array_clean.py
        """
}

process catfasta2phyml{
        cpus 16
        memory '10G'

        input:
        tuple val(meta), path(fastas, stageAs: "*")

        output:
        tuple val(meta), path("${meta}.supermatrix.phy"), emit: supermatrix
        tuple val(meta), path("${meta}.partitions.txt"), emit: partitions

        script:
        """
        catfasta2phyml.pl *.faa -c > ${meta}.supermatrix.phy 2> ${meta}.partitions.txt
        """
}

process iqtree{
        cpus 64
        memory '64G'

        input:
        tuple val(meta), path(alignment)
        //val{iqtree_model}
        //val{iqtree_outgroup}

        output:
        tuple val(meta), path("*treefile")

        script:
        """
        iqtree -s ${alignment} -m Q.insect+I+G4 -T ${task.cpus} -B 1000 -o qeLepCurv1
        """
}

process prepare_busco_tables{
        input:
        tuple val(meta), path(busco_dir), path(chromosome_file)

        output:
        tuple val(meta), path("${meta}.syngraph.buscos.tsv")

        script:
        """
        cut -f 1,3,4,5 ${busco_dir}/run_*/full_table.tsv | sed '/^#/d' | awk '\$2 != ""' > ${meta}.busco.reformatted.tsv
        grep -f ${chromosome_file} ${meta}.busco.reformatted.tsv > ${meta}.syngraph.buscos.tsv 
        """
}

process syngraph_build{
        input:
        tuple val(meta), path(input_dir)

        output:
        tuple val(meta), path("syngraph_build_results")

        script:
        """
        syngraph build -d ${input_dir} -m -o syngraph_build_results
        """
}

process syngraph_infer{
        input:
        tuple val(meta), path(input_dir)

        output:
        tuple val(meta), path("syngraph_infer_results")

        script:
        """
        MARKER=\$(sed -n -e ${LSB_JOBINDEX}p scripts/script_cec_syngraph_infer.txt)

        # Run the Python script for each combination of REARRANGEMENTS and METHOD
        for REARRANGEMENTS in 2 3; do
            for METHOD in quick slow; do
                python3 ../../../../../../../software/team301/user/am75/miniconda3/lib/python3.12/site-packages/syngraph/syngraph infer \
                -g 03_syngraph/output/one_lepi2.pickle \
                -t 03_syngraph/input/trees/supermatrix.phy.one_lepi2 \
                -m ${MARKER} \
                -r ${REARRANGEMENTS} \
                -a ${METHOD} \
                -s GCA_963678705 \
                -o 03_syngraph/output/one_lepi2/r${REARRANGEMENTS}.${METHOD}/syngraph.infer.m${MARKER}.${REARRANGEMENTS}.${METHOD}
            done
        done
        """
}

process summarise_clusters{
        input:

        output:

        script:
        """
        echo NA
        """
}
