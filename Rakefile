#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rake/clean'
require "rake/testtask"

task :default => [:test]

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
end

namespace :db do
  desc "reset database"
  task :reset => [:drop, :create]

  desc "create database"
  task :create do
    sh 'mysql -u root -e "create database query_comments_test;"'
  end

  desc "drop database"
  task :drop do
    sh 'mysql -u root -e "drop database query_comments_test;"'
  end
end
