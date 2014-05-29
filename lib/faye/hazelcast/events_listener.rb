class Faye::Hazelcast::EventsListener
  include com.hazelcast.core.MessageListener

  def initialize(engine)
    @engine = engine
  end

  def onMessage(event)
    type, client_id = event.getMessageObject().split(':')
    case type
    when 'message'
      @engine.empty_queue(client_id)
    when 'disconnect'
      @engine.server.trigger(:close, client_id)
    else
      @engine.server.debug 'Unknown event ?', type
    end
  end
end
