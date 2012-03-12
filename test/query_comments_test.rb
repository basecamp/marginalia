require 'test/unit'
require 'logger'
require 'pp'

require 'query_comments'

ActiveRecord::Base.establish_connection({
  :adapter  => "mysql",
  :host     => "localhost",
  :username => "root",
  :database => "query_comments_test"
})

class Post < ActiveRecord::Base
end

class PostsController < ActionController::Base
  def driver_only
    ActiveRecord::Base.connection.execute "select id from posts"
    render :nothing => true
  end

  def arel_only
    Post.all
    render :nothing => true
  end
end

unless Post.table_exists?
  ActiveRecord::Schema.define do
    create_table "posts", :force => true do |t|
    end
  end
end

QueryComments::Railtie.insert

class QueryCommentsTest < Test::Unit::TestCase
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

  def test_query_commenting_on_arel_with_no_action
    Post.count
    assert_match %r{/\*\*/$}, @queries.last
  end

  def test_query_commenting_on_arel_with_action
    PostsController.action(:arel_only).call(@env)
    assert_match %r{SELECT `posts`\.\* FROM `posts`  /\*application:rails,controller:posts,action:arel_only\*/$}, @queries.last
  end

  def test_configuring_application
    QueryComments.application_name = "customapp"
    PostsController.action(:driver_only).call(@env)

    assert_match %r{/\*application:customapp,controller:posts,action:driver_only\*/$}, @queries.first
  end

  def teardown
    QueryComments.application_name = nil
    ActiveSupport::Notifications.unsubscribe "sql.active_record"
  end
end
