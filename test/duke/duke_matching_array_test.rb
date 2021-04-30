# frozen_string_literal: true

require 'test_helper'
class DukeMatchingArrayTest < Minitest::Test
  def setup
    @itm1 = Duke::DukeMatchingItem.new(key: 11, name: 'Tracteur case ih', distance: 100, indexes: [1, 2, 3],
                                       matched: 'tracteur case ih')
    @itm2 = Duke::DukeMatchingItem.new(key: 12, name: 'Tracteur case oh', distance: 95, indexes: [1, 2, 3],
                                       matched: 'tracteur case ih')
    @itm3 = Duke::DukeMatchingItem.new(key: 13, name: 'Tracteur case rh', distance: 95, indexes: [7, 8, 9],
                                       matched: 'tracteur case ih')
    @itm4 = Duke::DukeMatchingItem.new(key: 13, name: 'Tracteur case rh', distance: 99, indexes: [11, 12, 13],
                                       matched: 'tracteur case r h')
    @empty_array = Duke::DukeMatchingArray.new
    @array = Duke::DukeMatchingArray.new(arr: [@itm1, @itm2])
    @array2 = Duke::DukeMatchingArray.new(arr: [@itm1, @itm3])
  end

  def test_can_concatenate_with_unicity_matching_arrays
    assert_equal 3, @array.uniq_concat(@array2).size, "Couldn't concatenate arrays"
  end

  def test_can_unicify_array
    assert_equal @array, @array.uniq_by_key, 'Unicity by key not repected on 1.size Array'
    assert_equal @array, Duke::DukeMatchingArray.new(arr: @array + [@itm1]).uniq_by_key,
                 'Unicity by key not working when duplicate'
  end

  def test_can_find_best_match
    assert_equal @itm1, @array.max, "Can't find best itm in DukeMatchingArray"
  end

  def test_can_find_itm_by_key
    assert_equal @itm1, @array.find_by_key(11), "Can't find item by key in DukeMatchingArray"
  end

  def test_can_add_element_correctly_to_array
    @empty_array.add_to_recognized(@itm2, [@empty_array])
    refute_empty @empty_array, "Array shouldn't be empty"
    @empty_array.add_to_recognized(@itm1, [@empty_array])
    assert_includes @empty_array, @itm1, "Couldn't add item to DukeMatchingArray"
    assert_equal 1, @empty_array.size, 'Added to many items (or not enough) to DukeMatchingArray'
    @empty_array.add_to_recognized(@itm3, [@empty_array, @array2])
    assert_equal 1, @empty_array.size, 'Added to many items (or not enough) to DukeMatchingArray'
    @empty_array.add_to_recognized(@itm3, [@empty_array])
    assert_equal 2, @empty_array.size, 'Added not enought (or too much) items to DukeMatchingArray'
  end

  def test_can_find_duplicated
    refute @array.duplicate?(@itm3), "Shouldn't find a duplicate"
    assert @array.duplicate?(@itm2), 'Should find a duplicate'
    refute @array2.duplicate?(@itm4), "Shouldn't find a duplicate"
    assert_equal 1, @array2.size, 'Added to many items to array'
  end

  def test_can_find_overlaps
    assert @array2.overlap?(@itm2), "Didn't find an overlap when present"
    refute @array2.overlap?(@itm4), 'Find a non existent overlap'
  end

  def test_can_find_lower_overlap
    assert @array2.lower_overlap?(@itm2), "Didn't find an overlap with lower distance"
  end
end
