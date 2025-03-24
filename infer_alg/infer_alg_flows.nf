include {get_taxon_info; collate_taxon_info; download_genomes; get_chromosome_names; busco; busco2fasta; mafft; trimal; trimal_array_clean; catfasta2phyml; iqtree; prepare_busco_tables; syngraph_build; syngraph_infer; summarise_clusters} from './infer_alg_tasks.nf'

workflow infer_alg_flow {

        take:
         input_tsv // channel: [ val(meta), val(accession), val(taxid)]
         busco_db
         busco_download_path
         iqtree_model
         iqtree_outgroup
         taxon

        main:
        // parse input tsv to channel
         Channel
                .fromPath( input_tsv )
                .splitCsv( header: true, sep: '\t')
                .multiMap{ row -> 
                      accession: [row.meta, row.accession]
                      taxid: [row.meta, row.taxid]
                      }
                .set{ meta_ch }

        // create taxonomy tsv
          get_taxon_info(meta_ch.taxid)
          collate_taxon_info( taxon,
                              get_taxon_info.out
                                    .map{meta, tsv -> tsv}
                                    .collect() 
                             )

        // get genomes and run BUSCO
          meta_ch.accession
                .map{ meta, accession -> accession}
                .collectFile( name: 'accessions.txt', newLine: true)
                .set{ accessions_file }

          get_chromosome_names( taxon, accessions_file )

          get_chromosome_names.out 
                              .transpose()
                              .map{ meta, chromosome_files -> chromosome_files}
                              .map{ genome ->
                                    (accession_prefix, accession_suffix, chromosomes, suffix) = genome.name.tokenize('.')
                                    [accession_prefix + "." + accession_suffix, genome]
                                    } 
                              .set{ chromosome_file_ch }

          // switch to combine() syntax if that works
          download_genomes( taxon, accessions_file )

          // currently assuming all the genomes will have the same number of underscores in their name
          download_genomes.out
                .transpose()
                .map{ meta, genomes -> genomes}
                .map{ genome ->
                      (accession_prefix, accession_suffix, meta, suffix) = genome.name.tokenize('_')
                      [accession_prefix + "_" + accession_suffix, genome]
                    } 
                .set{ fasta_ch }

          busco(fasta_ch, busco_db, busco_download_path)

        // infer tree

          busco2fasta(taxon,
                      busco.out
                          .map{ meta, busco_results -> busco_results}
                          .collect()
                       )

          mafft(busco2fasta.out)
          trimal(mafft.out)
          trimal_array_clean(trimal.out)
          catfasta2phyml(trimal_array_clean.out)
          iqtree(catfasta2phyml.out.supermatrix,           
                 //iqtree_model,
                 //iqtree_outgroup
                 )
          prepare_busco_tables(busco.out.join(chromosome_file_ch))
          syngraph_build(prepare_busco_tables.out 
                                             .transpose()
                                             .map{ meta, syngraph_inputs -> syngraph_inputs}
                                             .collect()
                          )
          //syngraph_infer(syngraph_build.out, iqtree.out)

          }


        // syngraph

          // rename()
          // 
          // 
          // 
          // summarise_clusters()

