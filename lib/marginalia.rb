require 'marginalia/railtie'

module Marginalia
  mattr_accessor :comment, :application_name

  module ActiveRecordInstrumentation
    def self.included(instrumented_class)
      if defined? Rails.application
        Marginalia.application_name = Rails.application.class.name.split("::").first
      end
        instrumented_class.class_eval do
          if defined? :execute
            alias_method :execute_without_marginalia, :execute
            alias_method :execute, :execute_with_marginalia
          end
        end
    end

    def execute_with_marginalia(sql, name = nil)
      execute_without_marginalia("#{sql} /*#{Marginalia.comment}*/", name)
    end
  end

end
