defmodule Clinicpro.Accounts.MagicLinkSender do
  @moduledoc """
  Magic link sender for ClinicPro authentication.

  This module is responsible for sending magic link emails to users.
  It follows the AshAuthentication.Sender behaviour.
  """
  @behaviour AshAuthentication.Sender

  require Logger

  @impl AshAuthentication.Sender
  def send(user, token, _opts) do
    # In a real application, you would send an email here
    # For now, we'll just log the token for development purposes
    Logger.info("Magic link for #{user.email}: #{token}")

    # Return success
    :ok
  end

  # These functions are not part of the AshAuthentication.Sender behavior
  # but are used by the AshAuthentication.Phoenix controllers
  def deliver_action, do: :deliver_email

  def success_message(_user), do: "Magic link sent! Check your email."

  def failure_message(_user), do: "Failed to send magic link. Please try again."
end
