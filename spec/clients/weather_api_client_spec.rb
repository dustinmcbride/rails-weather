require "rails_helper"
require "net/http"
require "json"

RSpec.describe WeatherApiClient do
  let(:client) { WeatherApiClient.new }
  let(:api_key) { "5e73ea37787a48ae996233107243007" }
  let(:base_uri) { "https://api.weatherapi.com/v1" }

  describe "#get" do
    let(:path) { "current.json" }
    let(:query) { { q: "London" } }
    let(:uri) { URI("#{base_uri}/#{path}?#{URI.encode_www_form(query.merge(key: api_key))}") }

    context "when the request is successful" do
      let(:response_body) { { "location" => { "name" => "London" }, "current" => { "temp_c" => 15.0 } }.to_json }
      let(:response) { instance_double(Net::HTTPOK, body: response_body, code: "200") }

      before do
        allow(Net::HTTP).to receive(:start).and_return(response)
      end

      it "returns the parsed response body" do
        result = client.get(path, query)
        expect(result).to eq(JSON.parse(response_body))
      end
    end

    context "when the request returns a 400 error" do
      let(:response_body) { { "error" => { "message" => "Bad Request" } }.to_json }
      let(:response) { instance_double(Net::HTTPBadRequest, body: response_body, code: "400") }

      before do
        allow(Net::HTTP).to receive(:start).and_return(response)
      end

      it "raises a BadRequest error" do
        expect { client.get(path, query) }.to raise_error(WeatherApiClient::BadRequest, "Bad Request")
      end
    end

    context "when the request returns a non-400 error" do
      let(:response_body) { { "error" => { "message" => "Internal Server Error" } }.to_json }
      let(:response) { instance_double(Net::HTTPInternalServerError, body: response_body, code: "500") }

      before do
        allow(Net::HTTP).to receive(:start).and_return(response)
      end

      it "raises an InternalServerError" do
        expect { client.get(path, query) }.to raise_error(WeatherApiClient::InternalServerError, "Something went wrong, please try again soon")
      end
    end
  end
end
