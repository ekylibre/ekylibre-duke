# frozen_string_literal: true

class DukeChannel < ApplicationCable::Channel
  def subscribed
    puts "On the subscribe method, about to stream from duke_#{params[:roomId]}"
    stream_from "duke_#{params[:roomId]}"
  end
end
