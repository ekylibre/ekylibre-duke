class DukeExportMessageJob < ApplicationJob
  include Pusher
  queue_as :duke

  def perform(item_id, session_id)
    I18n.locale = :fra
    # HOTFIX: doing it only once because watson fires two webhooks at the time of writing
    # TODO : Stop Watson from sending two webhooks for a single event
    if item_id.even?
      Pusher.trigger(session_id, 'my-event', {
        message: [{"response_type":"text","text": I18n.t("duke.exports.export_over" , id: item_id)}]
      })
    end 
  end
end
