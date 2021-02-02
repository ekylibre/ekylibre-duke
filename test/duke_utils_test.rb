require 'minitest/autorun'
require "fuzzystringmatch"
require "lib/duke/utils/duke_parsing"
require "lib/duke/utils/intervention_utils"
require "lib/duke/utils/harvest_reception_utils"

module Duke
  class DukeArticleTest < MiniTest::Unit::TestCase
    dukeArt = Duke::Models::DukeArticle.new(user_input: "J'ai labouré sur bouleytreau et bernessard")
    def test_create_words_combos
      # Should return exactly 30 combos of words
      assert_equal(30, dukeArt.create_words_combo.length, "Number of created words-combos is not exact")
      assert_equal({[0]=>"this",
                    [1]=>"is",
                    [2]=>"a",
                    [3]=>"sentence",
                    [0, 1]=>"this is",
                    [1, 2]=>"is a",
                    [2, 3]=>"a sentence",
                    [0, 1, 2]=>"this is a",
                    [1, 2, 3]=>"is a sentence",
                    [0, 1, 2, 3]=>"this is a sentence"},DukeParsing.create_words_combo("this is a sentence"), "Combos are not created correctly")
    end

    def test_duplicates
      saved_hash = {:key=>6, :name=>"Plantations nouvelles 2019", :indexes=>[7, 8], :distance=>0.95}
      saved_hash_lower = {:key=>4, :name=>"Jeunes plants", :indexes=>[4, 5], :distance=>0.94}
      saved_hash_higher = {:key=>4, :name=>"Jeunes plants", :indexes=>[4, 5], :distance=>0.98}
      target_list = [{:key=>4, :name=>"Jeunes plants", :indexes=>[3, 4], :distance=>0.97}]
      # No duplicate, should return False 
      assert_equal(false, DukeParsing.key_duplicate?(target_list, saved_hash), "Finds a duplicate when not present")
      assert_equal([{:key=>4, :name=>"Jeunes plants", :indexes=>[3, 4], :distance=>0.97}], target_list, "List Mutation shouldn't have happened")
      # Duplicate with higher distance, should return True 
      assert_equal(true, DukeParsing.key_duplicate?(target_list, saved_hash_lower), "Duplicate with higher distance not found")
      assert_equal([{:key=>4, :name=>"Jeunes plants", :indexes=>[3, 4], :distance=>0.97}], target_list, "List Mutation shouldn't have happened")
      # Duplicate with lower distance, should return False without overlappind element in previous list
      assert_equal(false, DukeParsing.key_duplicate?(target_list, saved_hash_higher), "Duplicate with lower distance not found")
      assert_equal([], target_list, "List Mutation to remove previous element should have occured")
    end

    def test_adding_recognized
      target_list = [{:key=>4, :name=>"Young Crops", :indexes=>[2,3], :distance=>0.97}]
      saved_hash_no_index = {:key=>2, :name=>"Long Crops", :indexes=>[2, 3], :distance=>0.90}
      saved_hash_yes_index = {:key=>2, :name=>"Young Crop thin Parcel", :indexes=>[2, 3, 4, 5], :distance=>0.95} # Distance becomes greater because length of what matches is higher
      saved_hash_no_other_list = {:key=>2, :name=>"Parcel Frederico", :indexes=>[6, 7], :distance=>0.94}
      saved_hash_yes_other_list = {:key=>2, :name=>"Parcel Frederic", :indexes=>[6, 7], :distance=>0.99} # Distance becomes greater because length of what matches is higher
      saved_hash_yes = {:key=>6, :name=>"Bouleytreau Verrier", :indexes=>[10, 11], :distance=>0.95}
      all_lists = [[],
                   [{:key=>74, :name=>"Frederic", :indexes=>[7], :distance=>1.0}],
                   [],
                   target_list]
      # No changes to the list, overlapping indexes and greater distance for the previous item
      assert_equal(target_list, DukeParsing.add_to_recognized(saved_hash_no_index, target_list, all_lists, "On the young crop it's parcel, Frederic and Peter on Bouleytreau Verrier"), "Item in the same list with overlapping indexes")
      # No changes to the list, item in another list but its distance is greater
      assert_equal(target_list, DukeParsing.add_to_recognized(saved_hash_no_other_list, target_list, all_lists, "On the young crop it's parcel, Frederic and Peter on Bouleytreau Verrier"), "Item in another list with same indexes")
      # Changes to the list, overlapping indexes and greater distance
      assert_equal([saved_hash_yes_index], DukeParsing.add_to_recognized(saved_hash_yes_index, target_list, all_lists, "On the young crop it's parcel, Frederic and Peter on Bouleytreau Verrier"), "Distance is greater for the new item")
      # Changes to the list, item in another list with overlapping indexes and a smaller distance
      assert_equal([saved_hash_yes_other_list], DukeParsing.add_to_recognized(saved_hash_yes_other_list, target_list, all_lists, "On the young crop it's parcel, Frederic and Peter on Bouleytreau Verrier"), "Item in another list with same indexes")
      # Changes to the list, basic case, nothing should interrupt
      assert_equal([target_list.first, saved_hash_yes], DukeParsing.add_to_recognized(saved_hash_yes, target_list, all_lists, "On the young crop it's parcel, Frederic and Peter on Bouleytreau Verrier"), "Basic case not working")
    end

    def test_concatenatation
      basic_array = [{:key=>4, :name=>"Jeunes plants", :indexes=>[3, 4], :distance=>0.97}]
      dup_array = [{:key=>4, :name=>"Jeunes plants", :indexes=>[17, 18], :distance=>0.96}]
      no_dup_array = [{:key=>2, :name=>"Bouleytreau-Verrier", :indexes=>[11, 12], :distance=>0.95}]
      remove_dup = [{:key=>2, :name=>"Bouleytreau-Verrier", :indexes=>[11, 12], :distance=>0.95},
                     {:key=>4, :name=>"Jeunes plants", :indexes=>[17, 18], :distance=>0.96}]
      # Returns the previous array - trying to add a duplicate
      assert_equal(basic_array, DukeParsing.uniq_concat(basic_array, dup_array), "Shouldn't add a duplicate to the concatenated array")
      # Returns the concatenations of the two arrays - no duplicate
      assert_equal([basic_array.first, no_dup_array.first], DukeParsing.uniq_concat(basic_array, no_dup_array), "Can't add element to new array when there's no duplicate")
      # Returns the concatenations of the two arrays, without the duplicate
      assert_equal([basic_array.first, remove_dup.first], DukeParsing.uniq_concat(basic_array, remove_dup), "Can't add correct element to new array")
    end

    def test_comparaison
      target_list = []
      workers_list = []
      # When there's a match, it should return : - distance , hash = {key, name, indexes, distance}, list_to_append
      assert_equal([0.9173553719008265, { :key => "item-id", :name => "Bouleytreau", :indexes => [1,2,3] , :distance => 0.9173553719008265}, target_list],
                  DukeParsing.compare_elements("bouley trop", "Bouleytreau", [1,2,3], 0.90, "item-id", target_list, nil, nil),
                  "Matching between a combo & an item did not return correctly")
      # When there's no match, it should return : - previous_distance , previous_best_hash, previous_list_to_append
      assert_equal([0.90, nil, nil],
                   DukeParsing.compare_elements("blatte trop", "Bouleytreau", [1,2,3], 0.90, "item-id", target_list, nil, nil),
                  "Not matching elements did not return correctly when comparing")
    end

    def test_parameters_concatenation
      old = {"tav"=>"12.3", "temperature"=>"18", "quantity"=>{"rate"=>200, "unit"=>"kg"}, "ph"=>"12", "nitrogen"=>"12.5", "sanitarystate"=>nil, "malic"=>nil, "h2so4"=>"4", "operatorymode"=>"manual", "pressing"=>nil}
      new = {"tav"=>"14.5", "quantity"=>nil, "temperature"=>nil, "ph"=>nil, "nitrogen"=>nil, "sanitarystate"=>"sain botrytis ", "malic"=>"12", "h2so4"=>nil, "operatorymode"=>nil, "pressing"=>nil}
      assert_equal( {"tav"=>"12.3",
                     "quantity"=>{"rate"=>200, "unit"=>"kg"},
                     "temperature"=>"18",
                     "ph"=>"12",
                     "nitrogen"=>"12.5",
                     "sanitarystate"=>"sain botrytis ",
                     "malic"=>"12",
                     "h2so4"=>"4",
                     "operatorymode"=>"manual",
                     "pressing"=>nil}, DukeHarvestReceptionUtils.concatenate_analysis(old, new),
                     "Can't concatenate two analysis")
    end

    def test_regex_extraction
      params = {}
      DukeHarvestReceptionUtils.extract_quantity("120 kg", params)
      assert_equal({"rate" => 120, "unit" => "kg"}, params['quantity'], "Basic Quantity regex failed")
      DukeHarvestReceptionUtils.extract_tav("12,3 de tavp", params)
      assert_equal("12.3", params['tav'],"TAVP regex failed")
      DukeHarvestReceptionUtils.extract_temp("18 °", params)
      assert_equal("18", params['temperature'], "Temperature regex failed")
      DukeHarvestReceptionUtils.extract_ph("3.9 de ph", params)
      assert_equal("3.9", params['ph'], "pH regex failed")
      DukeHarvestReceptionUtils.extrat_h2SO4("acidité égale à 3 grammes", params)
      assert_equal("3", params['h2so4'], "H2So4 regex failed")
      DukeHarvestReceptionUtils.extract_malic("12.5 grammes d'acide malique", params)
      assert_equal("12.5", params['malic'], "Malic regex failed")
      params = {}
      DukeHarvestReceptionUtils.extract_quantity("12,4 hectos", params)
      assert_equal({"rate" => 12.4, "unit" => "hl"}, params['quantity'], "Coma Quantity regex failed")
      DukeHarvestReceptionUtils.extract_quantity("3.8 tonnes", params)
      assert_equal({"rate" => 3.8, "unit" => "t"}, params['quantity'], "Dot Quantity regex failed")
      DukeHarvestReceptionUtils.extract_conflicting_degrees("température de 17,4 degrés", params)
      assert_equal("17.4", params['temperature'],"Conflicting degrees regex failed")
      DukeHarvestReceptionUtils.extract_conflicting_degrees("degré d'alcool de 12,4 degrés", params)
      assert_equal("12.4", params['tav'], "Conflicting degrees regex failed")
      DukeHarvestReceptionUtils.extract_ph("péage de 3,7", params)
      assert_equal("3.7", params['ph'], "pH regex failed")
      DukeHarvestReceptionUtils.extract_assimilated_nitrogen("12,4 milligrammes d'azote assimilable", params)
      assert_equal("12.4", params['assimilated_nitrogen'], "nitrogen regex failed")
      DukeHarvestReceptionUtils.extract_ammoniacal_nitrogen("azote ammoniacal était égal à 42", params)
      assert_equal("42", params['ammoniacal_nitrogen'], "nitrogen regex failed")
      DukeHarvestReceptionUtils.extract_sanitarystate("sain et botrytis", params)
      assert_equal("sain botrytis ", params['sanitarystate'], "SanitaryState regex failed")
      DukeHarvestReceptionUtils.extrat_h2SO4("8,2 grammes par litre d'acide", params)
      assert_equal("8.2", params['h2so4'], "H2So4 regex failed")
      DukeHarvestReceptionUtils.extract_malic("Acide malique à 3,5", params)
      assert_equal("3.5", params['malic'], "Malic regex failed")
      params = {}
      DukeHarvestReceptionUtils.extract_tav("12,5 degrés d'alcool", params)
      assert_equal("12.5", params['tav'], "TAVP regex failed")
      DukeHarvestReceptionUtils.extract_temp("19 degrés", params)
      assert_equal("19", params['temperature'], "Temerature regex failed")
    end

    def test_temporality_extraction 
      require 'active_support/core_ext/date/calculations'
      assert_equal(45,DukeParsing.extract_duration("Pendant 45 minutes"), "Did not match work duration correctly")
      assert_equal(120,DukeParsing.extract_duration("Travail de 2 heures"), "Did not match work duration correctly")
      assert_equal(220,DukeParsing.extract_duration("Travail de 3h40"), "Did not match work duration correctly")
      yest = Date.yesterday
      now = DateTime.now
      assert_equal(yest, DukeParsing.choose_date(now, yest), "Choosing wrong date when two are suggested")
      assert_equal(45, DukeParsing.choose_duration(60, 45), "Choosing wrong duration when two are suggested")
      assert_equal(DateTime.new(yest.year, yest.month, yest.day, 13, 54, 0, "+0#{Time.now.utc_offset / 3600}:00"),DukeParsing.extract_date("hier à 13h54"), "Did not match date correctly")
      assert_equal(DateTime.new(yest.year, 7, 14, 10, 0, 0, "+0#{Time.now.utc_offset / 3600}:00"),DukeParsing.extract_date("Le 14 juillet au matin"), "Did not match date correctly")
      assert_equal(DateTime.new(now.year, now.month, now.day, 11, 30, 0, "+0#{Time.now.utc_offset / 3600}:00"), DukeParsing.extract_date("à 11h30"), "Did not match date correctly")
      assert_equal(DateTime.now.hour, DukeParsing.extract_hour("No hour specified").hour, "Hour isn't automatically set to current one")
      assert_equal(DateTime.now.minute, DukeParsing.extract_hour("No hour specified").minute, "Hour isn't automatically set to current one")
      date, duration = DukeInterventionUtils.extract_date_and_duration("Pulvérisation hier de 11h à 14h")
      assert_equal(duration, 180, "Extract date and duration simultaneously failed")
      assert_equal(date, DateTime.new(yest.year, yest.month, yest.day, 11, 00, 00,"+0#{Time.now.utc_offset / 3600}:00"), "Extract date and duration simultaeously failed")
    end 

    def test_plant_area
      targets = [{:key=>85, :name=>"Bernessard", :indexes=>[2], :distance=>1}]
      crop_groups = [{:key=>85, :name=>"Bouleytreau", :indexes=>[6], :distance=>1}]
      DukeHarvestReceptionUtils.extract_plant_area("50% de bernessard et 20% de bouleytreau", targets, crop_groups)
      assert_equal(50, targets.first[:area], "Could not find plant area percentage")
      assert_equal(20, crop_groups.first[:area], "Could not find crop_groups area percentage")
      targets = [{:key=>85, :name=>"Bernessard", :indexes=>[1], :distance=>1}]
      crop_groups = [{:key=>85, :name=>"Bouleytreau", :indexes=>[3], :distance=>1}]
      DukeHarvestReceptionUtils.extract_plant_area("Sur Bernessard et Bouleytreau", targets, crop_groups)
      assert_equal(100, targets.first[:area], "Does not attribute 100% of a plant when not specified")
      assert_equal(100, crop_groups.first[:area], "Does not attribute 100% of a crop_groups when not specified")
    end

    def test_extract_number 
      assert_equal("12.3", DukeParsing.extract_number_parameter(nil, "Dix huit kg et 12,3 grammes d'acide"), "Can't extract number with coma")
      assert_equal("12.3", DukeParsing.extract_number_parameter(nil, "Dix huit kg et 12.3 grammes d'acide"), "Can't extract number with dot")
      assert_equal("12.3", DukeParsing.extract_number_parameter(12, "Dix huit kg et 12.3 grammes d'acide"), "Can't extract number with coma")
      assert_equal("18", DukeParsing.extract_number_parameter(18, "Dix huit kg et 12,3 grammes d'acide"), "Can't extract number with coma")
    end 

    def test_better_corrected_distance?
      content = "Bouleytrea Verrerie parmis"
      hash1 = {:key => "1", :name => "Bouleytreau", :indexes => [0], :distance => 0.92}
      hash2 = {:key => "2", :name => "Bouleytreau Verrier", :indexes => [0, 1], :distance => 0.91}
      hash3 = {:key => "3", :name => "Bouleytreau Verrier parcelle", :indexes => [0,1,2], :distance => 0.82}
      assert_equal(false, DukeParsing.better_corrected_distance?(hash1, hash2, content), "Corrected distance is not taken into account to find best match")
      assert_equal(true, DukeParsing.better_corrected_distance?(hash2, hash3, content), "Corrected distance is not taken into account to find best match")
    end 

    def test_clear_string? 
      str = DukeParsing.clear_string("Cuve numéro 3 -\_\- et Cuve n°4")
      assert_equal("cuve 3 et cuve 4", str, "String clearance not done appropriatly")
    end 
    
  end
end
