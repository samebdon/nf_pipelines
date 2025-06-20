#!/usr/bin/env python3

from Bio import Phylo
from Bio import SeqIO
from Bio import codonalign
import random
import sys, os


def tabulate_names(tree):
    names = {}
    for idx, clade in enumerate(tree.find_clades()):
        if clade.name:
            next
            # clade.name = "%d_%s" % (idx, clade.name)
        else:
            clade.name = str(idx)
        names[clade.name] = clade
    return names


def get_core_sisters(node):
    focal_parent = tree.get_path(node)[-2]
    sister_leaves = focal_parent.get_terminals()
    sister_leaves_core = [leaf for leaf in sister_leaves if "grc" not in leaf.name]
    n_sisters = len(sister_leaves_core)
    return n_sisters, sister_leaves_core, focal_parent


fasta_dir = str(sys.argv[1])
tree_dir = str(sys.argv[2])
out_fasta_dir = str(sys.argv[3])
out_tree_dir = str(sys.argv[4])
focal_taxon = str(sys.argv[5]).split(".")[0]

fasta_fs = os.listdir(fasta_dir)
tree_fs = os.listdir(tree_dir)

with open(f"{focal_taxon}.dnds.tsv", "w") as out_file:
    out_file.write(f'focal_taxon\torthogroup\tdn\tds\tdn/ds\n')

for tree_f in tree_fs:
    orthogroup = tree_f.split(".")[0]
    tree_path = f"{tree_dir}/{tree_f}"
    tree = Phylo.read(tree_path, "newick")
    tree_names = tabulate_names(tree)
    leaves = tree.get_terminals()
    focal_leaf = [leaf for leaf in leaves if focal_taxon in leaf.name][0]
    outgroup_leaf = [leaf for leaf in leaves if "dmel" in leaf.name][0]
    tree.root_with_outgroup({"name": outgroup_leaf.name})
    n_sisters = 0
    node = focal_leaf
    while n_sisters == 0:
        try:
            n_sisters, sister_leaves_core, focal_parent = get_core_sisters(node)
        except IndexError:
            print(f"{focal_taxon} has no parent node in orthogroup {orthogroup}")
            Phylo.draw_ascii(tree)
            continue
        node = focal_parent

    if n_sisters > 1:
    	print(f'check {tree_f} for paralogs, selecting random sister')
    	Phylo.draw_ascii(tree)

    # pick random sister
    sister_leaf = sister_leaves_core[random.randint(0, n_sisters - 1)]

    for leaf in leaves:
        if leaf is not focal_leaf and leaf is not sister_leaf:
            tree.prune(leaf)
            # Phylo.draw_ascii(tree)

    Phylo.write(tree, f"{out_tree_dir}/{orthogroup}.{focal_taxon}.pruned.newick", "newick")

    try:
        fasta_f = [fasta for fasta in fasta_fs if orthogroup in fasta][0]
    except IndexError:
        print(f"File {orthogroup} not in fasta_fs")
        continue

    fasta_sequences = SeqIO.parse(open(f"{fasta_dir}/{fasta_f}"), "fasta")
    out_sequences = []
    with open(f"{out_fasta_dir}/{orthogroup}.{focal_taxon}.pruned.fa", "w") as out_file:
        for fasta in fasta_sequences:
            name, sequence = fasta.id, str(fasta.seq)
            if (
                name.split(".")[0] in focal_leaf.name
                or name.split(".")[0] in sister_leaf.name
            ):
                out_sequences.append(fasta)
        SeqIO.write(out_sequences, out_file, "fasta")

    try:
    	seq_one = codonalign.codonseq.CodonSeq(out_sequences[0].seq)[:-3] # removing stop codons
    	seq_two = codonalign.codonseq.CodonSeq(out_sequences[1].seq)[:-3]
    except IndexError:
    	print(f'{len(out_sequences)} out sequences in {orthogroup}')
    	continue

    try:
    	dn, ds = codonalign.codonseq.cal_dn_ds(seq_one, seq_two, method='NG86')
    except:
    	print(f'stop codon KeyError in {orthogroup}')
    	continue


    with open(f"{focal_taxon}.dnds.tsv", "a") as out_file:
    	out_file.write(f'{focal_taxon}\t{orthogroup}\t{dn:,.5g}\t{ds:,.5g}\t{dn/ds:,.5g}\n')