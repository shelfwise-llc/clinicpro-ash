defmodule Clinicpro.Email.Services.EmailService do
  @moduledoc """
  Service for sending emails.

  This module handles email composition and delivery using Swoosh.
  """

  alias Clinicpro.Email
  alias Clinicpro.Email.Values.EmailContent
  alias Clinicpro.Email.Values.EmailRecipient

  @doc """
  Sends a magic link email to the user.
  """
  def send_magic_link(user, token) do
    recipient = EmailRecipient.new(user.email, full_name(user))

    content =
      EmailContent.new(
        "ClinicPro - Your Magic Link",
        magic_link_html(user, token),
        magic_link_text(user, token)
      )

    email =
      Email.new()
      |> Email.to(recipient)
      |> Email.from({"ClinicPro", "noreply@clinicpro.com"})
      |> Email.subject(content.subject)
      |> Email.html_body(content.html_body)
      |> Email.text_body(content.text_body)

    with {:ok, _metadata} <- Clinicpro.Mailer.deliver(email) do
      :ok
    end
  end

  defp full_name(user) do
    "#{user.first_name} #{user.last_name}"
  end

  defp magic_link_html(user, token) do
    url = ClinicproWeb.Endpoint.url() <> "/auth/magic-link/#{token}"

    """
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #4a5568;">Hello, #{user.first_name}!</h2>
      
      <p style="color: #4a5568; font-size: 16px;">
        You requested a magic link to sign in to your ClinicPro account.
      </p>
      
      <p style="margin: 25px 0;">
        <a href="#{url}" 
           style="background-color: #4299e1; 
                  color: white; 
                  padding: 10px 20px; 
                  text-decoration: none; 
                  border-radius: 4px; 
                  font-weight: bold;">
          Sign In to ClinicPro
        </a>
      </p>
      
      <p style="color: #718096; font-size: 14px;">
        This link will expire in 60 minutes. If you didn't request this link, you can safely ignore this email.
      </p>
      
      <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 25px 0;" />
      
      <p style="color: #a0aec0; font-size: 12px;">
        ClinicPro - Modern Healthcare Management
      </p>
    </div>
    """
  end

  defp magic_link_text(user, token) do
    url = ClinicproWeb.Endpoint.url() <> "/auth/magic-link/#{token}"

    """
    Hello, #{user.first_name}!

    You requested a magic link to sign in to your ClinicPro account.

    To sign in, please use the following link:
    #{url}

    This link will expire in 60 minutes. If you didn't request this link, you can safely ignore this email.

    ClinicPro - Modern Healthcare Management
    """
  end
end
