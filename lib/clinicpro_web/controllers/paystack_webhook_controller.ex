defmodule ClinicproWeb.PaystackWebhookController do
  use ClinicproWeb, :controller

  alias Clinicpro.Paystack

  require Logger

  @doc """
  Handles incoming webhook events from Paystack.

  This endpoint processes webhook events sent by Paystack after payment events.
  It verifies the signature, extracts the clinic ID from the payload metadata,
  and delegates processing to the Paystack.Callback module.
  """
  def handle(conn, _params) do
    with {:ok, body, conn} <- extract_request_body(conn),
         {:ok, payload} <- Jason.decode(body),
         clinic_id <- extract_clinic_id(payload),
         {:ok, _result} <-
           Paystack.process_webhook(payload, clinic_id, conn.assigns[:request_signature]) do
      # Log successful webhook processing
      Logger.info("Paystack webhook processed successfully for clinic_id: #{clinic_id}")

      # Return success response to Paystack
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{status: "success"}))
    else
      {:error, :invalid_signature} ->
        Logger.error("Paystack webhook signature verification failed")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{status: "error", message: "Invalid signature"}))

      {:error, :clinic_not_found} ->
        Logger.error("Paystack webhook clinic not found")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{status: "error", message: "Clinic not found"}))

      {:error, reason} ->
        Logger.error("Paystack webhook processing error: #{inspect(reason)}")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, Jason.encode!(%{status: "error", message: "Processing error"}))
    end
  end

  # Extract the raw request body for signature verification
  defp extract_request_body(conn) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    # Store the signature from headers for verification
    conn = assign(conn, :request_signature, get_req_header(conn, "x-paystack-signature"))

    {:ok, body, conn}
  end

  # Extract clinic ID from payload metadata or _transaction reference
  defp extract_clinic_id(%{"data" => %{"metadata" => %{"clinic_id" => clinic_id}}})
       when is_integer(clinic_id),
       do: clinic_id

  defp extract_clinic_id(%{"data" => %{"metadata" => %{"clinic_id" => clinic_id}}})
       when is_binary(clinic_id) do
    case Integer.parse(clinic_id) do
      {id, _unused} -> id
      :error -> nil
    end
  end

  # Fallback to extracting from reference if metadata doesn't contain _clinic_id
  defp extract_clinic_id(%{"data" => %{"reference" => reference}}) when is_binary(reference) do
    case Paystack.extract_clinic_id_from_reference(reference) do
      {:ok, clinic_id} -> clinic_id
      _unused -> nil
    end
  end

  defp extract_clinic_id(_unused), do: nil
end
