defmodule Counter do
	use GenServer

	def start_link() do
		{:ok, pid} = GenServer.start_link(Counter, 0)
		pid
	end

	def increment(pid) do
		GenServer.call(pid, :increment)
	end

	def decrement(pid) do
		GenServer.call(pid, :decrement)
	end

	def get(pid) do
		GenServer.call(pid, :get)
	end

	# implementation

	def handle_call(:decrement, _from, count) do
		{:reply, count - 1 , count - 1}
	end

	def handle_call(:get, _from, count) do
		{:reply, count , count}
	end

	def handle_call(:increment, _from, count) do
		{:reply, count + 1, count + 1}
	end
end