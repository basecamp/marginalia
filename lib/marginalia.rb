require 'marginalia/railtie'
require 'marginalia/comment'
require 'marginalia/sidekiq_instrumentation'

module Marginalia
  mattr_accessor :application_name

  module ActiveRecordInstrumentation
    def self.included(instrumented_class)
      instrumented_class.class_eval do
        if instrumented_class.method_defined?(:execute)
          alias_method :execute_without_marginalia, :execute
          alias_method :execute, :execute_with_marginalia
        end

        if instrumented_class.private_method_defined?(:execute_and_clear)
          alias_method :execute_and_clear_without_marginalia, :execute_and_clear
          alias_method :execute_and_clear, :execute_and_clear_with_marginalia
        else
          is_mysql2 = defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter) &&
            ActiveRecord::ConnectionAdapters::Mysql2Adapter == instrumented_class
          # Dont instrument exec_query on mysql2 and AR 3.2+, as it calls execute internally
          unless is_mysql2 && ActiveRecord::VERSION::STRING > "3.1"
            if instrumented_class.method_defined?(:exec_query)
              alias_method :exec_query_without_marginalia, :exec_query
              alias_method :exec_query, :exec_query_with_marginalia
            end
          end

          is_postgres = defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) &&
            ActiveRecord::ConnectionAdapters::PostgreSQLAdapter == instrumented_class
          # Instrument exec_delete and exec_update on AR 3.2+, since they don't
          # call execute internally
          if is_postgres && ActiveRecord::VERSION::STRING > "3.1"
            if instrumented_class.method_defined?(:exec_delete)
              alias_method :exec_delete_without_marginalia, :exec_delete
              alias_method :exec_delete, :exec_delete_with_marginalia
            end
            if instrumented_class.method_defined?(:exec_update)
              alias_method :exec_update_without_marginalia, :exec_update
              alias_method :exec_update, :exec_update_with_marginalia
            end
          end
        end
      end
    end

    def annotate_sql(sql)
      Marginalia::Comment.update_adapter!(self)
      comment = Marginalia::Comment.construct_comment
      if comment.present? && !sql.include?(comment)
        sql = if Marginalia::Comment.prepend_comment
          "/*#{comment}*/ #{sql}"
        else
          "#{sql} /*#{comment}*/"
        end
      end
      inline_comment = Marginalia::Comment.construct_inline_comment
      if inline_comment.present? && !sql.include?(inline_comment)
        sql = if Marginalia::Comment.prepend_comment
          "/*#{inline_comment}*/ #{sql}"
        else
          "#{sql} /*#{inline_comment}*/"
        end
      end

      sql
    end

    def execute_with_marginalia(sql, name = nil)
      execute_without_marginalia(annotate_sql(sql), name)
    end

    def exec_query_with_marginalia(sql, name = 'SQL', binds = [])
      exec_query_without_marginalia(annotate_sql(sql), name, binds)
    end

    if ActiveRecord::VERSION::MAJOR >= 5
      def exec_query_with_marginalia(sql, name = 'SQL', binds = [], **options)
        options[:prepare] ||= false
        exec_query_without_marginalia(annotate_sql(sql), name, binds, **options)
      end
    end

    def exec_delete_with_marginalia(sql, name = 'SQL', binds = [])
      exec_delete_without_marginalia(annotate_sql(sql), name, binds)
    end

    def exec_update_with_marginalia(sql, name = 'SQL', binds = [])
      exec_update_without_marginalia(annotate_sql(sql), name, binds)
    end

    def execute_and_clear_with_marginalia(sql, *args, **kwargs, &block)
      execute_and_clear_without_marginalia(annotate_sql(sql), *args, **kwargs, &block)
    end
  end

  module ActionControllerInstrumentation
    def self.included(instrumented_class)
      instrumented_class.class_eval do
        if respond_to?(:around_action)
          around_action :record_query_comment
        else
          around_filter :record_query_comment
        end
      end
    end

    def record_query_comment
      Marginalia::Comment.update!(self)
      yield
    ensure
      Marginalia::Comment.clear!
    end
  end

  def self.with_annotation(comment, &block)
    Marginalia::Comment.inline_annotations.push(comment)
    block.call if block.present?
  ensure
    Marginalia::Comment.inline_annotations.pop
  end
end
