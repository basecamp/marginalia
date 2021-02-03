source "https://rubygems.org"

gemspec

version = ENV["RAILS_VERSION"] || "4.2.0"

if "4.2.5" > version
  gem 'mysql2', '~> 0.3.13'
else
  gem 'mysql2', '>= 0.3.13', '< 0.5'
end
gem 'pg', '~> 0.15'
gem 'sqlite3', '~> 1.3.6'

rails = case version
when "main"
  {:github => "rails/rails", :branch => 'main'}
else
  "~> #{version}"
end

gem "rails", rails

if ENV["TEST_RAILS_API"] == "true"
  gem "rails-api", "~> 0.2.1"
end

if RUBY_VERSION.start_with?('2.3')
  gem 'mysql'
end
