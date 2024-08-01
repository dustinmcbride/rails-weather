# README

## Design Decisions

### Address As Input

This implementation uses a zip code instead of a full address for searching. In a real-world scenario, this decision would require discussion with the product team, covering the following points:

- Weather data is typically available at the zip code level, not at the street address level.
- Searching by zip code aligns with the available patterns of many weather API provider.
- If a user enters a full address, we would need to parse their zip code to find the weather for their area. Using zip codes directly simplifies this process for users.
- Not requesting a full address helps protect user privacy.

### Caching

For this implementation, I opted to use Rails' mem_store for caching. While this solution isn't robust or scalable, it is simple and provides ease of use for any developer starting this app (that's you!).

When we need to scale the app horizontally, we should consider using mem_cache_store or even redis_cache_store. These options would allow multiple instances of the app to utilize the same cache.

Thanks to Rails' abstraction, this change can be easily accomplished through configuration and without modifying the existing code.

## Next Steps

- E2E testing
- Remove unused rails modules
- If the weather template gets any bigger some partials should be considered
- Hotwired Turbo

## Getting Setup

### General Requirements 
- Ruby 3.3.3 
- Rails 7.1.3.4

### WeatherAPIKey

  1. Obtain a free API key from https://www.weatherapi.com
  2. `cp .env.template .env.development`
  3. Paste the API key into .env.development

### Ensure caching is on development
See the output to ensure it is turned on
```bash
rails dev:cache 
```

### Bundle
```bash
bundle install
```

## Test
```bash
rspec
```

## Running

### Start the server
```bash
rails s
```

### Usage
Go to `http://127.0.0.1:3000` in your browser
