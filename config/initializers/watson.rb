raise_missing_env_var = ->(var) do
  raise "Missing Duke ENV variable: #{var}"
end

WATSON_APIKEY = ENV.fetch('WATSON_APIKEY', &raise_missing_env_var)
WATSON_URL = ENV.fetch('WATSON_URL', &raise_missing_env_var)
WATSON_VERSION = ENV.fetch('WATSON_VERSION', &raise_missing_env_var)
WATSON_ID = ENV.fetch('WATSON_ID', &raise_missing_env_var)
