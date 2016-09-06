module VersionEye
  module ProductEsMapping

    def to_indexed_json # For ElasticSearch
      {
        :_id                => self.ids,
        :_type              => 'product',
        :name               => self.name,
        :description        => self.description.to_s,
        :description_manual => self.description_manual.to_s,
        :followers          => self.followers,
        :used_by_count      => self.used_by_count,
        :group_id           => self.group_id.to_s,
        :prod_key           => self.prod_key,
        :language           => self.language,
        :prod_type          => self.prod_type
      }
    end

  end
end
