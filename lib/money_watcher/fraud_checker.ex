defmodule MoneyWatcher.FraudChecker do
  @moduledoc """
  Handles the business logic for the fraud detection mechanism
  """

  use GenServer, restart: :temporary

  @fraudulent_debit_in_cts 1_000_000
  @fraud_period_in_milli_seconds 1_200_000
  @log_filename Application.get_env(:money_watcher, :log_filename)

  @doc """
  Start the agent for a given account
  """

  def start_link([], initial_state) do
    GenServer.start_link(__MODULE__, initial_state)
  end

  @doc """
  Retrieve the current account debit
  """
  def add(fraud_checker, transaction) do
    GenServer.cast(fraud_checker, {:add, transaction})
  end

  def get(fraud_checker) do
    GenServer.call(fraud_checker, :get)
  end

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

  @doc """
  calculates the debit on the last 20 minutes and logs a warning into a file if the account
  is considered fraudulent
  """
  def handle_cast(:check_debit, {account_id, transactions}) do
    min_time = :os.system_time(:milli_seconds) - @fraud_period_in_milli_seconds
    # Keep only relevant transactions for fraud check
    transactions = transactions
                   |> Enum.filter(fn(transaction) -> elem(transaction, 1) >= min_time end)

    total_debit = transactions
                  |> Enum.map_reduce(0, fn(transaction, acc) -> {transaction, elem(transaction, 0) + acc} end)
                  |> elem(1)

    if total_debit >= @fraudulent_debit_in_cts, do: log_warning(total_debit, account_id, List.first(transactions))
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
