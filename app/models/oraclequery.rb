require 'oci8'
require 'csv'
class Oraclequery
  include Airtel

  def initialize
    user = Utilities.load_config['oracle_user']
    pass = Utilities.load_config['oracle_password']
    ip = Utilities.load_config['oracle_ip'] 
    sid = Utilities.load_config['oracle_sid']
    username = "#{user}" 
    password = "#{pass}"
    url = "#{ip}" + "/" + "#{sid}"
    @conn = OCI8.new(username, password, url)
  end

  #Accepts :query_response and a query condition which would be
  #passed to the query_response method and returns an hash in the
  #format {:serviceplanid_servicetype => count(serviceplanid)}
  def query_block(block, query, subscriber_type = nil)
    a,total_hash = [],Hash.new
    returned_array = block.call(a, query, subscriber_type)
    if (subscriber_type == "shortcode")
      returned_array.each do |vals|
        total_hash["shortcode#{vals[0]}".to_sym] = vals[1].to_i
      end
    else
      returned_array.each do |vals|
        total_hash["#{subscriber_type}#{modify!(vals).to_s}".to_sym] = vals[2].to_i
      end
    end
    total_hash
  end

  #the method that executes an oracle query with an empty array
  #expected and the condition to evaluate
  def query_response(array_to_return, condition, subscriber_type)
    if (subscriber_type == "prepaid")
      CSV.open(File.join(Rails.root, 'dumps',"#{caller[2][/`([^']*)'/, 1]}#{subscriber_type}.csv"), 'ab') { |f| @conn.exec("select * from subscriber where prepaidsubscriber = 1 and #{condition}") { |sub| f << sub } } if Utilities.load_config['enable_csv']
      @conn.exec( "select serviceplanid,servicetype,count(serviceplanid) from subscriber where prepaidsubscriber = 1 and "+ condition + "  group by serviceplanid,servicetype" ) { |x| array_to_return << x }
      array_to_return
    elsif (subscriber_type == "postpaid")
      CSV.open(File.join(Rails.root, 'dumps',"#{caller[2][/`([^']*)'/, 1]}#{subscriber_type}.csv"), 'ab') { |f| @conn.exec("select * from subscriber where postpaidsubscriber = 1 and #{condition}") { |sub| f << sub } } if Utilities.load_config['enable_csv']
      @conn.exec( "select serviceplanid,servicetype,count(serviceplanid) from subscriber where postpaidsubscriber = 1 and "+ condition + "  group by serviceplanid,servicetype" ) { |x| array_to_return << x }
      array_to_return
    elsif (subscriber_type == "shortcode")
      @conn.exec( "select shortcode,count(shortcode) from subscriber where "+ condition + " group by shortcode" ) { |x| array_to_return << x }
      array_to_return
    else
      CSV.open(File.join(Rails.root, 'dumps',"#{caller[2][/`([^']*)'/, 1]}#{subscriber_type}.csv"), 'ab') { |f| @conn.exec("select * from subscriber where #{condition}") { |sub| f << sub } } if Utilities.load_config['enable_csv']
      @conn.exec( "select serviceplanid,servicetype,count(serviceplanid) from subscriber where "+ condition + "  group by serviceplanid,servicetype" ) { |x| array_to_return << x }
      array_to_return
    end  
  end

  def shortcodes
    a = []
    @conn.exec("select unique shortcode from subscriber") { |x| a << x }
    a.map { |x| "shortcode#{x.join}".to_sym }
  end

  #Returns all the plans subscribed to from the subscriber table in the form :serviceplanid_servicetype as an array, for prepaid subscriber it is :serviceplanid_servicetype_prepaid, for postpaid subscriber it is :serviceplanid_servicetype_postpaid
  def serviceplan(subscriber_type = nil)
    a = []
    if subscriber_type == "shortcode"
      b = shortcodes 
    elsif subscriber_type.nil?
      @conn.exec("select unique serviceplanid,servicetype from subscriber") { |x| a << x }
      b = a.map { |x| "#{subscriber_type}#{modify! x}".to_sym }
    else
      @conn.exec("select unique serviceplanid,servicetype from subscriber where #{subscriber_type}subscriber = 1") { |x| a << x }
      b = a.map { |x| "#{subscriber_type}#{modify! x}".to_sym  }
    end
    b
  end


  #Returns count of all the active subscribers in the Subscriber table through
  #the query_block method
  def total_active(subscriber_type = nil)
    query_block method(:query_response), "statusid = 'Active'", subscriber_type
  end

  #Returns all the deactivated subscribers in the Subscriber table through
  #the query_block method
  def total_deactivated(subscriber_type = nil)
    query_block method(:query_response), "statusid = 'Deactivated'", subscriber_type
  end

  #Returns the total activations from the previous day in the Subscriber table through the query_block method
  def total_activation(subscriber_type = nil)
    query_block method(:query_response), "statusid = 'Active' and trunc(last_subscription_date) = trunc(sysdate - 1)", subscriber_type 
  end

  #Returns the total deactivations from the previous day in the Subscriber table through the query_block method
  def total_deactivation(subscriber_type = nil)
    query_block method(:query_response), "statusid = 'Deactivated' and trunc(last_subscription_date) = trunc(sysdate - 1)", subscriber_type 
  end

  #Returns all renewals from the previous day in the Subscriber table through the query_block method
  def renewal(subscriber_type = nil)
    query_block method(:query_response),"trunc(date_created) != trunc(sysdate - 1) and trunc(last_subscription_date) = trunc(sysdate - 1) and statusid = 'Active'", subscriber_type
  end

  #Returns all fresh activations from the previous day in the Subscriber table through the query_block method
  def fresh_activation(subscriber_type = nil)
    query_block method(:query_response), "trunc(date_created) = trunc(sysdate - 1) and trunc(last_subscription_date) = trunc(sysdate - 1) and statusid = 'Active'", subscriber_type
  end

  #Returns all the subscribers in the Subscriber table through the query_block method (msisdn = msisdn) is the condition used here as there is no need to overwrite the query_block method
  def total(subscriber_type = nil)
    query_block method(:query_response), "msisdn = msisdn", subscriber_type
  end
end
