module Duke
  module Skill
    module Redirections
      class ToPhytoImport

        def initialize(event)
          @event = event
        end

        def handle
          #  modify paraams p_id, params aam change in CODE !!!
          if (prod = RegisteredPhytosanitaryProduct.find_by_id(@event.parsed)).present? #  parsed if phyto id
            Duke::DukeResponse.new(
              redirect: :over,
              sentence: I18n.t('duke.import.phyto_id', id: prod.id, name: prod.name)
            )
          elsif @event.options.specific.present? #  Specific is aam number
            prods = RegisteredPhytosanitaryProduct.select{|ph| ph.france_maaid == params[:aam]}
            response =  if prods.empty?
                          Duke::DukeResponse.new(
                            redirect: :over,
                            sentence: I18n.t('duke.import.invalid_maaid', id: @event.options.specific)
                          )
                        elsif prods.size.eql? 1
                          Duke::DukeResponse.new(
                            redirect: :over,
                            sentence: I18n.t('duke.import.phyto_id', id: prods.first.id, name: prods.first.name)
                          )
                        else
                          options = prods.map{|p| optionify(p.name, p.id.to_s)}
                          Duke::DukeResponse.new(
                            redirect: :ask,
                            options: dynamic_options(I18n.t('duke.import.w_maaid'), options)
                          )
                        end
            response
          else #  Issue matching Thousands of Phyto Products names, just redirecting to phyto_main_page
            Duke::DukeResponse.new(redirect: :over, sentence: I18n.t('duke.import.all_phyto'))
          end
        end

      end
    end
  end
end
