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

require 'rubygems'
require './twitterSocialMapsLib.rb'
require "./key2.rb"

################################################################################

   testID="BarackObama"

   timeNow=Time.now.strftime("%d/%m/%Y %H:%M")
   $stderr.puts "-------------- Start: #{testID} @ #{timeNow} --------------"

#   ret=TwitterFriends.new(testID,pollTwitter: false)
   ret=TwitterFriends.new(testID)

   timeNow=Time.now.strftime("%d/%m/%Y %H:%M")
   $stderr.puts "\n-------------- Done: #{testID} @ #{timeNow}  ---------------"
   ret.printClass




