class ResultsPage < Test::Page
  def results
    modify lis(:class => "sa_wr").map(&:text),
      :result   => proc { |index| results[index + 1] },
      :include? => proc { |term|
        regexp = Regexp.new Regexp.escape(term)
        results.any? { |result| result =~ regexp }
    }
  end
end
