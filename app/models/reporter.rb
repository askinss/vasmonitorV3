class Reporter
  include Airtel
  def initialize
    @subject = "Daily Reports for #{yesterday}"
  end

  def sender_param(param, period = "")
    active_and_deactivated = Hash.new
    others = Hash.new
    active_and_deactivated.merge!(Subscriber.send(("total_active").to_sym, "from_oracle"))
    active_and_deactivated.merge!(Subscriber.send(("total_deactivated").to_sym,"from_oracle"))
    active_and_deactivated.merge!(Subscriber.send(("total").to_sym,"from_oracle"))
    if period.empty?
      others.merge!(Subscriber.send(("fresh_activation" + period).to_sym,"from_oracle"))
      Subscriber.fresh_activation("from_oracle","to_mongo")
      others.merge!(Subscriber.send(("renewal" + period).to_sym,"from_oracle"))
      Subscriber.renewal("from_oracle","to_mongo")
      others.merge!(Subscriber.send(("total_activation" + period).to_sym,"from_oracle"))
      Subscriber.total_activation("from_oracle","to_mongo")
      others.merge!(Subscriber.send(("total_deactivation" + period).to_sym,"from_oracle"))
      Subscriber.total_deactivation("from_oracle","to_mongo")
      Utilities.send_message(@subject,Messagebuilder.build_message(Oraclequery.new.shortcodes, active_and_deactivated, others),'VAS REPORTS') 
    else
      others.merge!(Subscriber.send(("fresh_activation" + period).to_sym,"from_oracle"))
      others.merge!(Subscriber.send(("renewal" + period).to_sym,"from_oracle"))
      others.merge!(Subscriber.send(("total_activation" + period).to_sym,"from_oracle"))
      others.merge!(Subscriber.send(("total_deactivation" + period).to_sym,"from_oracle"))
      Utilities.send_message(@subject,Messagebuilder.build_message(Oraclequery.new.shortcodes, active_and_deactivated, others, period),'VAS REPORTS')
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

