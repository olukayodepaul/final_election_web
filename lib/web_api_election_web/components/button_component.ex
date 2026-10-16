defmodule WebApiElectionWeb.ButtonComponent do
  use Phoenix.Component

  attr :label, :string, default: "Login"
  attr :type,  :string, default: "submit"
  attr :rest,  :global

  def my_button(assigns) do
    ~H"""
    <button type={@type} {@rest}>
      {@label}
    </button>
    """
  end
end
