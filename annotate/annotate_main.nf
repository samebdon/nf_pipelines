// MAKE SURE FASTA HEADERS ARE SIMPLE FOR EARLGREY AND BRAKER
// awk '{print $1}' genome.fasta > genome.simple_header.fasta
// PIPELINE WILL REMOVE EXISTING SOFTMASKING

// add simple fasta headers to script?
// make tsv input to annotate row by row

log.info """\
         O R T H O L O G  P O P  G E N   N F   P I P E L I N E    
         ===================================
         species : ${params.meta}
         genome :  ${params.genome}
         prot db : ${params.prot_seq}
         outdir :  ${params.outdir}
         """
         .stripIndent()

include { braker2_flow; braker2_only_flow; braker2_flow_rm } from './annotate_flows.nf'

workflow {
        braker2_flow(params.meta, params.genome, params.prot_seq)
        // braker2_flow_rm(params.meta, params.genome, params.prot_seq)
        // braker2_only_flow(params.meta, params.genome, params.prot_seq)
}
