require_relative "hotp"
require "base32"

module Rotpl
  # TOTP (Time-based One-Time Password) implementation per RFC 6238.
  #
  # TOTP extends HOTP by using the current time as the moving factor.
  # This generates time-sensitive passwords that change every 30 seconds
  # (by default).
  #
  # To handle clock skew between client and server, this implementation
  # generates 3 codes: one for the current time window, one for the previous
  # window, and one for the next window.
  #
  # @example Basic usage
  #   secret = "12345678901234567890"
  #   totp = Rotpl::Totp.new(secret)
  #   codes = totp.generate_otp  # => ["287082", "359152", "969429"]
  #   # Check if user's code matches any of the three valid codes
  #
  # @example Custom time step
  #   totp = Rotpl::Totp.new(secret, time_step: 60)  # 60-second windows
  #
  # @see https://tools.ietf.org/html/rfc6238 RFC 6238
  class Totp
    # Initialize a new TOTP instance.
    #
    # @param secret [String] The shared secret key (byte string)
    # @param hotp [Class] The HOTP class to use (default: Rotpl::Hotp)
    # @param time_step [Integer] Time window in seconds (default: 30)
    #
    # @example
    #   totp = Rotpl::Totp.new("my_secret_key")
    #
    # @example With custom time step
    #   totp = Rotpl::Totp.new("my_secret_key", time_step: 60)
    def initialize(secret, hotp: Hotp, time_step: 30)
      @secret = secret
      @hotp = hotp
      @time_step = time_step
    end

    # Generate time-based one-time passwords.
    #
    # Returns an array of 3 OTP codes to handle clock skew:
    # - codes[0]: Previous time window
    # - codes[1]: Current time window
    # - codes[2]: Next time window
    #
    # @param time [Time, Integer] The time to use (default: Time.now)
    # @param code_digits [Integer] Number of digits in each OTP (default: 6)
    #
    # @return [Array<String>] Array of 3 OTP codes
    #
    # @example Generate codes for current time
    #   totp = Rotpl::Totp.new("secret")
    #   codes = totp.generate_otp
    #   # => ["287082", "359152", "969429"]
    #
    # @example Generate codes for specific time
    #   time = Time.at(59)
    #   codes = totp.generate_otp(time)
    #
    # @example Generate 8-digit codes
    #   codes = totp.generate_otp(code_digits: 8)
    def generate_otp(time = Time.now, code_digits: 6)
      time = time.to_i
      moving_factor = (time / @time_step).floor
      [-1, 0, 1].map { |offset|
        @hotp.generate_otp(@secret, moving_factor + offset, code_digits: code_digits)
      }
    end
  end
end