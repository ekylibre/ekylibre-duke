module Duke
  module Skill
    class DukeHarvestReception < DukeArticle
      using Duke::DukeRefinements

      attr_accessor :plant, :crop_groups, :destination, :press, :ambiguities, :parameters
      
      def initialize(**args)
        super() 
        @plant, @crop_groups, @destination, @press= Array.new(4, DukeMatchingArray.new)
        @retry = 0
        @ambiguities = []
        @parameters = {complementary: {}}
        args.each{|k, v| instance_variable_set("@#{k}", v)}
        @description = @user_input.clone
      end 

      # @param [SplatArray] args : Every instance variable we'll try to extract
      def parse_specifics(*args)
        extract_user_specifics(duke_json: self.duke_json(*args))
        extract_plant_area if args.include? :plant
      end 

      # @params [Boolean] post_harvest : Are we extracting TAV, or pressingTAV
      def extract_reception_parameters(post_harvest=false)
        %I[conflicting_degrees quantity tav temp ph amino_nitrogen ammoniacal_nitrogen assimilated_nitrogen sanitarystate malic h2SO4 pressing complementary pressing_tavp].each do |attr|
          send("extract_#{attr}")
        end
        @parameters['pressing_tavp'] = @parameters['tav'] if post_harvest
      end

      private

      attr_accessor :id, :retry

      # @params : [Integer] value : Integer parsed by ibm
      def extract_number_parameter(value)
        val = super(value) 
        @retry += 1 if val.nil? 
        val 
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
          
      def parseable
        [*super(), :plant, :crop_groups, :destination, :press]
      end

      # Extract values when conflicted between °C degrees & ° vol degrees
      def extract_conflicting_degrees
        tav = @user_input.matchdel(/(degré d\'alcool|alcool|degré|tavp|t avp2|tav|avp|t svp|pourcentage|t avait) *(jus de presse)? *(est|était)? *(égal +(a *|à *)?|= *|de *|à *)?(\d{1,2}(\.|,)\d{1,2}|\d{1,2}) *(degré)?/)
        @parameters['tav'] = tav[6].gsub(',','.') if tav
        temp = @user_input.matchdel(/(température|temp) *(est|était)? *(égal *|= *|de *|à *)?(\d{1,2}(\.|,)\d{1,2}|\d{1,2}) *(degré)?/)
        @parameters['temperature'] = temp[4].gsub(',','.') if temp
      end

      # Extracting TAV value in @user_input
      def extract_tav
        tav = @user_input.matchdel(/(\d{1,2}|\d{1,2}(\.|,)\d{1,2}) ?((degré(s)?|°|%)|(de|en|d\')? *(tavp|t avp|tav|(t)? *avp|(t)? *svp|t avait|thé avait|thé à l\'épée|alcool|(entea|mta) *vp))/)
        unless @parameters.key?('tav')
          @parameters['tav'] = (tav[1].gsub(',','.') if tav)||nil
        end
      end

      # Extracting Temperature value in @user_input
      def extract_temp
        temp = @user_input.matchdel(/(\d{1,2}|\d{1,2}(\.|,)\d{1,2}) +(degré|°)/)
        unless @parameters.key?('temperature')
          @parameters['temperature'] = (temp[1].gsub(',','.') if temp)||nil
        end
      end

      # Extracting pH value in @user_input
      def extract_ph
        ph = @user_input.matchdel(/(\d{1,2}|\d{1,2}(\.|,)\d{1,2}) +(de +)?(ph|péage)/)
        second_ph = @user_input.matchdel(/((ph|péage) *(est|était)? *(égal *(a|à)? *|= ?|de +|à +)?)(\d{1,2}(\.|,)\d{1,2}|\d{1,2})/)
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
        nitrogen = @user_input.matchdel(/(azote aminé *(est|était)? *(égal +|= ?|de +)?(à)? *)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})/)
        second_nitrogen = @user_input.matchdel(/(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(mg|milligramme)?.?(par l|\/l|par litre)? ?+(d\'|de|en)? *azote aminé/)
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
        nitrogen = @user_input.matchdel(/(azote (ammoniacal|ammoniaque) *(est|était)? *(égal +|= ?|de +)?(à)? *)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})/)
        second_nitrogen = @user_input.matchdel(/(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(mg|milligramme)?.?(par l|\/l|par litre)? ?+(d\'|de|en)? *azote ammonia/)
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
        nitrogen = @user_input.matchdel(/(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(mg|milligramme)?.?(par l|\/l|par litre)? ?+(d\'|de|en)? ?+(azote *(assimilable)?|sel d\'ammonium|substance(s)? azotée)/)
        second_nitrogen = @user_input.matchdel(/((azote *(assimilable)?|sel d\'ammonium|substance azotée) *(est|était)? *(égal +|= ?|de +)?(à)? *)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})/)
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
          @user_input.gsub!(sanitary_match[1], '')
          @user_input.gsub!(sanitary_match[2], '')
        end
        {sain: /s(a|e)in/, correct: /correct/, nromal: /normal/, botrytis: /(botrytis|beau titre is)/, oïdium: /o.dium/, pourriture: /pourriture/}.each do |val, regex|
          sanitarystate += val.to_s if @user_input.matchdel regex   
        end
        @parameters['sanitarystate'] = (sanitarystate if sanitarystate != "")||nil
      end

      # Extract SO Acid value in @user_input
      def extrat_h2SO4
        h2so4 = @user_input.matchdel(/(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) +(g|gramme)?.? *(par l|\/l|par litre)? ?+(d\'|de|en)? ?+(acidité|acide|h2so4)/)
        second_h2so4 = @user_input.matchdel(/(acide|acidité|h2so4) *(est|était)? *(égal.? *(a|à)?|=|de|à|a)? *(\d{1,3}(\.|,)\d{1,2}|\d{1,3})/)
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
        malic = @user_input.matchdel(/(\d{1,3}|\d{1,3}(\.|,)\d{1,2}) *(g|gramme)?.?(par l|\/l|par litre)? *(d\'|de|en)? *(acide?) *(malique|malic)/)
        second_malic = @user_input.matchdel(/((acide *)?(malic|malique) *(est|était)? *(égal +|= ?|de +|à +)?)(\d{1,3}(\.|,)\d{1,2}|\d{1,3})/)
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
          return ["#{I18n.t("duke.harvest_reception.ask.how_much_to_#{rand(0...2)}")} #{press[:name]}", index] unless press.key?("quantity")
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
        sentence+= "<br>&#8226 #{I18n.t("duke.harvest_reception.press")} : #{@press.map{|press| "#{press.name}#{" (#{press[:quantity].to_s} hl)" if press.key?('quantity')}"}.join(", ")}" unless @press.blank?
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
        if @retry == 2
          return :cancel
        elsif @ambiguities.present?
          return :ask_ambiguity, nil, @ambiguities.first
        elsif @plant.blank? && @crop_groups.blank?
          return :ask_plant
        elsif @parameters['quantity'].nil?
          return :ask_quantity
        elsif @destination.blank?
          return :ask_destination
        elsif @destination.to_a.length > 1 and @destination.any? {|dest| !dest.key?("quantity")}
          return :ask_destination_quantity, *speak_destination_hl
        elsif @press.to_a.length > 1 and @press.any? {|press| !press.key?("quantity")}
          return :ask_pressing_quantity, *speak_pressing_hl
        elsif @parameters['tav'].nil?
          return :ask_tav
        else
          return :save, speak_harvest_reception
        end
      end

    end
  end
end
