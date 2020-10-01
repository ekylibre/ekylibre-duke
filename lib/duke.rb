require "fuzzystringmatch"
require "ibm_watson"
require "duke/duke_webchat.rb"
require "duke/utils/duke_parsing"
require "duke/utils/intervention_utils"
require "duke/utils/harvest_reception_utils"
require "duke/interventions"
require "duke/harvest_receptions"
require "duke/version"
require "duke/rails/engine"

module Duke
  class WebChatRender < ApplicationController
    def render_webchat
      render partial: 'duke'
    end
  end
  wC = WebChatRender.new()
  wC.render_webchat()
end
