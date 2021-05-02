module Duke
  module Skill
    module HarvestReceptions
      class ModifyQuantityTav < Duke::Skill::DukeHarvestReception

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        def handle
          new_reception = Duke::Skill::DukeHarvestReception.new(user_input: @event.user_input)
          new_reception.extract_quantity_tavp
          %w[quantity tav].each do |attr|
            @parameters[attr] = new_reception.parameters[attr] unless new_reception.parameters[attr].nil?
          end
          update_description(@event.user_input)
          to_ibm
        end

      end
    end
  end
end
