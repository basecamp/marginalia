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

rails_major, rails_minor = version.split(".").map(&:to_i)
if (rails_major == 3 && rails_minor == 2) || rails_major >= 4
  gem "rails-api", "~> 0.2.1"
end
