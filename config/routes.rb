Rails.application.routes.draw do
  post '/dukewatson', to: 'duke/duke_webhooks#handle_webhook'
  post '/duke_create_session', to: 'duke/duke_webchat#create_session'
  post '/duke_delete_session', to: 'duke/duke_webchat#delete_session'
  post '/duke_render_msg', to: 'duke/duke_webchat#render_msg'
end
