module Gaston
  class ClassNameProxy
    def initialize(index, classname)
      @index = index
      @classname = classname
    end 

    def fields(field_list)
      @index.fields(@classname, field_list)
    end

    def ==(other)
      self.eql?(other) || @index == (other)
    end

    def method_missing(sym, *args, &block)
      @index.send(sym, *args, &block)
    end
  end
end
