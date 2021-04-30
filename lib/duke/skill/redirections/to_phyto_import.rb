module Duke
  module Skill
    module Redirections
      class ToPhytoImport
        using Duke::DukeRefinements

        def initialize(event)
        end 

        def handle
          # modify paraams p_id, params aam change in CODE !!!
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
  end
end