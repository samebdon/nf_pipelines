log.info """\
         G R C   D N / D S   N F   P I P E L I N E    
         ===================================
         Braker TSV : ${params.braker_tsv}
         Protein TSV : ${params.protein_tsv}
         outdir : ${params.outdir}
         """
         .stripIndent()

include { grc_dnds_flow } from './grc_dnds_flows.nf'

workflow {
        grc_dnds_flow(params.braker_tsv, params.protein_tsv)
}

// mamba activate grc_dnds
// mamba install -c conda-forge -c bioconda orthofinder ag
