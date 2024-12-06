include {unmask_genome; earlGrey; braker2} from './annotate_tasks.nf'

workflow braker2_flow {
        take:
          meta
          genome
          prot_seq

        main:
          unmask_genome(meta, genome)
          earlGrey(unmask_genome.out)
          braker2(earlGrey.out.softmasked_genome, prot_seq)
}

workflow braker2_only_flow {
        take:
          meta
          genome
          prot_seq

        main:
          braker2(meta.combine(genome), prot_seq)
}

workflow braker2_flow_rm{
        take:
          meta
          genome
          prot_seq

        main:
          unmask_genome(meta, genome)
          repeatmodeler(unmask_genome.out)
          repeatmasker(unmask_genome.out, repeatmodeler.out)
          braker2(repeatmasker.out, prot_seq)
}