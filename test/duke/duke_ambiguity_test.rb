# frozen_string_literal: true

require 'test_helper'

class DukeAmbiguityTest < Minitest::Test
  def setup
    @itm = Duke::DukeMatchingItem.new(key: 18, name: 'Massey-Fergusson', distance: 98, matched: 'Massey Fergusson')
    @itm2 = Duke::DukeMatchingItem.new(id: 22, partials: ['Massey-Fergusso'], name: 'Massey Fergusso')
    @itm3 = Duke::DukeMatchingItem.new(id: 25, partials: ['Charrue', 'Marsaly', 'Charrue Marsaly'],
                                       name: 'Charrue Marsaly')
    @ambiguity = Duke::DukeAmbiguity.new(itm: @itm, ambiguity_attr: [[:tool, [@itm2, @itm3]]], itm_type: :tool)
  end

  def test_it_can_find_ambiguous_item
    assert @ambiguity.send('ambiguous?', @itm2), 'Should find an ambiguity'
    refute @ambiguity.send('ambiguous?', @itm3), "Shouldn't find an ambiguity"
  end

  def test_it_can_create_ambiguous_option
    assert_equal @itm.name, @ambiguity.send(:option)[:label], "Can't find correct label for ambiguity option name"
    assert_equal @itm2[:name], @ambiguity.send(:option, product: @itm2, type: :tool)[:label],
                 "Can't find correct name for ambiguity option"
  end

  def test_it_can_create_ambiguity_object
    assert_empty @ambiguity.send(:create_ambiguity), 'Ambiguity should be empty'
    @ambiguity.check_ambiguity
    refute_empty @ambiguity.send(:create_ambiguity), 'Ambiguity should be present'
  end
end
