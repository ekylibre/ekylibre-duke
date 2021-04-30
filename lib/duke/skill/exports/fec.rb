module Duke
  module Skill
    module Exports
      class Fec < Duke::Skill::DukeSingleMatch
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input, email: event.user_id, session_id: event.session_id)
          @financial_year = DukeMatchingArray.new
          extract_best(:financial_year)
          @event = event
        end 

        def handle
          # modify param fina et param fec format 
          # AND IN CODE !!!!!
          year_from_id(@event.options.specific)
          exportFormat = fec_format(@event.options.format)
          if @financial_year.nil?
            w_fy(fec_format: exportFormat)
          elsif exportFormat.nil?
            w_fec_format
          elsif (ex = FinancialYear.find_by_id(@financial_year[:key])).respond_to?("fec_format")
            FecExportJob.perform_later(ex, ex.fec_format, 'year', User.find_by(email: @email), exportFormat.to_s, @session_id)
            {redirect: :startedExport, sentence: I18n.t("duke.exports.fec_started_redirection", code: @financial_year[:name], id: @financial_year[:key])}
          else
            {redirect: :startedExport, sentence: I18n.t("duke.exports.fec_ekyviti")}
          end
        end

        private

        # Correct FEC_format ambiguity
        def w_fec_format
          options = dynamic_options(I18n.t("duke.exports.which_fec_format"), [optJsonify(:Texte, :text), optJsonify(:XML, :xml)])
          {redirect: :ask_fec_format, options: options, financial_year: @financial_year[:key]}
        end 
        
      end
    end
  end
end