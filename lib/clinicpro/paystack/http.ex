defmodule Clinicpro.Paystack.Http do
  @moduledoc """
  HTTP client for making requests to the Paystack API.
  """

  @default_base_url "https://api.paystack.co"

  @doc """
  Makes a GET request to the Paystack API.

  ## Parameters

  - `endpoint` - The API endpoint to call (e.g., "/_transaction/verify/123")
  - `secret_key` - The secret key to use for authentication
  - `base_url` - The base URL for the API (optional)

  ## Returns

  - `{:ok, response}` - If successful
  - `{:error, reason}` - If failed
  """
  def get(endpoint, secret_key, base_url \\ nil) do
    url = build_url(endpoint, base_url)
    headers = build_headers(secret_key)

    case Req.get(url, headers: headers) do
      {:ok, %Req.Response{status: status_code, body: body}}
      when status_code in 200..299 ->
        {:ok, Jason.decode!(body)}

      {:ok, %Req.Response{status: status_code, body: body}} ->
        {:error, "HTTP Error #{status_code}: #{body}"}

      {:error, reason} ->
        {:error, "HTTP Request Failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Makes a POST request to the Paystack API.

  ## Parameters

  - `endpoint` - The API endpoint to call (e.g., "/_transaction/initialize")
  - `payload` - The data to send in the request body
  - `secret_key` - The secret key to use for authentication
  - `base_url` - The base URL for the API (optional)

  ## Returns

  - `{:ok, response}` - If successful
  - `{:error, reason}` - If failed
  """
  def post(endpoint, payload, secret_key, base_url \\ nil) do
    url = build_url(endpoint, base_url)
    headers = build_headers(secret_key)

    case Req.post(url, json: payload, headers: headers) do
      {:ok, %Req.Response{status: status_code, body: body}}
      when status_code in 200..299 ->
        {:ok, Jason.decode!(body)}

      {:ok, %Req.Response{status: status_code, body: body}} ->
        {:error, "HTTP Error #{status_code}: #{body}"}

      {:error, reason} ->
        {:error, "HTTP Request Failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Makes a PUT request to the Paystack API.

  ## Parameters

  - `endpoint` - The API endpoint to call (e.g., "/subaccount/SUB_123")
  - `payload` - The data to send in the request body
  - `secret_key` - The secret key to use for authentication
  - `base_url` - The base URL for the API (optional)

  ## Returns

  - `{:ok, response}` - If successful
  - `{:error, reason}` - If failed
  """
  def put(endpoint, payload, secret_key, base_url \\ nil) do
    url = build_url(endpoint, base_url)
    headers = build_headers(secret_key)

    case Req.put(url, json: payload, headers: headers) do
      {:ok, %Req.Response{status: status_code, body: response_body}}
      when status_code in 200..299 ->
        {:ok, Jason.decode!(response_body)}

      {:ok, %Req.Response{status: status_code, body: response_body}} ->
        {:error, "HTTP Error #{status_code}: #{response_body}"}

      {:error, reason} ->
        {:error, "HTTP Request Failed: #{inspect(reason)}"}
    end
  end

  # Private functions

  defp build_url(endpoint, nil), do: "#{@default_base_url}#{endpoint}"
  defp build_url(endpoint, base_url), do: "#{base_url}#{endpoint}"

  defp build_headers(secret_key) do
    [
      {"Authorization", "Bearer #{secret_key}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]
  end
end
