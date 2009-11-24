module Gaston
  class SimpleIndex < Index

    # Override to store on disk
    # TODO: how can we inherit just the key/create info?
    def ferret_index(create = false)
      # I know we are passing :field_infos => nil if not creating, but that
      # parameter is ignored in that case anyway
      Ferret::Index::Index.new(:path        => index_path,
                               :key         => [:ferret_class, :id],
                               :create      => create)
    end

    def index_path
      "#{RAILS_ROOT}/tmp/indexes/#{RAILS_ENV}/#{client}"
    end
  end
end
