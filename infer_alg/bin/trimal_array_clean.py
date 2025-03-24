#!/usr/bin/env python3
import os

# Directory containing the files
in_directory = 'trimal/'
out_directory = 'trimal_cleaned/'

# Loop through each file in the directory
for filename in os.listdir(in_directory):
    if filename.endswith('.faa'):
        in_filepath = os.path.join(in_directory, filename)
        out_filepath = os.path.join(out_directory, filename)
        # Read the content of the file
        with open(in_filepath, 'r') as file:
            content = file.readlines()
        # Modify the content
        modified_content = []
        for line in content:
            if line.startswith('>'):
                modified_content.append(line.split('.')[0] + '\n')  # Add a newline character after the species name
            else:
                modified_content.append(line.strip() + '\n')  # Add a newline character after the sequence
        # Write the modified content back to the file
        with open(out_filepath, 'w') as file:
            file.writelines(modified_content)


# The code modifies lines starting with > (FASTA headers)
# by truncating the text at the first period (.)
# and then adding a newline character at the end. For example, >GCF_028554725.1.10003at7147_6|NC_071671.1 becomes >GCF_028554725.
