#!/usr/bin/env ruby
#
# Geek    : Henry J. Escobar
# email   : henry.escobar@gmail.com
# Legal   : The MIT License (MIT)
# File    :
# Purpose :
# Notes   :
#
################################################################################
#
# Methods
#

################################################################################
#
# Global Vars and Configuration information
#
################################################################################

require 'rubygems'
require 'redis'
# CONFIG STUFF
$redisBase="duality:twitter:users"
$redisWorkQueueKey="duality:twitter:queue:findFriends"
$heartbeatExpire=1200 # -> 20 minutes
$minCacheExpire=86400 # => 24 hours

redisHostname="redis.local"
$redisObject=Redis.new(:host => redisHostname )

$workerName="#{File.basename($0)}:#{$$}"

################################################################################


################################################################################
#
# Utility methods
#
def logMessage(msg)
    timeNow=Time.now.strftime("%d/%m/%Y %H:%M")
    cleanMessage="#{timeNow}: #{msg}"
    $stderr.puts "#{cleanMessage}"
end # logMessage

                                                          
