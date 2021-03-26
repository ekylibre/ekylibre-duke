module Duke
  class DukeSingleMatch < DukeArticle

    def initialize(**args)
      super() 
      args.each{|k, v| instance_variable_set("@#{k}", v)}
      @matchArrs.concat([:financial_year, :entity, :activity_variety])
      extract_best(args.keys)
    end 

    # Redirect to (Unpaid|All) sales, to specific customer or all
    # @param [String] type - unpaid|nil
    def sale_redirect type
      type = (:all if type.nil?)|| :unpaid
      return {sentence: I18n.t("duke.redirections.to_#{type}_sales")} if @entity.blank?
      return {sentence: I18n.t("duke.redirections.to_#{type}_specific_sales" , entity: @entity.name)}
    end 

    # Redirect to (Unpaid|All) purchases, to specific supplier or all
    # @param [String] type - unpaid|nil
    def purchase_redirect(type)
      type = (:all if type.nil?)|| :unpaid
      return {sentence: I18n.t("duke.redirections.to_#{type}_bills")} if @entity.blank?
      return {sentence: I18n.t("duke.redirections.to_#{type}_specific_bills" , entity: @entity.name)}
    end 

    # Parse financial year and start balance sheet export
    # @param [String] id - FinancialYear id
    # @param [String] printer - which printer for printer_job
    # @param [String] template_nature - which template for printer_job
    def balance_sheet_redirect(id, printer, template_nature)
      year_from_id(id)
      return w_fy if @financial_year.nil?
      sentence = I18n.t("duke.exports.#{template_nature}_started", year: @financial_year[:name])
      PrinterJob.perform_later(printer, template: DocumentTemplate.find_by_nature(template_nature), financial_year: FinancialYear.find_by_id(@financial_year[:key]), perform_as: User.find_by(email: @email), duke_id: @session_id)
      return {redirect: :started, sentence: sentence}
    end 

    # Parse activity variety, and redirects to correct activity
    def activity_redirect 
      return {found: :no, sentence: I18n.t("duke.redirections.no_activity")} if @activity_variety.blank? # Return if no activity matched
      iterator = Activity.of_cultivation_variety(Activity.find_by_id(@activity_variety.key).cultivation_variety)
      return w_variety(iterator) if iterator.size > 1
      return {found: :yes, sentence: I18n.t("duke.redirections.activity", variety: @activity_variety.name), key: @activity_variety.key}
    end 

    # Redirects to activity if user clicked on btn-cultivation-variety-suggestion
    def activity_sugg_redirect
      act = Activity.find_by_id(@user_input.to_i)
      return {found: :yes, sentence: I18n.t("duke.redirections.activity", variety: act.cultivation_variety_name), key: act.id} if act.present?
      return {found: :no, sentence: I18n.t("duke.redirections.no_activity")}
    end 
    
    # Start tool Costs exports if a tool is recognized
    def tool_costs_redirect
      return {status: :no_tool, sentence: I18n.t("duke.exports.no_tool_found")} if @tool.blank?
      ToolCostExportJob.perform_later(equipment_ids: [@tool.key], campaign_ids: Campaign.current.ids, user: User.find_by(email: @email, duke_id: @session_id))
      return {status: :started, sentence: I18n.t("duke.exports.tool_export_started" , tool: @tool.name)}
    end 

    # Starts activity tracability exports
    def activity_traca_redirect
      return {status: :no_cultivation, sentence: I18n.t("duke.exports.no_var_found")} if @activity_variety.blank? 
      InterventionExportJob.perform_later(activity_id: @activity_variety.key, campaign_ids: Activity.find_by(id: @activity_variety.key).campaigns.pluck(:id), user: User.find_by(email: @email), duke_id: @session_id)
      return {status: :started, sentence: I18n.t("duke.exports.activity_export_started" , activity: @activity_variety.name)}
    end 

    private 

    attr_accessor :financial_year, :entity, :activity_variety
    
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

    # Returns best financial year
    def best_financial_year 
      return DukeMatchingItem.new(key: FinancialYear.first.id, name: FinancialYear.first.name) if FinancialYear.all.size.eql?(1) 
      @financial_year.max
    end 

    # Correct financialYear ambiguity
    def w_fy(fec_format: nil)
      return {redirect: :createFinancialYear, sentence: I18n.t("duke.exports.need_financial_year_creation")} if FinancialYear.all.empty?
      options = dynamic_options(I18n.t("duke.exports.which_financial_year"), FinancialYear.all.map{|fY| optJsonify(fY.code, fY.id.to_s)})
      {redirect: :ask_financialyear, options: options, format: fec_format}
    end 

    # Set @financialYear from btn-suggestion-click
    def year_from_id id
      @financial_year = {key: id.to_i, name: FinancialYear.find_by_id(id.to_i).code} if id.present? && FinancialYear.all.collect(&:id).include?(id.to_i) 
    end 

    # Extract uniq best element for each arg entry
    def extract_best(args)
      extract_user_specifics(jsonD: self.to_jsonD(args), level: 71)
      args.each do |arg|
        instance_variable_set("@#{arg}", send("best_#{arg}")) if respond_to?("best_#{arg}", true)
      end 
    end 

  end 
end
