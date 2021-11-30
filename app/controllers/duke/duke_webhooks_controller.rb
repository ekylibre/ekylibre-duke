module Duke
  class DukeWebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token

    # check if token concords with user email for authentication
    def webhook_token_auth
      main_params = JSON.parse(request.env['rack.input'].read)['main_param'].with_indifferent_access
      event = Duke::DukeEvent.new(main_params)
      begin
        Ekylibre::Tenant.switch event.tenant do
          if User.find_by(authentication_token: request.env['HTTP_X_EKYLIBRE_TOKEN']).email == request.env['HTTP_X_EKYLIBRE_EMAIL']
            handle_webhook(event)
          end
        end
      rescue StandardError => e
        puts e.class
        puts e.message
      end
    end

    private

      def handle_webhook(event)
        class_ = "Duke::Skill::#{event.handler}".constantize.new(event)
        I18n.with_locale(:fra) do
          response = class_.handle
          render json: response.as_json
        end
      end

  end
end
