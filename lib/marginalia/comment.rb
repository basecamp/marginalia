# frozen_string_literal: true

require 'socket'

module Marginalia
  module Comment
    mattr_accessor :components, :lines_to_ignore, :prepend_comment
    Marginalia::Comment.components ||= [:application, :controller, :action]

    def self.update!(controller = nil)
      self.marginalia_controller = controller
    end

    def self.update_job!(job)
      self.marginalia_job = job
    end

    def self.update_adapter!(adapter)
      self.marginalia_adapter = adapter
    end

    def self.construct_comment
      ret = String.new
      self.components.each do |c|
        component_value = self.send(c)
        if component_value.present?
          ret << "#{c}:#{component_value},"
        end
      end
      ret.chop!
      ret = self.escape_sql_comment(ret)
      ret
    end

    def self.construct_inline_comment
      return nil if inline_annotations.none?
      escape_sql_comment(inline_annotations.join)
    end

    def self.escape_sql_comment(str)
      while str.include?('/*') || str.include?('*/')
        str = str.gsub('/*', '').gsub('*/', '')
      end
      str
    end

    def self.clear!
      self.marginalia_controller = nil
    end

    def self.clear_job!
      self.marginalia_job = nil
    end

    private
      def self.marginalia_controller=(controller)
        Thread.current[:marginalia_controller] = controller
      end

      def self.marginalia_controller
        Thread.current[:marginalia_controller]
      end

      def self.marginalia_job=(job)
        Thread.current[:marginalia_job] = job
      end

      def self.marginalia_job
        Thread.current[:marginalia_job]
      end

      def self.marginalia_adapter=(adapter)
        Thread.current[:marginalia_adapter] = adapter
      end

      def self.marginalia_adapter
        Thread.current[:marginalia_adapter]
      end

      def self.application
        if defined?(Rails.application)
          Marginalia.application_name ||= Rails.application.class.name.split("::").first
        else
          Marginalia.application_name ||= "rails"
        end

        Marginalia.application_name
      end

      def self.job
        marginalia_job.class.name if marginalia_job
      end

      def self.controller
        marginalia_controller.controller_name if marginalia_controller.respond_to? :controller_name
      end

      def self.controller_with_namespace
        marginalia_controller.class.name if marginalia_controller
      end

      def self.action
        marginalia_controller.action_name if marginalia_controller.respond_to? :action_name
      end

      def self.sidekiq_job
        marginalia_job["class"] if marginalia_job && marginalia_job.respond_to?(:[])
      end

      DEFAULT_LINES_TO_IGNORE_REGEX = %r{\.rvm|/ruby/gems/|vendor/|marginalia|rbenv|monitor\.rb.*mon_synchronize}

      def self.line
        Marginalia::Comment.lines_to_ignore ||= DEFAULT_LINES_TO_IGNORE_REGEX

        last_line = caller_locations.find do |loc|
          loc.path !~ Marginalia::Comment.lines_to_ignore
        end

        if last_line
          root = if defined?(Rails) && Rails.respond_to?(:root)
            Rails.root.to_s
          elsif defined?(RAILS_ROOT)
            RAILS_ROOT
          else
            ""
          end

          if last_line.path.starts_with? root
            last_line = "#{last_line.path[root.length..]}:#{last_line.lineno}"
          else
            last_line = "#{last_line.path}:#{last_line.lineno}"
          end
        end

        last_line
      end

      def self.hostname
        @cached_hostname ||= Socket.gethostname
      end

      def self.pid
        Process.pid
      end

      def self.request_id
        if marginalia_controller.respond_to?(:request) && marginalia_controller.request.respond_to?(:uuid)
          marginalia_controller.request.uuid
        end
      end

      def self.socket
        if self.connection_config.present?
          self.connection_config[:socket]
        end
      end

      def self.db_host
        if self.connection_config.present?
          self.connection_config[:host]
        end
      end

      def self.database
        if self.connection_config.present?
          self.connection_config[:database]
        end
      end

      if Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new('6.1')
        def self.connection_config
          return if marginalia_adapter.pool.nil?
          marginalia_adapter.pool.spec.config
        end
      else
        def self.connection_config
          # `pool` might be a NullPool which has no db_config
          return unless marginalia_adapter.pool.respond_to?(:db_config)
          marginalia_adapter.pool.db_config.configuration_hash
        end
      end

      def self.inline_annotations
        Thread.current[:marginalia_inline_annotations] ||= []
      end
  end

end
