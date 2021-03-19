module Duke
  class DukeBookKeeping < DukeArticle

    def initialize(**args)
      super() 
      args.each{|k, v| instance_variable_set("@#{k}", v)}
      extract_best(args.keys)
    end 

    # Redirect to journal
    def journal_redirect
      return {sentence: I18n.t("duke.redirections.journals")} if @journal.empty? 
      return {sentence: I18n.t("duke.redirections.journal", name: @journal.name, key: @journal.key)}
    end 

    # Redirect to fog
    def fog_redirect
      return {sentence: I18n.t("duke.redirections.current_fog", key: FinancialYear.current.id)} if @journal.empty? 
      return {sentence: I18n.t("duke.redirections.fog", name: @journal.name, key: @journal.key)}
    end 
    
    # Redirect to lettering
    def lettering_redirect
      return {sentence: I18n.t("duke.redirections.letterings")} if @account.empty? 
      return {sentence: I18n.t("duke.redirections.lettering", name: @account.name, key: @account.key)}
    end 

    # Redirect to immobilization creation
    def new_fixed_asset_redirect 
      return {redirect: :speak, sentence: I18n.t("duke.redirections.to_undefined_fixed_asset")} if @depreciables.empty? 
      return {redirect: :speak, sentence: I18n.t("duke.redirections.to_specific_fixed_asset",id: @depreciables.key, name: @depreciables.name)}
    end 

    # Redirect to financial year
    def fy_redirect 
      return {sentence: I18n.t("duke.redirections.financial_years")} if @financial_year.blank?
      return {sentence: I18n.t("duke.redirections.financial_year", key: @financial_year.key, name: @financial_year.name)}
    end 

    def bank_account_redirect 
      return {sentence: I18n.t("duke.redirections.to_bank_accounts")} if @bank_account.blank?
      return {sentence: I18n.t("duke.redirections.to_bank_account", name: @bank_account.name, id: @bank_account.key)}
    end 

    # Redirect to bank reconciliation
    def reconc_redirect import_type
      return {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_import", import: params[:import_type])} if import_type.present? 
      return w_account if @bank_account.blank?
      return {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_account", id: @cash.key, name: @cash.name)}
    end 

    # Redirect to a fixed asset show
    def fixed_asset_redirect state
      return {sentence: I18n.t("duke.redirections.to_fixed_asset_product", name: @fixed_asset.name, id: @fixed_asset.key)} if @fixed_asset.present?
      return {sentence: I18n.t("duke.redirections.to_fixed_asset_state", state: state)} if state.present? 
      return {sentence: I18n.t("duke.redirections.to_all_fixed_assets")}
    end 

    # Redirect to (Unpaid|All) sales, to specific customer or all
    def sale_redirect(type)
      type = (:all if type.nil?)|| :unpaid
      return {sentence: I18n.t("duke.redirections.to_#{type}_sales")} if @entities.empty?
      return {sentence: I18n.t("duke.redirections.to_#{type}_specific_sales" , entity: @entities.name)}
    end 

    # Redirect to (Unpaid|All) purchases, to specific supplier or all
    def purchase_redirect(type)
      type = (:all if type.nil?)|| :unpaid
      return {sentence: I18n.t("duke.redirections.to_#{type}_bills")} if @entities.empty?
      return {sentence: I18n.t("duke.redirections.to_#{type}_specific_bills" , entity: @entities.name)}
    end 

    # Redirect to bank reconciliation after btn-click to disambiguate bank account
    # @param [String] id - cash id
    def btn_reconc_redirect id 
      cash = Cash.find_by_id(id)
      return {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_account", id: cash.id, name: cash.name)} if cash.present?
      return {status: :over, sentence: I18n.t("duke.redirections.to_reconcialiation_accounts")}
    end 

    # Redirect to tax declarations show
    # @param [String] state - Tax declaration state
    def tax_declaration_redirect tax_state
      url = "/backend/tax-declarations?utf8=✓&q="
      url += ("&state%5B%5D=#{tax_state}" if tax_state.present?)||"state%5B%5D=draft&state%5B%5D=validated&state%5B%5D=sent" 
      url += ("&period=#{@financial_year.started_on.strftime("%Y-%m-%d")}_#{@financial_year.stopped_on.strftime("%Y-%m-%d")}" if @financial_year.present?)||"&period=all"
      return {sentence: I18n.t("duke.redirections.to_tax_declaration_period",id: @financial_year.code, url: url)} if @financial_year.present?
      return {sentence: I18n.t("duke.redirections.to_tax_declaration", url: url)}
    end 

    # Redirect to accounting exchange creation
    # @param [String] id - FinancialYear id
    def exchange_redirect id
      year_from_id(id)
      return w_fy if @financial_year.nil?
      return {redirect: :already_open, sentence: I18n.t("duke.exports.exchange_already_opened", fy: @financial_year[:name], id: @financial_year[:key])} if FinancialYear.find_by_id(@financial_year[:key]).exchanges.any?{|exc| exc.opened?} 
      return {redirect: :create_journal, sentence: I18n.t("duke.exports.need_journal_creation")} if Journal.where("nature = 'various'").empty? 
      return {redirect: :add_accountant, sentence: I18n.t("duke.exports.need_fy_accountant", id: @financial_year[:key])} if FinancialYear.find_by_id(@financial_year[:key]).accountant.nil? 
      return {redirect: :modify_accountant, fy: @financial_year[:key], sentence: I18n.t("duke.exports.unconcording_accountants", accountant: FinancialYear.find_by_id(@financial_year[:key]).accountant.full_name)} if Journal.where("nature = 'various'").none?{|jr|jr.accountant == FinancialYear.find_by_id(@financial_year[:key]).accountant}
      return {redirect: :done, sentence: I18n.t("duke.exports.create_exchange", id: @financial_year[:key])}
    end 

    # Redirect to tax declarations create
    # @param [String] id - FinancialYear id
    def tax_redirect id
      year_from_id(id)
      return {sentence: I18n.t("duke.exports.no_tax_declaration")} unless FinancialYear.all.any?{|fy| !fy.tax_declaration_mode_none?}
      return {sentence: I18n.t("duke.exports.no_tax_on_fy", code: @financial_year[:name], id: @financial_year[:key])} if @financial_year.present? && FinancialYear.find_by_id(@financial_year[:key]).tax_declaration_mode_none? 
      return {sentence: I18n.t("duke.exports.tax_on_no_fy")} if @financial_year.blank?
      return {sentence: I18n.t("duke.exports.tax_on_fy", code: @financial_year[:name], id: @financial_year[:key])}
    end 

    # Redirect to closing financial year
    def closing_redirect(fy_id)
      year_from_id(fy_id)
      return w_fy if @financial_year.nil? 
      return {redirect: :alreadyclosed, sentence: I18n.t("duke.exports.closed", code: @financial_year[:name], id: @financial_year[:key])} if FinancialYear.find_by_id(@financial_year[:key]).state.eql?("locked")
      return {redirect: :closed, sentence: I18n.t("duke.exports.to_close", code: @financial_year[:name], id: @financial_year[:key])}
    end 
    
    # Parse every Fec parameters and starts FEC export
    def fec_redirect(format)
      exportFormat = fec_format(format)
      return w_fy(fec_format: exportFormat) if @financial_year.nil? 
      return w_fec_format if exportFormat.nil? 
      ex = FinancialYear.find_by_id(@financial_year[:key])
      return {redirect: :startedExport, sentence: I18n.t("duke.exports.fec_ekyviti")} unless ex.respond_to?("fec_format")
      FecExportJob.perform_later(ex, ex.fec_format, 'year', User.find_by(email: @email), exportFormat.to_s, @session_id)
      return {redirect: :startedExport, sentence: I18n.t("duke.exports.fec_started_redirection", code: @financial_year[:name], id: @financial_year[:key])}
    end 

    # Parse financial year and start balance sheet export
    def balance_sheet_redirect(printer, template_nature)
      return w_fy if @financial_year.nil?
      sentence = I18n.t("duke.exports.#{template_nature}_started", year: @financial_year[:name])
      PrinterJob.perform_later(printer, template: DocumentTemplate.find_by_nature(template_nature), financial_year: FinancialYear.find_by_id(@financial_year[:key]), perform_as: User.find_by(email: @email), duke_id: @session_id)
      return {redirect: :started, sentence: sentence}
    end 

    private 

    attr_accessor :financial_year, :journal, :account, :bank_account, :fixed_asset, :depreciables, :entities

    # Returns best account
    def best_account
      @account.max
    end 

    # Returns best fixed_asset
    def best_fixed_asset 
      @fixed_asset.max
    end 

    # Returns best depreciable
    def best_depreciables
      @depreciables.max
    end
    
    # Returns best entity
    def best_entities
      @entities.max
    end 

    # Returns best bank_account
    def best_bank_account
      return {key: Cash.first.id, name: Cash.first.name} if Cash.all.size.eql?(1)
      @bank_account.max
    end 

    # Returns best journal
    def best_journal
      return {key: Journal.first.id, name: Journal.first.name} if Journal.all.size.eql?(1)
      @journal.max
    end 

    # Returns best financial year
    def best_financial_year 
      return {key: FinancialYear.first.id, name: FinancialYear.first.code} if FinancialYear.all.size.eql?(1) 
      @financial_year.max
    end 

    # Correct financialYear ambiguity
    def w_fy(fec_format: nil)
      return {redirect: :createFinancialYear, sentence: I18n.t("duke.exports.need_financial_year_creation")} if FinancialYear.all.empty?
      options = dynamic_options(I18n.t("duke.exports.which_financial_year"), FinancialYear.all.map{|fY| optJsonify(fY.code, fY.id.to_s)})
      {redirect: :ask_financialyear, options: options, format: fec_format}
    end 

    # Correct FEC_format ambiguity
    def w_fec_format
      options = dynamic_options(I18n.t("duke.exports.which_fec_format"), [optJsonify(:Texte, :text), optJsonify(:XML, :xml)])
      {redirect: :ask_fec_format, options: options, financial_year: @financial_year[:key]}
    end 

    # Ask user which bank account he want's to select
    def w_account 
      options = dynamic_options(I18n.t("duke.redirections.which_reconciliation_account"), Cash.all.map{|cash| optJsonify(cash.name, cash.id.to_s)})
      {status: :ask, options: options} 
    end 

    # Set @financialYear from btn-suggestion-click
    def year_from_id id
      @financial_year = {key: id.to_i, name: FinancialYear.find_by_id(id.to_i).code} if id.present? && FinancialYear.all.collect(&:id).include?(id.to_i) 
    end 

    # Extract uniq best element for each arg entry
    def extract_best(args)
      extract_user_specifics(jsonD: self.to_jsonD(args), level: 0.72)
      args.each do |arg|
        instance_variable_set("@#{arg}", send("best_#{arg}")) if respond_to?("best_#{arg}", true)
      end 
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