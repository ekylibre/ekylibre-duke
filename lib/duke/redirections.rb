module Duke
  class Redirections
    include Duke::BaseDuke

    # Redirect to journals, or specific journal by name
    # @param [String] journal_word : word that matched Journal Entity
    def handle_to_journal params 
      input = params[:user_input].del(params[:journal_word])
      Duke::DukeSingleMatch.new(user_input: input,
                                journal: Duke::DukeMatchingArray.new).journal_redirect
    end 

    # Redirect to Accouting fog, for specific journal, or current fY
    def handle_to_accounting_fog params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                journal: Duke::DukeMatchingArray.new).fog_redirect
    end 

    # Redirect to accounting Lettering, for specific account, or all
    def handle_to_accounting_lettering params 
      input = params[:user_input].del(params[:lettering_word])
      Duke::DukeSingleMatch.new(user_input: input,
                                account: Duke::DukeMatchingArray.new).lettering_redirect
    end 

    # Redirect to financial_year, specific account, or all
    def handle_to_financial_year params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                financial_year: Duke::DukeMatchingArray.new).fy_redirect 
    end 

    # Redirects to tax declaration
    # @param [String] tax_state - state of tax declaration with want to show
    def handle_to_tax_declaration params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input]).tax_declaration_redirect(params[:tax_state])
    end 

    # Redirects to accounting exchange steps
    # @params [String] financial_year - optional Financial Year Id if clicked by user
    def handle_accounting_exchange params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input]).exchange_redirect(params[:financial_year])
    end 

    # Redirect to tax_declaration creation
    def handle_tax_declaration params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input]).tax_redirect(params[:financial_year])
    end 

    # Redirect to financial year closure
    # @params [String] financial_year - optional Financial Year Id if clicked by user
    def handle_close_financial_year params
      Duke::DukeSingleMatch.new(user_input: params[:user_input]).closing_redirect(params[:financial_year])
    end 

    # Redirect to bank_reconciliation
    # @param [String] import_type - CFONB | OFX
    def handle_to_bank_reconciliation params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                bank_account: Duke::DukeMatchingArray.new).reconc_redirect(params[:import_type])
    end 

    # Redirect to bank reconciliation if user clicked on btn-cash-suggestion
    def handle_to_bank_reconciliation_from_suggestion params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input]).btn_reconc_redirect
    end 

    # Redirect to fixed asset creation
    def handle_to_new_fixed_asset params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                depreciable: Duke::DukeMatchingArray.new).new_fixed_asset_redirect
    end 

    # Redirect to fixed asset show
    # @param [String] asset_state - State of fixed_asset
    def handle_to_fixed_asset params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                fixed_asset: Duke::DukeMatchingArray.new).fixed_asset_redirect(params[:asset_state])
    end 

    # Redirect to bank account(s)
    def handle_to_bank_account params 
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                bank_account: Duke::DukeMatchingArray.new).bank_account_redirect
    end 

    # @param [String] user_input 
    # @param [String] purchase_type : unpaid|nil
    def handle_to_bill(params)
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                entity: Duke::DukeMatchingArray.new).purchase_redirect(params[:purchase_type])
    end 

    # @param [String] user_input 
    # @param [String] sale_type : unpaid|nil
    def handle_to_sale(params)
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                entity: Duke::DukeMatchingArray.new).sale_redirect(params[:sale_type])
    end 

    # @param [String] user_input 
    # @return [Json] hasfound: bln|multiple, sentence & optional
    def handle_to_activity(params)
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                activity_variety: Duke::DukeMatchingArray.new).activity_redirect
    end 

    # @param [String] user_input
    # @return [Json]
    def handle_which_activity(params)
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                activity_variety: Duke::DukeMatchingArray.new).activity_sugg_redirect
    end 

    # @param [String] user_input
    def handle_fallback(params)
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                activity_variety: Duke::DukeMatchingArray.new,
                                tool: Duke::DukeMatchingArray.new,
                                entity: Duke::DukeMatchingArray.new).fallback_redirect
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

  end 
end