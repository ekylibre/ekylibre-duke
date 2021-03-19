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
    def handle_fallback(params)
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], tool: Duke::DukeMatchingArray.new,
                                                                       entities: Duke::DukeMatchingArray.new,
                                                                       activity_variety: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:tool, :date, :entities, :activity_variety))
      specifics = dukeArt.all_specifics(:tool, :entities, :activity_variety)
      return {} if specifics.empty? 
      max = specifics.max_by{|itm| itm[:distance]}
      return {found: :yes, sentence: I18n.t("duke.redirections.#{max[:type]}_fallback", id: max[:key], name: max[:name]) }
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

    # Return Sale types that can be dynamically displayed by IBM
    def handle_get_sale_types(params) 
      return {} if SaleNature.all.size < 2
      return {options: dynamic_options(I18n.t("duke.redirections.which_sale_type"), SaleNature.all.map{|type| optJsonify(type.name, type.id.to_s)})}
    end 

    # Redirects to tax declaration
    # @param [String] tax_state - state of tax declaration with want to show
    def handle_to_tax_declaration params 
      dukeAcc = Duke::DukeBookKeeping.new(user_input: params[:user_input], yParam: params[:financial_year])
      return dukeAcc.tax_declaration_redirect(params[:tax_state])
    end 

    # Redirects to accounting exchange steps
    # @params [String] financial_year - optional Financial Year Id if clicked by user
    def handle_accounting_exchange params 
      dukeAcc = Duke::DukeBookKeeping.new(user_input: params[:user_input], email: params[:user_id], session_id: params[:session_id], yParam: params[:financial_year])
      return dukeAcc.exchange_redirect
    end 

    # Redirect to tax_declaration creation
    def handle_tax_declaration params 
      dukeAcc = Duke::DukeBookKeeping.new(user_input: params[:user_input], yParam: params[:financial_year])
      return dukeAcc.tax_redirect 
    end 

    # Redirect to financial year closure
    # @params [String] financial_year - optional Financial Year Id if clicked by user
    def handle_close_financial_year params
      dukeAcc = Duke::DukeBookKeeping.new(user_input: params[:user_input], yParam: params[:financial_year])
      return dukeAcc.closing_redirect
    end 

    # Redirect to fixed asset creation
    def handle_to_new_fixed_asset params 
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], depreciables: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:depreciables), level: 0.80)
      return {redirect: :speak, sentence: I18n.t("duke.redirections.to_undefined_fixed_asset")} if dukeArt.depreciables.empty? 
      return {redirect: :speak, sentence: I18n.t("duke.redirections.to_specific_fixed_asset",id: dukeArt.depreciables.max.key, name: dukeArt.depreciables.max.name)}
    end 

    # Redirect to fixed asset show
    # @param [String] asset_state - State of fixed_asset
    def handle_to_fixed_asset params 
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], fixed_asset: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:fixed_asset), level: 0.80)
      return {sentence: I18n.t("duke.redirections.to_fixed_asset_product", name: dukeArt.fixed_asset.max.name, id: dukeArt.fixed_asset.max.key)} if dukeArt.fixed_asset.present? 
      return {sentence: I18n.t("duke.redirections.to_fixed_asset_state", state: params[:asset_state])} if params[:asset_state].present? 
      return {sentence: I18n.t("duke.redirections.to_all_fixed_assets")} 
    end 

    # Redirect to bank account(s)
    def handle_to_bank_account params 
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], bank_account: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:bank_account), level: 0.80)
      return {sentence: I18n.t("duke.redirections.to_bank_accounts")} if dukeArt.bank_account.blank?
      return {sentence: I18n.t("duke.redirections.to_bank_account", name: dukeArt.bank_account.max.name, id: dukeArt.bank_account.max.key)}
    end 

    # Redirect to bank_reconciliation
    # @param [String] import_type - CFONB | OFX
    def handle_to_bank_reconciliation params 
      return {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_import", import: params[:import_type])} if params[:import_type].present? 
      dukeArt = Duke::DukeArticle.new(user_input: params[:user_input], bank_account: Duke::DukeMatchingArray.new)
      dukeArt.extract_user_specifics(jsonD: dukeArt.to_jsonD(:bank_account), level: 0.80)
      return {status: :ask, options: dynamic_options(I18n.t("duke.redirections.which_reconciliation_account"), Cash.all.map{|cash| optJsonify(cash.name, cash.id.to_s)})} if dukeArt.bank_account.blank?
      cash = dukeArt.bank_account.max
      return {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_account", id: cash.key, name: cash.name)}
    end 
    
    # Redirect to bank reconciliation if user clicked on btn-cash-suggestion
    def handle_to_bank_reconciliation_from_suggestion params 
      begin   
        cash = Cash.find_by_id(params[:user_input])
        return {status: :over, sentence: I18n.t("duke.redirections.to_reconciliation_account", id: cash.id, name: cash.name)}
      rescue Exception 
        return {status: :over, sentence: I18n.t("duke.redirections.to_reconcialiation_accounts")}
      end
    end 

    # Redirect to phytosanitary import (by AAM id, or all)
    # @param [String] aam - aam number
    def handle_to_phyto_import params
      if (prod = RegisteredPhytosanitaryProduct.find_by_id(params[:p_id])).present?
        return {status: :over, sentence: I18n.t("duke.import.phyto_id", id: prod.id, name: prod.name)} 
      elsif params[:aam].present? 
        prods = RegisteredPhytosanitaryProduct.select{|ph| ph.france_maaid == params[:aam]}
        return {status: :over, sentence: I18n.t("duke.import.invalid_maaid", id: params[:aam])} if prods.empty?
        return {status: :over, sentence: I18n.t("duke.import.phyto_id", id: prods.first.id, name: prods.first.name)} if prods.size.eql? 1 
        return {status: :ask, options: dynamic_options(I18n.t("duke.import.w_maaid"), prods.map{|p| optJsonify(p.name, p.id.to_s)})}
      else # Issue matching Thousands of Phyto Products names, just redirecting to phyto_main_page
        return {status: :over, sentence: I18n.t("duke.import.all_phyto")}
      end
    end 

  end 
end