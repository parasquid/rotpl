require_relative "hotp"
require "base32"

module Rotpl
  class Totp
    def initialize(secret, hotp: Hotp, time_step: 30)
      @secret = secret
      @hotp = hotp
      @time_step = time_step
    end

    def generate_otp(time = Time.now, code_digits: 6)
      time = time.to_i
      moving_factor = (time / @time_step).floor
      [-1, 0, 1].map { |offset|
        @hotp.generate_otp(@secret, moving_factor + offset, code_digits: code_digits)
      }
    end
  end
end