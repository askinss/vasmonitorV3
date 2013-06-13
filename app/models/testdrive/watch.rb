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
      puts "Processing file #{file}"
      filename = File.join('/home/bblite/bbtestdrivepromo',file)
      File.foreach(filename) do |msisdn_from_file|
      puts "Processing msisdn #{msisdn_from_file}"
        msisdn = msisdn_from_file.chomp
        if validate msisdn
          insert(msisdn) ? (Utilities.send_sms(Utilities.config['bbtestdrivepromo_message'], msisdn); write_processed_record_to_file msisdn) : write_failed_record_to_file(msisdn) #todo create bbtestdrivepromo_message property in the config.yml file
        else
          write_failed_record_to_file msisdn
        end
      end
      File.delete(filename)
    end
  end

  def validate msisdn
    msisdn.match /^233\d{8}$/
  end

  def write_processed_record_to_file msisdn
    File.open("/home/bblite/bbtestdrivepromo_processed/success_#{Time.now.strftime("%Y-%m-%d")}", 'ab') { |file| file.puts msisdn }
  end

  def write_failed_record_to_file msisdn
    File.open("/home/bblite/bbtestdrivepromo_processed/failed_#{Time.now.strftime("%Y-%m-%d")}", 'ab') { |file| file.puts msisdn }
  end

  def insert msisdn
    @oracleconnect.exec("insert into bbtestdrivepromoinitial (id,misdn,status), values(\'#{SecureRandom.uuid}\',\'#{msisdn}\', 'available')")
    @oracleconnect.commit
  end

  class << self
    require 'rb-inotify'
    def watch
      testdrive = Testdrive::Watch.new
      notifier = INotify::Notifier.new
      notifier.watch("/home/bblite/bbtestdrivepromo", :create, :delete, :modify) { puts "Started processing files in /home/bblite/bbtestdrivepromo"; testdrive.process }
      notifier.run
    end
  end
end
