module Duke
  class DukeWebhooksController < ApplicationController
    # Maybe ovveride verify_authentificity_token with authenticate_by_token method ??
    skip_before_action :verify_authenticity_token    

    # check if token concords with user email for authentication
    def authenticate_by_token
      Ekylibre::Tenant.switch params[:main_param][:tenant] do
        if User.find_by(authentication_token: request.env['HTTP_EKYLIBRE_TOKEN']).email == request.env['HTTP_EKYLIBRE_EMAIL']
          handle_webhook
        end
      end
    end

    private 

    def handle_webhook
      event = ActiveSupport::HashWithIndifferentAccess.new(params[:main_param])
      class_ = ("Duke::Skill::#{event[:hook_skill]}").constantize.new
      I18n.with_locale(:fra) do
        response = class_.send "handle_#{event[:hook_request]}", event
        render json: response
      end 
    end

  end
end