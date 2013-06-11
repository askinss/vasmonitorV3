class Giveoneday

  def initialize
    @oracle = Oraclequery.new
    @oracle_connect = @oracle.conn
    @oracle_connect.autocommit = true
  end

  def conn
    @oracle_connect
  end

  def getSubStatus msisdn
    puts msisdn
    statusid = ""
    @oracle_connect.exec("select statusid from subscriber where (next_subscription_date - sysdate) < 7 and msisdn = \'#{msisdn}\'") do |x|
      puts "This is response from query #{x}"
      statusid = x[0]
    end
    statusid
  end

  def updateSubStatus msisdn
    @oracle_connect.exec("update subscriber set next_subscription_date = (next_subscription_date + 1) where msisdn = \'#{msisdn}\'")
    @oracle_connect.commit
    `curl '127.0.0.1:8051/blackberry/smsservice?msisdn=#{msisdn}&msg=status'`
  end

  def is_msisdn_active? statusid
    statusid == "Active"
  end

  def is_msisdn_deactivated? statusid
    statusid == "Deactivated"
  end

  def is_msisdn_not_existing? statusid
    statusid.empty?
  end

  def provision_one_day_free_plan_for_msisdn msisdn
    `curl '127.0.0.1:8051/blackberry/smsservice?msisdn=#{msisdn}&msg=bb1ayo'`
    @oracle_connect.exec("update subscriber set shortcode = 'bb1' where msisdn = \'#{msisdn}\'")
    @oracle_connect.commit
  end

  def determine_and_execute_action_for_subscriber_with_msisdn msisdn
    statusid = getSubStatus msisdn
    if is_msisdn_active? statusid
      updateSubStatus msisdn
      File.open('/home/bblite/gave_one_more_day_by_db_extension.txt', 'ab') { |file| file.puts msisdn }
    elsif is_msisdn_deactivated? statusid
      provision_one_day_free_plan_for_msisdn msisdn
      File.open('/home/bblite/gave_one_more_day_by_rim_provisioning_extension.txt', 'ab') { |file| file.puts msisdn }
    elsif is_msisdn_not_existing? statusid
      File.open('/home/bblite/no_record_of_msisdn_found_for_one_more_day.txt', 'ab') { |file| file.puts msisdn }
    else
      File.open('/home/bblite/no_record_of_msisdn_found_for_one_more_day.txt', 'ab') { |file| file.puts msisdn }
    end
  end

  class << self
    require 'csv'

    def getMsisdnFromCSV
      msisdn_array = []
      usemsisdn = ""
      usemsisdn << IO.read("/home/bblite/gave_one_more_day_by_rim_provisioning_extension.txt")
      usemsisdn << IO.read('/home/bblite/gave_one_more_day_by_rim_provisioning_extension.txt')
      usemsisdn << IO.read('/home/bblite/no_record_of_msisdn_found_for_one_more_day.txt')
      CSV.foreach('/home/bblite/BB_Subscribers_one_day_extension.csv') do |msisdn| 
        msisdn_array << msisdn[0] unless usemsisdn.include?(msisdn[0])
      end
      puts "There are #{msisdn_array.size} msisdns to be processed"
      msisdn_array
    end

    def process
      threads = []
      #getMsisdnFromCSV.each do |msisdn|
      getMsisdnFromCSV.each_slice(100).each do |msisdn_array|
        threads << Thread.new(msisdn_array) do |threaded_misidn_array|
          giveoneday = Giveoneday.new
          threaded_misidn_array.each do |msisdn|
            giveoneday.determine_and_execute_action_for_subscriber_with_msisdn msisdn
          end
          giveoneday.logoff
        end
      end
      threads.each { |thread| thread.join }
    end
  end

  def logoff
    @oracle_connect.logoff
  end

end
