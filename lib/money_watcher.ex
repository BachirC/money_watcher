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
    Plug.Conn.send_resp(conn, :ok, "")
  end

  def route(_, _, conn) do
    Plug.Conn.send_resp(conn, :ok, "")
  end
end
