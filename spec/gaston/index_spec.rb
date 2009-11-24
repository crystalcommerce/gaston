require "spec_helper"

module Gaston
  describe Index do
    before(:each) do
      Hijacker.stub!(:current_client).and_return("spec_house_cards")
    end

    it "prevents instantiation" do
      lambda { Index.new }.should raise_error
    end

    it "delegates rebuild to the correct index" do
      index = double("Index")
      Index.stub!(:instance).and_return(index)

      index.should_receive(:rebuild)
      Index.rebuild
    end

    describe "#instance" do
      it "finds the client from the Hijacker" do
        Hijacker.should_receive(:current_client)
        Index.instance
      end

      it "returns an existing index for the client if there is one" do
        index = double("Spec index")
        Index.store[Hijacker.current_client] = index
        Index.instance.should == index
      end
      
      it "creates an index for the client if there isn't one" do
        index = double("Spec index")
        Index.index_type.stub!(:new).and_return(index)
        Index.instance.should == index
      end

      it "puts created indexes in the store" do
        index = double("Spec index")
        Index.index_type.stub!(:new).and_return(index)
        Index.instance
        Index.store[Hijacker.current_client].should == index
      end

      after(:each) do
        Index.store.clear
      end
    end

    context "updating the index" do
      before(:each) do
        # We're going to cheat so it indexes in memory
        @index = Index.send(:new, "spec_house_cards")
        @index.indexed_classes << Product
        @ferret_index = mock("ferret index").as_null_object
        @index.stub!(:ferret_index).and_return(@ferret_index)
      end

      describe "#rebuild" do
        it "adds a document for every row of every class" do
          mock1 = mock("product", :id => 5).as_null_object
          mock2 = mock("product", :id => 7).as_null_object
          Product.stub!(:all).and_return([mock1, mock2])

          @ferret_index.should_receive(:<<).exactly(2).times
          @index.rebuild
        end

        it "adds a field for every field specified" do
          mock = mock("product", :id => 5, :class => Product).as_null_object
          Product.stub!(:all).and_return([mock])

          @index.fields "Product", [:name, :value]
          @ferret_index.should_receive(:<<).with(hash_including(:name => anything,
                                                                :value => anything))
          @index.rebuild
        end

        it "gets the fields info from the database rows" do
          mock = mock("product", :name => "Spec Product", :id => 6, :class => Product).as_null_object
          Product.stub!(:all).and_return([mock])

          @index.fields "Product", [:name]
          @ferret_index.should_receive(:<<).with(hash_including(:name => "Spec Product"))
          @index.rebuild
        end
      end

      describe "#update" do
        it "adds the updated object to the ferret index" do
          product = mock("product", :id => 6).as_null_object
          @ferret_index.should_receive(:add_document).with(hash_including(:id => 6))
          @index.update(product)
        end
      end
    end
  end
end
