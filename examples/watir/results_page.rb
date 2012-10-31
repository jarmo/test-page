class ResultsPage < Test::Page
  def results
    modify lis(:class => "sa_wr").map(&:text),
      :include? => proc { |term|
        regexp = Regexp.new Regexp.escape(term)
        results.any? { |result| result =~ regexp }
    }
  end
end
