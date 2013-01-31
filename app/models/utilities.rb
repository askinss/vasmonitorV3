require 'net/http'
require 'net/telnet'
require 'net/smtp'
require 'base64'
require 'timeout'
include Airtel

class Utilities

  TRANSACTIONID = (rand(100000)/777.0).to_f.round(8).to_s.gsub(/\w+\./, "")
  RIM_TIME = Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")

  def self.response_time(node)
    start_time = Time.now
    begin
      block_response = Timeout::timeout(10) { eval("Utilities.#{node}_response") }
    rescue 
      block_response = false
    end
    end_time = Time.now
    time_taken = (end_time - start_time).round(4)
    if block_response && (time_taken < 10)
      return time_taken
    else
      self.sendsms("#{node.upcase} is not responding!!!!, please act fast")
      self.send_message("#{node.upcase} is not responding!!!","Dear Support,\n\n#{node.upcase} is down, please respond\nRegards,\nVAS Apps", 'VAS MONITOR', self.load_config['admin_emails'].split(","))
      if node.downcase == "broker"
        self.sendsms("#{node.upcase} is about to be restarted")
        `bash #{Rails.root}/script/sdprestart.sh`
        self.sendsms("#{node.upcase} has restarted, please run ps -ef | grep SDP-server to confirm there is only one active SDP-server process")
      end
      return 0
    end
  end

  def self.air_response
    air_url = 'http://' + self.load_config['air_ip'] + ':' + self.load_config['air_port'].to_s + '/Air'
    air_user_and_pass = self.load_config['air_username'] + ':' + self.load_config['air_password']
    base64air_user_and_pass = Base64.encode64(air_user_and_pass)

    xml = '<?xml version="1.0"?><methodCall><methodName>GetBalanceAndDate</methodName><params><param><value><struct><member><name>originNodeType</name><value><string>EXT</string></value></member><member><name>originHostName</name><value><string>BBUCIP</string></value></member><member><name>externalData1</name><value><string>BBUIP</string></value></member><member><name>subscriberNumberNAI</name><value><i4>1</i4></value></member><member><name>originTransactionID</name><value><string>' + TRANSACTIONID.to_s + '</string></value></member><member><name>originTimeStamp</name><value><dateTime.iso8601>' + Time.now.strftime("%Y%m%dT%T%z") + '</dateTime.iso8601></value></member><member><name>subscriberNumber</name><value><string>' + self.load_config['test_msisdn'].to_s + '</string></value></member></struct></value></param></params></methodCall>'

    uri = URI(air_url)
    http = Net::HTTP.new(uri.hostname, uri.port)
    begin
      res = http.post(uri.path, xml, {'Content-Type' => 'text/xml', 'Authorization' => "Basic #{base64air_user_and_pass}", 'Content-Length' => xml.length.to_s, "User-Agent" => "VAS-UCIP/3.1/1.0", "Connection" => "keep-alive" })
      if res.code == '200'
        return true
      else 
        return false
      end
    rescue => e
      return false
      e.backtrace
    end
  end

  def self.ema_response
    resp1,resp2 = '','',''
    ema = Net::Telnet::new("Host" => self.load_config['ema_ip'],
                           "Port" => self.load_config['ema_port'],
                           "Timeout" => 10,
                           "Prompt" => /Enter command:/)
    ema.cmd("LOGIN:#{self.load_config['ema_user']}:#{self.load_config['ema_password']};") 
    ema.cmd("GET:HLRSUB:MSISDN,#{self.load_config['test_msisdn']}:IMSI;") 
    ema_response = ema.cmd("LOGOUT;\n") { |x| resp2 << x }
    ema.close
    if ema_response.include?(self.load_config['test_imsi'].to_s)
      return true
    else
      return false
    end
  end

  def self.rim_response
    rimurl = 'https://' + self.load_config['rim_url'] + '/ari/submitXML'
    rim_xml = "<?xml version='1.0' ?><!DOCTYPE ProvisioningRequest SYSTEM 'ProvisioningRequest.dtd'>" +\
      "<ProvisioningRequest TransactionId='"+TRANSACTIONID+"' Version='1.2' TransactionType='Status' ProductType='BlackBerry'>" +\
      "<Header><Sender id='101' name='WirelessCarrier'><Login>"+self.load_config['rim_username'] +"</Login><Password>"+self.load_config['rim_password']+"</Password>"+\
      "</Sender><TimeStamp>"+RIM_TIME+"</TimeStamp></Header><Body><ProvisioningEntity name='subscriber'>" +\
      "<ProvisioningDataItem name='BillingId'>"+self.load_config['test_imsi'].to_s+"</ProvisioningDataItem></ProvisioningEntity>" +\
      "</Body></ProvisioningRequest>"
    uri = URI(rimurl)
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = http.post(uri.path, rim_xml, {'Content-Type' => 'text/xml', 'Content-Length' => rim_xml.length.to_s, "User-Agent" => "VAS-UCIP/3.1/1.0", "Connection" => "keep-alive" })
    if res.code == '200'
      return true
    else 
      return false
    end
    #xmldoc = Document.new res.body
  end

  def self.broker_response
    brokerurl = "http://#{Utilities.load_config['broker_ip']}:#{Utilities.load_config['broker_port']}/blackberry/smsservice"
    uri = URI(brokerurl)
    params = {:msisdn => '255', :msg => 'status'}
    uri.query = URI.encode_www_form(params)
    res = Net::HTTP.get_response(uri)
    if res.code == '404'
      return true
    else
      return false
    end
  end

  def self.sendsms(message, receipients = self.load_config['admin_numbers'])
    kannelurl = 'http://127.0.0.1:13009/cgi-bin/sendsms'
    uri = URI(kannelurl)
    receipients.to_s.split(",").each do |receipient|
      params = {:username => 'admin', :password => 'password', :to => receipient.to_s, :text => message }
      uri.query = URI.encode_www_form(params)
      begin
        res = Net::HTTP.get_response(uri)
      rescue => e
        e.backtrace
      end
    end
  end

  def self.send_message(subject,message,sender= "#{self.load_config['opco']} VAS REPORTS",to = Utilities.load_config['receipients'])
    msg = <<END_OF_MESSAGE
From: #{self.load_config['opco']} #{sender} <apps@vas-consulting.com>
To: support@vas-consulting.com <SUPPORT> 
MIME-Version: 1.0
Content-type: text/html
Subject:#{self.load_config['opco']} #{subject}

#{message}

END_OF_MESSAGE
    begin
      smtp = Net::SMTP.new('smtp.gmail.com', 465)
      smtp.enable_tls
      smtp.set_debug_output $stderr
      smtp.start('127.0.0.1','apps.vasconsulting@gmail.com','passw0rd$','plain') do |smtp|
        smtp.send_message(msg,'monitor@vas-consulting.com',to = Utilities.load_config['receipients'].split(","))
      end
    rescue => e
      puts e.backtrace
    end
  end

  def self.execute
    self.load_config['nodes_to_monitor'].split(",").each do |node|
      if self.singleton_methods.include?("#{node}_response".to_sym)
        Mongobroker.create!(:value => self.response_time(node), :node => node.downcase)
        puts node
      else
        self.sendsms("Please consult the VASCON team to include #{node} for monitoring")
        next
      end
    end
  end

  def self.load_config
    YAML.load_file File.join(Rails.root, 'config', 'config.yml')
  end
end
