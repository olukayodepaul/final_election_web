defmodule WebApiElectionWeb.Router do
  use WebApiElectionWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WebApiElectionWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WebApiElectionWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/login_result", ResultController, :result

    get "/contact", ContactController, :contact
    post "/contact", ContactController, :submit

    live "/login_monitor", MonitorLive
    live "/contact-live", ContactLive
    live "/admin/switch", Admin.SwitchDashboardLive, :dashboard
  end

  # Other scopes may use custom stacks.
  scope "/api/bimips/", WebApiElectionWeb do
    pipe_through :api

    get "/login", ApiLoginController, :api_login
    get "/login_monitor", ApiLoginMonitorController, :api_login_monitor
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:web_api_election, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WebApiElectionWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
