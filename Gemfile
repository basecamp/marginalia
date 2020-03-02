source "https://rubygems.org"

gemspec

version = ENV["RAILS_VERSION"] || "4.2.0"

if version < "4.2.5"
  gem 'mysql2', '~> 0.3.13'
elsif version < "5.1"
  gem 'mysql2', '>= 0.3.13', '< 0.5'
else
  gem 'mysql2'
end
gem 'pg', '~> 0.15'
gem 'sqlite3', '~> 1.3.6'

if version == "master"
  gem "rails", github: "rails/rails"
else
  gem "rails", "~> #{version}"
end

if ENV["TEST_RAILS_API"] == "true"
  gem "rails-api", "~> 0.2.1"
end

if RUBY_VERSION.start_with?('2.3')
  gem 'mysql'
end
