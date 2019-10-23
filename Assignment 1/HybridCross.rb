#This file contains the class HybridCross
require "csv"

class HybridCross

    attr_accessor :parent1
    attr_accessor :parent2
    attr_accessor :f2_wild
    attr_accessor :f2_p1
    attr_accessor :f2_p2
    attr_accessor :f2_p1p2
    @@hybridcross_array = [] #hybridcross will contain all the objects of the class HybridCross
    
    def initialize (params = {})
        @parent1 = params.fetch(:Parent1, 'parent 1 unknown')
        @parent2 = params.fetch(:Parent2, 'parent 2 unknown')
        @f2_wild = params.fetch(:F2_Wild, 'f2 wild unknown')
        @f2_p1 = params.fetch(:F2_P1, 'f2-p1 unknown')
        @f2_p2 = params.fetch(:F2_P2, 'f2-p2 unknown')
        @f2_p1p2 = params.fetch(:F2_P1P2, 'f2-p1p2 unknown')
        #I call the method linked genes, to check if the two genes represented in this object are linked
        linked_genes @parent1, @parent2, @f2_wild, @f2_p1, @f2_p2, @f2_p1p2
        @@hybridcross_array << self #Each time we add an object, it goes into gene_array
    end
    
    def HybridCross.crosses ()
        #this class method returns gene_array, so that we can easily access the class Gene objects outside the class
        return @@hybridcross_array
    end
    
    #This method checks if the two genes are linked
    def linked_genes (parent1, parent2, w, p1, p2, p)
        #First, we perform a chi square test
        observed = [w.to_f, p1.to_f, p2.to_f, p.to_f]
        total =  observed[0] + observed[1] + observed[2] + observed[3]
        expected = [total*9/16, total*3/16, total*3/16, total*1/16]
        chi = 0
        for i in 0..3
            val = ((observed[i]-expected[i])**2)/expected[i]
            chi = chi + val
        end
        case
            when chi>7.815 #Given three degrees of freedom, a p-value of 0.05 corresponds to 7.815
                #First, we call the method SeedStock.gene_from_seed, which using the seed stock returns the ID of the associated gene
                mutant_gene_1 = SeedStock.gene_from_seed(parent1)
                mutant_gene_2 = SeedStock.gene_from_seed(parent2)
                #Then, we call the method Gene.gene_from_id, which using the gene ID returns the corresponding gene
                gene_1 = Gene.gene_from_id(mutant_gene_1)
                gene_2 = Gene.gene_from_id(mutant_gene_2)
                #We add the linked gene to the gene_name property
                if gene_1.linked_genes == 'no linked genes'
                    gene_1.linked_genes = [gene_2.gene_name]
                else
                    gene_1.linked_genes.push(gene_2.gene_name)
                end
                if gene_2.linked_genes == 'no linked genes'
                    gene_2.linked_genes = [gene_1.gene_name]
                else
                    gene_2.linked_genes.push(gene_1.gene_name)
                end
                #Prints which genes are linked
                puts "RECORDING: #{gene_1.gene_name} is genetically linked to #{gene_2.gene_name} with chisquare score #{chi}"
        end
    end
    
end
