module Duke
  class Redirections
    include Duke::BaseDuke

    # @param [String] user_input 
    # @return [Json] hasfound: bln|multiple, sentence & optional
    def handle_to_activity(params)
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], activity_variety: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:activity_variety, :date))
      return {found: :no, sentence: I18n.t("duke.redirections.no_activity")} if dukeArt.activity_variety.empty? # Return if no activity matched
      max_variety = dukeArt.activity_variety.max
      iterator = Activity.of_cultivation_variety(Activity.find_by_id(max_variety.key).cultivation_variety)
      if iterator.size > 1 # If more than one activity of this variety, ask which
        return {found: :multiple, optional: dynamic_options(I18n.t("duke.redirections.which_activity", variety: max_variety.name), iterator.map{|act| optJsonify(act.name, act.id.to_s)})}
      else # If only one, return
        return {found: :yes, sentence: I18n.t("duke.redirections.activity", variety: max_variety.name), key: max_variety.key}
      end 
    end 

    # @param [String] user_input
    # @return [Json]
    def handle_which_activity(params)
      begin # if user_clicked on Activity, user_input is it's id
        act = Activity.find_by_id(params[:user_input].to_i)
        return {found: :yes, sentence: I18n.t("duke.redirections.activity", variety: act.cultivation_variety_name), key: act.id}
      rescue # Return misunderstanding
        return {found: :no, sentence: I18n.t("duke.redirections.no_activity")}
      end 
    end 

    # @param [String] user_input
    # TODO :: REDO AS GLOBAL FallBack
    def handle_to_tool(params)
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], equipments: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:equipments, :date))
      return {found: :no, sentence: I18n.t("duke.redirections.not_finding")} if dukeArt.equipments.empty?
      return {found: :yes, sentence: I18n.t("duke.redirections.found_tool" , tool: dukeArt.equipments.max.name), key: dukeArt.equipments.max.key}
    end 

    # @param [String] user_input 
    # @param [String] purchase_type : unpaid|nil
    def handle_to_bill(params)
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], entities: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:entities, :date))
      purchase_type = (:all if params[:purchase_type].nil?)|| :unpaid
      return {sentence: I18n.t("duke.redirections.to_#{purchase_type}_bills")} if dukeArt.entities.empty?
      return {sentence: I18n.t("duke.redirections.to_#{purchase_type}_specific_bills" , entity: dukeArt.entities.max.name)}
    end 

    # @param [String] user_input 
    # @param [String] sale_type : unpaid|nil
    def handle_to_sale(params) 
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], entities: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:entities, :date))
      sale_type = (:all if params[:sale_type].nil?)|| :unpaid
      return {sentence: I18n.t("duke.redirections.to_#{sale_type}_sales")} if dukeArt.entities.empty?
      return {sentence: I18n.t("duke.redirections.to_#{sale_type}_specific_sales" , entity: dukeArt.entities.max.name)}
    end 

    def handle_get_sale_types(params) 
      return {} if SaleNature.all.size < 2
      return {options: dynamic_options(I18n.t("duke.redirections.which_sale_type"), SaleNature.all.map{|type| optJsonify(type.name, type.id.to_s)})}
    end 

    def handle_to_tax_declaration params 
      dukeAcc = Duke::DukeBookKeeping.new(user_input: params[:user_input])
      dukeAcc.extract_user_specifics(jsonD: dukeAcc.to_jsonD(:financial_year, :date), level: 0.72) 
      return dukeAcc.tax_declaration_redirect(params[:tax_state])
    end 

    def handle_to_new_fixed_asset params 
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], depreciables: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:depreciables), level: 0.80)
      return {redirect: :speak, sentence: I18n.t("duke.redirections.to_undefined_fixed_asset")} if dukeArt.depreciables.empty? 
      return {redirect: :speak, sentence: I18n.t("duke.redirections.to_specific_fixed_asset",id: dukeArt.depreciables.max.key, name: dukeArt.depreciables.max.name)}
    end 

    def handle_to_fixed_asset params 
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], fixed_asset: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:fixed_asset), level: 0.80)
      return {sentence: I18n.t("duke.redirections.to_fixed_asset_product", name: dukeArt.fixed_asset.max.name, id: dukeArt.fixed_asset.max.key)} if dukeArt.fixed_asset.present? 
      return {sentence: I18n.t("duke.redirections.to_fixed_asset_state", state: params[:asset_state])} if params[:asset_state].present? 
      return {sentence: I18n.t("duke.redirections.to_all_fixed_assets")} 
    end 

    def handle_to_bank_account params 
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], bank_account: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:bank_account), level: 0.80)
      return {sentence: I18n.t("duke.redirections.to_bank_accounts")} if dukeArt.bank_account.blank?
      return {sentence: I18n.t("duke.redirections.to_bank_account", name: dukeArt.bank_account.max.name, id: dukeArt.bank_account.max.key)}
    end 

    def handle_to_bank_reconciliation params 
      return {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_import", import: params[:import_type])} if params[:import_type].present? 
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], bank_account: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:bank_account), level: 0.80)
      return {status: :ask, options: dynamic_options(I18n.t("duke.redirections.which_reconciliation_account"), Cash.all.map{|cash| optJsonify(cash.name, cash.id.to_s)})} if dukeArt.bank_account.blank?
      cash = dukeArt.bank_account.max
      return {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_account", id: cash.key, name: cash.name)}
    end 
    
    def handle_to_bank_reconciliation_from_suggestion params 
      begin   
        cash = Cash.find_by_id(params[:user_input])
        return {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_account", id: cash.id, name: cash.name)}
      rescue Exception 
        return {status: :over, sentence: I18n.t("duke.redirections.to_reconcialiation_accounts")}
      end
    end 

    def handle_to_phyto_import params
      byebug
      if (prod = RegisteredPhytosanitaryProduct.find_by_id(params[:p_id])).present?
        return {status: :over, sentence: I18n.t("duke.import.phyto_id", id: prod.id, name: prod.name)} 
      elsif params[:aam].present? 
        prods = RegisteredPhytosanitaryProduct.select{|ph| ph.france_maaid == params[:aam]}
        return {status: :over, sentence: I18n.t("duke.import.invalid_maaid", id: params[:aam])} if prods.empty?
        return {status: :over, sentence: I18n.t("duke.import.phyto_id", id: prods.first.id, name: prods.first.name)} if prods.size.eql? 1 
        return {status: :ask, options: dynamic_options(I18n.t("duke.import.w_maaid"), prods.map{|p| optJsonify(p.name, p.id.to_s)})}
      else # Issue matching Thousands of Phyto Products names, just redirecting to phyto_main_page
        #dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], registered_phyto: Duke::DukeMatchingArray.new)
        #dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:registered_phyto), level: 0.80)
        return {status: :over, sentence: I18n.t("duke.import.all_phyto")} # if dukeArt.registered_phyto.blank? 
        #phyto = dukeArt.registered_phyto.max
        #return {status: :over, sentence: I18n.t("duke.import.phyto_id", id: phyto.key, name: phyto.name)}
      end
    end 

  end 
end