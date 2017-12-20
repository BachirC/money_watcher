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

    transac = {10, :os.system_time(:milli_seconds)}
    FraudChecker.add(fraud_checker, transac)
    assert FraudChecker.get(fraud_checker) == [transac]
  end

  test "considers only transactions in fraud period when calculating debit", %{fraud_checker: fraud_checker} do
    timestamp = :os.system_time(:milli_seconds)

    transac1 = {@fraud_debit * 2, timestamp - @fraud_period - 1_000}
    transac2 = {@fraud_debit / 2, timestamp - @fraud_period + 1_000}
    transac3 = {@fraud_debit / 2, timestamp}

    expected = [transac3, transac2]

    FraudChecker.add(fraud_checker, transac1)
    FraudChecker.add(fraud_checker, transac2)
    FraudChecker.add(fraud_checker, transac3)
    FraudChecker.check_debit(fraud_checker)
    {_, transactions} = :sys.get_state(fraud_checker)

    assert expected == transactions
  end

  test "warns when fraud debit is reached", %{fraud_checker: fraud_checker} do
    if File.exists?(@log_filename), do: File.rm(@log_filename)

    transac = {@fraud_debit + 1, :os.system_time(:milli_seconds)}
    FraudChecker.add(fraud_checker, transac)
    FraudChecker.check_debit(fraud_checker)
    # Wait for the processing
    {_, _} = :sys.get_state(fraud_checker)

    assert File.exists?(@log_filename) == true

    counter = @log_filename
              |> File.stream!()
              |> Enum.count()
    :ok = File.rm(@log_filename)

    assert counter == 1
  end

  test "doesn't warn when fraud debit not reached", %{fraud_checker: fraud_checker} do
    if File.exists?(@log_filename), do: File.rm(@log_filename)

    transac = {@fraud_debit - 1, :os.system_time(:milli_seconds)}
    FraudChecker.add(fraud_checker, transac)
    FraudChecker.check_debit(fraud_checker)
    # Wait for the processing
    {_, _} = :sys.get_state(fraud_checker)

    assert File.exists?(@log_filename) == false
  end

  test "are temporary workers" do
    assert Supervisor.child_spec(FraudChecker, []).restart == :temporary
  end
end
