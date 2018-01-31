require "minitest/autorun"
require 'mocha/test_unit'

require 'marginalia'

# Shim for compatibility with older versions of MiniTest
MiniTest::Test = MiniTest::Unit::TestCase unless defined?(MiniTest::Test)

class EscapeTest < MiniTest::Test
  def test_good_comment
    assert_equal Marginalia.escape_sql_comment('app:foo'), 'app:foo'
  end

  def test_bad_comments
    assert_equal Marginalia.escape_sql_comment('*/; DROP TABLE USERS;/*'), '; DROP TABLE USERS;'
    assert_equal Marginalia.escape_sql_comment('**//; DROP TABLE USERS;/*'), '; DROP TABLE USERS;'
  end
end
