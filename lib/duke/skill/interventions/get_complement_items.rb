module Duke
  module Skill
    module Interventions
      class GetComplementItems < Duke::Skill::DukeIntervention
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end 

        def handle
          to_ibm(options: all_options(@event.options.specific))
        end

        private 

        # @param [String] type : Type of item for which we want to display all suggestions
        # @return [Json] OptJson for Ibm to display clickable buttons with every item & labels
        def all_options(type)
          pars = Procedo::Procedure.find(@procedure).parameters_of_type(type.to_sym).select do |param|
            Product.availables(at: @date.to_time).of_expression(param.filter).present?
          end
          items = pars.map do |param|
            [
              {
                global_label: param.human_name
              },
              Product.availables(at: @date.to_time).of_expression(param.filter)
            ]
          end
          items = items.flatten.reject do |prod| # Remove Already chosen from suggestions
            prod.respond_to?(:id) && send(type).any?{|reco| reco.key == prod.id}
          end
          options = items.map do |itm| # Turn it to Jsonified options
            itm.is_a?(Hash) ? itm : optJsonify(itm.name, itm.id)
          end
          if options.empty?
            dynamic_text(I18n.t('duke.interventions.ask.no_complement'))
          elsif options.size == 2
            dynamic_options(I18n.t('duke.interventions.ask.one_complement'), options)
          else
            dynamic_options(I18n.t("duke.interventions.ask.what_complement_#{type}"), options)
          end
        end

      end
    end
  end
end