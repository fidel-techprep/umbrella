require "http"
require "erb"
require "json"
include ERB::Util

# Retrieve API keys from the environment
GMAPS_KEY, PIRATE_WEATHER_KEY = ENV.fetch("GMAPS_KEY"), ENV.fetch("PIRATE_WEATHER_KEY")

# Display welcome message


puts "*   __   __  __   __  _______  ______    _______  ___      ___      _______   *   _______  _______  _______   *";
puts "   |  | |  ||  |_|  ||  _    ||    _ |  |       ||   |    |   |    |   _   |     |   _   ||       ||       |   ";
puts "   |  | |  ||       || |_|   ||   | ||  |    ___||   |    |   |    |  |_|  |     |  |_|  ||    _  ||    _  |   ";
puts "   |  |_|  ||       ||       ||   |_||_ |   |___ |   |    |   |    |       |     |       ||   |_| ||   |_| |   ";
puts "   |       ||       ||  _   | |    __  ||    ___||   |___ |   |___ |       |     |       ||    ___||    ___|   ";
puts "   |       || ||_|| || |_|   ||   |  | ||   |___ |       ||       ||   _   |     |   _   ||   |    |   |       ";
puts "   |_______||_|   |_||_______||___|  |_||_______||_______||_______||__| |__|     |__| |__||___|    |___|       ";

puts "\n                                         Welcome to the Umbrella App!\n"


# Get user location and display wait message
print "Please enter your location: "
user_location = gets.chomp
puts "Please hang tight while we work it out behind the scenes..."

# Construct Google Maps' URL
gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{url_encode(user_location)}&key=#{GMAPS_KEY}"

# GET coordinates from Google Maps API
raw_location = JSON.parse(HTTP.get(gmaps_url))

abort "Whoa! We don't know that place :( Bye!" if raw_location["results"].empty?

coords = raw_location["results"][0]["geometry"]["location"]
full_location_name = raw_location["results"][0]["formatted_address"]

# Construct Pirate Weather's URL
p_weather_url = "https://api.pirateweather.net/forecast/#{PIRATE_WEATHER_KEY}/#{coords["lat"]},#{coords["lng"]}"

# Break down weather data
raw_forecast = JSON.parse(HTTP.get(p_weather_url))
summary = raw_forecast["hourly"]["data"][0]["summary"]
temperature = raw_forecast["hourly"]["data"][0]["temperature"]
precipitation_prob = (raw_forecast["hourly"]["data"][0]["precipProbability"] * 100).to_i
wind_speed = raw_forecast["hourly"]["data"][0]["windSpeed"]
humidity = (raw_forecast["hourly"]["data"][0]["humidity"] * 100).to_i
uv_index = raw_forecast["hourly"]["data"][0]["uvIndex"].to_i
data_12hr_window = raw_forecast["hourly"]["data"][1..12]



# Display forecast data
puts "-" * 112
puts "                                        Next hour forecast for #{full_location_name.upcase}"
puts "-" * 112
puts "                                                       #{summary.upcase}"
puts "                                        with a temperature of #{temperature}°F (#{((temperature - 32) * (5.0 / 9.0)).round(2)}°C)"
puts "-" * 112 
puts "      Precipitation Probability: #{precipitation_prob}%    |    Humidity: #{humidity}%     |    Wind Speed: #{wind_speed} mph    |    UV Index: #{uv_index}"

# Calculate 12-hour window precipitation
future_precip = data_12hr_window.each{|hour| hour["hour"] = data_12hr_window.index(hour) + 1}
future_precip.select!{|hour| hour["precipProbability"] >= 0.10}

if !future_precip.empty?
  puts "-" * 112
  puts "                                   Precipitation Probability for the next 12 Hours"
  puts "-" * 112 

  precip_string =  " " * 40

  future_precip.each_with_index do | hour, index|
    #puts "
                                                  
    precip_string += "#{hour["hour"]}hrs: #{(hour["precipProbability"] * 100).to_i}%   "
    precip_string += ("\n" + (" " * 40)) if index > 0 && (index + 1) % 3 == 0
    precip_string += (("-" * 36) + "\n" + (" " * 40)) if index > 0 && (index + 1) % 3 == 0
  end 
  
  puts precip_string
  puts "-" * 112
  puts "-" * 112
  puts "                                 *-*-*-*-*  YOU MAY WANT TO CARRY AN UMBRELLA!!  *-*-*-*-*"
  puts "-" * 112
else 
  puts "-" * 112
  puts "-" * 112
  puts "                                  😄😄😄  You probably won't need an umbrella today!  😄😄😄"
  puts "-" * 112
end
