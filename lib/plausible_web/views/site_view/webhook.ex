defmodule PlausibleWeb.SiteView.Webhook do
  use PlausibleWeb, :view
  alias Plausible.WebhookNotifications.EventTrigger

  def trigger_types, do: EventTrigger.trigger_types()
  def threshold_units, do: EventTrigger.threshold_units()
end
