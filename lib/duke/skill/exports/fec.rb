module Duke
  module Skill
    module Exports
      class Fec < Duke::Skill::DukeSingleMatch

        def initialize(event)
          super(user_input: event.user_input, email: event.user_id, session_id: event.session_id)
          @financial_year = DukeMatchingArray.new
          extract_best(:financial_year)
          @event = event
        end

        #  Export acitivity tracability sheet
        def handle
          year_from_id(@event.options.specific)
          format = fec_format(@event.parsed)
          if @financial_year.nil?
            w_fy(fec_format: format)
          elsif format.nil?
            w_fec_format
          elsif (ex = FinancialYear.find_by_id(@financial_year[:key])).respond_to?('fec_format')
            FecExportJob.perform_later(ex, ex.fec_format, 'year', User.find_by(email: @email), format.to_s, @session_id)
            sentence = I18n.t('duke.exports.fec_started_redirection', code: @financial_year[:name], id: @financial_year[:key])
            Duke::DukeResponse.new(redirect: :startedExport, sentence: sentence)
          else
            Duke::DukeResponse.new(redirect: :startedExport, sentence: I18n.t('duke.exports.fec_ekyviti'))
          end
        end

        private

          # Correct FEC_format ambiguity
          def w_fec_format
            options = dynamic_options(I18n.t('duke.exports.which_fec_format'), [optionify(:Texte, :text), optionify(:XML, :xml)])
            Duke::DukeResponse.new(redirect: :ask_fec_format, options: options, parsed: @financial_year[:key])
          end

      end
    end
  end
end
