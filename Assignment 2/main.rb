require 'rest-client'
require 'json'
require_relative "Gene.rb"
require_relative "Protein.rb"
require_relative "Annotation.rb"
require_relative "functions.rb"
require_relative "Network.rb"
require_relative "InteractionNetwork.rb"

ask_prot()
ask_gene()
ask_score()
define_depth()
puts puts puts

$interaction_hash = {} #Hash that contains all the genes that have interactions as keys, and an array with their interactions as values
$genes_from_list = [] #Array containing all the genes of the list
File.readlines("./ArabidopsisSubNetwork_GeneList.txt").each do |line|
  line = line.delete_suffix("\n")
  $genes_from_list |= [line.upcase]
  ghash = {:gene_id => line.upcase}
  puts "Working on gene #{ghash[:gene_id]}"
  Gene.new(ghash)
end

puts "All the genes have been annotated, now the networks will be generated"
Network.new()
net_array = InteractionNetwork.nets_array()
puts "#{net_array.length} graphs were generated"

print_report()
