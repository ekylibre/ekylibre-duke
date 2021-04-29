module Duke
  module Skill
    module HarvestReceptions
      class ParseTargets < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          newHarv = Duke::Skill::DukeHarvestReception.new(user_input: @event.user_input)
          newHarv.parse_specifics(:plant, :crop_groups, :date)
          update_targets(newHarv)
          adjust_retries(@event.options.previous)  # @current_asking to options.preious
          to_ibm
        end

        private

        # @param [DukeHarvestReception] harv
        def update_targets harv 
          if harv.plant.blank? && harv.crop_groups.blank? 
            pct_regex = harv.user_input.match(/(\d{1,2}) *(%|pour( )?cent(s)?)/)
            if pct_regex
              @crop_groups.to_a.each { |crop_group| crop_group[:area] = pct_regex[1]}
              @plant.to_a.each { |target| target[:area] = pct_regex[1]}
            end
          else  
            harv.find_ambiguity
            [:plant, :crop_groups, :ambiguities].each{|type| self.instance_variable_set("@#{type}", harv.send(type))}
            update_description harv.user_input
          end 
        end
        
      end
    end
  end
end