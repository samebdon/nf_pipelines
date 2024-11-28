#!/usr/bin/env python3

import pandas as pd
import numpy as np

df = pd.read_csv('Orthogroups.GeneCount.tsv', sep='\t')
grcs = ['bcop_grc', 'bimp_grc', 'ling_grc']
cores = [label for label in df.columns.to_list() if not in grcs + ['phyg']]
df['core_SCO'] = (df.loc[:,cores]==1).sum(axis=1)==df.loc[:,cores].shape[1]

for grc in grcs
	df[(df['core_SCO']==True) & ([grc]==1)]['Orthogroup'].to_csv(f'{grc}.SCOs.txt')
