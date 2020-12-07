module Duke
  class DukeWebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token

    def handle_webhook
      event = params["main_param"]
      Ekylibre::Tenant.switch event[:tenant] do
        class_ = ("Duke::#{event["hook_skill"]}").constantize.new
        response = class_.send "handle_#{event["hook_request"]}", event
        render json: response
      end 
    end

  end
end
