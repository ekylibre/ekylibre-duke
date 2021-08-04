module Duke
  module Skill
    module HarvestReceptions
      class SaveHarvestReception < Duke::Skill::DukeHarvestReception

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
        end

        # Saves harvest reception and handles redirecting
        def handle
          Duke::DukeResponse.new(sentence: I18n.t('duke.harvest_reception.saved', id: save_harvest_reception))
        end

        private

          # @Returns [Integer] newly created IncomingHarvest id
          def save_harvest_reception
            # Issue when registering an incoming harvest with any type of attributes. Not without
            @parameters['quantity']['rate'] *= 1000 if @parameters['quantity']['unit'].eql?('t')
            harvest_dic = { received_at: Time.zone.parse(@date),
                            quantity_value: @parameters['quantity']['rate'].to_s,
                            quantity_unit: ('kilogram' if %w[kg t].include?(@parameters['quantity']['unit'])) || 'hectoliter' }
            ih = WineIncomingHarvest.create(ih_attr(harvest_dic))
            analysis = Analysis.create!({ nature: 'vine_harvesting_analysis',
                                        analysed_at: Time.zone.parse(date),
                                        sampled_at: Time.zone.parse(date),
                                        items_attributes: create_analysis_attributes,
                                        wine_incoming_harvest: ih })
            targets_attributes(ih.id).each{|target| WineIncomingHarvestPlant.create(target)}
            storages_attributes(ih.id).each{|storage| WineIncomingHarvestStorage.create(storage)}
            press_attributes(ih.id).each{|press| WineIncomingHarvestPress.create(press)}
            ih.id
          end

          # @returns [Hash] Analysis_attributes with every analysis items
          def create_analysis_attributes
            attributes = {}
            attributes[0] = {
                _destroy: 'false',
                indicator_name: 'estimated_harvest_alcoholic_volumetric_concentration',
                measure_value_value: @parameters['tav'],
                measure_value_unit: 'volume_percent'
              }
            unless @parameters['ph'].nil?
              attributes[1] = {
                _destroy: 'false',
                indicator_name: 'potential_hydrogen',
                decimal_value: @parameters['ph']
              }
            end
            unless @parameters['temperature'].nil?
              attributes[2] = {
                _destroy: 'false',
                indicator_name: 'temperature',
                measure_value_value: @parameters['temperature'],
                measure_value_unit: 'celsius'
              }
            end
            unless @parameters['assimilated_nitrogen'].nil?
              attributes[3] = {
                _destroy: 'false',
                indicator_name: 'assimilated_nitrogen_concentration',
                measure_value_value: @parameters['assimilated_nitrogen'],
                measure_value_unit: 'milligram_per_liter'
              }
            end
            unless @parameters['amino_nitrogen'].nil?
              attributes[4] = {
                _destroy: 'false',
                indicator_name: 'amino_nitrogen_concentration',
                measure_value_value: @parameters['amino_nitrogen'],
                measure_value_unit: 'milligram_per_liter'
              }
            end
            unless @parameters['ammoniacal_nitrogen'].nil?
              attributes[5] = {
                _destroy: 'false',
                indicator_name: 'ammoniacal_nitrogen_concentration',
                measure_value_value: @parameters['ammoniacal_nitrogen'],
                measure_value_unit: 'milligram_per_liter'
}
            end
            unless @parameters['h2so4'].nil?
              attributes[6] = {
                _destroy: 'false',
                indicator_name: 'total_acid_concentration',
                measure_value_value: @parameters['h2so4'],
                measure_value_unit: 'gram_per_liter'
              }
            end
            unless @parameters['malic'].nil?
              attributes[7] = {
                _destroy: 'false',
                indicator_name: 'malic_acid_concentration',
                measure_value_value: @parameters['malic'],
                measure_value_unit: 'gram_per_liter'
              }
            end
            unless @parameters['sanitarystate'].nil?
              attributes[8] ={
                _destroy: 'false',
                indicator_name: 'sanitary_vine_harvesting_state',
                string_value: @parameters['sanitarystate']
              }
            end
            unless @parameters['pressing_tavp'].nil?
              attributes[9] ={
                measure_value_unit: 'volume_percent',
                indicator_name: 'estimated_pressed_harvest_alcoholic_volumetric_concentration',
                measure_value_value: @parameters['pressing_tavp']
              }
            end
            attributes
          end

          # @returns [Hash] incoming_harvest_attrs with press & ComplementaryItems
          def ih_attr(dic)
            unless @parameters['complementary'].blank? # add complementary if exists
              if @parameters['complementary'].key?('ComplementaryDecantation')
                dic[:sedimentation_duration] = @parameters['complementary']['ComplementaryDecantation'].delete('^0-9')
              end
              if @parameters['complementary'].key?('ComplementaryTrailer')
                dic[:vehicle_trailer] = @parameters['complementary']['ComplementaryTrailer']
              end
              if @parameters['complementary'].key?('ComplementaryTime')
                dic[:harvest_transportation_duration] = @parameters['complementary']['ComplementaryTime'].delete('^0-9')
              end
              if @parameters['complementary'].key?('ComplementaryDock')
                dic[:harvest_dock] = @parameters['complementary']['ComplementaryDock']
              end
              if @parameters['complementary'].key?('ComplementaryNature')
                dic[:harvest_nature] = @parameters['complementary']['ComplementaryNature']
              end
              dic[:last_load] = 'true' if @parameters['complementary'].key?('ComplementaryLastLoad')
            end
            dic
          end

          # @param [String] value
          # @param [String] unit
          # @return [Float] conversion in hectoliter
          def unit_to_hectoliter(value, unit)
            if unit == 'hl'
              format('%.3f', value.to_f)
            elsif unit == 'kg'
              format('%.3f', value.to_f/130)
            else
              format('%.3f', value.to_f/0.130)
            end
          end

          # @return [Hash] storage_attributes
          def storages_attributes(id)
            if @destination.to_a.size.eql? 1
              [
                { storage_id: @destination.first.key,
                  quantity_value: unit_to_hectoliter(@parameters['quantity']['rate'], @parameters['quantity']['unit']),
                  quantity_unit: 'hectoliter',
                  wine_incoming_harvest_id: id }
              ]
            else
              @destination.map{|cuve|
                {
                  storage_id: cuve.key,
                  quantity_value: cuve['quantity'],
                  quantity_unit: 'hectoliter',
                  wine_incoming_harvest_id: id
                }
              }
            end
          end

          # @return [Array] target_attributes
          def targets_attributes(id)
            tar = @plant.map{|tar| { plant_id: tar.key, harvest_percentage_received: tar[:area].to_s, wine_incoming_harvest_id: id }}
            cg = @crop_groups.flat_map{|cg| CropGroup.available_crops(cg.key, 'is plant or is land_parcel').map{|crop|
                                              {
                                                plant_id: crop[:id],
                                                harvest_percentage_received: cg[:area].to_s,
                                                wine_incoming_harvest_id: id
                                              }
                                            }
            }.flatten
            return (tar + cg).uniq{|t| t[:plant_id]}
          end

          # @return [Array]press_attributes
          def press_attributes(id)
            add_pressing_program
            if @press.to_a.size.eql? 1
              [
                { press_id: @press.first.key,
                  quantity_value: unit_to_hectoliter(@parameters['quantity']['rate'], @parameters['quantity']['unit']),
                  quantity_unit: 'hectoliter',
                  pressing_schedule: @press.first[:pressing_schedule],
                  pressing_started_at: @press.first[:pressing_started_at],
                  wine_incoming_harvest_id: id }
              ]
            else
              @press.map{|press|
                {
                  press_id: press.key,
                  quantity_value: press['quantity'],
                  quantity_unit: 'hectoliter',
                  wine_incoming_harvest_id: id,
                  pressing_schedule: press[:pressing_schedule],
                  pressing_started_at: press[:pressing_started_at]
                }
              }
            end
          end

          # adds pressing_program and pressing_hour to each @press
          def add_pressing_program
            @press.each do |press|
              press[:pressing_schedule] = @parameters['pressing'].present? ? @parameters['pressing']['program'] : ''
              press[:pressing_started_at] = if @parameters.dig(:pressing, :hour).present?
                                              @parameters['pressing']['hour'].to_time.strftime('%H:%M')
                                            else
                                              ''
                                            end
            end
          end

      end
    end
  end
end
