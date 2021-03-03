# frozen_string_literal: true

module Duke
  class Assistant
    include IBMWatson

    class Auth 
      # Authenticator class with SessionID and AssistantID
      attr_reader :session_id, :assistant_id
      
      def initialize(session_id:, assistant_id:)
        @session_id = session_id
        @assistant_id = assistant_id
      end

      def to_json
        {session_id: session_id, assistant_id: assistant_id}
      end
    end
    
    attr_reader :api_key, :version, :url, :authenticator

    # Creating an Assistant instance, basically at each Request, does not @return
    def initialize(api_key:, version:, url:)
      @api_key = api_key
      @version = version
      @url = url
      @authenticator = Authenticators::IamAuthenticator.new(
        apikey: api_key
      )
      @assistant = AssistantV2.new(
        version: version,
        authenticator: @authenticator
      )
      @assistant.service_url = url
    end
    
    # @return [Auth]
    def session_creation(assistant_id)
      response = @assistant.create_session(
        assistant_id: assistant_id
      )
      session_id = JSON.parse(JSON.pretty_generate(response.result))['session_id']
      Auth.new(session_id: session_id, assistant_id: assistant_id)
    end

    # @param [Auth] auth
    # @param [String] message
    # @param [String] user_id -> Current Account Email
    def send_message(auth:, message:, user_id:)
      body = {
        input: { text: message },
        context: {
          global: {
            system: {
              user_id: user_id
            }
          },
          skills: {
            "main skill": {
              user_defined: { tenant: Ekylibre::Tenant.current }
            }
          }
        }
      }
      DukeRequestJob.perform_later(build_url(auth), body, make_headers, auth.session_id)
    end

    # @param [Auth] auth
    # @param [String] intent
    # @param [String] message
    # @param [String] user_id -> Current Account Email
    def send_message_intent(auth:, intent:, message:, user_id:)
      body = {
        input: { text: message,
                 intents: [{intent: intent,
                            confidence: 1 }]},
        context: {
          global: {
            system: {
              user_id: user_id
            }
          },
          skills: {
            "main skill": {
              user_defined: { tenant: Ekylibre::Tenant.current }
            }
          }
        }
      }
    DukeRequestJob.perform_later(build_url(auth), body, make_headers, auth.session_id)
    end
    
    private
    # Returns correct API URL
    def build_url(auth)
      "#{@url}/v2/assistants/#{auth.assistant_id}/sessions/#{auth.session_id}/message?version=#{@version}"
    end
    
    # Creating API-accepted headers for IBM Watson
    def make_headers
      headers = Common.new.get_sdk_headers(:conversation, :V2, :message).merge({"Accept": "application/json",
                                                                                "Content-Type": "application/json"})
      @authenticator.authenticate(headers)
      headers
    end
  end
end
