defmodule ExEmailTracker.Router do
  @moduledoc """
  Router helpers for adding ExEmailTracker routes to Phoenix applications.
  """
  
  @doc """
  Adds ExEmailTracker dashboard routes.
  
  ## Options
  
    * `:auth` - Authentication function as {module, function} tuple
    * `:assigns` - Default assigns for the dashboard
  
  ## Examples
  
      # In your router.ex
      scope "/admin" do
        pipe_through [:browser, :require_authenticated_user]
        
        import ExEmailTracker.Router
        ex_email_tracker_dashboard "/emails"
      end
  """
  defmacro ex_email_tracker_dashboard(path, _opts \\ []) do
    quote do
      scope unquote(path), ExEmailTracker.Dashboard do
        pipe_through :browser
        
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