require File.expand_path("page/version", File.dirname(__FILE__))

module Test
  class Page
    attr_reader :container

    def initialize(container)
      @container = container
    end

    def modify element, methodz
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

    def redirect_to(page, container)
      page.new container
    end      

    def method_missing(name, *args)
      if @container.respond_to?(name)
        self.class.class_eval %Q[
          def #{name}(*args)
            @container.send(:#{name}, *args) {yield}
          end
        ]
        self.send(name, *args) {yield}
      else
        super
      end
    end
      
  end
end
