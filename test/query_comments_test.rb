# -*- coding: utf-8 -*-
require 'rails/version'

def using_rails_api?
  ENV["TEST_RAILS_API"] == true
end

def request_id_available?
  Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('3.2')
end

def active_job_available?
  Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('4.2')
end

def adapter_pool_available?
  Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new('3.2.19')
end

require "minitest/autorun"
require "mocha/minitest"
require 'logger'
require 'pp'
require 'active_record'
require 'action_controller'
require 'sidekiq'
require 'sidekiq/testing'

if request_id_available?
  require 'action_dispatch/middleware/request_id'
end

if active_job_available?
  require 'active_job'
end

if using_rails_api?
  require 'rails-api/action_controller/api'
end

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

ActiveRecord::Base.establish_connection({
  :adapter  => "postgresql",
  :host     => "localhost",
  :port     => 25432,
  :username => "development",
  :password => "development",
  :database => "marginalia_test"
})

class Post < ActiveRecord::Base
end

class PostsController < ActionController::Base
  def driver_only
    ActiveRecord::Base.connection.execute "select id from posts"
    if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('5')
      render body: nil
    else
      render nothing: true
    end
  end
end

module API
  module V1
    class PostsController < ::PostsController
    end
  end
end

if active_job_available?
  class PostsJob < ActiveJob::Base
    def perform
      Post.first
    end
  end
end

class PostsSidekiqJob
  include Sidekiq::Worker
  def perform
    Post.first
  end
end

if using_rails_api?
  class PostsApiController < ActionController::API
    def driver_only
      ActiveRecord::Base.connection.execute "select id from posts"
      head :no_content
    end
  end
end

unless Post.table_exists?
  ActiveRecord::Schema.define do
    create_table "posts", :force => true do |t|
    end
  end
end

Marginalia::Railtie.insert

