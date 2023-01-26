class DukeSendJob < ApplicationJob
  queue_as :duke

  def perform(session_id: nil, intent: nil, message: , user_defined: )
    assistant = Duke::Assistant.new(api_key: WATSON_APIKEY, version: WATSON_VERSION, url: WATSON_URL, assistant_id: WATSON_EKYVITI_ID)
    if session_id.nil?
      session_id = assistant.session_assistant_creation(WATSON_EKYVITI_ID)
    end
    begin
      response = assistant.send_build_message(WATSON_EKYVITI_ID, session_id, intent, message, user_defined)
    rescue IBMCloudSdkCore::ApiException => e
      puts e.inspect.red
    end
    ActionCable.server.broadcast "duke_#{session_id}", message: response['output']['generic']
  end
end
