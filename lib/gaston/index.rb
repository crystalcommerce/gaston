module Gaston
  class Index
    attr_accessor :client, :indexed_classes
    cattr_writer :index_type

    # Returns an instance of Gaston::Index
    # This instance will be a subclass of Gaston::Index
    # TODO: pull out this logic so the type of index can be more easily configured.
    def self.instance(clientname = nil)
      clientname ||= Hijacker.current_client
      index = store[clientname]
      if index.nil?
        index = index_type.send(:new, clientname)
        store[clientname] = index
      end
      index
    end

    def self.store
      @@store ||= {}
    end

    # Rebuild the current search index.
    # This will index any objects that have been registered with
    # the index at this point
    def self.rebuild
      instance.rebuild
    end

    def self.index_type
      @@index_type ||= Gaston::SimpleIndex
    end

    def self.update(product)
      instance.update(product)
    end

    def rebuild()
      idx = ferret_index(true)
      with_ferret_index(idx) do |f_idx|
        indexed_classes.each do |clazz|
          clazz.find_in_batches do |objects|
            objects.each do |row|
              f_idx << make_document(row)
            end
          end
        end
        f_idx.optimize
      end
    end

    def search(classname, term, options = {})
      results = []
      query = make_query(classname, term)
      with_ferret_index do |f_idx|
        f_idx.search_each(query, :limit => 500) do |doc_id, score|
          doc = f_idx[doc_id]
          results << doc[:id]
        end
      end
      options.merge!( :order => "field(id,#{results.join(',')})" )
      objs = classname.constantize.find(results, options)
      SearchResults.new(results.size, objs)
    end

    def update(product)
      with_ferret_index do |f_idx|
        f_idx.add_document(make_document(product))
      end
    end

    def make_query(classname, term)
      query = "(ferret_class:#{classname}) AND (name|category_name:\"#{term}\"^100.0"
      term.split(/\s+/).each do |t|
        query << " (name|category_name:#{t}^50.0 name|category_name:#{t}~0.7)"
      end
      query << ")"
      query
    end

    def make_document(record)
      @fields[record.class.name] ||= []
      document = @fields[record.class.name].inject({}){ |h, f| h[f] = record.send(f); h }
      document[:ferret_class] = record.class.name
      document[:id] = record.id
      document
    end

    def with_ferret_index(idx = nil)
      f = idx || ferret_index
      yield f
      f.close
    end

    def ferret_index(create = false)
      Ferret::Index::Index.new(:key => [:ferret_class, :id], :create => create)
    end

    def fields(classname, field_list)
      fi = ferret_index.field_infos
      field_list.each do |field|
        unless @fields[classname].include?(field)
          @fields[classname] << field
        end
      end
    end

    private_class_method :new

    private

    def initialize(client)
      @client = client
      @fields = Hash.new { |h, k| h[k] = [] }
      @indexed_classes = []
    end
  end
end
