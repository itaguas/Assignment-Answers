class Annotation

    attr_accessor :id
    attr_accessor :name
    attr_accessor :clase
    @@annotation_array = [] #annotation_array will contain all the objects of the class Annotation
    @@kegg_array = [] #kegg_array will contain all the objects related to KEGG of the class Annotation
    @@go_array = [] #go_array will contain all the objects related to G of the class Annotation
    
    def initialize(params = {})
        @id = params.fetch(:id, 'unknown ID') #We don't need to check if the ID is correct, because we already checked it in the main program
        @name = params.fetch(:name, 'unknown name')
        @clase = params.fetch(:clase, 'unknown class')
        check_class(self)
        @@annotation_array << self
        if @clase == "KEGG"
            @@kegg_array << self
        elsif @clase == "GO"
            @@go_array << self
        end
    end
    
    def Annotation.create(an_array)
        #Receives as input a hash that contains an ID as key and the name as value
        #Creates a hash with the attributes id and name
        for element in an_array
            khash = {:id => element[0], :name => element[1]}
            Annotation.new(khash) 
        end
    end
    
    def Annotation.array()
        #Returns annotation_array
        return @@annotation_array
    end
    
    def Annotation.kegg()
        #Returns the kegg_array
        return @@kegg_array
    end
    
    def Annotation.go()
        #Returns the go_array
        return @@go_array
    end
    
    def Annotation.annotation_from_id(id)
        #Receives as input an ID
        #Returns the object that contains that ID
        for object in @@annotation_array
            if object.id == id
                return object
            end
        end
    end

    def check_class(object)
        #Receives an object of the class Annotation
        #Sets the class of the attribute as GO or KEGG
        if /GO:\d{7}/ =~ object.id
            object.clase = "GO"
        elsif /[a-z]{2,4}\d{5}/i =~ object.id
            object.clase = "KEGG"
        else
            return
        end
    end
            
end
