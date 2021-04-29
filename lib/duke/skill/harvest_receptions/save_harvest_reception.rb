module Duke
  module Skill
    module HarvestReceptions
      class SaveHarvestReception < Duke::Skill::DukeHarvestReception
        using Duke::DukeRefinements

        def initialize(event)
          super()
          recover_from_hash(event.parsed)
        end 

        def handle
          Duke::DukeResponse.new(sentence: I18n.t("duke.harvest_receptions.saved", id: save_harvest_reception)) 
        end

        private

        # @Returns [Integer] newly created IncomingHarvest id
        def save_harvest_reception
          @parameters['quantity']['rate'] *= 1000 if @parameters['quantity']['unit'].eql?("t")
          harvest_dic = { received_at: Time.zone.parse(@date),
                          quantity_value: @parameters['quantity']['rate'].to_s,
                          quantity_unit: ("kilogram" if ["kg","t"].include?(@parameters['quantity']['unit'])) || "hectoliter"}
          iH = WineIncomingHarvest.create(iH_attr(harvest_dic))
          analysis = Analysis.create!({nature: "vine_harvesting_analysis",
                                      analysed_at: Time.zone.parse(date),
                                      sampled_at: Time.zone.parse(date),
                                      items_attributes: create_analysis_attributes,
                                      wine_incoming_harvest: iH})
          targets_attributes.each{|wihT| WineIncomingHarvestPlant.create(wihT)}
          storages_attributes.each{|wihS| WineIncomingHarvestStorage.create(wihS)}
          press_attributes.each{|wihP|WineIncomingHarvestPress.create(wihP)}
          iH.id
        end 

        # @returns [Hash] Analysis_attributes with every analysis items
        def create_analysis_attributes
          attributes = {"0"=>{"_destroy"=>"false", "indicator_name"=>"estimated_harvest_alcoholic_volumetric_concentration", "measure_value_value"=> @parameters['tav'], "measure_value_unit"=>"volume_percent"}}
          attributes[1] = {"_destroy"=>"false", "indicator_name"=>"potential_hydrogen", "decimal_value"=> @parameters['ph'] } unless @parameters['ph'].nil?
          attributes[2] = {"_destroy"=>"false", "indicator_name"=>"temperature", "measure_value_value"=> @parameters['temperature'], "measure_value_unit"=>"celsius"} unless @parameters['temperature'].nil?
          attributes[3] = {"_destroy"=>"false", "indicator_name"=>"assimilated_nitrogen_concentration", "measure_value_value"=> @parameters['assimilated_nitrogen'], "measure_value_unit"=>"milligram_per_liter"} unless @parameters['assimilated_nitrogen'].nil?
          attributes[4] = {"_destroy"=>"false", "indicator_name"=>"amino_nitrogen_concentration", "measure_value_value"=> @parameters['amino_nitrogen'], "measure_value_unit"=>"milligram_per_liter"} unless @parameters['amino_nitrogen'].nil?
          attributes[5] = {"_destroy"=>"false", "indicator_name"=>"ammoniacal_nitrogen_concentration", "measure_value_value"=> @parameters['ammoniacal_nitrogen'], "measure_value_unit"=>"milligram_per_liter"} unless @parameters['ammoniacal_nitrogen'].nil?
          attributes[6] = {"_destroy"=>"false", "indicator_name"=>"total_acid_concentration", "measure_value_value"=>@parameters['h2so4'], "measure_value_unit"=>"gram_per_liter"} unless @parameters['h2so4'].nil?
          attributes[7] = {"_destroy"=>"false", "indicator_name"=>"malic_acid_concentration", "measure_value_value"=>@parameters['malic'], "measure_value_unit"=>"gram_per_liter"} unless @parameters['malic'].nil?
          attributes[8] = {"_destroy"=>"false", "indicator_name"=>"sanitary_vine_harvesting_state", "string_value"=> @parameters['sanitarystate']} unless @parameters['sanitarystate'].nil?
          attributes[9] = {"measure_value_unit" =>"volume_percent","indicator_name" => "estimated_pressed_harvest_alcoholic_volumetric_concentration", "measure_value_value" => @parameters['pressing_tavp']} unless @parameters['pressing_tavp'].nil?
          attributes
        end

        # @returns [Hash] incoming_harvest_attrs with press & ComplementaryItems
        def iH_attr dic
          unless @parameters['complementary'].blank? #add complementary if exists
            dic[:sedimentation_duration] = @parameters['complementary']['ComplementaryDecantation'].delete("^0-9") if @parameters['complementary'].key?('ComplementaryDecantation')
            dic[:vehicle_trailer] = @parameters['complementary']['ComplementaryTrailer'] if @parameters['complementary'].key?('ComplementaryTrailer')
            dic[:harvest_transportation_duration] = @parameters['complementary']['ComplementaryTime'].delete("^0-9") if @parameters['complementary'].key?('ComplementaryTime')
            dic[:harvest_dock] = @parameters['complementary']['ComplementaryDock'] if @parameters['complementary'].key?('ComplementaryDock')
            dic[:harvest_nature] = @parameters['complementary']['ComplementaryNature'] if @parameters['complementary'].key?('ComplementaryNature')
            dic[:last_load] = "true" if @parameters['complementary'].key?('ComplementaryLastLoad')
          end
          dic
        end

        # @param [String] value
        # @param [String] unit
        # @return [Float] conversion in hectoliter
        def unit_to_hectoliter(value, unit)
          if unit == "hl"
            return sprintf('%.3f', value.to_f)
          elsif unit == "kg"
            return sprintf('%.3f', value.to_f/130)
          else
            return sprintf('%.3f', value.to_f/0.130)
          end
        end

        # @return [Hash] storage_attributes
        def storages_attributes
          return [{storage_id: @destination.first.key,
                  quantity_value: unit_to_hectoliter(@parameters['quantity']['rate'],@parameters['quantity']['unit']),
                  quantity_unit: "hectoliter",
                  wine_incoming_harvest_id: @id}] if @destination.to_a.size.eql? 1
          return @destination.map{|cuve| {storage_id: cuve.key, quantity_value: cuve['quantity'], quantity_unit: "hectoliter", wine_incoming_harvest_id: @id}}
        end 
        
        # @return [Array] target_attributes
        def targets_attributes 
          tar = @plant.map{|tar| {plant_id: tar.key, harvest_percentage_received: tar[:area].to_s, wine_incoming_harvest_id: @id}}
          cg = @crop_groups.flat_map{|cg| CropGroup.available_crops(cg.key, "is plant or is land_parcel").map{|crop| {plant_id: crop[:id], harvest_percentage_received: cg[:area].to_s, wine_incoming_harvest_id: @id}}}.flatten
          return (tar + cg).uniq{|t| t[:plant_id]}
        end 

        # @return [Array] press_attributes
        def press_attributes 
          add_pressing_program
          return [{press_id: @press.first.key,
                  quantity_value: unit_to_hectoliter(@parameters['quantity']['rate'],@parameters['quantity']['unit']),
                  quantity_unit: "hectoliter",
                  pressing_schedule: @press.first[:pressing_schedule], 
                  pressing_started_at: @press.first[:pressing_started_at],
                  wine_incoming_harvest_id: @id}] if @press.to_a.size.eql? 1
          return @press.map{|press| {press_id: press.key, quantity_value: press['quantity'], quantity_unit: "hectoliter", wine_incoming_harvest_id: @id, pressing_schedule: press[:pressing_schedule], pressing_started_at: press[:pressing_started_at]}}
        end 
        
        # adds pressing_program and pressing_hour to each @press
        def add_pressing_program
          @press.each do |press|
            press[:pressing_schedule] = (@parameters['pressing']['program'] if parameters['pressing'].present?)||""
            press[:pressing_started_at] = (@parameters['pressing']['hour'].to_time.strftime("%H:%M") if @parameters.dig(:pressing, :hour).present?)||""
          end 
        end 
        
      end
    end
  end
end