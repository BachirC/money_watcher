defmodule MoneyWatcher.RegistryTest do
  use ExUnit.Case, async: true

  alias MoneyWatcher.{Registry, FraudChecker}
  setup do
    {:ok, registry} = start_supervised(Registry)
    %{registry: registry, iban: "IBAN"}
  end

  test "spawns fraud_checkers", %{registry: registry, iban: iban} do
    assert Registry.lookup(registry, iban) == :error

    Registry.create(registry, iban)
    assert {:ok, fraud_checker} = Registry.lookup(registry, iban)

    timestamp = :os.system_time(:milli_seconds)
    transaction = {100_000, timestamp}
    FraudChecker.add(fraud_checker, transaction)
    assert FraudChecker.get(fraud_checker) == [transaction]
  end

  test "removes fraud_checker on exit", %{registry: registry, iban: iban} do
    Registry.create(registry, iban)
    {:ok, fraud_checker} = Registry.lookup(registry, iban)
    GenServer.stop(fraud_checker)
    assert Registry.lookup(registry, iban) == :error
  end

  test "removes bucket on crash", %{registry: registry, iban: iban} do
    Registry.create(registry, iban)
    {:ok, fraud_checker} = Registry.lookup(registry, iban)

    # Stop the bucket with non-normal reason
    GenServer.stop(fraud_checker, :shutdown)
    assert Registry.lookup(registry, iban) == :error
  end
end
