module Duke
  class DukeWebchatController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create_assistant
      Assistant.new(api_key: WATSON_APIKEY, version: WATSON_VERSION, url: WATSON_URL)
    end 

    def create_session
      assistant_id = if Activity.availables.any? {|act| act[:family] == :vine_farming}
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
        assistant.send_message_intent(auth: auth, intent: intent, message: params[:msg], user_id: params[:user_id])
      else
        assistant.send_message(auth: auth, message: params[:msg], user_id: params[:user_id])
      end
      render json: {}
    end

    def api_details
      render json: {pusher_key: ENV['PUSHER_KEY'], azure_key: AZURE_API_KEY, azure_region: AZURE_REGION}
    end 

  end
end
