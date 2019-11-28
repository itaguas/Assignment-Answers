require 'net/http'
require 'bio'

def extract_exon(varname, feature)
  #Function that either directly extracts the exon or, if the exon is on another gene, extracts the exon from that gene
  if /^\d+..\d+/ =~ feature.position
    comp = false #Variable that is false if the exon is on the + chain, and true if it is on the - chain
    chain = false #This is also to see if the exon is on the + or - chain
    pos = feature.position.split("..")
    exon = eval(varname).subseq(pos[0].to_i,pos[1].to_i)
    return exon,comp,chain
  elsif /complement\((?<range>\d+..\d+)\)/ =~ feature.position
    comp = true
    chain = true
    pos = range.split("..")
    exon = eval(varname).subseq(pos[0].to_i,pos[1].to_i)
    return exon,comp,chain
  else #if the exon is referenced to another gene
    assoc = feature.assoc
    /exon_id=(?<newgene>A[Tt]\d[Gg]\d\d\d\d\d)/ =~ assoc["note"] #We go to the new gene and take the sequence
    unless $other_genes.include?(newgene)
      $other_genes << newgene
      address = URI("http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{newgene}")
      response = Net::HTTP.get_response(address)                          
      record = response.body
      File.open("newgene.embl", 'w') do |newfile|
        newfile.puts record
      end
      filename = "@datafile_#{newgene}"
      instance_variable_set(filename, Bio::FlatFile.new(Bio::EMBL, File.open("newgene.embl", 'r')))
      eval("@datafile_#{newgene}").each_entry do |newentry|
        next unless newentry.accession
        varname2 = "@#{newgene}"
        instance_variable_set(varname2, Bio::Sequence::NA.new(newentry.seq.downcase))
      end
      eval("@datafile_#{newgene}").rewind() #So that we can access the object again
    end
    eval("@datafile_#{newgene}").each_entry do |newentry|
      next unless newentry.accession
      newentry.features.each do |newfeature|
        if newfeature.feature == "exon"
          notes = newfeature.assoc
          #puts "NOTE: #{notes['note']}"
          if notes["note"] == assoc["note"]
            varname3 = "@#{newgene}"
            exon,comp = extract_exon(varname3, newfeature) #if necessary, we call the function again
          end
        end
      end
    end
    if /complement/ =~ feature.position
      chain = true
      if comp
        comp = false
      else
        comp = true
      end
    else
      chain = false
    end
    eval("@datafile_#{newgene}").rewind()
    return exon,comp,chain,newgene
  end
end

def scan_exon(exon,comp)
  #Function that annotates the coordinates of the target sequences
  if comp
    search = Bio::Sequence::NA.new("cttctt")
    re = Regexp.new(search.to_re)
    pos = exon.enum_for(:scan, re).map { Regexp.last_match.begin(0) }
    return pos, search.length
  else
    search = Bio::Sequence::NA.new("gaagaa")
    re = Regexp.new(search.to_re)
    pos = exon.enum_for(:scan, re).map { Regexp.last_match.begin(0) }
    return pos, search.length
  end
end

File.open("genes.gff3", 'w') do |file|
  file.puts "##gff-version 3"
end

File.open("genes_without_seq.txt", 'w') do |file|
  file.puts "Genes without the sequence CTTCTT"
end

File.open("chr.gff3", 'w') do |file|
  file.puts "##gff-version 3"
end

genes_from_list = [] #Array containing all the genes of the list
File.readlines("./ArabidopsisSubNetwork_GeneList.txt").each do |line|
  line = line.delete_suffix("\n")
  genes_from_list |= [line.upcase]
  puts "GENE: #{line.upcase}"
  address = URI("http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{line.upcase}")  # create a "URI" object
  response = Net::HTTP.get_response(address)  # use the Net::HTTP object "get_response" method
  record = response.body
  #Add the data to the file
  File.open('genes.embl', 'a') do |myfile|
    myfile.puts record
  end
end


