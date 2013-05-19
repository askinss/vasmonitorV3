class Monitor::Sdpservermonitor < Monitor::Monitorbase
require 'net/http'
  def monitor
    raise "SDP-server is down, no process id found" if ps.empty?
    brokerurl = "http://#{load_config['ip']}:#{load_config['port']}/blackberry/smsservice"
    uri = URI(brokerurl)
    params = {:msisdn => '255', :msg => load_config['status_shortcode']}
    uri.query = URI.encode_www_form(params)
    res = Net::HTTP.get_response(uri)
    puts res.code.inspect
    if res.code == '404'
      return true
    else
      return false
    end
  end

  def action_for_success_response
    super
  end

  def action_for_failure_response
    super
  end
end
