module Duke
  class DukeWebchatController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create_assistant
      Assistant.new(api_key: WATSON_APIKEY, version: WATSON_VERSION, url: WATSON_URL)
    end

    def create_session
      render(json: create_assistant.session_creation(WATSON_EKYVITI_ID).to_json)
    end

    def create_session_assistant
      create_assistant.session_assistant_creation(WATSON_EKYVITI_ID)
    end

    def send_msg
      DukeSendJob.perform_later(session_id: params[:duke_id], intent: params[:user_intent], message: params[:msg], user_defined: user_defined)
      # assistant = create_assistant
      # auth = Assistant::Auth.new(session_id: params[:duke_id], assistant_id: params[:assistant_id])
      # if (intent = params[:user_intent]).present?
         # assistant.send_message_intent(auth: auth, intent: intent, message: params[:msg], user_defined: user_defined)
      # else
         # assistant.send_message(auth: auth, message: params[:msg], user_defined: user_defined)
      # end
      render json: {}
    end

    def api_details
      render json: { azure_key: AZURE_API_KEY, azure_region: AZURE_REGION }
    end

    private

      def user_defined
        if Rails.env.development?
          user_plan = 'ekyagri-performance'
          user_url = "#{NGROK_HTTPS_URL}/dukewatson"
        else
          user_plan = defined?(Saassy) ? Saassy.product_name : 'ekyagri'
          user_url = "#{request.protocol}#{request.host}/dukewatson"
        end
        if current_user
          {
            tenant: Ekylibre::Tenant.current,
            user_token: current_user.authentication_token,
            user_email: current_user.email,
            user_url: user_url,
            user_plan: user_plan
          }
        else
          {
            tenant: Ekylibre::Tenant.current
          }
        end
      end

  end
end
