class Messagebuilder
  include Airtel
  def self.build_message(*args)
    message = "<h3 style=\"color:blue;text-align:center;font:5px\">ACTIVE AND DEACTIVATED SUBSCRIBERS AT #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}</h3>"
    message << Tablegenerator.new(args[0],args[1]).generate_table
    message << ("<br />" * 3)
    if args.size == 3 
      message << "<h3 style=\"color:blue;text-align:center;font:5px\"> SUMMARY of PROVISIONING for #{yesterday}</h3>"
      puts args[2]
      message << Tablegenerator.new(args[0],args[2]).generate_table
    elsif (args.size == 4) && (args[3] == "_weekly")
      message << "<h3 style=\"color:blue;text-align:center;font:5px\"> SUMMARY of PROVISIONING for  #{last_week}</h3>"
      message << Tablegenerator.new(args[0],args[2]).generate_table
      puts args[2]
    elsif (args.size == 4) && (args[3] == "_monthly")
      puts args[2]
      message << "<h3 style=\"color:blue;text-align:center;font:5px\"> SUMMARY of PROVISIONING for  #{last_month_to_s}</h3>"
      message << Tablegenerator.new(args[0],args[2]).generate_table
    end
    message << ("<br />" * 3)
    puts message
    message
  end
end
