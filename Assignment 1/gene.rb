#This file contains the class gene
require "csv"

class Gene

    attr_accessor :gene_id
    attr_accessor :gene_name
    attr_accessor :mutant_phenotype
    attr_accessor :linked_genes
    @@gene_array = [] #gene_array will contain all the objects of the class Gene
    
    def initialize (params = {})
        @gene_id = params.fetch(:Gene_ID, 'unknown ID')
        @gene_id = identifier (@gene_id) #We call the function identifier to check if the gene ID is valid
        @gene_name = params.fetch(:Gene_name, 'unknown name')
        @mutant_phenotype = params.fetch(:mutant_phenotype, 'unknown mutant phenotype')
        @linked_genes = params.fetch(:linked_genes, 'no linked genes')
        @@gene_array << self #Each time we add an object, it goes into gene_array
    end
    
    def identifier (id)
        #This function checks if an ID is a valid gene ID
        #If it is, it returns the ID
        #If it is not, it aborts the program giving an error message
        code = Regexp.new(/A[Tt]\d[Gg]\d\d\d\d\d/)
        if code.match(id)
            return id
        else
            abort "\nERROR: #{id} is not a valid Gene ID"
        end
    end
    
    def Gene.genes ()
        #this class method returns gene_array, so that we can easily access the class Gene objects outside the class
        return @@gene_array
    end
    
    def Gene.gene_from_id (gene_id)
        #This class function receives as input a gene_id, and checks if any object of the class has such ID. If it does, it returns that object. 
        for object in @@gene_array
            if object.gene_id == gene_id
                return object
            end
        end
        abort "\nERROR: the gene with ID #{gene_id} is present in the SeedStock file but not in the Genes file" #If the gene_id doesn't exist, it raises an error
    end
    
end
