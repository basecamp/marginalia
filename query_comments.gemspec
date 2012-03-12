Gem::Specification.new do |gem|
  gem.authors       = ["Noah Lorang", "Nick Quaranto"]
  gem.email         = ["noah@37signals.com"]
  gem.homepage      = "https://github.com/37signals/query_comments"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test}/*`.split("\n")
  gem.name          = "query_comments"
  gem.require_paths = ["lib"]
  gem.version       = "1.0.0"

  gem.add_runtime_dependency "actionpack", ">= 2.3", "< 3.3"
  gem.add_runtime_dependency "activerecord", ">= 2.3", "< 3.3"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "mysql"

  gem.summary = description = %q{Attach comments to your ActiveRecord queries.}
end
