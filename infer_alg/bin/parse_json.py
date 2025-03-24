#!/usr/bin/env python3

import pandas as pd 
import sys

json_f = sys.argv[1]
json_df = pd.read_json(json_f)

accession = json_df.reports[0]['assembly_accession']

for sequence in json_df.reports:
	# we could include 
	if (sequence['assigned_molecule_location_type'] == 'Chromosome') & (sequence['role']=='assembled-molecule'):
		print(sequence['genbank_accession'])