defmodule MoneyWatcherTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "/accounts/:account_id/debit" do
    conn = conn(:post, "/accounts/DE89370400440532013000/debit", %{"amount" => "1000"})
    conn = MoneyWatcher.call(conn, [])
    assert conn.state == :sent
    assert conn.status == 200
  end

  test "with invalid account_id" do
    conn = conn(:post, "/accounts/INVALID_IBAN/debit", %{"amount" => "1000"})
    conn = MoneyWatcher.call(conn, [])
    assert conn.state == :sent
    assert conn.status == 200
  end

  test "with invalid amount" do
    conn = conn(:post, "/accounts/DE89370400440532013000/debit", %{"amount" => "-1000"})
    conn = MoneyWatcher.call(conn, [])
    assert conn.state == :sent
    assert conn.status == 200
  end

  test "with no amount" do
    conn = conn(:post, "/accounts/DE89370400440532013000/debit")
    conn = MoneyWatcher.call(conn, [])
    assert conn.state == :sent
    assert conn.status == 200
  end

  test "invalid url" do
    conn = conn(:post, "/non_existant")
    conn = MoneyWatcher.call(conn, [])
    assert conn.state == :sent
    assert conn.status == 200
  end
end
