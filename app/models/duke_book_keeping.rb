module Duke
  class DukeBookKeeping < DukeArticle

    attr_accessor :financial_year

    def initialize(yParam: nil, **args)
      super() 
      args.each{|k, v| instance_variable_set("@#{k}", v)}
      @financial_year = extract_financial_year(yParam)
    end 

    # Redirect to closing financial year
    def closing_redirect
      return disambiguate_fy if @financial_year.nil? 
      return {redirect: :alreadyclosed, sentence: I18n.t("duke.exports.fy_already_closed", code: @financial_year[:name], id: @financial_year[:key])} if FinancialYear.find_by_id(@financial_year[:key]).state.eql?("locked")
      return {redirect: :closed, sentence: I18n.t("duke.exports.closed_fy", code: @financial_year[:name], id: @financial_year[:key])}
    end 

    # Redirect to tax declarations create
    def tax_redirect 
      return {sentence: I18n.t("duke.exports.no_tax_declaration")} unless FinancialYear.all.any?{|fy| !fy.tax_declaration_mode_none?}
      return {sentence: I18n.t("duke.exports.no_tax_on_fy", code: @financial_year[:name], id: @financial_year[:key])} if @financial_year.present? && FinancialYear.find_by_id(@financial_year[:key]).tax_declaration_mode_none? 
      return {sentence: I18n.t("duke.exports.tax_on_no_fy")} if @financial_year.blank?
      return {sentence: I18n.t("duke.exports.tax_on_fy", code: @financial_year[:name], id: @financial_year[:key])}
    end 

    # Redirect to tax declarations show
    def tax_declaration_redirect(tax_state)
      url = "/backend/tax-declarations?utf8=✓&q="
      url += ("&state%5B%5D=#{tax_state}" if tax_state.present?)||"state%5B%5D=draft&state%5B%5D=validated&state%5B%5D=sent" 
      url += ("&period=#{@financial_year.started_on.strftime("%Y-%m-%d")}_#{@financial_year.stopped_on.strftime("%Y-%m-%d")}" if @financial_year.present?)||"&period=all"
      return {sentence: I18n.t("duke.redirections.to_tax_declaration_period",id: @financial_year.code, url: url)} if @financial_year.present?
      return {sentence: I18n.t("duke.redirections.to_tax_declaration", url: url)}
    end 

    # Redirect to accounting exchange creation
    def exchange_redirect
      return disambiguate_fy if @financial_year.nil? 
      return {redirect: :already_open, sentence: I18n.t("duke.exports.exchange_already_opened", fy: @financial_year[:name], id: @financial_year[:key])} if FinancialYear.find_by_id(@financial_year[:key]).exchanges.any?{|exc| exc.opened?} 
      return {redirect: :create_journal, sentence: I18n.t("duke.exports.need_journal_creation")} if Journal.where("nature = 'various'").empty? 
      return {redirect: :add_accountant, sentence: I18n.t("duke.exports.need_fy_accountant", id: @financial_year[:key])} if FinancialYear.find_by_id(@financial_year[:key]).accountant.nil? 
      return {redirect: :modify_accountant, fy: @financial_year[:key], sentence: I18n.t("duke.exports.unconcording_accountants", accountant: FinancialYear.find_by_id(@financial_year[:key]).accountant.full_name)} if Journal.where("nature = 'various'").none?{|jr|jr.accountant == FinancialYear.find_by_id(@financial_year[:key]).accountant}
      return {redirect: :done, sentence: I18n.t("duke.exports.create_exchange", id: @financial_year[:key])}
    end 
    
    # Parse every Fec parameters and starts FEC export
    def fec_redirect(format)
      exportFormat = fec_format(format)
      return disambiguate_fy(fec_format: exportFormat) if @financial_year.nil? 
      return disambiguate_fec_format if exportFormat.nil? 
      ex = FinancialYear.find_by_id(@financial_year[:key])
      return {redirect: :startedExport, sentence: I18n.t("duke.exports.fec_ekyviti")} unless ex.respond_to?("fec_format")
      FecExportJob.perform_later(ex, ex.fec_format, 'year', User.find_by(email: @email), exportFormat.to_s, @session_id)
      return {redirect: :startedExport, sentence: I18n.t("duke.exports.fec_started_redirection", code: @financial_year[:name], id: @financial_year[:key])}
    end 

    # Parse financial year and start balance sheet export
    def balance_sheet_redirect(printer, template_nature)
      return disambiguate_fy if @financial_year.nil?
      sentence = I18n.t("duke.exports.#{template_nature}_started", year: @financial_year[:name])
      PrinterJob.perform_later(printer, template: DocumentTemplate.find_by_nature(template_nature), financial_year: FinancialYear.find_by_id(@financial_year[:key]), perform_as: User.find_by(email: @email), duke_id: @session_id)
      return {redirect: :started, sentence: sentence}
    end 

    private 

    # Correct financialYear ambiguity
    def disambiguate_fy(fec_format: nil)
      return {redirect: :createFinancialYear, sentence: I18n.t("duke.exports.need_financial_year_creation")} if FinancialYear.all.empty?
      options = dynamic_options(I18n.t("duke.exports.which_financial_year"), FinancialYear.all.map{|fY| optJsonify(fY.code, fY.id.to_s)})
      return {redirect: :ask_financialyear, options: options, format: fec_format}
    end 

    # Correct FEC_format ambiguity
    def disambiguate_fec_format
      options = dynamic_options(I18n.t("duke.exports.which_fec_format"), [optJsonify(:Texte, :text), optJsonify(:XML, :xml)])
      return {redirect: :ask_fec_format, options: options, financial_year: @financial_year[:key]}
    end 

    # Extract financial year from user utterance or optional id
    # @param [String] id - FinancialYear id if user clicked a btn-fY-suggestion
    def extract_financial_year(id)
      @financial_year = DukeMatchingArray.new
      extract_user_specifics(jsonD: self.to_jsonD(:financial_year), level: 0.72) 
      return {key: id.to_i, name: FinancialYear.find_by_id(id.to_i).code} if id.present? && FinancialYear.all.collect(&:id).include?(id.to_i) 
      return {key: FinancialYear.first.id, name: FinancialYear.first.code} if FinancialYear.all.size.eql?(1) 
      return nil if @financial_year.empty?
      return @financial_year.max 
    end 

    # Extract fec_format from user utterance
    # @param [String] format: Format if user clicked on btn-format-suggestion
    def fec_format(format=nil)
      return format if format.present? && [:text, :xml].include?(format.to_sym) 
      {text: /t(e)?xt/, xml: /xml/}.each do |key, reg|
        return key if @user_input.match(reg)
      end
      nil
    end 

  end 
end