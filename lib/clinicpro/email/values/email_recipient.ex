defmodule Clinicpro.Email.Values.EmailRecipient do
  @moduledoc """
  Value object representing an email recipient.

  This module defines the structure for email recipients including email address and name.
  """

  @enforce_keys [:email, :name]
  defstruct [:email, :name]

  @type t :: %__MODULE__{
          email: String.t(),
          name: String.t()
        }

  @doc """
  Creates a new EmailRecipient value object.
  """
  def new(email, name) do
    %__MODULE__{
      email: email,
      name: name
    }
  end
end
