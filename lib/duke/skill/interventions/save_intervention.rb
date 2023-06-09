module Duke
  module Skill
    module Interventions
      class SaveIntervention < Duke::Skill::DukeIntervention

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
          @updaters = []
        end

        # Saves intervention and handles redirecting
        def handle
          Duke::DukeResponse.new(sentence: I18n.t('duke.interventions.saved', id: save_intervention.id))
        end

        private

          def zoned_working_periods
            @working_periods.each do |wp|
              %w[started_at stopped_at].each do |indicator|
                wp[indicator] = Time.zone.at(wp[indicator].to_time).to_s
              end
            end
            @working_periods.map.with_index{|wp, index| [index.to_s, wp]}.to_h
          end

          # @returns [Integer] newly created intervention id
          def save_intervention
            attributes = intervention_attributes
            add_readings_attributes(attributes)

            intervention = Procedo::Engine.new_intervention(attributes)
            @updaters.each do |updater|
              intervention.impact_with!(updater)
            end
            attributes = intervention.to_attributes
            attributes[:description] = "Duke : #{@description}"
            ::Intervention.create!(attributes)
          end

          def intervention_attributes
            attributes = {
              procedure_name: @procedure,
              state: 'done',
              number: '50',
              nature: 'record',
              tools_attributes: tool_attributes.to_a,
              doers_attributes: doer_attributes.to_a,
              targets_attributes: target_attributes.to_a,
              inputs_attributes: input_attributes.to_a,
              working_periods_attributes: zoned_working_periods
            }
          end

          # @params [hash] params : Intervention_parameters
          # Add readings to params_attributes
          def add_readings_attributes(params)
            @readings.delete_if{|_key, reading| reading.blank?}.each do |key, reading|
              params["#{key}s_attributes".to_sym].each do |attr|
                attr[:readings_attributes] = reading.map{|uniq_reading| ActiveSupport::HashWithIndifferentAccess.new(uniq_reading)}
              end
            end
          end

          # @return Array with target_attributes
          def target_attributes
            target_reference = Procedo::Procedure.find(@procedure).parameters.find {|param| param.type == :target}
            if target_reference.blank? || (send(target_reference.name).blank? && @crop_groups.blank?)
              []
            else
              targets = send(target_reference.name).map do |target|
                {
                  reference_name: target_reference.name,
                  product_id: target.key,
                  working_zone: Product.find_by_id(target.key).shape
                }
              end
              groups = @crop_groups.map{|group| CropGroup.available_crops(group.key, 'is plant or is land_parcel')}.flatten.map do |crop|
                {
                  reference_name: target_reference.name,
                  product_id: crop.id,
                  working_zone: Product.find_by_id(crop.id).shape
                }
              end
              targets = (targets + groups).uniq{|t| t[:product_id]}
              targets.map.with_index { |target, i| [i, target] }.to_h
            end
          end

          # @return Array with input_attributes
          def input_attributes
            if @input.blank? || Procedo::Procedure.find(@procedure).parameters_of_type(:input).blank?
              []
            else
              computed_attributes = {}
              @input.to_a.each_with_index do |input, index|
                computed_attributes[index.to_s] = {
                  reference_name: input_reference_name(input.key),
                  product_id: input.key,
                  quantity_value: input.rate[:value].to_f,
                  quantity_handler: input_quantity_handler(input)
                }
                @updaters << "inputs[#{index}]quantity_value"
              end
              computed_attributes
            end
          end

          def input_quantity_handler(input)
            if input[:rate][:unit] == 'population'
              matter = Matter.find(input[:key])
              return "net_#{matter.default_unit.dimension}"
            else
              return input[:rate][:unit]
            end
          end

          # @return Array with doer_attributes
          def doer_attributes
            if @doer.blank? && @worker_group.blank? || Procedo::Procedure.find(@procedure).parameters_of_type(:doer).blank?
              []
            else
              @worker_group.each do |worker_group|
                WorkerGroup.find(worker_group.key).items.map(&:worker_id).each do |worker_id|
                  @doer.push(Duke::DukeMatchingItem.new(key: worker_id))
                end
              end
              @doer.uniq_by_key.map.with_index do |doer, index|
                [index, {
                  reference_name: Procedo::Procedure.find(@procedure).parameters_of_type(:doer).first.name,
                  product_id: doer.key
                }]
              end.to_h
            end
          end

          # @return Array with tool_attributes
          def tool_attributes
            if @tool.blank? || Procedo::Procedure.find(@procedure).parameters_of_type(:tool).blank?
              []
            else
              @tool.map.with_index do |tool, index|
                [index, {
                  reference_name: tool_reference_name(tool.key),
                  product_id: tool.key
                }]
              end.to_h
            end
          end

          # @param [Integer] key: tool id
          # @return [String] tool reference_name
          def tool_reference_name(key)
            reference_name = Procedo::Procedure.find(@procedure).parameters_of_type(:tool).first
            Procedo::Procedure.find(@procedure).parameters.find_all{|param| param.type == :tool}.each do |tool_type|
              if Equipment.of_expression(tool_type.filter).include? Equipment.find_by_id(key)
                reference_name = tool_type
                break
              end
            end
            reference_name.name
          end

          # @param [Integer] key: input id
          # @return [String] input reference_name
          def input_reference_name(key)
            inputs = Procedo::Procedure.find(@procedure).parameters_of_type(:input)
            inputs.find {|inp| Matter.find_by_id(key).of_expression(inp.filter)}.name
          end

      end
    end
  end
end
