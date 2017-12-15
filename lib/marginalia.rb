require 'marginalia/active_record_instrumentation'
require 'thread'

module Marginalia
  def self.install
    Marginalia::ActiveRecordInstrumentation.install
  end

  def self.set(key, value)
    self.context[key] = value
  end

  def self.clear!
    Thread.current[:marginalia_context] = {}
  end

  def self.construct_comment
    values = self.context.map {|k,v| "#{k}=#{v}"}.join(',')
    values = self.escape_sql_comment(values)
    '/*' + values + '*/'
  end

  def self.escape_sql_comment(str)
    str = str.dup
    while str.include?('/*') || str.include?('*/')
      str = str.gsub('/*', '').gsub('*/', '')
    end
    str
  end

  private
    def self.context
      Thread.current[:marginalia_context] ||= {}
    end
end
