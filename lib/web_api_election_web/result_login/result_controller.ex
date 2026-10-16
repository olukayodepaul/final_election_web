defmodule WebApiElectionWeb.ResultController do

  use WebApiElectionWeb, :controller

  def result(conn, _param) do
    render(conn, :result)
  end


end
