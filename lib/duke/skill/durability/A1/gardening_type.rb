module Duke
  module Skill
    module Durability
      module A1
        class GardeningType < Durability::IdeaArticle
          using Duke::Utils::DukeRefinements
          include Duke::Utils::BaseDuke

          def initialize(event)
            super(event, 'A1')
          end

          def handle
            if (val = shelter_gardening_value).nil?
              if val.is_a?(String)
                item('A1_1').set!(val, :string)
                item('A2_4', 'A2').set!(val, :string)
              else
                item('A1_1').set!(val, :boolean)
                item('A2_4', 'A2').set!(val, :boolean)
              end
              @component.update_global_score
              if @event.user_input.match(Duke::Utils::Regex.multiple_answers)
                varieties = Onoma::CropSet.find('sheltered_gardening_idea').varieties
                species = Activity.of_campaign(@campaign).select{|act| varieties.include? act.cultivation_variety.to_sym}
                                                        .map{|act| optionify(act.name, act.id.to_s)}
                return DukeResponse.new(
                  redirect: :more,
                  options: dynamic_options(I18n.t('idea.gardening_type'), species)
                )
              end
            end
            DukeResponse.new
          end

          private

            def shelter_gardening_value
              if btn_click_cancelled?(@event.user_input)
                nil
              elsif @event.user_input.match(Duke::Utils::Regex.multiple_answers)
                'both'
              else
                @event.user_input.eql?('sheltered')
              end
            end

        end
      end
    end
  end
end
