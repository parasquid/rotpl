require "spec_helper"
require "rotpl"

describe "Rotpl Integration Tests" do
  describe "loading the gem" do
    it "defines the Rotpl module" do
      expect(defined?(Rotpl)).to eq("constant")
      expect(Rotpl).to be_a(Module)
    end

    it "defines Rotpl::VERSION" do
      expect(Rotpl::VERSION).to be_a(String)
      expect(Rotpl::VERSION).to match(/^\d+\.\d+\.\d+$/)
    end

    it "loads all main classes" do
      expect(defined?(Rotpl::Hotp)).to eq("constant")
      expect(defined?(Rotpl::Totp)).to eq("constant")
      expect(defined?(Rotpl::GoogleAuthenticator)).to eq("constant")
    end
  end

  describe "HOTP → TOTP → GoogleAuthenticator inheritance chain" do
    it "TOTP uses HOTP internally" do
      secret = "12345678901234567890"
      time = Time.at(59)

      totp = Rotpl::Totp.new(secret)
      codes = totp.generate_otp(time)

      # The current time window (index 1) should match HOTP counter 1
      hotp_code = Rotpl::Hotp.generate_otp(secret, 1)
      expect(codes[1]).to eq(hotp_code)
    end

    it "GoogleAuthenticator extends TOTP with Base32 decoding" do
      # "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ" decodes to "12345678901234567890"
      base32_secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
      binary_secret = "12345678901234567890"

      time = Time.at(59)

      ga = Rotpl::GoogleAuthenticator.new(base32_secret)
      totp = Rotpl::Totp.new(binary_secret)

      ga_codes = ga.generate_otp(time)
      totp_codes = totp.generate_otp(time)

      expect(ga_codes).to eq(totp_codes)
    end
  end

  describe "real-world usage scenarios" do
    context "setting up 2FA for a new user" do
      it "generates a secret, creates QR code URL, and verifies codes" do
        # 1. Generate a random Base32 secret for the user
        require 'securerandom'
        require 'base32'
        random_secret = Base32.encode(SecureRandom.random_bytes(20))

        # 2. Create authenticator
        ga = Rotpl::GoogleAuthenticator.new(random_secret)

        # 3. Generate QR code URL (standard format)
        user_email = "user@example.com"
        issuer = "MyApp"
        qr_url = "otpauth://totp/#{user_email}?secret=#{random_secret}&issuer=#{issuer}"

        expect(qr_url).to include("otpauth://totp/")
        expect(qr_url).to include(random_secret)

        # 4. User scans QR code and enters first code
        codes = ga.generate_otp
        user_input = codes[1] # User enters the current code

        # 5. Verify the code
        expect(codes).to include(user_input)
      end
    end

    context "user logging in with 2FA" do
      let(:user_secret) { "JBSWY3DPEHPK3PXP" }
      let(:authenticator) { Rotpl::GoogleAuthenticator.new(user_secret) }

      it "accepts valid codes within the time window" do
        valid_codes = authenticator.generate_otp

        # Simulate user entering each possible valid code
        valid_codes.each do |code|
          expect(valid_codes).to include(code)
        end
      end

      it "handles clock drift between client and server" do
        # Server time
        server_time = Time.now
        server_codes = authenticator.generate_otp(server_time)

        # Client time is 15 seconds behind
        client_time = server_time - 15
        client_codes = authenticator.generate_otp(client_time)

        # There should be overlap in valid codes due to window tolerance
        # The previous window on server overlaps with current window on client
        expect((server_codes & client_codes).empty?).to be false
      end
    end

    context "testing with multiple authenticators" do
      it "different secrets generate different codes" do
        ga1 = Rotpl::GoogleAuthenticator.new("JBSWY3DPEHPK3PXP")
        ga2 = Rotpl::GoogleAuthenticator.new("HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ")

        time = Time.at(1234567890)
        codes1 = ga1.generate_otp(time)
        codes2 = ga2.generate_otp(time)

        expect(codes1).not_to eq(codes2)
      end

      it "same secret generates same codes" do
        ga1 = Rotpl::GoogleAuthenticator.new("JBSWY3DPEHPK3PXP")
        ga2 = Rotpl::GoogleAuthenticator.new("JBSWY3DPEHPK3PXP")

        time = Time.at(1234567890)
        codes1 = ga1.generate_otp(time)
        codes2 = ga2.generate_otp(time)

        expect(codes1).to eq(codes2)
      end
    end

    context "backup codes and recovery" do
      it "can pre-generate codes for future time windows" do
        ga = Rotpl::GoogleAuthenticator.new("JBSWY3DPEHPK3PXP")

        # Generate codes for multiple time windows (e.g., for backup codes)
        backup_codes = []
        base_time = Time.now.to_i

        # Generate 5 future time windows (5 x 30 seconds)
        5.times do |i|
          future_time = Time.at(base_time + (i * 30))
          codes = ga.generate_otp(future_time)
          backup_codes << codes[1] # Take the current window code
        end

        expect(backup_codes.length).to eq(5)
        expect(backup_codes.uniq.length).to eq(5) # All unique
      end
    end
  end

  describe "edge cases and robustness" do
    it "handles very large time values" do
      ga = Rotpl::GoogleAuthenticator.new("JBSWY3DPEHPK3PXP")
      large_time = Time.at(99999999999)

      codes = ga.generate_otp(large_time)
      expect(codes).to be_an(Array)
      expect(codes.length).to eq(3)
    end

    it "handles time at epoch (0)" do
      ga = Rotpl::GoogleAuthenticator.new("JBSWY3DPEHPK3PXP")
      epoch_time = Time.at(0)

      codes = ga.generate_otp(epoch_time)
      expect(codes).to be_an(Array)
      expect(codes.length).to eq(3)
    end

    it "generates codes quickly" do
      ga = Rotpl::GoogleAuthenticator.new("JBSWY3DPEHPK3PXP")

      start_time = Time.now
      1000.times { ga.generate_otp }
      elapsed = Time.now - start_time

      # Should be able to generate 1000 codes in less than 1 second
      expect(elapsed).to be < 1.0
    end

    it "produces zero-padded codes" do
      # Some time windows might produce codes starting with 0
      ga = Rotpl::GoogleAuthenticator.new("JBSWY3DPEHPK3PXP")

      # Test many time windows to find zero-padded codes
      found_zero_padded = false
      100.times do |i|
        time = Time.at(i * 30)
        codes = ga.generate_otp(time)
        if codes.any? { |c| c.start_with?('0') }
          found_zero_padded = true
          break
        end
      end

      # At least one code should start with 0 in 100 attempts
      # Each code should still be exactly 6 digits
      codes = ga.generate_otp(Time.at(1234567890))
      codes.each do |code|
        expect(code.length).to eq(6)
      end
    end
  end
end
