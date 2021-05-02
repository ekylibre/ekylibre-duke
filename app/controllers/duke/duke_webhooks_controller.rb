module Duke
  class DukeWebhooksController < ApplicationController
    # Maybe ovveride verify_authentificity_token with authenticate_by_token method ??
    skip_before_action :verify_authenticity_token

    # check if token concords with user email for authentication
    def webhook_token_auth
      event = Duke::DukeEvent.new(params[:main_param])
      begin
        Ekylibre::Tenant.switch event.tenant do
          if User.find_by(authentication_token: request.env['HTTP_EKYLIBRE_TOKEN']).email == request.env['HTTP_EKYLIBRE_EMAIL']
            handle_webhook(event)
          end
        end
      rescue StandardError => e
        puts e.class
        puts e.message
        puts e.trace
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
