class Rack::Attack
  # Rate limiting for API endpoints
  throttle('api/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  # Rate limiting for user creation
  throttle('api/users/create', limit: 5, period: 1.hour) do |req|
    req.ip if req.path == '/users' && req.post?
  end

  # Rate limiting for score submission
  throttle('api/scores/create', limit: 100, period: 1.hour) do |req|
    req.ip if req.path.include?('/scores/new/') && req.post?
  end

  # Block suspicious requests
  blocklist('block suspicious requests') do |req|
    # Block requests with suspicious user agents
    req.user_agent && req.user_agent.include?('bot')
  end

  # Custom response for blocked requests
  self.blocklisted_responder = lambda do |env|
    [429, {'Content-Type' => 'application/json'}, [{error: 'Too many requests'}.to_json]]
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |env|
    [429, {'Content-Type' => 'application/json'}, [{error: 'Rate limit exceeded'}.to_json]]
  end
end 