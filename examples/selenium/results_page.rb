class ResultsPage < Test::Page
  def results
    modify find_elements(:class => "sa_wr").map(&:text),
      :result   => proc { |i| results[i + 1] },
      :include? => proc { |term|
        regexp = Regexp.new Regexp.escape term
        results.any? {|result| result =~ regexp}
      }
  end
end
