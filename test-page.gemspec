# -*- encoding: utf-8 -*-
require File.expand_path('../lib/test/page/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jarmo Pertman"]
  gem.email         = ["jarmo.p@gmail.com"]
  gem.description   = %q{test-page helps you to write easily maintainable integration tests by using Watir, Selenium or any other testing library.}
  gem.summary       = %q{test-page helps you to write easily maintainable integration tests by using Watir, Selenium or any other testing library.}
  gem.homepage      = "https://github.com/jarmo/test-page"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "test-page"
  gem.require_paths = ["lib"]
  gem.version       = Test::Page::VERSION

  gem.add_development_dependency "rspec", "~>2.0"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "yard"
  gem.add_development_dependency "redcarpet"
  gem.add_development_dependency "rake"
end
