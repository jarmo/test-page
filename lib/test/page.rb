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
    def element
      @setup_done ||= begin
                        setup if respond_to?(:setup)
                        true
                      end
      @element ||= begin
                     element_proc = self.class.element_block
                     element_proc && instance_eval(&element_proc)
                   end
    end

    # @param [Object] Element element for the {Page}. {.element} set via block will be used if not specified.
    def initialize(element=nil)
      @element = element
    end

    # Add or modify element instance methods.
    #
    # When element does not have the specified method then that method will be
    # added to the specific element instance.
    # When element has specified method it will be invoked before invoking the
    # specified method.
    #
    # @example Add #png? method to Watir::Image
    #   class Gallery < Test::Page
    #     def thumbnail
    #       image = img(:id => "thumbnail")
    #       modify image,
    #         :png? => proc { File.extname(image.src).downcase == ".png" }
    #     end
    #   end
    #
    #   Gallery.new.thumbnail.png? # returns true for images, which have
    #                              # the src attribute set to png.
    #
    # @example Modify Watir::Button#click to return new MainPage instance after click
    #   class LoginForm < Test::Page
    #     def login_button
    #       modify button(:id => "login"),
    #         :click => proc { redirect_to MainPage }
    #     end
    #   end
    #
    #   LoginForm.new.login_button.click # performs the click and returns
    #                                    # a new MainPage instance.
    #
    # @param [Object] Element element to modify.
    # @param [Hash<Symbol,Proc>] Hash of method name as a Symbol and body as a Proc pairs.
    #
    # @return [Object] Modified Element instance.
    def modify(element, methods)
      methods.each_pair do |meth, return_value|
        element.instance_eval do 
          singleton = class << self; self end

          singleton.send :alias_method, "__#{meth}", meth if respond_to? meth
          singleton.send :define_method, meth do |*args|
            self.send("__#{meth}", *args) if respond_to? "__#{meth}"
            return_value.call(*args)
          end
        end
      end
      element
    end

    # Create new {Page} object conveniently on page actions.
    #
    # @param [Page] Page page class to make an instance of
    # @param [Object] Element optional element instance. When not specified current {Page} element will be used.
    def redirect_to(page, element=nil)
      page.new element || self.element
    end      

    # Proxies every method call not found on {Page} to element instance.
    # Subsequent executions of the same method will be invoked on the {Page} object directly.
    def method_missing(name, *args)
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
      
  end
end
