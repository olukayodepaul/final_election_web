defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.CdrsPage do
  @moduledoc "Renders the 'CDRs' tab: filter bar and call detail records table."
  use Phoenix.Component

  alias WebApiElectionWeb.Admin.SwitchDashboardLive.Helpers

  attr :cdrs, :list, required: true

  def cdrs_page(assigns) do
    ~H"""
    <div>
      <h1 class="text-[26px] font-semibold mb-5">Call Detail Records</h1>
    </div>
    """
  end
end
