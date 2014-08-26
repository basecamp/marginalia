# -*- coding: utf-8 -*-
require 'test/unit'
require 'mocha/test_unit'
require 'logger'
require 'pp'
require 'active_record'
require 'action_controller'
require 'marginalia'
RAILS_ROOT = File.expand_path(File.dirname(__FILE__))

ActiveRecord::Base.establish_connection({
  :adapter  => ENV["DRIVER"] || "mysql",
  :host     => "localhost",
  :username => ENV["DB_USERNAME"] || "root",
  :database => "marginalia_test"
})

class Post < ActiveRecord::Base
end

class PostsController < ActionController::Base
  def driver_only
    ActiveRecord::Base.connection.execute "select id from posts"
    render :nothing => true
  end
end

unless Post.table_exists?
  ActiveRecord::Schema.define do
    create_table "posts", :force => true do |t|
    end
  end
end

Marginalia::Railtie.insert

class MarginaliaTest < Test::Unit::TestCase
  def setup
    @queries = []
    ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
      @queries << args.last[:sql]
    end
    @env = Rack::MockRequest.env_for('/')
  end

  def test_double_annotate
    ActiveRecord::Base.connection.expects(:annotate_sql).returns("select id from posts").once
    ActiveRecord::Base.connection.send(:select, "select id from posts")
  ensure
    ActiveRecord::Base.connection.unstub(:annotate_sql)
  end

  def test_query_commenting_on_mysql_driver_with_no_action
    ActiveRecord::Base.connection.execute "select id from posts"
    assert_match %r{select id from posts /\*application:rails\*/$}, @queries.first
  end

  if ENV["DRIVER"] =~ /^mysql/
    def test_query_commenting_on_mysql_driver_with_binary_chars
      ActiveRecord::Base.connection.execute "select id from posts /* \x81\x80\u0010\ */"
      assert_equal "select id from posts /* \x81\x80\u0010 */ /*application:rails*/", @queries.first
    end
  end

  if ENV["DRIVER"] =~ /^postgres/
    def test_query_commenting_on_postgres_update
      ActiveRecord::Base.connection.expects(:annotate_sql).returns("update posts set id = 1").once
      ActiveRecord::Base.connection.send(:exec_update, "update posts set id = 1")
    ensure
      ActiveRecord::Base.connection.unstub(:annotate_sql)
    end

    def test_query_commenting_on_postgres_delete
      ActiveRecord::Base.connection.expects(:annotate_sql).returns("delete from posts where id = 1").once
      ActiveRecord::Base.connection.send(:exec_delete, "delete from posts where id = 1")
    ensure
      ActiveRecord::Base.connection.unstub(:annotate_sql)
    end
  end

  def test_query_commenting_on_mysql_driver_with_action
    PostsController.action(:driver_only).call(@env)
    assert_match %r{select id from posts /\*application:rails,controller:posts,action:driver_only\*/$}, @queries.first
  end

  def test_configuring_application
    Marginalia.application_name = "customapp"
    PostsController.action(:driver_only).call(@env)

    assert_match %r{/\*application:customapp,controller:posts,action:driver_only\*/$}, @queries.first
  end

  def test_configuring_query_components
    Marginalia::Comment.components = [:controller]
    PostsController.action(:driver_only).call(@env)

    assert_match %r{/\*controller:posts\*/$}, @queries.first
  end

  def test_last_line_component
    Marginalia::Comment.components = [:line]
    PostsController.action(:driver_only).call(@env)

    # Because "lines_to_ignore" by default includes "marginalia" and "gem", the
    # extracted line line will be from the line in this file that actually
    # triggers the query.
    assert_match %r{/\*line:test/query_comments_test.rb:[0-9]+:in `driver_only'\*/$}, @queries.first
  end

  def test_last_line_component_with_lines_to_ignore
    Marginalia::Comment.lines_to_ignore = /foo bar/
    Marginalia::Comment.components = [:line]
    PostsController.action(:driver_only).call(@env)
    # Because "lines_to_ignore" does not include "marginalia", the extracted
    # line will be from marginalia/comment.rb.
    assert_match %r{/\*line:.*lib/marginalia/comment.rb:[0-9]+}, @queries.first
  end

  def test_hostname_and_pid
    Marginalia::Comment.components = [:hostname, :pid]
    PostsController.action(:driver_only).call(@env)
    assert_match %r{/\*hostname:#{Socket.gethostname},pid:#{Process.pid}\*/$}, @queries.first

  end

  def teardown
    Marginalia.application_name = nil
    Marginalia::Comment.components = [:application, :controller, :action]
    ActiveSupport::Notifications.unsubscribe "sql.active_record"
  end
end
