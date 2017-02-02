task :console do
  require 'irb'
  require 'irb/completion'
  require 'pry'

  $LOAD_PATH.unshift(File.dirname(__FILE__))
  require 'lib/hotp'
  require 'lib/totp'
  require 'lib/google_authenticator'

  ARGV.clear
  IRB.start
end