#!/usr/bin/env rake
require "bundler/gem_tasks"

task :default => ['test:all']

namespace :test do
  desc "test all drivers"
  task :all => [:postgresql]

  desc "test PostgreSQL driver"
  task :postgresql do
    sh "DRIVER=postgresql DB_USERNAME=postgres bundle exec ruby -Ilib -Itest test/*_test.rb"
  end
end

namespace :db do

  desc "reset all databases"
  task :reset => [:"postgresql:reset"]

  namespace :postgresql do
    desc "reset PostgreSQL database"
    task :reset => [:drop, :create]

    desc "create PostgreSQL database"
    task :create do
      sh 'createdb -h 127.0.0.1 -p 25432 -U development marginalia_test'
    end

    desc "drop PostgreSQL database"
    task :drop do
      sh 'psql -h 127.0.0.1 -p 25432 -d postgres -U development -c "DROP DATABASE IF EXISTS marginalia_test"'
    end
  end
end
