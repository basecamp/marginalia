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
          Marginalia::Comment.update!(self)
          yield
        ensure
          Marginalia::Comment.clear!
        end
        around_filter :record_query_comment
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

      # SQL queries made through PostgreSQLAdapter#exec_delete will not be annotated.
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
