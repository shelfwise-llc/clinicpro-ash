defmodule Clinicpro.Auth.RateLimiter do
  @moduledoc """
  Production-grade rate limiting for authentication attempts
  """

  use GenServer
  require Logger

  @table_name :auth_rate_limits
  @max_attempts 5
  @lockout_duration_minutes 60
  @cleanup_interval_minutes 10

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(@table_name, [:named_table, :public, read_concurrency: true])
    schedule_cleanup()
    {:ok, %{}}
  end

  def check_rate_limit(identifier, ip_address \\ nil) do
    key = rate_limit_key(identifier, ip_address)
    now = System.system_time(:second)

    case :ets.lookup(@table_name, key) do
      [] ->
        # First attempt
        :ets.insert(@table_name, {key, 1, now, nil})
        {:ok, @max_attempts - 1}

      [{^key, attempts, first_attempt, locked_until}] ->
        cond do
          # Account is locked
          locked_until && now < locked_until ->
            remaining_lockout = locked_until - now
            {:error, :locked, remaining_lockout}

          # Reset window if enough time has passed
          now - first_attempt > 3600 ->
            :ets.insert(@table_name, {key, 1, now, nil})
            {:ok, @max_attempts - 1}

          # Within rate limit
          attempts < @max_attempts ->
            :ets.update_counter(@table_name, key, {2, 1})
            {:ok, @max_attempts - attempts - 1}

          # Exceeded rate limit - lock account
          true ->
            lockout_until = now + @lockout_duration_minutes * 60
            :ets.insert(@table_name, {key, attempts + 1, first_attempt, lockout_until})

            # Log security event
            Logger.warn("Account locked due to too many failed attempts",
              identifier: identifier,
              ip_address: ip_address,
              attempts: attempts + 1
            )

            {:error, :rate_limited, @lockout_duration_minutes}
        end
    end
  end

  def record_successful_login(identifier, ip_address \\ nil) do
    key = rate_limit_key(identifier, ip_address)
    :ets.delete(@table_name, key)

    Logger.info("Successful login",
      identifier: identifier,
      ip_address: ip_address
    )
  end

  def unlock_account(identifier, ip_address \\ nil) do
    key = rate_limit_key(identifier, ip_address)
    :ets.delete(@table_name, key)

    Logger.info("Account manually unlocked",
      identifier: identifier,
      ip_address: ip_address
    )
  end

  def get_account_status(identifier, ip_address \\ nil) do
    key = rate_limit_key(identifier, ip_address)
    now = System.system_time(:second)

    case :ets.lookup(@table_name, key) do
      [] ->
        {:ok, %{attempts: 0, locked: false, remaining_attempts: @max_attempts}}

      [{^key, attempts, _first_attempt, locked_until}] ->
        locked = locked_until && now < locked_until
        remaining_lockout = if locked, do: locked_until - now, else: 0

        {:ok,
         %{
           attempts: attempts,
           locked: locked,
           remaining_attempts: max(0, @max_attempts - attempts),
           remaining_lockout_seconds: remaining_lockout
         }}
    end
  end

  # Private functions
  defp rate_limit_key(identifier, ip_address) do
    # Combine identifier and IP for more granular rate limiting
    case ip_address do
      nil -> "auth:#{identifier}"
      ip -> "auth:#{identifier}:#{ip}"
    end
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval_minutes * 60 * 1000)
  end

  def handle_info(:cleanup, state) do
    cleanup_expired_entries()
    schedule_cleanup()
    {:noreply, state}
  end

  defp cleanup_expired_entries do
    now = System.system_time(:second)

    # Remove entries older than 24 hours
    cutoff = now - 24 * 3600

    :ets.select_delete(@table_name, [
      {{:_, :_, :"$1", :_}, [{:<, :"$1", cutoff}], [true]}
    ])
  end
end
