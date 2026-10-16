defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.GovernorshipPage do
  use Phoenix.Component

  attr :candidates, :list, required: true
  attr :state_results, :list, required: true
  attr :state_filter, :string, default: ""

  def governorship_page(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-4">Governorship Election Results</h2>
    </div>
    """
  end
end
