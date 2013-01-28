require 'net/http'
require 'rexml/document'
include Airtel

class Suspend
  def suspend(imsi)
    rimurl = 'https://' + Utilities.load_config['rim_url'] + '/ari/submitXML'
    rim_xml = "<?xml version='1.0'?><!DOCTYPE ProvisioningRequest SYSTEM 'ProvisioningRequest.dtd'><ProvisioningRequest TransactionId='1352538320589' Version='1.2' TransactionType='Suspend' ProductType='BlackBerry'><Header><Sender id='101' name='WirelessCarrier'><Login>bbliteZM</Login><Password>Airtelzm01</Password></Sender><TimeStamp>2012-11-10T11:05:20Z</TimeStamp></Header><Body><ProvisioningEntity name='subscriber'><ProvisioningDataItem name='BillingId'>#{imsi}</ProvisioningDataItem></ProvisioningEntity></Body></ProvisioningRequest>"
    uri = URI(rimurl)
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = http.post(uri.path, rim_xml, {'Content-Type' => 'text/xml', 'Content-Length' => rim_xml.length.to_s, "User-Agent" => "VAS-UCIP/3.1/1.0", "Connection" => "keep-alive" })
    if res.code == '200'
      xmldoc = Document.new res.body
      puts xmldoc.methods
      xmldoc.node("//ProvisioningReply/Body/ProvisioningEntity/ProvisioningDataItem[@name='ErrorCode']")
    else 
      return false
    end

  end
end
