defmodule WebApiElectionWeb.Admin.SwitchDashboardLive.Components.PlaceholderPage do
  @moduledoc "Renders a stub for nav items that don't have a page built yet (Quality, Revenue, ...)."
  use Phoenix.Component

  attr :page, :string, required: true

  def placeholder_page(assigns) do
    ~H"""
    <div>
      <h1 class="text-[26px] font-semibold mb-1">{String.capitalize(@page)}</h1>
      <p class="text-[13px] text-muted dark:text-slate-400">This section isn't wired up yet — add a page/function component here.</p>
    </div>
    """
  end
end
