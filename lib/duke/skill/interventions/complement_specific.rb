module Duke
  module Skill
    module Interventions
      class ComplementSpecific < Duke::Skill::DukeIntervention

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        def handle
          tmp_int = Duke::Skill::Interventions::ComplementSpecific.new(@event)
          tmp_int.user_input = @event.user_input
          tmp_int.parse_specific_buttons(@event.options.specific)
          concat_specific(int: tmp_int)
          to_ibm(modifiable: modification_candidates)
        end

        # Parse a specific item type, if user can answer via buttons
        # @param [String] sp : specific item type
        def parse_specific_buttons(specific)
          if btn_click_response? @user_input # If response type matches a multiple click response
            products = btn_click_responses(@user_input).map do |id| # Creating a list with all chosen products
              Product.find_by_id id
            end
            products.each{|product| unless product.nil?
                                      send(specific).push DukeMatchingItem.new(name: product.name,
                                                                              key: product.id,
                                                                              distance: 1,
                                                                              matched: product.name)
                                    end}
            add_input_rate if specific.to_sym == :input
            @specific = specific.to_sym
            @description = products.map(&:name).join(', ')
          else
            parse_specific(specific)
          end
        end

      end
    end
  end
end
