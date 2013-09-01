class ResultsPage < Test::Page
  def results
    lis(:class => "sa_wr").map(&:text)
  end
end
