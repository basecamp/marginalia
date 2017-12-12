source "https://rubygems.org"

gemspec

version = ENV["RAILS_VERSION"] || "4.2.0"

if "4.2.5" > version
  gem 'mysql2', '~> 0.3.13'
else
  gem 'mysql2', '>= 0.3.13', '< 0.5'
end

gem "activerecord", "~> #{version}"
