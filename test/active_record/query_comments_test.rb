# -*- coding: utf-8 -*-

require "minitest/autorun"
require 'mocha/test_unit'
require 'logger'
require 'pp'
require 'active_record'
require 'tmpdir'

require 'active_record/connection_adapters/postgresql_adapter'

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
RAILS_ROOT = File.expand_path(File.dirname(__FILE__))

class Post < ActiveRecord::Base
end

class ActiveRecordMarginaliaTest < MiniTest::Test
  def setup
    # TODO log all statements via log_statement=all
    @@pg_dir = Dir.mktmpdir
    @@pg_port = 5439
    @@db_name = "active_record_marginalia_test"

    %x[initdb -A trust -D #{@@pg_dir}]
    %x[pg_ctl -o"-p #{@@pg_port}" -D#{@@pg_dir} -l logfile start]
    %x[createdb -p#{@@pg_port} #{@@db_name}]

    ActiveRecord::Base.establish_connection({
      :adapter  => ENV["DRIVER"] || "postgresql",
      :host     => "localhost",
      :port     => @@pg_port,
      :username => ENV["DB_USERNAME"] || "root",
      :database => @@db_name
    })

    unless Post.table_exists?
      ActiveRecord::Schema.define do
        create_table "posts", :force => true do |t|
        end
      end
    end

    Marginalia.install
    Marginalia.set('app', 'rails')
  end

  def test_double_annotate
    ActiveRecord::Base.connection.expects(:annotate_sql).returns("select id from posts").once
    ActiveRecord::Base.connection.send(:select, "select id from posts")
  ensure
    ActiveRecord::Base.connection.unstub(:annotate_sql)
  end

  # if ENV["DRIVER"] =~ /^postgres/
  #   def test_query_commenting_on_postgres_update
  #     ActiveRecord::Base.connection.expects(:annotate_sql).returns("update posts set id = 1").once
  #     ActiveRecord::Base.connection.send(:exec_update, "update posts set id = 1")
  #   ensure
  #     ActiveRecord::Base.connection.unstub(:annotate_sql)
  #   end

  #   def test_query_commenting_on_postgres_delete
  #     ActiveRecord::Base.connection.expects(:annotate_sql).returns("delete from posts where id = 1").once
  #     ActiveRecord::Base.connection.send(:exec_delete, "delete from posts where id = 1")
  #   ensure
  #     ActiveRecord::Base.connection.unstub(:annotate_sql)
  #   end
  # end

  def test_configuring_application
    Marginalia.set('app', 'customapp')
    Post.all.to_a
    assert_match %r{/\*app:customapp\*/$}, @queries.first
  end

  # def test_configuring_query_components
  #   Marginalia.set('controller', 'posts')
  #   Post.all.to_a
  #   assert_match %r{/\*app:rails,controller=posts\*/$}, @queries.first
  # end

  def teardown
    Marginalia.clear!
    ActiveSupport::Notifications.unsubscribe "sql.active_record"
    system("dropdb -p#{@@pg_port} #{@@db_name}")
    system("pg_ctl -o'-p #{@@pg_port}' -D#{@@pg_dir} -l logfile stop")
  end
end
