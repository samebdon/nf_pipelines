include {filterIncompleteGeneModelsAGAT; getLongestIsoformAGAT; select_proteins; orthofinder; select_orthogroups; select_msa; concat_orthogroup_topologies; iqtree; get_orthogroup_cds; macsev2; codeml} from './grc_dnds_tasks.nf'

workflow orthofinder_flow{

        take:
         braker_tsv // channel: [ val(meta), /path/to/genome, /path/to/cds, /path/to/gff, /path/to/prot_fa ]
         protein_tsv // channel: [ val(meta), /path/to/cds, /path/to/prot_fa ]

        main:

         // parse braker_tsv
         Channel
                .fromPath( braker_tsv )
                .splitCsv( header: true, sep: '\t')
                .multiMap{ row -> 
                        genome: [row.meta, row.genome]
                        cds:  [row.meta, row.cds]
                        gff: [row.meta, row.gff]
                        prot_fa: [row.meta, row.prot_fa]
                        }
                .set{ braker_ch }

         // parse protein_tsv
         Channel
                .fromPath( protein_tsv )
                .splitCsv( header: true, sep: '\t')
                .multiMap{ row ->
                        cds:  [row.meta, row.cds]
                        prot_fa: [row.meta, row.prot_fa]
                }
                .set{ prot_ch }

         // add species prefix to fasta headers of both cds and prot here when i get the chance, should be able to do it with sed

         // select suitable proteins for orthology inference
         filterIncompleteGeneModelsAGAT(braker_ch.gff.join(braker_ch.genome))
         getLongestIsoformAGAT(filterIncompleteGeneModelsAGAT.out)
         select_proteins(getLongestIsoformAGAT.out.join(braker_ch.prot_fa))

         // combine denovo and preprocessed protein datasets
         select_proteins.out
                .concat(prot_ch.prot_fa)
                .collect( flat:false )
                .map{ it.transpose() }
                .set { selected_prot_ch }

         // orthology inference
         orthofinder(selected_prot_ch)

         emit:
         orthofinder.out.all
         orthofinder.out.gene_count
         orthofinder.out.msa
}

workflow grc_dnds_flow {

        take:
         braker_tsv // channel: [ val(meta), /path/to/genome, /path/to/cds, /path/to/gff, /path/to/prot_fa ]
         protein_tsv // channel: [ val(meta), /path/to/cds, /path/to/prot_fa ]
         msa
         gene_counts
         selected_protein_tsvs

        main:
         // parse braker_tsv
         Channel
                .fromPath( braker_tsv )
                .splitCsv( header: true, sep: '\t')
                .multiMap{ row -> 
                        genome: [row.meta, row.genome]
                        cds:  [row.meta, row.cds]
                        gff: [row.meta, row.gff]
                        prot_fa: [row.meta, row.prot_fa]
                        }
                .set{ braker_ch }

         // parse protein_tsv
         Channel
                .fromPath( protein_tsv )
                .splitCsv( header: true, sep: '\t')
                .multiMap{ row ->
                        cds:  [row.meta, row.cds]
                        prot_fa: [row.meta, row.prot_fa]
                }
                .set{ prot_ch }

         // get msa channel
         Channel
                .fromPath( msa )
                .set{ msa_ch }

         Channel
                .fromPath( selected_protein_tsvs )
                .set{ sel_prot_tsv_ch }


         cds_ch = braker_ch.cds
                            .concat(prot_ch.cds)

         select_orthogroups(gene_counts)
         select_orthogroups.out
                            .map{ orthoset ->
                             meta = orthoset.baseName
                             [meta, orthoset]
                           }
                           .transpose()
                           .set{ orthoset_ch }

         // get prot and cds alignments
           select_msa(orthoset_ch,
                      msa_ch.collect()
                      )
          
         //concat_orthogroup_topologies()

         // get trees
          iqtree(select_msa.out)

         // need to get files of CDSs for alignment given orthogroups
          get_orthogroup_cds(orthoset_ch, 
                             cds_ch.transpose()
                                   .map{meta, cds -> cds}
                                   .collect(),
                             sel_prot_tsv_ch.collect()
                             )

         // align_CDS
          macsev2(get_orthogroup_cds.out)

         // codeml
         // codeml(macsev2.out, iqtree.out)

}