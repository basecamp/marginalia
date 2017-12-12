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
    self.context.map {|k,v| "#{k}=#{v}"}.join(',')
  end

  private
    def self.context
      Thread.current[:marginalia_context] ||= {}
    end
end
