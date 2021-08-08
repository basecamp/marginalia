module Marginalia

  # Alternative to ActiveJob Instrumentation for Sidekiq.
  module SidekiqInstrumentation

    class Middleware
      def call(worker, msg, queue)
        Marginalia::Comment.update_job! msg
        yield
      ensure
        Marginalia::Comment.clear_job!
      end
    end

    def self.enable!
      Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add Marginalia::SidekiqInstrumentation::Middleware
        end
      end
    end
  end

end
