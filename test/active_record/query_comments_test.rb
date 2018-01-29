# -*- coding: utf-8 -*-

require "minitest/autorun"
require 'mocha/test_unit'
require 'logger'
require 'pp'
require 'active_record'
require "test_helpers"
require 'tempfile'

# Shim for compatibility with older versions of MiniTest
MiniTest::Test = MiniTest::Unit::TestCase unless defined?(MiniTest::Test)

# From version 4.1, ActiveRecord expects `Rails.env` to be
# defined if `Rails` is defined
if defined?(Rails) && !defined?(Rails.env)
  module Rails
    def self.env
    end
  end
end

require 'marginalia'
Marginalia.install

RAILS_ROOT = File.expand_path(File.dirname(__FILE__))

class Post < ActiveRecord::Base
end

DB_PORT=5439
DB_NAME="active_record_marginalia_test"
LOG_FILE=Tempfile.new("active_record_logfile").path

TestHelpers.create_db(
  db_name: DB_NAME,
  db_port: DB_PORT,
  log_file: LOG_FILE,
)

ActiveRecord::Base.establish_connection({
  :adapter  => "postgresql",
  :host     => "localhost",
  :port     => DB_PORT,
  :username => ENV["DB_USERNAME"] || "root",
  :database => DB_NAME,
})

# Enable logging of queries to log file
query = <<~QUERY
  SET log_statement = 'all';
QUERY
ActiveRecord::Base.connection.execute(query)

unless Post.table_exists?
  ActiveRecord::Schema.define do
    create_table "posts", :force => true do |t|
      t.string :foo
    end
  end
end


class ActiveRecordMarginaliaTest < MiniTest::Test
  def test_configuring_application
    Marginalia.set('app', 'customapp')
    Post.all.to_a
    assert TestHelpers.file_contains_string(LOG_FILE, "/*app:customapp*/")
  end

  def test_configuring_query_components
    Marginalia.set('app', 'rails')
    Marginalia.set('controller', 'posts')
    Post.all.to_a
    assert TestHelpers.file_contains_string(LOG_FILE, "/*app:rails,controller:posts*/")
  end

  def test_update_statement_contains_comment
    Marginalia.set('app', 'sinatra')
    Post.create({foo: "foo"})
    TestHelpers.truncate_file(LOG_FILE)
    Post.update(1, { foo: "bar" })
    assert TestHelpers.file_contains_string(LOG_FILE, "/*app:sinatra*/")
  end

  def teardown
    Marginalia.clear!
    TestHelpers.truncate_file(LOG_FILE)
  end
end
