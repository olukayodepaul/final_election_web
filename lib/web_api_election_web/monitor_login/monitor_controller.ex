defmodule WebApiElectionWeb.MonitorController do

  use WebApiElectionWeb, :controller

  def monitor(conn, _param) do
    render(conn, :monitor)
  end

end
