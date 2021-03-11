class DukeRequestJob < ApplicationJob
  include HTTParty
  include Pusher
  queue_as :duke

  def perform(url, body, headers, session_id)
    response = HTTParty.post(HTTP::URI.parse(url), :headers => HTTP::Headers.coerce(headers), :body => body.to_json)
    Pusher.trigger(session_id, 'duke', {
      message: response['output']['generic']
    })
  end
end
