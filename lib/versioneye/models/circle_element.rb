class CircleElement < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  # This attributes describe to which product
  # this circle_element belongs to. Parent!
  # This fields are only important if you wanan store the
  # instance to DB. Otherwise they can be empty!
  field :language           , type: String
  field :prod_key           , type: String
  field :prod_version       , type: String
  field :prod_scope         , type: String

  # This attributes describe the circle_element itself!
  field :dep_prod_key       , type: String, :default => ''
  field :version            , type: String, :default => ''
  field :text               , type: String, :default => ''
  field :connections_string , type: String
  field :dependencies_string, type: String
  field :level              , type: Integer, :default => 1

  attr_accessor :connections, :dependencies


  def self.fetch_circle(language, prod_key, version, scope)
    CircleElement.where(language: language, prod_key: prod_key, prod_version: version, prod_scope: scope)
  end


  def init_arrays
    self.connections  = Array.new
    self.dependencies = Array.new
  end


  def self.store_circle(circle, lang, prod_key, version, scope)
    circle.each do |key, element|
      element.language            = lang
      element.prod_key            = prod_key
      element.prod_version        = version
      element.prod_scope          = scope
      element.connections_string  = element.connections_as_string
      element.dependencies_string = element.dependencies_as_string
      element.save
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  def connections_as_string
    response = ""
    return response if connections.nil? or connections.empty?
    connections.each do |conn|
      response += "\"#{conn}\","
    end
    end_pos = response.size - 2
    response[0..end_pos]
  end


  def dependencies_as_string
    response = ""
    return response if dependencies.nil? or dependencies.empty?
    dependencies.each do |dep|
      response += "\"#{dep}\","
    end
    end_pos = response.size - 2
    response[0..end_pos]
  end


  def as_json(options = {})
    {
      :text        => self.text,
      :id          => self.dep_prod_key,
      :connections => self.connections
    }
  end


end
