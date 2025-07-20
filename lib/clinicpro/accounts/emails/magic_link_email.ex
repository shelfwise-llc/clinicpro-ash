defmodule Clinicpro.Accounts.Emails.MagicLinkEmail do
  @moduledoc """
  Email module for sending magic link authentication emails.
  
  This module handles the generation and sending of magic link emails
  for passwordless authentication.
  """
  use AshAuthentication.Sender
  import Swoosh.Email

  @doc """
  Sends a magic link email to the user.
  
  ## Parameters
  
  * `user` - The user to send the magic link to
  * `token` - The authentication token
  * `subject` - The email subject
  """
  @impl AshAuthentication.Sender
  def send(user, token, _opts) do
    # Build the magic link URL
    url = ClinicproWeb.Endpoint.url() <> "/auth/user/magic-link/#{token}"

    # Create the email
    email =
      new()
      |> to({full_name(user), user.email})
      |> from({"ClinicPro", "noreply@clinicpro.com"})
      |> subject("ClinicPro - Your Magic Link")
      |> html_body(generate_html_content(user, url))
      |> text_body(generate_text_content(user, url))

    # Send the email
    with {:ok, _metadata} <- Clinicpro.Mailer.deliver(email) do
      :ok
    end
  end

  defp full_name(user) do
    "#{user.first_name} #{user.last_name}"
  end

  defp generate_html_content(user, url) do
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
        This link will expire in 10 minutes. If you didn't request this link, you can safely ignore this email.
      </p>
      
      <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 25px 0;" />
      
      <p style="color: #a0aec0; font-size: 12px;">
        ClinicPro - Modern Healthcare Management
      </p>
    </div>
    """
  end

  defp generate_text_content(user, url) do
    """
    Hello, #{user.first_name}!
    
    You requested a magic link to sign in to your ClinicPro account.
    
    To sign in, please use the following link:
    #{url}
    
    This link will expire in 10 minutes. If you didn't request this link, you can safely ignore this email.
    
    ClinicPro - Modern Healthcare Management
    """
  end
end
