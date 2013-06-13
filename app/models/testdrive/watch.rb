class Testdrive::Watch
  require "securerandom"
  attr_accessor :oracleconnect
  def initialize
    @oracle = Oraclequery.new
    @oracleconnect = @oracle.conn
    @oracleconnect.autocommit = true
  end

  def process
    Dir.foreach('/home/bblite/bbtestdrivepromo') do |file|
      next if file == '.' or file == '..'
      puts "Processing file #{file}"
      filename = File.join('/home/bblite/bbtestdrivepromo',file)
      File.foreach(filename) do |msisdn_from_file|
      puts "Processing msisdn #{msisdn_from_file}"
        msisdn = msisdn_from_file.chomp
        if validate msisdn
          insert(msisdn) ? (Utilities.sendsms(Utilities.load_config['bbtestdrivepromo_message'], msisdn); write_processed_record_to_file msisdn) : write_failed_record_to_file(msisdn)
        else
          write_failed_record_to_file msisdn
        end
      end
      File.delete(filename)
    end
  end

  def validate msisdn
    msisdn.match /^233\d{9}$/
  end

  def write_processed_record_to_file msisdn
    File.open("/home/bblite/bbtestdrivepromo_processed/success_#{Time.now.strftime("%Y-%m-%d")}", 'ab') { |file| file.puts msisdn }
  end

  def write_failed_record_to_file msisdn
    File.open("/home/bblite/bbtestdrivepromo_processed/failed_#{Time.now.strftime("%Y-%m-%d")}", 'ab') { |file| file.puts msisdn }
  end

  def insert msisdn
    @oracleconnect.exec("insert into bbtestdrivepromoinitial (id,MSISDN,status,date_created) VALUES(\'#{SecureRandom.uuid}\',\'#{msisdn}\', 'available', sysdate)")
    @oracleconnect.commit
  end

  def logoff
    @oracle.logoff
  end

  class << self
    require 'rb-inotify'
    def watch
      testdrive = Testdrive::Watch.new
      notifier = INotify::Notifier.new
      notifier.watch("/home/bblite/bbtestdrivepromo", :create, :delete, :modify) { puts "Started processing files in /home/bblite/bbtestdrivepromo"; testdrive.process; testdrive.logoff }
      notifier.run
    end
  end
end
