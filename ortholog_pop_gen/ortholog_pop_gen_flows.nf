include { get_best_cds_bed; get_best_pep_fasta; get_callable_cds_bed; make_genome_file; get_mask_bed; get_samples; remove_missing_vcf; generate_loci; generate_effective_fasta_AGAT;generate_effective_fasta_AGAT_no_vcf; orthofinder; get_SCO_genes; filter_annotation; filter_orthogroups; mafft; mafft_batch; dupe_prot_fasta; get_orthogroup_haps; get_orthogroup_haps_batch; translatorx; translatorx_pair;orthodiver;agg_orthodiver;merge_results} from './ortholog_pop_gen_tasks.nf'

// remove non informative fastas earlier
// add orthogroup filtering step to generalise for inferring orthology with >2 species
// can take get best pep fasta out of this so can be independent of second sample vcf

workflow gen_haps_flow {
        take:
          species
          genome_fasta
          vcf
          callable_bed
          annotation
          pep_fasta

        main:
          get_best_cds_bed(species, annotation)
          get_best_pep_fasta(get_best_cds_bed.out.bed, pep_fasta)
          get_callable_cds_bed(get_best_cds_bed.out.bed, callable_bed)
          make_genome_file(genome_fasta)
          get_mask_bed(get_callable_cds_bed.out, make_genome_file.out)
          get_samples(vcf)
          // remove_missing_vcf(species, vcf)
          generate_loci(get_samples.out.splitText( by: 1 ).map{it -> it.trim()}, get_mask_bed.out, genome_fasta, vcf)//remove_missing_vcf.out)
          generate_effective_fasta_AGAT(generate_loci.out, get_best_cds_bed.out.gff)

        emit:
          generate_effective_fasta_AGAT.out.collect()
          get_best_pep_fasta.out
}

workflow gen_haps_flow_no_vcf {
        take:
          species
          genome_fasta
          annotation
          pep_fasta

        main:
          get_best_cds_bed(species, annotation)
          get_best_pep_fasta(get_best_cds_bed.out.bed, pep_fasta)
          make_genome_file(genome_fasta)
          get_mask_bed(get_best_cds_bed.out.bed, make_genome_file.out)
          generate_effective_fasta_AGAT_no_vcf(species, genome_fasta, get_best_cds_bed.out.gff)

        emit:
          generate_effective_fasta_AGAT_no_vcf.out
          get_best_pep_fasta.out
}

workflow infer_orthology_flow {
        take:
          prot_fastas
          annotation_1
          annotation_2

        main:
          orthofinder(prot_fastas)
          get_SCO_genes(orthofinder.out.all)
          filter_annotation(get_SCO_genes.out.genes, annotation_1, annotation_2)

        emit:
          orthofinder.out.all
          orthofinder.out.sco
          filter_annotation.out.sp1
          filter_annotation.out.sp2
          get_SCO_genes.out.sc_orthogroups
}

// assuming 2 protein files in prot_dir for now. should generalise for any number of samples
// need an orthodiver flow with no outgroup vcf
// maybe the orthodiver flow is the same actually its just the earlier bit that changes?
workflow orthodiver_flow {
        take:
          hap_fastas_1
          hap_fastas_2
          ortholog_seqs
        main:
          // TO DO filter_orthogroups(species_1, species_2, ortholog_seqs)
          mafft_batch(ortholog_seqs.flatten().collect())

          // amend these two for no outgroup fasta?
          get_orthogroup_haps_batch(mafft_batch.out, hap_fastas_1, hap_fastas_2)
          translatorx_pair(mafft_batch.out, get_orthogroup_haps_batch.out.flatten())
          orthodiver(translatorx_pair.out)
          agg_orthodiver(orthodiver.out.flatten().collect())

        emit:
          agg_orthodiver.out
}

workflow merge_orthodiver_gene_pop {
        take:
          agg_orthodiver
          gene_pop_1
          gene_pop_2
          orthogroups

        main:
          merge_results(agg_orthodiver, gene_pop_1, gene_pop_2, orthogroups)
}