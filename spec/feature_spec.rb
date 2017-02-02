require "spec_helper"
require_relative "../lib/hotp"

describe Rotpl::Hotp do
  Given(:klass) { Rotpl::Hotp }
  Given(:secret) { "12345678901234567890" }

  describe "hmac_sha1" do
    When(:result) { klass.hmac_sha1(secret, count) }

    context "count 0" do
      Given(:count) { 0 }
      Then { result == "cc93cf18508d94934c64b65d8ba7667fb7cde4b0" }
    end

    context "count 1" do
      Given(:count) { 1 }
      Then { result == "75a48a19d4cbe100644e8ac1397eea747a2d33ab" }
    end

    context "count 2" do
      Given(:count) { 2 }
      Then { result == "0bacb7fa082fef30782211938bc1c5e70416ff44" }
    end

    context "count 3" do
      Given(:count) { 3 }
      Then { result == "66c28227d03a2d5529262ff016a1e6ef76557ece" }
    end

    context "count 4" do
      Given(:count) { 4 }
      Then { result == "a904c900a64b35909874b33e61c5938a8e15ed1c" }
    end

    context "count 5" do
      Given(:count) { 5 }
      Then { result == "a37e783d7b7233c083d4f62926c7a25f238d0316" }
    end

    context "count 6" do
      Given(:count) { 6 }
      Then { result == "bc9cd28561042c83f219324d3c607256c03272ae" }
    end

    context "count 7" do
      Given(:count) { 7 }
      Then { result == "a4fb960c0bc06e1eabb804e5b397cdc4b45596fa" }
    end

    context "count 8" do
      Given(:count) { 8 }
      Then { result == "1b3c89f65e6c9e883012052823443f048b4332db" }
    end

    context "count 9" do
      Given(:count) { 9 }
      Then { result == "1637409809a679dc698207310c8c7fc07290d9e5" }
    end
  end

  describe "generate_otp" do
    Given(:code_digits) { 6 }
    Given(:add_checksum) { false }
    Given(:truncation_offfset) { nil }

    context "all hotp" do
      Given(:moving_factors) { [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] }
      Given(:reference_otps) { [755224, 287082, 359152, 969429, 338314, 254676, 287922, 162583, 399871, 520489] }
      Given(:moving_factor) { }
      Then {
        (0..9).each { |count|
          moving_factor = count
          hotp = klass.generate_otp(
            secret,
            moving_factor,
            code_digits,
            add_checksum,
            truncation_offfset
          )

          expect(hotp).to eq(reference_otps[count])
        }
      }
    end
  end
end