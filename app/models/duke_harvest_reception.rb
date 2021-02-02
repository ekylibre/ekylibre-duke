module Duke
  class DukeHarvestReception < DukeArticle

    attr_accessor :plant, :crop_groups, :destination, :press, :retry, :ambiguities, :parameters, :description, :user_input

    def initialize(**args)
      super() 
      @plant, @crop_groups, @destination= Array.new(3, DukeMatchingArray.new)
      @retry = 0
      @ambiguities = []
      @parameters = {complementary: {}}
      args.each{|k, v| instance_variable_set("@#{k}", v)}
      @description = @user_input.clone
      @matchArrs = [:plant, :crop_groups, :destination, :press]
    end 

    # @param [String] type : type_of parameter
    # @param [String] value : Float.to_s 
    def add_parameter(type, value)
      value = {rate: value.to_f, unit: find_quantity_unit } if type.to_sym == :quantity
      @parameters[type] = value
    end 

    # Perform Quantity/Tavp regex extractions 
    def extract_quantity_tavp
      extract_quantity
      extract_conflicting_degrees
      extract_tav
    end 

    # Extracts everything it can from a sentence
    def parse_sentence 
      extract_date
      extract_reception_parameters
      extract_user_specifics
      extract_plant_area
      find_ambiguity
    end 

    # @Returns [Integer] newly created IncomingHarvest id
    def save_harvest_reception
      @parameters['quantity']['rate'] *= 1000 if @parameters['quantity']['unit'].eql?("t")
      analysis = Analysis.create!({nature: "vine_harvesting_analysis",
                                    analysed_at: Time.zone.parse(date),
                                    sampled_at: Time.zone.parse(date),
                                    items_attributes: create_analysis_attributes})
      harvest_dic = {received_at: Time.zone.parse(@date),
                      storages_attributes: storages_attributes,
                      plants_attributes: targets_attributes,
                      analysis: analysis,
                      quantity_value: @parameters['quantity']['rate'].to_s,
                      quantity_unit: ("kilogram" if ["kg","t"].include?(@parameters['quantity']['unit'])) || "hectoliter"}
      iH = WineIncomingHarvest.create!(create_incoming_harvest_attr(harvest_dic))
      return iH.id
    end 

    # @param [SplatArray] args : Every instance variable we'll try to extract
    def parse_specifics(*args)
      @user_input = clear_string
      extract_user_specifics(jsonD: self.to_jsonD(*args))
      extract_plant_area if args.include? :plant
    end 

    # @param [DukeHarvestReception] harv
    def update_targets harv 
      if harv.plant.blank? && harv.crop_groups.blank? 
        pct_regex = harv.user_input.match(/(\d{1,2}) *(%|pour( )?cent(s)?)/)
        if pct_regex
          @crop_groups.to_a.each { |crop_group| crop_group[:area] = pct_regex[1]}
          @plant.to_a.each { |target| target[:area] = pct_regex[1]}
        end
      else  
        harv.find_ambiguity
        [:plant, :crop_groups, :ambiguities].each{|type| self.instance_variable_set("@#{type}", harv.send(type))}
        update_description harv.user_input
      end 
    end   

    # @param [DukeHarvestReception] harv
    def update_destination harv
      harv.find_ambiguity
      [:destination, :ambiguities].each{|type| self.instance_variable_set("@#{type}", harv.send(type))}
      update_description harv.user_input
    end 

    # @param [DukeHarvestReception] harv
    def update_press harv 
      harv.find_ambiguity
      [:press, :ambiguities].each{|type| self.instance_variable_set("@#{type}", harv.send(type))}
      update_description harv.user_input
    end 

    # @param [String] ComplementaryType
    def update_complementary type
      @parameters[:complementary] = {} if @parameters[:complementary].nil?
      @parameters[:complementary][type] = @user_input
      update_description @user_input
    end

    # @param [Integer] index : index of press inside @press
    # @param [Integer] value : Quantity in press(hl)
    def update_press_quantity index, value
      @press[index][:quantity] = value
    end
    
    # @param [Integer] index : index of container inside @destination
    # @param [Integer] value : Quantity in container(hl)
    def update_destination_quantity index, value
      @destination[index][:quantity] = value
    end 

    # @param [String] current_asking : what we're asking to the user 
    # @param [*] optional
    def adjust_retries(current_asking, optional=nil)
      what_next, sentence, new_optional = redirect
      if what_next == current_asking && (optional.nil?||optional.eql?(new_optional))
        @retry += 1
      else  
        reset_retries
      end 
    end 
    
    # @params : [Integer] value : Integer parsed by ibm
    def extract_number_parameter(value)
      val = super(value) 
      @retry += 1 if val.nil? 
      val 
    end 

    # @param [DukeHarvestReception] harv
    def concatenate_analysis harv
      final_parameters = harv.parameters.dup.map(&:dup).to_h
      harv.parameters.each do |key, value|
        if (['key','tav'].include?(key)||value.nil?)
          final_parameters[key] = @parameters[key]
        end
      end
      @parameters = final_parameters
    end

    # @params [Boolean] post_harvest : Are we extracting TAV, or pressingTAV
    def extract_reception_parameters(post_harvest=false)
      extract_conflicting_degrees # either °C degrees or ° Vol
      extract_quantity 
      extract_tav
      extract_temp
      extract_ph
      extract_amino_nitrogen
      extract_ammoniacal_nitrogen
      extract_assimilated_nitrogen
      extract_sanitarystate
      extract_malic
      extrat_h2SO4
      extract_pressing
      extract_complementary
      extract_pressing_tavp
      if post_harvest 
        @parameters['pressing_tavp'] = @parameters['tav']
      end 
    end

    private

    # returns an unit from user_input
    def find_quantity_unit 
      return 'kg' if @user_input.match('(?i)(kg|kilo)')
      return 't' if @user_input.match('(?i)\d *t\b|tonne')
      return 'hl'
    end 

    def extract_quantity
      # Extracting quantity data
      quantity = @user_input.matchdel('(\d{1,5}(\.|,)\d{1,2}|\d{1,5}) *(kilo|kg|hecto|expo|texto|hl|t\b|tonne)')
      if quantity
        unit = if quantity[3].match('(kilo|kg)')
                "kg" 
                elsif quantity[3].match('(hecto|hl|texto|expo)')
                "hl"
                else
                "t"
                end
        @parameters['quantity'] = {"rate" => quantity[1].gsub(',','.').to_f, "unit" => unit} # rate is the first capturing group
      else
        @parameters['quantity'] = nil
      end
    end

    # Extract values when conflicted between °C degrees & ° vol degrees
    def extract_conflicting_degrees
      tav = @user_input.matchdel('(degré d\'alcool|alcool|degré|tavp|t avp2|tav|avp|t svp|pourcentage|t avait) *(jus de presse)? *(est|était)? *(égal +(a *|à *)?|= *|de *|à *)?(\d{1,2}(\.|,)\d{1,2}|\d{1,2}) *(degré)?')
      @parameters['tav'] = tav[6].gsub(',','.') if tav
      temp = @user_input.matchdel('(température|temp) *(est|était)? *(égal *|= *|de *|à *)?(\d{1,2}(\.|,)\d{1,2}|\d{1,2}) *(degré)?')
      @parameters['temperature'] = temp[4].gsub(',','.') if temp
    end

    # Extracting TAV value in @user_input
    def extract_tav
      tav = @user_input.matchdel('(\d{1,2}|\d{1,2}(\.|,)\d{1,2}) ?((degré(s)?|°|%)|(de|en|d\')? *(tavp|t avp|tav|(t)? *avp|(t)? *svp|t avait|thé avait|thé à l\'épée|alcool|(entea|mta) *vp))')
      unless @parameters.key?('tav')
        @parameters['tav'] = (tav[1].gsub(',','.') if tav)||nil
      end
    end

    # Extracting Temperature value in @user_input
    def extract_temp
      temp = @user_input.matchdel('(\d{1,2}|\d{1,2}(\.|,)\d{1,2}) +(degré|°)')
      unless @parameters.key?('temperature')
        @parameters['temperature'] = (temp[1].gsub(',','.') if temp)||nil
      end
    end

    # Extracting pH value in @user_input
    def extract_ph
      ph = @user_input.matchdel('(\d{1,2}|\d{1,2}(\.|,)\d{1,2}) +(de +)?(ph|péage)')
      second_ph = @user_input.matchdel('((ph|péage) *(est|était)? *(égal *(a|à)? *|= ?|de +|à +)?)(\d{1,2}(\.|,)\d{1,2}|\d{1,2})')
      @parameters['ph'] = if ph
                            ph[1].gsub(',','.') # ph is the first capturing group
                          elsif second_ph
                            second_ph[6].gsub(',','.') # ph is the sixh capturing group
                          else
                            nil
                          end
    end

    # Extract Nitrogen value in @user_input
    def extract_amino_nitrogen
      nitrogen = @user_input.matchdel('(azote aminé *(est|était)? *(égal +|= ?|de +)?(à)? *)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})')
      second_nitrogen = @user_input.matchdel('(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(mg|milligramme)?.?(par l|\/l|par litre)? ?+(d\'|de|en)? *azote aminé')
      @parameters['amino_nitrogen'] =  if nitrogen
                                          nitrogen[1].gsub(',','.') # nitrogen is the first capturing group
                                        elsif second_nitrogen
                                          second_nitrogen[5].gsub(',','.') # nitrogen is the seventh capturing group
                                        else
                                          nil
                                        end
    end

    # Extract Nitrogen value in @user_input
    def extract_ammoniacal_nitrogen
      nitrogen = @user_input.matchdel('(azote (ammoniacal|ammoniaque) *(est|était)? *(égal +|= ?|de +)?(à)? *)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})')
      second_nitrogen = @user_input.match('(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(mg|milligramme)?.?(par l|\/l|par litre)? ?+(d\'|de|en)? *azote ammonia')
      @parameters['ammoniacal_nitrogen'] =  if nitrogen
                                              nitrogen[1].gsub(',','.') # nitrogen is the first capturing group
                                            elsif second_nitrogen
                                              second_nitrogen[6].gsub(',','.') # nitrogen is the seventh capturing group
                                            else
                                              nil
                                            end
    end

    # Extract Nitrogen value in @user_input
    def extract_assimilated_nitrogen
      nitrogen = @user_input.matchdel('(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(mg|milligramme)?.?(par l|\/l|par litre)? ?+(d\'|de|en)? ?+(azote *(assimilable)?|sel d\'ammonium|substance(s)? azotée)')
      second_nitrogen = @user_input.match('((azote *(assimilable)?|sel d\'ammonium|substance azotée) *(est|était)? *(égal +|= ?|de +)?(à)? *)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})')
      @parameters['assimilated_nitrogen'] = if nitrogen
                                              nitrogen[1].gsub(',','.') # nitrogen is the first capturing group
                                            elsif second_nitrogen
                                              second_nitrogen[7].gsub(',','.') # nitrogen is the seventh capturing group
                                            else
                                              nil
                                            end
    end

    # Extract SanitaryState value in @user_input
    def extract_sanitarystate
      sanitary_match = @user_input.match('(état sanitaire) *(.*?)(destination|tav|\d{1,3} *(kg|hecto|kilo|hl|tonne)|cuve|degré|température|pourcentage|alcool|ph|péage|azote|acidité|malique|manuel|mécanique|hectare|$)')
      sanitarystate = ""
      if sanitary_match
        sanitarystate += sanitary_match[2]
        @user_input[sanitary_match[1]] = ""
        @user_input[sanitary_match[2]] = ""
      end
      {sain: /s(a|e)in/, correct: /correct/, nromal: /normal/, botrytis: /(botrytis|beau titre is)/, oïdium: /o.dium/, pourriture: /pourriture/}.each do |val, regex|
        sanitarystate += val.to_s if @user_input.matchdel regex   
      end
      @parameters['sanitarystate'] = (sanitarystate if sanitarystate != "")||nil
    end

    # Extract SO Acid value in @user_input
    def extrat_h2SO4
      h2so4 = @user_input.matchdel('(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(g|gramme)?.? *(par l|\/l|par litre)? ?+(d\'|de|en)? ?+(acidité|acide|h2so4)')
      second_h2so4 = @user_input.matchdel('(acide|acidité|h2so4) *(est|était)? *(égal.? *(a|à)?|=|de|à|a)? *(\d{1,3}(\.|,)\d{1,2}|\d{1,3})')
      @parameters['h2so4'] =  if h2so4
                                h2so4[1].gsub(',','.') # h2so4 is the first capturing group
                              elsif second_h2so4
                                second_h2so4[5].gsub(',','.') # h2so4 is the third capturing group
                              else
                                nil
                              end
    end

    # Extract Malic Acid value in @user_input
    def extract_malic
      malic = @user_input.matchdel('(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) *(g|gramme)?.?(par l|\/l|par litre)? *(d\'|de|en)? *(acide?) *(malique|malic)')
      second_malic = @user_input.matchdel('((acide *)?(malic|malique) *(est|était)? *(égal +|= ?|de +|à +)?)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})')
      @parameters['malic'] =  if malic
                                malic[1].gsub(',','.') # malic is the first capturing group
                              elsif second_malic
                                second_malic[6].gsub(',','.') # malic is the sixth capturing group
                              else
                                nil
                              end
    end

    def extract_pressing
      # pressing values can only be added by clicking on a button, and are empty by default
      @parameters['pressing'] = nil
    end

    def extract_pressing_tavp
      # pressing values can only be added by clicking on a button, and are empty by default
      @parameters['pressing_tavp'] = nil
    end

    def extract_complementary
      # pressing values can only be added by clicking on a button, and are empty by default
      @parameters['complementary'] = nil
    end


    def extract_plant_area
      # Extracts a plant area from a sentence
      [@plant, @crop_groups].each do |crops|
        crops.to_a.each do |target|
          first_area = @user_input.match(/(\d{1,2}) *(%|pour( )?cent(s)?) *(de *(la|l\')?|du|des|sur|à|a|au)? #{target.matched}/)
          second_area = @user_input.match( /(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) *((hect)?are(s)?) *(de *(la|l\')?|du|des|sur|à|a|au)? #{target.matched}/)
          if first_area  # If percentage -> Area value
            target[:area] = first_area[1].to_i
          elsif second_area && !Plant.find_by(id: target[:key]).nil? # If area -> convert in percentage -> Area value
            target[:area] = 100
            area = (second_area[1].gsub(',','.').to_f if second_area[3].match(/hect/))||second_area[1].gsub(',','.').to_f/100
            whole_area = Plant.find_by(id: target[:key])&.net_surface_area&.to_f
            target[:area] = [(100*area/whole_area).to_i, 100].min unless whole_area.zero?
          else
            target[:area] = 100 # Else Area = 100%
          end
        end
      end
    end

    def speak_destination_hl
      @destination.each_with_index do |cuve, index|
        return ["#{I18n.t("duke.harvest_reception.ask.how_much_to_#{rand(0...2)}")} #{cuve[:name]}", index] unless cuve.key?("quantity")
      end
    end

    def speak_pressing_hl
      @press.each_with_index do |press, index|
        return ["#{I18n.t("duke.harvest_reception.ask.how_much_to_#{rand(0...2)}")} #{cuve[:name]}", index] unless press.key?("quantity")
      end
    end

    # @return [String] sentence with current harvestReception recap
    def speak_harvest_reception
      sentence = I18n.t("duke.harvest_reception.ask.save_harvest_reception_#{rand(0...2)}")
      sentence+= "<br>&#8226 #{I18n.t("duke.interventions.group")} : #{@crop_groups.map{|cg| "#{cg[:area].to_s}% #{cg.name}"}.join(", ")}" unless @crop_groups.blank?
      sentence+= "<br>&#8226 #{I18n.t("duke.interventions.plant")} : #{@plant.map{|tar| "#{tar[:area].to_s}% #{tar.name}"}.join(", ")}" unless @plant.blank?
      sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.quantity")} : #{@parameters['quantity']['rate'].to_s} #{@parameters['quantity']['unit']}"
      sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.tavp")} : #{@parameters['tav']} % vol"
      sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.destination")} : #{@destination.map{|des| "#{des.name}#{" (#{des[:quantity].to_s} hl)" if des.key?('quantity')}"}.join(", ")}"
      sentence+= "<br>&#8226 #{I18n.t("duke.interventions.date")} : #{@date.to_time.strftime("%d/%m/%Y - %H:%M")}"
      sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.temp")} : #{@parameters['temperature']} °C" unless @parameters['temperature'].nil?
      sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.sanitary_specified")}" unless @parameters['sanitarystate'].nil?
      sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.ph")} : #{@parameters['ph']}" unless @parameters['ph'].nil?
      sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.total_acidity")} : #{@parameters['h2so4']} g H2SO4/L" unless @parameters['h2so4'].nil?
      sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.malic_acid")} : #{@parameters['malic']} g/L" unless @parameters['malic'].nil?
      sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.amino_n")} : #{@parameters['amino_nitrogen']} mg/L" unless @parameters['amino_nitrogen'].nil?
      sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.ammoniacal_n")} : #{@parameters['ammoniacal_nitrogen']} mg/L" unless @parameters['ammoniacal_nitrogen'].nil?
      sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.assimilated_n")} : #{@parameters['assimilated_nitrogen']} mg/L" unless @parameters['assimilated_nitrogen'].nil?
      sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.press_tavp")} : #{@parameters['pressing_tavp'].to_s} % vol " unless @parameters['pressing_tavp'].nil?
      unless @parameters['complementary'].nil?
        sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.decant_time")} : #{@parameters['complementary']['ComplementaryDecantation'].delete("^0-9")} mins" if @parameters['complementary'].key?('ComplementaryDecantation')
        sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.transportor")} : #{@parameters['complementary']['ComplementaryTrailer']}" if @parameters['complementary'].key?('ComplementaryTrailer')
        sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.transport_dur")} : #{@parameters['complementary']['ComplementaryTime'].delete("^0-9")} mins" if @parameters['complementary'].key?('ComplementaryTime')
        sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.reception_dock")} : #{@parameters['complementary']['ComplementaryDock']}" if @parameters['complementary'].key?('ComplementaryDock')
        sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.vendange_nature")} : #{I18n.t('duke.harvest_reception.'+@parameters['complementary']['ComplementaryNature'])}" if @parameters['complementary'].key?('ComplementaryNature')
        sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.last_load")}" if @parameters['complementary'].key?('ComplementaryLastLoad')
      end
      return sentence.gsub(/, <br>&#8226/, "<br>&#8226")
    end

    def redirect
      return ["cancel", nil, nil] if @retry == 2
      return ["ask_ambiguity", nil, @ambiguities.first] unless @ambiguities.blank?
      return ["ask_plant", nil, nil] if @plant.blank? && @crop_groups.blank?
      return ["ask_quantity", nil, nil] if @parameters['quantity'].nil?
      return ["ask_destination", nil, nil] if @destination.blank?
      return ["ask_destination_quantity", speak_destination_hl].flatten if @destination.to_a.length > 1 and @destination.any? {|dest| !dest.key?("quantity")}
      return ["ask_pressing_quantity", speak_pressing_hl].flatten if @press.to_a.length > 1 and @press.any? {|press| !press.key?("quantity")}
      return ["ask_tav", nil, nil] if @parameters["tav"].nil?
      return "save", speak_harvest_reception, nil
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
    def create_incoming_harvest_attr dic
      unless @parameters['pressing'].nil? #add pressing items
        dic[:pressing_schedule] = @parameters['pressing']['program']
        dic[:pressing_started_at] = @parameters['pressing']['hour'].to_time.strftime("%H:%M") unless @parameters['pressing']['hour'].nil?
      end
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
      return {"0" => {storage_id: @destination.first.key,
                    quantity_value: unit_to_hectoliter(@parameters['quantity']['rate'],@parameters['quantity']['unit']),
                    quantity_unit: "hectoliter"}} if @destination.to_a.size.eql? 1
      return Hash[*@destination.each_with_index.map{|cuve, index| [index.to_s, {storage_id: cuve.key, quantity_value: cuve['quantity'], quantity_unit: "hectoliter"}]}.flatten]
    end 
    
    # @return [Array] target_attributes
    def targets_attributes 
      tar = @plant.map{|tar| {plant_id: tar.key, harvest_percentage_received: tar[:area].to_s}}
      cg = @crop_groups.map{|cg| CropGroup.available_crops(cg.key, "is plant or is land_parcel").flatten.map{|crop| {plant_id: crop[:id], harvest_percentage_received: cg[:area].to_s}}}.flatten
      return Hash[*(tar + cg).uniq{|t| t[:plant_id]}.each_with_index.map{|val, ind|[ind.to_s, val]}.flatten]
    end 

  end
end
