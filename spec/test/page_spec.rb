require File.expand_path("../spec_helper", File.dirname(__FILE__))
require File.expand_path("../../lib/test/page", File.dirname(__FILE__))

describe Test::Page do
  let(:my_page_class) { Class.new(Test::Page) }

  context ".browser" do
    before { Test::Page.browser = nil }

    it "sets the browser object for page" do
      Test::Page.browser = "my browser"
      Test::Page.browser.should == "my browser"
    end

    it "does not set the browser object for sub-page class" do
      Test::Page.browser = "your browser"
      my_page_class.browser.should be_nil
    end

    it "sets the browser object for sub-page instances" do
      Test::Page.browser = "your browser"
      my_page = my_page_class.new
      my_page.browser.should == "your browser"
    end

    it "can be overridden by sub-page" do
      Test::Page.browser = "their browser"
      my_page_class.browser = "my page browser"
      my_page_class.browser.should == "my page browser"
      Test::Page.browser.should == "their browser"
    end
  end

  context ".element" do
    it "sets the element via block" do
      my_page_class.element { "my element" }
      my_page = my_page_class.new
      my_page.element.should == "my element"
    end
  end

  context "#initialize" do
    it "allows to set element" do
      my_page = my_page_class.new "my special element"
      my_page.element.should == "my special element"
    end
  end

  context "#element" do
    it "evaluates element provided by the block only once per instance" do
      block_called = false
      my_page_class.element do
        raise "block should have been called only once!" if block_called
        block_called = true
        "my element in block"
      end
      my_page = my_page_class.new
      2.times { my_page.element.should == "my element in block" }
      block_called.should be_true
    end
  end

  context "#setup" do
    it "is called only once if page has method defined" do
      block_called = false
      my_page_class.send :define_method, :setup do
        raise "block should have been called only once!" if block_called
        block_called = true
        @element = "element via setup"
      end
      my_page = my_page_class.new
      2.times { my_page.element.should == "element via setup" }
      block_called.should be_true
    end
  end

  context "#modify" do
    let(:my_modified_page_class) do
      my_page_class.send :define_method, :something do
        modify Hash.new,
          :action => proc { "hi" },
          :store => proc { |a, b| a + b }
      end      
      my_page_class
    end

    it "returns the instance of the original object" do
      my_page = my_modified_page_class.new
      my_page.something.should == {}
    end

    it "allows to modify default behavior of the instance's methods" do
      my_page = my_modified_page_class.new
      my_page.something.store(1, 2).should == 3
    end

    it "executes the original instance method too" do
      my_page = my_modified_page_class.new
      result = my_page.something
      result.store 1, 2
      result.should == {1 => 2}
    end

    it "modifies only singleton instance methods, leaving original class intact" do
      my_page = my_modified_page_class.new
      result = my_page.something
      result.store(1, 2).should == 3

      original_hash = Hash.new
      original_hash.store(1, 2).should == 2
      original_hash.should == {1 => 2}
    end

    it "allows to add new methods too" do
      my_page = my_modified_page_class.new
      my_page.something.action.should == "hi"
    end
  end

  context "#redirect_to" do
    it "returns the new page instance" do
      second_page = Class.new(Test::Page)
      my_page_class.send(:define_method, :redirect_me) { redirect_to second_page }
      my_page = my_page_class.new
      my_page.redirect_me.should be_an_instance_of(second_page)
    end

    it "reuses the existing page element" do
      second_page = Class.new(Test::Page)
      my_page_class.send(:define_method, :redirect_me) { redirect_to second_page }
      my_page = my_page_class.new "provided element"
      redirected_page = my_page.redirect_me
      redirected_page.element.should == "provided element"
    end

    it "is possible to specify new element" do
      second_page = Class.new(Test::Page)
      my_page_class.send(:define_method, :redirect_me) { redirect_to second_page, "new element" }
      my_page = my_page_class.new "provided element"
      redirected_page = my_page.redirect_me
      redirected_page.element.should == "new element"
    end

  end  

  context "#method_missing" do
    it "calls all missing methods on element object" do
      my_page = my_page_class.new "element"
      my_page.should_not respond_to(:size)
      my_page.size.should == "element".size
    end

    it "defines methods to the page class" do
      my_page = my_page_class.new "element"
      my_page.should_not respond_to(:size)
      my_page.size
      my_page.should respond_to(:size)
    end

    it "will raise a NoMethodError if no method is found on element" do
      expect { my_page_class.new("element").foo }.to raise_error(NoMethodError)
    end
  end
end

