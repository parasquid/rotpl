require_relative "hotp"

module Rotpl
  class Totp
    def initialize(secret, hotp: Hotp)
      @secret = secret
      @hotp = hotp
    end

    def generate_otp(time = Time.now.to_i, code_digits: 6)
      @hotp.generate_otp(@secret, time.to_i, code_digits: code_digits)
    end
  end
end