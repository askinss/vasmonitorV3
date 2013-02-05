require 'mysql2'
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

  def query_block(block, query)
    a,total_hash = [],Hash.new
    returned_array = block.call(a, query)
    returned_array.each do |vals|
      total_hash[modify!(vals)] = vals[2].to_i
    end
    total_hash
  end

  def query_response(array_to_return, condition)
    @conn.query( "select serviceplanid,servicetype,count(serviceplanid) from subscriber where "+ condition + "  group by serviceplanid,servicetype" ).each { |x| array_to_return << x.values }
    array_to_return
  end

  def shortcodes
    a = []
    @conn.query("select distinct serviceplanid,servicetype from subscriber").each { |x| a << x.values }
    a.map { |x| modify! x }
  end

  def total_active
    query_block method(:query_response), "statusid = 'Active'"
  end

  def total_deactivated
    query_block method(:query_response), "statusid = 'Deactivated'"
  end
  
  def total_activation
    query_block method(:query_response), "statusid = 'Active' and cast(last_subscription_date as date) = CAST(NOW() - INTERVAL 1 DAY AS DATE)" 
  end

  def total_deactivation
    query_block method(:query_response), "statusid = 'Deactivated' and cast(last_subscription_date as date) = CAST(NOW() - INTERVAL 1 DAY AS DATE)"
  end

  def renewal
    query_block method(:query_response),"cast(date_created as date) != CAST(NOW() - INTERVAL 1 DAY AS DATE) and cast(last_subscription_date as date) = CAST(NOW() - INTERVAL 1 DAY AS DATE) and statusid = 'Active'"
  end

  def fresh_activation
    query_block method(:query_response),"cast(date_created as date) = CAST(NOW() - INTERVAL 1 DAY AS DATE) and cast(last_subscription_date as date) = CAST(NOW() - INTERVAL 1 DAY AS DATE) and statusid = 'Active'"
  end

  def total
    query_block method(:query_response), "msisdn = msisdn"
  end

end
  
