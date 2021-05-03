module Duke
  module Skill
    module HarvestReceptions
      class AddPressing < Duke::Skill::DukeHarvestReception

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Add press to incoming harvest
        def handle
          new_reception = Duke::Skill::DukeHarvestReception.new(user_input: @event.user_input)
          new_reception.parse_specifics(:press, :date)
          update_press(new_reception)
          adjust_retries(@event.options.previous)
          to_ibm
        end

        private

          # @param [DukeHarvestReception] harv
          def update_press(harv)
            harv.find_ambiguity
            %i[press ambiguities].each{|type| self.instance_variable_set("@#{type}", harv.send(type))}
            update_description harv.user_input
          end

      end
    end
  end
end
