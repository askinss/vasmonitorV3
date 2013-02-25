require 'mysql2'
require 'csv'
class Mysqlquery
  include Airtel

  def initialize
    user = Utilities.load_config['mysql_user']
    pass = Utilities.load_config['mysql_password']
    ip = Utilities.load_config['mysql_ip'] 
    sid = Utilities.load_config['mysql_database']
    username = "#{user}" 
    password = "#{pass}"
    @conn = Mysql2::Client.new(:host => ip, :username => user, :password => pass, :database => sid)
  end

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

  def query_response(array_to_return, condition, subscriber_type)
    if (subscriber_type == "prepaid")
      CSV.open(File.join(Rails.root, 'dumps',"#{caller[2][/`([^']*)'/, 1]}#{subscriber_type}.csv"), 'ab') { |f| @conn.query("select * from subscriber where prepaidsubscriber = 1 and #{condition}").each { |sub| f << sub.values } } if Utilities.load_config['enable_csv']
      @conn.query( "select serviceplanid,servicetype,count(serviceplanid) from subscriber where prepaidsubscriber = 1 and "+ condition + "  group by serviceplanid,servicetype" ).each { |x| array_to_return << x.values }
      array_to_return
    elsif (subscriber_type == "postpaid")
      CSV.open(File.join(Rails.root, 'dumps',"#{caller[2][/`([^']*)'/, 1]}#{subscriber_type}.csv"), 'ab') { |f| @conn.query("select * from subscriber where postpaidsubscriber = 1 and #{condition}").each { |sub| f << sub.values } } if Utilities.load_config['enable_csv']
      @conn.query( "select serviceplanid,servicetype,count(serviceplanid) from subscriber where postpaidsubscriber = 1 and "+ condition + "  group by serviceplanid,servicetype" ).each { |x| array_to_return << x.values }
      array_to_return
    elsif (subscriber_type == "shortcode")
      @conn.query( "select shortcode,count(shortcode) from subscriber where "+ condition + " group by shortcode" ).each { |x| array_to_return << x.values }
      array_to_return
    else
      CSV.open(File.join(Rails.root, 'dumps',"#{caller[2][/`([^']*)'/, 1]}#{subscriber_type}.csv"), 'ab') { |f| @conn.query("select * from subscriber where #{condition}").each { |sub| f << sub.values } } if Utilities.load_config['enable_csv']
      @conn.query( "select serviceplanid,servicetype,count(serviceplanid) from subscriber where "+ condition + "  group by serviceplanid,servicetype" ).each { |x| array_to_return << x.values }
      array_to_return
    end
  end

  def shortcodes
    a = []
    @conn.query("select distinct shortcode from subscriber").each { |x| a << x.values }
    a.map { |x| "shortcode#{x.join}".to_sym }
  end
  
  #Returns all the plans subscribed to from the subscriber table in the form :serviceplanid_servicetype as an array, for prepaid subscriber it is :serviceplanid_servicetype_prepaid, for postpaid subscriber it is :serviceplanid_servicetype_postpaid
  def serviceplan(subscriber_type = nil)
    a = []
    if subscriber_type == "shortcode"
      b = shortcodes 
    elsif subscriber_type.nil?
      @conn.query("select distinct serviceplanid,servicetype from subscriber").each { |x| a << x }
      b = a.map { |x| modify! x.values }
    else
      @conn.query("select distinct serviceplanid,servicetype from subscriber where #{subscriber_type}subscriber = 1").each { |x| a << x }
      b = a.map { |x| "#{subscriber_type}#{modify! x.values}".to_sym }
    end
    b 
  end

  def total_active(subscriber_type = nil)
    query_block method(:query_response), "statusid = 'Active'", subscriber_type
  end

  def total_deactivated(subscriber_type = nil)
    query_block method(:query_response), "statusid = 'Deactivated'", subscriber_type
  end
  
  def total_activation(subscriber_type = nil)
    query_block method(:query_response), "statusid = 'Active' and cast(last_subscription_date as date) = CAST(NOW() - INTERVAL 1 DAY AS DATE)", subscriber_type
  end

  def total_deactivation(subscriber_type = nil)
    query_block method(:query_response), "statusid = 'Deactivated' and cast(last_subscription_date as date) = CAST(NOW() - INTERVAL 1 DAY AS DATE)", subscriber_type
  end

  def renewal(subscriber_type = nil)
    query_block method(:query_response),"cast(date_created as date) != CAST(NOW() - INTERVAL 1 DAY AS DATE) and cast(last_subscription_date as date) = CAST(NOW() - INTERVAL 1 DAY AS DATE) and statusid = 'Active'", subscriber_type
  end

  def fresh_activation(subscriber_type = nil)
    query_block method(:query_response),"cast(date_created as date)!= CAST(NOW() - INTERVAL 1 DAY AS DATE) and cast(last_subscription_date as date) = CAST(NOW() - INTERVAL 1 DAY AS DATE) and statusid = 'Active'", subscriber_type
  end

  def total(subscriber_type = nil)
    query_block method(:query_response), "msisdn = msisdn", subscriber_type
  end

end
  
