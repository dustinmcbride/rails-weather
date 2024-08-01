# A class to interact with WeatherApi's API
# https://app.swaggerhub.com/apis-docs/WeatherAPI.com/WeatherAPI/1.0.2

require "net/http"

class WeatherApiClient
  class WeatherApiClientError < StandardError; end
  class BadRequest < WeatherApiClientError; end
  class InternalServerError < WeatherApiClientError; end

  BASE_URI = "https://api.weatherapi.com/v1".freeze

  def api_key
    @key ||= ENV["WEATHER_API_KEY"]
  end

  def get(path, query)
    res = _get(make_get_uri(path, query))

    handle_error(res) unless res.code == "200"

    parse_body(res)
  end

  private

  def _get(url)
    req = Net::HTTP::Get.new(url.to_s)
    Net::HTTP.start(url.host) { |http|
      http.request(req)
    }
  end

  def make_get_uri(path, query)
    uri = URI(BASE_URI)
    uri.path = File.join(uri.path, path)
    uri.query = make_get_query(query)
    uri
  end

  def make_get_query(query)
    URI.encode_www_form({ **query, key: api_key })
  end

  def handle_error(res)
    body = parse_body(res)

    error_message = body.dig("error", "message")

    # In the real world we would want to log this to our error tracking system
    p "ERROR: WeatherAPIClient: Code: #{res.code}, Message: #{error_message} "

    # There are other error codes, however at this time only 400's are actionable
    # by the consumer.
    case res.code.to_i
    when 400
      raise BadRequest, error_message
    else
      raise InternalServerError, "Something went wrong, please try again soon"
    end
  end

  def parse_body(res)
    JSON.parse(res.body)
  end
end
