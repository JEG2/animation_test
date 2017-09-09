defmodule AnimationTest.FrameRate do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> System.os_time(:millisecond) end, name: __MODULE__)
  end

  def calculate do
    Agent.get_and_update(__MODULE__, fn last_time ->
      current_time = System.os_time(:millisecond)
      frames = round(1 / ((current_time - last_time) / 1_000))
      {frames, current_time}
    end)
  end
end
