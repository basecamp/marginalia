require 'marginalia/railtie'
require 'marginalia/comment'

module Marginalia
  mattr_accessor :application_name

  module ActiveRecordLogSubscriberInstrumentation
    def self.included(instrumented_class)
      Marginalia::Comment.components = [:application, :controller, :action]

      instrumented_class.class_eval do
        if defined? :sql
          alias_method :sql_without_marginalia, :sql
          alias_method :sql, :sql_with_marginalia
        end
      end
    end

    # Extends the original method by stamping a comment together with the sql.
    def sql_with_marginalia(event)
      if comment = Marginalia::Comment.to_s
        event.payload[:sql] = "#{event.payload[:sql]} /*#{comment}*/"
      end

      sql_without_marginalia(event)
    end
  end
end
