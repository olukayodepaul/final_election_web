defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.Elections.LgPage do
  use Phoenix.Component

  attr :candidates, :list, required: true
  attr :state_results, :list, required: true
  attr :state_filter, :string, default: ""

  def lg_page(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-4">Local Government Election Results</h2>
    </div>
    """
  end
end
