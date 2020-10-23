module Duke
  class Interventions < Duke::Utils::InterventionUtils

    def handle_parse_sentence(params)
      Ekylibre::Tenant.switch params['tenant'] do
        procedure = params['procedure']
        unless procedure.scan(/[|]/).empty?
          if Activity.availables.any? {|act| act[:family] != :vine_farming}
            what_next, sentence, optional = disambiguate_procedure(procedure)
            return {:parsed => params[:user_input], :redirect => what_next, :sentence => sentence, :optional => optional}
          else 
            procedure = procedure.split(/[|]/)[1]
          end 
        end 
        return if Procedo::Procedure.find(procedure).nil?
        unless (Procedo::Procedure.find(procedure).activity_families & [:vine_farming, :plant_farming]).any?
          return {:redirect => "non_supported_proc"}
        end 
        equipments, workers, inputs = [], [], []
        # Finding when it happened and how long it lasted, + getting cleaned user_input
        date, duration, user_input = extract_date_and_duration(clear_string(params[:user_input]))
        parsed = {:inputs => inputs,
                  :workers => workers,
                  :equipments => equipments,
                  :procedure => procedure,
                  :duration => duration,
                  :date => date,
                  :user_input => params[:user_input],
                  :retry => 0}
        tag_specific_targets(parsed)
        extract_user_specifics(user_input, parsed)
        add_input_rate(user_input, parsed[:inputs])
        parsed[:ambiguities] = find_ambiguity(parsed, user_input)
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :sentence => sentence, :redirect => what_next, :optional => optional  }
      end
    end

    def handle_parse_disambiguation(params)
      parsed = params[:parsed]
      ambElement = params[:optional][-2]
      ambType, ambArray = parsed.find { |key, value| value.is_a?(Array) and value.any? { |subhash| subhash[:name] == ambElement[:name]}}
      ambHash = ambArray.find {|hash| hash[:name] == ambElement[:name]}
      begin
        chosen_one = eval(params[:user_input])
        ambHash[:name] = chosen_one["name"]
        ambHash[:key] = chosen_one["key"]
      rescue
        if params[:user_input] == "Tous"
          params[:optional].each_with_index do |ambiguate, index|
            # Last two values are the one that's already added, and the inSentenceName value -> useless
            unless [1,2].include?(params[:optional].length - index)
              hashClone = ambHash.clone()
              hashClone[:name] = ambiguate[:name].to_s
              hashClone[:key] = ambiguate[:key].to_s
              ambArray.push(hashClone)
            end
          end
        elsif params[:user_input] == "Aucun"
          ambArray.delete(ambHash)
        end
      ensure
        parsed[:ambiguities].shift
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_add_information(params)
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        new_equipments = []
        new_workers = []
        new_inputs = []
        new_crop_groups = []
        user_input = clear_string(params[:user_input])
        new_parsed = {:inputs => new_inputs,
                      :workers => new_workers,
                      :equipments => new_equipments,
                      :procedure => parsed[:procedure],
                      :duration => parsed[:duration],
                      :date => parsed[:date],
                      :user_input => user_input}
        tag_specific_targets(new_parsed)
        extract_user_specifics(user_input, new_parsed)
        add_input_rate(user_input, new_inputs)
        [:inputs, :workers, :equipments, :crop_groups, Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name].each do |entity|
          parsed[entity] = uniq_concat(new_parsed[entity], parsed[entity].to_a)
        end
        parsed[:user_input] += " - #{params[:user_input]}"
        parsed[:ambiguities] = find_ambiguity(new_parsed, user_input)
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_modify_target(params)
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        crop_groups = []
        user_input = clear_string(params[:user_input])
        new_parsed = {:procedure => parsed[:procedure],
                      :duration => parsed[:duration],
                      :date => parsed[:date],
                      :user_input => user_input}
        tag_specific_targets(new_parsed)
        extract_user_specifics(user_input, new_parsed)
        parsed[:crop_groups] = new_parsed[:crop_groups]
        parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name] =  new_parsed[Procedo::Procedure.find(parsed[:procedure]).parameters.find {|param| param.type == :target}.name]
        parsed[:user_input] += " - (Cultures) #{params[:user_input]}"
        parsed[:ambiguities] = find_ambiguity(new_parsed, user_input)
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_modify_worker(params)
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        workers = []
        user_input = clear_string(params[:user_input])
        new_parsed = {:workers => workers,
                      :procedure => parsed[:procedure],
                      :duration => parsed[:duration],
                      :date => parsed[:date],
                      :user_input => user_input}
        extract_user_specifics(user_input, new_parsed)
        parsed[:workers] = new_parsed[:workers]
        parsed[:user_input] += " - (Travailleurs) #{params[:user_input]}"
        parsed[:ambiguities] = find_ambiguity(new_parsed, user_input)
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_modify_temporality(params)
      parsed = params[:parsed]
      date, duration, user_input = extract_date_and_duration(clear_string(params[:user_input]))
      parsed[:date] = choose_date(date, parsed[:date])
      parsed[:duration] = choose_duration(duration, parsed[:duration])
      parsed[:user_input] += " - (Temporalité) #{params[:user_input]}"
      parsed[:ambiguities] = []
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
    end

    def handle_modify_equipment(params)
      parsed = params[:parsed]
      Ekylibre::Tenant.switch params['tenant'] do
        equipments = []
        user_input = clear_string(params[:user_input])
        new_parsed = {:equipments => equipments,
                      :procedure => parsed[:procedure],
                      :duration => parsed[:duration],
                      :date => parsed[:date],
                      :user_input => user_input}
        extract_user_specifics(user_input, new_parsed)
        parsed[:equipments] = new_parsed[:equipments]
        parsed[:user_input] += " - (Equipement) #{params[:user_input]}"
        parsed[:ambiguities] = find_ambiguity(new_parsed, user_input)
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
    end

    def handle_parse_input_quantity(params)
      parsed = params[:parsed]
      value = extract_number_parameter(params[:quantity], params[:user_input])
      if value.nil?
        parsed[:retry] += 1
        what_next, sentence, optional = redirect(parsed)
        return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
      end
      parsed[:inputs][params[:optional]][:rate][:value] = value
      parsed[:user_input] += " - (Quantité) #{params[:user_input]}"
      parsed[:retry] = 0
      what_next, sentence, optional = redirect(parsed)
      return  { :parsed => parsed, :redirect => what_next, :sentence => sentence, :optional => optional}
    end


    def handle_save_intervention(params)
      I18n.locale = :fra
      Ekylibre::Tenant.switch params['tenant'] do
        tools_attributes = []
        params[:parsed][:equipments].to_a.each do |tool|
          tools_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:tool)[0].name, 'product_id' => tool[:key]})
        end
        doers_attributes = []
        params[:parsed][:workers].to_a.each do |worker|
          doers_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:doer)[0].name, "product_id" => worker[:key]})
        end
        inputs_attributes = []
        unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:input).empty?
          params[:parsed][:inputs].to_a.each do |input|
            inputs_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters_of_type(:input)[0].name,
                                               "product_id" => input[:key],
                                               "quantity_value" => input[:rate][:value].to_f*input[:rate][:factor],
                                               "quantity_population" => input[:rate][:value].to_f*input[:rate][:factor],
                                               "quantity_handler" => input[:rate][:unit]})
          end
        end
        unless Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.nil?
          targets_attributes = []
          params[:parsed][Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.name].to_a.each do |target|
            targets_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.name, "product_id" => target[:key]})
          end 
          params[:parsed][:crop_groups].to_a.each do |cropgroup|
            CropGroup.available_crops(cropgroup[:key], "is plant").each do |crop|
              targets_attributes.push({"reference_name" => Procedo::Procedure.find(params[:parsed][:procedure]).parameters.find {|param| param.type == :target}.name, "product_id" => crop[:id]})
            end
          end
        end 
        duration = params[:parsed][:duration].to_i
        date = params[:parsed][:date]

        intervention = Intervention.create!(procedure_name: params[:parsed][:procedure],
                                            description: 'Duke : ' << params[:parsed][:user_input],
                                            state: 'done',
                                            number: '50',
                                            nature: 'record',
                                            tools_attributes: tools_attributes,
                                            doers_attributes: doers_attributes,
                                            targets_attributes: targets_attributes,
                                            inputs_attributes: inputs_attributes,
                                            working_periods_attributes:   [ { "started_at": Time.zone.parse(date) , "stopped_at": Time.zone.parse(date) + duration.minutes}])
        return {"link" => "\\backend\\interventions\\"+intervention['id'].to_s}
      end
    end
  end
end
