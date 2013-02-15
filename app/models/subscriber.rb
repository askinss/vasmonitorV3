class Subscriber

  include Airtel

  def initialize(subscribertype = nil)
    @model = eval("#{Utilities.load_config['adapter'].capitalize}query").new
    @subscriber_type = subscribertype
    @serviceplan = @model.serviceplan(subscribertype)
  end

  def serviceplan
    @serviceplan
  end

  def query_helper(method) #this method is to help return 0 for queries that do not return serviceplan or shortcodes
    #@model.send(method.to_sym).
    orig_response = @model.send(method, @subscriber_type)
    serviceplan.each { |service| (orig_response[service] = 0) unless orig_response.keys.to_s.include?("#{service.to_s}") }
    orig_response
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

  def self.method_missing(method, *arg)
    begin
      queryclass = eval(arg[0].gsub("from_","").capitalize + "query").new
      shortcodes = queryclass.serviceplan
      h = Hash.new
      if (method == :shortcodes)
        queryclass.shortcodes
      elsif (method == :serviceplan)
        queryclass.serviceplan
      elsif method.to_s.include?("weekly")
        arr = shortcodes.map { |shortcode| Report.sum_of_hash(7, shortcode.to_sym, method.to_s.gsub("_weekly","")) }
        h[method.to_s.gsub("_weekly","").to_sym] = arr
        h
      elsif method.to_s.include?("monthly")
        arr = shortcodes.map { |shortcode| Report.sum_of_hash(30, shortcode.to_sym, method.to_s.gsub("_monthly","")) }
        h[method.to_s.gsub("_monthly","").to_sym] = arr
        h
      elsif (arg.size == 1)
        arr = shortcodes.map { |shortcode| queryclass.send(method.to_sym)[shortcode].nil? ? 0 : queryclass.send(method.to_sym)[shortcode] }
        h[method.to_sym] = arr
        h
      elsif (arg[1] == "to_mongo")
        a = queryclass.send(method.to_sym)
        a[:description] = method.to_s
        begin
          Report.create!(a)
        rescue => e
          e.backtrace
        end
      end
    rescue
      super
    end
  end
end
