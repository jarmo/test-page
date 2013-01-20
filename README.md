# Test::Page
[![Gem Version](https://badge.fury.io/rb/rautomation.png)](http://badge.fury.io/rb/rautomation)
[![Build Status](https://secure.travis-ci.org/jarmo/test-page.png)](http://travis-ci.org/jarmo/test-page)
[![Coverage](https://coveralls.io/repos/jarmo/test-page/badge.png?branch=master)](https://coveralls.io/r/jarmo/test-page)
[![Dependency Status](https://gemnasium.com/jarmo/test-page.png)](https://gemnasium.com/jarmo/test-page)
[![Code Quality](https://codeclimate.com/badge.png)](https://codeclimate.com/github/jarmo/test-page)

Test::Page helps you to write easily maintainable integration tests by implementing [Page Objects](https://code.google.com/p/selenium/wiki/PageObjects) pattern.

Page Objects may be objects representing whole pages like LoginPage, ProfilePage or part of the pages like LoginForm, Header etc.

Test::Page can be described like:

* Is framework agnostic - you can use it with any library you want - [Watir](http://watir.com), [Selenium](http://seleniumhq.org/), [Capybara](https://github.com/jnicklas/capybara) etc.
* Has really [easy API](http://rubydoc.info/github/jarmo/test-page/frames) - you can start testing right away instead of spending too much time to learn new framework.
* Has really small codebase - even if you can't remember that small API you can dig right into the code - it's less than 100 lines!
* Despite of its name you may use it with [RSpec](http://rspec.info/), [Test::Unit](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/test/unit/rdoc/Test/Unit.html) or any other testing library.

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

[Check out Selenium example](https://github.com/jarmo/test-page/tree/master/examples) instead, if that's your flavor of choice.

This is the spec we are trying to run:

    # spec/search_spec.rb

    require "test/page"
    require "watir"
    require File.expand_path("search_page", File.dirname(__FILE__))

    describe "Bing" do
      
      let(:browser)     { Watir::Browser.new }
      let(:search_page) { SearchPage.new }
      
      before { Test::Page.browser = browser }
      after  { browser.close }

      it "finds Google" do
        results_page = search_page.search "google"
        results_page.should have(10).results
        results_page.results[0].should =~ /google/i
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
      element { browser.div(:id => "sbox") }

      def setup
        browser.goto "http://bing.com"
      end

      def search(term)
        text_field(:id => "sb_form_q").set term
        button(:id => "sb_form_go").click
        redirect_to ResultsPage, browser.ul(:id => "wg0")
      end
    end

Let's create the ResultsPage object:

    # spec/support/page/results_page.rb

    class ResultsPage < Test::Page
      def results
        modify lis(:class => "sa_wr").map(&:text),
          :include? => proc { |term|
            regexp = Regexp.new Regexp.escape(term)
            results.any? { |result| result =~ regexp }
        }
      end
    end

There you have it, a fully functional spec using two page objects. Reference to the
[API documentation](http://rubydoc.info/github/jarmo/test-page/frames) for more usage information.

## License

Copyright (c) Jarmo Pertman (jarmo.p@gmail.com). See LICENSE for details.
