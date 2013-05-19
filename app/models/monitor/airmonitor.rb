class Monitor::Airmonitor < Monitor::Monitorbase
  require 'net/http'
  require 'base64'
  attr_writer :ip, :port, :username, :password, :test_msisdn

  def initialize
    super
    @ip = load_config['ip']
    @port = load_config['port'].to_s
    @username = load_config['username']
    @password = load_config['password']
    @test_msisdn = load_config['test_msisdn'].to_s
  end

  def monitor
    air_url = 'http://' + @ip  + ':' + @port + '/Air'
    air_user_and_pass =  @username + ':' + @password
    base64air_user_and_pass = Base64.encode64(air_user_and_pass)

    xml = '<?xml version="1.0"?><methodCall><methodName>GetBalanceAndDate</methodName><params><param><value><struct><member><name>originNodeType</name><value><string>EXT</string></value></member><member><name>originHostName</name><value><string>BBUCIP</string></value></member><member><name>externalData1</name><value><string>BBUIP</string></value></member><member><name>subscriberNumberNAI</name><value><i4>1</i4></value></member><member><name>originTransactionID</name><value><string>' + TRANSACTIONID.to_s + '</string></value></member><member><name>originTimeStamp</name><value><dateTime.iso8601>' + Time.now.strftime("%Y%m%dT%T%z") + '</dateTime.iso8601></value></member><member><name>subscriberNumber</name><value><string>' + @test_msisdn + '</string></value></member></struct></value></param></params></methodCall>'

    uri = URI(air_url)
    http = Net::HTTP.new(uri.hostname, uri.port)
    begin
      res = http.post(uri.path, xml, {'Content-Type' => 'text/xml', 'Authorization' => "Basic #{base64air_user_and_pass}", 'Content-Length' => xml.length.to_s, "User-Agent" => "VAS-UCIP/3.1/1.0", "Connection" => "keep-alive" })
      if res.code == '200'
        return true
      else 
        raise "Air Server returned with #{res.code} http response code which means #{Rack::Utils::HTTP_STATUS_CODES[res.code.to_i]}"
        return false
      end
    rescue => e
      raise e.message
      return false
      e.backtrace
    end
  end

  def action_for_success_response

  end

  def action_for_failure_response
    super
  end
end
