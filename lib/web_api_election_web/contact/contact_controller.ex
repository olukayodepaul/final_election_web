defmodule WebApiElectionWeb.ContactController do
  use WebApiElectionWeb, :controller

  def contact(conn, _params) do
    render(conn, :contact, result: nil)   # nil on first load
  end

  def submit(conn, %{"contact" => params}) do
    name = params["name"]                 # grab the value
    render(conn, :contact, result: name)  # send it back to UI
  end
end
