module Duke
  module Skill
    module Redirections
      class ToJournal < Duke::Skill::DukeSingleMatch
        using Duke::Utils::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input.duke_del(event.options.specific))
          @journal = Duke::DukeMatchingArray.new
          extract_best(:journal)
        end

        # Redirects to journals, or a specific one
        def handle
          if @journal.blank?
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.journals'))
          else
            Duke::DukeResponse.new(sentence: I18n.t('duke.redirections.journal', name: @journal.name, key: @journal.key))
          end
        end

      end
    end
  end
end
