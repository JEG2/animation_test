defmodule AnimationTest.Canvas do
  require Logger
  require Record
  alias AnimationTest.FrameRate

  @behaviour :wx_object

  defstruct ~w[panel background_brush rectangle_brush font radians]a
  Record.defrecordp(
    :wx, Record.extract(:wx, from_lib: "wx/include/wx.hrl")
  )
  Record.defrecordp(
    :wxPaint, Record.extract(:wxPaint, from_lib: "wx/include/wx.hrl")
  )

  # Client API

  def start_link(parent, options) do
    :wx_object.start_link(__MODULE__, [parent, options], [ ])
  end

  # Server API

  def init(args) do
    Process.send_after(self(), :tick, 16)

    :wx.batch(fn -> do_init(args) end)
  end

  def handle_call(:shutdown, _from, state = %__MODULE__{panel: panel}) do
    :wxPanel.destroy(panel)
    {:reply, :ok, state}
  end
  def handle_call(message, _from, state) do
    Logger.debug "Unhandled call:  #{inspect message}"
    {:reply, :ok, state}
  end

  def handle_cast(message, state) do
    Logger.debug "Unhandled cast:  #{inspect message}"
    {:noreply, state}
  end

  def handle_sync_event(wx(event: wxPaint()), _paint_event, state) do
    paint(state)
    :ok
  end

  def handle_event(wx, state) do
    Logger.debug "Unhandled event:  #{inspect wx}"
    {:noreply, state}
  end

  def handle_info(
    :tick,
    state = %__MODULE__{panel: panel, radians: radians}
  ) do
    :wxFrame.refresh(panel, eraseBackground: false)
    pi2 = :math.pi * 2
    new_radians =
      if radians >= pi2 do
        0.0
      else
        radians + (pi2 / 60)
      end
    Process.send_after(self(), :tick, 16)
    {:noreply, %__MODULE__{state | radians: new_radians}}
  end
  def handle_info(info, state) do
    Logger.debug "Unhandled info:  #{inspect info}"
    {:noreply, state}
  end

  def code_change(_old_vsn, _state, _extra) do
    {:error, :not_implemented}
  end

  def terminate(_reason, _state) do
    :ok
  end

  # Helpers

  defp do_init([parent, _options]) do
    panel = :wxPanel.new(parent)
    background_brush = :wxBrush.new({0, 0, 0})
    rectangle_brush = :wxBrush.new({255, 0, 0, 200})
    font = :wxFont.new
    :wxFont.setPointSize(font, 16)

    :wxFrame.connect(panel, :paint, [:callback])

    state = %__MODULE__{
      panel: panel,
      background_brush: background_brush,
      rectangle_brush: rectangle_brush,
      font: font,
      radians: 0.0
    }
    {panel, state}
  end

  defp paint(
    %__MODULE__{
      panel: panel,
      background_brush: background_brush,
      rectangle_brush: rectangle_brush,
      font: font,
      radians: radians
    }
  ) do
    {width, height} = :wxPanel.getClientSize(panel)

    panel_context = :wxPaintDC.new(panel)
    graphics_context = :wxGraphicsContext.create(panel_context)

    fps = FrameRate.calculate

    :wxGraphicsContext.setBrush(graphics_context, background_brush)
    :wxGraphicsContext.drawRectangle(graphics_context, 0, 0, width, height)
    graphics_font = :wxGraphicsContext.createFont(
      graphics_context,
      font,
      col: {0, 0, 200}
    )
    :wxGraphicsContext.setFont(graphics_context, graphics_font)
    text = "FPS:  #{fps}"
    {_text_width, text_height, _descent, _leading} =
      :wxGraphicsContext.getTextExtent(graphics_context, text)
    :wxGraphicsContext.drawText(
      graphics_context,
      text,
      10,
      400 - (text_height + 10)
    )

    :wxGraphicsContext.rotate(graphics_context, radians)
    :wxGraphicsContext.setBrush(graphics_context, rectangle_brush)
    :wxGraphicsContext.drawRectangle(
      graphics_context,
      50,
      100,
      width - 100,
      height - 200
    )

    :wxGraphicsContext.destroy(graphics_context)
    :wxPaintDC.destroy(panel_context)
  end
end
