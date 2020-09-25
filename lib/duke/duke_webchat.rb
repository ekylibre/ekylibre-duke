module Duke
  class DukeWebchat
    include IBMWatson
    require "ibm_watson/authenticators"
    require "ibm_watson/assistant_v2"
    @@authenticator = nil
    @@assistant = nil
    @@session_id = nil
    @@assistant_id = "8813ae7e-22f3-4ad8-ad89-9a9d69af1244"

    def create_session(user_id, tenant)
      if @@session_id.nil?
        @@authenticator = Authenticators::IamAuthenticator.new(
          apikey: "5boUgUgHnTAjNhjaN0X0CIpIs5w2z7YFZo-3PcNDP9OD"
        )
        @@assistant = AssistantV2.new(
          version: "2020-04-01",
          authenticator: @@authenticator
        )
        @@assistant.service_url = "https://api.eu-gb.assistant.watson.cloud.ibm.com"
        response = @@assistant.create_session(
          assistant_id: @@assistant_id
        )
        @@session_id = JSON.parse(JSON.pretty_generate(response.result))['session_id']
        response = send_msg("", user_id, tenant)
        return response
      else
        return {}
      end
    end

    def delete_session
      unless @@assistant.nil?
        response = @@assistant.delete_session(
          assistant_id: @@assistant_id,
          session_id: @@session_id
        )
        @@authenticator = nil
        @@assistant = nil
        @@session_id = nil
      end
    end

    def send_msg(msg, user_id, tenant)
      puts("on lance le msg : #{msg} #{user_id} #{tenant}")
      response = @@assistant.message(
        assistant_id: @@assistant_id,
        session_id: @@session_id,
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
      puts("on a reussi à envoyer un message efficacement !")
      jsonresp = JSON.parse(JSON.pretty_generate(response.result))
      puts "voici la réponse qu'on a au message ! : #{jsonresp}\n\n\n\n\n\n\n\n\n\n"
      return jsonresp['output']['generic']
    end
  end
end
