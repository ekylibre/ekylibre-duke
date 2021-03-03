module Duke
  class DukeBookKeeping < DukeArticle

    attr_accessor :user_input, :financial_year, :format, :fyHash

    def initialize(**args)
      super() 
      @financial_year = DukeMatchingArray.new
      args.each{|k, v| instance_variable_set("@#{k}", v)}
    end 

    # @param [String] year: optional financial_year param 
    # @return [Json] to_ibm
    def exchange_redirect(year) 
      @fyHash = fy(year)
      return disambiguate_fy if @fyHash.nil? 
      return {redirect: :already_open, sentence: I18n.t("duke.exports.exchange_already_opened", fy: @fyHash[:name], id: @fyHash[:key])} if FinancialYear.find_by_id(@fyHash[:key]).exchanges.any?{|exc| exc.opened?} 
      return {redirect: :create_journal, sentence: I18n.t("duke.exports.need_journal_creation")} if Journal.where("nature = 'various'").empty? 
      return {redirect: :add_accountant, sentence: I18n.t("duke.exports.need_fy_accountant", id: @fyHash[:key])} if FinancialYear.find_by_id(@fyHash[:key]).accountant.nil? 
      return {redirect: :modify_accountant, fy: @fyHash[:key], sentence: I18n.t("duke.exports.unconcording_accountants", accountant: FinancialYear.find_by_id(@fyHash[:key]).accountant.full_name)} if Journal.where("nature = 'various'").none?{|jr|jr.accountant == FinancialYear.find_by_id(@fyHash[:key]).accountant}
      return {redirect: :done, sentence: I18n.t("duke.exports.create_exchange", id: @fyHash[:key])}
    end 
    
    # @param [String] year: optional financial_year param 
    # @param [String] format: optional financial_year param
    # @return [Json] to_ibm
    def fec_redirect(year, format)
      @fyHash = fy(year)
      exportFormat = fec_format(format)
      return disambiguate_fy if @fyHash.nil? 
      return disambiguate_fec_format if exportFormat.nil? 
      ex = FinancialYear.find_by_id(@fyHash[:key])
      FecExportJob.perform_later(ex, ex.fec_format, 'year', User.find_by(email: @email), exportFormat.to_s, @session_id)
      return {redirect: :startedExport, sentence: I18n.t("duke.exports.fec_started_redirection", code: @fyHash[:name], id: @fyHash[:key])}
    end 

    def balance_sheet_redirect(printer, template_nature)
      @fyHash = fy
      return disambiguate_fy if @fyHash.nil?
      sentence = I18n.t("duke.exports.#{template_nature}_started", year: @fyHash[:name])
      PrinterJob.perform_later(printer, template: DocumentTemplate.find_by_nature(template_nature), financial_year: FinancialYear.find_by_id(@fyHash[:key]), perform_as: User.find_by(email: @email), duke_id: @session_id)
      return {redirect: :started, sentence: sentence}
    end 

    def closing_redirect(id)
      @fyHash = fy(id)
      return disambiguate_fy if @fyHash.nil? 
      return {redirect: :alreadyclosed, sentence: I18n.t("duke.exports.fy_already_closed", code: @fyHash[:name], id: fyHash[:key])} if FinancialYear.find_by_id(@fyHash[:key]).state.eql?("locked")
      return {redirect: :closed, sentence: I18n.t("duke.exports.closed_fy", code: @fyHash[:name], id: fyHash[:key])}
    end 

    def tax_redirect 
      @fyHash = fy
      return {sentence: I18n.t("duke.exports.no_tax_declaration")} unless FinancialYear.all.any?{|fy| !fy.tax_declaration_mode_none?}
      return {sentence: I18n.t("duke.exports.no_tax_on_fy", code: @fyHash[:name], id: @fyHash[:key])} if @fyHash.present? && FinancialYear.find_by_id(@fyHash[:key]).tax_declaration_mode_none? 
      return {sentence: I18n.t("duke.exports.tax_on_no_fy")} if @fyHash.blank?
      return {sentence: I18n.t("duke.exports.tax_on_fy", code: @fyHash[:name], id: @fyHash[:key])}
    end 

    def tax_declaration_redirect(tax_state)
      fYear = (FinancialYear.find_by_id(fy[:key]) if fy.present?)||nil
      url = "/backend/tax-declarations?utf8=✓&q="
      url += ("&state%5B%5D=#{tax_state}" if tax_state.present?)||"state%5B%5D=draft&state%5B%5D=validated&state%5B%5D=sent" 
      url += ("&period=#{fYear.started_on.strftime("%Y-%m-%d")}_#{fYear.stopped_on.strftime("%Y-%m-%d")}" if fYear.present?)||"&period=all"
      return {sentence: I18n.t("duke.redirections.to_tax_declaration_period",id: fYear.code, url: url)} if fYear.present?
      return {sentence: I18n.t("duke.redirections.to_tax_declaration", url: url)}
    end 

    private 

    # Correct financialYear ambiguity
    # @return [Json] to_ibm
    def disambiguate_fy  
      return {redirect: :createFinancialYear, sentence: I18n.t("duke.exports.need_financial_year_creation")} if FinancialYear.all.empty?
      options = dynamic_options(I18n.t("duke.exports.which_financial_year"), FinancialYear.all.map{|fY| optJsonify(fY.code, fY.id.to_s)})
      return {redirect: :ask_financialyear, options: options, format: fec_format}
    end 

    # Correct FEC_format ambiguity
    # @return [Json] to_ibm
    def disambiguate_fec_format
      options = dynamic_options(I18n.t("duke.exports.which_fec_format"), [optJsonify(:Texte, :text), optJsonify(:XML, :xml)])
      return {redirect: :ask_fec_format, options: options, financial_year: @fyHash[:key]}
    end 

    # @param [String] id - Stringified id if user click on suggestion
    # @return [Hash] financialYear id & name
    def fy(id=nil)
      return {key: id.to_i, name: FinancialYear.find_by_id(id.to_i).code} if id.present? && FinancialYear.all.collect(&:id).include?(id.to_i) 
      return {key: FinancialYear.first.id, name: FinancialYear.first.code} if FinancialYear.all.size.eql?(1) 
      return nil if @financial_year.empty?
      return @financial_year.max 
    end 

    # @param [String] format: Format if user clicked on btn-format
    # @return [String] 
    def fec_format(format=nil)
      return format if format.present? && [:text, :xml].include?(format.to_sym) 
      {text: /t(e)?xt/, xml: /xml/}.each do |key, reg|
        return key if @user_input.match(reg)
      end
      nil
    end 

  end 
end