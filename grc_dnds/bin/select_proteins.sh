#!/usr/bin/env bash

GFF="$1"
FASTA="$2"

awk '$3=="mRNA"' $GFF | awk '{print $9}' | cut -f-1 -d';' | cut -f2- -d'=' > transcripts.txt
awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' < $FASTA > single_line.fa

for TRANSCRIPT in $(cat transcripts.txt);
do
	grep -A1 $TRANSCRIPT single_line.fa
done
