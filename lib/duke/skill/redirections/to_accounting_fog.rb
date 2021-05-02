module Duke
  module Skill
    module Redirections
      class ToAccountingFog < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input)
          @journal = Duke::DukeMatchingArray.new
          extract_best(:journal)
        end

        def handle
          # # modify params journal word to options.sss
          if @journal.blank?
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.current_fog', key: FinancialYear.current.id))
          else
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.fog', name: @journal.name, key: @journal.key))
          end
        end

      end
    end
  end
end
