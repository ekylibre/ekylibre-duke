module Duke
  module Skill
    class DukeSingleMatch < DukeArticle

      def initialize(**args)
        super()
        args.each{|k, v| instance_variable_set("@#{k}", v)}
      end

      private

        attr_accessor :financial_year, :journal, :account, :bank_account, :fixed_asset, :depreciable, :entity, :activity_variety

        def parseable
          [*super, :financial_year, :journal, :account, :bank_account, :fixed_asset, :depreciable, :entity, :activity_variety].uniq
        end

        # Returns best account
        def best_account
          @account.max
        end

        # Returns best fixed_asset
        def best_fixed_asset
          @fixed_asset.max
        end

        # Returns best depreciable
        def best_depreciable
          @depreciable.max
        end

        # Returns best entity
        def best_entity
          @entity.max
        end

        # Returns best activity variety
        def best_activity_variety
          @activity_variety.max
        end

        # Returns best tool
        def best_tool
          @tool.max
        end

        # Returns best bank_account
        def best_bank_account
          return DukeMatchingItem.new(key: Cash.first.id, name: Cash.first.name) if Cash.all.size.eql?(1)

          @bank_account.max
        end

        # Returns best journal
        def best_journal
          return DukeMatchingItem.new(key: Journal.first.id, name: Journal.first.name) if Journal.all.size.eql?(1)

          @journal.max
        end

        # Returns best financial year
        def best_financial_year
          return DukeMatchingItem.new(key: FinancialYear.first.id, name: FinancialYear.first.name) if FinancialYear.all.size.eql?(1)

          @financial_year.max
        end

        # Correct financialYear ambiguity
        def w_fy(fec_format: nil)
          if FinancialYear.all.empty?
            Duke::DukeResponse.new(
              redirect: :createFinancialYear,
              sentence: I18n.t('duke.exports.need_financial_year_creation')
            )
          else
            fys = FinancialYear.all.map{|fy| optionify(fy.code, fy.id.to_s)}
            Duke::DukeResponse.new(
              redirect: :ask_financialyear,
              options: dynamic_options(I18n.t('duke.exports.which_financial_year'), fys),
              parsed: fec_format
            )
          end
        end

        # Set @financialYear from btn-suggestion-click
        # @param [String] id - optional btn-click-fy-id
        def year_from_id(id)
          if id.present? && FinancialYear.all.collect(&:id).include?(id.to_i)
            @financial_year = {
              key: id.to_i,
              name: FinancialYear.find_by_id(id.to_i).code
              }
          end
        end

        # Returns sale|purchase type
        # @param [String] type - recognized saleType entity from IBM
        def sale_filter(type)
          type.nil? ? :all : :unpaid
        end

        # Extract uniq best element for each arg entry
        def extract_best(*args)
          extract_user_specifics(duke_json: self.duke_json(args), level: 71)
          args.each do |arg|
            instance_variable_set("@#{arg}", send("best_#{arg}")) if respond_to?("best_#{arg}", true)
          end
        end

        # Extract fec_format from user utterance
        # @param [String] format: Format if user clicked on btn-format-suggestion
        def fec_format(format = nil)
          if format.present? && %i[text xml].include?(format.to_sym)
            format
          elsif @user_input.match(/t(e)?xt/)
            :text
          elsif @user_input.match(/xml/)
            :xml
          end
        end

    end
  end
end
