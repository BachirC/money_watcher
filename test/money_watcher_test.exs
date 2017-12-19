defmodule MoneyWatcherTest do
  use ExUnit.Case
  doctest MoneyWatcher

  test "greets the world" do
    assert MoneyWatcher.hello() == :world
  end
end
