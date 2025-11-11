# ROTPL - Ruby OTP-Two-Factor-authentication Library

A Ruby implementation of HMAC-based One-Time Password (HOTP) and Time-based One-Time Password (TOTP) algorithms, fully compatible with Google Authenticator.

## Features

- **HOTP** - Counter-based one-time passwords per [RFC 4226](https://tools.ietf.org/html/rfc4226)
- **TOTP** - Time-based one-time passwords per [RFC 6238](https://tools.ietf.org/html/rfc6238)
- **Google Authenticator** - Full compatibility with Google Authenticator QR codes
- Clock skew tolerance (±30 seconds by default)
- Clean, testable API with dependency injection
- RFC test vector validation

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rotpl'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install rotpl
```

## Quick Start

### Google Authenticator (Most Common Use Case)

```ruby
require 'rotpl'

# Secret from Google Authenticator QR code
secret = "JBSWY3DPEHPK3PXP"
ga = Rotpl::GoogleAuthenticator.new(secret)

# Generate current codes (returns 3 codes for clock tolerance)
codes = ga.generate_otp
# => ["287082", "359152", "969429"]

# The middle code is the current time window
current_code = codes[1]

# Verify user input
user_code = "359152"
if codes.include?(user_code)
  puts "Valid code!"
end
```

### Time-based OTP (TOTP)

```ruby
require 'rotpl'

# Use a binary secret (not Base32-encoded)
secret = "12345678901234567890"
totp = Rotpl::Totp.new(secret)

# Generate codes for current time
codes = totp.generate_otp
# => ["287082", "359152", "969429"]

# Generate codes for specific time
time = Time.at(59)
codes = totp.generate_otp(time)

# Custom time step (default is 30 seconds)
totp = Rotpl::Totp.new(secret, time_step: 60)
codes = totp.generate_otp
```

### Counter-based OTP (HOTP)

```ruby
require 'rotpl'

secret = "12345678901234567890"

# Generate OTP for counter value 0
otp = Rotpl::Hotp.generate_otp(secret, 0)
# => "755224"

# Generate OTP for counter value 1
otp = Rotpl::Hotp.generate_otp(secret, 1)
# => "287082"

# Generate 8-digit OTP
otp = Rotpl::Hotp.generate_otp(secret, 0, code_digits: 8)
# => "94287082"
```

## Usage Examples

### Building a Login System

```ruby
require 'rotpl'

class TwoFactorAuth
  def initialize(user_secret)
    @ga = Rotpl::GoogleAuthenticator.new(user_secret)
  end

  def verify(user_input)
    valid_codes = @ga.generate_otp
    valid_codes.include?(user_input)
  end
end

# In your login controller
auth = TwoFactorAuth.new(user.two_factor_secret)
if auth.verify(params[:otp_code])
  # Login successful
else
  # Invalid code
end
```

### Generating QR Code Secrets

```ruby
require 'base32'

# Generate a random secret for a new user
random_secret = Base32.encode(SecureRandom.random_bytes(20))
# => "JBSWY3DPEHPK3PXP"

# Store this in your database
user.update(two_factor_secret: random_secret)

# Create QR code URL for Google Authenticator
# Format: otpauth://totp/Label?secret=SECRET&issuer=Issuer
qr_url = "otpauth://totp/#{user.email}?secret=#{random_secret}&issuer=MyApp"

# Generate QR code from qr_url and display to user
```

### Handling Clock Skew

```ruby
# TOTP returns 3 codes by default
codes = totp.generate_otp
# codes[0] = previous 30-second window
# codes[1] = current 30-second window
# codes[2] = next 30-second window

# Accept any of the 3 codes to handle clock differences
def verify_with_tolerance(user_input, totp)
  totp.generate_otp.include?(user_input)
end
```

### Custom Time Windows

```ruby
# 60-second windows instead of 30
totp = Rotpl::Totp.new(secret, time_step: 60)

# 15-second windows for higher security (more frequent code changes)
totp = Rotpl::Totp.new(secret, time_step: 15)
```

## API Documentation

All classes and methods include YARD documentation. Key classes:

### `Rotpl::Hotp`
- `Hotp.generate_otp(secret, counter, code_digits: 6)` - Generate HOTP code
- `Hotp.hmac_sha1(secret, counter)` - Compute HMAC-SHA1 hash

### `Rotpl::Totp`
- `Totp.new(secret, hotp: Hotp, time_step: 30)` - Initialize TOTP
- `#generate_otp(time = Time.now, code_digits: 6)` - Generate codes (returns array of 3)

### `Rotpl::GoogleAuthenticator`
- `GoogleAuthenticator.new(base32_secret, time_step: 30)` - Initialize with Base32 secret
- `#generate_otp(time = Time.now, code_digits: 6)` - Generate codes (returns array of 3)

## Testing

Run the test suite:

```bash
bundle install
rspec
```

Tests validate against official RFC 4226 and RFC 6238 test vectors.

## Security Considerations

- Always use HTTPS when transmitting OTP codes
- Store secrets securely (encrypted in database)
- Use constant-time comparison when verifying codes
- Implement rate limiting to prevent brute force attacks
- Consider requiring backup codes for account recovery
- Secrets should be at least 160 bits (20 bytes) for HMAC-SHA1

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Don't forget tests!
6. Create new Pull Request

## License

GNU LGPL v3 - See LICENSE file for details

## Copyright

The code has been mostly derived from the original reference implementation of [RFC 6238](https://tools.ietf.org/html/rfc6238):

    Copyright (c) 2011 IETF Trust and the persons identified as authors of the code. All rights reserved.

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
      * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    Neither the name of Internet Society, IETF or IETF Trust, nor the names of specific contributors, may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.