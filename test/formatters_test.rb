require "minitest/autorun"

# Shim for compatibility with older versions of MiniTest
MiniTest::Test = MiniTest::Unit::TestCase unless defined?(MiniTest::Test)

require 'marginalia/formatter'

class FormatterTest < MiniTest::Test
  def test_factory_invalid_formatter
    assert_raises(ArgumentError) do
      Marginalia::FormatterFactory.from_symbol(:non_existing_formatter)
    end
  end

  def test_factory_invalid_quote_values
    assert_raises(ArgumentError) do
      Marginalia::Formatter.new(key_value_separator: ':', quote_values: :does_not_exist)
    end
  end

  def test_sqlcommenter_key_value_separator
    formatter = Marginalia::FormatterFactory.from_symbol(:sqlcommenter)
    assert_equal('=', formatter.key_value_separator)
  end

  def test_sqlcommenter_quote_value
    formatter = Marginalia::FormatterFactory.from_symbol(:sqlcommenter)
    assert_equal("'Joe\\'s Crab Shack'", formatter.quote_value("Joe's Crab Shack"))
  end
end
