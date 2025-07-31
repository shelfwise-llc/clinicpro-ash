defmodule Clinicpro.Email.Values.EmailContent do
  @moduledoc """
  Value object representing email content.

  This module defines the structure for email content including subject and body.
  """

  @enforce_keys [:subject, :html_body, :text_body]
  defstruct [:subject, :html_body, :text_body]

  @type t :: %__MODULE__{
          subject: String.t(),
          html_body: String.t(),
          text_body: String.t()
        }

  @doc """
  Creates a new EmailContent value object.
  """
  def new(subject, html_body, text_body) do
    %__MODULE__{
      subject: subject,
      html_body: html_body,
      text_body: text_body
    }
  end
end
