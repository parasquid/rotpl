task :console do
  require 'irb'
  require 'irb/completion'
  require 'pry'

  $LOAD_PATH.unshift(File.dirname(__FILE__))
  require 'lib/hotp'
  require 'lib/totp'

  ARGV.clear
  IRB.start
end