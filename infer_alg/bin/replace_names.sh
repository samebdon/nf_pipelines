#!/bin/bash

# Define your files
input_file="supermatrix.phy.one_lepi_no_sipho.treefile"
mapping_file="acc_name_match.txt"
output_file="trial_tree_new.txt"

# Read the mapping file and create a sed command
sed_command=$(awk -F',' '{print "s/" $2 "/" $1 "/g"}' $mapping_file)

# Apply the sed command to the input file and save to the output file
sed "$sed_command" $input_file > $output_file
