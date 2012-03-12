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

#ActiveSupport::LogSubscriber.colorize_logging = false
#ActiveRecord::Base.logger = Logger.new(STDOUT)

class Post < ActiveRecord::Base
end

unless Post.table_exists?
  ActiveRecord::Schema.define do
    create_table "posts", :force => true do |t|
      t.string "body"
    end
  end
end

QueryComments.initialize!

class QueryCommentsTest < Test::Unit::TestCase
  def setup
    @queries = []
    ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
      @queries << args.last[:sql]
    end
  end

  def test_blank_query
    Post.count
    assert_match %r{/\*\*/}, @queries.first
  end
end
