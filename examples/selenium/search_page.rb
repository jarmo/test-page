require File.expand_path("results_page", File.dirname(__FILE__))

class SearchPage < Test::Page
  element { browser.find_element(id: "sbox") }

  def setup
    browser.navigate.to("http://bing.com")
  end

  def search(term)
    find_element(:id => "sb_form_q").send_keys term
    find_element(:id => "sb_form_go").click
    redirect_to ResultsPage, browser.find_element(:id => "wg0")
  end
end
