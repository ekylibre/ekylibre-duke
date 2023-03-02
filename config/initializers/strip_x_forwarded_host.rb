class StripXForwardedHost
  def initialize(app)
    @app = app
  end

  def call(env)
    env.delete('HTTP_X_FORWARDED_HOST')
    begin
      @app.call(env)
    rescue ActionController::InvalidAuthenticityToken => e
      binding.pry
    end
  end
end