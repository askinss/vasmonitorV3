require 'logger'
require 'socket'
module Airtel
  COMMON_YEAR_DAYS_IN_MONTH = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  def yesterday
    (Time.now - 86400).strftime("%d/%m/%Y")
  end


  def current_ip
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily
    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end

  def first_day_of_the_month?
    Time.now.strftime("%d") == "01"
  end

  def last_month_to_s
    (Time.now - 86400).strftime("%B-%Y") #works only on the last day of the month
  end

  def last_month
    (Time.now - 86400).strftime("%Y-%m")
  end

  def today_date
    Time.now.strftime("%d/%m/%Y")
  end

  def last_week
    (Time.now - 86400).strftime("Week %U %B-%Y")
  end

  def number_of_days_in_last_month
    (Date.new(Time.now.year,12,31).to_date<<(12-last_month_to_i)).day
  end

  def time_between_700am_to_730am?
    t = Time.now
    early = Time.new(t.year, t.month, t.day, 7, 0, 0, t.utc_offset)
    late  = Time.new(t.year, t.month, t.day, 7, 30, 0, t.utc_offset)
    t.between?(early, late)
  end

  def days_in_last_month(month = (Time.now - 86400).strftime("%m").to_i, year = (Time.now - 86400).year)
    return 29 if month == 2 && Date.gregorian_leap?(year)
    COMMON_YEAR_DAYS_IN_MONTH[month]
  end

  def modify!(shortcode)
    (shortcode[0].gsub(" ",'') + "_" + shortcode[1].to_s).to_sym
  end
end


