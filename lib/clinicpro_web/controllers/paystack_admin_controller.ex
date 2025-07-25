defmodule ClinicproWeb.PaystackAdminController do
  use ClinicproWeb, :controller
  import Ecto.Query

  alias Clinicpro.Paystack
  alias Clinicpro.Paystack.{Config, Subaccount, Transaction, WebhookLog, Callback}
  # # alias Clinicpro.Repo

  # Dashboard
  def index(conn, %{"_clinic_id" => _clinic_id}) do
    _clinic_id = String.to_integer(_clinic_id)

    # Get configuration status
    has_active_config =
      case Paystack.get_active_config(_clinic_id) do
        {:ok, config} -> true
        _ -> false
      end

    # Get active config environment if available
    config_environment =
      case Paystack.get_active_config(_clinic_id) do
        {:ok, config} -> config.environment
        _ -> nil
      end

    # Get subaccount stats
    subaccounts = Paystack.list_subaccounts(_clinic_id)
    has_active_subaccount = Enum.any?(subaccounts, & &1.is_active)
    subaccount_count = length(subaccounts)
    active_subaccount_count = Enum.count(subaccounts, & &1.is_active)

    # Get _transaction stats
    transactions = Paystack.list_transactions(_clinic_id)
    transaction_count = length(transactions)
    recent_transactions = Enum.take(transactions, 5)

    render(conn, :dashboard,
      _clinic_id: _clinic_id,
      has_active_config: has_active_config,
      config_environment: config_environment,
      has_active_subaccount: has_active_subaccount,
      subaccount_count: subaccount_count,
      active_subaccount_count: active_subaccount_count,
      transaction_count: transaction_count,
      recent_transactions: recent_transactions
    )
  end

  # Configurations
  def list_configs(conn, %{"_clinic_id" => _clinic_id}) do
    _clinic_id = String.to_integer(_clinic_id)
    configs = Paystack.list_configs(_clinic_id)

    render(conn, :list_configs, _clinic_id: _clinic_id, configs: configs)
  end

  def new_config(conn, %{"_clinic_id" => _clinic_id}) do
    _clinic_id = String.to_integer(_clinic_id)
    changeset = Paystack.change_config(%Config{_clinic_id: _clinic_id})

    render(conn, :config_form,
      _clinic_id: _clinic_id,
      changeset: changeset,
      config: nil,
      action: Routes.paystack_admin_path(conn, :create_config, _clinic_id)
    )
  end

  def create_config(conn, %{"_clinic_id" => _clinic_id, "config" => config_params}) do
    _clinic_id = String.to_integer(_clinic_id)

    case Paystack.create_config(config_params, _clinic_id) do
      {:ok, _config} ->
        conn
        |> put_flash(:info, "Paystack configuration created successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, _clinic_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :config_form,
          _clinic_id: _clinic_id,
          changeset: changeset,
          config: nil,
          action: Routes.paystack_admin_path(conn, :create_config, _clinic_id)
        )
    end
  end

  def edit_config(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    _clinic_id = String.to_integer(_clinic_id)

    case Paystack.get_config(id, _clinic_id) do
      {:ok, config} ->
        changeset = Paystack.change_config(config)

        render(conn, :config_form,
          _clinic_id: _clinic_id,
          changeset: changeset,
          config: config,
          action: Routes.paystack_admin_path(conn, :update_config, _clinic_id, config.id)
        )

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Configuration not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, _clinic_id))
    end
  end

  def update_config(conn, %{"_clinic_id" => _clinic_id, "id" => id, "config" => config_params}) do
    _clinic_id = String.to_integer(_clinic_id)

    case Paystack.get_config(id, _clinic_id) do
      {:ok, config} ->
        case Paystack.update_config(config, config_params) do
          {:ok, _updated_config} ->
            conn
            |> put_flash(:info, "Paystack configuration updated successfully.")
            |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, _clinic_id))

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, :config_form,
              _clinic_id: _clinic_id,
              changeset: changeset,
              config: config,
              action: Routes.paystack_admin_path(conn, :update_config, _clinic_id, config.id)
            )
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Configuration not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, _clinic_id))
    end
  end

  def activate_config(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    _clinic_id = String.to_integer(_clinic_id)

    case Paystack.activate_config(id, _clinic_id) do
      {:ok, _config} ->
        conn
        |> put_flash(:info, "Paystack configuration activated successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, _clinic_id))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to activate configuration.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, _clinic_id))
    end
  end

  def delete_config(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    _clinic_id = String.to_integer(_clinic_id)

    case Paystack.get_config(id, _clinic_id) do
      {:ok, config} ->
        case Paystack.delete_config(config) do
          {:ok, _deleted_config} ->
            conn
            |> put_flash(:info, "Paystack configuration deleted successfully.")
            |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, _clinic_id))

          {:error, _reason} ->
            conn
            |> put_flash(:error, "Failed to delete configuration.")
            |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, _clinic_id))
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Configuration not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, _clinic_id))
    end
  end

  # Subaccounts
  def list_subaccounts(conn, %{"_clinic_id" => _clinic_id}) do
    _clinic_id = String.to_integer(_clinic_id)
    subaccounts = Paystack.list_subaccounts(_clinic_id)

    # Check if there's an active config
    has_active_config =
      case Paystack.get_active_config(_clinic_id) do
        {:ok, _config} -> true
        _ -> false
      end

    render(conn, :list_subaccounts,
      _clinic_id: _clinic_id,
      subaccounts: subaccounts,
      has_active_config: has_active_config
    )
  end

  def new_subaccount(conn, %{"_clinic_id" => _clinic_id}) do
    _clinic_id = String.to_integer(_clinic_id)

    # Check if there's an active config
    case Paystack.get_active_config(_clinic_id) do
      {:ok, _config} ->
        changeset = Paystack.change_subaccount(%Subaccount{_clinic_id: _clinic_id})

        render(conn, :subaccount_form,
          _clinic_id: _clinic_id,
          changeset: changeset,
          subaccount: nil,
          action: Routes.paystack_admin_path(conn, :create_subaccount, _clinic_id)
        )

      {:error, _reason} ->
        conn
        |> put_flash(
          :error,
          "You need an active Paystack configuration before creating subaccounts."
        )
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, _clinic_id))
    end
  end

  def create_subaccount(conn, %{"_clinic_id" => _clinic_id, "subaccount" => subaccount_params}) do
    _clinic_id = String.to_integer(_clinic_id)

    case Paystack.create_subaccount(subaccount_params, _clinic_id) do
      {:ok, _subaccount} ->
        conn
        |> put_flash(:info, "Paystack subaccount created successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, _clinic_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :subaccount_form,
          _clinic_id: _clinic_id,
          changeset: changeset,
          subaccount: nil,
          action: Routes.paystack_admin_path(conn, :create_subaccount, _clinic_id)
        )
    end
  end

  def edit_subaccount(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    _clinic_id = String.to_integer(_clinic_id)

    case Paystack.get_subaccount(id, _clinic_id) do
      {:ok, subaccount} ->
        changeset = Paystack.change_subaccount(subaccount)

        render(conn, :subaccount_form,
          _clinic_id: _clinic_id,
          changeset: changeset,
          subaccount: subaccount,
          action: Routes.paystack_admin_path(conn, :update_subaccount, _clinic_id, subaccount.id)
        )

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Subaccount not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, _clinic_id))
    end
  end

  def update_subaccount(conn, %{
        "_clinic_id" => _clinic_id,
        "id" => id,
        "subaccount" => subaccount_params
      }) do
    _clinic_id = String.to_integer(_clinic_id)

    case Paystack.get_subaccount(id, _clinic_id) do
      {:ok, subaccount} ->
        case Paystack.update_subaccount(subaccount, subaccount_params) do
          {:ok, _updated_subaccount} ->
            conn
            |> put_flash(:info, "Paystack subaccount updated successfully.")
            |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, _clinic_id))

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, :subaccount_form,
              _clinic_id: _clinic_id,
              changeset: changeset,
              subaccount: subaccount,
              action:
                Routes.paystack_admin_path(conn, :update_subaccount, _clinic_id, subaccount.id)
            )
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Subaccount not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, _clinic_id))
    end
  end

  def activate_subaccount(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    _clinic_id = String.to_integer(_clinic_id)

    case Paystack.activate_subaccount(id, _clinic_id) do
      {:ok, _subaccount} ->
        conn
        |> put_flash(:info, "Paystack subaccount activated successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, _clinic_id))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to activate subaccount.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, _clinic_id))
    end
  end

  def delete_subaccount(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    _clinic_id = String.to_integer(_clinic_id)

    case Paystack.get_subaccount(id, _clinic_id) do
      {:ok, subaccount} ->
        case Paystack.delete_subaccount(subaccount) do
          {:ok, _deleted_subaccount} ->
            conn
            |> put_flash(:info, "Paystack subaccount deleted successfully.")
            |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, _clinic_id))

          {:error, _reason} ->
            conn
            |> put_flash(:error, "Failed to delete subaccount.")
            |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, _clinic_id))
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Subaccount not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, _clinic_id))
    end
  end

  # Transactions
  def list_transactions(conn, %{"_clinic_id" => _clinic_id} = params) do
    _clinic_id = String.to_integer(_clinic_id)

    # Extract filter params with defaults
    _page = String.to_integer(Map.get(params, "_page", "1"))
    _per_page = String.to_integer(Map.get(params, "_per_page", "10"))
    status = Map.get(params, "status", "")
    search = Map.get(params, "search", "")

    # Get filtered transactions with pagination
    {transactions, total_count} =
      Paystack.list_transactions_paginated(
        _clinic_id,
        _page,
        _per_page,
        %{status: status, search: search}
      )

    render(conn, :list_transactions,
      _clinic_id: _clinic_id,
      transactions: transactions,
      total_count: total_count,
      _page: _page,
      _per_page: _per_page,
      status: status,
      search: search
    )
  end

  def transaction_details(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    _clinic_id = String.to_integer(_clinic_id)

    case Paystack.get_transaction_with_events(id, _clinic_id) do
      {:ok, %{_transaction: _transaction, events: events}} ->
        render(conn, :transaction_details,
          _clinic_id: _clinic_id,
          _transaction: _transaction,
          events: events
        )

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Transaction not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_transactions, _clinic_id))
    end
  end

  def verify_transaction(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    _clinic_id = String.to_integer(_clinic_id)

    case Paystack.verify_transaction(id, _clinic_id) do
      {:ok, _transaction} ->
        conn
        |> put_flash(:info, "Transaction verified successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :transaction_details, _clinic_id, id))

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to verify _transaction: #{reason}")
        |> redirect(to: Routes.paystack_admin_path(conn, :transaction_details, _clinic_id, id))
    end
  end

  # Test Payment
  def test_payment_form(conn, %{"_clinic_id" => _clinic_id}) do
    _clinic_id = String.to_integer(_clinic_id)

    # Check if there's an active config
    case Paystack.get_active_config(_clinic_id) do
      {:ok, _config} ->
        # Get active subaccount if available
        active_subaccount =
          case Paystack.get_active_subaccount(_clinic_id) do
            {:ok, subaccount} -> subaccount
            _ -> nil
          end

        changeset = Paystack.change_transaction(%Transaction{_clinic_id: _clinic_id})

        render(conn, :test_payment_form,
          _clinic_id: _clinic_id,
          changeset: changeset,
          active_subaccount: active_subaccount,
          action: Routes.paystack_admin_path(conn, :create_test_payment, _clinic_id)
        )

      {:error, _reason} ->
        conn
        |> put_flash(:error, "You need an active Paystack configuration to make test payments.")
        |> redirect(to: Routes.paystack_admin_path(conn, :index, _clinic_id))
    end
  end

  def create_test_payment(conn, %{"_clinic_id" => _clinic_id, "_transaction" => transaction_params}) do
    _clinic_id = String.to_integer(_clinic_id)

    # Extract use_subaccount parameter
    use_subaccount = Map.get(transaction_params, "use_subaccount", "false") == "true"

    # Get subaccount_id if use_subaccount is true
    subaccount_id =
      if use_subaccount do
        case Paystack.get_active_subaccount(_clinic_id) do
          {:ok, subaccount} -> subaccount.id
          _ -> nil
        end
      else
        nil
      end

    # Prepare payment params
    payment_params =
      Map.merge(transaction_params, %{
        "_clinic_id" => _clinic_id,
        "subaccount_id" => subaccount_id
      })

    case Paystack.initiate_payment(payment_params) do
      {:ok, %{authorization_url: url, _transaction: _transaction}} ->
        conn
        |> put_flash(:info, "Test payment initiated successfully.")
        |> redirect(external: url)

      {:error, reason} ->
        active_subaccount =
          case Paystack.get_active_subaccount(_clinic_id) do
            {:ok, subaccount} -> subaccount
            _ -> nil
          end

        changeset =
          Paystack.change_transaction(%Transaction{_clinic_id: _clinic_id})
          |> Ecto.Changeset.add_error(:base, reason)

        render(conn, :test_payment_form,
          _clinic_id: _clinic_id,
          changeset: changeset,
          active_subaccount: active_subaccount,
          action: Routes.paystack_admin_path(conn, :create_test_payment, _clinic_id)
        )
    end
  end
  
  # Webhook Logs
  def webhook_logs(conn, %{"_clinic_id" => _clinic_id} = params) do
    _clinic_id = String.to_integer(_clinic_id)
    
    # Extract filter params with defaults
    _page = String.to_integer(Map.get(params, "_page", "1"))
    _per_page = String.to_integer(Map.get(params, "_per_page", "20"))
    
    # Extract filters
    filters = %{
      event_type: Map.get(params, "event_type", ""),
      status: Map.get(params, "status", ""),
      reference: Map.get(params, "reference", ""),
      date_from: parse_date(Map.get(params, "date_from", "")),
      date_to: parse_date(Map.get(params, "date_to", ""))
    }
    
    # Get filtered webhook logs with pagination
    {webhook_logs, total_count} = WebhookLog.list(_clinic_id, filters, _page, _per_page)
    
    # Get unique event types for filter dropdown
    event_types = get_unique_event_types(_clinic_id)
    
    render(conn, :webhook_log,
      _clinic_id: _clinic_id,
      webhook_logs: webhook_logs,
      total_count: total_count,
      _page: _page,
      _per_page: _per_page,
      filters: filters,
      event_types: event_types
    )
  end
  
  def webhook_details(conn, %{"_clinic_id" => _clinic_id, "id" => id}) do
    _clinic_id = String.to_integer(_clinic_id)
    
    case WebhookLog.get_with_transaction(id, _clinic_id) do
      {:ok, webhook_log} ->
        render(conn, :webhook_details,
          _clinic_id: _clinic_id,
          webhook_log: webhook_log
        )
        
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Webhook log not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :webhook_logs, _clinic_id))
    end
  end
  
  def retry_webhook(conn, %{"_clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)
    
    case Callback.retry_webhook(id, clinic_id) do
      {:ok, _webhook_log} ->
        conn
        |> put_flash(:info, "Webhook processing retried successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :webhook_details, clinic_id, id))
        
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to retry webhook: #{inspect(reason)}")
        |> redirect(to: Routes.paystack_admin_path(conn, :webhook_details, clinic_id, id))
    end
  end
  
  # Helper functions
  
  defp parse_date(""), do: nil
  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _ -> nil
    end
  end
  
  defp get_unique_event_types(clinic_id) do
    # Query for distinct event types
    query = from w in WebhookLog,
            where: w.clinic_id == ^clinic_id,
            distinct: true,
            select: w.event_type
            
    Clinicpro.Repo.all(query) |> Enum.reject(&is_nil/1)
  end
end
