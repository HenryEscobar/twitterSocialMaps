#!/usr/bin/env ruby
#
# Geek    : Henry J. Escobar
# email   : henry.escobar@gmail.com
# Legal   : The MIT License (MIT)
# File    :
# Purpose : Iterate over my followers and add their friends of friends...
# Notes   :
#		Need to make recursive
#
################################################################################
#
# Methods
#

require 'rubygems'
require './twitterSocialMapsLib.rb'
require "./key2.rb"

################################################################################

   testID="hankinnyc"

   timeNow=Time.now.strftime("%d/%m/%Y %H:%M")
   $stderr.puts "-------------- Start: #{testID} @ #{timeNow} --------------"

#   ret=TwitterFriends.new(testID,pollTwitter: false)
   ret=TwitterFriends.new(testID)

   timeNow=Time.now.strftime("%d/%m/%Y %H:%M")
   $stderr.puts "\n-------------- Done: #{testID} @ #{timeNow}  ---------------"
   ret.printClass



   ret.friends.each do |friend|
      timeNow=Time.now.strftime("%d/%m/%Y %H:%M")
      $stderr.puts "\n------------- Start: #{friend} @ #{timeNow} -------------"

      tFriend=TwitterFriends.new(friend)

      timeNow=Time.now.strftime("%d/%m/%Y %H:%M")
      $stderr.puts "\n------------- Done: #{friend}  @ #{timeNow} -------------"
      #tFriend.printClass

   end # ret.friends.each do |friend|
 



