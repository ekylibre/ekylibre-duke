module Duke
  class DukeWebchatController < ApplicationController
    include IBMWatson

    def init_webchat
      @@authenticator = Authenticators::IamAuthenticator.new(
        apikey: WATSON_APIKEY
      )
      @@assistant = AssistantV2.new(
        version: WATSON_VERSION,
        authenticator: @@authenticator
      )
      @@assistant.service_url = WATSON_URL
      Ekylibre::Tenant.switch Ekylibre::Tenant.current do 
        if Activity.availables.any? {|act| act[:family] == :vine_farming}
          @@assistant_id = WATSON_EKYVITI_ID
        else 
          @@assistant_id = WATSON_EKY_ID
        end 
      end 
      render html: "session_created"
    end 

    def create_session
      response = @@assistant.create_session(
        assistant_id: @@assistant_id
      )
      session_id = JSON.parse(JSON.pretty_generate(response.result))['session_id']
      render html: session_id
    end

    def render_msg
      headers = {}.merge!(Common.new.get_sdk_headers("conversation", "V2", "message"))
      headers["Accept"] = "application/json"
      headers["Content-Type"] = "application/json" 
      @@authenticator.authenticate(headers)
      url = "#{WATSON_URL}/v2/assistants/#{@@assistant_id}/sessions/#{params[:duke_id]}/message?version=#{WATSON_VERSION}"
      body = {"input":{"text": params[:msg]},"context":{"global":{"system":{"user_id":params[:user_id]}},"skills":{"main skill":{"user_defined":{"tenant": params[:tenant]}}}}}
      RequestWorker.perform_async(url, body, headers, params[:duke_id])
      render json: {}
    end

  end
end
