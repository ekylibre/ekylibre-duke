module Duke
  module Skill
    module HarvestReceptions
      class ParseTargets < Duke::Skill::DukeHarvestReception

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Parses targets from sentence
        # options previous: last redirect
        def handle
          new_reception = Duke::Skill::DukeHarvestReception.new(user_input: @event.user_input)
          new_reception.parse_specifics(:plant, :crop_groups, :date)
          update_targets(new_reception)
          adjust_retries(@event.options.previous)  # @current_asking to options.preious
          to_ibm
        end

        private

          # @param [DukeHarvestReception] harv
          def update_targets(harv)
            if harv.plant.blank? && harv.crop_groups.blank?
              pct_regex = harv.user_input.match(Duke::Utils::Regex.percentage)
              if pct_regex
                @crop_groups.to_a.each { |crop_group| crop_group[:area] = pct_regex[1]}
                @plant.to_a.each { |target| target[:area] = pct_regex[1]}
              end
            else
              harv.find_ambiguity
              %i[plant crop_groups ambiguities].each{|type| self.instance_variable_set("@#{type}", harv.send(type))}
              update_description harv.user_input
            end
          end

      end
    end
  end
end
