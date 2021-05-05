# frozen_string_literal: true

require 'test_helper'
class BaseDukeTest < Minitest::Test
  include Duke::BaseDuke
  def setup
    @json = optJsonify(:tractor, '3')
    @label_json = optJsonify(:tractor)
    @option = dynamic_options(:title, [], :description).first
    @text = dynamic_text(:sentence).first
  end

  def test_its_a_number
    assert number?('3'), '3 is a number'
    assert number?('4.3'), '4.3 is a number'
    refute number?('4,3'), '4,3 is not a number'
  end

  def test_it_create_dynamic_options
    assert_equal :description, @option[:description], 'Incorrect description for dynamic option'
    assert_equal :option, @option[:response_type].to_sym, 'Incorrect response type for dynamic option'
    assert_equal :title, @option[:title], 'Incorrect title for dynamic option'
    assert_empty @option[:options], 'Dynamic options should be empty'
  end

  def test_it_create_option_from_label
    assert_equal :tractor, @label_json[:label], 'Incorrect label for dynamic option'
    assert_equal :tractor, @json[:label], 'Incorrect label for dynamic option'
    assert_equal 3.to_s, @json[:value][:input][:text], 'Incorrect text value for dynamic option'
  end

  def test_it_creates_dynamic_text
    assert_equal :text, @text[:response_type].to_sym, 'Incorrect response_type for dynamic text'
    assert_equal :sentence, @text[:text], 'Incorrect text for dynamic text'
  end
end
