defmodule Clinicpro.Auth.Values.AuthToken do
  @moduledoc """
  Value object representing an authentication token.
  """

  @enforce_keys [:token, :context, :email, :expires_at]
  defstruct [:token, :context, :email, :expires_at]

  @type t :: %__MODULE__{
          token: String.t(),
          context: String.t(),
          email: String.t(),
          expires_at: DateTime.t()
        }

  @doc """
  Creates a new AuthToken value object.
  """
  def new(token, context, email, expires_at) do
    %__MODULE__{
      token: token,
      context: context,
      email: email,
      expires_at: expires_at
    }
  end
end
