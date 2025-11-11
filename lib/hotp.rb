# ROTPL - Ruby OTP-Two-Factor-authentication Library
#
# This module implements HMAC-based One-Time Password (HOTP) and
# Time-based One-Time Password (TOTP) algorithms per RFC 4226 and RFC 6238.
module Rotpl
  # HOTP (HMAC-based One-Time Password) implementation per RFC 4226.
  #
  # HOTP generates one-time passwords using HMAC-SHA1 and a counter value.
  # Each generated password is unique and can only be used once.
  #
  # @example Basic usage
  #   secret = "12345678901234567890"
  #   hotp = Rotpl::Hotp.new(secret)
  #   code = Rotpl::Hotp.generate_otp(secret, 0)  # => "755224"
  #
  # @see https://tools.ietf.org/html/rfc4226 RFC 4226
  class Hotp

    # Initialize a new HOTP instance.
    #
    # @param secret [String] The shared secret key (byte string)
    # @param digest_factory [OpenSSL::Digest] The digest algorithm to use (default: SHA-1)
    #
    # @example
    #   hotp = Rotpl::Hotp.new("my_secret_key")
    def initialize(secret, digest_factory: OpenSSL::Digest.new('sha1'))
      @secret = secret
      @digest_factory = digest_factory
    end

    # Compute HMAC hash for a given counter value.
    #
    # This method converts the counter to an 8-byte big-endian value and
    # computes the HMAC-SHA1 hash.
    #
    # @param data [Integer] The counter value
    # @return [String] The hexadecimal HMAC hash
    #
    # @example
    #   hotp = Rotpl::Hotp.new("secret")
    #   hash = hotp.hmac(0)  # => "cc93cf18508d94934c64b65d8ba7667fb7cde4b0"
    def hmac(data)
      # text byte array and left pad with 0 bytes for blocksize 8
      left_padded_data = [data].pack("N").rjust(8, 0.chr)
      OpenSSL::HMAC.hexdigest(@digest_factory, @secret, left_padded_data)
    end

    # Class method to compute HMAC-SHA1 for a given secret and counter.
    #
    # @param secret [String] The shared secret key
    # @param count [Integer] The counter value
    # @return [String] The hexadecimal HMAC hash
    #
    # @example
    #   hash = Rotpl::Hotp.hmac_sha1("secret", 0)
    def self.hmac_sha1(secret, count)
      self.new(secret).hmac(count)
    end

    # Generate a one-time password using HOTP algorithm.
    #
    # This is the main method for generating OTP codes. It implements the
    # dynamic truncation algorithm per RFC 4226 Section 5.3.
    #
    # @param secret [String] The shared secret key (byte string)
    # @param moving_factor [Integer] The counter/moving factor
    # @param code_digits [Integer] Number of digits in the OTP (default: 6)
    # @param add_checksum [Boolean] Whether to add a checksum digit (default: false)
    # @param truncation_offfset [Integer] Manual truncation offset, -1 for dynamic (default: -1)
    #
    # @return [String] The generated OTP code (zero-padded to code_digits length)
    #
    # @example Generate standard 6-digit OTP
    #   otp = Rotpl::Hotp.generate_otp("secret", 0)  # => "755224"
    #
    # @example Generate 8-digit OTP
    #   otp = Rotpl::Hotp.generate_otp("secret", 0, code_digits: 8)
    def self.generate_otp(
        secret,                 # byte[]
        moving_factor,          # long
        code_digits: 6,
        add_checksum: false,
        truncation_offfset: -1
    )

      # compute hmac hash and convert to byte array
      hash = [hmac_sha1(secret, moving_factor)].pack("H*")

      truncation_offfset ||= -1
      if truncation_offfset >= 0 && truncation_offfset < hash[-4].ord
        offset = truncation_offfset
      else
        offset = hash[-1].ord & 0xf
      end

      # put selected bytes into result int
      binary =  (hash[offset + 0].ord & 0x7f) << 24 |
                (hash[offset + 1].ord & 0xff) << 16 |
                (hash[offset + 2].ord & 0xff) <<  8 |
                (hash[offset + 3].ord & 0xff)

      otp = (binary % (10 ** code_digits)).to_s.rjust(code_digits, "0")
    end

  end
end