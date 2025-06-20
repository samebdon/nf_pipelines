#!/bin/bash -ue
mkdir out_fastas
mkdir out_trees
select_comparisons.py fastas trees out_fastas out_trees bimp_grc.SCOs
