log.info """\
         G R C   D N / D S   N F   P I P E L I N E    
         ===================================
         Input TSV : ${params.input_tsv}
         outdir : ${params.outdir}
         """
         .stripIndent()

include { orthofinder_flow; orthofinder_flow_gff; grc_dnds_flow; grc_dnds_flow_gff } from './grc_dnds_flows.nf'

workflow {
        //orthofinder_flow(params.braker_tsv, params.protein_tsv)
        //orthofinder_flow_gff(params.input_tsv )
        //grc_dnds_flow(params.braker_tsv, params.protein_tsv, params.msa, params.gene_counts, params.selected_protein_tsvs)
        grc_dnds_flow_gff(params.input_tsv, params.msa, params.gene_counts, params.selected_protein_tsvs)
}

// mamba activate grc_dnds
// mamba install -c conda-forge -c bioconda orthofinder ag
