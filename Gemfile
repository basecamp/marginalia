source "https://rubygems.org"

gemspec

version = ENV["RAILS_VERSION"] || "4.0.2"

rails = case version
when "master"
  {:github => "rails/rails"}
else
  "~> #{version}"
end

gem "rails", rails
