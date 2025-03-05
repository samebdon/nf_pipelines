include {;} from './infer_alg_tasks.nf'

workflow infer_alg_flow {

        take:
         accession_tsv // channel: [ val(meta), val(accession)]
         busco_db

        main:
        // parse input tsv to channel
         Channel
                .fromPath( accession_tsv )
                .splitCsv( header: true, sep: '\t')
                .map{ row -> 
                        tuple(row.meta, row.accession)
                        }
                .set{ accession_ch }

          get_taxon_info(accession_ch)
          download_genomes(accession_ch)
          busco(download_genomes.out, busco_db)
          busco2fasta(busco.out)
          mafft()
          trimal()
          catfasta2phyml()
          iqtree()
          rename()
          prepare_syngraph_input()
          syngraph_build()
          syngraph_infer()
          summarise_clusters()
}