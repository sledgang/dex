# frozen_string_literal: true

# ( ͠° ͜ʖ °)
module Dex
  module Lenny
    extend self

    LENNYS = [
      "( ͡° ͜ʖ ͡°)",
      "( ✧≖ ͜ʖ≖)",
      "(͡ ͡° ͜ つ ͡͡°)",
      "( ͠° ͜ʖ °)",
      "( ͡°( ͡° ͜ʖ( ͡° ͜ʖ ͡°)ʖ ͡°) ͡°)",
    ].freeze

    # ( ͠° ͜ʖ °)
    def get
      LENNYS.sample
    end
  end
end
