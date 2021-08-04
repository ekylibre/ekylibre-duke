module Duke
  module Skill
    module Redirections
      class ToAccountingFog < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @journal = Duke::DukeMatchingArray.new
          extract_best(:journal)
        end

        # Redirects to accounting fog with doc on current financialYear or on specified journal
        def handle
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
