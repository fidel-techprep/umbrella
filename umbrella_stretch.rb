require "http"
require "erb"
require "json"
require "ascii_charts"
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

# GET data from Google Maps API
raw_location = JSON.parse(HTTP.get(gmaps_url))

# Abort execution if Google Maps API returns no results
abort "Whoa! We don't know that place :( Bye!" if raw_location["results"].empty?

# Get coordinates 
coords = raw_location["results"][0]["geometry"]["location"]
full_location_name = raw_location["results"][0]["formatted_address"]

# Construct Pirate Weather's URL
p_weather_url = "https://api.pirateweather.net/forecast/#{PIRATE_WEATHER_KEY}/#{coords["lat"]},#{coords["lng"]}"

# Break down weather data
raw_forecast = JSON.parse(HTTP.get(p_weather_url))["hourly"]["data"]
summary = raw_forecast[0]["summary"]
temperature = raw_forecast[0]["temperature"]
precipitation_prob = (raw_forecast[0]["precipProbability"] * 100).to_i
wind_speed = raw_forecast[0]["windSpeed"]
humidity = (raw_forecast[0]["humidity"] * 100).to_i
uv_index = raw_forecast[0]["uvIndex"].to_i

# Display forecast data
puts "-" * 112
puts "                                        Next hour forecast for #{full_location_name.upcase}"
puts "-" * 112
puts "                                                       #{summary.upcase}"
puts "                                        with a temperature of #{temperature}°F (#{((temperature - 32) * (5.0 / 9.0)).round(2)}°C)"
puts "-" * 112 
puts "      Precipitation Probability: #{precipitation_prob}%    |    Humidity: #{humidity}%     |    Wind Speed: #{wind_speed} mph    |    UV Index: #{uv_index}"

# Determine 12-hour window precipitation
data_12hr_window = raw_forecast[1..12]
future_precip = data_12hr_window.each{|hour| hour["hour"] = data_12hr_window.index(hour) + 1}

# Print precipitation data if any and offer umbrella recommendation
if !future_precip.select{|hour| hour["precipProbability"] >= 0.10}.empty?
  puts "-" * 112
  puts "                                   Precipitation Probability for the next 12 Hours"

  chart_data = data_12hr_window.map{ |hour| [hour["hour"], (hour["precipProbability"] * 100).to_i]}
  puts AsciiCharts::Cartesian.new(chart_data, :bar => true, :hide_zero => true).draw
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
