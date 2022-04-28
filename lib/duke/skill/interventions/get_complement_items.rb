module Duke
  module Skill
    module Interventions
      class GetComplementItems < Duke::Skill::DukeIntervention

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @event = event
        end

        # Returns optionified items of specific type to be displayed to the user
        # options specific: what we'll display (input || doer || tool)
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
                Product.availables(at: @date.to_time).of_expression(param.filter).reject{|pr| send(type).any?{|reco| reco.key == pr.id}}
              ]
            end
            items = add_worker_groups(items) if type.to_sym == :doer
            options = items.flatten.map do |itm| # Turn it to Jsonified options
              itm.is_a?(Hash) ? itm : optionify(itm.send(display_name(type)), itm.id)
            end
            if options.empty?
              dynamic_text(I18n.t('duke.interventions.ask.no_complement'))
            elsif options.size == 2
              dynamic_options(I18n.t('duke.interventions.ask.one_complement'), options)
            else
              dynamic_options(I18n.t("duke.interventions.ask.what_complement_#{type}"), options)
            end
          end

          def add_worker_groups(items)
            if WorkerGroup.any?
              items.push([
                  {
                    global_label: I18n.t('duke.interventions.worker_group')
                  },
                  WorkerGroup.all.reject{|wg| send(:worker_group).any?{|worker_group| worker_group.key == wg.id}}
                ])
            end
            items
          end

          def display_name(type)
            type == 'input' ? :unambiguous_name : :name
          end

      end
    end
  end
end
