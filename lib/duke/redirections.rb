module Duke
  class Redirections < Duke::Utils::DukeParsing
    def handle_to_activity(params)
      I18n.locale = :fra
      user_input = clear_string(params[:user_input])
      Ekylibre::Tenant.switch params['tenant'] do
        parsed = {:activity_variety => []}
        extract_user_specifics(user_input, parsed, 0.82)
        if parsed[:activity_variety].empty? 
          sentence = I18n.t("duke.redirections.no_activity")
          return {:found => :no, :sentence => sentence}
        elsif Activity.of_campaign(Campaign.current).find_by_id(parsed[:activity_variety].first[:key]).nil?
          # There is no current campaign of this type 
          variety = Activity.find_by_id(parsed[:activity_variety].first[:key]).cultivation_variety_name
          sentence = I18n.t("duke.redirections.no_current_activity", variety: variety)
          return {:found => :not_currently, sentence => sentence, :variety => variety}
        else 
          variety = Activity.find_by_id(parsed[:activity_variety].first[:key]).cultivation_variety_name
          sentence = I18n.t("duke.redirections.activity", variety: variety)
          return {:found => :yes, :sentence => sentence, :key => parsed[:activity_variety].first[:key]}
        end 
      end 
    end 

    def handle_to_tool(params)
      I18n.locale = :fra
      user_input = clear_string(params[:user_input])
      Ekylibre::Tenant.switch params['tenant'] do
        parsed = {:equipments => [],
                  :date => Time.now}
        extract_user_specifics(user_input, parsed, 0.82)
        if parsed[:equipments].empty? 
          sentence = I18n.t("duke.redirections.not_finding")
          return {:found => :no, :sentence => sentence}
        else 
          max_matcher = parsed[:equipments].max_by{|eq| eq[:distance]}
          sentence =  I18n.t("duke.redirections.found_tool" , tool: max_matcher[:name])
          return {:found => :yes, :sentence => sentence, :key => max_matcher[:key]}
        end 
      end 
    end 

  end 
end