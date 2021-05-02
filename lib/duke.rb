# External libs
require 'similar_text'
require 'ibm_watson'
require 'httparty'

require 'duke/utils/duke_refinements'
require 'duke/utils/base_duke'
require 'duke/skill/duke_article'
require 'duke/skill/duke_single_match'
require 'duke/skill/duke_intervention'
require 'duke/skill/duke_harvest_reception'

files = Dir[File.join(__dir__, '/duke/**/*')].reject{|fn| File.directory?(fn)}
files.each do |file|
  require file
end

module Duke
  def self.proc_entities_path
    File.join(File.dirname(__dir__), 'config', 'entities', 'procedures.json')
  end
end
