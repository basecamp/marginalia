require 'marginalia/railtie'
require 'marginalia/comment'

module Marginalia
  mattr_accessor :application_name

  module ActiveRecordInstrumentation
    def self.included(instrumented_class)
      Marginalia::Comment.components = [:application, :controller, :action]
      instrumented_class.class_eval do
        if defined? :execute
          alias_method :execute_without_marginalia, :execute
          alias_method :execute, :execute_with_marginalia
        end
      end
    end

    def execute_with_marginalia(sql, name = nil)
      execute_without_marginalia("#{sql} /*#{Marginalia::Comment.to_s}*/", name)
    end
  end

end
