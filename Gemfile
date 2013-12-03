source "https://rubygems.org"

gemspec

version = ENV["RAILS_VERSION"] || "3.2.15"

rails = case version
when "master"
  {:github => "rails/rails"}
else
  "~> #{version}"
end

gem "rails", rails
