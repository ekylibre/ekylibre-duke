module Duke
  class DukeWebhooksController < ApplicationController
    # Maybe ovveride verify_authentificity_token with authenticate_by_token method ??
    skip_before_action :verify_authenticity_token
    before_action :authenticate_by_token
    
    def handle_webhook
      event = ActiveSupport::HashWithIndifferentAccess.new(params[:main_param])
      class_ = ("Duke::Skill::#{event[:hook_skill]}").constantize.new
      Ekylibre::Tenant.switch event[:tenant] do
        I18n.with_locale(:fra) do
          response = class_.send "handle_#{event[:hook_request]}", event
          render json: response
        end 
      end 
    end

    private 

    # check if token concords with user email for authentication
    def authenticate_by_token
      if User.find_by_email(request.env['HTTP_EKYLIBRE_EMAIL']).authentication_token == request.env['HTTP_EKYLIBRE_TOKEN']
        handle_webhook
      else 
        logger.info('Unable to authenticate the user')
      end
    end

  end
end
