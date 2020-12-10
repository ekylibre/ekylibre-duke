class DukeExportMessageJob < ApplicationJob
  queue_as :duke

  def perform(item_id, session_id)
    ActionCable.server.broadcast 'duke',
      message: [{"response_type":"text","text": I18n.t("duke.exports.export_over" , id: item_id)}],
      room_id: session_id
  end
end
