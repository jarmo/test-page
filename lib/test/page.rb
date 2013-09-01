require File.expand_path("page/version", File.dirname(__FILE__))
require 'forwardable'

module Test
  class Page
    extend Forwardable

    def_delegators :element, :present?, :p

    class << self
      # Set and get the browser object for {Page}.
      #
      # This makes it possible to reuse one global browser object between
      # different {Page} objects. It will be also shared between sub-classes of {Page}
      # class.
      #
      # @example Set Watir browser object as the global browser
      #   Test::Page.browser = Watir::Browser.new
      attr_accessor :browser

      # @private
      attr_reader :element_block 

      # Set element for the {Page} via block.
      # It will be evaluated lazily after {Page} has been instantiated.
      #
      # Element is like the container of the {Page} - everything outside of that element
      # is not considered as part of the {Page}.
      # Use as specific element as possible.
      #
      # @example Use Watir::Div as an {element}. 
      #   class MyPage < Test::Page
      #     element { browser.div(:id => "search") }
      #   end
      def element(&block)
        @element_block = block
      end
    end

    attr_writer :browser

    # Set and get the browser object for specific {Page} instance.
    #
    # This is useful if some specific {Page} instance needs a different browser
    # than is set via {.browser} method. Popup browser windows might be
    # one example.
    #
    # If browser is not set via {#browser} then browser set via
    # {.browser} will be used.
    def browser
      @browser || parent_page_browser
    end

    # Get the element instance.
    #
    # When {#setup} is defined, it will be executed once per {Page} instance.
    #
    # @return [Object] if element is specified for {#initialize}.
    # @return [Object] otherwise {.element} block is evaluated once per {Page} instance and its value will be returned.
    # @raise [NoBrowserSetException] if {.element} has been set via block and browser has not been set.
    def element
      @setup_done ||= begin
                        setup if respond_to?(:setup)
                        true
                      end
      @element ||= begin
                     raise_no_browser_set_exception unless browser
                     element_proc = self.class.element_block
                     element_proc && instance_eval(&element_proc)
                   end
    end

    # @param [Object] Element element for the {Page}. {.element} set via block will be used if not specified.
    def initialize(element=nil)
      @element = element
    end

    # Create new {Page} object conveniently on page actions.
    #
    # @param [Page] Page page class to make an instance of
    # @param [Object] Element optional element instance to use as a container.
    def redirect_to(page, element=nil)
      page.new element
    end      

    # Proxies every method call not found on {Page} to element instance.
    # Subsequent executions of the same method will be invoked on the {Page} object directly.
    def method_missing(name, *args)
      begin
        element
      rescue SystemStackError
        raise_invalid_element_definition
      end

      if element.respond_to?(name)
        self.class.send :define_method, name do |*args|
          element.send(name, *args) {yield}
        end
        self.send(name, *args) {yield}
      else
        super
      end
    end

    private

    def parent_page_browser
      page_with_browser = self.class.ancestors.find do |klass|
        klass.respond_to?(:browser) && klass.browser
      end
      page_with_browser ? page_with_browser.browser : nil
    end

    def raise_no_browser_set_exception
      raise NoBrowserSetException.new %q[No browser has been set to the page!

Set it to the class directly:
  Test::Page.browser = browser_instance

Or set it to the instance of page:
  page = MyPage.new
  page.browser = browser_instance]
    end

    def raise_invalid_element_definition
      raise InvalidElementDefinition.new %q[Element defined via block cannot be evaluated, because it is causing SystemStackError.

This is usually caused by the fact that the browser instance is not used to search that element.

For example, this is not a correct way to define an element:
  element { div(:id => "something") }

Correct way would be like this:
  element { browser.div(:id => "something") }]
    end

    NoBrowserSetException = Class.new(RuntimeError)
    InvalidElementDefinition = Class.new(RuntimeError)
  end
end
