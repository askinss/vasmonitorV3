class Monitor::Rimmonitor < Monitor::Monitorbase
  require 'net/http'
  attr_writer :rim_time, :url, :username, :password, :test_imsi
  def initialize
    super
    @rim_time = Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")
    @url = load_config['url']
    @username = load_config['username']
    @password = load_config['password']
    @test_imsi = load_config['test_imsi'].to_s
  end

  def monitor
    rimurl = 'https://' + @url + '/ari/submitXML'
    rim_xml = "<?xml version='1.0' ?><!DOCTYPE ProvisioningRequest SYSTEM 'ProvisioningRequest.dtd'>" +\
      "<ProvisioningRequest TransactionId='"+TRANSACTIONID+"' Version='1.2' TransactionType='Status' ProductType='BlackBerry'>" +\
      "<Header><Sender id='101' name='WirelessCarrier'><Login>"+@username +"</Login><Password>"+@password+"</Password>"+\
      "</Sender><TimeStamp>"+@rim_time+"</TimeStamp></Header><Body><ProvisioningEntity name='subscriber'>" +\
      "<ProvisioningDataItem name='BillingId'>"+@test_imsi+"</ProvisioningDataItem></ProvisioningEntity>" +\
      "</Body></ProvisioningRequest>"
    uri = URI(rimurl)
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.ssl_version = :SSLv3
    res = http.post(uri.path, rim_xml, {'Content-Type' => 'text/xml', 'Content-Length' => rim_xml.length.to_s, "User-Agent" => "VAS-UCIP/3.1/1.0", "Connection" => "keep-alive" })
    if res.code == '200'
      return true
    else 
      raise "Air Server returned with #{res.code} http response code which means #{Rack::Utils::HTTP_STATUS_CODES[res.code.to_i]}"
      return false
    end
  end

  def action_for_success_response

  end

  def action_for_failure_response
    super
  end
end

