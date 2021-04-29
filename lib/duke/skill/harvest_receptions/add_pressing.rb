module Duke
  module Skill
    module HarvestReceptions
      class AddPressing < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          newHarv = Duke::Skill::DukeHarvestReception.new(user_input: @event.user_input)
          newHarv.parse_specifics(:press, :date)
          update_press(newHarv)
          adjust_retries(@event.options.previous)
          to_ibm
        end
        
        private

        # @param [DukeHarvestReception] harv
        def update_press harv 
          harv.find_ambiguity
          [:press, :ambiguities].each{|type| self.instance_variable_set("@#{type}", harv.send(type))}
          update_description harv.user_input
        end 

      end
    end
  end
end