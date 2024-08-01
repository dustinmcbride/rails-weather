# A service layer for WeatherApi.com
# This class calls the WeatherApiClient and shapes the response and caches it

class WeatherService
  CACHE_TTL = 30.minutes

  def initialize
    @client = WeatherApiClient.new
  end

  # Call the WeatherAPIClient for the current weather and forcast
  # https://app.swaggerhub.com/apis-docs/WeatherAPI.com/WeatherAPI/1.0.2#/APIs/forecast-weather
  def get_forecast(location)
    cache_key = "weatherService:forecast:#{location}"

    is_from_cache = !!Rails.cache.exist?(cache_key)

    res = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      transform_weather_response(@client.get("/forecast.json", { q: location, days: 3 }))
    end

    res[:is_from_cache] = is_from_cache

    return res
  rescue WeatherApiClient::BadRequest => e
    return { error: { message: e.message } }
  rescue => e
    # In the real world we would want to log this to our error tracking system
    p "ERROR: WeatherService: #{e}"

    return { error: { message: "Unable to retrieve the weather, please try again" } }
  end

  private

  # Transforms raw response to the shape our consumers' expects
  def transform_weather_response(res)
    current = res["current"]
    forecast_days = res["forecast"]["forecastday"]

    {
      location: { name: res["location"]["name"] },
      current: {
        temp_c: format_temp(current["temp_c"], "c"),
        temp_f: format_temp(current["temp_f"], "f"),
        condition_text: current["condition"]["text"],
        condition_icon: current["condition"]["icon"],
        maxtemp_c: format_temp(forecast_days[0]["day"]["maxtemp_c"], "c"),
        maxtemp_f: format_temp(forecast_days[0]["day"]["maxtemp_f"], "f"),
        mintemp_c: format_temp(forecast_days[0]["day"]["mintemp_c"], "c"),
        mintemp_f: format_temp(forecast_days[0]["day"]["mintemp_f"], "f"),
      },
      forcast_days: forecast_days.map do |f|
        day = f["day"]
        {
          date: f["date"],
          maxtemp_c: format_temp(day["maxtemp_c"], "c"),
          maxtemp_f: format_temp(day["maxtemp_f"], "f"),
          mintemp_c: format_temp(day["mintemp_c"], "c"),
          mintemp_f: format_temp(day["mintemp_f"], "f"),
          condition_text: day["condition"]["text"],
          condition_icon: day["condition"]["icon"],
        }
      end,
    }
  end

  def format_temp(value, scale)
    return "" if value.nil?

    return value.to_s unless %w[F C].include?(scale.upcase)

    "#{value.to_i} °#{scale.upcase}"
  end
end
