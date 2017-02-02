module Rotpl
  class Hotp

    def initialize(secret, digest_factory: OpenSSL::Digest.new('sha1'))
      @secret = secret
      @digest_factory = digest_factory
    end

    def hmac(data)
      # text byte array and left pad with 0 bytes for blocksize 8
      left_padded_data = [data].pack("N").rjust(8, 0.chr)
      OpenSSL::HMAC.hexdigest(@digest_factory, @secret, left_padded_data)
    end

    def self.hmac_sha1(secret, count)
      self.new(secret).hmac(count)
    end

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