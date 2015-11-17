defmodule FailureCounter do
	use GenServer

	def start_link() do
		GenServer.start_link(FailureCounter, %{}, name: __MODULE__)
	end

	def increment_and_get(url) do
		GenServer.call(__MODULE__, {:increment_and_get, url})
	end

	def handle_call({:increment_and_get, url}, _from, counts) do
		new_val = Map.get(counts, url, 0) + 1
		# map = Map.get_and_update(map, url, fn n -> n+1)
		map = Map.put(counts, url, new_val)
		{:reply, new_val, map}
	end
end