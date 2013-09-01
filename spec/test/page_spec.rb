require File.expand_path("../spec_helper", File.dirname(__FILE__))
require File.expand_path("../../lib/test/page", File.dirname(__FILE__))

describe Test::Page do
  let(:page_class) { Class.new(Test::Page) }
  before { Test::Page.browser = nil }

  context ".browser" do
    it "sets the browser object for page" do
      Test::Page.browser = "my browser"
      Test::Page.browser.should == "my browser"
    end

    it "does not set the browser object for sub-page class" do
      Test::Page.browser = "your browser"
      page_class.browser.should be_nil
    end

    it "sets the browser object for sub-page instances" do
      Test::Page.browser = "your browser"
      page = page_class.new
      page.browser.should == "your browser"
    end

    it "can be overridden by sub-page" do
      Test::Page.browser = "their browser"
      page_class.browser = "my page browser"
      page_class.browser.should == "my page browser"
      Test::Page.browser.should == "their browser"
    end
  end

  context ".element" do
    before { page_class.browser = "foo" }

    it "sets the element via block" do
      page_class.element { "my element" }
      page = page_class.new
      page.element.should == "my element"
    end
  end

  context "#initialize" do
    it "allows to set element" do
      page = page_class.new "my special element"
      page.element.should == "my special element"
    end
  end

  context "#element" do
    it "evaluates element provided by the block only once per instance" do
      page_class.browser = "foo"
      block_called = false
      page_class.element do
        raise "block should have been called only once!" if block_called
        block_called = true
        "my element in block"
      end
      page = page_class.new
      2.times { page.element.should == "my element in block" }
      block_called.should be_true
    end

    it "raises an exception if browser is not set" do
      page_class.element { "whatever" }

      expect {
        page_class.new.element
      }.to raise_error(Test::Page::NoBrowserSetException)
    end

    it "raises an exception if element is set via block without using browser" do
      page_class.element { foo_bar }
      page_class.browser = "foo"

      expect {
        page_class.new.element
      }.to raise_error(Test::Page::InvalidElementDefinition)
    end
  end

  context "#setup" do
    it "is called only once if page has method defined" do
      block_called = false
      page_class.send :define_method, :setup do
        raise "block should have been called only once!" if block_called
        block_called = true
        @element = "element via setup"
      end
      page = page_class.new
      2.times { page.element.should == "element via setup" }
      block_called.should be_true
    end
  end

  context "#redirect_to" do
    it "returns the new page instance" do
      second_page = Class.new(Test::Page)
      page_class.send(:define_method, :redirect_me) { redirect_to second_page }
      page_class.browser = "foo"
      page = page_class.new
      page.redirect_me.should be_an_instance_of(second_page)
    end

    it "is possible to specify new element" do
      second_page = Class.new(Test::Page)
      page_class.send(:define_method, :redirect_me) { redirect_to second_page, "new element" }
      page = page_class.new "provided element"
      redirected_page = page.redirect_me
      redirected_page.element.should == "new element"
    end

  end  

  context "#method_missing" do
    it "calls all missing methods on element object" do
      page = page_class.new "element"
      page.should_not respond_to(:size)
      page.size.should == "element".size
    end

    it "defines methods to the page class" do
      page = page_class.new "element"
      page.should_not respond_to(:size)
      page.size
      page.should respond_to(:size)
    end

    it "defined methods to the page class will invoke methods on new element instance too" do
      page = page_class.new "element"
      page.size
      el = page.element
      el.instance_eval do
        singleton = class << self; self end
        singleton.send(:define_method, :size) { raise "not expected to call this!" }
      end

      page.instance_variable_set :@element, "new element"
      expect {
        page.size
      }.not_to raise_error
    end

    it "will raise a NoMethodError if no method is found on element" do
      expect { page_class.new("element").foo }.to raise_error(NoMethodError)
    end
  end
end

