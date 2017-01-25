module Capybara
  module Angular
    class Waiter
      attr_accessor :page

      def initialize(page)
        @page = page
      end

      def wait_until_ready
        return unless angular_app?

        setup_ready

        start = Time.now
        until ready?
          timeout! if timeout?(start)
          if page_reloaded_on_wait?
            return unless angular_app?
            setup_ready
          end
          sleep(0.01)
        end
      end

      private

      def timeout?(start)
        Time.now - start > Capybara::Angular.default_max_wait_time
      end

      def timeout!
        raise Timeout::Error.new("timeout while waiting for angular")
      end

      def ready?
        page.evaluate_script("window.angularReady")
      end

      def angular_app?
        begin
          page.evaluate_script "(typeof $ != 'undefined') && (typeof window.angularApp != 'undefined')"
        rescue Capybara::NotSupportedByDriverError
          false
        end
      end

      def setup_ready
        page.execute_script <<-JS
          window.angularReady = false;
          var app = $('body');
          var injector = app.injector();

          injector.invoke(function($browser) {
            $browser.notifyWhenNoOutstandingRequests(function() {
              window.angularReady = true;
            });
          });
        JS
      end

      def page_reloaded_on_wait?
        page.evaluate_script("window.angularReady === undefined")
      end
    end
  end
end
