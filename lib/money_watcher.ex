defmodule MoneyWatcher do
  @moduledoc """
  Documentation for MoneyWatcher.
  """

  use Application
  alias MoneyWatcher.FraudChecker
  import Plug.Conn

  def start(_type, _args) do
    MoneyWatcher.Supervisor.start_link(name: MoneyWatcher.Supervisor)
  end

  def init(default_options) do
    IO.puts "Starting MoneyWatcher..."
    default_options
  end

  def call(conn, _options) do
    route(conn.method, conn.path_info, conn)
  end

  def route("POST", ["accounts", account_id, "debit"], conn) do
    %{"amount" => amount} = fetch_query_params(conn).params
    if validate_params(%{account_id: account_id, amount: amount}) do
      with pid <- MoneyWatcher.Registry.create(MoneyWatcher.Registry, account_id),
           :ok <- FraudChecker.add(pid, {String.to_integer(amount), :os.system_time(:milli_seconds)}),
           :ok <- FraudChecker.check_debit(pid) do
             Plug.Conn.send_resp(conn, :ok, "")
           end
    else
      Plug.Conn.send_resp(conn, :ok, "Invalid params")
    end
  end

  def route(_, _, conn) do
    Plug.Conn.send_resp(conn, :ok, "")
  end

  defp validate_params(params) do
    with {amount, ""} <- Integer.parse(params.amount),
         true <- Bankster.iban_valid?(params.account_id) && amount > 0 do
           true
    else
      _err -> false
    end
  end
end
