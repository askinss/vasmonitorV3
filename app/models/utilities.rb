require 'net/http'
require 'net/telnet'
require 'net/smtp'
require 'base64'
require 'timeout'
require 'zip/zip'
include Airtel

class Utilities

  TRANSACTIONID = (rand(100000)/777.0).to_f.round(8).to_s.gsub(/\w+\./, "")
  RIM_TIME = Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")
  SCHEDULER_SERVER_LOGS_PATH = '/home/bblite/SDP-Scheduler-server/logs/catalina.out'

  def self.response_time(node)
    start_time = Time.now
    begin
      block_response = Timeout::timeout(60) { eval("Utilities.#{node}_response") }
    rescue 
      block_response = false
    end
    end_time = Time.now
    time_taken = (end_time - start_time).round(4)
    if block_response && (time_taken < 60)
      return time_taken
    else
      self.sendsms("#{node.upcase} is not responding!!!!, please act fast")
      Rails.logger.info("#{node.upcase} is not responding!!!!, please act fast") 
      self.send_message("#{node.upcase} is not responding!!!","Dear Support,\n\n#{node.upcase} is down, please respond\nRegards,\nVAS Apps", "#{self.load_config['opco']} VAS MONITOR", self.load_config['admin_emails'])
      if node.downcase == "broker"
        #do nothing this is to remove unnecessary panic
      end
      return 0
    end
  end

  def self.scheduler_response
    (return true) if (File.size SCHEDULER_SERVER_LOGS_PATH) < 100000 #Return true if file size is less than 100kb
    found = false
    time = Time.now.strftime('%Y-%m-%d %H')
    time_in_last_hour = 1.hour.ago.strftime('%Y-%m-%d %H')
    time_in_last_2hours = 2.hour.ago.strftime('%Y-%m-%d %H')
    File.foreach(SCHEDULER_SERVER_LOGS_PATH) { |x| (found = true; break) if x.match(/(#{time}|#{time_in_last_hour}|#{time_in_last_2hours}).*Hourly\ Scheduler\ .*for\ this\ hour/) }
    return found
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
    ema = Net::Telnet::new("Host" => self.load_config['ema_ip'],
                           "Port" => self.load_config['ema_port'],
                           "Timeout" => 10,
                           "Prompt" => /Enter command:/)
    ema.cmd("LOGIN:#{self.load_config['ema_user']}:#{self.load_config['ema_password']};")
    ema.waitfor(/Enter command:/)
    ema_response = ema.cmd("GET:HLRSUB:MSISDN,#{self.load_config['test_msisdn']}:IMSI;")
    ema.cmd("LOGOUT;\n") 
    ema.close
    if (ema_response.match(/RESP:\d+:MSISDN,\d+:IMSI,\d+;/))
      return true
    else
      return false
    end
  end

  def self.nam_reset msisdn
    ema = Net::Telnet::new("Host" => self.load_config['ema_ip'],
                           "Port" => self.load_config['ema_port'],
                           "Timeout" => 10,
                           "Prompt" => /Enter command:/)
    ema.cmd("LOGIN:#{self.load_config['ema_user']}:#{self.load_config['ema_password']};")
    ema.waitfor(/Enter command:/)
    ema_response = ema.cmd("SET:HLRSUB:MSISDN,#{msisdn}:NAM,1;")
    puts ema_response
    ema_response1 = ema.cmd("SET:HLRSUB:MSISDN,#{msisdn}:NAM,0;")
    puts ema_response1
    ema.cmd("LOGOUT;\n") 
    ema.close
  end

  def self.get_imei msisdn
    ema = Net::Telnet::new("Host" => self.load_config['ema_ip'],
                           "Port" => self.load_config['ema_port'],
                           "Timeout" => 10,
                           "Prompt" => /Enter command:/)
    ema.cmd("LOGIN:#{self.load_config['ema_user']}:#{self.load_config['ema_password']};")
    ema.waitfor(/Enter command:/)
    ema_response = ema.cmd("GET:HLRSUB:MSISDN,#{msisdn}:IMEISV;")
    ema.cmd("LOGOUT;\n") 
    ema.close
    ema_response
  end

  def self.add_apn msisdn
    ema = Net::Telnet::new("Host" => self.load_config['ema_ip'],
                           "Port" => self.load_config['ema_port'],
                           "Timeout" => 10,
                           "Prompt" => /Enter command:/)
    ema.cmd("LOGIN:#{self.load_config['ema_user']}:#{self.load_config['ema_password']};")
    ema.waitfor(/Enter command:/)
    ema_response = ema.cmd("SET:HLRSUB:MSISDN,"+msisdn+":PDPCP,3;")
    ema.cmd("LOGOUT;\n") 
    ema.close
    ema_response
  end

  def self.remove_apn msisdn
    ema = Net::Telnet::new("Host" => self.load_config['ema_ip'],
                           "Port" => self.load_config['ema_port'],
                           "Timeout" => 10,
                           "Prompt" => /Enter command:/)
    ema.cmd("LOGIN:#{self.load_config['ema_user']}:#{self.load_config['ema_password']};")
    ema.waitfor(/Enter command:/)
    ema_response = ema.cmd("SET:HLRSUB:MSISDN,"+msisdn+":PDPCP,1;")
    ema.cmd("LOGOUT;\n") 
    ema.close
    ema_response
  end

  def self.get_msisdn_ema_details(msisdn)
    ema = Net::Telnet::new("Host" => self.load_config['ema_ip'],
                           "Port" => self.load_config['ema_port'],
                           "Timeout" => 10,
                           "Prompt" => /Enter command:/)
    ema.cmd("LOGIN:#{self.load_config['ema_user']}:#{self.load_config['ema_password']};")
    ema.waitfor(/Enter command:/)
    ema_response = ema.cmd("GET:HLRSUB:MSISDN,#{msisdn};")
    ema.cmd("LOGOUT;\n") 
    ema.close
    ema_response
  end

  def self.get_imsis(msisdn)
    ema = Net::Telnet::new("Host" => self.load_config['ema_ip'],
                           "Port" => self.load_config['ema_port'],
                           "Timeout" => 10,
                           "Prompt" => /Enter command:/)
    ema.cmd("LOGIN:#{self.load_config['ema_user']}:#{self.load_config['ema_password']};")
    ema.waitfor(/Enter command:/)
    msisdn_and_imsi = []
      msisdn.each do |msi| 
      resp = ema.cmd("GET:HLRSUB:MSISDN,#{msi}:IMSI;").match(/RESP:(?<respcode>\d+):MSISDN,(?<msisdn>\d+):IMSI,(?<imsi>\d+);/)
      unless resp.nil?
        (resp[:respcode] == "0" && resp[:msisdn] == msi) ? (msisdn_and_imsi << [msi,resp[:imsi]]) : next
      end
    end
    ema.close
    msisdn_and_imsi
  end

  def self.iat_response
    iaturl = 'http://' + self.load_config['iat_url'] + '/'
    iat_xml = "<?xml version='1.0' ?><!DOCTYPE ProvisioningRequest SYSTEM 'ProvisioningRequest.dtd'>" +\
      "<ProvisioningRequest TransactionId='"+TRANSACTIONID+"' Version='1.2' TransactionType='Status' ProductType='BlackBerry'>" +\
      "<Header><Sender id='101' name='WirelessCarrier'><Login>"+self.load_config['iat_username'] +"</Login><Password>"+self.load_config['iat_password']+"</Password>"+\
      "</Sender><TimeStamp>"+RIM_TIME+"</TimeStamp></Header><Body><ProvisioningEntity name='subscriber'>" +\
      "<ProvisioningDataItem name='BillingId'>"+self.load_config['test_imsi'].to_s+"</ProvisioningDataItem></ProvisioningEntity>" +\
      "</Body></ProvisioningRequest>"
    uri = URI(iaturl)
    http = Net::HTTP.new(uri.hostname, uri.port)
    res = http.post(uri.path, iat_xml, {'Content-Type' => 'text/xml', 'Content-Length' => iat_xml.length.to_s, "User-Agent" => "VAS-UCIP/3.1/1.0", "Connection" => "keep-alive" })
    if res.code == '200'
      return true
    else 
      return false
    end
    #xmldoc = Document.new res.body
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
    http.ssl_version = :SSLv3
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
      params = {:username => 'admin', :password => 'password', :to => receipient.to_s, :text => message, :from => 3379 }
      uri.query = URI.encode_www_form(params)
      begin
        res = Net::HTTP.get_response(uri)
        puts res.code
      rescue => e
        e.backtrace
      end
    end
  end

  def self.send_message(subject,message,sender = "#{self.load_config['opco']} VAS REPORTS",to = Utilities.load_config['admin_emails'])
    msg = <<END_OF_MESSAGE
From: #{sender} 
To: #{to} 
MIME-Version: 1.0
Content-type: text/html
Subject:#{self.load_config['opco']} #{subject}

#{message}

END_OF_MESSAGE
    begin
      smtp = Net::SMTP.new('smtp.gmail.com', 465)
      smtp.enable_tls
      smtp.set_debug_output $stderr
      smtp.start('127.0.0.1',self.load_config['sender'],self.load_config['sender_password'],'plain') do |smtp|
        smtp.send_message(msg,self.load_config['sender'],to.split(","))
      end
    rescue => e
      puts e.backtrace
      Rails.logger.error e.backtrace
    end
  end

  def self.execute
    self.load_config['nodes_to_monitor'].split(",").each do |node|
      if self.singleton_methods.include?("#{node}_response".to_sym)
        Mongobroker.create!(:value => self.response_time(node), :node => node.downcase)
        Rails.logger.info node
      else
        self.sendsms("Please consult the VASCON team to include #{node} for monitoring")
        next
      end
    end
  end

  def self.load_config
    YAML.load_file File.join(Rails.root, 'config', 'config.yml')
  end

  def self.zip
    dir_path = File.join(Rails.root,'dumps', '/')
    Dir.foreach(dir_path) do |f| 
      if f != '.' && f != '..'
        Zip::ZipFile.open(File.join(Rails.root,"dump.zip"), Zip::ZipFile::CREATE) { |zipfile|
          zipfile.get_output_stream(f) { |file| file.puts File.read(File.join(dir_path,f)) }
        }
        File.delete(File.join(dir_path,f)) #delete the files after zipping them
      end
    end
  end

  def self.send_att(subject,message,sender= "#{self.load_config['opco']} VAS REPORTS",to = Utilities.load_config['receipients'])
    filename = File.join(Rails.root, "dump.zip")
    filecontent = File.read(filename)
    encodedcontent = [filecontent].pack("m")   # base64
    marker = "AUNIQUEMARKER"
    part1 = <<EOF
From: #{sender}
To: #{to} 
Content-Type: multipart/mixed; boundary=#{marker}
Subject:#{subject}
MIME-Version: 1.0
--#{marker}
EOF
    msg = <<END_OF_MESSAGE
MIME-Version: 1.0
Content-type: text/html

#{message}
--#{marker}
END_OF_MESSAGE
part3 =<<EOD
Content-type: text/html
Content-transfer-Encoding:base64
Content-disposition: attachment; filename="dump.zip"

#{encodedcontent}
--#{marker}--
EOD
msg  = part1 + msg + part3
    begin
      smtp = Net::SMTP.new('smtp.gmail.com', 465)
      smtp.enable_tls
      smtp.set_debug_output $stderr
      smtp.start('127.0.0.1',self.load_config['sender'],self.load_config['sender_password'],'plain') do |smtp|
        smtp.send_message(msg,self.load_config['sender'],to.split(","))
      end
    rescue => e
      puts e.backtrace
      Rails.logger.error e.backtrace
    end
    File.delete(filename) #deletefile after sending
  end

  def self.batch_deactivated(imsi) #array of IMSIs should be supplied
    rimurl = 'https://' + self.load_config['rim_url'] + '/ari/submitXML'
    threads = []
    imsi.flatten.each_slice(100).each do |msis|
      threads << Thread.new(msis) do |threaded_imsi_arr|
        threaded_imsi_arr.each do |threaded_imsi|
          begin
            rim_xml = "<?xml version='1.0' ?><!DOCTYPE ProvisioningRequest SYSTEM 'ProvisioningRequest.dtd'>"+"<ProvisioningRequest TransactionId='"+TRANSACTIONID+"' Version='1.2' TransactionType='Cancel' ProductType='BlackBerry'><Header><Sender id='101' name='WirelessCarrier'><Login>"+self.load_config['rim_username']+"</Login><Password>"+self.load_config['rim_password']+"</Password></Sender><TimeStamp>"+Time.now.strftime("%Y-%m-%dT%TZ")+"</TimeStamp></Header><Body><ProvisioningEntity name='subscriber'><ProvisioningDataItem name='BillingId'>"+threaded_imsi+"</ProvisioningDataItem></ProvisioningEntity></Body></ProvisioningRequest>"
            uri = URI(rimurl)
            http = Net::HTTP.new(uri.hostname, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            http.ssl_version = :SSLv3
            res = http.post(uri.path, rim_xml, {'Content-Type' => 'text/xml', 'Content-Length' => rim_xml.length.to_s, "User-Agent" => "VAS-UCIP/3.1/1.0", "Connection" => "keep-alive" })
            if res.code == '200'
              puts "Deactivated #{threaded_imsi}"
              File.open(File.join(Rails.root, 'dumps','deactivated_imsis'), 'ab') { |f| f.puts threaded_imsi }
            else 
              File.open(File.join(Rails.root, 'dumps','fail_to_deactivate_imsis'), 'ab') { |f| f.puts threaded_imsi }
            end
          rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
            File.open(File.join(Rails.root, 'dumps','exceptions'), 'ab') { |f| f.puts e.backtrace }
          end
        end
      end
    end
    threads.each { |thread| thread.join }
  end

  def self.get_accurate_imsis_deactivated_a_month_ago
    a = Subscriber.new
    msisdn_and_imsi = []
    threads = []
    msisdn = []
    a.conn.exec("select msisdn from subscriber where next_subscription_date < (sysdate - 30) and statusid = 'Deactivated'") { |x| msisdn << x }
    a.logoff
    msisdn.flatten!.each_slice(1000).each do  |msis|
      threads << Thread.new(msis) do |threaded_imsi|
        begin
          Utilities.get_imsis(threaded_imsi).each { |msi_imsi| msisdn_and_imsi << msi_imsi }
        rescue Timeout::Error => e
          retry
        end
      end
    end
    threads.each { |thread| thread.join }
    msisdn_and_imsi.each do |msi_and_imsi| 
      CSV.open(File.join(Rails.root, 'dumps','msisdn_and_imsis_deactivated_a_month_ago.csv'), 'ab') do |row|
        row << msi_and_imsi
      end
    end  
    msisdn_and_imsi
  end

  def self.get_active_ems_imsi
    imsi = []; CSV.foreach(File.join(Rails.root, 'ems.csv'), :headers => true) { |x| (imsi << x[4]) if x[9] == 'Active' }; imsi
  end

  def self.get_deactivated_imsi_active_in_ems
    a = Subscriber.new
    imsi = []
    a.conn.exec("select imsi from subscriber where statusid != 'Active' and servicetype != 1") { |x| imsi << x[0] } #ommiting one day plan subscribers
    a.logoff
    deactivated_imsi_active_in_ems = (imsi & self.get_active_ems_imsi)
    deactivated_imsi_active_in_ems.each { |imsi_to_be_deactivated| File.open('/home/bblite/imsi_to_be_deactivated', 'ab') { |f| f.puts imsi_to_be_deactivated } }
    deactivated_imsi_active_in_ems
  end

  def self.deactivate_imsis_deactivated_for_over_a_month
    self.batch_deactivated(self.get_accurate_imsis_deactivated_a_month_ago.collect { |row| row[1] })
  end
end
