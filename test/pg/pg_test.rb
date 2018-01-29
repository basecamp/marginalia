require "minitest/autorun"
require 'mocha/test_unit'
require 'pg'
require 'marginalia'
require 'test_helpers'

# Shim for compatibility with older versions of MiniTest
MiniTest::Test = MiniTest::Unit::TestCase unless defined?(MiniTest::Test)

DB_NAME='pg_test'
DB_PORT=5455
LOG_FILE='pg_log'

# Override pg logic
Marginalia.install

TestHelpers.create_db(
  db_name: DB_NAME,
  db_port: DB_PORT,
  log_file: LOG_FILE
)

# create pg connection
$conn = PG.connect({
  host: "localhost",
  port: DB_PORT,
  dbname: DB_NAME,
  user: ENV["DB_USERNAME"] || `whoami`,
})

# Enable logging of queries to log file
query = <<~QUERY
SET log_statement = 'all';
QUERY

$conn.exec(query)

create_posts = <<~QUERY
CREATE TABLE IF NOT EXISTS posts (
  id INTEGER,
  title VARCHAR
);
QUERY

$conn.exec(create_posts)

class PgTest < MiniTest::Test
  def test_select_contains_comment
    Marginalia.set('app', 'foobar')
    select = "select * from posts;"
    $conn.exec(select)
    assert TestHelpers.file_contains_string(LOG_FILE, '/*app:foobar*/')
  end

  def test_crud_actions_contain_comment
    Marginalia.set('app', 'sync')
    create_record = "INSERT INTO POSTS VALUES (1, 'My Title')"
    $conn.exec(create_record)
    assert TestHelpers.file_contains_string(LOG_FILE, '/*app:sync*/')

    TestHelpers.truncate_file(LOG_FILE)

    Marginalia.set('app', 'api')
    update_query = <<~UPDATE
    UPDATE posts
    SET id = 2
    where id = 1
    UPDATE
    $conn.exec(update_query)

    assert TestHelpers.file_contains_string(LOG_FILE, '/*app:api*/')
    TestHelpers.truncate_file(LOG_FILE)

    Marginalia.set('app', 'foo')
    delete_record = "DELETE FROM POSTS where id = 2"
    $conn.exec(delete_record)

    assert TestHelpers.file_contains_string(LOG_FILE, '/*app:foo*/')
  end

  def teardown
    # truncate log file after each test run
    Marginalia.clear!
    TestHelpers.truncate_file(LOG_FILE)
  end
end
