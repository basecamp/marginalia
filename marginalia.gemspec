Gem::Specification.new do |gem|
  gem.authors       = ["Noah Lorang", "Nick Quaranto", "Taylor Weibley"]
  gem.email         = ["arthurnn@github.com"]
  gem.homepage      = "https://github.com/basecamp/marginalia"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test}/*`.split("\n")
  gem.name          = "marginalia"
  gem.require_paths = ["lib"]
  gem.version       = "1.10.0"
  gem.license       = "MIT"

  gem.add_runtime_dependency "actionpack", ">= 2.3"
  gem.add_runtime_dependency "activerecord", ">= 2.3"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "pg"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "sidekiq"

  gem.summary = gem.description = %q{Attach comments to your ActiveRecord queries.}
end
