#!/usr/bin/env ruby
#
# Geek    : Henry J. Escobar
# email   : henry.escobar@gmail.com
# Legal   : The MIT License (MIT)
# File    :
# Purpose : Library to poll twitter and add to short/long term storage
# Notes   :
# Todo    :
#       Write stuff to postgres since too much data for redis.
#       i.e. Abusing redis too much
#		
#
################################################################################
#
# Methods
#

################################################################################
#
# Library for all the things
#
################################################################################

require 'rubygems'
require 'twitter'
require 'redis'
require 'json'
require './twitterSocialMapsConfig.rb'

############################################################################### 
#
# workerName      := { host:filename:pid || hardcoded:pid? }
# status          := { working, done }
# workerHeartBeat := { ctime+30 min }
# lastwrite       := ctime of last write

class TwitterFriends 

   attr_accessor  :screen_name,:friends,:status

   ###########################################################################
   def initialize(screen_name, options = {})
       options[:pollTwitter] = true if options.empty?

       #logMessage("working on #{screen_name}")

       @screen_name     = screen_name
       @status          = "ready"     #-> ready|wip|done
       @statuses_count  = -1
       @heartbeat       = -1
       @startTime       = -1
       @stopTime     = -1
       @lastwrite     = -1
       @cacheExpire     = -1
       @lastAccess     = -1
       @accessCount     = -1
       @createDate     = Time.new.getutc.to_i
       @followers_count     = -1
       @friend_count	= -1
       @listed_count	= -1
       @verified	= -1
       @ffRatio		= -1
       @cursor		= -1
       @next_cursor	= -1
       @workerName	= $workerName
       @friends		= Array.new

       initUserID(options)
   end #def initilize

   ###########################################################################
   def exportJson
       hash=Hash.new
       hash["screen_name"]	= @screen_name
       hash["status"]		= @status	
       hash["statuses_count"]	= @statuses_count
       hash["heartbeat"]	= @heartbeat
       hash["startTime"]	= @startTime
       hash["stopTime"]		= @stopTime
       hash["lastwrite"]	= @lastwrite
       hash["cacheExpire"]	= @cacheExpire
       hash["lastAccess"]	= @lastAccess
       hash["accessCount"]	= @accessCount
       hash["createDate"]	= @createDate
       hash["followers_count"]	= @followers_count
       hash["friend_count"]	= @friend_count
       hash["listed_count"]	= @listed_count
       hash["verified"]		= @verified
       hash["ffRatio"]		= @ffRatio
       hash["cursor"]		= @cursor
       hash["next_cursor"]	= @next_cursor
       hash["workerName"]	= @workerName
       hash["friends"]		= @friends

       return hash
   end # exportJson

   ###########################################################################
   def importJson(inputJson)
       if ( ! inputJson.is_a?(Hash) ) 
	  logMessage "ASSERT: input not a HASH. exiting"
	  exit 5
       end
       @screen_name	=  inputJson["screen_name"]
       @status		=  inputJson["status"]
       @statuses_count	=  inputJson["statuses_count"]
       @heartbeat	=  inputJson["heartbeat"]
       @startTime	=  inputJson["startTime"]
       @stopTime	=  inputJson["stopTime"]
       @lastwrite	=  inputJson["lastwrite"]
       @cacheExpire	=  inputJson["cacheExpire"]
       @lastAccess	=  inputJson["lastAccess"]
       @accessCount	=  inputJson["accessCount"]
       @createDate	=  inputJson["createDate"]
       @followers_count	=  inputJson["followers_count"]
       @friend_count	=  inputJson["friend_count"]
       @listed_count	=  inputJson["listed_count"]
       @verified	=  inputJson["verified"]
       @ffRatio		=  inputJson["ffRatio"]
       @cursor		=  inputJson["cursor"]
       @next_cursor	=  inputJson["next_cursor"]
       @workerName	=  inputJson["workerName"]
       @friends		=  inputJson["friends"]
       return 0
   end # importJson

   ###########################################################################
   def printClass
       puts "\t------- #{@screen_name} @ ctime #{Time.new.getutc.to_i} -------"

       printf "\tscreen_name:    %18s  Status:          %18s\n",
		@screen_name,@status
       printf "\theartbeat:      %18s  lastwrite:       %18s\n",
		@heartbeat,@lastwrite
       printf "\tstartTime:      %18s  stopTime:        %18s\n",
		@startTime,@stopTime
       printf "\tcacheExpire:    %18s  lastAccess:      %18s\n",
		@cacheExpire,@lastAccess
       printf "\taccessCount:    %18s  followers_count: %18s\n",
		@accessCount,@followers_count
       printf "\tfriend_count:   %18s  listed_count:    %18s\n",
		@friend_count,@listed_count
       printf "\tverified:       %18s  ffRatio:         %.3f\n", 
		@verified, @ffRatio
       printf "\tstatuses_count: %18s\n",@statuses_count
       printf "\tcreateDate:     %18s  \n",@createDate
       printf "\tworkerName:     %18s\n",@workerName
       printf "\tcursor:         %18s\n", @cursor
       printf "\tnext_cursor:    %18s\n", @next_cursor
       #printf "\tfriends: %s\n", @friends	
       printf "\tfriends:        <SUPPRESSED>\n"

       puts "\n\t------- Data calculated from object -------"

       myTime=Time.now.strftime("%m/%d/%Y %H:%M")
       printf "\tCurrent Time           : %s\n\n",myTime
      
       myTime=Time.at(@startTime).strftime("%m/%d/%Y %H:%M")
       printf "\tstartTime   : %s",myTime
      
       if ( @stopTime > 0 ) 
          myTime=Time.at(@stopTime).strftime("%m/%d/%Y %H:%M")
          printf "\t\tstopTime    : %s\n",myTime
       else
          printf "\t\tstopTime    : <NA> still running\n"
       end

       myTime=Time.at(@createDate).strftime("%m/%d/%Y %H:%M")
       printf "\tcreateDate  : %s",myTime

       myTime=Time.at(@heartbeat).strftime("%m/%d/%Y %H:%M")
       printf "\t\theartbeat   : %s\n",myTime

       myTime=Time.at(@lastAccess).strftime("%m/%d/%Y %H:%M")
       printf "\tlastAccess  : %s",myTime

       myTime=Time.at(@lastwrite).strftime("%m/%d/%Y %H:%M")
       printf "\t\tlastwrite   : %s\n",myTime

       remainingTime=@heartbeat - Time.new.getutc.to_i
       printf "\n"
       printf "\tfriends.size           : %i\n", @friends.size
       printf "\theartbeat reaming time : %i\n",remainingTime

   end # printFriendHash

   ###########################################################################
   def initUserID(options={})
       msgPrepend="Log(#{@screen_name})"
       if ( checkCache()  ) # non-nil return from checkCache

          ###############
	  # Is it WIP? has the heartbeat time expired?
          if ( ( @status.downcase.match(/^wip$/) ) 	&& 
	       ( @heartbeat < Time.new.getutc.to_i )   )
                logMessage "#{msgPrepend}: WIP heartbeat expired. freeing"
                @status="ready"
          end # if wip

          case @status.downcase
	       when ( /^done$/  )
		  logMessage "#{msgPrepend}: done status.  Using Cached data"
		  return 0
	       when ( /^ready$/ )
	          if ( options[:pollTwitter] ) 
		     logMessage "#{msgPrepend}: ready status. ask twitter"
                     loopTwitter 
                  else
		     #logMessage "#{msgPrepend}: ready status. :pollTwitter: #{options[:pollTwitter]}"
		     return 0
                  end
	       when ( /^wip$/ )
		  logMessage "#{msgPrepend}: wip status. worker: #{@workerName}"
		  return 1
	       else
		  logMessage "ASSERT #{msgPrepend}: unknown status #{status}. exiting"
		  exit 7
          end # case
       end # if checkCache

       logMessage "#{msgPrepend}: checkCache returned non-zero"

   end #initUserID

   ###########################################################################
   def checkCache
       ctimeTag=Time.new.getutc.to_i
       @lastAccess=ctimeTag
       @accessCount+=1

       redisKey=$redisBase + ":" +  @screen_name
       # Had json errors when redis returned nil. quick fix
       redisCache=$redisObject.GET(redisKey.downcase)
       #not in cache. return nil
       if ( redisCache.nil? ) 
          return 1
       end

       redisJson=JSON.parse(redisCache)
       if ( redisJson.size < 1 ) 
          return 1
       end

       # Check if expired
       ctimeTag=Time.new.getutc.to_i
       # never expire for now 
       ctimeTag=1000000000
       if ( redisJson["cacheExpire"] > ctimeTag )
          return 2
       end
	  
       importJson(redisJson)
       return 0
   end # checkCache

   ###########################################################################
   def writeCache
       @lastwrite=Time.new.getutc.to_i
       key=$redisBase + ":" +  @screen_name
       h=Hash.new
       h=exportJson

       return $redisObject.SET(key.downcase,h.to_json)
   end # writeCache

   ###########################################################################
   def loopTwitter
       cnt=0
       @status="wip"
       $stderr.print "loop count:"
       @startTime=Time.new.getutc.to_i
       @workerName	= $workerName
       @heartbeat=Time.new.getutc.to_i + $heartbeatExpire

       #$stderr.puts "debug remove me"
       #       writeCache
       #exit
       begin
          cnt+=1
          $stderr.printf "#{cnt},"
          ctimeTag=Time.new.getutc.to_i
          @heartbeat=ctimeTag + $heartbeatExpire
          pollTwitter
       end while (@next_cursor > 0 ) 

       ctimeTag=Time.new.getutc.to_i
       @stopTime=ctimeTag 
       @expire=ctimeTag+$minCacheExpire
       @status="done"
       writeCache
   end #  loopTwitter

   ###########################################################################
   def pollTwitter
       begin 
          friendsCursor = Twitter.friends(@screen_name,
				:cursor => @next_cursor, 
				:count => '200',
				:skip_status => true,
				)
          ctimeTag=Time.new.getutc.to_i
          @cursor=@next_cursor
          @next_cursor=friendsCursor.next_cursor
          rescue Twitter::Error::TooManyRequests => error
             sleepyTime=error.rate_limit.reset_in+1 # add a second to be nice
	     sleepInMin=sleepyTime/60
             $stderr.puts "\n"
             logMessage("Rate limit hit. Sleeping for ~ #{sleepInMin} min...\n")
  	     # checkpoint what I have!
             writeCache
             sleep sleepyTime
             retry
          rescue Twitter::Error::NotFound => error
             logMessage("ERROR: #{@screen_name} does not exist")
	     return
          rescue Twitter::Error::Forbidden => error
	     printf "Error: %s %s\n ", error.message, error.backtrace
	     exit 	# doesn't work!!!
          rescue Twitter::Error::ServiceUnavailable => error
             logMessage("ERROR: twitter api Unavailable. sleeping 30 min.")
	     sleep 1800
	     #infient lloop?
             retry
          rescue Twitter::Error::ClientError => error
             logMessage("ERROR: twitter client Error... . sleeping 30 min.")
		$stderr.puts "error: #{error}"
		exit
	     sleep 1800
             retry
          #rescue Exception => e
