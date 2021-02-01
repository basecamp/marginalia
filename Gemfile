source "https://rubygems.org"

gemspec

version = "6.1.1"

# remove mysql and sqlite
gem 'pg', '>= 0.18', '< 2.0'

rails = case version
when "master"
  {:github => "rails/rails"}
else
  "~> #{version}"
end

gem "rails", rails

if ENV["TEST_RAILS_API"] == "true"
  gem "rails-api", "~> 0.2.1"
end

