#!/usr/bin/env bash

TAXID="$1"

ORDER=$(curl -Ls "https://goat.genomehubs.org/api/v2/search?query=tax_lineage%28${TAXID}%29%20AND%20tax_rank%28order%29&result=taxon&taxonomy=ncbi&size=1&fields=none" -H "accept:text/tab-separated-values" | tail -n 1 | cut -f 3)
SUBORDER=$(curl -Ls "https://goat.genomehubs.org/api/v2/search?query=tax_lineage%28${TAXID}%29%20AND%20tax_rank%28suborder%29&result=taxon&taxonomy=ncbi&size=1&fields=none" -H "accept:text/tab-separated-values" | tail -n 1 | cut -f 3)
INFRAORDER=$(curl -Ls "https://goat.genomehubs.org/api/v2/search?query=tax_lineage%28${TAXID}%29%20AND%20tax_rank%28infraorder%29&result=taxon&taxonomy=ncbi&size=1&fields=none" -H "accept:text/tab-separated-values" | tail -n 1 | cut -f 3)
SUPERFAMILY=$(curl -Ls "https://goat.genomehubs.org/api/v2/search?query=tax_lineage%28${TAXID}%29%20AND%20tax_rank%28superfamily%29&result=taxon&taxonomy=ncbi&size=1&fields=none" -H "accept:text/tab-separated-values" | tail -n 1 | cut -f 3)
FAMILY=$(curl -Ls "https://goat.genomehubs.org/api/v2/search?query=tax_lineage%28${TAXID}%29%20AND%20tax_rank%28family%29&result=taxon&taxonomy=ncbi&size=1&fields=none" -H "accept:text/tab-separated-values" | tail -n 1 | cut -f 3)
SUBFAMILY=$(curl -Ls "https://goat.genomehubs.org/api/v2/search?query=tax_lineage%28${TAXID}%29%20AND%20tax_rank%28subfamily%29&result=taxon&taxonomy=ncbi&size=1&fields=none" -H "accept:text/tab-separated-values" | tail -n 1 | cut -f 3)

echo -e $ORDER"\t"$SUBORDER"\t"$INFRAORDER"\t"$SUPERFAMILY"\t"$FAMILY"\t"$SUBFAMILY"\t"$TAXID >> $TAXID.taxonomy.tsv