require "minitest/autorun"
require 'mocha/test_unit'
require 'pg'
require 'marginalia'
require 'test_helpers'
require 'tempfile'

# Shim for compatibility with older versions of MiniTest
MiniTest::Test = MiniTest::Unit::TestCase unless defined?(MiniTest::Test)

DB_NAME="marginalia_test"

# Override pg logic
Marginalia.install

# create pg connection
$conn = PG.connect({
  host: "localhost",
  port: ENV['MARGINALIA_DB_PORT'],
  dbname: DB_NAME,
})

# Enable logging of queries to log file
query = <<~QUERY
SET log_statement = 'all';
QUERY

$conn.exec(query)

drop_posts = <<~QUERY
DROP TABLE IF EXISTS posts;
QUERY

$conn.exec(drop_posts)

create_posts = <<~QUERY
CREATE TABLE posts (
  id INTEGER,
  title VARCHAR
);
QUERY

$conn.exec(create_posts)

class PgTest < MiniTest::Test
  def setup
    Marginalia.set('adapter', 'pg')
  end

  def test_select_contains_comment
    Marginalia.set('app', 'foobar')
    select = "select * from posts;"
    $conn.exec(select)
    assert TestHelpers.file_contains_string(ENV['MARGINALIA_LOG_FILE'], '/*adapter:pg,app:foobar*/')
  end

  def test_crud_actions_contain_comment
    Marginalia.set('app', 'crud.insert')
    create_record = "INSERT INTO POSTS VALUES (1, 'My Title')"
    $conn.exec(create_record)
    assert TestHelpers.file_contains_string(ENV['MARGINALIA_LOG_FILE'], '/*adapter:pg,app:crud.insert*/')

    Marginalia.set('app', 'crud.update')
    update_query = <<~UPDATE
    UPDATE posts
    SET id = 2
    where id = 1
    UPDATE
    $conn.exec(update_query)

    assert TestHelpers.file_contains_string(ENV['MARGINALIA_LOG_FILE'], '/*adapter:pg,app:crud.update*/')
    Marginalia.set('app', 'crud.delete')
    delete_record = "DELETE FROM POSTS where id = 2"
    $conn.exec(delete_record)

    assert TestHelpers.file_contains_string(ENV['MARGINALIA_LOG_FILE'], '/*adapter:pg,app:crud.delete*/')
  end

  def teardown
    # truncate log file after each test run
    Marginalia.clear!
  end
end
