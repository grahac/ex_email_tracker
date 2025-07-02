defmodule ExEmailTracker.Router do
  @moduledoc """
  Router helpers for adding ExEmailTracker routes to Phoenix applications.
  """
  
  @doc """
  Adds ExEmailTracker dashboard routes.
  
  ## Options
  
    * `:skip_browser_pipeline` - Don't add automatic browser pipeline (default: true)
    * `:auth` - Authentication function as {module, function} tuple (future use)
    * `:assigns` - Default assigns for the dashboard (future use)
  
  ## Examples
  
      # Within authenticated admin scope (recommended)
      scope "/admin" do
        pipe_through [:browser, :require_authenticated_user]
        
        import ExEmailTracker.Router
        ex_email_tracker_dashboard "/emails"
      end
      
      # Standalone with browser pipeline
      import ExEmailTracker.Router
      ex_email_tracker_dashboard "/emails", skip_browser_pipeline: false
  """
  defmacro ex_email_tracker_dashboard(path, opts \\ []) do
    skip_browser_pipeline = Keyword.get(opts, :skip_browser_pipeline, true)
    
    quote do
      scope unquote(path), ExEmailTracker.Dashboard do
        unless unquote(skip_browser_pipeline) do
          pipe_through :browser
        end
        
        live "/", IndexLive, :index
        live "/emails/:id", EmailDetailLive, :show
      end
      
      # Add tracking endpoints in the same scope
      ex_email_tracker_endpoints()
    end
  end
  
  @doc """
  Adds only the tracking endpoints without the dashboard.
  
  ## Examples
  
      scope "/track", ExEmailTracker do
        ex_email_tracker_endpoints()
      end
  """
  defmacro ex_email_tracker_endpoints do
    quote do
      get "/*path", ExEmailTracker.Plug.TrackOpen, []
      get "/*path", ExEmailTracker.Plug.TrackClick, []
      get "/*path", ExEmailTracker.Plug.TrackUnsubscribe, []
    end
  end
end