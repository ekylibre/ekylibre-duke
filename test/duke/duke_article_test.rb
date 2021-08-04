require 'test_helper'
class DukeArticleTest < Minitest::Test
  def setup
    @article = Duke::Skill::DukeArticle.new(user_input: 'Enregistre un labour ce matin')
    @time_article = Duke::Skill::DukeArticle.new(user_input: 'Labour à 8h30 pendant 3h30')
    @time_article_bis = Duke::Skill::DukeArticle.new(user_input: 'Labour hier à 14h30')
    @num_article = Duke::Skill::DukeArticle.new(user_input: "4,5 degrés d'alcool")
  end

  def test_can_create_combos
    assert_equal 14, @article.send(:create_words_combo).size, 'Number of combos created is incorrect'
    assert_includes @article.send(:create_words_combo).to_a, [[2, 3, 4], 'labour ce matin'],
                    "Combo dosn't include one it should"
    assert_includes @article.send(:create_words_combo).keys, [0], 'Combo keys incorrectly created'
  end

  def test_can_be_converted_to_json
    assert_includes @article.duke_json.keys, :date.to_s, 'Duke json should have "date" key'
    refute_includes @article.duke_json(:user_input).keys, :date.to_s, 'Duke json should have "date" key'
  end

  def test_can_be_recovered_from_json
    assert_equal @article, @article.recover_from_hash(@article.duke_json), 'Article not create properly from json'
  end

  def test_can_update_description
    @article.update_description('420')
    assert_includes @article.description, '420', 'Description not update properly'
  end

  def test_can_convert_string_to_year
    assert_equal 2019, @article.send(:year_from_str, 19), 'Wrong year extraction'
    assert_equal 2018, @article.send(:year_from_str, '2018'), 'Wrong year extraction'
    assert_equal Time.now.year, @article.send(:year_from_str, ''), 'Wrong year extraction'
  end

  def test_can_parse_date_and_duration
    @time_article.extract_date
    @time_article.send(:extract_duration)
    assert_equal Time.now.change(hour: 8, min: 30, offset: @time_article.send(:offset)), @time_article.date,
                 'Wrong date parsed'
    assert_equal 210, @time_article.duration, 'Wrong duration parsed'
  end

  def test_can_parse_date_and_set_base_duration
    @time_article_bis.extract_date
    @time_article_bis.send(:extract_duration)
    assert_equal 1.day.ago.change(hour: 14, min: 30, offset: @time_article_bis.send(:offset)), @time_article_bis.date,
                 'Wrong date parsed'
    assert_nil @time_article_bis.duration, "Duration isn't nil when specific hour is parsed"
  end

  def test_can_extract_number_parameter
    assert_equal 4.5.to_s, @num_article.send(:extract_number_parameter, nil),
                 "Didn't extract correct number from string"
    assert_equal 4.5.to_s, @num_article.send(:extract_number_parameter, 4), "Didn't extract correct number from string"
    assert_equal 2.to_s, @num_article.send(:extract_number_parameter, 2), "Didn't extract correct number from string"
  end
end
