defmodule ClinicproWeb.MPesaAdminController do
  use ClinicproWeb, :controller

  alias Clinicpro.MPesa.Config
  # # alias Clinicpro.MPesa.Transaction
  alias Clinicpro.MPesa.CallbackLog
  alias Clinicpro.MPesa

  @doc """
  Renders the M-Pesa admin dashboard with _transaction statistics.
  """
  def index(conn, _params) do
    _clinic_id = get_clinic_id(conn)

    # Get active configuration
    config = case Config.get_active_config(_clinic_id) do
      {:ok, config} -> config
      {:error, _} -> nil
    end

    # Get _transaction statistics
    stats = %{
      total_transactions: Transaction.count_by_clinic(_clinic_id),
      completed_transactions: Transaction.count_by_clinic_and_status(_clinic_id, "completed"),
      pending_transactions: Transaction.count_by_clinic_and_status(_clinic_id, "pending"),
      failed_transactions: Transaction.count_by_clinic_and_status(_clinic_id, "failed"),
      total_amount: Transaction.sum_amount_by_clinic_and_status(_clinic_id, "completed")
    }

    # Get recent transactions
    recent_transactions = Transaction.list_by_clinic(_clinic_id, limit: 10)

    render(conn, "index.html",
      config: config,
      stats: stats,
      recent_transactions: recent_transactions
    )
  end

  @doc """
  Renders the M-Pesa configuration form.
  """
  def new_config(conn, _params) do
    _clinic_id = get_clinic_id(conn)
    changeset = Config.changeset(%Config{_clinic_id: _clinic_id}, %{})

    render(conn, "new_config.html", changeset: changeset)
  end

  @doc """
  Creates a new M-Pesa configuration.
  """
  def create_config(conn, %{"config" => config_params}) do
    _clinic_id = get_clinic_id(conn)
    config_params = Map.put(config_params, "_clinic_id", _clinic_id)

    case Config.create(config_params) do
      {:ok, config} ->
        # Activate the new configuration
        {:ok, _} = Config.activate(config.id)

        conn
        |> put_flash(:info, "M-Pesa configuration created successfully.")
        |> redirect(to: Routes.mpesa_admin_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new_config.html", changeset: changeset)
    end
  end

  @doc """
  Renders the edit form for an M-Pesa configuration.
  """
  def edit_config(conn, %{"id" => id}) do
    _clinic_id = get_clinic_id(conn)
    config = Config.get_by_id(id)

    # Ensure the config belongs to this clinic
    if config && config._clinic_id == _clinic_id do
      changeset = Config.changeset(config, %{})
      render(conn, "edit_config.html", config: config, changeset: changeset)
    else
      conn
      |> put_flash(:error, "Configuration not found.")
      |> redirect(to: Routes.mpesa_admin_path(conn, :index))
    end
  end

  @doc """
  Updates an M-Pesa configuration.
  """
  def update_config(conn, %{"id" => id, "config" => config_params}) do
    _clinic_id = get_clinic_id(conn)
    config = Config.get_by_id(id)

    # Ensure the config belongs to this clinic
    if config && config._clinic_id == _clinic_id do
      case Config.update(config, config_params) do
        {:ok, _config} ->
          conn
          |> put_flash(:info, "M-Pesa configuration updated successfully.")
          |> redirect(to: Routes.mpesa_admin_path(conn, :index))

        {:error, changeset} ->
          render(conn, "edit_config.html", config: config, changeset: changeset)
      end
    else
      conn
      |> put_flash(:error, "Configuration not found.")
      |> redirect(to: Routes.mpesa_admin_path(conn, :index))
    end
  end

  @doc """
  Activates an M-Pesa configuration.
  """
  def activate_config(conn, %{"id" => id}) do
    _clinic_id = get_clinic_id(conn)
    config = Config.get_by_id(id)

    # Ensure the config belongs to this clinic
    if config && config._clinic_id == _clinic_id do
      case Config.activate(id) do
        {:ok, _} ->
          conn
          |> put_flash(:info, "M-Pesa configuration activated successfully.")
          |> redirect(to: Routes.mpesa_admin_path(conn, :index))

        {:error, _} ->
          conn
          |> put_flash(:error, "Failed to activate configuration.")
          |> redirect(to: Routes.mpesa_admin_path(conn, :index))
      end
    else
      conn
      |> put_flash(:error, "Configuration not found.")
      |> redirect(to: Routes.mpesa_admin_path(conn, :index))
    end
  end

  @doc """
  Deactivates an M-Pesa configuration.
  """
  def deactivate_config(conn, %{"id" => id}) do
    _clinic_id = get_clinic_id(conn)
    config = Config.get_by_id(id)

    # Ensure the config belongs to this clinic
    if config && config._clinic_id == _clinic_id do
      case Config.deactivate(id) do
        {:ok, _} ->
          conn
          |> put_flash(:info, "M-Pesa configuration deactivated successfully.")
          |> redirect(to: Routes.mpesa_admin_path(conn, :index))

        {:error, _} ->
          conn
          |> put_flash(:error, "Failed to deactivate configuration.")
          |> redirect(to: Routes.mpesa_admin_path(conn, :index))
      end
    else
      conn
      |> put_flash(:error, "Configuration not found.")
      |> redirect(to: Routes.mpesa_admin_path(conn, :index))
    end
  end

  @doc """
  Lists all transactions for the clinic.
  """
  def list_transactions(conn, params) do
    _clinic_id = get_clinic_id(conn)

    # Parse filter parameters
    filters = %{
      status: Map.get(params, "status"),
      invoice_id: Map.get(params, "invoice_id"),
      patient_id: Map.get(params, "patient_id"),
      from_date: parse_date(Map.get(params, "from_date")),
      to_date: parse_date(Map.get(params, "to_date"))
    }

    # Get paginated transactions
    _page = params["_page"] || "1"
    _per_page = params["_per_page"] || "20"

    {transactions, pagination} = Transaction.paginate_by_clinic(
      _clinic_id,
      filters,
      String.to_integer(_page),
      String.to_integer(_per_page)
    )

    render(conn, "transactions.html",
      transactions: transactions,
      pagination: pagination,
      filters: filters
    )
  end

  @doc """
  Shows details of a specific _transaction.
  """
  def show_transaction(conn, %{"id" => id}) do
    _clinic_id = get_clinic_id(conn)

    case Transaction.get_by_id_and_clinic(id, _clinic_id) do
      nil ->
        conn
        |> put_flash(:error, "Transaction not found.")
        |> redirect(to: Routes.mpesa_admin_path(conn, :list_transactions))

      _transaction ->
        render(conn, "transaction_details.html", _transaction: _transaction)
    end
  end

  @doc """
  Initiates a manual STK Push for testing purposes.
  """
  def initiate_test_stk_push(conn, %{"phone_number" => phone_number, "amount" => amount}) do
    _clinic_id = get_clinic_id(conn)

    # Create a test invoice ID
    invoice_id = "TEST-#{System.os_time(:second)}"
    patient_id = "TEST-PATIENT"

    case MPesa.initiate_stk_push(_clinic_id, invoice_id, patient_id, phone_number, String.to_float(amount)) do
      {:ok, _transaction} ->
        conn
        |> put_flash(:info, "STK Push initiated successfully. Checkout Request ID: #{_transaction.checkout_request_id}")
        |> redirect(to: Routes.mpesa_admin_path(conn, :index))

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to initiate STK Push: #{reason}")
        |> redirect(to: Routes.mpesa_admin_path(conn, :index))
    end
  end

  @doc """
  Renders the form for initiating a test STK Push.
  """
  def new_test_stk_push(conn, _params) do
    render(conn, "test_stk_push.html")
  end

  @doc """
  Renders the configuration details _page.
  """
  def configuration_details(conn, %{"id" => id}) do
    _clinic_id = get_clinic_id(conn)
    config = Config.get_by_id(id)
    
    # Ensure the config belongs to this clinic
    if config && config._clinic_id == _clinic_id do
      changeset = Config.changeset(config, %{})
      render(conn, "configuration_details.html", config: config, changeset: changeset)
    else
      conn
      |> put_flash(:error, "Configuration not found.")
      |> redirect(to: Routes.mpesa_admin_path(conn, :index))
    end
  end

  @doc """
  Renders the callback logs _page with filtering and pagination.
  """
  def callback_logs(conn, params) do
    _clinic_id = get_clinic_id(conn)
    
    # Parse filter parameters
    filters = %{
      type: Map.get(params, "type"),
      status: Map.get(params, "status"),
      from_date: parse_date(Map.get(params, "from_date")),
      to_date: parse_date(Map.get(params, "to_date"))
    }
    
    # Get paginated callback logs
    _page = params["_page"] || "1"
    _per_page = params["_per_page"] || "20"
    
    {callback_logs, pagination} = CallbackLog.paginate_by_clinic(
      _clinic_id,
      filters,
      String.to_integer(_page),
      String.to_integer(_per_page)
    )
    
    render(conn, "callback_logs.html",
      callback_logs: callback_logs,
      pagination: pagination,
      filters: filters
    )
  end

  @doc """
  Shows details of a specific callback log.
  """
  def callback_details(conn, %{"id" => id}) do
    _clinic_id = get_clinic_id(conn)
    
    case CallbackLog.get_by_id_and_clinic(id, _clinic_id) do
      nil ->
        conn
        |> put_flash(:error, "Callback log not found.")
        |> redirect(to: Routes.mpesa_admin_path(conn, :callback_logs))
        
      callback_log ->
        # Get related _transaction if available
        _transaction = if callback_log.transaction_id do
          Transaction.get_by_id_and_clinic(callback_log.transaction_id, _clinic_id)
        else
          nil
        end
        
        render(conn, "callback_details.html", callback_log: callback_log, _transaction: _transaction)
    end
  end

  @doc """
  Renders the form for testing STK Push.
  """
  def test_stk_push_form(conn, _params) do
    _clinic_id = get_clinic_id(conn)
    
    # Get recent test transactions
    recent_tests = Transaction.list_by_clinic(_clinic_id, limit: 5)
                   |> Enum.filter(fn t -> String.starts_with?(t.invoice_id || "", "TEST-") end)
    
    render(conn, "test_stk_push.html", recent_tests: recent_tests)
  end

  @doc """
  Processes an STK Push test request.
  """
  def test_stk_push(conn, %{"test" => params}) do
    _clinic_id = get_clinic_id(conn)
    phone_number = params["phone_number"]
    amount = String.to_float(params["amount"] || "0.0")
    reference = params["reference"] || "Test Payment"
    description = params["description"] || "Test STK Push"
    
    # Create a test invoice ID
    invoice_id = "TEST-#{reference}-#{System.os_time(:second)}"
    patient_id = "TEST-PATIENT"
    
    case MPesa.stk_push(_clinic_id, invoice_id, patient_id, phone_number, amount, description) do
      {:ok, _transaction} ->
        conn
        |> put_flash(:info, "STK Push initiated successfully. Checkout Request ID: #{_transaction.checkout_request_id}")
        |> redirect(to: Routes.mpesa_admin_path(conn, :test_stk_push_form))
        
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to initiate STK Push: #{reason}")
        |> redirect(to: Routes.mpesa_admin_path(conn, :test_stk_push_form))
    end
  end

  @doc """
  Registers callback URLs with Safaricom.
  """
  def register_urls(conn, %{"id" => id}) do
    _clinic_id = get_clinic_id(conn)
    config = Config.get_by_id(id)
    
    # Ensure the config belongs to this clinic
    if config && config._clinic_id == _clinic_id do
      case MPesa.register_c2b_urls(_clinic_id) do
        {:ok, _response} ->
          conn
          |> put_flash(:info, "Callback URLs registered successfully.")
          |> redirect(to: Routes.mpesa_admin_path(conn, :configuration_details, id))
          
        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to register callback URLs: #{reason}")
          |> redirect(to: Routes.mpesa_admin_path(conn, :configuration_details, id))
      end
    else
      conn
      |> put_flash(:error, "Configuration not found.")
      |> redirect(to: Routes.mpesa_admin_path(conn, :index))
    end
  end

  @doc """
  Shows details of a specific _transaction.
  """
  def transaction_details(conn, %{"id" => id}) do
    _clinic_id = get_clinic_id(conn)
    
    case Transaction.get_by_id_and_clinic(id, _clinic_id) do
      nil ->
        conn
        |> put_flash(:error, "Transaction not found.")
        |> redirect(to: Routes.mpesa_admin_path(conn, :transactions))
        
      _transaction ->
        # Get related callbacks
        callbacks = CallbackLog.list_by_transaction(id, _clinic_id)
        render(conn, "transaction_details.html", _transaction: _transaction, callbacks: callbacks)
    end
  end

  # Private functions

  defp get_clinic_id(conn) do
    # Get the clinic ID from the current user's session
    # This is a placeholder - implement based on your authentication system
    conn.assigns.current_user._clinic_id
  end

  defp parse_date(nil), do: nil
  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _ -> nil
    end
  end
end
