defmodule MoneyWatcher.FraudChecker do
  @moduledoc """
  Handles the business logic for the fraud detection mechanism
  """

  use GenServer, restart: :temporary

  @fraud_debit_in_cts Application.get_env(:money_watcher, :fraud_debit_in_euro_cents)
  @fraud_period_in_milli_seconds Application.get_env(:money_watcher, :fraud_period_in_milli_seconds)
  @log_filename Application.get_env(:money_watcher, :log_filename)

  @doc """
  Starts the agent for a given account
  """
  def start_link(opts \\ [], initial_state) do
    GenServer.start_link(__MODULE__, initial_state)
  end

  @doc """
  Adds a transaction to the state
  """
  def add(fraud_checker, transaction) do
    GenServer.cast(fraud_checker, {:add, transaction})
  end

  @doc """
  Retrieves all transactions in the state
  """
  def get(fraud_checker) do
    GenServer.call(fraud_checker, :get)
  end

  @doc """
  Checks if the account is fraudulent
  """
  def check_debit(fraud_checker) do
    GenServer.cast(fraud_checker, :check_debit)
  end

  # Server

  def init({:name, account_id}) do
    {:ok, {account_id, []}}
  end

  def handle_call(:get, _from,  {_account_id, transactions} = state) do
    {:reply, transactions, state}
  end

  def handle_cast({:add, transaction}, {account_id, transactions}) do
    transactions = [transaction | transactions]
    {:noreply, {account_id, transactions}}
  end

  def handle_cast(:check_debit, {account_id, transactions}) do
    min_time = :os.system_time(:milli_seconds) - @fraud_period_in_milli_seconds
    # Keep only relevant transactions for fraud check
    transactions = transactions
                   |> Enum.filter(fn(transaction) -> elem(transaction, 1) >= min_time end)

    total_debit = transactions
                  |> Enum.map_reduce(0, fn(transaction, acc) -> {transaction, elem(transaction, 0) + acc} end)
                  |> elem(1)

    if total_debit >= @fraud_debit_in_cts, do: log_warning(total_debit, account_id, List.first(transactions))
    {:noreply, {account_id, transactions}}
  end

  def log_warning(total_debit, account_id, {_amount, timestamp}) do
    time = timestamp
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_iso8601()
    log = """
    Account=#{account_id} last_transaction_at=#{time} Debit_in_last_20_min_in_cts=#{total_debit} \
    Potential fraudulent account detected
    """

    File.open(@log_filename, [:append], fn(file) ->
      IO.write(file, log)
    end)
  end
end
