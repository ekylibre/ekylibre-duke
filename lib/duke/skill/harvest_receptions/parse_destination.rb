module Duke
  module Skill
    module HarvestReceptions
      class ParseDestination < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          newHarv = Duke::Skill::DukeHarvestReception.new(user_input: @event.user_input)
          newHarv.parse_specifics(:destination, :date)
          update_destination(newHarv)
          adjust_retries(@event.options.previous) 
          to_ibm
        end
        
        private

        # @param [DukeHarvestReception] harv
        def update_destination harv
          harv.find_ambiguity
          [:destination, :ambiguities].each{|type| self.instance_variable_set("@#{type}", harv.send(type))}
          update_description harv.user_input
        end 

      end
    end
  end
end