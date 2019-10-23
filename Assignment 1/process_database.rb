require_relative "SeedStock.rb"
require_relative "Gene.rb"
require_relative "HybridCross.rb"

#####SEEDSTOCK ENTRIES
#I first read the file using CSV.read.
parsed_file = CSV.read(ARGV[1], { :col_sep => "\t" })
#I transform the column which contains the grams left to float type
for i in 1..parsed_file.length-1
    parsed_file[i][4] = parsed_file[i][4].to_i
end
#We create a hash from each line of the document and create a new object of the class with it
for i in 1..parsed_file.length-1
    hash = Hash[parsed_file[0].map(&:to_sym).zip(parsed_file[i])]
    $parsed_file = parsed_file[i][0]
    $parsed_file = SeedStock.new(hash)
end


#####GENE ENTRIES
parsed_file = CSV.read(ARGV[0], { :col_sep => "\t" })

for i in 1..parsed_file.length-1
    hash = Hash[parsed_file[0].map(&:to_sym).zip(parsed_file[i])]
    $parsed_file = parsed_file[i][0]
    $parsed_file = Gene.new(hash)
end

#####PLANTING
#We create the variable seedstock_array, containing the objects of SeedStock class
seedstock_array = SeedStock.seeds()
seeds=[]
#We use the method .plant with seven seeds, and at the same time create an array with the grams left of each object
for i in 0..seedstock_array.length-1
    seeds.push(seedstock_array[i].plant(7))
end
#We take the data from the original file and replace the grams column for the array we've just created
tsv_table = CSV.read(ARGV[1], { :col_sep => "\t" })
for i in 1..tsv_table.length-1
    tsv_table[i][4] = seeds[i-1]
end
#We create the new file
CSV.open(ARGV[3], "wb", col_sep: "\t") do |csv|
    for i in 0..tsv_table.length-1
        csv << tsv_table[i]
    end
end


#####HYBRIDCROSS ENTRIES
parsed_file = CSV.read(ARGV[2], { :col_sep => "\t" })
#We transform the last 4 columns to integer type
for i in 1..parsed_file.length-1
    for j in 2..parsed_file[i].length-1
        parsed_file[i][j] = parsed_file[i][j].to_i
    end
end

for i in 1..parsed_file.length-1
    hash = Hash[parsed_file[0].map(&:to_sym).zip(parsed_file[i])]
    $parsed_file = parsed_file[i][0]
    $parsed_file = HybridCross.new(hash)
end

#LINKED GENES
#Here, we print which genes are linked to each other
puts
puts
puts "Final Report:"
puts
#We create an array with all the objects of Gene class, and then check all of them to see whether they have linked genes
genes_array = Gene.genes()
for object in genes_array
    if object.linked_genes != 'no linked genes'
        print "#{object.gene_name} is linked to "
        for i in 0..object.linked_genes.length-1
            if i == object.linked_genes.length-1
                puts "#{object.linked_genes[i]}"
            elsif i == object.linked_genes.length-2
                print "#{object.linked_genes[i]} and "
            else
                print "#{object.linked_genes[i]}, "
            end
        end
    end
end

puts
print "To prove that the code stops when a gene with an incorret ID is introduced, we create a gene with ID AT434"
Gene.new(:Gene_ID => "AT434",)
