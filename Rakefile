#!/usr/bin/env rake
require "bundler/gem_tasks"

task :default => ['test:all']

namespace :test do
  desc "test all drivers"
  task :all => [:mysql, :mysql2, :sqlite]

  desc "test mysql driver"
  task :mysql do
    sh "DRIVER=mysql ruby -Ilib -Itest test/*_test.rb"
  end

  desc "test mysql2 driver"
  task :mysql2 do
    sh "DRIVER=mysql2 ruby -Ilib -Itest test/*_test.rb"
  end
  
  desc "test sqlite3 driver"
  task :sqlite do
    sh "DRIVER=sqlite3 ruby -Ilib -Itest test/*_test.rb"
  end
end

namespace :db do
  desc "reset database"
  task :reset => [:drop, :create]

  desc "create database"
  task :create do
    sh 'mysql -u root -e "create database marginalia_test;"'
  end

  desc "drop database"
  task :drop do
    sh 'mysql -u root -e "drop database marginalia_test;"'
  end
end
