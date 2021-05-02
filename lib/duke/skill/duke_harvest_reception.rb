module Duke
  module Skill
    class DukeHarvestReception < DukeArticle
      using Duke::Utils::DukeRefinements

      attr_accessor :plant, :crop_groups, :destination, :press, :ambiguities, :parameters

      def initialize(**args)
        super()
        @plant, @crop_groups, @destination, @press= Array.new(4, DukeMatchingArray.new)
        @retry = 0
        @ambiguities = []
        @parameters = { complementary: {} }
        args.each{|k, v| instance_variable_set("@#{k}", v)}
        @description = @user_input.clone
      end

      # @param [SplatArray] args : Every instance variable we'll try to extract
      def parse_specifics(*args)
        extract_user_specifics(duke_json: self.duke_json(*args))
        extract_plant_area if args.include? :plant
      end

      # @params [Boolean] post_harvest : Are we extracting TAV, or pressingTAV
      def extract_reception_parameters(post_harvest = false)
        %I[conflicting_degrees quantity tav temp ph amino_nitrogen ammoniacal_nitrogen assimilated_nitrogen sanitarystate malic h2so4
           pressing complementary pressing_tavp].each do |attr|
          send("extract_#{attr}")
        end
        @parameters['pressing_tavp'] = @parameters['tav'] if post_harvest
      end

      # Perform Quantity/Tavp regex extractions
      def extract_quantity_tavp
        extract_quantity
        extract_conflicting_degrees
        extract_tav
      end

      private

        attr_accessor :id, :retry

        # What user_specifics are to be extracted
        def parseable
          [*super(), :plant, :crop_groups, :destination, :press]
        end

        # @params : [Integer] value : Integer parsed by ibm
        def extract_number_parameter(value)
          val = super(value)
          @retry += 1 if val.nil?
          val
        end

        # @param [String] current_asking : what we're asking to the user
        # @param [*] optional
        def adjust_retries(current_asking, optional = nil)
          what_next, sentence, new_optional = redirect
          if what_next == current_asking && (optional.nil?||optional.eql?(new_optional))
            @retry += 1
          else
            reset_retries
          end
        end

        #  Adds quantity if parsed to @parameters
        def extract_quantity
          # Extracting quantity data
          quantity = @user_input.matchdel(Duke::Utils::Regex.quantity)
          if quantity
            unit = if quantity[3].match(/(kilo|kg)/)
                     'kg'
                   elsif quantity[3].match(/(hecto|hl|texto|expo)/)
                     'hl'
                   else
                     't'
                   end
            @parameters['quantity'] = { 'rate' => quantity[1].gsub(',', '.').to_f, 'unit' => unit } # rate is the first capturing group
          else
            @parameters['quantity'] = nil
          end
        end

        # Extract values when conflicted between °C degrees & ° vol degrees
        def extract_conflicting_degrees
          tav = @user_input.matchdel(Duke::Utils::Regex.conflicting_tav)
          @parameters['tav'] = tav[6].gsub(',', '.') if tav
          temp = @user_input.matchdel(Duke::Utils::Regex.conflicting_temp)
          @parameters['temperature'] = temp[4].gsub(',', '.') if temp
        end

        # Extracting TAV value in @user_input
        def extract_tav
          tav = @user_input.matchdel(Duke::Utils::Regex.tav)
          @parameters['tav'] = tav ? tav[1].gsub(',', '.') : nil unless @parameters.key?('tav')
        end

        # Extracting Temperature value in @user_input
        def extract_temp
          temp = @user_input.matchdel(Duke::Utils::Regex.temp)
          unless @parameters.key?('temperature')
            @parameters['temperature'] =  temp ? temp[1].gsub(',', '.') : nil
          end
        end

        # Extracting pH value in @user_input
        def extract_ph
          ph = @user_input.matchdel(Duke::Utils::Regex.ph)
          second_ph = @user_input.matchdel(Duke::Utils::Regex.second_ph)
          @parameters['ph'] = if ph
                                ph[1].gsub(',', '.') # ph is the first capturing group
                              else
                                second_ph ? second_ph[6].gsub(',', '.') : nil # ph is the sixh capturing group
                              end
        end

        # Extract Nitrogen value in @user_input
        def extract_amino_nitrogen
          nitrogen = @user_input.matchdel(Duke::Utils::Regex.nitrogen)
          second_nitrogen = @user_input.matchdel(Duke::Utils::Regex.second_nitrogen)
          @parameters['amino_nitrogen'] =  if nitrogen
                                             nitrogen[1].gsub(',', '.') # nitrogen is the first capturing group
                                           elsif second_nitrogen
                                             second_nitrgoen ? second_nitrogen[5].gsub(',', '.') : nil
                                           end
        end

        # Extract Nitrogen value in @user_input
        def extract_ammoniacal_nitrogen
          nitrogen = @user_input.matchdel(Duke::Utils::Regex.ammo_nitrogen)
          second_nitrogen = @user_input.matchdel(Duke::Utils::Regex.second_ammo_nitrogen)
          @parameters['ammoniacal_nitrogen'] =  if nitrogen
                                                  nitrogen[1].gsub(',', '.') # nitrogen is the first capturing group
                                                elsif second_nitrogen
                                                  second_nitrogen ? second_nitrogen[6].gsub(',', '.') : nil
                                                end
        end

        # Extract Nitrogen value in @user_input
        def extract_assimilated_nitrogen
          nitrogen = @user_input.matchdel(Duke::Utils::Regex.assi_nitrogen)
          second_nitrogen = @user_input.matchdel(Duke::Utils::Regex.second_assi_nitrogen)
          @parameters['assimilated_nitrogen'] = if nitrogen
                                                  nitrogen[1].gsub(',', '.') # nitrogen is the first capturing group
                                                elsif second_nitrogen
                                                  second_nitrogen ? second_nitrogen[7].gsub(',', '.') : nil
                                                end
        end

        # Extract SanitaryState value in @user_input
        def extract_sanitarystate
          sanitary_match = @user_input.match(Duke::Utils::Regex.sanitary_state)
          sanitarystate = ''
          if sanitary_match
            sanitarystate += sanitary_match[2]
            @user_input.gsub!(sanitary_match[1], '')
            @user_input.gsub!(sanitary_match[2], '')
          end
          {
            sain: /s(a|e)in/,
            correct: /correct/,
            nromal: /normal/,
            botrytis: /(botrytis|beau titre is)/,
            oïdium: /o.dium/,
            pourriture: /pourriture/
          }.each do |val, regex|
            sanitarystate += val.to_s if @user_input.matchdel regex
          end
          @parameters['sanitarystate'] = (sanitarystate if sanitarystate != '')||nil
        end

        # Extract SO Acid value in @user_input
        def extract_h2so4
          h2so4 = @user_input.matchdel(Duke::Utils::Regex.h2so4)
          second_h2so4 = @user_input.matchdel(Duke::Utils::Regex.second_h2so4)
          @parameters['h2so4'] =  if h2so4
                                    h2so4[1].gsub(',', '.') # h2so4 is the first capturing group
                                  elsif second_h2so4
                                    second_h2so4 ? second_h2so4[5].gsub(',', '.') : nil # h2so4 is the third capturing group
                                  end
        end

        # Extract Malic Acid value in @user_input
        def extract_malic
          malic = @user_input.matchdel(Duke::Utils::Regex.malic)
          second_malic = @user_input.matchdel(Duke::Utils::Regex.second_malic)
          @parameters['malic'] =  if malic
                                    malic[1].gsub(',', '.') # malic is the first capturing group
                                  elsif second_malic
                                    second_malic ? second_malic[6].gsub(',', '.') : nil # malic is the sixth capturing group
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
              first_area = @user_input.match(Duke::Utils::Regex.first_area(target.matched))
              second_area = @user_input.match(Duke::Utils::Regex.second_area(target.matched))
              if first_area  # If percentage -> Area value
                target[:area] = first_area[1].to_i
              elsif second_area && Plant.find_by(id: target[:key]).present? # If area -> convert in percentage -> Area value
                target[:area] = 100
                area = second_area[3].match(/hect/) ? second_area[1].gsub(',', '.').to_f : second_area[1].gsub(',', '.').to_f/100
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
            return ["#{I18n.t("duke.harvest_reception.ask.how_much_to_#{rand(0...2)}")} #{cuve[:name]}", index] unless cuve.key?('quantity')
          end
        end

        def speak_pressing_hl
          @press.each_with_index do |press, index|
            unless press.key?('quantity')
              return ["#{I18n.t("duke.harvest_reception.ask.how_much_to_#{rand(0...2)}")} #{press[:name]}",
                      index]
            end
          end
        end

        # @return [String] sentence with current harvestReception recap
        def speak_harvest_reception
          sentence = I18n.t("duke.harvest_reception.ask.save_harvest_reception_#{rand(0...2)}")
          # Crop Group
          if @crop_groups.present?
            sentence+= "<br>&#8226 #{I18n.t('duke.interventions.group')} : "
            sentence += @crop_groups.map{|cg| "#{cg[:area].to_s}% #{cg.name}"}.join(', ').to_s
          end
          # Plant
          if @plant.present?
            sentence+= "<br>&#8226 #{I18n.t('duke.interventions.plant')} : "
            sentence += @plant.map{|tar| "#{tar[:area].to_s}% #{tar.name}"}.join(', ').to_s
          end
          # Quantity
          sentence+= "<br>&#8226 #{I18n.t('duke.harvest_reception.quantity')} : "
          sentence += "#{@parameters['quantity']['rate'].to_s} #{@parameters['quantity']['unit']}"
          # TAV
          sentence+= "<br>&#8226 #{I18n.t('duke.harvest_reception.tavp')} : #{@parameters['tav']} % vol"
          # Destinations
          sentence+= "<br>&#8226 #{I18n.t('duke.harvest_reception.destination')} : "
          sentence += @destination.map{|des| "#{des.name}#{" (#{des[:quantity].to_s} hl)" if des.key?('quantity')}"}.join(', ').to_s
          # Press
          if @press.present?
            sentence+= "<br>&#8226 #{I18n.t('duke.harvest_reception.press')} : "
            sentence += @press.map{|press| "#{press.name}#{" (#{press[:quantity].to_s} hl)" if press.key?('quantity')}"}.join(', ').to_s
          end
          # Date
          sentence+= "<br>&#8226 #{I18n.t('duke.interventions.date')} : #{@date.to_time.strftime('%d/%m/%Y - %H:%M')}"
          # Optional parameters
          %w[temperature sanitarystate ph h2so4 malic amino_nitrogen ammoniacal_nitrogen assimilated_nitrogen pressing_tavp].each do |param|
            sentence += I18n.t("duke.harvest_reception.speak.#{param}", "#{param}": @parameters[param]) if @parameters[param].present?
          end
          # Complementary parameters
          complement = @parameters['complementary']
          if complement.present?
            if complement.key?('ComplementaryDecantation')
              sentence+= I18n.t('duke.harvest_reception.speak.decant_time', time: complement['ComplementaryDecantation'].delete('^0-9'))
            end
            if complement.key?('ComplementaryTrailer')
              sentence += I18n.t('duke.harvest_reception.speak.transporter', transporter: complement['ComplementaryTrailer'])
            end
            if complement.key?('ComplementaryTime')
              sentence +=  I18n.t('duke.harvest_reception.speak.transport_dur',
                                  transport_dur: complement['ComplementaryTime'].delete('^0-9'))
            end
            if complement.key?('ComplementaryDock')
              sentence += I18n.t('duke.harvest_reception.speak.reception_dock', reception_dock: complement['ComplementaryDock'])
            end
            if complement.key?('ComplementaryNature')
              h_nature = I18n.t("duke.harvest_reception.#{complement['ComplementaryNature']}")
              sentence += I18n.t('duke.harvest_reception.speak.h_nature', h_nature: h_nature)
            end
            sentence+=  I18n.t('duke.harvest_reception.speak.last_load') if complement.key?('ComplementaryLastLoad')
          end
          sentence.gsub(/, <br>&#8226/, '<br>&#8226')
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
          elsif (@destination.to_a.length > 1) && @destination.any? {|dest| !dest.key?('quantity')}
            return :ask_destination_quantity, *speak_destination_hl
          elsif (@press.to_a.length > 1) && @press.any? {|press| !press.key?('quantity')}
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
