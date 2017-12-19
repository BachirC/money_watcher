defmodule MoneyWatcher.FraudCheckerTest do
  use ExUnit.Case, async: true

  alias MoneyWatcher.FraudChecker

  @fraud_debit Application.get_env(:money_watcher, :fraud_debit_in_euro_cents)
  @fraud_period Application.get_env(:money_watcher, :fraud_period_in_milli_seconds)
  @log_filename Application.get_env(:money_watcher, :log_filename)

  setup do
    {:ok, fraud_checker} = start_supervised({FraudChecker, {:name, "IBAN"}})
    %{fraud_checker: fraud_checker}
  end

  test "stores transaction", %{fraud_checker: fraud_checker} do
    assert FraudChecker.get(fraud_checker) == []

    timestamp = :os.system_time(:milli_seconds)
    FraudChecker.add(fraud_checker, {10, timestamp})
    assert FraudChecker.get(fraud_checker) == [{10, timestamp}]
  end

  test "calculates debit on fraud period", %{fraud_checker: fraud_checker} do
    timestamp = :os.system_time(:milli_seconds)

    FraudChecker.add(fraud_checker, {@fraud_debit * 2, timestamp - @fraud_period - 1_000})
    FraudChecker.add(fraud_checker, {@fraud_debit / 2, timestamp - @fraud_period + 1_000})
    FraudChecker.add(fraud_checker, {@fraud_debit / 2, timestamp})

    expected = [
      {@fraud_debit / 2, timestamp - @fraud_period + 1_000},
      {@fraud_debit / 2, timestamp}
    ]

    FraudChecker.check_debit(fraud_checker)
    {_, transactions} = :sys.get_state(fraud_checker)
    assert transactions -- expected == []
    counter = @log_filename
              |> File.stream!()
              |> Enum.count()

    assert counter == 1
    :ok = File.rm(@log_filename)
  end

  test "are temporary workers" do
    assert Supervisor.child_spec(FraudChecker, []).restart == :temporary
  end
end
