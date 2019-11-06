class Network
  
  attr_accessor :net
  attr_accessor :genes_involved
  @@network_array = []
  
  def initialize(params = {})
    ids_array_int = Gene.ids_int()
    @net = Network.create_graph(ids_array_int, $interaction_hash, self)
    @genes_involved = @net.vertices
    @@network_array << self
    subnetwork(self.net) #Creates the corresponding objects of the subclass InteractionNetwork
  end
  
  def Network.net_array
    #Returns network_array
    return @@network_array
  end
  
  def Network.net_from_gene(gene_id)
    #Receives as input a gene ID
    #Checks if the gene ID is involved in a network
    #If it does, returns the network
    for object in @@network_array
      if object.genes_involved.include?(gene_id)
        return object
      end
    end
  end
  
  require 'rgl/dot'
  require 'rgl/path'
  require 'rgl/implicit'
  require 'rgl/traversal'
  
  def Network.create_graph(ids_array, interaction_hash, net)
    #Function that, using the rgl gem, creates an Implicit graph
    #Receives an array of gene ids (the nodes), the interaction hash (the edges), and an object of the class Network
    #Returns a network
    RGL::ImplicitGraph.new { |g|
      g.vertex_iterator { |b| ids_array.each(&b) }
      g.adjacent_iterator { |x, b|
        if interaction_hash[x].class != NilClass #I had to add this check because otherways, the method bfs_search_tree_from(object) (used in the subnetwork method below)
          interaction_hash[x].each { |y|
            b.call(y)
          }
        end
      }
      g.directed = false
    }
  end
  
  def subnetwork(net)
    #Receives as input an object of the class Network
    #Creates InteractionNetwork objects: one for each graph that is independent in the Network object
    i=0
    for object in $genes_from_list #Takes every gene of the list
      if net.has_vertex?(object) #Checks if the gene is in the network
        neted_genes = InteractionNetwork.involved_genes() #neted_genes is an array with the genes that are already involved in an InteractionNetwork object
        unless neted_genes.include?(object) #If the gene is in neted_genes, it goes on to the next
          i=i+1
          #I create variables such as tree1 and subtree1 for each object, for some reason I did not understand, even though the objects of InteractionNetwork are correctly created, after each object is added the @net attribute of all the other objects is changed to be the same
          var_name = "@tree#{i}"
          var_name_2 = "@subtree#{i}"
          instance_variable_set(var_name, net.bfs_search_tree_from(object)) #Takes all the nodes connected to the gene
          instance_variable_set(var_name_2, net.vertices_filtered_by {|v| eval("#{var_name}").has_vertex? v}) #Creates a graph with this nodes
          snhash = {:subnet_of => net, :network => eval("#{var_name_2}"), :genes_involved => eval("#{var_name_2}").vertices}
          InteractionNetwork.new(snhash)
        end
      end
    end
    j=0
    #Corrects the @net attribute of the objects of InteractionNetwork
    iarray=InteractionNetwork.nets_array()
    for object in iarray
      j=j+1
      object.net = eval("@tree#{j}")
    end
  end
  
  def create_file()
    #Function that creates a file called GRAPH containing the graph
    file = File.new("GRAPH", "w")
    self.net.print_dotted_on(params = {}, s = file)
  end
  
end