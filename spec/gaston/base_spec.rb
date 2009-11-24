require "spec_helper"

module Gaston
  class Doc
    extend Base
    attr_accessor :name, :type
  end

  describe Base do
    before(:each) do
      Hijacker::Database.stub!(:all).and_return([mock("Database", :database => "spec_data")])
      Hijacker.stub!(:current_client).and_return("spec_data")
      @index = double("Index").as_null_object
      @index.stub!(:fields)
      Gaston::Index.stub!(:instance).and_return(@index)
    end

    describe "#define_index" do
      it "passes the correct index into the block" do
        Doc.define_index do |index|
          index.should == @index
        end
      end

      it "registers the fields with the index" do
        @index.should_receive(:fields).with(anything, array_including([:name, :type]))
        Doc.define_index do |index|
          index.fields [:name, :type]
        end
      end
    end

    describe "#search" do
      it "Passes the class name and the search term to the index" do
        @index.should_receive(:search).with(Doc.name, "fancy name", {})
        Doc.search("fancy name")
      end
    end
  end
end
