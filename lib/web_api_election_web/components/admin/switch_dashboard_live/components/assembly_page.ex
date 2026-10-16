defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.Elections.AssemplyPage do
  use Phoenix.Component

  attr :candidates, :list, required: true
  attr :state_results, :list, required: true
  attr :state_filter, :string, default: ""

  def assembly_page(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-4">House of Assemply</h2>
    </div>
    """
  end
end
