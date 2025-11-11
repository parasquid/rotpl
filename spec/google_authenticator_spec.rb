require "spec_helper"
require "rotpl"

describe Rotpl::GoogleAuthenticator do
  let(:base32_secret) { "JBSWY3DPEHPK3PXP" }
  let(:ga) { Rotpl::GoogleAuthenticator.new(base32_secret) }

  describe "#initialize" do
    it "creates a GoogleAuthenticator instance with Base32 secret" do
      expect(ga).to be_a(Rotpl::GoogleAuthenticator)
    end

    it "is a subclass of Totp" do
      expect(ga).to be_a(Rotpl::Totp)
    end

    it "handles secrets with spaces" do
      secret_with_spaces = "JBSW Y3DP EHPK 3PXP"
      ga_with_spaces = Rotpl::GoogleAuthenticator.new(secret_with_spaces)

      codes1 = ga.generate_otp(Time.at(59))
      codes2 = ga_with_spaces.generate_otp(Time.at(59))

      expect(codes1).to eq(codes2)
    end

    it "handles lowercase Base32 secrets" do
      lowercase_secret = base32_secret.downcase
      ga_lowercase = Rotpl::GoogleAuthenticator.new(lowercase_secret)

      codes1 = ga.generate_otp(Time.at(59))
      codes2 = ga_lowercase.generate_otp(Time.at(59))

      expect(codes1).to eq(codes2)
    end

    it "handles mixed case Base32 secrets with spaces" do
      mixed_secret = "jbsw Y3Dp EhPk 3pXp"
      ga_mixed = Rotpl::GoogleAuthenticator.new(mixed_secret)

      codes1 = ga.generate_otp(Time.at(59))
      codes2 = ga_mixed.generate_otp(Time.at(59))

      expect(codes1).to eq(codes2)
    end

    it "accepts custom time_step" do
      ga_custom = Rotpl::GoogleAuthenticator.new(base32_secret, time_step: 60)
      expect(ga_custom).to be_a(Rotpl::GoogleAuthenticator)
    end
  end

  describe "#generate_otp" do
    it "generates an array of 3 codes" do
      codes = ga.generate_otp
      expect(codes).to be_an(Array)
      expect(codes.length).to eq(3)
    end

    it "generates 6-digit codes by default" do
      codes = ga.generate_otp
      expect(codes.all? { |c| c.length == 6 }).to be true
      expect(codes.all? { |c| c =~ /^\d{6}$/ }).to be true
    end

    it "generates 8-digit codes when specified" do
      codes = ga.generate_otp(code_digits: 8)
      expect(codes.all? { |c| c.length == 8 }).to be true
      expect(codes.all? { |c| c =~ /^\d{8}$/ }).to be true
    end

    it "generates consistent codes for the same time" do
      time = Time.at(1234567890)
      codes1 = ga.generate_otp(time)
      codes2 = ga.generate_otp(time)

      expect(codes1).to eq(codes2)
    end

    it "generates different codes for different times" do
      time1 = Time.at(1234567890)
      time2 = Time.at(1234567890 + 30)

      codes1 = ga.generate_otp(time1)
      codes2 = ga.generate_otp(time2)

      # Current code at time1 should be different from current code at time2
      expect(codes1[1]).not_to eq(codes2[1])
    end

    it "provides clock skew tolerance" do
      time = Time.at(1234567890)
      codes = ga.generate_otp(time)

      # Should have previous, current, and next window codes
      expect(codes[0]).not_to eq(codes[1])
      expect(codes[1]).not_to eq(codes[2])
      expect(codes[0]).not_to eq(codes[2])
    end
  end

  describe "typical use case: two-factor authentication" do
    let(:user_secret) { "JBSWY3DPEHPK3PXP" }
    let(:authenticator) { Rotpl::GoogleAuthenticator.new(user_secret) }

    it "can verify user input during login" do
      # Generate valid codes
      valid_codes = authenticator.generate_otp

      # Simulate user entering the current code
      user_input = valid_codes[1]

      # Verify the code
      expect(valid_codes).to include(user_input)
    end

    it "accepts codes from adjacent time windows" do
      time = Time.now
      valid_codes = authenticator.generate_otp(time)

      # All three codes should be considered valid
      # (previous, current, and next time window)
      expect(valid_codes.length).to eq(3)
      valid_codes.each do |code|
        expect(valid_codes).to include(code)
      end
    end

    it "rejects invalid codes" do
      valid_codes = authenticator.generate_otp
      invalid_code = "000000"

      expect(valid_codes).not_to include(invalid_code)
    end
  end

  describe "compatibility with Google Authenticator format" do
    it "works with standard Google Authenticator Base32 secrets" do
      # Common Base32 secret format from Google Authenticator
      secrets = [
        "JBSWY3DPEHPK3PXP",
        "HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ",
        "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
      ]

      secrets.each do |secret|
        ga = Rotpl::GoogleAuthenticator.new(secret)
        codes = ga.generate_otp

        expect(codes).to be_an(Array)
        expect(codes.length).to eq(3)
        expect(codes.all? { |c| c =~ /^\d{6}$/ }).to be true
      end
    end
  end
end
