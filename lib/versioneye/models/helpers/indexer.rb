class Indexer


  def self.create_indexes
    ::Mongoid.models.each do |model|
      index_keys = model.collection.indexes.map{ |doc| doc["name"] }
      next if index_keys.empty?
      next if model.embedded?

      create_index model     
    end.compact
  rescue => e
    p e.message
    p e.backtrace.join("\n")
  end


  def self.create_index model 
    result = model.create_indexes
    p "#{model} .. #{result}"
  rescue => e 
    p e.message
    p e.backtrace.join("\n")
  end


  def self.drop_indexes
    ::Mongoid.models.each do |model|
      next if model.embedded?
      
      result = model.remove_indexes
      p "#{model} .. #{result}"
    end.compact
  rescue => e
    p e.message
    p e.backtrace.join("\n")
  end


end
