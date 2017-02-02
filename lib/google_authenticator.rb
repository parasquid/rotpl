require_relative "hotp"

module Rotpl
  class GoogleAuthenticator < Totp
    def initialize(secret, hotp: Hotp, time_step: 30)
      super
      @secret = Base32.decode(@secret.delete(" ").upcase)
    end
  end
end