#	  puts e.message, e.backtrace
       end # end of rescue block
   
       friendsCursor.users.each do |i|
          @friends.push(i.screen_name)
          processTwitterUser(i)
       end
     
       writeCache
    end # def pollTwitter(twiterHash)

   ###########################################################################
   #
   # is instance_variable_set bad form???
   #
   def processTwitterUser(twitterUser)
       friend=TwitterFriends.new(twitterUser.screen_name,pollTwitter: false)
       friend.instance_variable_set("@screen_name",twitterUser.screen_name)
       friend.instance_variable_set("@followers_count",
		twitterUser.followers_count)
       friend.instance_variable_set("@friend_count",twitterUser.friend_count)
       friend.instance_variable_set("@listed_count",twitterUser.listed_count)
       friend.instance_variable_set("@verified",twitterUser.verified)
    
       if (twitterUser.friend_count == 0 ) 
          friend.instance_variable_set("@ffRation",twitterUser.followers_count)
       else
          friend.instance_variable_set("@ffRation",
		twitterUser.followers_count/twitterUser.friend_count )
       end

       friend.instance_variable_set("@statuses_count",
		twitterUser.statuses_count)

       #friend.printClass
       friend.writeCache

   end # processTwitterUser

end # class TwitterFriends 

############################################################################### 

