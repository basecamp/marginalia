require 'socket'

module Marginalia
  module Comment
    mattr_accessor :components, :lines_to_ignore
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
      ret = ''
      self.components.each do |c|
        component_value = self.send(c)
        if component_value.present?
          ret << "#{c.to_s}:#{component_value.to_s},"
        end
      end
      ret.chop!
      ret
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
        marginalia_job["class"] if marginalia_job
      end

      def self.line
        Marginalia::Comment.lines_to_ignore ||= /\.rvm|gem|vendor\/|marginalia|rbenv/
        last_line = caller.detect do |line|
          line !~ Marginalia::Comment.lines_to_ignore
        end
        if last_line
          root = if defined?(Rails) && Rails.respond_to?(:root)
            Rails.root.to_s
          elsif defined?(RAILS_ROOT)
            RAILS_ROOT
          else
            ""
          end
          if last_line.starts_with? root
            last_line = last_line[root.length..-1]
          end
          last_line
        end
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

      if Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new('3.2.19')
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

        def self.connection_config
          return if marginalia_adapter.pool.nil?
          marginalia_adapter.pool.spec.config
        end
      end
  end

end
