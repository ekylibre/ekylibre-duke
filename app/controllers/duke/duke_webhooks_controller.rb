module Duke
  class DukeWebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token

    def handle_webhook
      event = ActiveSupport::HashWithIndifferentAccess.new(params[:main_param])
      class_ = ("Duke::#{event[:hook_skill]}").constantize.new
      Ekylibre::Tenant.switch event[:tenant] do
        I18n.with_locale(:fra) do
          response = class_.send "handle_#{event[:hook_request]}", event
          render json: response
        end 
      end 
    end

  end
end
