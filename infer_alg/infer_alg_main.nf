log.info """\
         I N F E R   A L G   N F   P I P E L I N E    
         ===================================
         Genome TSV : ${params.accession_tsv}
         BUSCO DB : ${params.busco_db}
         outdir : ${params.outdir}
         """
         .stripIndent()

include { infer_alg_flow } from './infer_alg_flows.nf'

workflow {
         infer_alg_flow(params.accession_tsv)
}
