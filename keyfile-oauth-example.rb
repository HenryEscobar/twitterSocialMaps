#!/usr/bin/ruby
################################################################################
#
# Twitter key info and config
# Set your twitter api to this and require in ruby code
#
# This was a quick hack and should be done more properly.
# I have my files named key1.rb and key2.rb for the two api keys I 
#	Registered with twitter
#
################################################################################
Twitter.configure do |config|
  config.consumer_key = 'XXXXXXXXXXXXXXXXXXXXXX'
  config.consumer_secret = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
  config.oauth_token = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' 
  config.oauth_token_secret = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
end



