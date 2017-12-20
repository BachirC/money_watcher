# MoneyWatcher

- Elixir 1.5.2
- Erlang/OTP 20

## Installation

- Clone the project
- `mix deps.get`
- Fire up a console `iex -S mix`
- Start the HTTP server

```elixir
iex(1)> {:ok, _} = Plug.Adapters.Cowboy.http MoneyWatcher, []
Starting MoneyWatcher...
{:ok, #PID<0.213.0>}
iex(2)>
```
- Use example

```http
curl -X POST http://localhost:4000/accounts/DE89370400440532013000/debit?amount=1000000
account_id : IBAN format
amount : Strictly positive integer (€ cents)

cat money_watcher_log.txt
```
- When the debit for an account goes over 10k € (1M € cents) in the past 20min, a warning is logged in `money_watcher_log.txt`.

- To launch tests `mix test`. Logs file is `money_watcher_log_test.txt`.
