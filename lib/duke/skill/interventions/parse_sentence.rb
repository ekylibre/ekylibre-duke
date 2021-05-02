module Duke
  module Skill
    module Interventions
      class ParseSentence < Duke::Skill::DukeIntervention
        using Duke::DukeRefinements

        def initialize(event)
          super(user_input: event.user_input, procedure: event.options.procedure)
          extract_procedure unless permitted_procedure_or_categorie?
        end

        def handle
          if ok_procedure?
            parse_sentence
            to_ibm(modifiable: modification_candidates, moreable: complement_candidates)
          else
            guide_to_procedure
          end
        end

        private

          # @returns bln, is procedure_parseable?
          def ok_procedure?
            procedo = Procedo::Procedure.find(@procedure)
            procedo.present? && (procedo.activity_families & %i[vine_farming plant_farming]).any?
          end

          # @return json with next_step if procedure is not parseable
          def guide_to_procedure
            if @procedure.blank?
              suggest_procedure_from_blank
            elsif @procedure.is_a?(Hash)
              suggest_procedure_from_hash
            else
              suggest_procedure_from_string
            end
          end

          # Is the transmitted procedure accepted, or a category or an activity family
          def permitted_procedure_or_categorie?
            ok_procedure? or Onoma::ProcedureCategory.find(@procedure).present? or Onoma::ActivityFamily.find(@procedure).present?
          end

          # Extract procedure from user sentence
          def extract_procedure
            procs = Duke::DukeMatchingArray.new
            @user_input += " - #{@procedure}" if @procedure.present?
            @user_input = @user_input.duke_clear # Get clean string before parsing
            attributes =  [
                            [
                              :procedure,
                              {
                                iterator: procedure_iterator,
                                list: procs
                              }
                            ]
                          ]
            create_words_combo.each do |combo| # Creating all combo_words from user_input
              parser = DukeParser.new(word_combo: combo, level: 80, attributes: attributes) # create new DukeParser
              parser.parse # parse procedure
            end
            @procedure = procs.max.key if procs.present?
          end

          # Procedures iterator depending on user activity scope
          def procedure_iterator
            procedure_scope =
            [
              :common,
              if ekyagri?
                :vegetal
              else
                vegetal? ? :viti_vegetal : :viti
              end,
              animal? ? :animal : nil
            ]
            procedure_entities.slice(*procedure_scope).values.flatten
          end

          # Handles blank procedure accordingly
          def suggest_procedure_from_blank
            if (farming_type = exclusive_farming_type).present?
              suggest_categories_from_family(farming_type)
            else
              suggest_families_disambiguation
            end
          end

          # Handles string (not accepted procedure) accordingly
          def suggest_procedure_from_string
            procedo = Procedo::Procedure.find(@procedure)
            if Onoma::ActivityFamily.find(@procedure).present?
              suggest_categories_from_family(@procedure)
            elsif Onoma::ProcedureCategory.find(@procedure).present?
              suggest_procedures_from_category
            elsif procedo.present? && (procedo.activity_families & %i[vine_farming plant_farming]).empty?
              non_supported_redirect
            elsif @procedure.scan(/cancel/).present?
              cancel_redirect
            else
              not_understanding_redirect
            end
          end

          # Handles hash procedure (matched a category or an ambiguity) accordingly
          def suggest_procedure_from_hash
            if @procedure.key?(:categories)
              suggest_categories_disambiguation
            elsif @procedure.key?(:procedures)
              suggest_procedures_disambiguation
            elsif @procedure.key?(:category)
              @procedure = @procedure[:category]
              suggest_procedures_from_category
            end
          end

          # Suggest disambiguation to the user for his selected procedure
          # @returns json
          def suggest_procedures_disambiguation
            procs = @procedure[:procedures].map do |proc|
              label = Procedo::Procedure.find(proc[:name]).human_name
              label +=  " - Prod. #{proc[:family]}" if proc.key?(:family)
              optionify(label, proc[:name])
            end
            options = dynamic_options(I18n.t('duke.interventions.ask.which_procedure'), procs)
            Duke::DukeResponse.new(parsed: @description, redirect: :what_procedure, options: options)
          end

          # Suggest disambiguation to the user for his selected category
          # @returns json
          def suggest_categories_disambiguation
            categories = @procedure[:categories].map do |cat|
              label = Onoma::ProcedureCategory.find(cat[:name]).human_name
              label += " - Prod. #{cat[:family]}" if cat.key?(:family)
              optionify(label, cat[:name])
            end
            options = dynamic_options(I18n.t('duke.interventions.ask.what_category'), categories)
            Duke::DukeResponse.new(parsed: @description, redirect: :what_procedure, options: options)
          end

          # Suggest disambiguation to the user for the intervention family
          def suggest_families_disambiguation
            families = %i[plant_farming vine_farming].map do |fam|
              optionify(Onoma::ActivityFamily[fam].human_name, fam)
            end
            families += [optionify(I18n.t('duke.interventions.cancel'), :cancel)]
            options = dynamic_options(I18n.t('duke.interventions.ask.what_family'), families)
            Duke::DukeResponse.new(parsed: @description, redirect: :what_procedure, options: options)
          end

          # Suggest procedures to the user for selected category
          def suggest_procedures_from_category
            procs = Procedo::Procedure.of_main_category(@procedure)
            procs.sort_by!(&:position) if procs.all?{|proc| defined?(proc.position)}
            procs.map! do |proc|
              optionify(proc.human_name.to_sym, proc.name)
            end
            options = dynamic_options(I18n.t('duke.interventions.ask.which_procedure'), procs)
            Duke::DukeResponse.new(parsed: @description, redirect: :what_procedure, options: options)
          end

          # Suggest categories to the user for selected family
          def suggest_categories_from_family(family)
            categories = Onoma::ProcedureCategory.select do |cat|
              cat.activity_family.include?(family.to_sym) and Procedo::Procedure.of_main_category(cat).present?
            end
            categories = ListSorter.new(:procedure_categories, categories).sort if defined?(ListSorter)
            categories.map! do |cat|
              optionify(cat.human_name, cat.name)
            end
            options = dynamic_options(I18n.t('duke.interventions.ask.what_category'), categories)
            Duke::DukeResponse.new(parsed: @description, redirect: :what_procedure, options: options)
          end

          # @returns json Option with all clickable buttons understandable by IBM
          def complement_candidates
            procedo = Procedo::Procedure.find(@procedure)
            candidates = %i[target tool doer input].select{|type| procedo.parameters_of_type(type).present?}
                                                        .map{|type| optionify(I18n.t("duke.interventions.#{type}"))}
            candidates.push optionify(I18n.t('duke.interventions.working_period'))
            dynamic_options(I18n.t('duke.interventions.ask.what_add'), candidates)
          end

      end
    end
  end
end