datafile = Bio::FlatFile.new(Bio::EMBL, File.open('genes.embl', 'r')) # use that to create the correct type
$other_genes = [] #Array with the genes that we have to annotate that are not on the list
gene_number = -1 #Number of the gene in the list
#Variables to not repeat entries in the files
added_genes = []
added_exons1 = []
added_exons2 = []
datafile.each_entry do |entry|
  gene_ex = 0
  next unless entry.accession
  puts "AC: #{entry.accession}"
  chr = entry.accession.split(":")
  gene_number = gene_number+1
  #For this assignment, I have not used objects. THerefore, everytime I name the objects dynamically so that I can access them later
  varname = "@#{genes_from_list[gene_number]}"
  instance_variable_set(varname, Bio::Sequence::NA.new(entry.seq.downcase))
  seqname = "@seq_#{genes_from_list[gene_number]}"
  instance_variable_set(seqname, entry.to_biosequence)
  entry.features.each do |feature|
    if feature.feature == "exon"
      associations = feature.assoc
      assoc_note = associations["note"]
      exon,comp,chain,newgene = extract_exon(varname,feature)
      if newgene #This is to get the right coordinates for the files
        eval("@datafile_#{newgene}").each_entry do |newentry|
          next unless newentry.accession
          chr = newentry.accession.split(":")
        end
        eval("@datafile_#{newgene}").rewind()
      end
      pos,len = scan_exon(exon,comp)
      if pos != [] #If we have found sequences
        gene_ex = 1
        for index in pos
          index_ini = index + 1
          index_fin = index + len
          nfeat = "#{index_ini.to_s}..#{index_fin.to_s}"
          #We create and add the features
          f = Bio::Feature.new('repeat',nfeat)
          f.append(Bio::Feature::Qualifier.new('repeat_motif', 'CTTCTT'))
          if chain
            f.append(Bio::Feature::Qualifier.new('strand', '-'))
          else
            f.append(Bio::Feature::Qualifier.new('strand', '+'))
          end
          eval("@seq_#{genes_from_list[gene_number]}").features << f
          eval("@seq_#{genes_from_list[gene_number]}").features.each do |feat|
            featuretype = feat.feature
            next unless featuretype == "repeat"
            qual = feat.assoc
            #We add the neccessary lines to the files
            File.open('genes.gff3', 'a') do |file|
              if newgene
                b = "#{newgene}\t.\t#{qual["repeat_motif"]}\t#{index_ini}\t#{index_fin}\t.\t#{qual["strand"]}\t.\t#{assoc_note}"
                unless added_exons1.include?(b)
                  file.puts b
                  added_exons1 << b
                end
              else
                b = "#{genes_from_list[gene_number]}\t.\t#{qual["repeat_motif"]}\t#{index_ini}\t#{index_fin}\t.\t#{qual["strand"]}\t.\t#{assoc_note}"
                unless added_exons1.include?(b)
                  file.puts b
                  added_exons1 << b
                end
              end
            end
            File.open('chr.gff3', 'a') do |file|
              if newgene
                a = "#{chr[2]}\t.\tgene\t#{chr[3]}\t#{chr[4]}\t.\t+\t.\tID=#{newgene}"
                unless added_genes.include?(a)
                  file.puts a
                  added_genes << a
                end
                c = "#{chr[2]}\t.\tnucleotide_motif\t#{chr[3].to_i+index_ini}\t#{chr[3].to_i+index_fin}\t.\t#{qual["strand"]}\t.\t#{assoc_note}"
                unless added_exons2.include?(c)
                  file.puts c
                  added_exons2 << c
                end
              else
                a= "#{chr[2]}\t.\tgene\t#{chr[3]}\t#{chr[4]}\t.\t+\t.\tID=#{genes_from_list[gene_number]}"
                unless added_genes.include?(a)
                  file.puts a
                  added_genes |= [a]
                end
                c = "#{chr[2]}\t.\tnucleotide_motif\t#{chr[3].to_i+index_ini}\t#{chr[3].to_i+index_fin}\t.\t#{qual["strand"]}\t.\t#{assoc_note}"
                unless added_exons2.include?(c)
                  file.puts c
                  added_exons2 << c
                end
              end
            end
          end
        end
      end
    end
  end
  if gene_ex == 0
    File.open('genes_without_seq.txt', 'a') do |file|
      file.puts "#{genes_from_list[gene_number]}"
    end
  end
end

File.delete("./newgene.embl")
File.delete("./genes.embl")
