require 'spec_helper'

module Gaston
  describe ClassNameProxy do
    it "passes unknown method calls to the wrapped index" do
      index = mock("index")
      proxy = ClassNameProxy.new(index, Object.name)
      
      index.should_receive(:unknown_method).with(2, "args")
      proxy.unknown_method(2, "args")
    end

    it "augments the fields with the classname" do
      index = mock("index")
      proxy = ClassNameProxy.new(index, Product.name)
      
      index.should_receive(:fields).with(Product.name, [:name, :category_name])
      proxy.fields [:name, :category_name]
    end

    it "is == with the wrapped index class" do
      index = mock("index")
      proxy = ClassNameProxy.new(index, Product.name)
      proxy.should == index
    end
  end
end
