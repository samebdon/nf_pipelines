#!/usr/bin/env python3

import pandas as pd 
import numpy as np
import sys, os
import subprocess

orthoset_f = sys.argv[1] # orthogroups to use
selected_protein_dir = sys.argv[2] # gene names per dataset per orthogroup
cds_dir = sys.argv[3] # cds fasta files

outdir = 'orthoset_cds_fastas'

orthogroups = pd.read_csv(orthoset_f, header=None)[0].to_list()
selected_protein_fs = os.listdir(selected_protein_dir)
cds_fs = os.listdir(cds_dir)

prot_tsv_names = ['Orthogroup','Species','Proteins','Orthologs']

for prot_tsv in selected_protein_fs:
	species = prot_tsv.split('.')[0]
	prot_df = pd.read_csv(f"{selected_protein_dir}/{prot_tsv}", sep = '\t', names = prot_tsv_names)
	prot_df.drop(['Species', 'Orthologs'], inplace=True, axis=1)
	prot_df = prot_df[prot_df['Orthogroup'].isin(orthogroups)].reset_index().drop('index', axis=1).drop_duplicates().reset_index().drop('index', axis=1)

	subprocess.run(
		f"sed -e 's/>/>{species}./g' {cds_dir}/{species}.selected_CDSs.sl.fa > {cds_dir}/{species}.rn.fa",
		shell=True,
		executable="/bin/bash"
		)

	for index, row in prot_df.iterrows():

		orthogroup = row['Orthogroup']
		proteins = row['Proteins'].split(',')
		for protein in proteins:
			subprocess.run(
				f"grep -A1 {protein} {cds_dir}/{species}.rn.fa >> {outdir}/{orthogroup}.cds.fa",
				shell=True,
				executable="/bin/bash"
				)