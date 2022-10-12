defmodule PlugImageProcessing.Supervisor do
  use Supervisor

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  def child_spec(opts),
    do: Supervisor.child_spec(super(opts), id: Keyword.get(opts, :name, __MODULE__))

  @impl Supervisor
  def init(_opts) do
    children = [
      {Finch, name: PlugImageProcessing.Sources.URL}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
