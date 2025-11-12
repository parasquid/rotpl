require "spec_helper"
require "rotpl"

describe Rotpl::Totp do
  let(:secret) { "12345678901234567890" }
  let(:totp) { Rotpl::Totp.new(secret) }

  describe "#initialize" do
    it "creates a TOTP instance with default time_step" do
      expect(totp).to be_a(Rotpl::Totp)
    end

    it "accepts custom time_step" do
      custom_totp = Rotpl::Totp.new(secret, time_step: 60)
      expect(custom_totp).to be_a(Rotpl::Totp)
    end
  end

  describe "#generate_otp" do
    context "RFC 6238 test vectors" do
      # Test vectors from RFC 6238
      # Using the secret "12345678901234567890"

      it "generates correct OTP for time 59" do
        time = Time.at(59)
        codes = totp.generate_otp(time)
        # Middle code (index 1) is for the current time window
        expect(codes[1]).to eq("287082")
      end

      it "generates correct OTP for time 1111111109" do
        time = Time.at(1111111109)
        codes = totp.generate_otp(time)
        expect(codes[1]).to eq("081804")
      end

      it "generates correct OTP for time 1111111111" do
        time = Time.at(1111111111)
        codes = totp.generate_otp(time)
        expect(codes[1]).to eq("050471")
      end

      it "generates correct OTP for time 1234567890" do
        time = Time.at(1234567890)
        codes = totp.generate_otp(time)
        expect(codes[1]).to eq("005924")
      end

      it "generates correct OTP for time 2000000000" do
        time = Time.at(2000000000)
        codes = totp.generate_otp(time)
        expect(codes[1]).to eq("279037")
      end

      it "generates correct OTP for time 20000000000" do
        time = Time.at(20000000000)
        codes = totp.generate_otp(time)
        expect(codes[1]).to eq("353130")
      end
    end

    context "clock skew tolerance" do
      let(:time) { Time.at(59) }

      it "returns an array of 3 codes" do
        codes = totp.generate_otp(time)
        expect(codes).to be_an(Array)
        expect(codes.length).to eq(3)
      end

      it "returns codes for previous, current, and next time windows" do
        codes = totp.generate_otp(time)
        expect(codes[0]).to eq("755224") # previous window (counter -1)
        expect(codes[1]).to eq("287082") # current window (counter 0)
        expect(codes[2]).to eq("359152") # next window (counter +1)
      end

      it "all codes are strings" do
        codes = totp.generate_otp(time)
        expect(codes.all? { |c| c.is_a?(String) }).to be true
      end

      it "all codes are 6 digits by default" do
        codes = totp.generate_otp(time)
        expect(codes.all? { |c| c.length == 6 }).to be true
      end
    end

    context "custom code digits" do
      let(:time) { Time.at(59) }

      it "generates 8-digit codes when specified" do
        codes = totp.generate_otp(time, code_digits: 8)
        expect(codes.all? { |c| c.length == 8 }).to be true
        expect(codes[1]).to eq("94287082")
      end

      it "generates 7-digit codes when specified" do
        codes = totp.generate_otp(time, code_digits: 7)
        expect(codes.all? { |c| c.length == 7 }).to be true
      end
    end

    context "custom time step" do
      it "generates different codes with 60-second time step" do
        totp_30 = Rotpl::Totp.new(secret, time_step: 30)
        totp_60 = Rotpl::Totp.new(secret, time_step: 60)

        time = Time.at(59)
        codes_30 = totp_30.generate_otp(time)
        codes_60 = totp_60.generate_otp(time)

        expect(codes_30[1]).not_to eq(codes_60[1])
      end
    end

    context "current time" do
      it "generates codes for current time when no time argument provided" do
        codes = totp.generate_otp
        expect(codes).to be_an(Array)
        expect(codes.length).to eq(3)
        expect(codes.all? { |c| c.length == 6 }).to be true
      end
    end
  end
end
