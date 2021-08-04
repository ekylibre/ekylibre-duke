module Duke
  module Skill
    module HarvestReceptions
      class ParseDestinationQuantity < Duke::Skill::DukeHarvestReception

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Add destination quantity to press or container
        # options : {quantity: number parsed by ibm,
        #            specific: 'destination'||'press'
        #            index: index of element in list}
        def handle
          @user_input = @event.user_input
          value = extract_number_parameter(@event.options.quantity)
          unless value.nil?
            send("update_#{@event.options.specific}_quantity", @event.options.index, value)
            update_description(@event.user_input)
            reset_retries
          end
          to_ibm
        end

        private

          # @param [Integer] index : index of press inside @press
          # @param [Integer] value : Quantity in press(hl)
          def update_press_quantity(index, value)
            @press[index][:quantity] = value
          end

          # @param [Integer] index : index of container inside @destination
          # @param [Integer] value : Quantity in container(hl)
          def update_destination_quantity(index, value)
            @destination[index][:quantity] = value
          end

      end
    end
  end
end
