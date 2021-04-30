module Duke
  module Skill
    module Redirections
      class GetSalesTypes
        using Duke::DukeRefinements

        def initialize(event)
          @sales = SaleNature.all
        end 

        def handle
          ## modify params journal word to options.sss
          if @sales.size < 2 
            Duke::DukeResponse.new
          else
            options = @sales.map{|type| optJsonify(type.name, type.id.to_s)}
            Duke::DukeResponse.new(options: dynamic_options(I18n.t("duke.redirections.which_sale_type"), options))
          end
        end
        
      end
    end
  end
end