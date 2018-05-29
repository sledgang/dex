require "discordcr"
require "yaml"

module Dex
  struct Config
    YAML.mapping(
      token: String,
      channels: Array(UInt64))
  end

  # Configure Discord client
  {% begin %}
    class_getter config = Config.from_yaml(File.read("config.yml"))
    class_getter client = Discord::Client.new(config.token)
    class_getter ipc_channels = [] of Channel(Discord::Message)
  {% end %}

  client.on_message_create do |payload|
    next unless config.channels.includes?(payload.channel_id)
    ipc_channels.each do |channel|
      channel.send(payload)
    end
  end

  # Run client in another fiber
  spawn do
    client.run
  end

  # Set up and handle IPC connection
  server = UNIXServer.new("/tmp/dex.sock")
  at_exit { server.close }

  def self.handle_peer(peer, channel = Channel(Discord::Message).new)
    ipc_channels << channel
    loop do
      message = channel.receive
      json = message.to_json
      peer.write_bytes(json.bytesize, IO::ByteFormat::SystemEndian)
      peer.print(json)
    end
  rescue ex : Errno
    ipc_channels.delete(channel)
    Discord::LOGGER.warn("IPC Peer exception: #{ex.inspect}")
  end

  # Connection loop
  while peer = server.accept?
    Discord::LOGGER.info("IPC Peer connected")
    spawn handle_peer(peer)
  end
end
