require 'net/http'
require 'net/telnet'
require 'net/smtp'
require 'base64'
require 'timeout'
class Monitor::Monitorbase

  TRANSACTIONID = (rand(100000)/777.0).to_f.round(8).to_s.gsub(/\w+\./, "")

  attr_reader :timeout, :persist
  attr_writer :smsmessage

  def initialize
    @timeout = 10
    @persist = true
    @smsmessage = "#{nodename.upcase} is not responding!!!!, please act fast"
  end

  def monitor
    #should return an array with first element been a boolean that determines success status of and the subsequent elements are parameters to supply to action_for_success_response or action_for_failure_response as the case may be
  end

  def action_for_success_response 

  end

  def action_for_failure_response
    puts @smsmessage
    Rails.logger.error (@smsmessage) 
    Utilities.sendsms(@smsmessage, load_config('admin_numbers'))
    Utilities.send_message("#{nodename.upcase} is not responding!!!!", emailmessage(@smsmessage), "#{Utilities.load_config['opco']} VAS MONITOR", load_config('admin_emails'))
  end

  protected
  def nodename
    self.class.to_s.match(/Monitor::(?<class>\w+)monitor/)[:class]
  end

  def ps
    process_name = load_config['process_name']
    process_name[process_name.size - 1] = "[#{process_name.last}]"
    `ps -efl | grep #{process_name}`
  end

  def load_config(node = nodename.downcase)
    Monitor::Utility.load_config[node]
  end

  def emailmessage(messagebody)
    message =  <<END_OF_MESSAGE
Dear Support,

#{messagebody}

Regards,

VAS Apps
END_OF_MESSAGE
    message
  end

end
