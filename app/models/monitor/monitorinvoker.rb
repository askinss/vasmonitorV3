class Monitor::Monitorinvoker
  def self.invoke
    Dir.foreach(File.join(Rails.root, "app/models/monitor")) do |file|
      if (file =~ /^\w+monitor\.rb$/)
        puts file
        nodename = file.gsub(".rb", "")
        node = eval("Monitor::" + nodename.capitalize).new 
        puts "checking #{nodename}"
        start_time = Time.now
        block_response = false
        begin
          block_response = Timeout::timeout(node.timeout) { node.monitor }
        rescue Timeout::Error => e
          Rails.logger.error e.backtrace.join("\n")
          node.smsmessage = "#{nodename.gsub("monitor", "").capitalize} did not respond in #{node.timeout} seconds, please investigate"
        rescue Exception => e
          unless e.instance_of?(Timeout::Error)
            node.smsmessage = "#{nodename.gsub("monitor", "").capitalize} responded with:\n\n #{e.message} error message, please check"
            Rails.logger.error e.backtrace.join("\n")
          end
        end
        end_time = Time.now
        time_taken = (end_time - start_time).round(4)
        node.action_for_failure_response unless block_response
        Mongobroker.create!(:value => time_taken, :node => nodename)
      end
    end
  end
end
