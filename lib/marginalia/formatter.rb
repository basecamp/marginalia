# frozen_string_literal: true
module Marginalia
  class Formatter
    attr_reader :key_value_separator

    SUPPORTED_QUOTE_VALUES = %i[
      none
      single
    ].freeze

    # @param [String] key_value_separator: indicates the string used for
    # separating keys and values.
    #
    # @param [Symbol] quote_values: indicates how values will be formatted (eg:
    # in single quotes, not quoted at all, etc)
    def initialize(key_value_separator:, quote_values:)
      unless SUPPORTED_QUOTE_VALUES.include?(quote_values)
        raise ArgumentError, "Quote_values arg is unsupported: #{quote_values}"
      end
      @key_value_separator = key_value_separator
      @quote_values = quote_values
    end

    # @param [string] value
    # @return [String] The formatted value that will be used in our key-value
    # pairs.
    def quote_value(value)
      if @quote_values == :none
        value
      else
        "'#{value.gsub("'", "\\\\'")}'"
      end
    end
  end

  class FormatterFactory
    SUPPORTED_FORMATTERS = %i[
      default
      sqlcommenter
    ].freeze

    # @param [Symbol] formatter: the kind of formatter we're building.
    # @return [Formatter]
    def self.from_symbol(formatter)
      unless SUPPORTED_FORMATTERS.include?(formatter)
        raise ArgumentError, "Formatter is unsupported: #{formatter}"
      end

      if formatter == :default
        Formatter.new(key_value_separator: ':', quote_values: :none)
      else
        Formatter.new(key_value_separator: '=', quote_values: :single)
      end
    end
  end
end
