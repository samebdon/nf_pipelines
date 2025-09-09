#!/usr/bin/env python3

import sys
from os import listdir
from os.path import isfile, join
from Bio import Phylo

tree_dir = sys.argv[1]
tree_files = [f for f in listdir(tree_dir) if isfile(join(tree_dir, f))]

for tree_file in tree_files:
	meta = tree_file.split('.')[0]
	tree = Phylo.read(f'{tree_dir}/{tree_file}', "newick")
	leaves = tree.get_terminals()
	excluded_leaves = [leaf for leaf in leaves if 'phyg' in leaf.name]
	for leaf in excluded_leaves:
		tree.prune(leaf)
	Phylo.write(tree, f'{tree_dir}/{meta}.pruned.treefile','newick')
