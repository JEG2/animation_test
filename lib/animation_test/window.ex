defmodule AnimationTest.Window do
  use Bitwise
  require Logger
  require Record
  alias AnimationTest.Canvas

  @behaviour :wx_object

  defstruct ~w[frame panel]a
  Record.defrecordp(
    :wx, Record.extract(:wx, from_lib: "wx/include/wx.hrl")
  )
  Record.defrecordp(
    :wxClose, Record.extract(:wxClose, from_lib: "wx/include/wx.hrl")
  )

  # Client API

  def start_link(options) do
    :wx_object.start_link(__MODULE__, options, [ ])
  end

  # Server API

  def init(options) do
    Process.flag(:trap_exit, true)

    :wx.new

    :wx.batch(fn -> do_init(options) end)
  end

  def handle_call(message, _from, state) do
    Logger.debug "Unhandled call:  #{inspect message}"
    {:reply, :ok, state}
  end

  def handle_cast(message, state) do
    Logger.debug "Unhandled cast:  #{inspect message}"
    {:noreply, state}
  end

  def handle_event(wx(event: wxClose()), state) do
    System.halt(0)
    {:noreply, state}
  end
  def handle_event(wx, state) do
    Logger.debug "Unhandled event:  #{inspect wx}"
    {:noreply, state}
  end

  def handle_info(info, state) do
    Logger.debug "Unhandled info:  #{inspect info}"
    {:noreply, state}
  end

  def code_change(_old_vsn, _state, _extra) do
    {:error, :not_implemented}
  end

  def terminate(_reason, %__MODULE__{frame: frame, panel: panel}) do
    :wx_object.call(panel, :shutdown)
    :wxFrame.destroy(frame)
    :wx.destroy
  end

  # Helpers

  defp do_init(options) do
    frame_style =
      :wx_const.wxDEFAULT_FRAME_STYLE ^^^ :wx_const.wxRESIZE_BORDER
    frame =
      :wxFrame.new(:wx.null, :wx_const.wxID_ANY, 'Canvas', style: frame_style)
    panel = Canvas.start_link(frame, options)

    :wxFrame.setClientSize(frame, {400, 400})
    sizer = :wxBoxSizer.new(:wx_const.wxVERTICAL)
    :wxSizer.add(sizer, panel, flag: :wx_const.wxEXPAND, proportion: 1)
    :wxPanel.setSizer(frame, sizer)
    :wxSizer.layout(sizer)
    frame_size = :wxFrame.getSize(frame)
    :wxFrame.setMinSize(frame, frame_size)
    :wxFrame.setMaxSize(frame, frame_size)

    :wxFrame.connect(frame, :close_window)

    :wxFrame.center(frame)
    :wxFrame.show(frame)

    {frame, %__MODULE__{frame: frame, panel: panel}}
  end
end
