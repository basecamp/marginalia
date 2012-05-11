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
      ActiveRecord::LogSubscriber.module_eval do
        include Marginalia::ActiveRecordLogSubscriberInstrumentation
      end
    end
  end
end
