defmodule MoneyWatcher.Registry do
  @moduledoc """
  Registers and monitors the FraudChecker processes : {pid: name} and {ref: name} mapping
  """

  use GenServer

  ## Client API

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the fraud_checker pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the fraud_checker exists, `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a fraud_checker associated with the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  ## Server Callbacks

  def init(:ok) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  def handle_call({:lookup, name}, _from, {names, _} = state) do
    {:reply, Map.fetch(names, name), state}
  end

  @doc """
  If a process FraudChecker with given name exists, returns its pid. Otherwise, create a
  new one and register it.
  """
  def handle_call({:create, name}, _from, {names, refs}) do
    if Map.has_key?(names, name) do
      {:reply, Map.get(names, name), {names, refs}}
    else
      {:ok, fraud_checker} = MoneyWatcher.FraudCheckerSupervisor.start_fraud_checker([name: name])
      ref = Process.monitor(fraud_checker)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, fraud_checker)
      {:reply, fraud_checker, {names, refs}}
    end
  end

  @doc """
  Allows to cleanup any process stopped or crashed from the register
  """
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
