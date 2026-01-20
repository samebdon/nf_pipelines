log.info """\
         V A R  C A L L   N F   P I P E L I N E    
         ===================================
         genome : ${params.genome}
	 reads : ${params.bams}
         outdir : ${params.outdir}
         species : ${params.species}
         """
         .stripIndent()

include { var_call_flow; var_call_flow_single_pe; var_call_flow_single_se; var_call_flow_bams } from './var_call_flows.nf'

// many samples paired-end reads
//workflow {
//         read_pairs_ch = Channel.fromFilePairs( params.reads, checkIfExists:true )
//         var_call_flow(params.genome, params.genome_index, read_pairs_ch, params.repeat_bed, params.species)
//}

// with bams
workflow{
  bam_ch = Channel.fromPath(params.bams, checkIfExists:true)
  var_call_flow_bams(params.genome, params.genome_index, bam_ch, params.repeat_bed, params.species)
}

// one sample paired-end reads
//workflow {
//         read_pairs_ch = Channel.fromFilePairs( params.reads, checkIfExists:true )
//         var_call_flow_single_pe(params.genome, params.genome_index, read_pairs_ch, params.repeat_bed, params.species)
//}

// one sample single-end reads
//workflow {
//        var_call_flow_single_se(params.genome, params.genome_index, params.reads, params.repeat_bed, params.species)
//}

