class Protein

    attr_accessor :main_prot_ac #Contains the first accession number of the protein
    attr_accessor :list_prot_ac #Contains the rest accession numbers of the protein
    attr_accessor :prot_id
    attr_accessor :gene_id
    @@prot_array = [] #protein_array will contain all the objects of the class Gene
    
    def initialize(params = {})
        @main_prot_ac = params.fetch(:main_prot_ac, 'unknown uniprot accession number') #We don't need to check if the ID is correct, because we already checked it in the main program
        @list_prot_ac = params.fetch(:list_prot_ac, 'unknown uniprot accession numbers')
        @prot_id = params.fetch(:prot_id, 'unknown protein ID')
        @gene_id = params.fetch(:gene_id, 'unknown gene ID')
        @@prot_array << self
    end
    
    def Protein.proteins()
        #Returns prot_array
        return @@prot_array
    end
    
    def Protein.prot_from_ac(prot_ac)
        #Receives as input a uniprot AC
        #Checks if any object of the class has such ID
        #If it does, it returns that object.
        for object in @@prot_array
            if object.list_prot_ac.include? prot_ac
                return object
            end
        end
    end
    
    def Protein.prot_from_geneid(gene_id)
        #Receives as input a gene ID
        #checks if any object of the class has such ID
        #If it does, it returns that object.
        for object in @@prot_array
            if object.gene_id == gene_id
                return object
            end
        end
    end
    
    def Protein.retrieve_ac(gene_id)
        #Receives as input a gene ID
        #Updates the attribute prot_id
        for object in @@prot_array
            if object.gene_id == gene_id
                res = fetch("http://togows.dbcls.jp/entry/uniprot/#{object.gene_id}/accessions.json")
                if res
                    body = JSON.parse(res.body)
                    if body[0] != []
                        object.main_prot_ac = body[0][0]
                        object.list_prot_ac = body[0]
                    end
                end
            end
        end
    end
    
    def Protein.retrieve_id(gene_id)
        #Receives as input a gene ID
        #Updates the attributes main_prot_ac and list_prot_ac
        for object in @@prot_array
            if object.gene_id == gene_id
                res = fetch("http://togows.org/entry/ebi-uniprot/#{object.gene_id}/entry_id.json")
                if res
                    body = JSON.parse(res.body)
                    if body[0] != []
                        object.prot_id = body[0]
                    end
                end
            end
        end
    end

end