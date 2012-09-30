require File.expand_path("page/version", File.dirname(__FILE__))

module Test
  class Page
    extend Forwardable

    def_delegators :container, :present?, :p

    class << self
      attr_accessor :browser
      attr_reader :setup_block, :container_block 

      def container(&block)
        @container_block = block
      end

      def setup(&block)
        @setup_block = block
      end
    end

    attr_writer :browser
    attr_writer :container

    def browser
      @browser || parent_page_browser
    end

    def container
      if @setup_block
        instance_eval(&@setup_block) 
        @setup_block = nil
      end
      @container ||= self.class.container_block && instance_eval(&self.class.container_block)
    end

    def initialize(container=nil, &block)
      @container = container
      @setup_block = self.class.setup_block

      block.call self if block
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

    def redirect_to(page, container=nil)
      page.new container || self.container
    end      

    def method_missing(name, *args)
      if container.respond_to?(name)
        self.class.send :define_method, name do |*args|
          container.send(name, *args) {yield}
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
