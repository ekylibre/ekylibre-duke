require 'test_helper'
class DukeRefinementsTest < Minitest::Test
  def setup
    @string = 'Frédéric ce matin cuve n°3'
  end
  using Duke::Utils::DukeRefinements

  def test_can_refine_string_deletion
    refute_includes @string.duke_del('cuve'), 'cuve', "Couldn't delete a word from sentence"
  end

  def test_can_refine_string_matching_deletion
    refute_nil @string.matchdel(/matin/), "String Matching deletion didn't return a MatchData"
    refute_includes @string, 'matin', "Didn't delete substring on string matching deletion"
  end

  def test_can_refine_string_clearing
    refute_match(/[A-Z]|n ?°|le|la|les|-|_|é/, @string.duke_clear, 'Is still matching some useless characters')
  end

  def test_can_refine_substrings
    assert_equal 276, @string.substrings.size, 'Found correct substrings'
    assert_includes @string.substrings, [13, 'éric ce matin'], 'All substrings not correct'
  end

  def test_can_refine_words_combinations
    assert_equal 15, @string.words_combinations.size, "Didn't find correct number of words combinations"
    assert_includes @string.words_combinations, 'ce matin', "All substrings aren't found"
  end

  def test_can_refine_duke_words
    assert_includes @string.duke_words, 'Frédéric', "A duke word hasn't been found"
    assert_equal 5, @string.duke_words.size, "Didn't found all duke words"
  end

  def test_can_refine_partial_similar
    assert_in_delta 'Frédéric'.partial_similar(@string), 100, 10, "Partial similar didn't return an acceptable number"
    assert_in_delta 'Frédéric'.partial_similar(@string.words_combinations), 100, 10,
                    "Partial similar didn't return an acceptable number"
  end
end
