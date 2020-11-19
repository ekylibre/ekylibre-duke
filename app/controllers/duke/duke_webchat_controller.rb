module Duke
  class DukeWebchatController < ApplicationController
    before_filter :create_assistant
    include IBMWatson

    def create_assistant 
      @authenticator = Authenticators::IamAuthenticator.new(
        apikey: WATSON_APIKEY
      )
      @assistant = AssistantV2.new(
        version: WATSON_VERSION,
        authenticator: @authenticator
      )
      @assistant.service_url = WATSON_URL
    end 
    
    def create_session
      if Activity.availables.any? {|act| act[:family] == :vine_farming}
        assistant_id = WATSON_EKYVITI_ID
      else 
        assistant_id = WATSON_EKY_ID
      end 
      response = @assistant.create_session(
        assistant_id: assistant_id
      )
      session_id = JSON.parse(JSON.pretty_generate(response.result))['session_id']
      render json: {:session_id => session_id, :assistant_id => assistant_id}
    end

    def send_msg
      headers = {}.merge!(Common.new.get_sdk_headers("conversation", "V2", "message"))
      headers["Accept"] = "application/json"
      headers["Content-Type"] = "application/json" 
      @authenticator.authenticate(headers)
      url = "#{WATSON_URL}/v2/assistants/#{params[:assistant_id]}/sessions/#{params[:duke_id]}/message?version=#{WATSON_VERSION}"
      if params[:user_intent].nil?
        body = {"input":{"text": params[:msg]},"context":{"global":{"system":{"user_id":params[:user_id]}},"skills":{"main skill":{"user_defined":{"tenant": params[:tenant]}}}}}
      else
        body = {"input":{"text": params[:msg], "intents":[{"intent": params[:user_intent],"confidence":1}]},"context":{"global":{"system":{"user_id":params[:user_id]}},"skills":{"main skill":{"user_defined":{"tenant": params[:tenant]}}}}}
      end
      RequestWorker.perform_async(url, body, headers, params[:duke_id])
      render json: {}
    end

  end
end
