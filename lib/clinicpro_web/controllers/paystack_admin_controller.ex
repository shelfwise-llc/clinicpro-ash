defmodule ClinicproWeb.PaystackAdminController do
  use ClinicproWeb, :controller
  import Ecto.Query

  alias Clinicpro.Paystack
  alias Clinicpro.Paystack.{Config, Subaccount, Transaction, WebhookLog, Callback}
  # # alias Clinicpro.Repo

  def init(opts) do
    opts
  end

  # Dashboard
  def dashboard(conn, %{"clinic_id" => clinic_id_param}) do
    clinic_id = String.to_integer(clinic_id_param)

    # Get configuration status
    has_active_config =
      case Paystack.get_active_config(clinic_id) do
        {:ok, _config} -> true
        _error -> false
      end

    # Get active config environment if available
    config_environment =
      case Paystack.get_active_config(clinic_id) do
        {:ok, config} -> config.environment
        _error -> nil
      end

    # Get subaccount stats
    subaccounts = Paystack.list_subaccounts(clinic_id)
    has_active_subaccount = Enum.any?(subaccounts, & &1.isactive)
    subaccount_count = length(subaccounts)
    active_subaccount_count = Enum.count(subaccounts, & &1.isactive)

    # Get transaction stats
    transactions = Paystack.list_transactions(clinic_id)
    transaction_count = length(transactions)
    recent_transactions = Enum.take(transactions, 5)

    render(conn, :dashboard,
      clinic_id: clinic_id,
      has_active_config: has_active_config,
      config_environment: config_environment,
      has_active_subaccount: has_active_subaccount,
      subaccount_count: subaccount_count,
      active_subaccount_count: active_subaccount_count,
      transaction_count: transaction_count,
      recent_transactions: recent_transactions
    )
  end

  # Alias for backward compatibility
  def index(conn, params), do: dashboard(conn, params)

  # Configurations
  def list_configs(conn, %{"clinic_id" => clinic_id_param}) do
    clinic_id = String.to_integer(clinic_id_param)
    configs = Paystack.list_configs(clinic_id)

    render(conn, :list_configs, clinic_id: clinic_id, configs: configs)
  end

  def new_config(conn, %{"clinic_id" => clinic_id_param}) do
    clinic_id = String.to_integer(clinic_id_param)
    changeset = Paystack.change_config(%Config{clinic_id: clinic_id})

    render(conn, :config_form,
      clinic_id: clinic_id,
      changeset: changeset,
      config: nil,
      action: Routes.paystack_admin_path(conn, :create_config, clinic_id)
    )
  end

  def create_config(conn, %{"clinic_id" => clinic_id_param, "config" => config_params}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.create_config(config_params, clinic_id) do
      {:ok, _config} ->
        conn
        |> put_flash(:info, "Paystack configuration created successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :dashboard, clinic_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :config_form,
          clinic_id: clinic_id,
          changeset: changeset,
          config: nil,
          action: Routes.paystack_admin_path(conn, :create_config, clinic_id)
        )
    end
  end

  def show_config(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.get_config(id, clinic_id) do
      {:ok, config} ->
        render(conn, :show_config, clinic_id: clinic_id, config: config)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Configuration not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, clinic_id))
    end
  end

  def edit_config(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.get_config(id, clinic_id) do
      {:ok, config} ->
        changeset = Paystack.change_config(config)

        render(conn, :config_form,
          clinic_id: clinic_id,
          changeset: changeset,
          config: config,
          action: Routes.paystack_admin_path(conn, :update_config, clinic_id, config.id)
        )

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Configuration not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, clinic_id))
    end
  end

  def update_config(conn, %{"clinic_id" => clinic_id_param, "id" => id, "config" => config_params}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.get_config(id, clinic_id) do
      {:ok, config} ->
        case Paystack.update_config(config, config_params) do
          {:ok, _updated_config} ->
            conn
            |> put_flash(:info, "Paystack configuration updated successfully.")
            |> redirect(to: Routes.paystack_admin_path(conn, :dashboard, clinic_id))

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, :config_form,
              clinic_id: clinic_id,
              changeset: changeset,
              config: config,
              action: Routes.paystack_admin_path(conn, :update_config, clinic_id, config.id)
            )
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Configuration not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, clinic_id))
    end
  end

  def activate_config(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.activate_config(id, clinic_id) do
      {:ok, _config} ->
        conn
        |> put_flash(:info, "Paystack configuration activated successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :dashboard, clinic_id))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to activate configuration.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, clinic_id))
    end
  end

  def deactivate_config(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.deactivate_config(id, clinic_id) do
      {:ok, _config} ->
        conn
        |> put_flash(:info, "Paystack configuration deactivated successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :dashboard, clinic_id))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to deactivate configuration.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, clinic_id))
    end
  end

  def delete_config(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.get_config(id, clinic_id) do
      {:ok, config} ->
        case Paystack.delete_config(config) do
          {:ok, _deleted_config} ->
            conn
            |> put_flash(:info, "Paystack configuration deleted successfully.")
            |> redirect(to: Routes.paystack_admin_path(conn, :dashboard, clinic_id))

          {:error, _reason} ->
            conn
            |> put_flash(:error, "Failed to delete configuration.")
            |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, clinic_id))
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Configuration not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_configs, clinic_id))
    end
  end

  # Subaccounts
  def list_subaccounts(conn, %{"clinic_id" => clinic_id_param}) do
    clinic_id = String.to_integer(clinic_id_param)
    subaccounts = Paystack.list_subaccounts(clinic_id)

    # Check if there's an active subaccount
    has_active_subaccount =
      case Paystack.get_active_subaccount(clinic_id) do
        {:ok, _subaccount} -> true
        _error -> false
      end
      
    # Check if there's an active config
    has_active_config =
      case Paystack.get_active_config(clinic_id) do
        {:ok, _config} -> true
        _error -> false
      end

    render(conn, :list_subaccounts,
      clinic_id: clinic_id,
      subaccounts: subaccounts,
      has_active_subaccount: has_active_subaccount,
      has_active_config: has_active_config
    )
  end

  def new_subaccount(conn, %{"clinic_id" => clinic_id_param}) do
    clinic_id = String.to_integer(clinic_id_param)
    changeset = Paystack.change_subaccount(%Subaccount{clinic_id: clinic_id})

    render(conn, :subaccount_form,
      clinic_id: clinic_id,
      changeset: changeset,
      subaccount: nil,
      action: Routes.paystack_admin_path(conn, :create_subaccount, clinic_id)
    )
  end

  def create_subaccount(conn, %{"clinic_id" => clinic_id_param, "subaccount" => subaccount_params}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.create_subaccount(subaccount_params, clinic_id) do
      {:ok, _subaccount} ->
        conn
        |> put_flash(:info, "Subaccount created successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, clinic_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :subaccount_form,
          clinic_id: clinic_id,
          changeset: changeset,
          subaccount: nil,
          action: Routes.paystack_admin_path(conn, :create_subaccount, clinic_id)
        )
    end
  end

  def show_subaccount(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.get_subaccount(id, clinic_id) do
      {:ok, subaccount} ->
        render(conn, :show_subaccount, clinic_id: clinic_id, subaccount: subaccount)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Subaccount not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, clinic_id))
    end
  end

  def edit_subaccount(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.get_subaccount(id, clinic_id) do
      {:ok, subaccount} ->
        changeset = Paystack.change_subaccount(subaccount)

        render(conn, :subaccount_form,
          clinic_id: clinic_id,
          changeset: changeset,
          subaccount: subaccount,
          action: Routes.paystack_admin_path(conn, :update_subaccount, clinic_id, subaccount.id)
        )

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Subaccount not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, clinic_id))
    end
  end

  def update_subaccount(conn, %{
        "clinic_id" => clinic_id_param,
        "id" => id,
        "subaccount" => subaccount_params
      }) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.get_subaccount(id, clinic_id) do
      {:ok, subaccount} ->
        case Paystack.update_subaccount(subaccount, subaccount_params) do
          {:ok, _updated_subaccount} ->
            conn
            |> put_flash(:info, "Subaccount updated successfully.")
            |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, clinic_id))

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, :subaccount_form,
              clinic_id: clinic_id,
              changeset: changeset,
              subaccount: subaccount,
              action: Routes.paystack_admin_path(conn, :update_subaccount, clinic_id, subaccount.id)
            )
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Subaccount not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, clinic_id))
    end
  end

  def activate_subaccount(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.activate_subaccount(id, clinic_id) do
      {:ok, _subaccount} ->
        conn
        |> put_flash(:info, "Subaccount activated successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, clinic_id))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to activate subaccount.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, clinic_id))
    end
  end

  def deactivate_subaccount(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.deactivate_subaccount(id, clinic_id) do
      {:ok, _subaccount} ->
        conn
        |> put_flash(:info, "Subaccount deactivated successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, clinic_id))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to deactivate subaccount.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, clinic_id))
    end
  end

  def delete_subaccount(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.get_subaccount(id, clinic_id) do
      {:ok, subaccount} ->
        case Paystack.delete_subaccount(subaccount) do
          {:ok, _deleted_subaccount} ->
            conn
            |> put_flash(:info, "Subaccount deleted successfully.")
            |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, clinic_id))

          {:error, _reason} ->
            conn
            |> put_flash(:error, "Failed to delete subaccount.")
            |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, clinic_id))
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Subaccount not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_subaccounts, clinic_id))
    end
  end

  # Transactions
  def list_transactions(conn, %{"clinic_id" => clinic_id_param}) do
    clinic_id = String.to_integer(clinic_id_param)
    transactions = Paystack.list_transactions(clinic_id)

    render(conn, :list_transactions, clinic_id: clinic_id, transactions: transactions)
  end

  def show_transaction(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.get_transaction(id, clinic_id) do
      {:ok, transaction} ->
        render(conn, :show_transaction, clinic_id: clinic_id, transaction: transaction)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Transaction not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :list_transactions, clinic_id))
    end
  end

  def verify_transaction(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.verify_transaction(id, clinic_id) do
      {:ok, _transaction} ->
        conn
        |> put_flash(:info, "Transaction verified successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :show_transaction, clinic_id, id))

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to verify transaction: #{reason}")
        |> redirect(to: Routes.paystack_admin_path(conn, :show_transaction, clinic_id, id))
    end
  end

  # Test Payment
  def test_payment_form(conn, %{"clinic_id" => clinic_id_param}) do
    clinic_id = String.to_integer(clinic_id_param)

    # Check if there's an active config
    case Paystack.get_active_config(clinic_id) do
      {:ok, _config} ->
        # Get active subaccount if available
        active_subaccount =
          case Paystack.get_active_subaccount(clinic_id) do
            {:ok, subaccount} -> subaccount
            _error -> nil
          end

        changeset = Paystack.change_transaction(%Transaction{clinic_id: clinic_id})

        render(conn, :test_payment_form,
          clinic_id: clinic_id,
          changeset: changeset,
          active_subaccount: active_subaccount,
          action: Routes.paystack_admin_path(conn, :process_test_payment, clinic_id)
        )

      {:error, _reason} ->
        conn
        |> put_flash(:error, "You need an active Paystack configuration to make test payments.")
        |> redirect(to: Routes.paystack_admin_path(conn, :dashboard, clinic_id))
    end
  end

  def process_test_payment(conn, %{
        "clinic_id" => clinic_id_param,
        "transaction" => transaction_params
      }) do
    clinic_id = String.to_integer(clinic_id_param)

    # Extract use_subaccount parameter
    use_subaccount = Map.get(transaction_params, "use_subaccount", "false") == "true"

    # Get subaccount_id if use_subaccount is true
    subaccount_id =
      if use_subaccount do
        case Paystack.get_active_subaccount(clinic_id) do
          {:ok, subaccount} -> subaccount.id
          _error -> nil
        end
      else
        nil
      end

    # Prepare payment params
    payment_params =
      Map.merge(transaction_params, %{
        "clinic_id" => clinic_id,
        "subaccount_id" => subaccount_id
      })

    case Paystack.initiate_payment(payment_params) do
      {:ok, %{authorization_url: url, transaction: _transaction}} ->
        conn
        |> put_flash(:info, "Test payment initiated successfully.")
        |> redirect(external: url)

      {:error, reason} ->
        active_subaccount =
          case Paystack.get_active_subaccount(clinic_id) do
            {:ok, subaccount} -> subaccount
            _error -> nil
          end

        changeset =
          Paystack.change_transaction(%Transaction{clinic_id: clinic_id})
          |> Ecto.Changeset.add_error(:base, reason)

        render(conn, :test_payment_form,
          clinic_id: clinic_id,
          changeset: changeset,
          active_subaccount: active_subaccount,
          action: Routes.paystack_admin_path(conn, :process_test_payment, clinic_id)
        )
    end
  end

  # Webhook logs
  def webhook_logs(conn, %{"clinic_id" => clinic_id_param}) do
    clinic_id = String.to_integer(clinic_id_param)
    webhook_logs = Paystack.list_webhook_logs(clinic_id)

    render(conn, :webhook_logs, clinic_id: clinic_id, webhook_logs: webhook_logs)
  end

  def webhook_details(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.get_webhook_log(id, clinic_id) do
      {:ok, webhook_log} ->
        render(conn, :webhook_details, clinic_id: clinic_id, webhook_log: webhook_log)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Webhook log not found.")
        |> redirect(to: Routes.paystack_admin_path(conn, :webhook_logs, clinic_id))
    end
  end

  def retry_webhook(conn, %{"clinic_id" => clinic_id_param, "id" => id}) do
    clinic_id = String.to_integer(clinic_id_param)

    case Paystack.retry_webhook(id, clinic_id) do
      {:ok, _webhook_log} ->
        conn
        |> put_flash(:info, "Webhook processing retried successfully.")
        |> redirect(to: Routes.paystack_admin_path(conn, :webhook_details, clinic_id, id))

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to retry webhook: #{reason}")
        |> redirect(to: Routes.paystack_admin_path(conn, :webhook_details, clinic_id, id))
    end
  end

  # Helper functions
  defp parse_date(""), do: nil

  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _error -> nil
    end
  end
end
