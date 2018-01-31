require "minitest/autorun"
require 'mocha/test_unit'
require 'logger'
require 'sequel'
require 'marginalia'
require 'test_helpers'
require "tempfile"

# Shim for compatibility with older versions of MiniTest
MiniTest::Test = MiniTest::Unit::TestCase unless defined?(MiniTest::Test)

DB_NAME="marginalia_test"
LOG_FILE="tmp/marginalia_log"

class PgTest < MiniTest::Test
  DB = Sequel.postgres(
    DB_NAME,
    host: 'localhost',
    port: ENV['MARGINALIA_DB_PORT'],
  )

  query = <<~QUERY
    SET log_statement = 'all';
  QUERY
  DB.run(query)

  DB.run "DROP TABLE IF EXISTS posts"
  DB.run "CREATE TABLE posts (id INTEGER, title VARCHAR(255));"

  TestHelpers.truncate_file(LOG_FILE)

  # Override pg logic
  Marginalia.install

  def test_raw_sql_has_comments
    Marginalia.set('app', 'foobar')
    dataset = DB.from(:posts)
    dataset.all
    assert TestHelpers.file_contains_string(LOG_FILE, '/*app:foobar*/')
  end

  def test_crud_actions_contain_comment
    Marginalia.set('app', 'crud.insert')
    posts = DB.from(:posts)
    posts.insert(id: 1, title: "Insert")
    assert TestHelpers.file_contains_string(LOG_FILE, '/*app:crud.insert*/')

    Marginalia.set('app', 'crud.update')
    posts.where(id: 1).update(title: "Update")
    assert TestHelpers.file_contains_string(LOG_FILE, '/*app:crud.update*/')

    Marginalia.set('app', 'crud.delete')
    posts.where(id: 1).delete
    assert TestHelpers.file_contains_string(LOG_FILE, '/*app:crud.delete*/')
  end

  def teardown
    # truncate log file after each test run
    Marginalia.clear!
    TestHelpers.truncate_file(LOG_FILE)
  end
end
