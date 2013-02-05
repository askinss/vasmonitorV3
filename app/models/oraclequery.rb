require 'oci8'
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
    puts "This is connection url #{url}"
    puts "This is username #{username}"
    puts "This is password #{password}"
    @conn = OCI8.new(username, password, url)
  end

  #Accepts :query_response and a query condition which would be
  #passed to the query_response method and returns an hash in the
  #format {:serviceplanid_servicetype => count(serviceplanid)}
  def query_block(block, query)
    a,total_hash = [],Hash.new
    returned_array = block.call(a, query)
    returned_array.each do |vals|
      total_hash[modify!(vals)] = vals[2].to_i
    end
    total_hash
  end

  #the method that executes an oracle query with an empty array
  #expected and the condition to evaluate
  def query_response(array_to_return, condition)
    @conn.exec( "select serviceplanid,servicetype,count(serviceplanid) from subscriber where "+ condition + "  group by serviceplanid,servicetype" ) { |x| array_to_return << x }
    array_to_return
  end

  #Returns all the plans subscribed to from the subscriber table in
  #the form :serviceplanid_servicetype as an array
  def shortcodes
    a = []
    @conn.exec("select unique serviceplanid,servicetype from subscriber") { |x| a << x }
    a.map { |x| modify! x }
  end

  #Returns all the active subscribers in the Subscriber table through
  #the query_block method
  def total_active
    query_block method(:query_response), "statusid = 'Active'"
  end

  #Returns all the deactivated subscribers in the Subscriber table through
  #the query_block method
  def total_deactivated
    query_block method(:query_response), "statusid = 'Deactivated'"
  end

  #Returns the total activations from the previous day in the Subscriber table through the query_block method
  def total_activation
    query_block method(:query_response), "statusid = 'Active' and trunc(last_subscription_date) = trunc(sysdate - 1)" 
  end

  #Returns the total deactivations from the previous day in the Subscriber table through the query_block method
  def total_deactivation
    query_block method(:query_response), "statusid = 'Deactivated' and trunc(last_subscription_date) = trunc(sysdate - 1)" 
  end

  #Returns all renewals from the previous day in the Subscriber table through the query_block method
  def renewal
    query_block method(:query_response),"trunc(date_created) != trunc(sysdate - 1) and trunc(last_subscription_date) = trunc(sysdate - 1) and statusid = 'Active'"
  end

  #Returns all fresh activations from the previous day in the Subscriber table through the query_block method
  def fresh_activation
    query_block method(:query_response), "trunc(date_created) = trunc(sysdate - 1) and trunc(last_subscription_date) = trunc(sysdate - 1) and statusid = 'Active'"
  end

  #Returns all the subscribers in the Subscriber table through the query_block method (msisdn = msisdn) is the condition used here as there is no need to overwrite the query_block method
  def total
    query_block method(:query_response), "msisdn = msisdn"
  end
end
