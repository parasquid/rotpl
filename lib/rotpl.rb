# frozen_string_literal: true

require_relative "rotpl/version"
require_relative "rotpl/hotp"
require_relative "rotpl/totp"
require_relative "rotpl/google_authenticator"

# ROTPL - Ruby OTP-Two-Factor-authentication Library
#
# A Ruby implementation of HMAC-based One-Time Password (HOTP) and
# Time-based One-Time Password (TOTP) algorithms, fully compatible
# with Google Authenticator.
#
# @see https://tools.ietf.org/html/rfc4226 RFC 4226 (HOTP)
# @see https://tools.ietf.org/html/rfc6238 RFC 6238 (TOTP)
module Rotpl
end
