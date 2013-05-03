class Subscriber

  include Airtel

  def initialize(subscribertype = nil)
    @model =  model
    @subscriber_type = subscribertype
    @serviceplan = @model.serviceplan(subscribertype)
  end

  def serviceplan
    @serviceplan
  end

  def query_helper(method) #this method is to help return 0 for queries that do not return serviceplan or shortcodes
    #@model.send(method.to_sym).
    orig_response = @model.send(method, @subscriber_type)
    ordered_response = {}
    serviceplan.each { |service| ordered_response[service] = orig_response[service].nil? ? 0 : orig_response[service] }
    ordered_response
  end

  def shortcodes
    @model.shortcodes
  end

  def total_active
    query_helper __method__#__method__ is the same as the calling method(defined method, in this case total_active)
  end

  def total_deactivated
    query_helper __method__
  end

  def total_activation
    query_helper __method__
  end

  def total_deactivation
    query_helper __method__
  end

  def renewal
    query_helper __method__
  end

  def fresh_activation
    query_helper __method__
  end

  def total
    query_helper __method__
  end

  def conn
    @model.conn
  end

  def logoff
    @model.logoff
  end

  def total_fresh_activation_count
    @model.total_fresh_activation_count
  end

  def total_renewal_count
    @model.total_renewal_count
  end

  def total_deactivation_count
    @model.total_deactivation_count
  end
  
  def total_activation_count
    @model.total_activation_count
  end
end
