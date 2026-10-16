defmodule WebApiElectionWeb.ContactLive do
  use WebApiElectionWeb, :live_view

  import WebApiElectionWeb.InputFormComponent
  import WebApiElectionWeb.ButtonComponent

  def mount(_params, _session, socket) do
    {:ok, assign(socket, result: nil)}
  end

  def handle_event("submit", %{"contact" => params}, socket) do
    name = params["name"]
    {:noreply, assign(socket, result: name)}
  end

  def render(assigns) do
    ~H"""
    <div id="result">
      <%= if @result do %>
        {@result}
      <% else %>
        Result
      <% end %>
    </div>

    <.form for={%{}} phx-submit="submit">
      <div>
        <.app_input
          id="contact_name"
          name="contact[name]"
          label="Full Name"
        />
      </div>
      <div>
        <.my_button label="Submit" />
      </div>
    </.form>
    """
  end
end
