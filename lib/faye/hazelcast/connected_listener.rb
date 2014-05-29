class Faye::Hazelcast::ConnectedListener
  include com.hazelcast.core.EntryListener

  def initialize(engine)
    @engine = engine
  end

  def entryEvicted(event)
    @engine.destroy_client(event.key)
  end

  def entryAdded(event); end

  def entryRemoved(event); end

  def entryUpdated(event); end
end
