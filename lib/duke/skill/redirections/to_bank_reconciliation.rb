module Duke
  module Skill
    module Redirections
      class ToBankReconciliation < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input)
          @bank_account = Duke::DukeMatchingArray.new
          extract_best(:bank_account)
          @event = event
        end

        def handle
          # # modify importtype opt.specific
          if @event.options.specific.present?
            Duke::DukeResponse.new(
              redirect: :over,
              sentence: I18n.t('duke.redirections.to_reconciliation_import', import: @event.options.specific)
            )
          elsif @bank_account.blank?
            w_account
          else
            Duke::DukeResponse.new(
              status: :over,
              sentence: I18n.t('duke.redirections.to_reconciliation_account', id: @bank_account.key, name: @bank_account.name)
            )
          end
        end

        private

          # Ask user which bank account he want's to select
          def w_account
            cashes = Cash.all.map{|cash| optionify(cash.name, cash.id.to_s)}
            options = dynamic_options(I18n.t('duke.redirections.which_reconciliation_account'), cashes)
            Duke::DukeResponse.new(redirect: :ask, options: options)
          end

      end
    end
  end
end
