require 'marginalia'

module Marginalia
  if defined? Rails::Railtie
    require 'rails/railtie'

    class Railtie < Rails::Railtie
      initializer 'marginalia.insert' do
        ActiveSupport.on_load :active_record do
          Marginalia::Railtie.insert_into_active_record
        end

        ActiveSupport.on_load :action_controller do
          Marginalia::Railtie.insert_into_action_controller
        end

        ActiveSupport.on_load :active_job do
          Marginalia::Railtie.insert_into_active_job
        end
      end
    end
  end

  class Railtie
    def self.insert
      insert_into_active_record
      insert_into_action_controller
      insert_into_active_job
    end

    def self.insert_into_active_job
      if defined? ActiveJob::Base
        ActiveJob::Base.class_eval do
          around_perform do |job, block|
            begin
              Marginalia::Comment.update_job! job
              block.call
            ensure
              Marginalia::Comment.clear_job!
            end
          end
        end
      end
    end

    def self.insert_into_action_controller
      ActionController::Base.send(:include, ActionControllerInstrumentation)
      if defined? ActionController::API
        ActionController::API.send(:include, ActionControllerInstrumentation)
      end
    end

    def self.insert_into_active_record
      if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
        ActiveRecord::ConnectionAdapters::Mysql2Adapter.module_eval do
          include Marginalia::ActiveRecordInstrumentation
        end
      end

      if defined? ActiveRecord::ConnectionAdapters::MysqlAdapter
        ActiveRecord::ConnectionAdapters::MysqlAdapter.module_eval do
          include Marginalia::ActiveRecordInstrumentation
        end
      end

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
  end
end
