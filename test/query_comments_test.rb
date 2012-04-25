require 'test/unit'
require 'logger'
require 'pp'
require 'active_record'
require 'action_controller'
require 'marginalia'

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

  def test_query_commenting_on_mysql_driver_with_no_action
    ActiveRecord::Base.connection.execute "select id from posts"
    assert_match %r{select id from posts /\*\*/$}, @queries.first
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

  def teardown
    Marginalia.application_name = nil
    ActiveSupport::Notifications.unsubscribe "sql.active_record"
  end
end
