process unmask_genome {

        input:
        val(meta)
        path(genome)

        output:
        tuple val(meta), path("${meta}.unmasked.fa")

        script:
        """
        awk '/^>/ {print(\$0)}; /^[^>]/ {print(toupper(\$0))}' ${genome} > ${meta}.unmasked.fa
        """
}

process earlGrey {
        publishDir params.outdir, mode:'copy'
        memory '200G'
        cpus 64
        queue 'basement'
        conda '/software/treeoflife/conda/users/envs/team360/se13/earlgrey'

        input:
        tuple val(meta), path(genome)

        output:
        path("./results/${meta}_EarlGrey"), emit: all
        path("./results/${meta}_EarlGrey/${meta}_summaryFiles/${meta}.filteredRepeats.bed"), emit: repeat_bed
	tuple val(meta), path("./results/${meta}_EarlGrey/${meta}_summaryFiles/${meta}.softmasked.fasta"), emit: softmasked_genome
        
	script:
        """
        earlGrey -g ${genome} -s ${meta} -o ./results -t ${task.cpus} -d yes
        """
}

process braker2 {
        publishDir params.outdir, mode:'copy'
        memory '40G'
        cpus 32
        queue 'long'

        input:
        tuple val(meta), path(genome)
        path(prot_seq)

        output:
        tuple val(meta), path("wdir/*")

        script:
        """
        mkdir wdir
        braker.pl \
                --genome=${genome} \
                --softmasking \
                --workingdir=wdir \
                --threads ${task.cpus} \
                --species=${meta} \
                --gff3 \
                --prot_seq=${prot_seq} \
                --useexisting
        """
}

process repeatmodeler{
        cpus 72
        queue long

        input:
        tuple val(meta), path(genome)

        output:
        tuple val(meta), path("${meta}_repeat_db")

        script:
        """
        BuildDatabase -name ${meta}_repeat_db ${genome}
        RepeatModeler -database ${meta}_repeat_db -pa ${task.cpus} -LTRStruct
        """
}

process repeatmasker{
        cpus 72
        queue long

        input:
        tuple val(meta), path(genome)
        tuple val(rp_meta), path(repeat_db)

        output:
        tuple val(meta), path("${genome}.masked")

        script:
        """
        RepeatMasker -pa ${task.cpus} -lib ${repeat_db} -xsmall ${genome}
        """
}

process tandem_repeats_finder{
        input:
        tuple val(meta), path(genome)

        output:

        script:
        """

        """
}