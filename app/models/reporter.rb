class Reporter
  include Airtel
  def initialize
    @subject = "Daily Reports for #{yesterday}"
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

  def report(param = "from_oracle")
    self.sender_param(param)
    if first_day_of_the_month?
      @subject = "Monthly reports for #{last_month_to_s}"
      self.sender_param(param, "_monthly")
    elsif Time.now.sunday?
      @subject = "Weekly reports for #{last_week}"
      self.sender_param(param, "_weekly")
    end
  end
end

