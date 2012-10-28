# Test::Page

Test::Page helps you to write easily maintainable integration tests by implementing [Page Objects](https://code.google.com/p/selenium/wiki/PageObjects) pattern.

* It is framework agnostic - you can use it with any library you want - [Watir](http://watir.com), [Selenium](http://seleniumhq.org/), [Capybara](https://github.com/jnicklas/capybara) etc.
* It has really easy API - you can start testing right away instead of spending much time to learn new framework.
* It has really small codebase - even if you can't remember that easy API you can dig right into the code - it's less than 100 lines!

Despite of its name you can use it with [RSpec](http://rspec.info/), [Test::Unit](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/test/unit/rdoc/Test/Unit.html) or any other testing library.

## Installation

Add this line to your application's Gemfile:

    gem 'test-page'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install test-page

## Usage

The following example uses Watir with RSpec, but you can use whichever library
you like.

This is the spec we are trying to run:

    # spec/search_spec.rb

    require "test/page"
    require "watir"
    require File.expand_path("support/page/search_page", File.dirname(__FILE__))

    describe "Bing" do
      
      let(:browser)     { Watir::Browser.new }
      let(:search_page) { SearchPage.new }
      
      before { Test::Page.browser = browser }
      after  { browser.close }

      it "finds Google" do
        results_page = search_page.search "google"
        results_page.should have(10).results
        results_page.results[0].text.should =~ /google/i
      end

      it "finds Bing itself" do
        results_page = search_page.search "bing"
        results_page.results.should include("Bing")
      end
      
    end

Let's create the SearchPage object:

    # spec/support/page/search_page.rb

    require File.expand_path("results_page", File.dirname(__FILE__))

    class SearchPage < Test::Page
      # Specifying the container element.
      element { browser.div(:id => "sbox") }

      # #setup is an optional method which any page might have
      # to set the state up properly after initialization.
      def setup
        browser.goto "http://bing.com"
      end

      # #search will perform the search operation and return
      # a ResultsPage object after it's done.
      def search(term)
        text_field(:id => "sb_form_q").set term
        button(:id => "sb_form_go").click
        redirect_to ResultsPage, browser.ul(:id => "wg0")
      end
    end

Let's create the ResultsPage object:

    # spec/support/page/results_page.rb

    class ResultsPage < Test::Page
      # #results return the LiCollection which has #include? as its additional
      # helper method. This is done with the help of Test::Page#modify.
      def results
        modify lis(:class => "sa_wr").map(&:text),
          :include? => proc do |term|
            regexp = Regexp.new Regexp.escape(term)
            results.any? { |result| result =~ regexp }
          end
      end
    end

There you have it, a fully functional spec using two page objects. Reference to the
API documentation for more usage information.

## License

Copyright (c) Jarmo Pertman. See LICENSE for details.
