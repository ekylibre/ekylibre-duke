class DukeRequestJob < ApplicationJob
  include HTTParty
  queue_as :duke

  def perform(url, body, headers, session_id)
    response = HTTParty.post(HTTP::URI.parse(url), :headers => HTTP::Headers.coerce(headers), :body => body.to_json)
    ActionCable.server.broadcast 'duke',
      message: response['output']['generic'],
      room_id: session_id
  end
end
