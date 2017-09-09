defmodule AnimationTest.GUI do
  use Agent
  alias AnimationTest.Window

  def start_link(options) do
    Agent.start_link(fn -> Window.start_link(options) end)
  end
end
