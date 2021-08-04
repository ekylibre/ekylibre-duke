Rails.application.routes.draw do
  post '/dukewatson', to: 'duke/duke_webhooks#webhook_token_auth'
  post '/duke_init_webchat', to: 'duke/duke_webchat#init_webchat'
  post '/duke_create_session', to: 'duke/duke_webchat#create_session'
  post '/duke_send_msg', to: 'duke/duke_webchat#send_msg'
  get '/duke_api_details', to: 'duke/duke_webchat#api_details'
  mount ActionCable.server, at: '/cable'
end
