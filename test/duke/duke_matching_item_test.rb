# frozen_string_literal: true

require 'test_helper'
class DukeMatchingItemTest < Minitest::Test
  def setup
    @itm1 = Duke::DukeMatchingItem.new(key: 12, name: 'Bouleytreau', distance: 95, matched: 'Bouleytreau')
    @itm2 = Duke::DukeMatchingItem.new(key: 10, name: 'Bouleytreau Verrier', distance: 91, matched: 'Bouleytreau Vert')
  end

  def test_can_find_if_other_item_match_is_lower
    refute @itm1.lower_match?(@itm2), "Couldn't find lower match"
  end

  def test_can_merge_an_item_into_another_hash
    assert_includes @itm1.merge_h(
      {
        area: 100
      }
    ).keys, :area.to_s, "Couldn't find key inside merged DukeMatchingItem"
  end
end
