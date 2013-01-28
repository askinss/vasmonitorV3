class Report
  include Airtel
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  def method_missing(method_sym, *arguments)
    begin
      puts method_sym
      puts arguments[0].inspect
      sum_of_hash(7, arguments[0][0], method_sym.to_s)
    rescue
      super
    end
  end

  def self.report_hash(no_of_days, shortcode, provisioning_type)
    hash_of_report = {}
    array_of_counts = []
    iterator = 0
    start_date = 0
    self.where(created_at: { '$gte' => (Time.now - no_of_days.to_i * 86400), '$lte' => Time.now }, description: provisioning_type).each do |x| 
      (array_of_counts << x.attributes[shortcode.to_s])
      start_date = (x.created_at.to_i - 86400) if (iterator == 0)
      iterator += 1
    end
    hash_of_report[shortcode] = [start_date,array_of_counts]
    hash_of_report
  end

  def self.sum_of_hash(no_of_days, shortcode, description)
    begin
      Report.where(created_at: { '$gte' => (Time.now - no_of_days.to_i * 86400), '$lte' => Time.now }, description: description).sum(shortcode.to_sym).to_i
    rescue => e 
      e.backtrace
      return 0
    end
  end

  def self.provisioning_type
    (self.all.map { |x| x.description.gsub("_"," ").upcase }).uniq
  end

  def total_active
  end

end
