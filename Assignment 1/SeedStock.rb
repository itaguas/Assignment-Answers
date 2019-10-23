require "csv"

class SeedStock

    attr_accessor :seed_stock
    attr_accessor :mutant_gene_id
    attr_accessor :last_planted
    attr_accessor :storage
    attr_accessor :grams_remaining
    @@seedstock_array = [] #seedstock_array will contain all the objects of the class SeedStock
    
    def initialize (params = {})
        @seed_stock = params.fetch(:Seed_Stock, 'unknown stock')
        @mutant_gene_id = params.fetch(:Mutant_Gene_ID, 'unknown gene ID')
        @last_planted = params.fetch(:Last_Planted, 'unknown date of plantation')
        @storage = params.fetch(:Storage, 'unknown storage')
        @grams_remaining = params.fetch(:Grams_Remaining, 'unknown grams remaining')
        @@seedstock_array << self #Each time we add an object, it goes into seedstock_array
    end
    
    def SeedStock.seeds ()
        #this class method returns seedstock_array, so that we can easily access the class SeedStock objects outside the class
        return @@seedstock_array
    end
    
    def SeedStock.gene_from_seed (seed_stock)
        #This class function receives as input a seed_stock, and checks if any object of the class has such seed_stock. If it does, it returns the mutant_gene_id of that object.
        for object in @@seedstock_array
            if object.seed_stock == seed_stock
                return object.mutant_gene_id
            end
        end
        abort "\nERROR: the seed #{seed_stock} is present in the HybridCross file but not in the SeedStock file" #If the seed_stock doesn't exist, it raises an error
    end
    
    def plant (n)
        #This method allows thte planting of a number n of seeds on the object
        case
            when n<@grams_remaining
                @grams_remaining = @grams_remaining - n
            #When the number of grams remaining is 0, a warning is printed
            when n==@grams_remaining
                @grams_remaining=0
                puts "WARNING: we have run out of SeedStock #{@seed_stock}"
            #When the number of grams remaining would be lower than 0, it sets to 0 and prints a warning message, as well as how many grams were planted
            when n>@grams_remaining
                a = @grams_remaining
                @grams_remaining=0
                puts "WARNING: we have run out of SeedStock #{@seed_stock}. Only #{a} grams were planted"
        end
        return @grams_remaining
    end
    
end
