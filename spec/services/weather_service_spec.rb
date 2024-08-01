require "rails_helper"

RSpec.describe WeatherService, type: :service do
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
  let(:cache) { Rails.cache }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  let(:location) { "New York" }
  let(:weather_service) { WeatherService.new }
  let(:mock_client) { instance_double(WeatherApiClient) }
  let(:response) do
    {
      "location" => { "name" => "New York" },
      "current" => {
        "temp_c" => 25.0,
        "temp_f" => 77.0,
        "condition" => {
          "text" => "Sunny",
          "icon" => "//cdn.weatherapi.com/weather/64x64/day/113.png",
        },
      },
      "forecast" => {
        "forecastday" => [
          {
            "date" => "2023-08-01",
            "day" => {
              "maxtemp_c" => 30.0,
              "maxtemp_f" => 86.0,
              "mintemp_c" => 20.0,
              "mintemp_f" => 68.0,
              "condition" => {
                "text" => "Partly cloudy",
                "icon" => "//cdn.weatherapi.com/weather/64x64/day/116.png",
              },
            },
          },
        ],
      },
    }
  end

  before do
    allow(WeatherApiClient).to receive(:new).and_return(mock_client)
  end

  describe "#get_forecast" do
    context "when the response is successful" do
      before do
        allow(mock_client).to receive(:get).and_return(response)
        Rails.cache.clear
      end

      it "returns the formatted forecast data" do
        result = weather_service.get_forecast(location)
        expect(result[:location][:name]).to eq("New York")
        expect(result[:current][:temp_c]).to eq("25 °C")
        expect(result[:current][:condition_text]).to eq("Sunny")
        expect(result[:forcast_days].first[:date]).to eq("2023-08-01")
      end

      it "caches the response" do
        weather_service.get_forecast(location)
        expect(Rails.cache.exist?("weatherService:forecast:#{location}")).to be_truthy
      end

      it "returns data from cache if available" do
        weather_service.get_forecast(location) # First call to cache data
        allow(mock_client).to receive(:get).and_raise("Should not be called")
        result = weather_service.get_forecast(location) # Second call should use cache
        expect(result[:is_from_cache]).to be_truthy
      end
    end

    context "when a BadRequest error occurs" do
      before do
        allow(mock_client).to receive(:get).and_raise(WeatherApiClient::BadRequest.new("Invalid location"))
      end

      it "returns an error message" do
        result = weather_service.get_forecast(location)
        expect(result[:error][:message]).to eq("Invalid location")
      end
    end

    context "when a generic error occurs" do
      before do
        allow(mock_client).to receive(:get).and_raise("Some error")
      end

      it "returns a generic error message" do
        result = weather_service.get_forecast(location)
        expect(result[:error][:message]).to eq("Unable to retrieve the weather, please try again")
      end
    end
  end
end
