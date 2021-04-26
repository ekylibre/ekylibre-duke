# External libs
require 'similar_text'
require "ibm_watson"
require 'httparty'
# Objects
require "duke/duke_refinements"
require "duke/base_duke"
require "duke/duke_ambiguity"
require "duke/duke_article"
require "duke/duke_harvest_reception"
require "duke/duke_intervention"
require "duke/duke_matching_array"
require "duke/duke_matching_item"
require "duke/duke_parser"
require "duke/duke_single_match"
# Skills
require "duke/skill/interventions"
require "duke/skill/redirections"
require "duke/skill/amounts"
require "duke/skill/issues"
require "duke/skill/exports"
require "duke/skill/harvest_receptions"
# Gem requirements
require "duke/version"
require "duke/engine"
module Duke

  def self.proc_entities_path
    File.join(File.dirname(__dir__), 'config', 'entities', 'procedures.json')
  end

end