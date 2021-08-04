# frozen_string_literal: true

require 'test_helper'
class DukeInterventionTest < Minitest::Test
  def setup
    mock_event = Minitest::Mock.new
    @intervention = Duke::Skill::DukeIntervention.new(user_input: 'Enregistre un labour ce matin pendant 3h30',
                                               procedure: 'plowing')
    @day_intervention = Duke::Skill::DukeIntervention.new(user_input: 'Taille de formation', procedure: 'vine_pruning')
    mock_event.expect :parsed, @day_intervention.duke_json
    @interval_intervention = Duke::Skill::Interventions::ComplementWorkingPeriods.new(mock_event)
  end

  def test_can_extract_date_and_duration
    @intervention.extract_date_and_duration
    assert_equal Time.now.change(hour: 8, min: 0o0, offset: @intervention.send(:offset)), @intervention.date,
                 'Incorrect date parsing'
    assert_equal 210, @intervention.duration, 'Incorrect duration parsing'
  end

  def test_can_extract_working_period_from_interval
    @intervention.send(:extract_wp_from_interval, 'entre 15h et 19h')
    assert_includes @intervention.working_periods,
                    {
                      started_at: Time.now.change(hour: 15, min: 0, offset: @intervention.send(:offset)),
                      stopped_at: Time.now.change(hour: 19, min: 0, offset: @intervention.send(:offset))
                    },
                    'Should extract a working period from this interval'
  end

  def test_can_add_working_interval
    @interval_intervention.extract_date_and_duration
    @interval_intervention.send(:add_working_interval,
                                [
                                  {
                                    started_at: Time.now.change(hour: 15),
                                    stopped_at: Time.now.change(hour: 19)
                                  }
                                ])
    assert_equal 2, @interval_intervention.working_periods.size, "Adds workings periods when it shouldn't"
    @interval_intervention.send(:add_working_interval,
                                [
                                  {
                                    started_at: Time.now.change(hour: 3),
                                    stopped_at: Time.now.change(hour: 5)
                                  }
                                ])
    assert_equal 3, @interval_intervention.working_periods.size, "Can't add a working_periods interval"
  end

  def test_can_update_retries
    @day_intervention.extract_number_parameter(nil)
    assert_equal 1, @day_intervention.send(:retry), "Can't update the retry level"
    @intervention.extract_number_parameter(nil)
    assert_equal 0, @intervention.send(:retry), "Update retry level when it shouldn't"
  end

  def test_can_detect_current_time
    refute @day_intervention.not_current_time?, "It is current time, yet it believes it isn't. Dumb Duke!"
    @intervention.extract_date_and_duration
    assert @intervention.not_current_time?, 'It should not be current time'
  end
end
