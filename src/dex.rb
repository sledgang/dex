require 'pry'
require_relative 'dex/bot'
require_relative 'dex/docs'
require_relative 'dex/lenny'

module Dex
  extend Bot
  extend Docs
  extend Lenny

  Discordrb::LOGGER.info 'Loading docs..'
  YARD.parse('vendor/bundle/ruby/*/bundler/gems/discordrb-*/**/*.rb')
  YARD::Registry.save(false, 'discordrb')

  # Recall docs into chat
  bot.message(start_with: 'dex.doc', in: config.channels) do |event|
    path = event.message.content[7..-1].strip
    Discordrb::LOGGER.info("[#{event.channel.name} | #{event.user.distinct}] Lookup: #{path}")

    next event.respond(lenny) if path.empty?

    begin
      object = lookup(path)

      next event.respond(lenny) unless object
      Discordrb::LOGGER.info("Found: #{object.inspect}")

      event.respond <<~DOC
      **#{path}**
      #{object.docstring}
      DOC
    rescue Docs::LookupFail => ex
      Discordrb::LOGGER.info("Error: #{ex.message}")
      event.respond "#{ex.message} #{lenny}"
    end
  end

  bot.run(:async)
  binding.pry if ARGV[0] == 'pry'
  bot.sync
end
