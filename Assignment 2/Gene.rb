class Gene

    attr_accessor :gene_id
    attr_accessor :kegg_path #Array containing the KEGG IDs
    attr_accessor :go_p #Array containing the GO IDs
    attr_accessor :at_interactor #Array containing all the IDs of the genes of Arabidopsis thaliana it interacts with
    attr_accessor :gene_depth #Number indicating the "gene depth": for the genes of the list it is 1, for the genes the genes of the list interact with is 2...
    @@gene_array = [] #gene_array will contain all the objects of the class Gene
    @@ids_array = [] #ids_array will contain all the ids of all the objects of the class Gene
    @@ids_int = [] #ids_int will contain all the ids of the objects of the class Gene that interact with other genes
    
    def initialize(params = {})
        @gene_id = params.fetch(:gene_id, 'unknown gene ID')
        @gene_id = identifier (@gene_id) #Calls the identifier method to check if the gene ID is valid
        @@ids_array << self.gene_id
        @kegg_path = params.fetch(:kegg_path, 'not involved in any KEGG pathway')
        @go_p = params.fetch(:go_p, 'no gene ontology annotations for biological processes')
        @at_interactor = params.fetch(:at_interactor, 'this gene does not interact with any other Arabidopsis thaliana gene')
        @gene_depth = params.fetch(:gene_depth, 1)
        if $UP #If the user has indicated so at the start of the program, each gene generates a Protein class object with the gene ID, uniprot ACs and protein ID
            complete_protein(self.gene_id) 
        else #If not, each gene generates a Protein class object just with the gene ID
            phash = {:gene_id => gene_id}
            Protein.new(phash)
        end
        interactions(self) #Calls the interaction methods, that updates the attribute at_accessor
        if $ANOT_ALL || @gene_depth == 1 && $ANOT_LIST || @gene_depth == 1 && @at_interactor.class == Array #The genes the user has indicated at the start are annotated
            Gene.kegg(self) #Calls the kegg method to update the attribute kegg_path
            Gene.go(self) #Calls the go method to update the attribute go_p
        end
        @@gene_array << self
        if self.at_interactor.class == Array #In case the gene interacts at least with one gene
            $interaction_hash[self.gene_id] = self.at_interactor #$interaction_hash is updated
            @@ids_int |= [self.gene_id]
        end
        if self.gene_depth < $DEPTH && self.at_interactor.class == Array #In case the depth of the gene is not yet the maximum depth defined by the user, we create new Gene class objects for its interactors
            add_genes(self.gene_depth, self.at_interactor, self.gene_id)
        end
        
    end
    
    def identifier(id)
        #Receives as input an ID (the attribute gene_id)
        #Checks if an ID is a valid gene ID
        #If it is, it returns the ID. If it is not, it aborts the program giving an error message
        code = Regexp.new(/A[Tt]\d[Gg]\d\d\d\d\d/)
        if code.match(id)
            return id
        else
            abort "\nERROR: #{id} is not a valid Gene ID"
        end
    end
    
    def Gene.genes()
        #Returns an array with all the objects
        return @@gene_array
    end
    
    def Gene.ids()
        #Returns an array with all the gene IDs
        return @@ids_array
    end
    
    def Gene.ids_int()
        #Returns an array with all the gene IDs of genes that have interactions
        return @@ids_int
    end
    
    def Gene.gene_from_id(gene_id)
        #Receives as input a gene_id
        #Checks if any object of the class has such ID
        #If it does, it returns that object. 
        for object in @@gene_array
            if object.gene_id == gene_id
                return object
            end
        end
    end
    
    def Gene.gene_in_class(gene_id)
        #Method similar to gene_from_id, with the only difference that if the ID is in the class returns true, and if it is not returns false
        for object in @@gene_array
            if object.gene_id == gene_id
                return true
            end
        end
        return false
    end
    
    def complete_protein(gene_id)
        #Receives as input a gene ID
        #Creates a Protein class object with attributes gene ID, protein ID and protein ACs
        res = fetch("http://togows.dbcls.jp/entry/uniprot/#{gene_id}/accessions.json")
        if res
            body = JSON.parse(res.body)
            if body[0] != []
                uniprot_ac = body[0][0]
                acs = body[0]
                phash = {:main_prot_ac => uniprot_ac, :list_prot_ac => acs, :gene_id => gene_id}
                protein = Protein.new(phash)
    
                res = fetch("http://togows.org/entry/ebi-uniprot/#{gene_id}/entry_id.json")
                if res
                    body = JSON.parse(res.body)
                    if body[0] != []
                        protein.prot_id = body[0]
                    end
                end
            else
                puts "WARNING: gene #{gene_id} does not have a valid uniprot ID"
            end
        end
    end
    
    
    def Gene.kegg(gene)
        #Receives as input an object of the class gene
        #Updates the attribute kegg_path with all the KEGG IDs
        res = fetch("http://togows.dbcls.jp/entry/genes/ath:#{gene.gene_id}/pathways.json") #ath: is for arabidopsis thaliana
        if res
            body = JSON.parse(res.body)
            if body[0] && body[0] != {}
                gene.kegg_path = body[0].keys
                Annotation.create(body[0])
            end
        end
    end
    
    def Gene.go(gene)
        #Receives as input an object of the class gene
        #Updates the attribute go_p with all the GO IDs
        res = fetch ("http://togows.dbcls.jp/entry/uniprot/#{gene.gene_id}/dr.json")
        if res
            body = JSON.parse(res.body)
            ghash = {}
            if body[0]["GO"]
                for go in body[0]["GO"]
                    if /P:/=~ go[1]
                        /(?<go_id>GO:\d{7})/ =~ go[0]
                        if gene.go_p.class != Array
                            gene.go_p = []
                        end
                        gene.go_p |= [go_id]
                        ghash[go_id]=go[1]
                    end
                end
            end
        end
        Annotation.create(ghash) #Creates an object of the class Annotation, and adds the ID and the names of both KEGG and GO as attributes, and classifies the object as GO or KEGG class
    end

    def interactions(gene)
        #Receives as input an object of the class Gene
        #Annotates in an array all the genes the gene interacts with (including himself, if that is the case), and updates the at_interactor attribute
        res = fetch ("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{gene.gene_id}?format=tab25")
        interactors = []
        $gene_himself = []
        if res != ""
            body = res.body
            if $SCORE
                /intact-miscore:(?<miscore>\d+.\d+)/ =~ res.body
            end
            if $SCORE == false || miscore.to_f >= $MSC
                body = body.split("\n")
                for entry in body
                    body = entry.split("\t")
                    if body[0] == body[1] #Checks if the gene interacts with himself
                        interactors |= [gene.gene_id]
                        $gene_himself |= [gene.gene_id] #$gene_himself will be used to write the final report
                    else
                        /(?<igene>AT[1-5]G\d{5})/i =~ body[5]
                        if igene
                            igene = igene.upcase
                            #Takes into account if the gene is in the first or the second place on each interaction
                            if igene != gene.gene_id
                                interactors |= [igene]
                                @@ids_int |= [igene]
                            else
                                /(?<igene>AT[1-5]G\d{5})/i =~ body[4]
                                if igene
                                    igene = igene.upcase
                                    interactors |= [igene]
                                    @@ids_int |= [igene]
                                    #$graph.add_edge(gene.gene_id,igene.upcase)
                                end
                            end
                        end
                    end
                end
            end
        end
        if interactors != []
            gene.at_interactor = interactors
        end
    end

    def add_genes(gd, interaction_array, id)
        #Takes as input the attributes gene depth, at_interactor and gene_id of an object of the class Gene
        #For each gene ID of interaction_array, if such gene is not already an object, creates an object
        for element in interaction_array
            gene_object = Gene.gene_in_class(element)
            if gene_object #This gene already exists as an object
                gene = Gene.gene_from_id(element)
                #Makes sure that the gene it interacts with has this gene in its at_interactor attribute
                unless gene.at_interactor.class == Array
                    gene.at_interactor = []
                end
                gene.at_interactor |= [id]
            else
                ghash = {:gene_id => element, :gene_depth => gd+1}
                Gene.new(ghash)
            end
        end
    end

    def Gene.annotate(gene_id)
        #Takes as input the gene_id of a Gene class object
        #Calls the methods that update the kegg_path and go_p attributes
        for object in @@gene_array
            if object.gene_id == gene_id
                Gene.kegg(object)
                Gene.go(object)
            end
        end
    end

end