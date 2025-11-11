require_relative "hotp"
require_relative "totp"

module Rotpl
  # Google Authenticator compatible TOTP implementation.
  #
  # This class extends TOTP to support Base32-encoded secrets typically
  # provided by Google Authenticator QR codes and provisioning URLs.
  #
  # Google Authenticator uses:
  # - Base32-encoded secrets (case-insensitive, spaces allowed)
  # - 30-second time windows
  # - 6-digit codes
  # - HMAC-SHA1 algorithm
  #
  # @example Using a Google Authenticator secret
  #   # Secret from Google Authenticator QR code
  #   secret = "JBSWY3DPEHPK3PXP"
  #   ga = Rotpl::GoogleAuthenticator.new(secret)
  #   codes = ga.generate_otp
  #   current_code = codes[1]  # Middle code is the current time window
  #
  # @example With spaces in secret (spaces are automatically removed)
  #   secret = "JBSW Y3DP EHPK 3PXP"
  #   ga = Rotpl::GoogleAuthenticator.new(secret)
  #
  # @example Verifying user input
  #   ga = Rotpl::GoogleAuthenticator.new("JBSWY3DPEHPK3PXP")
  #   user_code = "123456"
  #   valid = ga.generate_otp.include?(user_code)
  #
  # @see https://github.com/google/google-authenticator Google Authenticator
  class GoogleAuthenticator < Totp
    # Initialize a new Google Authenticator compatible TOTP instance.
    #
    # The secret is automatically Base32-decoded. Spaces are removed and
    # the string is converted to uppercase before decoding.
    #
    # @param secret [String] Base32-encoded secret (from QR code or provisioning URL)
    # @param hotp [Class] The HOTP class to use (default: Rotpl::Hotp)
    # @param time_step [Integer] Time window in seconds (default: 30)
    #
    # @example
    #   ga = Rotpl::GoogleAuthenticator.new("JBSWY3DPEHPK3PXP")
    #
    # @example Secret with spaces
    #   ga = Rotpl::GoogleAuthenticator.new("JBSW Y3DP EHPK 3PXP")
    def initialize(secret, hotp: Hotp, time_step: 30)
      super
      @secret = Base32.decode(@secret.delete(" ").upcase)
    end
  end
end