# -*- coding: utf-8 -*-

require "minitest/autorun"
gem 'mocha'
require 'test/unit'
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

DB_NAME="marginalia_test"

ActiveRecord::Base.establish_connection({
  :adapter  => "postgresql",
  :host     => "localhost",
  :port     => ENV['MARGINALIA_DB_PORT'],
  :database => DB_NAME,
})

# Enable logging of queries to log file
query = <<~QUERY
  SET log_statement = 'all';
QUERY
ActiveRecord::Base.connection.execute(query)

drop_posts = <<~QUERY
DROP TABLE IF EXISTS posts;
QUERY

ActiveRecord::Base.connection.execute(drop_posts)


ActiveRecord::Schema.define do
  create_table "posts", :force => true do |t|
    t.string :title
  end
end


class ActiveRecordMarginaliaTest < MiniTest::Test
  def setup
    Marginalia.set('adapter', 'active_record')
  end

  def test_crud_actions_contain_comment
    Marginalia.set('app', 'crud.insert')
    Post.create({title: "foo"})
    assert TestHelpers.file_contains_string(ENV['MARGINALIA_LOG_FILE'], "/*adapter:active_record,app:crud.insert*/")

    Marginalia.set('app', 'crud.update')
    Post.update(1, { title: "bar" })
    assert TestHelpers.file_contains_string(ENV['MARGINALIA_LOG_FILE'], "/*adapter:active_record,app:crud.update*/")

    Marginalia.set('app', 'crud.delete')
    Post.find(1).destroy
    assert TestHelpers.file_contains_string(ENV['MARGINALIA_LOG_FILE'], "/*adapter:active_record,app:crud.delete*/")
  end

  def teardown
    Marginalia.clear!
  end
end
