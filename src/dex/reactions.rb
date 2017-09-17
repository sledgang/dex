# Helper methods for abusing reactions :'(
module Reactions
  RATE_LIMIT = 0.25

  # Manually issues a reaction request
  def react(message, reaction)
    channel_id = message.channel.id
    message_id = message.id
    encoded_reaction = URI.encode(reaction)

    RestClient.put(
      "#{Discordrb::API.api_base}/channels/#{channel_id}/messages/#{message_id}/reactions/#{encoded_reaction}/@me",
      nil,
      Authorization: bot.token
    )
  end

  # Applies multiple reactions at the given `RATE_LIMIT`
  def spam_reactions(message, *reactions)
    reactions.each { |r| react(message, r) ; sleep RATE_LIMIT }
  end
end
