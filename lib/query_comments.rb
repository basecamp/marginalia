require 'active_record'
require 'action_controller'

require 'query_comments/railtie'

module QueryComments
  mattr_accessor :comment, :application_name

  module ActiveRecordInstrumentation
    def self.included(instrumented_class)
      instrumented_class.class_eval do
        alias_method_chain :execute, :query_comments
      end
    end

    def execute_with_query_comments(sql, name = nil)
      sql = "#{sql} /*#{QueryComments.comment}*/"
      execute_without_query_comments(sql, name)
    end
  end

  module ArelInstrumentation
    def self.included(instrumented_class)
      instrumented_class.class_eval do
        alias_method_chain :to_sql, :query_comments
      end
    end

    def to_sql_with_query_comments(arel)
      if arel.respond_to?(:ast)
        "#{visitor.accept(arel.ast)} /*#{QueryComments.comment}*/"
      else
        "#{arel} /*#{QueryComments.comment}*/"
      end
    end
  end
end
