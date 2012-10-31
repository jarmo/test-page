require "test/page"
require "selenium-webdriver"
require File.expand_path("search_page", File.dirname(__FILE__))

describe "Bing" do

  let(:browser)     { Selenium::WebDriver.for :firefox }
  let(:search_page) { SearchPage.new }
  
  before { Test::Page.browser = browser }
  after  { browser.quit }

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
