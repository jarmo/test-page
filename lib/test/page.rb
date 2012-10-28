require File.expand_path("page/version", File.dirname(__FILE__))
require 'forwardable'

module Test
  class Page
    extend Forwardable

    def_delegators :element, :present?, :p

    class << self
      attr_accessor :browser
      attr_reader :element_block 

      def element(&block)
        @element_block = block
      end
    end

    attr_writer :browser

    def browser
      @browser || parent_page_browser
    end

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

    def initialize(element=nil)
      @element = element
    end

    def modify(element, methodz)
      methodz.each_pair do |meth, return_value|
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

    def redirect_to(page, element=nil)
      page.new element || self.element
    end      

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
