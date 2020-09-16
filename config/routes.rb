Rails.application.routes.draw do
  post '/dukewatson', to: 'duke/duke_webhooks#handle_webhook'
end
