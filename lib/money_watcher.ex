defmodule MoneyWatcher do
  @moduledoc """
  Entry point of the app. Handles the start of the Supervisor and routing.
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
    url_params = fetch_query_params(conn).params
    params = Map.merge(%{"account_id" => account_id}, url_params)
    if validated_params = validate_params(params) do
      with pid <- MoneyWatcher.Registry.create(MoneyWatcher.Registry, account_id),
           :ok <- FraudChecker.add(pid, {validated_params.amount, :os.system_time(:milli_seconds)}),
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

  defp validate_params(%{"account_id" => account_id, "amount" => amount}) do
    with {amount, ""} <- Integer.parse(amount),
         true <- Bankster.iban_valid?(account_id) && amount > 0 do
           %{account_id: account_id, amount: amount}
    else
      _err -> false
    end
  end
  defp validate_params(_), do: false
end