class MarginaliaTest < MiniTest::Test
  def setup
    @queries = []
    ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
      @queries << args.last[:sql]
    end
    @env = Rack::MockRequest.env_for('/')
    ActiveJob::Base.queue_adapter = :inline
  end

  def test_double_annotate
    ActiveRecord::Base.connection.expects(:annotate_sql).returns("select id from posts").once
    ActiveRecord::Base.connection.send(:select, "select id from posts")
  ensure
    ActiveRecord::Base.connection.unstub(:annotate_sql)
  end

  def test_exists
    skip if Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new('3.2')
    Post.exists?
    assert_match %r{/\*application:rails\*/$}, @queries.last
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

    if using_rails_api?
      PostsApiController.action(:driver_only).call(@env)
      assert_match %r{select id from posts /\*application:rails,controller:posts_api,action:driver_only\*/$}, @queries.second
    end
  end

  def test_configuring_application
    Marginalia.application_name = "customapp"
    PostsController.action(:driver_only).call(@env)
    assert_match %r{/\*application:customapp,controller:posts,action:driver_only\*/$}, @queries.first

    if using_rails_api?
      PostsApiController.action(:driver_only).call(@env)
      assert_match %r{/\*application:customapp,controller:posts_api,action:driver_only\*/$}, @queries.second
    end
  end

  def test_configuring_query_components
    Marginalia::Comment.components = [:controller]
    PostsController.action(:driver_only).call(@env)
    assert_match %r{/\*controller:posts\*/$}, @queries.first

    if using_rails_api?
      PostsApiController.action(:driver_only).call(@env)
      assert_match %r{/\*controller:posts_api\*/$}, @queries.second
    end
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

  def test_default_lines_to_ignore_regex
    line = "/gems/a_gem/lib/a_gem.rb:1:in `some_method'"
    call_stack = [line] + caller

    assert_match(
      call_stack.detect { |line| line !~ Marginalia::Comment::DEFAULT_LINES_TO_IGNORE_REGEX },
      line
    )
  end

  def test_hostname_and_pid
    Marginalia::Comment.components = [:hostname, :pid]
    PostsController.action(:driver_only).call(@env)
    assert_match %r{/\*hostname:#{Socket.gethostname},pid:#{Process.pid}\*/$}, @queries.first
  end

  def test_controller_with_namespace
    Marginalia::Comment.components = [:controller_with_namespace]
    API::V1::PostsController.action(:driver_only).call(@env)
    assert_match %r{/\*controller_with_namespace:API::V1::PostsController}, @queries.first
  end

  if adapter_pool_available?
    def test_db_host
      Marginalia::Comment.components = [:db_host]
      API::V1::PostsController.action(:driver_only).call(@env)
      assert_match %r{/\*db_host:localhost}, @queries.first
    end

    def test_database
      Marginalia::Comment.components = [:database]
      API::V1::PostsController.action(:driver_only).call(@env)
      assert_match %r{/\*database:marginalia_test}, @queries.first
    end

    def test_socket
      # setting socket in configuration would break some connections - mock it instead
      pool = ActiveRecord::Base.connection_pool
      pool.db_config.stubs(:socket).returns("marginalia_socket")
      Marginalia::Comment.components = [:socket]
      API::V1::PostsController.action(:driver_only).call(@env)
      assert_match %r{/\*socket:marginalia_socket}, @queries.first
      pool.db_config.unstub(:socket)
    end
  end

  if request_id_available?
    def test_request_id
      @env["action_dispatch.request_id"] = "some-uuid"
      Marginalia::Comment.components = [:request_id]
      PostsController.action(:driver_only).call(@env)
      assert_match %r{/\*request_id:some-uuid.*}, @queries.first

      if using_rails_api?
        PostsApiController.action(:driver_only).call(@env)
        assert_match %r{/\*request_id:some-uuid.*}, @queries.second
      end
    end

  else
    def test_request_id_is_noop_on_old_rails
      @env["action_dispatch.request_id"] = "some-uuid"
      Marginalia::Comment.components = [:request_id]
      PostsController.action(:driver_only).call(@env)
      assert_match %r{^select id from posts$}, @queries.first
    end
  end

  if active_job_available?
    def test_active_job
      Marginalia::Comment.components = [:job]
      PostsJob.perform_later
      assert_match %{job:PostsJob}, @queries.first

      Post.first
      refute_match %{job:PostsJob}, @queries.last
    end

    def test_active_job_with_sidekiq
      Marginalia::Comment.components = [:job, :sidekiq_job]
      PostsJob.perform_later
      assert_match %{job:PostsJob}, @queries.first

      Post.first
      refute_match %{job:PostsJob}, @queries.last
    end
  end

  def test_sidekiq_job
    Marginalia::Comment.components = [:sidekiq_job]
    Marginalia::SidekiqInstrumentation.enable!

    # Test harness does not run Sidekiq middlewares by default so include testing middleware.
    Sidekiq::Testing.server_middleware do |chain|
      chain.add Marginalia::SidekiqInstrumentation::Middleware
    end

    Sidekiq::Testing.fake!
    PostsSidekiqJob.perform_async
    PostsSidekiqJob.drain
    assert_match %{sidekiq_job:PostsSidekiqJob}, @queries.first

    Post.first
    refute_match %{sidekiq_job:PostsSidekiqJob}, @queries.last
  end

  def test_good_comment
    assert_equal Marginalia::Comment.escape_sql_comment('app:foo'), 'app:foo'
  end

  def test_bad_comments
    assert_equal Marginalia::Comment.escape_sql_comment('*/; DROP TABLE USERS;/*'), '; DROP TABLE USERS;'
    assert_equal Marginalia::Comment.escape_sql_comment('**//; DROP TABLE USERS;/*'), '; DROP TABLE USERS;'
  end

  def test_inline_annotations
    Marginalia.with_annotation("foo") do
      Post.first
    end
    Post.first
    assert_match %r{/\*foo\*/$}, @queries.first
    refute_match %r{/\*foo\*/$}, @queries.last
    # Assert we're not adding an empty comment, either
    refute_match %r{/\*\s*\*/$}, @queries.last
  end

  def test_nested_inline_annotations
    Marginalia.with_annotation("foo") do
      Marginalia.with_annotation("bar") do
        Post.first
      end
    end
    assert_match %r{/\*foobar\*/$}, @queries.first
  end

  def test_bad_inline_annotations
    Marginalia.with_annotation("*/; DROP TABLE USERS;/*") do
      Post.first
    end
    Marginalia.with_annotation("**//; DROP TABLE USERS;//**") do
      Post.first
    end
    assert_match %r{/\*; DROP TABLE USERS;\*/$}, @queries.first
    assert_match %r{/\*; DROP TABLE USERS;\*/$}, @queries.last
  end

  def test_inline_annotations_are_deduped
    Marginalia.with_annotation("foo") do
      ActiveRecord::Base.connection.execute "select id from posts /*foo*/"
    end
    assert_match %r{select id from posts /\*foo\*/ /\*application:rails\*/$}, @queries.first
  end

  def test_add_comments_to_beginning_of_query
    Marginalia::Comment.prepend_comment = true

    ActiveRecord::Base.connection.execute "select id from posts"
    assert_match %r{/\*application:rails\*/ select id from posts$}, @queries.first
  ensure
    Marginalia::Comment.prepend_comment = nil
  end

  def test_comment_key_value_separator
    Marginalia.with_comment_settings(key_value_separator: '=') do
      ActiveRecord::Base.connection.execute "select id from posts"
      assert_equal 'select id from posts /*application=rails*/', @queries.first
    end
  end

  def test_comment_quote_values_single
    Marginalia.application_name = "Joe's app"
    Marginalia.with_comment_settings(quote_values: :single) do
      ActiveRecord::Base.connection.execute "select id from posts"
      assert_equal "select id from posts /*application:'Joe\\'s app'*/", @queries.first
    end
  end

  def teardown
    Marginalia.application_name = nil
    Marginalia::Comment.lines_to_ignore = nil
    Marginalia::Comment.components = [:application, :controller, :action]
    ActiveSupport::Notifications.unsubscribe "sql.active_record"
  end
end
