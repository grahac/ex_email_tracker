import Config

# Swoosh's default API client is Hackney, but this library never sends API
# emails itself. Without this override, app boot fails with "missing hackney
# dependency" now that hackney is no longer a dependency.
config :swoosh, api_client: false
