source "https://rubygems.org"

gemspec

version = ENV["RAILS_VERSION"] || "4.2.0"
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
