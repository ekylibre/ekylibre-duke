# frozen_string_literal: true

class DukeChannel < ApplicationCable::Channel
  def subscribed
    stream_from "duke_#{params[:roomId]}"
  end
end
