class Indexer


  def self.create_indexes
    ::Mongoid.models.each do |model|
      next if model.embedded?

      create_index model
    end.compact
  rescue => e
    p e.message
    p e.backtrace.join("\n")
  end


  def self.create_index model
    p "creating index for #{model}"
    p model.create_indexes
  rescue => e
    p e.message
    p e.backtrace.join("\n")
  end


  def self.drop_indexes
    ::Mongoid.models.each do |model|
      next if model.embedded?

      p "drop indexes for #{model}"
      p model.remove_indexes
    end.compact
  rescue => e
    p e.message
    p e.backtrace.join("\n")
  end


end
