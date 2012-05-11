require 'test/unit'
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
  class Logger < Array
    def debug(message)
      push message
    end

    def error(message)
      push message
    end

    def debug?
      true
    end
  end

  def setup
    @old_logger = ActiveRecord::Base.logger
    @logger     = Logger.new
    @env        = Rack::MockRequest.env_for('/')
    ActiveRecord::Base.logger = @logger
  end

  def test_query_commenting_with_no_action
    ActiveRecord::Base.connection.execute "select id from posts"
    assert_match %r{select id from posts}, @logger.first
  end

  def test_query_commenting_with_action
    PostsController.action(:driver_only).call(@env)
    assert_match %r{select id from posts /\*application:rails,controller:posts,action:driver_only\*/}, @logger.first
  end

  def test_configuring_application
    Marginalia.application_name = "customapp"
    PostsController.action(:driver_only).call(@env)

    assert_match %r{/\*application:customapp,controller:posts,action:driver_only\*/}, @logger.first
  end

  def test_configuring_query_components
    Marginalia::Comment.components = [:controller]
    PostsController.action(:driver_only).call(@env)

    assert_match %r{/\*controller:posts\*/}, @logger.first
  end

  def test_last_line_component
    Marginalia::Comment.components = [:line]
    PostsController.action(:driver_only).call(@env)
    assert_match %r{/\*line:test/query_comments_test.rb:[0-9]*:in `call'\*/}, @logger.first
  end

  def test_last_line_component_with_lines_to_ignore
    Marginalia::Comment.lines_to_ignore = /foo bar/
    Marginalia::Comment.components = [:line]
    PostsController.action(:driver_only).call(@env)
    assert_match %r{/\*line:.*lib/marginalia/comment.rb:7:in .*?\*/}, @logger.first
  end

  def teardown
    Marginalia.application_name    = nil
    Marginalia::Comment.components = [:application, :controller, :action]
    ActiveRecord::Base.logger      = @old_logger
  end
end
