require "minitest/autorun"
require 'mocha/test_unit'
require 'logger'
require 'sequel'
require 'marginalia'
require 'test_helpers'

# Shim for compatibility with older versions of MiniTest
MiniTest::Test = MiniTest::Unit::TestCase unless defined?(MiniTest::Test)

class PgTest < MiniTest::Test
  DB_PORT=5457
  DB_NAME='sequel_test'
  LOG_FILE='sequel_log'

  TestHelpers.create_db(
    db_name: DB_NAME,
    db_port: DB_PORT,
    log_file: LOG_FILE,
  )

  DB = Sequel.postgres(
    DB_NAME,
    host: 'localhost',
    port: DB_PORT,
  )

  query = <<~QUERY
    ALTER DATABASE #{DB_NAME};
    SET log_statement = 'all';
  QUERY
  DB.run(query)

  DB.run "CREATE TABLE IF NOT EXISTS posts (id INTEGER, title VARCHAR(255));"

  TestHelpers.truncate_file(LOG_FILE)

  def setup
    # Override pg logic
    Marginalia.install

    # Configure app
    Marginalia.set('app', 'foobar')

    @dataset = DB[:posts]
  end

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
    TestHelpers.truncate_file(LOG_FILE)
  end
end
