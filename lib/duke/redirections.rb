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

    # Return Sale types that can be dynamically displayed by IBM
    def handle_get_sale_types(params) 
      return {} if SaleNature.all.size < 2
      return {options: dynamic_options(I18n.t("duke.redirections.which_sale_type"), SaleNature.all.map{|type| optJsonify(type.name, type.id.to_s)})}
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

    # Redirect to journals, or specific journal by name
    # @param [String] journal_word : word that matched Journal Entity
    def handle_to_journal params 
      input = params[:user_input].del(params[:journal_word])
      Duke::DukeBookKeeping.new(user_input: input, journal: Duke::DukeMatchingArray.new).journal_redirect
    end 

    # Redirect to Accouting fog, for specific journal, or current fY
    def handle_to_accounting_fog params 
      Duke::DukeBookKeeping.new(user_input: params[:user_input], journal: Duke::DukeMatchingArray.new).fog_redirect
    end 

    # Redirect to accounting Lettering, for specific account, or all
    def handle_to_accounting_lettering params 
      input = params[:user_input].del(params[:lettering_word])
      Duke::DukeBookKeeping.new(user_input: input, account: Duke::DukeMatchingArray.new).lettering_redirect
    end 

    # Redirect to financial_year, specific account, or all
    def handle_to_financial_year params 
      Duke::DukeBookKeeping.new(user_input: params[:user_input], financial_year: Duke::DukeMatchingArray.new).fy_redirect 
    end 

    # Redirects to tax declaration
    # @param [String] tax_state - state of tax declaration with want to show
    def handle_to_tax_declaration params 
      Duke::DukeBookKeeping.new(user_input: params[:user_input]).tax_declaration_redirect(params[:tax_state])
    end 

    # Redirects to accounting exchange steps
    # @params [String] financial_year - optional Financial Year Id if clicked by user
    def handle_accounting_exchange params 
      Duke::DukeBookKeeping.new(user_input: params[:user_input]).exchange_redirect(params[:financial_year])
    end 

    # Redirect to tax_declaration creation
    def handle_tax_declaration params 
      Duke::DukeBookKeeping.new(user_input: params[:user_input]).tax_redirect(params[:financial_year])
    end 

    # Redirect to financial year closure
    # @params [String] financial_year - optional Financial Year Id if clicked by user
    def handle_close_financial_year params
      Duke::DukeBookKeeping.new(user_input: params[:user_input]).closing_redirect(params[:financial_year])
    end 

    # Redirect to bank_reconciliation
    # @param [String] import_type - CFONB | OFX
    def handle_to_bank_reconciliation params 
      Duke::DukeBookKeeping.new(user_input: input, bank_account: Duke::DukeMatchingArray.new).reconc_redirect(params[:import_type])
    end 

    # Redirect to bank reconciliation if user clicked on btn-cash-suggestion
    def handle_to_bank_reconciliation_from_suggestion params 
      Duke::DukeBookKeeping.new.btn_reconc_redirect(params[:user_input])
    end 

    # Redirect to fixed asset creation
    def handle_to_new_fixed_asset params 
      Duke::DukeBookKeeping.new(user_input: params[:user_input], depreciables: Duke::DukeMatchingArray.new).new_fixed_asset_redirect
    end 

    # Redirect to fixed asset show
    # @param [String] asset_state - State of fixed_asset
    def handle_to_fixed_asset params 
      Duke::DukeBookKeeping.new(user_input: params[:user_input], fixed_asset: Duke::DukeMatchingArray.new).fixed_asset_redirect(params[:asset_state])
    end 

    # Redirect to bank account(s)
    def handle_to_bank_account params 
      Duke::DukeBookKeeping.new(user_input: params[:user_input], bank_account: Duke::DukeMatchingArray.new).bank_account_redirect
    end 

    # @param [String] user_input 
    # @param [String] purchase_type : unpaid|nil
    def handle_to_bill(params)
      Duke::DukeBookKeeping.new(user_input: params[:user_input], entities: Duke::DukeMatchingArray.new).purchase_redirect(params[:purchase_type])
    end 

    # @param [String] user_input 
    # @param [String] sale_type : unpaid|nil
    def handle_to_sale(params)
      Duke::DukeBookKeeping.new(user_input: params[:user_input], entities: Duke::DukeMatchingArray.new).sale_redirect(params[:sale_type])
    end 

  end 
end