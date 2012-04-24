require 'query_comments/railtie'

module QueryComments
  mattr_accessor :comment, :application_name

  module ActiveRecordInstrumentation
    def self.included(instrumented_class)
      if defined? Rails.application
        QueryComments.application_name = Rails.application.class.name.split("::").first
      end
      instrumented_class.class_eval do
        alias_method :execute_without_query_comments, :execute
        alias_method :execute, :execute_with_query_comments
      end
    end

    def execute_with_query_comments(sql, name = nil)
      execute_without_query_comments("#{sql} /*#{QueryComments.comment}*/", name)
    end
  end

end
