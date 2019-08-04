defmodule CaptureGoWeb.GamesView do
  @moduledoc """
  Renders a go board with SVG.
  "x", "y", and "rank" refer to go board coordinates
  "x_pos", "y_pos", and "position" refer to SVG coordinates
  """

  use CaptureGoWeb, :view

  alias CaptureGoWeb.LiveGame
  alias CaptureGo.Goban
  alias CaptureGo.Accounts.User
  alias CaptureGo.Games.Game

  def display_winner(%Goban{winner: winner}) do
    case winner do
      nil -> ""
      :black -> "Black wins!"
      :white -> "White wins!"
      _ -> "Game Over"
    end
  end

  def display_turn(%Goban{turn: turn} = goban) do
    if Goban.over?(goban) do
      ""
    else
      color =
        case turn do
          :white -> "White"
          :black -> "Black"
        end

      "#{color} to play"
    end
  end

  def pass_button(%Game{} = game, %User{} = user) do
    game_action_button(game, user, "pass", "Pass Turn")
  end

  def pass_button(_game, _nil_user), do: ""

  def resign_button(%Game{} = game, %User{} = user) do
    game_action_button(game, user, "resign", "Resign")
  end

  def resign_button(_game, _nil_user), do: ""

  def game_action_button(%Game{} = game, %User{} = user, action, display) do
    active = Game.active_player?(game, user.id)

    if display_game_buttons?(game, user.id) do
      ~E"""
      <button class="button"
        <%= game_action_attrs(active, action) %>
      >
        <%= display %>
      </button>
      """
    end
  end

  defp display_game_buttons?(game, user_id) do
    Game.participant?(game, user_id) && game.state == :started
  end

  def game_action_attrs(button_active, phx_click) do
    if button_active do
      "phx-click=\"#{phx_click}\""
    else
      "disabled"
    end
  end

  @margin 50
  @intersection_size_length 100
  @stone_radius @intersection_size_length / 4
  # the amount to truncate lines to make the board not look like a hash
  @margin_truncation 1 + @intersection_size_length / 2
  @star_point_radius 7

  def nine_by_nine() do
    map_intersections(&render_intersection/1)
  end

  def star_points() do
    for x <- [2, 4, 6], y <- [2, 4, 6] do
      %{x_pos: x_pos, y_pos: y_pos} = intersection_position({x, y})
      circle(%{cx: x_pos, cy: y_pos, r: @star_point_radius})
    end
  end

  def render_stones(goban) do
    map_intersections(fn intersection ->
      stone(intersection, goban)
    end)
  end

  # General

  defp map_intersections(render_fn) do
    for x <- 0..8, y <- 0..8 do
      {x, y}
      |> intersection_position()
      |> render_fn.()
    end
  end

  defp intersection_position({x, y}) do
    %{x: x, y: y, x_pos: position(x), y_pos: position(y)}
  end

  defp position(rank) do
    rank * (@intersection_size_length / 2) + @margin
  end

  # Stones

  defp stone(%{x: x, y: y, x_pos: x_pos, y_pos: y_pos}, goban) do
    {:ok, color} = Goban.stone_at(goban, {x, y})

    props = %{
      cx: x_pos,
      cy: y_pos,
      r: @stone_radius,
      style: stone_style(color),
      phx_click: stone_phx_click(color, x, y)
    }

    circle(props)
  end

  defp stone_style(color) do
    case color do
      :white -> "fill:white;stroke:black;"
      :black -> nil
      nil -> "opacity:0;"
    end
  end

  defp stone_phx_click(color, x, y) do
    if color do
      nil
    else
      "make_move:#{x},#{y}"
    end
  end

  defp circle(%{cx: cx, cy: cy, r: r} = props) do
    phx_click = props[:phx_click]
    style = props[:style]

    ~E"""
    <circle cx="<%= cx %>" cy="<%= cy %>" r="<%= r %>"
      <%= if phx_click do %>
        phx-click="<%= phx_click %>"
      <% end %>
      <%= if style do %>
        style="<%= style %>"
      <% end %>
    />
    """
  end

  # Background board

  defp render_intersection(intersection_position) do
    ~E"""
    <%= truncated_horizontal_line(intersection_position) %>
    <%= truncated_vertical_line(intersection_position) %>
    """
  end

  defp truncated_vertical_line(%{y_pos: y_pos, x_pos: x_pos, x: x}) do
    x_start = truncate_line_start(x, x_pos)
    x_end = truncate_line_end(x, x_pos)

    props = %{
      y1: y_pos,
      y2: y_pos,
      x1: x_start,
      x2: x_end
    }

    line(props)
  end

  defp truncated_horizontal_line(%{y_pos: y_pos, x_pos: x_pos, y: y}) do
    y_start = truncate_line_start(y, y_pos)
    y_end = truncate_line_end(y, y_pos)

    props = %{
      x1: x_pos,
      x2: x_pos,
      y1: y_start,
      y2: y_end
    }

    line(props)
  end

  defp truncate_line_start(rank, position) do
    case rank do
      0 -> position
      _ -> position - @margin_truncation
    end
  end

  defp truncate_line_end(rank, position) do
    case rank do
      8 -> position
      _ -> position + @margin_truncation
    end
  end

  defp line(%{x1: x1, y1: y1, x2: x2, y2: y2}) do
    ~E"""
    <line x1="<%= x1 %>" y1="<%= y1 %>" x2="<%= x2 %>" y2="<%= y2 %>"
          stroke="black" stroke-width="3" />
    """
  end
end
