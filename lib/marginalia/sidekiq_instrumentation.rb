module Marginalia

  # Alternative to ActiveJob Instrumentation for Sidekiq.
  # Apt for Instrumenting Sidekiq with Rails version < 4.2.
  module SidekiqInstrumentation

    class Middleware
      def call(worker, msg, queue)
        Marginalia::Comment.update_job! msg
        yield
      ensure
        Marginalia::Comment.clear_job!
      end
    end

    def self.enable!(annotate_delayed_class_extension: false)
      if annotate_delayed_class_extension
        Sidekiq::Extensions::DelayedClass.class_eval do
          # NOTE: Prefer redefining perform so that YAML is only parsed once.
          # Adding a Marginalia::Comment.components would incur an extra parsing on every query
          # in a delayed class
          def perform(yml)
            (target, method_name, args) = YAML.load(yml)
            annotation_context = marginalia_annotate_perform(target, method_name, args)
            Marginalia.with_annotation(annotation_context) do
              target.__send__(method_name, *args)
            end
          end
          
          # NOTE: Hook is called before perform is executed and may have
          # other side-effects
          # @return [String] annotation_context
          def marginalia_annotate_perform(target, method_name, args)
            "#{target}.#{method_name}"
          end
        end
      end
      Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add Marginalia::SidekiqInstrumentation::Middleware
        end
      end
    end
  end

end
