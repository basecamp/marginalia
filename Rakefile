#!/usr/bin/env rake
require "bundler/gem_tasks"
require_relative "test/test_helpers"
require "tempfile"

DB_PORT=ENV['MARGINALIA_DB_PORT'] || 5455
DB_NAME='marginalia_test'
LOG_FILE=ENV['MARGINALIA_LOG_FILE'] || "tmp/marginalia_log"

task :default => ['test:postgresql']

namespace :test do
  desc "test PostgreSQL driver"
  task :postgresql => [:"db:postgresql:reset"] do
    sh "for file in $(find test -type f -name '*_test.rb'); do MARGINALIA_LOG_FILE=#{LOG_FILE} MARGINALIA_DB_PORT=#{DB_PORT} ruby -Ilib -Itest $file; done"
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
      instance = TestHelpers.create_db(
        db_name: DB_NAME,
        db_port: DB_PORT,
        log_file: LOG_FILE,
      )
    end

    desc "kill PostgreSQL database"
    task :drop do
      PgInstance.stop_cluster(DB_PORT, "tmp")
      %x[rm -rf "tmp"] unless ENV['TRAVIS']
    end
  end
end
