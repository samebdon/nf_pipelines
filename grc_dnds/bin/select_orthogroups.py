#!/usr/bin/env python3

import pandas as pd
import numpy as np

df = pd.read_csv('Orthogroups.GeneCount.tsv', sep='\t')
grcs = ['bcop_grc', 'bimp_grc', 'ling_grc']
cores = [label for label in df.columns.to_list() if label.split('.')[0] not in grcs + ['phyg']][1:-1]
df['core_SCO'] = (df.loc[:,cores]==1).sum(axis=1)==df.loc[:,cores].shape[1]

for grc in grcs:
	grc_sco_df = df[(df['core_SCO']==True) & (df[grc+'.selected_proteins']==1)]['Orthogroup'].to_csv(f'{grc}.SCOs.txt', header=None, index=False)