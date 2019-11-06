def fetch(url, headers = {accept: "*/*"}, user = "", pass="")
  response = RestClient::Request.execute({
    method: :get,
    url: url.to_s,
    user: user,
    password: pass,
    headers: headers})
  return response
  
  rescue RestClient::ExceptionWithResponse => e
    $stderr.puts e.response
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  rescue RestClient::Exception => e
    $stderr.puts e.response
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  rescue Exception => e
    $stderr.puts e
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
end

def ask_prot()
  puts "Each object of the gene class automatically generates an object of the Protein class. Would you like to retrieve the Uniprot accession number and the ID of the proteins corresponding to each gene? (y/n)"
  answer = gets
  if answer.upcase == "Y\n"
    $UP = true
  elsif answer.upcase == "N\n"
    puts "Neither Uniprot accession number nor ID will be retrieved; they can be retrieved using the funcitons Protein.retrieve_ac(gene_id) and Protein.retrieve_id(gene_id), respectively"
  else
    puts "Please, answer 'y' for yes and 'n' for no"
    ask_prot()
  end
end

def ask_gene()
  puts "Would you like to anotate:\na) Just the genes from the list that interact with other genes; this is the recommended option, since the genes of interest for this task are the ones that interact with others (write 'a')\nb) All the genes from the list (write 'b')\nc) All the genes from the list and all its interactions (write 'c')"
  answer = gets
  if answer.upcase == "C\n"
    puts "All the genes will be annotated"
    $ANOT_ALL = true
  elsif answer.upcase == "B\n"
    puts "All the genes from the list will be annotated. Other genes can be annotated using the class method Gene.annotate(gene_id)"
    $ANOT_LIST = true
  elsif answer.upcase == "A\n"
    puts "Just the genes with interactions from the list will be annotated. Other genes can be annotated using the class method Gene.annotate(gene_id)"
  else
    puts "Please, answer 'a' for option a, 'b' for option b and 'c' for option c"
    ask_gene()
  end
end

def ask_score()
  puts "Would you like to apply a MIscore filter to the interactions? (y/n)"
  answer = gets
  if answer.upcase == "Y\n"
    $SCORE = true
    $MSC = 0.485
    puts "The MIscore filter has been set to 0.485"
  elsif answer.upcase == "N\n"
    $SCORE = false
    puts "No filter has been set"
  else
    puts "Please, answer 'y' for yes and 'n' for no"
    ask_score()
  end
end


def define_depth()
  puts "How deep do you want to go?"
  answer = gets
  unless answer.to_i > 0
    puts "Please, answer with an integer greater than 0 (2, for instance)"
    define_depth()
  else
    $DEPTH = answer.to_i
  end
end

def print_report()
  report = File.new("FINAL REPORT", "w")
  report.puts "-------------------------- REPORT --------------------------"
  report.puts
  iarray = InteractionNetwork.nets_array()
  net_number = 0
  for object in iarray
    num = 0
    for element in $genes_from_list
      if object.genes_involved.include?(element)
        if $gene_himself.include?(element)
          num = 2
          report.puts
          report.puts "If a network with just one gene appears, it means that such gene interacts with himself"
          report.puts
          report.puts
        end
        num = num + 1
      end
    end
    if num > 1
      net_number = net_number + 1
      report.puts "Genes that interact on network #{net_number} are:"
      for element in $genes_from_list
        if object.genes_involved.include?(element)
          gene = Gene.gene_from_id(element)
          report.puts "\t#{gene.gene_id}"
          report.puts "\t\tKEGG annotation of this gene: #{gene.kegg_path}"
          report.puts "\t\tGO annotation of this gene: #{gene.go_p}"
          report.puts "\t--------------------------------------------"
        end
      end
    end
  end
  report.puts
  report.puts "=============================================================="
end