module Duke
  module Skill
    module Redirections
      class GetSalesTypes
        include Duke::Utils::BaseDuke

        def initialize(event)
          @sales = SaleNature.all
        end

        # Returns sales types as ibm-readable options if multiple sale types exists
        def handle
          if @sales.size < 2
            Duke::DukeResponse.new
          else
            options = @sales.map{|type| optionify(type.name, type.id.to_s)}
            Duke::DukeResponse.new(options: dynamic_options(I18n.t('duke.redirections.which_sale_type'), options))
          end
        end

      end
    end
  end
end
