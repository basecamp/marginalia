source "https://rubygems.org"

gemspec

version = ENV["RAILS_VERSION"] || "4.0.2"
rails_api = ENV["TEST_RAILS_API"] == "true"

rails = case version
when "master"
  {:github => "rails/rails"}
else
  "~> #{version}"
end

gem "rails", rails

if rails_api
  gem "rails-api", "~> 0.2.1"
end
