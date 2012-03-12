require 'active_record'
require 'action_controller'

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

  def self.initialize!
    ActionController::Base.class_eval do
      def record_query_comment
        QueryComments.comment = "application:#{QueryComments.application_name || "rails"},controller:#{controller_name},action:#{action_name}"
        yield
      ensure
        QueryComments.comment = nil
      end
      around_filter :record_query_comment
    end

    if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
      ActiveRecord::ConnectionAdapters::Mysql2Adapter.module_eval do
        include QueryComments::ActiveRecordInstrumentation
        include QueryComments::ArelInstrumentation
      end
    end

    if defined? ActiveRecord::ConnectionAdapters::MysqlAdapter
      ActiveRecord::ConnectionAdapters::MysqlAdapter.module_eval do
        include QueryComments::ActiveRecordInstrumentation
        include QueryComments::ArelInstrumentation
      end
    end
  end
end
