module Duke
  module Skill
    module HarvestReceptions
      class ParseParameter < Duke::Skill::DukeHarvestReception

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        def handle
          @user_input = @event.user_input
          value = extract_number_parameter(@event.options.quantity) # modify @value in options.quantity
          unless value.nil?
            add_parameter(@event.options.specific, value) #  modify @parameter in options.specific
            update_description(@event.user_input)
            reset_retries
          end
          to_ibm
        end

        private

          #  @param [String] type : type_of parameter
          #  @param [String] value : Float.to_s
          def add_parameter(type, value)
            value = { rate: value.to_f, unit: find_quantity_unit } if type.to_sym == :quantity
            @parameters[type] = value
          end

          #  returns an unit from user_input
          def find_quantity_unit
            return 'kg' if @user_input.match('(?i)(kg|kilo)')
            return 't' if @user_input.match('(?i)\d *t\b|tonne')

            return 'hl'
          end

      end
    end
  end
end
