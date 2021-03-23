module Duke
  class Redirections
    include Duke::BaseDuke

    # Common @params : [String] user_input : User Utterance

    # Redirects to activity, or suggest multiple if cultivation_variety ambiguity
    # @return [Json] found: boolean|multiple, sentence & optional
    def handle_to_activity(params)
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                activity_variety: Duke::DukeMatchingArray.new).activity_redirect
    end 

    # Parse btn.click for activity to be redirected to
    # @return [Json] found: boolean, sentence
    def handle_which_activity(params)
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                activity_variety: Duke::DukeMatchingArray.new).activity_sugg_redirect
    end 

    # @param [String] purchase_type : unpaid|nil
    def handle_to_bill(params)
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                entity: Duke::DukeMatchingArray.new).purchase_redirect(params[:purchase_type])
    end 

    # @param [String] sale_type : unpaid|nil
    def handle_to_sale(params) 
      Duke::DukeSingleMatch.new(user_input: params[:user_input],
                                entity: Duke::DukeMatchingArray.new).sale_redirect(params[:sale_type])
    end 

  end 
end