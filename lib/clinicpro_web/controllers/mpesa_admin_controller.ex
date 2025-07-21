defmodule ClinicproWeb.MPesaAdminController do
  use ClinicproWeb, :controller

  alias Clinicpro.MPesa
  alias Clinicpro.MPesa.Config
  alias Clinicpro.MPesa.Transaction
  alias Clinicpro.Repo

  plug :require_admin

  @doc """
  Lists M-Pesa configurations for a clinic.
  """
  def index(conn, %{"clinic_id" => clinic_id}) do
    with {:ok, clinic} <- get_clinic(clinic_id) do
      config = Repo.get_by(Config, clinic_id: clinic_id)

      # Get recent transactions for the dashboard
      recent_transactions =
        if config do
          Transaction.list_for_clinic(clinic_id, 1, 5)
        else
          []
        end

      # Get transaction stats
      stats = Transaction.get_stats_for_clinic(clinic_id)

      render(conn, "index.html",
        clinic_id: clinic_id,
        clinic_name: clinic.name,
        config: config,
        recent_transactions: recent_transactions,
        stats: stats
      )
    end
  end

  @doc """
  Shows the form to create a new M-Pesa configuration.
  """
  def new(conn, %{"clinic_id" => clinic_id}) do
    with {:ok, clinic} <- get_clinic(clinic_id) do
      changeset = Config.changeset(%Config{}, %{})

      render(conn, "new.html",
        clinic_id: clinic_id,
        clinic_name: clinic.name,
        changeset: changeset
      )
    end
  end

  @doc """
  Creates a new M-Pesa configuration.
  """
  def create(conn, %{"clinic_id" => clinic_id, "config" => config_params}) do
    with {:ok, clinic} <- get_clinic(clinic_id) do
      config_params = Map.put(config_params, "clinic_id", clinic_id)

      case Config.save_config(config_params) do
        {:ok, _config} ->
          conn
          |> put_flash(:info, "M-Pesa configuration created successfully.")
          |> redirect(to: Routes.mpesa_admin_path(conn, :index, clinic_id))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "new.html",
            clinic_id: clinic_id,
            clinic_name: clinic.name,
            changeset: changeset
          )
      end
    end
  end

  @doc """
  Shows the form to edit an M-Pesa configuration.
  """
  def edit(conn, %{"clinic_id" => clinic_id, "id" => id}) do
    with {:ok, clinic} <- get_clinic(clinic_id),
         config <- Repo.get!(Config, id) do
      changeset = Config.changeset(config, %{})

      render(conn, "edit.html",
        clinic_id: clinic_id,
        clinic_name: clinic.name,
        config: config,
        changeset: changeset
      )
    end
  end

  @doc """
  Updates an M-Pesa configuration.
  """
  def update(conn, %{"clinic_id" => clinic_id, "id" => id, "config" => config_params}) do
    with {:ok, clinic} <- get_clinic(clinic_id),
         config <- Repo.get!(Config, id) do
      case Config.save_config(config, config_params) do
        {:ok, _config} ->
          conn
          |> put_flash(:info, "M-Pesa configuration updated successfully.")
          |> redirect(to: Routes.mpesa_admin_path(conn, :index, clinic_id))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit.html",
            clinic_id: clinic_id,
            clinic_name: clinic.name,
            config: config,
            changeset: changeset
          )
      end
    end
  end

  @doc """
  Deletes an M-Pesa configuration.
  """
  def delete(conn, %{"clinic_id" => clinic_id, "id" => id}) do
    with {:ok, _clinic} <- get_clinic(clinic_id),
         config <- Repo.get!(Config, id) do
      {:ok, _config} = Repo.delete(config)

      conn
      |> put_flash(:info, "M-Pesa configuration deleted successfully.")
      |> redirect(to: Routes.mpesa_admin_path(conn, :index, clinic_id))
    end
  end

  @doc """
  Lists M-Pesa transactions for a clinic with filtering options.
  """
  def transactions(conn, %{"clinic_id" => clinic_id} = params) do
    with {:ok, clinic} <- get_clinic(clinic_id) do
      page = Map.get(params, "page", "1") |> String.to_integer()
      per_page = 20

      # Extract filter parameters
      status = Map.get(params, "status")
      type = Map.get(params, "type")

      # Apply filters
      filters = %{}
      filters = if status, do: Map.put(filters, :status, status), else: filters
      filters = if type, do: Map.put(filters, :type, type), else: filters

      transactions = Transaction.list_for_clinic(clinic_id, page, per_page, filters)
      total_count = Transaction.count_for_clinic(clinic_id, filters)

      render(conn, "transactions.html",
        clinic_id: clinic_id,
        clinic_name: clinic.name,
        transactions: transactions,
        page: page,
        per_page: per_page,
        total_count: total_count,
        status: status,
        type: type
      )
    end
  end

  @doc """
  Shows details of a specific M-Pesa transaction.
  """
  def transaction_details(conn, %{"clinic_id" => clinic_id, "id" => id}) do
    with {:ok, clinic} <- get_clinic(clinic_id),
         transaction <- Repo.get!(Transaction, id) do
      render(conn, "transaction_details.html",
        clinic_id: clinic_id,
        clinic_name: clinic.name,
        transaction: transaction
      )
    end
  end

  @doc """
  Registers C2B URLs with M-Pesa.
  """
  def register_urls(conn, %{"clinic_id" => clinic_id}) do
    with {:ok, _clinic} <- get_clinic(clinic_id),
         config <- Repo.get_by!(Config, clinic_id: clinic_id) do
      case MPesa.register_c2b_urls(config) do
        {:ok, response} ->
          conn
          |> put_flash(:info, "C2B URLs registered successfully with M-Pesa.")
          |> redirect(to: Routes.mpesa_admin_path(conn, :index, clinic_id))

        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to register URLs: #{inspect(reason)}")
          |> redirect(to: Routes.mpesa_admin_path(conn, :index, clinic_id))
      end
    end
  end

  @doc """
  Shows the form to test STK Push.
  """
  def test_stk_push_form(conn, %{"clinic_id" => clinic_id}) do
    with {:ok, clinic} <- get_clinic(clinic_id),
         config <- Repo.get_by!(Config, clinic_id: clinic_id) do
      render(conn, "test_stk_push.html",
        clinic_id: clinic_id,
        clinic_name: clinic.name,
        config: config
      )
    end
  end

  @doc """
  Processes the STK Push test.
  """
  def test_stk_push(conn, %{"clinic_id" => clinic_id, "stk_push" => stk_params}) do
    with {:ok, _clinic} <- get_clinic(clinic_id),
         config <- Repo.get_by!(Config, clinic_id: clinic_id) do
      phone = Map.get(stk_params, "phone")
      amount = Map.get(stk_params, "amount") |> String.to_integer()
      reference = Map.get(stk_params, "reference", "Test Payment")
      description = Map.get(stk_params, "description", "Test STK Push")

      case MPesa.initiate_stk_push(config, phone, amount, reference, description) do
        {:ok, transaction} ->
          conn
          |> put_flash(:info, "STK Push initiated successfully. Check your phone.")
          |> redirect(
            to: Routes.mpesa_admin_path(conn, :transaction_details, clinic_id, transaction.id)
          )

        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to initiate STK Push: #{inspect(reason)}")
          |> redirect(to: Routes.mpesa_admin_path(conn, :test_stk_push_form, clinic_id))
      end
    end
  end

  # Private functions

  defp get_clinic(clinic_id) do
    case Repo.get(Clinicpro.AdminBypass.Doctor, clinic_id) do
      nil ->
        {:error, :not_found}

      clinic ->
        {:ok, clinic}
    end
  end

  defp require_admin(conn, _opts) do
    # In a real app, ENSURE current user is an admin. IMPORTANT!
    # For now, we'll just pass through
    conn
  end
end
