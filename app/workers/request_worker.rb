class RequestWorker
  include Sidekiq::Worker
  include HTTParty
  include Pusher


  def perform(url, body, headers, session_id)
    response = HTTParty.post(HTTP::URI.parse(url), :headers => HTTP::Headers.coerce(headers), :body => body.to_json, :debug_output => $stdout)
    Pusher.trigger(session_id, 'duke', {
      message: response['output']['generic']
    })
  end
end
