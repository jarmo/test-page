class ResultsPage < Test::Page
  def results
    find_elements(:class => "sa_wr").map(&:text)
  end
end
