module Duke
  class DukeWebchatController < ApplicationController
    @@webChat = Duke::DukeWebchat.new
    @@msg = nil

    def create_session
      response = @@webChat.create_session(params[:user_id], params[:tenant])
      render json: response
    end

    def send_msg
      puts "on a recu le message et les params : #{params}"
      response = @@webChat.send_msg(params[:msg],params[:user_id], params[:tenant])
      render json: response
    end

    def delete_session
      response = @@webChat.delete_session
      render json: response
    end

  end
end
