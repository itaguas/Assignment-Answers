require 'bio'

if ARGV[0].class == NilClass
  abort "the command to run this file should be: ruby [name of the script] [file1] [file2]. The order of the files does not matter"
end

#We create the output file
File.open("Reciprocal_genes", 'w') do |file|
  file.printf "%-20s %s\n", "S. pombe", "A. thaliana"
end

#We set the parameters. To do this, I checked two papers:
#Moreno-Hagelsieb, Gabriel & Latimer, Kristen. (2008). Choosing BLAST options for better detection of orthologs as reciprocal best hits. Bioinformatics (Oxford, England). 24. 319-24. 10.1093/bioinformatics/btm585
#Ward, Natalie & Moreno-Hagelsieb, Gabriel. (2014). Quickly finding orthologs as reciprocal best hits with BLAT, LAST, and UBLAST: how much do we miss?. PloS one. 9. e101850. 10.1371/journal.pone.0101850
$EVAL = 10**-6 #According to the information contained in these papers, I set the e-value to 10**-6
#I also found that coverage might be a good filter. However, I decided not to apply it because one file contains nucleic acids and the other proteins, so introns and other non-coding regions might interfere with the results

#We check which file is larger; that will be file 2, and the other will be file 1.
if File.size(ARGV[0]) < File.size(ARGV[1])
  datafile1 = ARGV[0]
  datafile2 = ARGV[1]
else
  datafile1 = ARGV[1]
  datafile2 = ARGV[0]
end

#We check that the files are fasta-formatted. To do this, we create a Bio::Flatfile with automatic detection of the type, and then check if the type assigned is FastaFormat
file1 = Bio::FlatFile.auto(datafile1)
file2 = Bio::FlatFile.auto(datafile2)
incorrect_files = 0
if file1.autodetect != Bio::FastaFormat
  incorrect_files = 1
end
if file2.autodetect != Bio::FastaFormat
  if incorrect_files == 1
    incorrect_files = 3
  else
    incorrect_files = 2
  end
end
if incorrect_files == 1
  abort "#{datafile1} is not a fasta file"
elsif incorrect_files == 2
  abort "#{datafile2} is not a fasta file"
elsif incorrect_files == 3
  abort "neither file is a fasta file"
end

#We check what type the sequences in the files are (nucleotidic or proteic sequence, or neither). To do this, we check the type of the first entry of each file.
seqtype1 = Bio::Sequence.auto(file1.next_entry().seq)
file1.rewind()
seqtype2 = Bio::Sequence.auto(file2.next_entry().seq)
file2.rewind()
incorrect_data = 0
if seqtype1.seq.class == Bio::Sequence::AA
  type1 = 'prot'
elsif seqtype1.seq.class = Bio::Sequence::NA
  type1 = 'nucl'
else
  incorrect_data = 1
end
if seqtype2.seq.class == Bio::Sequence::AA
  type2 = 'prot'
elsif seqtype2.seq.class == Bio::Sequence::NA
  type2 = 'nucl'
else
  if incorrect_data == 1
    incorrect_data = 3
  else
    incorrect_data = 2
  end
end
if incorrect_data == 1
  abort "#{datafile1} has sequences that are neither nucleotidic nor proteic"
elsif incorrect_data == 2
  abort "#{datafile2} has sequences that are neither nucleotidic nor proteic"
elsif incorrect_files == 3
  abort "neither file has sequences that are either nucleotidic or proteic"
end

#We create the databases
system("makeblastdb -in '#{datafile1}' -dbtype #{type1} -out ./db1")
system("makeblastdb -in '#{datafile2}' -dbtype #{type2} -out ./db2")

#We create the factories. factory1 is used to blast genes from file 1 against the database from file 2, and factory2 to blast genes from file 2 against the database from file 1.
if type1 == 'nucl' and type2 == 'nucl'
  factory1 = Bio::Blast.local('blastn', './db2')
  factory2 = Bio::Blast.local('blastn', './db1')
elsif type1 == 'nucl' and type2 == 'prot'
  factory1 = Bio::Blast.local('blastx', './db2')
  factory2 = Bio::Blast.local('tblastn', './db1')
elsif type1 == 'prot' and type2 == 'nucl'
  factory1 = Bio::Blast.local('tblastn', './db2')
  factory2 = Bio::Blast.local('blastx', './db1')
elsif type1 == 'prot' and type2 == 'prot'
  factory1 = Bio::Blast.local('blastp', './db2')
  factory2 = Bio::Blast.local('blastp', './db1')
end

#We create a dictionary containing as keys the IDs of the larger file and as values its sequences.
entries2 = {}
file2.each_entry do |entry2|
  entries2[entry2.entry_id] = entry2.seq
end

count = 0 #Variable that counts the number of orthologues found.

#We go through all the entries from file 1. If the blast has results, and if the first hit has a good enough e-value, that first hit is blasted against the database to see if we get a reciprocal best hit. If we do, the two genes are added to the output file.
file1.each_entry do |entry1|
  first_id = entry1.entry_id
  puts "WORKING ON GENE: #{first_id}"
  report1 = factory1.query(entry1.seq)
  if report1.hits.length > 0
    if report1.hits[0].evalue <= $EVAL
      bestid_1 = report1.hits[0].definition.match(/^(\w+\.\w+)|/).to_s
      report2 = factory2.query(entries2[bestid_1])
      if report2.hits.length > 0
        if report2.hits[0].evalue <= $EVAL
          bestid_2 = report2.hits[0].definition.match(/^(\w+\.\w+)|/).to_s
          if bestid_2 == first_id
            File.open('Reciprocal_genes', 'a') do |myfile|
              myfile.printf "%-20s %s\n", first_id, bestid_1
              count = count + 1
            end
          end
        end
      end
    end
  end
end

puts "#{count} reciprocal pairs were found"

#The next steps that I would take to look for orthologues would be:
###First, I would take the genes of the putative orthologues of S. pombe instead of the proteins, and search again for reciprocal best hits with a coverage filter of 50%
###Then, I would look for GO annotations of both genes, to see if they share terms.
###Also, machine learning algorithms could be used to predict orthology from gene's sequence features, as explained in the following paper:
#####Campos, Túlio & Korhonen, Pasi & Gasser, Robin & Young, Neil. (2019). An Evaluation of Machine Learning Approaches for the Prediction of Essential Genes in Eukaryotes Using Protein Sequence-Derived Features. Computational and Structural Biotechnology Journal. 10.1016/j.csbj.2019.05.008
