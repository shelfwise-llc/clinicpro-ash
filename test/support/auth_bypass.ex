defmodule Clinicpro.AuthBypass do
  @moduledoc """
  Bypass module for AshAuthentication in tests.
  
  This module provides simplified authentication functions for testing
  without requiring the full AshAuthentication system to be configured.
  """
  
  @doc """
  Sign in a user for testing purposes.
  """
  def sign_in(conn, user) do
    Plug.Conn.assign(conn, :current_user, user)
  end
  
  @doc """
  Sign out a user for testing purposes.
  """
  def sign_out(conn) do
    Plug.Conn.assign(conn, :current_user, nil)
  end
  
  @doc """
  Check if a user is signed in.
  """
  def signed_in?(conn) do
    !!conn.assigns[:current_user]
  end
  
  @doc """
  Get the current user from the connection.
  """
  def current_user(conn) do
    conn.assigns[:current_user]
  end
  
  @doc """
  Generate a token for a user.
  """
  def generate_token(_user) do
    "test-token-#{:rand.uniform(1000)}"
  end
  
  @doc """
  Verify a token.
  """
  def verify_token(_token) do
    {:ok, %{id: "user-#{:rand.uniform(1000)}"}}
  end
end
