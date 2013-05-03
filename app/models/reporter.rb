class Reporter
  include Airtel
  def initialize
    @subject = "Daily Reports for #{yesterday}"
    @configured_subscriber_types = Utilities.load_config['subscriber_type'].split(",") << nil
    @provisioning_types = %w[total_active total_deactivated total fresh_activation renewal total_activation total_deactivation]
  end

  def daily
    message = ''
    @configured_subscriber_types.each do |st|
      subscribercounts = Subscriber.new(st)
      serviceplan = subscribercounts.serviceplan.map { |x| (st.nil? ? x : x.to_s.gsub(st, "")) }
      total_active = subscribercounts.total_active
      total_deactivated = subscribercounts.total_deactivated
      total = subscribercounts.total
      fresh_activation = subscribercounts.fresh_activation
      renewal = subscribercounts.renewal
      total_activation = subscribercounts.total_activation
      total_deactivation = subscribercounts.total_deactivation
      active_and_deactivated = {:total_active => total_active.values, :total_deactivated => total_deactivated.values, :total => total.values}
      yesterday_activations = { :fresh_activation => fresh_activation.values, :renewal => renewal.values, :total_deactivation => total_deactivation.values, :total_activation => total_activation.values}
      begin
        @provisioning_types.each { |hash| eval(hash)[:description] = hash; eval(hash)[:rimservice_or_shortcode] = st;Report.create eval(hash) }
      rescue => e
        puts e.backtrace
      end
      message << Messagebuilder.build_message(serviceplan, active_and_deactivated, (st.nil? ? "" : st) , yesterday_activations)
      subscribercounts.logoff
    end
    message
  end

  def weekly
    message = ''
    arr = []
    @configured_subscriber_types.each do |st|
      subscribercounts = Subscriber.new(st)
      serviceplan = subscribercounts.serviceplan
      total_active = subscribercounts.total_active
      total_deactivated = subscribercounts.total_deactivated
      total = subscribercounts.total
      lastweek_sums = {}
      active_and_deactivated = {:total_active => total_active.values, :total_deactivated => total_deactivated.values, :total => total.values}
      %w[fresh_activation renewal total_activation total_deactivation].each do |type|
        lastweek_sums[type] = serviceplan.map { |shortcode| p Report.sum_of_hash(7,shortcode,type); Report.sum_of_hash(7,shortcode,type) }
      end
      message << Messagebuilder.build_message(serviceplan, active_and_deactivated, (st.nil? ? "" : st) , lastweek_sums, "weekly")
    end
    message
  end

  def sms_report
    sub = Subscriber.new
    Utilities.sendsms "BB Subscriptions for #{yesterday}:\n Fresh Activations = #{sub.total_fresh_activation_count}\n Renewal= #{sub.total_renewal_count}\n Total Activation= #{sub.total_activation_count}\n Total Deactivation: #{sub.total_deactivation_count}", Utilities.load_config['receipients_numbers']
    sub.logoff
  end

  def report
    sms_report if Utilities.load_config['send_sms_report']
    message ||= daily #using this to make daily run
    if Utilities.load_config['enable_csv']
      trans = Transaction.new
      activity = Activity.new
      trans.generate if Utilities.load_config['enable_transaction_report']
      activity.generate if Utilities.load_config['enable_activity_report']
      Utilities.zip
      Utilities.send_att(@subject,message)
    else
      Utilities.send_message(@subject,daily,'VAS REPORTS')
    end
  end
end


