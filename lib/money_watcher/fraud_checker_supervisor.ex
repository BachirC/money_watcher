defmodule MoneyWatcher.FraudCheckerSupervisor do
  @moduledoc """
  Supervises the FraudChecker processes, handles creation and init strategy. simple one for one
  strategy to manually start new FraucChecker processes
  """

  use Supervisor

  @name MoneyWatcher.FraudCheckerSupervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_fraud_checker(initial_state) do
    Supervisor.start_child(@name, initial_state)
  end

  def init(:ok) do
    Supervisor.init([MoneyWatcher.FraudChecker], strategy: :simple_one_for_one)
  end
end
