require 'singleton'

module Versioneye


  class Log

    include Singleton

    def initialize
      environment = ENV['RAILS_ENV']
      environment = 'development' if environment.to_s.empty?
      @logger = ActiveSupport::Logger.new("log/#{environment}.log", 10, 10485760) # 10485760 = 10 MB
      @logger.formatter = Versioneye::Formatter.new
    end

    def log
      @logger
    end

  end


  class Formatter

    SEVERITY_TO_TAG_MAP     = {'DEBUG'=>'meh', 'INFO'=>'fyi', 'WARN'=>'hmm', 'ERROR'=>'wtf', 'FATAL'=>'omg', 'UNKNOWN'=>'???'}
    SEVERITY_TO_COLOR_MAP   = {'DEBUG'=>'0;37', 'INFO'=>'32', 'WARN'=>'33', 'ERROR'=>'31', 'FATAL'=>'31', 'UNKNOWN'=>'37'}

    def call(severity, time, progname, msg)
      formatted_severity = sprintf("%-3s","#{SEVERITY_TO_TAG_MAP[severity]}")
      formatted_time     = time.strftime("%Y-%m-%d %H:%M:%S.") << time.usec.to_s[0..2].rjust(3)
      color              = SEVERITY_TO_COLOR_MAP[severity]

      "\033[0;37m#{formatted_time}\033[0m [\033[#{color}m#{formatted_severity}\033[0m] #{msg.strip} (pid:#{$$})\n"
    end
  end


end
