source "https://rubygems.org"

gemspec

rails_version = ENV["RAILS_VERSION"] || "6.1.0"
if rails_version == "main"
  gem "rails", github: "rails/rails"
else
  gem "rails", "~> #{rails_version}"
end
