require 'discordrb'
require 'yaml'
require 'ostruct'

module Bot
  def config
    @config ||= OpenStruct.new YAML.load_file('config.yml')

    raise 'invalid config' unless [
      :token,
      :channels,
      :owner
    ].map { |e| @config.respond_to?(e) }.all?

    @config
  end

  def bot
    @bot ||= Discordrb::Bot.new(token: config.token)
  end
end
