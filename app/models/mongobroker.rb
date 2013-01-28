class Mongobroker
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  field :node
  field :status
  field :value, :type => Float
  field :timestamp
  field :created_at

  def self.response_time(nodename, span)
    array_of_response_times = []
    if span == "hour"
      #30 seconds is added to make up for the lost 5mins, this is
      #following the assumption that the query would not occur on
      #exactly the second when the insert was done
      self.where(node: nodename, created_at: { '$gte' => (Time.now - 3630), '$lte' => Time.now }).each { |noden| array_of_response_times << noden.value.to_f.round(4) }
    elsif span == "day"
      self.where(node: nodename, created_at: { '$gte' => (Time.now - 86430), '$lte' => Time.now }).each_slice(12) {|chunks_of_12| break if (chunks_of_12.size < 12); sum_of_response_times = 0; chunks_of_12.each { |y| sum_of_response_times += y.value.to_f }; array_of_response_times << (sum_of_response_times/12).round(4) }
    end
    return array_of_response_times
  end

  def self.nodes
    (self.all.map { |x| x.node }).uniq
  end

  def self.hashmap_response
    hash = Hash.new
    hash[:air_hourly] = self.response_time("air", "hour")
    hash[:air_day] = self.response_time("air", "day")
    hash[:ema_hour] = self.response_time("ema", "hour")
    hash[:ema_day] = self.response_time("ema", "day")
    hash[:broker_hourly] = self.response_time("broker", "hour")
    hash[:broker_day] = self.response_time("broker", "day")
    hash[:rim_hourly] = self.response_time("rim", "hour")
    hash[:rim_day] = self.response_time("rim", "day")
    hash
  end
end
