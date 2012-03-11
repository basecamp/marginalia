# Could run in an initializer, or place in lib/query_commenter.rb or in a gem
module QueryComments

  module ActiveRecordInstrumentation
    def self.included(instrumented_class)
      instrumented_class.class_eval do
        alias_method :execute_without_instrumentation, :execute
        alias_method :execute, :execute_with_instrumentation
      end
    end

    def execute_with_instrumentation(sql, name = nil)
      sql = "#{sql} /*#{ActiveRecord::Base.query_comment}*/"
      execute_without_instrumentation(sql, name)
    end
  end

  class ActiveRecord::Base
    cattr_accessor :query_comment
  end

  def self.initialize!

    ActionController::Base.class_eval do
      def record_query_comment
        ActiveRecord::Base.query_comment = "application:BCX,controller:#{controller_name},action:#{action_name}"
        yield
      ensure
        ActiveRecord::Base.query_comment = nil
      end
      around_filter :record_query_comment
    end

    if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
      ActiveRecord::ConnectionAdapters::Mysql2Adapter.module_eval do
         include QueryComments::ActiveRecordInstrumentation 
      end
    end
    
    if defined? ActiveRecord::ConnectionAdapters::MysqlAdapter
      ActiveRecord::ConnectionAdapters::MysqlAdapter.module_eval do
         include QueryComments::ActiveRecordInstrumentation 
      end
    end
  end
end

# Via an initializer or railtie in a gem, call:
QueryComments.initialize!
