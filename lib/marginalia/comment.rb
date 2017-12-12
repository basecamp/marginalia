require 'socket'

module Marginalia
  module Comment
    def self.set(key, value)
      self.context[key] = value
    end

    def self.construct_comment
      self.context.map {|k,v| "#{k}=#{v}"}.join(',')
    end

    def self.clear!
      Thread.current[:marginalia_context] = {}
    end

    private
      def self.context
        Thread.current[:marginalia_context] ||= {}
      end
  end

end
