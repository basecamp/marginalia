require 'active_record'

module Marginalia
  module ActiveRecordInstrumentation
    def self.install
      if defined? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.module_eval do
          include Marginalia::ActiveRecordInstrumentation
        end
      end

      if defined? ActiveRecord::ConnectionAdapters::SQLite3Adapter
        ActiveRecord::ConnectionAdapters::SQLite3Adapter.module_eval do
          include Marginalia::ActiveRecordInstrumentation
        end
      end
    end

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
      comment = Marginalia.construct_comment
      if comment.present? && !sql.include?(comment)
        "#{sql} #{comment}"
      else
        sql
      end
    end

    def execute_with_marginalia(sql, name = nil)
      execute_without_marginalia(annotate_sql(sql), name)
    end

    def exec_query_with_marginalia(sql, name = 'SQL', binds = [])
      exec_query_without_marginalia(annotate_sql(sql), name, binds)
    end

    if ActiveRecord::VERSION::MAJOR >= 5
      def exec_query_with_marginalia(sql, name = 'SQL', binds = [], options = {})
        options[:prepare] ||= false
        exec_query_without_marginalia(annotate_sql(sql), name, binds, options)
      end
    end

    def exec_delete_with_marginalia(sql, name = 'SQL', binds = [])
      exec_delete_without_marginalia(annotate_sql(sql), name, binds)
    end

    def exec_update_with_marginalia(sql, name = 'SQL', binds = [])
      exec_update_without_marginalia(annotate_sql(sql), name, binds)
    end

    def execute_and_clear_with_marginalia(sql, *args, &block)
      execute_and_clear_without_marginalia(annotate_sql(sql), *args, &block)
    end
  end
end
