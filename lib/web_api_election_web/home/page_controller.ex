defmodule WebApiElectionWeb.PageController do
  use WebApiElectionWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end


end
