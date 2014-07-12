require 'faye'

$CLASSPATH << File.expand_path('../../../vendor/hazelcast-3.2.1.jar', __FILE__)

module Faye
  class Hazelcast; end
end

require 'faye/hazelcast/connected_listener'
require 'faye/hazelcast/events_listener'

class Faye::Hazelcast
  attr_reader :server

  # @todo: remove these readers
  attr_reader :hazel, :connected, :subscriptions, :messages, :channels, :events

  def self.create(server, options)
    new(server, options)
  end

  def initialize(server, options)
    @server, @options = server, options
    config = com.hazelcast.config.Config.new
    options.fetch(:hazelcast, {}).each do |key, value|
      config.setProperty(key, value)
    end
    @hazel = com.hazelcast.core.Hazelcast.newHazelcastInstance(config)
    at_exit { @hazel.shutdown }

    @subscriptions = @hazel.getMultiMap('faye.subscriptions')
    @messages      = @hazel.getMultiMap('faye.messages')
    @channels      = @hazel.getMultiMap('faye.channels')

    @connected = @hazel.getMap('faye.connected')
    @connected.addLocalEntryListener(ConnectedListener.new(self))

    @events = @hazel.getTopic('conversations')
    @events.addMessageListener(EventsListener.new(self))
  end

  def create_client(&callback)
    begin
      client_id = @server.generate_id
    end while @connected.containsKey(client_id)
    ping(client_id)
    @server.debug 'Created new client ?', client_id
    @server.trigger(:handshake, client_id)
    callback.call(client_id)
  end

  def destroy_client(client_id, &callback)
    @connected.delete(client_id)
    @subscriptions.remove(client_id).each do |channel|
      @channels.remove(channel, client_id)
    end
    @messages.remove(client_id)
    @server.debug 'Destroyed client ?', client_id
    @server.trigger(:disconnect, client_id)
    @events.publish("disconnect:#{client_id}")
    callback.call if callback
  end

  def client_exists(client_id, &callback)
    callback.call(@connected.containsKey(client_id))
  end

  def ping(client_id)
    timeout = @server.timeout
    timeout = 0 unless Numeric === timeout
    @server.debug 'Ping from ?', client_id
    @connected.set(
      client_id, '', timeout * 2,
      java.util.concurrent.TimeUnit::SECONDS
    )
  end

  def subscribe(client_id, channel, &callback)
    if @subscriptions.containsEntry(client_id, channel)
      callback.call(true) if callback
      return
    end
    @subscriptions.put(client_id, channel)
    @channels.put(channel, client_id)
    @server.debug 'Subscribed client ? to channel ?', client_id, channel
    @server.trigger(:subscribe, client_id, channel)
    callback.call(true) if callback
  end

  def unsubscribe(client_id, channel, &callback)
    unless @subscriptions.containsEntry(client_id, channel)
      callback.call(true) if callback
      return
    end
    @subscriptions.remove(client_id, channel)
    @channels.remove(channel, client_id)
    @server.debug 'Unsubscribed client ? from channel ?', client_id, channel
    @server.trigger(:unsubscribe, client_id, channel)
    callback.call(true)
  end

  def publish(message, channels)
    @server.debug 'Publishing message ?', message

    clients = Set.new
    channels.each do |channel|
      @channels.get(channel).each(&clients.method(:add))
    end

    clients.each do |client_id|
      @server.debug 'Queueing for client ?: ?', client_id, message
      @messages.put(client_id, MultiJson.dump(message))
      @events.publish("message:#{client_id}")
      client_exists(client_id) do |exists|
        @messages.remove(client_id) unless exists
      end
    end

    @server.trigger(
      :publish,
      *message.values_at('clientId', 'channel', 'data')
    )
  end

  def empty_queue(client_id)
    return unless @server.has_connection?(client_id)
    @server.debug 'Delivering messages to ?', client_id
    @server.deliver(
      client_id,
      @messages.remove(client_id).map(&MultiJson.method(:load))
    )
  end

  def disconnect
    @hazel.shutdown
  end
end
