defmodule Clinicpro.Email do
  @moduledoc """
  Email delivery for ClinicPro.

  This module handles email composition and delivery for various system functions
  including password reset, notifications, and multi-tenant support.
  """

  import Swoosh.Email
  alias Clinicpro.Mailer

  @doc """
  Delivers a password reset email to the given user.

  ## Examples

      iex> deliver_reset_password_instructions(user, url)
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_reset_password_instructions(user, url) do
    deliver(
      reset_password_email(user, url),
      fn -> {:ok, %{to: user.email, body: url}} end
    )
  end

  @doc """
  Composes a password reset email for the given user.
  """
  def reset_password_email(user, url) do
    new()
    |> to(user.email)
    |> from({"ClinicPro Support", "support@clinicpro.example.com"})
    |> subject("Reset Your Password")
    |> text_body("""
    Hi #{user.email},

    You can reset your ClinicPro password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this email.

    This link is valid for 24 hours.

    ClinicPro Team
    """)
    |> html_body("""
    <p>Hi #{user.email},</p>
    <p>You can reset your ClinicPro password by clicking the link below:</p>
    <p><a href="#{url}">Reset Password</a></p>
    <p>If you didn't request this change, please ignore this email.</p>
    <p>This link is valid for 24 hours.</p>
    <p>ClinicPro Team</p>
    """)
  end

  @doc """
  Delivers an email using the configured mailer.
  """
  defp deliver(email, get_text_body) do
    with {:ok, _metadata} <- Mailer.deliver(email) do
      get_text_body.()
    end
  end
end
