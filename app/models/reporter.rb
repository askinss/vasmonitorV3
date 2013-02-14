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
        @provisioning_types.each { |hash| eval(hash)[:description] = hash ;Report.create eval(hash) }
      rescue => e
        puts e.backtrace
      end
      message << Messagebuilder.build_message(serviceplan, active_and_deactivated, (st.nil? ? "" : st) , yesterday_activations)
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

  def sender_param(param, period = "")
    active_and_deactivated = Hash.new
    others = Hash.new
    queryclass = eval(param.gsub("from_","").capitalize + "query").new
    active_and_deactivated.merge!(Subscriber.send(("total_active").to_sym, param))
    active_and_deactivated.merge!(Subscriber.send(("total_deactivated").to_sym,param))
    active_and_deactivated.merge!(Subscriber.send(("total").to_sym,param))
    if period.empty?
      others.merge!(Subscriber.send(("fresh_activation" + period).to_sym,param))
      Subscriber.fresh_activation(param,"to_mongo")
      others.merge!(Subscriber.send(("renewal" + period).to_sym,param))
      Subscriber.renewal(param,"to_mongo")
      others.merge!(Subscriber.send(("total_activation" + period).to_sym,param))
      Subscriber.total_activation(param,"to_mongo")
      others.merge!(Subscriber.send(("total_deactivation" + period).to_sym,param))
      Subscriber.total_deactivation(param,"to_mongo")
      Utilities.send_message(@subject,Messagebuilder.build_message(queryclass.shortcodes, active_and_deactivated, others),'VAS REPORTS') 
    else
      others.merge!(Subscriber.send(("fresh_activation" + period).to_sym,param))
      others.merge!(Subscriber.send(("renewal" + period).to_sym,param))
      others.merge!(Subscriber.send(("total_activation" + period).to_sym,param))
      others.merge!(Subscriber.send(("total_deactivation" + period).to_sym,param))
      Utilities.send_message(@subject,Messagebuilder.build_message(queryclass.shortcodes, active_and_deactivated, others, period),'VAS REPORTS')
    end
  end

  def report
    if Utilities.load_config['enable_csv']
      Utilities.zip
      Utilities.send_att(@subject,daily)
    else
      Utilities.send_message(@subject,daily,'VAS REPORTS')
    end
  end
end

