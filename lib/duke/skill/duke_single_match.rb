module Duke
  module Skill
    class DukeSingleMatch < DukeArticle

      def initialize(**args)
        super() 
        args.each{|k, v| instance_variable_set("@#{k}", v)}
        extract_best(args.keys)
      end 

      # Redirect to journal
      def journal_redirect
        if @journal.blank? 
          {sentence: I18n.t("duke.redirections.journals")} 
        else 
          {sentence: I18n.t("duke.redirections.journal", name: @journal.name, key: @journal.key)}
        end
      end 

      # Redirect to fog
      def fog_redirect
        if @journal.blank?
          {sentence: I18n.t("duke.redirections.current_fog", key: FinancialYear.current.id)}
        else 
          {sentence: I18n.t("duke.redirections.fog", name: @journal.name, key: @journal.key)}
        end
      end 
      
      # Redirect to lettering
      def lettering_redirect
        if @account.blank?
          {sentence: I18n.t("duke.redirections.letterings")}
        else 
          {sentence: I18n.t("duke.redirections.lettering", name: @account.name, key: @account.key)}
        end
      end 

      # Redirect to immobilization creation
      def new_fixed_asset_redirect
        if @depreciable.blank?
          {redirect: :speak, sentence: I18n.t("duke.redirections.to_undefined_fixed_asset")}
        else
          {redirect: :speak, sentence: I18n.t("duke.redirections.to_specific_fixed_asset",id: @depreciable.key, name: @depreciable.name)}
        end
      end 

      # Redirect to financial year
      def fy_redirect
        if @financial_year.blank?
          {sentence: I18n.t("duke.redirections.financial_years")}
        else
          {sentence: I18n.t("duke.redirections.financial_year", key: @financial_year.key, name: @financial_year.name)}
        end
      end 

      # Redirect to bank account
      def bank_account_redirect
        if @bank_account.blank?
          return {sentence: I18n.t("duke.redirections.to_bank_accounts")} 
        else
          return {sentence: I18n.t("duke.redirections.to_bank_account", name: @bank_account.name, id: @bank_account.key)}
        end
      end 

      # Redirect to account plans
      def accounts_plan_redirect id
        if id.present? 
          {sentence: I18n.t("duke.redirections.to_account_plan",id: id.delete("^0-9"))}
        else 
          {sentence: I18n.t("duke.redirections.to_account_plans")}
        end
      end 

      def fixed_asset_sale_redirect 
        if @fixed_asset.blank? 
          {sentence: I18n.t("duke.redirections.to_immobilisations_sale")}
        else  
          {sentence: I18n.t("duke.redirections.to_immobilisation_sale", name: @fixed_asset[:name], id: @fixed_asset[:key])}
        end
      end 

      # Redirect to bank reconciliation
      # @param [String] import_type - cfonb|ofx
      def reconc_redirect import_type
        if import_type.present?
          {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_import", import: import_type)}
        elsif @bank_account.blank?
          w_account
        else
          {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_account", id: @bank_account.key, name: @bank_account.name)}
        end
      end 

      # Redirect to a fixed asset show
      # @param [String] state - state of fixed assets we wish to access
      def fixed_asset_redirect state
        if @fixed_asset.present?
          {sentence: I18n.t("duke.redirections.to_fixed_asset_product", name: @fixed_asset.name, id: @fixed_asset.key)}
        elsif state.present? 
          {sentence: I18n.t("duke.redirections.to_fixed_asset_state", state: state)}
        else
          {sentence: I18n.t("duke.redirections.to_all_fixed_assets")}
        end
      end 

      # Redirect to (Unpaid|All) sales, to specific customer or all
      # @param [String] type - unpaid|nil
      def sale_redirect type
        filter = sale_filter(type)
        if @entity.blank?
          {sentence: I18n.t("duke.redirections.to_#{filter}_sales")}
        else 
          {sentence: I18n.t("duke.redirections.to_#{filter}_specific_sales" , entity: @entity.name)}
        end
      end 

      # Redirect to (Unpaid|All) purchases, to specific supplier or all
      # @param [String] type - unpaid|nil
      def purchase_redirect(type)
        filter = sale_filter(type)
        if @entity.blank?
          {sentence: I18n.t("duke.redirections.to_#{filter}_bills")}
        else
          {sentence: I18n.t("duke.redirections.to_#{filter}_specific_bills" , entity: @entity.name)}
        end
      end 

      # Redirect to bank reconciliation after btn-click to disambiguate bank account
      def btn_reconc_redirect
        cash = Cash.find_by_id(@user_input)
        if cash.present?
          {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_account", id: cash.id, name: cash.name)}
        else
          {status: :over, sentence: I18n.t("duke.redirections.to_reconcialiation_accounts")}
        end
      end 

      # Redirect to tax declarations show
      # @param [String] state - Tax declaration state
      def tax_declaration_redirect tax_state
        url = "/backend/tax-declarations?utf8=✓&q="
        url += ("&state%5B%5D=#{tax_state}" if tax_state.present?)||"state%5B%5D=draft&state%5B%5D=validated&state%5B%5D=sent" 
        url += ("&period=#{@financial_year.started_on.strftime("%Y-%m-%d")}_#{@financial_year.stopped_on.strftime("%Y-%m-%d")}" if @financial_year.present?)||"&period=all"
        if @financial_year.present?
          {sentence: I18n.t("duke.redirections.to_tax_declaration_period",id: @financial_year.code, url: url)}
        else
          {sentence: I18n.t("duke.redirections.to_tax_declaration", url: url)}
        end
      end 

      # Redirect to accounting exchange creation
      # @param [String] id - FinancialYear id
      def exchange_redirect id
        year_from_id(id)
        if @financial_year.nil?
          w_fy
        elsif FinancialYear.find_by_id(@financial_year[:key]).exchanges.any?{|exc| exc.opened?}
          {redirect: :already_open, sentence: I18n.t("duke.exports.exchange_already_opened", fy: @financial_year[:name], id: @financial_year[:key])}
        elsif Journal.where("nature = 'various'").empty? 
          {redirect: :create_journal, sentence: I18n.t("duke.exports.need_journal_creation")}
        elsif FinancialYear.find_by_id(@financial_year[:key]).accountant.nil?
          {redirect: :add_accountant, sentence: I18n.t("duke.exports.need_fy_accountant", id: @financial_year[:key])}
        elsif Journal.where("nature = 'various'").none?{|jr|jr.accountant == FinancialYear.find_by_id(@financial_year[:key]).accountant}
          {redirect: :modify_accountant, fy: @financial_year[:key], sentence: I18n.t("duke.exports.unconcording_accountants", accountant: FinancialYear.find_by_id(@financial_year[:key]).accountant.full_name)}
        else
          {redirect: :done, sentence: I18n.t("duke.exports.create_exchange", id: @financial_year[:key])}
        end
      end 

      # Redirect to tax declarations create
      # @param [String] id - FinancialYear id
      def tax_redirect id
        year_from_id(id)
        if FinancialYear.all.none?{|fy| !fy.tax_declaration_mode_none?}
          {sentence: I18n.t("duke.exports.no_tax_declaration")}
        elsif @financial_year.present? && FinancialYear.find_by_id(@financial_year[:key]).tax_declaration_mode_none? 
          {sentence: I18n.t("duke.exports.no_tax_on_fy", code: @financial_year[:name], id: @financial_year[:key])}
        elsif @financial_year.blank?
          {sentence: I18n.t("duke.exports.tax_on_no_fy")}
        else
          {sentence: I18n.t("duke.exports.tax_on_fy", code: @financial_year[:name], id: @financial_year[:key])}
        end
      end 

      # Redirect to closing financial year
      # @param [String] id - FinancialYear id
      def closing_redirect id
        year_from_id(id)
        if @financial_year.nil?
          w_fy
        elsif FinancialYear.find_by_id(@financial_year[:key]).closed?
          {redirect: :alreadyclosed, sentence: I18n.t("duke.exports.closed", code: @financial_year[:name], id: @financial_year[:key])}
        else
          {redirect: :closed, sentence: I18n.t("duke.exports.to_close", code: @financial_year[:name], id: @financial_year[:key])}
        end
      end 

      def locking_redirect id 
        year_from_id(id)
        if @financial_year.nil?
          w_fy 
        elsif FinancialYear.find_by_id(@financial_year[:key]).state.eql?("locked")
          {redirect: :alreadyclosed, sentence: I18n.t("duke.exports.locked", code: @financial_year[:name], id: @financial_year[:key])}
        else
          {redirect: :closed, sentence: I18n.t("duke.exports.to_lock", code: @financial_year[:name], id: @financial_year[:key])}
        end
      end 

      # Parse activity variety, and redirects to correct activity
      def activity_redirect
        if @activity_variety.blank?
          return {found: :no, sentence: I18n.t("duke.redirections.no_activity")} # Return if no activity matched
        elsif (iterator = Activity.of_cultivation_variety(Activity.find_by_id(@activity_variety.key).cultivation_variety)).size > 1
          w_variety(iterator)
        else
          {found: :yes, sentence: I18n.t("duke.redirections.activity", variety: @activity_variety.name), key: @activity_variety.key}
        end
      end 

      # Redirects to activity if user clicked on btn-cultivation-variety-suggestion
      def activity_sugg_redirect
        act = Activity.find_by_id(@user_input.to_i)
        if act.present?
          {found: :yes, sentence: I18n.t("duke.redirections.activity", variety: act.cultivation_variety_name), key: act.id} 
        else
          {found: :no, sentence: I18n.t("duke.redirections.no_activity")}
        end
      end 

      # Looks for tool|entity|activity_variety and redirects if matches something
      def fallback_redirect
        best = best_of(:tool, :entity, :activity_variety)
        if best.blank?
          {found: :no, sentence: I18n.t("duke.redirections.no_fallback")}
        else
          {found: :yes, sentence: I18n.t("duke.redirections.#{best[:type]}_fallback", id: best.key, name: best.name)}
        end
      end 

      # Parse every Fec parameters and starts FEC export
      # @param [String] id - FinancialYear id
      # @param [String] format - xml|txt = exporting format
      def fec_redirect(id, format)
        year_from_id(id)
        exportFormat = fec_format(format)
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

      # Parse financial year and start balance sheet export
      # @param [String] id - FinancialYear id
      # @param [String] printer - which printer for printer_job
      # @param [String] template_nature - which template for printer_job
      def balance_sheet_redirect(id, printer, template_nature)
        year_from_id(id)
        if @financial_year.nil?
          w_fy
        else
          PrinterJob.perform_later(printer, template: DocumentTemplate.find_by_nature(template_nature), financial_year: FinancialYear.find_by_id(@financial_year[:key]), perform_as: User.find_by(email: @email), duke_id: @session_id)
          {redirect: :started, sentence: I18n.t("duke.exports.#{template_nature}_started", year: @financial_year[:name])}
        end
      end 

      # Start tool Costs exports if a tool is recognized
      def tool_costs_redirect
        if @tool.blank?
          {status: :no_tool, sentence: I18n.t("duke.exports.no_tool_found")}
        else
          ToolCostExportJob.perform_later(equipment_ids: [@tool.key], campaign_ids: Campaign.current.ids, user: User.find_by(email: @email, duke_id: @session_id))
          {status: :started, sentence: I18n.t("duke.exports.tool_export_started" , tool: @tool.name)}
        end
      end 

      # Starts activity tracability exports
      def activity_traca_redirect
        if @activity_variety.blank?
          {status: :no_cultivation, sentence: I18n.t("duke.exports.no_var_found")}
        else
          InterventionExportJob.perform_later(activity_id: @activity_variety.key, campaign_ids: Activity.find_by(id: @activity_variety.key).campaigns.pluck(:id), user: User.find_by(email: @email), duke_id: @session_id)
          {status: :started, sentence: I18n.t("duke.exports.activity_export_started" , activity: @activity_variety.name)}
        end
      end 

      private 

      attr_accessor :financial_year, :journal, :account, :bank_account, :fixed_asset, :depreciable, :entity

      # Returns best account
      def best_account
        @account.max
      end 

      # Returns best fixed_asset
      def best_fixed_asset 
        @fixed_asset.max
      end 

      # Returns best depreciable
      def best_depreciable
        @depreciable.max
      end
      
      # Returns best entity
      def best_entity
        @entity.max
      end 

      # Returns best activity variety
      def best_activity_variety 
        @activity_variety.max
      end 

      # Returns best tool
      def best_tool 
        @tool.max
      end 

      # Returns best bank_account
      def best_bank_account
        return DukeMatchingItem.new(key: Cash.first.id, name: Cash.first.name) if Cash.all.size.eql?(1)
        @bank_account.max
      end 

      # Returns best journal
      def best_journal
        return DukeMatchingItem.new(key: Journal.first.id, name: Journal.first.name) if Journal.all.size.eql?(1)
        @journal.max
      end 

      # Returns best financial year
      def best_financial_year 
        return DukeMatchingItem.new(key: FinancialYear.first.id, name: FinancialYear.first.name) if FinancialYear.all.size.eql?(1) 
        @financial_year.max
      end 

      # Return best match across multiple entries, with it's type as an hash entry
      def best_of(*args)
        vals = args.map{|arg| send(arg).merge_h({type: arg}) if send(arg).present?}.compact
        return vals.max_by{|itm| itm.distance}
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

      # Ask user which variety he want's to select
      def w_variety vars
        opts = vars.map{|act| optJsonify(act.name, act.id.to_s)}
        return {found: :multiple, optional: dynamic_options(I18n.t("duke.redirections.which_activity", variety: @activity_variety.name), opts)}
      end 

      # Set @financialYear from btn-suggestion-click
      # @param [String] id - optional btn-click-fy-id
      def year_from_id id
        @financial_year = {key: id.to_i, name: FinancialYear.find_by_id(id.to_i).code} if id.present? && FinancialYear.all.collect(&:id).include?(id.to_i) 
      end 

      # Returns sale|purchase type 
      # @param [String] type - recognized saleType entity from IBM
      def sale_filter type 
        return :all if type.nil?
        :unpaid
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
end