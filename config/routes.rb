Rails.application.routes.draw do
  post '/dukewatson', to: 'duke/duke_webhooks#handle_webhook'
  post '/duke_which_integration', to: 'duke/duke_webhooks#specify_integration'
end
