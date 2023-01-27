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

      def to_json(*_args)
        { session_id: session_id, assistant_id: assistant_id }
      end
    end

    attr_reader :api_key, :version, :url, :authenticator

    # Creating an Assistant instance, basically at each Request, does not @return
    def initialize(api_key:, version:, url:, assistant_id: nil)
      @api_key = api_key
      @version = version
      @url = url
      @assistant_id = assistant_id
      @authenticator = Authenticators::IamAuthenticator.new(apikey: api_key)
      @assistant = AssistantV2.new(authenticator: @authenticator, version: version)
      @assistant.service_url = url
      if Rails.env.development?
        @assistant.configure_http_client(disable_ssl_verification: true)
      end
    end

    # @return [Auth]
    def session_creation(assistant_id)
      response = @assistant.create_session(
        assistant_id: assistant_id
      )
      session_id = JSON.parse(JSON.pretty_generate(response.result))['session_id']
      Auth.new(session_id: session_id, assistant_id: assistant_id)
    end

    # @return [Assistant]
    def session_assistant_creation(assistant_id)
      response = @assistant.create_session(assistant_id: assistant_id)
      response.result["session_id"]
    end

    def send_build_message(assistant_id, session_id, intent, message, user_defined)
      begin
        response = @assistant.message(
          assistant_id: assistant_id,
          session_id: session_id,
          input: build_input_message(intent: intent, message: message),
          context: build_context_message(user_defined)
        )
      rescue IBMCloudSdkCore::ApiException => e
        puts e.inspect.red
        raise StandardError.new("IBM Wastson API error : #{e.inspect}")
      end
    end

    def send_test_message(assistant_id, session_id, message)
      begin
        response = @assistant.message(
          assistant_id: assistant_id,
          session_id: session_id,
          input: { "text" => message },
          context: nil
        )
      rescue IBMCloudSdkCore::ApiException => e
        puts e.inspect.red
        raise StandardError.new("IBM Wastson API error : #{e.inspect}")
      end
    end

    def build_input_message(intent:, message:)
      if intent.present?
        { message_type: 'text', text: message, intents: [{ intent: intent, confidence: 1 }] }
      else
        { message_type: 'text', text: message }
      end
    end

    def build_context_message(user_defined)
      {
        global: {
          system: {
            user_id: user_defined[:user_email]
          }
        },
        skills: {
          user_defined: user_defined
        }
      }
    end

    # @param [Auth] auth
    # @param [String] message
    # @param [String] user_id -> Current Account Email
    def send_message(auth:, message:, user_defined:)
      body = {
        input: { text: message },
        context: {
          global: {
            system: {
              user_id: user_defined[:user_email]
            }
          },
          skills: {
            "main skill": {
              user_defined: user_defined
            }
          }
        }
      }
      DukeRequestJob.perform_later(build_url(auth), body, make_headers, auth.session_id)
    end

    # @param [Auth] auth
    # @param [String] intent
    # @param [String] message
    # @param [String] user_id -> Current Account Email
    def send_message_intent(auth:, intent:, message:, user_defined:)
      body = {
        input: { text: message,
                 intents: [{ intent: intent,
                            confidence: 1 }] },
        context: {
          global: {
            system: {
              user_id: user_defined[:user_email]
            }
          },
          skills: {
            "main skill": {
              user_defined: user_defined
            }
          }
        }
      }
      DukeRequestJob.perform_later(build_url(auth), body, make_headers, auth.session_id)
    end

    private
      # Returns correct API URL
      def build_url(auth)
        ibm_url = "#{@url}/v2/assistants/#{auth.assistant_id}/sessions/#{auth.session_id}/message?version=#{@version}"
        puts "ibm_url #{ibm_url.inspect.green}"
        ibm_url
      end

      # Creating API-accepted headers for IBM Watson
      def make_headers
        headers = Common.new.get_sdk_headers(:conversation, :V2, :message).merge({ Accept: 'application/json',
                                                                                  "Content-Type": 'application/json' })
        @authenticator.authenticate(headers)
        puts "headers #{headers.inspect.green}"
        headers
      end
  end
end
