defmodule Counter do
	use GenServer
	require Logger

	def start_link() do
		{:ok, pid} = GenServer.start_link(Counter, 0)
		pid
	end

	def increment(pid, n \\ 1) do
		GenServer.call(pid, {:increment, n})
	end

	def decrement(pid) do
		GenServer.call(pid, :decrement)
	end

	def get(pid) do
		GenServer.call(pid, :get)
	end

	# implementation

	def handle_call(:decrement, _from, count) do
		Logger.debug "decrementing by one from #{count} -> #{count-1}"
		{:reply, count - 1 , count - 1}
	end

	def handle_call(:get, _from, count) do
		{:reply, count , count}
	end

	def handle_call({:increment, n}, _from, count) do
		Logger.debug "incrementing by #{n} from #{count} -> #{count+n}"
		{:reply, count + n, count + n}
	end
end