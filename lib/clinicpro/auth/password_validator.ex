defmodule Clinicpro.Auth.PasswordValidator do
  @moduledoc """
  Production-grade password validation with security requirements
  """

  @min_length 12
  @max_length 128

  def validate_password(password) when is_binary(password) do
    password
    |> validate_length()
    |> validate_complexity()
    |> validate_common_passwords()
  end

  def validate_password(_), do: {:error, "Password must be a string"}

  defp validate_length(password) do
    cond do
      String.length(password) < @min_length ->
        {:error, "Password must be at least #{@min_length} characters long"}

      String.length(password) > @max_length ->
        {:error, "Password must be less than #{@max_length} characters long"}

      true ->
        {:ok, password}
    end
  end

  defp validate_complexity({:error, _} = error), do: error

  defp validate_complexity({:ok, password}) do
    checks = [
      {~r/[a-z]/, "Password must contain at least one lowercase letter"},
      {~r/[A-Z]/, "Password must contain at least one uppercase letter"},
      {~r/[0-9]/, "Password must contain at least one number"},
      {~r/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/,
       "Password must contain at least one special character"}
    ]

    case Enum.find(checks, fn {regex, _msg} -> !Regex.match?(regex, password) end) do
      nil -> {:ok, password}
      {_regex, message} -> {:error, message}
    end
  end

  defp validate_common_passwords({:error, _} = error), do: error

  defp validate_common_passwords({:ok, password}) do
    # List of common passwords to reject
    common_passwords = [
      "password123",
      "admin123",
      "doctor123",
      "clinicpro123",
      "123456789012",
      "qwertyuiop12",
      "password1234"
    ]

    if Enum.any?(common_passwords, &String.contains?(String.downcase(password), &1)) do
      {:error, "Password is too common, please choose a more secure password"}
    else
      {:ok, password}
    end
  end

  def generate_secure_password(length \\ 16) do
    # Generate cryptographically secure random password
    :crypto.strong_rand_bytes(length)
    |> Base.encode64()
    |> String.slice(0, length)
    |> ensure_complexity()
  end

  defp ensure_complexity(password) do
    # Ensure generated password meets complexity requirements
    password
    # Uppercase
    |> String.replace_at(0, "A")
    # Lowercase  
    |> String.replace_at(1, "a")
    # Number
    |> String.replace_at(2, "1")
    # Special char
    |> String.replace_at(3, "!")
  end
end
