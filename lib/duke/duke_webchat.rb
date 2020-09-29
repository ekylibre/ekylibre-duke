module Duke
  class DukeWebchat

    def create_session(assistant, assistant_id)
      response = assistant.create_session(
        assistant_id: assistant_id
      )
      session_id = JSON.parse(JSON.pretty_generate(response.result))['session_id']
      return session_id
    end

    def delete_session(assistant, assistant_id, duke_id)
      response = @assistant.delete_session(
        assistant_id: @assistant_id,
        session_id: duke_id
      )
      return ""
    end

    def send_msg(assistant, assistant_id, duke_id, msg, user_id, tenant)
      response = assistant.message(
        assistant_id: assistant_id,
        session_id: duke_id,
        input: {
          text: msg
        },
        context: {
             global: {
                 system: {
                     user_id: user_id
                 }
             },
             skills: {
                 "main skill": {
                     user_defined: {
                         tenant: tenant
                     }
                 }
             }
         }
      )
      jsonresp = JSON.parse(JSON.pretty_generate(response.result))
      return jsonresp['output']['generic']
    end


  end
end
