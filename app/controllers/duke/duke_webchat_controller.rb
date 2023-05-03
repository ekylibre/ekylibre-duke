module Duke
  class DukeWebchatController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create_assistant
      Assistant.new(api_key: WATSON_APIKEY, version: WATSON_VERSION, url: WATSON_URL)
    end

    def create_session
      render(json: create_assistant.session_creation(WATSON_ID).to_json)
    end

    def send_msg
      assistant = create_assistant
      auth = Assistant::Auth.new(session_id: params[:duke_id], assistant_id: params[:assistant_id])
      if (intent = params[:user_intent]).present?
        assistant.send_message_intent(auth: auth, intent: intent, message: params[:msg], user_defined: user_defined)
      else
        assistant.send_message(auth: auth, message: params[:msg], user_defined: user_defined)
      end
      render json: {}
    end

    def api_details
      render json: { azure_key: AZURE_API_KEY, azure_region: AZURE_REGION }
    end

    private

      def user_defined
        user_plan = 'ekyviti'
        base_url =  if Rails.env == 'development'
                      ENV.fetch('NGROK_HTTPS_URL') { raise 'NGROK_HTTPS_URL env variable should be set in dev mode' }
                    else
                      request.protocol + request.host
                    end
        user_url =
        if current_user
          {
            tenant: Ekylibre::Tenant.current,
            user_token: current_user.authentication_token,
            user_email: current_user.email,
            user_url: base_url + '/dukewatson',
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
