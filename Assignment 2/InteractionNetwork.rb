class InteractionNetwork < Network
  
  attr_accessor :subnet_of
  @@interactionnetwork_array = []
  @@netted_genes = []
  
  def initialize (params = {})
    @subnet_of = params.fetch(:subnet_of, 'the complete net is unknown')
    @net = params.fetch(:network, 'no net stored')
    @genes_involved = params.fetch(:genes_involved, 'Patata')
    for object in @genes_involved
      @@netted_genes |= [object]
    end
    @@interactionnetwork_array << self
  end
  
  def InteractionNetwork.nets_array()
    return @@interactionnetwork_array
  end
  
  def InteractionNetwork.involved_genes()
    return @@netted_genes
  end
  
  def InteractionNetwork.subnet_from_gene(gene_id)
    for object in @@interactionnetwork_array
      if object.genes_involved.include?(gene_id)
        return object
      end
    end
  end
  
end