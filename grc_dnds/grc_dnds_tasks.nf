process filterIncompleteGeneModelsAGAT{
        publishDir params.outdir, mode:'copy'
        memory '4G'

        input:
        tuple val(meta), path(gff), path(genome)

        output:
        tuple val(meta), path("${meta}.agat.complete_genes.gff3")

        script:
        """
        agat_sp_filter_incomplete_gene_coding_models.pl -gff ${gff} --fasta ${genome} -o ${meta}.agat.complete_genes.gff3
        """
}

process getLongestIsoformAGAT{
        publishDir params.outdir, mode:'copy'
        memory '4G'

        input:
        tuple val(meta), path(gff)

        output:
        tuple val(meta), path("${meta}.agat.longest_isoform.gff3")

        script:
        """
        agat_sp_keep_longest_isoform.pl -gff ${gff} -o ${meta}.agat.longest_isoform.gff3
        """
}

process select_proteins{
        publishDir params.outdir, mode:'copy'
        memory '4G'

        input:
        tuple val(meta), path(gff), path(prot_fa)

        output:
        tuple val(meta), path("${meta}.selected_proteins.fa")

        script:
        """
        select_proteins.sh ${gff} ${prot_fa} > ${meta}.selected_proteins.fa 
        """

}

process selectProteinsAGAT{
        publishDir params.outdir, mode:'copy'
        memory '4G'

        input:
        tuple val(meta), path(gff), path(genome)

        output:
        tuple val(meta), path("${meta}.selected_proteins.fa")

        script:
        """
        agat_sp_extract_sequences.pl -g ${gff} -f ${genome} -t cds -p -o ${meta}.selected_proteins.fa
        """
}

process selectCDSsAGAT{
        publishDir params.outdir, mode:'copy'
        memory '4G'

        input:
        tuple val(meta), path(gff), path(genome)

        output:
        tuple val(meta), path("${meta}.selected_CDSs.fa")

        script:
        """
        agat_sp_extract_sequences.pl -g ${gff} -f ${genome} -t cds -o ${meta}.selected_CDSs.fa
        """
}

process orthofinder {
        publishDir params.outdir, mode:'copy'
        cpus 16
        memory '64G'

        input:
        tuple val(meta_list), path(prot_fastas, stageAs: "fastas/*")

        output:
        path("orthofinder_results/*"), emit: all
        path("orthofinder_results/*/Orthogroups/Orthogroups.GeneCount.tsv"), emit: gene_count
        path("orthofinder_results/*/MultipleSequenceAlignments/*"), emit: msa

        script:
        """
        orthofinder -f fastas -t ${task.cpus} -a ${task.cpus} -o orthofinder_results -M msa
        """
}

// Here Fede runs analyse_alignments_V2.R and filters OGs differently
// Also looks at quality but doesnt filter on quality

process select_orthogroups{
        publishDir params.outdir, mode:'copy'

        input:
        path(gene_counts)

        output:
        path('*.SCOs.txt')

        script:
        """
        select_orthogroups.py ${gene_counts}
        """
}

process select_msa{
        publishDir params.outdir, mode:'copy'

        input:
        tuple val(meta), path(orthoset)
        path(msas, stageAs: "alignments/*")

        output:
        tuple val(meta), path("selected_alignments/*")

        script:
        """
        mkdir selected_alignments
        parallel -j1 'mv alignments/{}.fa selected_alignments/{}.fa' :::: ${orthoset}
        """
}

// Assuming the topology of these trees will be the same as the IQ trees?
process concat_orthogroup_topologies{

        input:
        path(gene_trees, stageAs: "gene_trees/*")

        output:
        path('OG_topologies.txt')

        script:
        """
        gawk 'BEGINFILE{printf("%s\t",FILENAME)}1' *.txt | sed 's/_tree.txt//g' > OG_topologies.tsv
        """
}

// Here Fede cleans alignments
// Runs analyse_alignments_with_identity_v2.R
// Runs clean_alignments.sh and meta_clean_alignments.sh (which does the following)
// Runs prequal # check?
// Aligns codon sequences based on amino acid translations with MACSEv2
// Uses BMGE to filter unreliably aligned columns 
// https://academic.oup.com/sysbio/article/64/5/778/1685763

// Is it just because of the filtering and we could use the trees straight out of orthofinder?
// Can compare the orthofinder trees to iq trees

process iqtree{
        publishDir params.outdir, mode:'copy'
        cpus 32
        memory '64G'

        input:
        tuple val(meta), path(alignments, stageAs: "alignments/*")
        //val{iqtree_model}
        //val{iqtree_outgroup}

        output:
        tuple val(meta), path("${meta}_trees/*pruned.treefile")

        script:
        """
        mkdir ${meta}_trees
        parallel -j4 'iqtree2 -s {} -T 8 -B 1000' ::: alignments/*
        parallel -j1 "cat alignments/{/} | cut -f-1 -d' ' > ${meta}_trees/{/}" ::: alignments/*.treefile
        prune_trees.py ${meta}_trees
        """
}

process get_orthogroup_cds{

        input:
        tuple val(meta), path(orthoset)
        path(cds, stageAs: "fastas/*")
        path(prots, stageAs: "selected_proteins/*")

        output:
        tuple val(meta), path("orthoset_cds_fastas/*")

        script:
        """
        mkdir sl_fastas
        mkdir orthoset_cds_fastas

        parallel -j1 'multi2singlefasta.sh < {} > sl_fastas/{/.}.sl.fa' ::: fastas/*
        get_orthogroup_cds.py ${orthoset} selected_proteins/ sl_fastas/ 
        """
}

// https://github.com/Obscuromics/Fly-Germ-Line-Chromosomes/blob/main/scripts/treefile2table_of_neighbors.py

// run_codeml.pl
// optim_blen.ctl
// two_omegas.ctl

// need trees from iqtree
// need codon alignments
// need to get cds for the prot fa dataset
// need to use the protein alignments with the cds's to make nucleotide alignments for each orthogroup

// fede used macsev2 which translates codon sequences to amino acids for alignment, is it better to use the prot sequences themselves?

process macsev2 {
        publishDir params.outdir, mode:'copy'
        cpus 32
        memory '48G'

        input:
        tuple val(meta), path(cds, stageAs: "fastas/*")

        output:
        tuple val(meta), path("${meta}_alignments/*")

        script:
        """
        mkdir ${meta}_alignments
        parallel -j32 'macse -prog alignSequences -seq {}' ::: fastas/* || true
        mv fastas/*.cds_NT.fa ${meta}_alignments
        parallel -j1 "sed -i 's/_selected_proteins_/./g' {}" ::: ${meta}_alignments/*
        """
}

// use trees to select pairs of NT alignments for codeml
// check 1 grc dataset per orthogroup

process select_comparisons{
        publishDir params.outdir, mode:'copy'

        input:
        tuple val(meta), path(cds, stageAs: "fastas/*"), path(trees, stageAs: "trees/*")

        output:
        tuple val(meta), path("pruned_alignments/*"), path("pruned_trees/*"), path("*.dnds.tsv")

        script:
        """
        mkdir pruned_alignments
        mkdir pruned_trees
        select_comparisons.py fastas trees pruned_alignments pruned_trees ${meta}
        """
}

process codeml {
        publishDir params.outdir, mode:'copy'
        input:
        tuple val(meta), path(alignment), path(tree)

        output:

        script:
        """

        """
}