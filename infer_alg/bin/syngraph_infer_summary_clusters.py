import os
import sys
import glob

def combine_files(input_paths, output_file):
    header = "cluster\tnode\talg\tmarker\trearrangement\tmethod\ttree\n"
    with open(output_file, 'w') as outfile:
        outfile.write(header)
        for file_path in input_paths:
            if os.path.isfile(file_path) and file_path.endswith('.clusters.tsv'):
                print(f"Processing file: {file_path}")
                process_file(file_path, outfile)
            else:
                print(f"Ignored (not a clusters.tsv file): {file_path}")

def process_file(file_path, outfile):
    parts = os.path.basename(file_path).split('.')
    if len(parts) >= 5:
        m_number = parts[2][1:]  # Extract the 'm' number
        r_number = parts[3]      # Extract the 'r' number
        a_number = parts[4]      # Extract the 'a' number
        # Extract tree name by navigating up the directory structure to capture the right "tree" name
        tree_name = os.path.basename(os.path.dirname(os.path.dirname(file_path)))  # Grandparent directory name
        with open(file_path, 'r') as infile:
            for line in infile:
                if line.strip():
                    try:
                        cluster, node, alg = line.strip().split('\t')
                        outfile.write(f"{cluster}\t{node}\t{alg}\t{m_number}\t{r_number}\t{a_number}\t{tree_name}\n")
                    except ValueError:
                        print(f"Skipping improperly formatted line in {file_path}: {line.strip()}")
                else:
                    print(f"Skipping empty line in {file_path}")
    else:
        print("Filename format is incorrect, skipping:", file_path)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python script.py input_file1 input_file2 ... output_file")
        sys.exit(1)

    input_paths = sys.argv[1:-1]  # All arguments except the last one are input file paths
    output_file = sys.argv[-1]  # The last argument is the output file
    combine_files(input_paths, output_file)
