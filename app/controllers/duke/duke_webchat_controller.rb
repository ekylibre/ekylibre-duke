module Duke
  class DukeWebchatController < ApplicationController
    include IBMWatson
    require "ibm_watson/authenticators"
    require "ibm_watson/assistant_v2"

    def initialize
      @authenticator = Authenticators::IamAuthenticator.new(
        apikey: "5boUgUgHnTAjNhjaN0X0CIpIs5w2z7YFZo-3PcNDP9OD"
      )
      @assistant = AssistantV2.new(
        version: "2020-04-01",
        authenticator: @authenticator
      )
      @assistant.service_url = "https://api.eu-gb.assistant.watson.cloud.ibm.com"
      @assistant_id = "8813ae7e-22f3-4ad8-ad89-9a9d69af1244"
      @webChat = Duke::DukeWebchat.new
    end

    def create_session
      session_id = @webChat.create_session(@assistant, @assistant_id)
      render html: session_id
    end

    def render_msg
      resp = @webChat.send_msg(@assistant, @assistant_id, params[:duke_id], params[:msg], params[:user_id], params[:tenant])
      render json: resp
    end

  end
end
