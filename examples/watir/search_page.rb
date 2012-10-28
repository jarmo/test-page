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
