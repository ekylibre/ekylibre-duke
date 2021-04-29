module Duke
  module Skill
    module HarvestReceptions
      class AddComplementary < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          @user_input = @event.user_input
          update_complementary(@event.options.specific) # modify parameter to options.specific 
          to_ibm
        end
        
        private

        # @param [String] ComplementaryType
        def update_complementary type
          @parameters[:complementary] = {} if @parameters[:complementary].nil?
          @parameters[:complementary][type] = @user_input
          update_description(@user_input)
        end

      end
    end
  end
end