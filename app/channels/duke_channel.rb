class DukeChannel < ApplicationCable::Channel
  def subscribed
    stream_from "duke_#{params[:roomId]}"
  end
end
