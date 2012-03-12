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
      execute_without_query_comments("#{sql} /*#{QueryComments.comment}*/", name)
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
        query = visitor.accept(arel.ast).to_s
      else
        query = arel.to_s
      end

      comment = "/*#{QueryComments.comment}*/"
      if query.ends_with?(comment)
        query
      else
        "#{query} #{comment}"
      end
    end
  end
end
