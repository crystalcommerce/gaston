module Gaston
  module Base
    def define_index
      Hijacker::Database.all.each do |client|
        index = Gaston::Index.instance(client.database)
        yield ClassNameProxy.new(index, self.name)
        index.indexed_classes << self
      end
    end

    def search(term, options = {})
      index = Gaston::Index.instance
      index.search(self.name, term, options)
    end
  end
end

ActiveRecord::Base.extend Gaston::Base
