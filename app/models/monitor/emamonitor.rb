class Monitor::Emamonitor < Monitor::Monitorbase
  require 'net/telnet'
  attr_writer :ip, :port, :username, :password, :test_msisdn

  def initialize
    super
    @ip = load_config['ip']
    @port = load_config['port']
    @username = load_config['username']
    @password = load_config['password']
    @test_msisdn = load_config['test_msisdn'].to_s
    @timeout = 20
  end

  def monitor
    ema_response = ''
    i = 0
    while i < 3 do 
      begin
        puts "count no #{i}"
        ema = Net::Telnet::new("Host" => @ip,
                               "Port" => @port.to_s,
                               "Timeout" => 2,
                               "Prompt" => /Enter command:/)
        login = ema.cmd("LOGIN:#{@username}:#{@password};")
        ema.waitfor(/Enter command:/)
        ema_response = ema.cmd("GET:HLRSUB:MSISDN,#{@test_msisdn}:IMSI;")
        puts ema_response
        ema.cmd("LOGOUT;\n") 
        ema.close
      rescue
      end
      break if (ema_response.match(/RESP:\d+:MSISDN,\d+:IMSI,\d+;/))
      i += 1
    end
    puts ema_response.inspect
    if (ema_response.match(/RESP:\d+:MSISDN,\d+:IMSI,\d+;/))
      return true
    else
      raise "Response from EMA for GET:HLRSUB:MSISDN,#{load_config['test_msisdn']}:IMSI; is: #{ema_response}, this does not seem right, please check"
      return false
    end
  end

  def action_for_success_response

  end

  def action_for_failure_response
    super
  end
end
