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

  end

  def shortcodes
    a = []
    @conn.query("select distinct serviceplanid,servicetype from subscriber") { |x| a << x.values }
    b = a.flatten
    b.map { |x| modify! x }
  end

  def total_active
  end

  def total_deactivated
  end
  
  def total_activation
  end

  def total_deactivation
  end

  def renewal
  end

  def fresh_activation
  end

  def total
  end

end
  
