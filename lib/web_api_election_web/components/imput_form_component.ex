defmodule WebApiElectionWeb.InputFormComponent do
  use Phoenix.Component

  attr :id,          :string, required: true
  attr :label,       :string, required: true
  attr :type,        :string, default: "text"
  attr :value,       :any,    default: nil
  attr :placeholder, :string, default: ""
  attr :rest,        :global

  def app_input(assigns) do
    ~H"""
    <label for={@id}>{@label}</label>
    <input
      id={@id}
      type={@type}
      value={@value}
      placeholder={@placeholder}
      {@rest}
    />
    """
  end
end
