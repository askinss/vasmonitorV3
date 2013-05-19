class Monitor::Prepaidjobmonitor < Monitor::Monitorbase

  attr_writer :log_path

  def initialize
    super
    @smsmessage = "No record of completion of Prepaid Job was found in the last 2hours, please check"
    @timeout = 60
    @log_path = load_config['log_path']
  end

  def monitor
    raise "SDP-Scheduler is down, no process id found" if ps.empty?
    (return true) if (File.size @log_path) < 100000 #Return true if file size is less than 100kb
    found = false
    time = Time.now.strftime('%Y-%m-%d %H')
    time_in_last_hour = (Time.now - 3600).strftime('%Y-%m-%d %H')
    File.foreach(@log_path) { |x| (found = true; break) if x.match(/(#{time}|#{time_in_last_hour}).*Hourly\ Scheduler\ .*for\ this\ hour/) }
    return found
  end

  def action_for_success_response

  end

  def action_for_failure_response
    super
  end
end

