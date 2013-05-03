source "https://rubygems.org"

gemspec

version = ENV["RAILS_VERSION"] || "3.2"

rails = case version
when "master"
  {:github => "rails/rails"}
else
  "~> #{version}.0"
end

gem "rails", rails
