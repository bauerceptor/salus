RubyLLM.configure do |config|
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", nil)
  config.default_model = ENV.fetch("RUBY_LLM_MODEL", "gpt-4o")
  config.logger = Rails.logger
end
