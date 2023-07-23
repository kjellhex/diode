require 'time'

# a class to provide for simple logging
class Logger

	Levels = {
		:Debug => 1,
		:Info => 2,
		:Warn => 3,
		:Error => 4
	}

	attr_accessor(:logPath, :logLevel)

	# create a new logger
	def initialize(path="/dev/null", level=:Info)
		@logPath = File.expand_path(path)
		@logLevel = level
		raise("Unknown log level #{level}") unless Levels.include?(level)
	end

	# returns an open log file for appending
	def logFile(&block)
		File.open(@logPath, "a", &block)
	end

	def logmsg(priority=:Info, msg="", log=nil)
		return if Levels[priority] < Levels[@logLevel]
		f = log || logFile()
		event = "%s pri=%s %s" % [Time.now.to_s()[0..18], priority.to_s(), msg]
		f.puts(event)
		puts(event) if $DEBUG # also echo to stdout if debug is on
		f.close() if log.nil?
		nil  # so we can rescue and log a message, implicitly returning nil
	end

	def error(msg, log=nil)
		logmsg(:Error, msg, log)
	end

	def warn(msg, log=nil)
		logmsg(:Warn, msg, log)
	end

	def info(msg, log=nil)
		logmsg(:Info, msg, log)
	end

	def debug(msg, log=nil)
		logmsg(:Debug, msg, log)
	end

end

