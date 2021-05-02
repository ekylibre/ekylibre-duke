module Duke
  module Skill
    module HarvestReceptions
      class ParseDestination < Duke::Skill::DukeHarvestReception

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        def handle
          new_reception = Duke::Skill::DukeHarvestReception.new(user_input: @event.user_input)
          new_reception.parse_specifics(:destination, :date)
          update_destination(new_reception)
          adjust_retries(@event.options.previous)
          to_ibm
        end

        private

          #  @param [DukeHarvestReception] harv
          def update_destination(harv)
            harv.find_ambiguity
            %i[destination ambiguities].each{|type| self.instance_variable_set("@#{type}", harv.send(type))}
            update_description harv.user_input
          end

      end
    end
  end
end
