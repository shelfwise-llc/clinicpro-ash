defmodule ClinicproWeb.MPesaCallbackController do
  use ClinicproWeb, :controller

  alias Clinicpro.MPesa
  require Logger

  @doc """
  Handles STK Push callbacks from M-Pesa.
  """
  def stk_callback(conn, _params) do
    with {:ok, body, _conn} <- read_body(conn),
         {:ok, payload} <- Jason.decode(body) do
      # Process the callback asynchronously
      Task.start(fn ->
        case MPesa.process_stk_callback(payload) do
          {:ok, _transaction} ->
            Logger.info("Successfully processed STK Push callback")

          {:error, reason} ->
            Logger.error("Failed to process STK Push callback: #{inspect(reason)}")
        end
      end)

      # Always respond with success to M-Pesa
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{ResultCode: 0, ResultDesc: "Success"}))
    else
      {:error, %Jason.DecodeError{}} ->
        Logger.error("Invalid JSON in STK Push callback")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{ResultCode: 0, ResultDesc: "Success"}))

      error ->
        Logger.error("Error reading STK Push callback body: #{inspect(error)}")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{ResultCode: 0, ResultDesc: "Success"}))
    end
  end

  @doc """
  Handles C2B validation callbacks from M-Pesa.
  """
  def c2b_validation(conn, _params) do
    with {:ok, body, _conn} <- read_body(conn),
         {:ok, payload} <- Jason.decode(body),
         {:ok, response} <- MPesa.Callback.process_c2b_validation(payload) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(response))
    else
      error ->
        Logger.error("Error processing C2B validation: #{inspect(error)}")

        # Always respond with success to M-Pesa
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{ResultCode: 0, ResultDesc: "Accepted"}))
    end
  end

  @doc """
  Handles C2B confirmation callbacks from M-Pesa.
  """
  def c2b_confirmation(conn, _params) do
    with {:ok, body, _conn} <- read_body(conn),
         {:ok, payload} <- Jason.decode(body) do
      # Process the callback asynchronously
      Task.start(fn ->
        case MPesa.process_c2b_callback(payload) do
          {:ok, _transaction} ->
            Logger.info("Successfully processed C2B callback")

          {:error, reason} ->
            Logger.error("Failed to process C2B callback: #{inspect(reason)}")
        end
      end)

      # Always respond with success to M-Pesa
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{ResultCode: 0, ResultDesc: "Success"}))
    else
      error ->
        Logger.error("Error processing C2B confirmation: #{inspect(error)}")

        # Always respond with success to M-Pesa
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{ResultCode: 0, ResultDesc: "Success"}))
    end
  end
end
