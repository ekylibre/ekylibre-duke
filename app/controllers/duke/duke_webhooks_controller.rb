module Duke
  class DukeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

    def handle_webhook
      begin
        event = params["main_param"]
        class_ = ("Duke::#{event["hook_skill"]}").constantize.new
        response = class_.send "handle_#{event["hook_request"]}", event
      end
      render json: response
    end

    def specify_integration
      Ekylibre::Tenant.switch params[:tenant] do 
        if Activity.availables.any? {|act| act[:family] == :vine_farming}
          @integration_id = ENV['WATSON_INTEGRATION_ID_EKYVITI'] 
        else 
          @integration_id = ENV['WATSON_INTEGRATION_ID_EKY']
        end 
      end 
      render  html: @integration_id
    end 
  end
end
