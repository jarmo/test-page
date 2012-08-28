require File.expand_path("../../lib/test/page", File.dirname(__FILE__))

describe Test::Page do
  context ".new" do
    it "allows to specify the container" do
      page = DummyPage.new :container
      page.container.should == :container
    end
  end

  context "#modify" do
    it "returns the instance of the object" do
      page = DummyPage.new nil
      page.something.should == {}
    end

    it "allows to modify default behavior of the instance's methods" do
      page = DummyPage.new nil
      page.something.store(1, 2).should == 3
    end

    it "executes the original method too" do
      page = DummyPage.new nil
      res = page.something
      res.store(1, 2)
      res.should == {1 => 2}
    end

    it "doesn't modify instance methods of the class itself" do
      h = Hash.new
      h.store(1, 2).should == 2
      h.should == {1 => 2}
    end

    it "allows to add new methods too" do
      page = DummyPage.new nil
      page.something.new_method.should == []
    end
  end

  context "#redirect_to" do
    it "redirects to the new page using the provided container" do
      page = DummyPage.new nil
      new_page = page.something.another_page :container
      new_page.container.should == :container
    end
  end

  context "#method_missing" do
    it "redirects all missing methods to container object" do
      page = DummyPage.new []
      page.should_not respond_to(:empty?)
      page.should be_empty
    end
  end

  class DummyPage < Test::Page
    def something
      modify Hash.new,
        :store => lambda {|a,b| a + b},
        :new_method => lambda {[]},
        :another_page => lambda {|container| redirect_to AnotherDummyPage, container}
    end
  end

  class AnotherDummyPage < Test::Page
  end
end

