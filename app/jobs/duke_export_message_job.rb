class DukeExportMessageJob < ApplicationJob
  include Pusher
  queue_as :duke

  def perform(item_id, session_id)
    I18n.locale = :fra
    Pusher.trigger(session_id, 'duke', {
      message: [{"response_type":"text","text": I18n.t("duke.exports.export_over" , id: item_id)}]
    })
  end
end
