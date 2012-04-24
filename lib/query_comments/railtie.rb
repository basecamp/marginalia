require 'query_comments'

module QueryComments
  if defined? Rails::Railtie
    require 'rails'

    class Railtie < Rails::Railtie
      initializer 'query_comments.insert' do
        ActiveSupport.on_load :active_record do
          QueryComments::Railtie.insert_into_active_record
        end

        ActiveSupport.on_load :action_controller do
          QueryComments::Railtie.insert_into_action_controller
        end
      end
    end
  end

  class Railtie
    def self.insert
      insert_into_active_record
      insert_into_action_controller
    end

    def self.insert_into_action_controller
      ActionController::Base.class_eval do
        def record_query_comment
          QueryComments.comment = "application:#{QueryComments.application_name || "rails"},controller:#{controller_name},action:#{action_name}"
          yield
        ensure
          QueryComments.comment = nil
        end
        around_filter :record_query_comment
      end
    end

    def self.insert_into_active_record
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
end
