module Duke
  class DukeWebchatController < ApplicationController

    def create_assistant
      Assistant.new(api_key: WATSON_APIKEY, version: WATSON_VERSION, url: WATSON_URL)
    end

    def create_session
      assistant_id = if Saassy.ekyviti?
                       WATSON_EKYVITI_ID
                     else
                       WATSON_EKY_ID
                     end
      render(json: create_assistant.session_creation(assistant_id).to_json)
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
        if current_user
          {
            tenant: Ekylibre::Tenant.current,
            user_token: current_user.authentication_token,
            user_email: current_user.email
          }
        else
          {
            tenant: Ekylibre::Tenant.current
          }
        end
      end

  end
end
