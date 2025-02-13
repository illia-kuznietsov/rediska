defmodule RediskaWeb.RediskaLive do
  use RediskaWeb, :live_view

  def mount(_params, _session, socket) do
    IO.inspect(%{key: "", value: ""} |> to_form())
    {:ok, socket |> assign(show_modal: false, selected_row: nil, page: 1, page_count: 5)}
  end

  def handle_event("select_row", params, socket) do
    {:noreply, socket |> assign(selected_row: params)}
  end

  def handle_event("change_page", %{"dir" => dir}, socket) do
    new_page = socket.assigns.page
    |> then(&(&1 + String.to_integer(dir)))
    |> max(1)
    |> min(socket.assigns.page_count)
    {:noreply, socket |> assign(page: new_page)}
  end

  attr :text, :string
  attr :type, :string
  attr :locked, :boolean
  attr :on_click, :fun

  def custom_button(%{type: "regular"} = assigns) do
    ~H"""
    <button class="px-2 py-5 h-fit rounded-full bg-green-500 text-white font-bold shadow-lg" phx-click={@on_click}>
      <span>{@text}</span>
    </button>
    """
  end

  def custom_button(%{type: "lockable"} = assigns) do
    ~H"""
    <button
      class="px-2 py-5 h-fit rounded-full bg-pink-500 disabled:bg-pink-100 disabled:border disabled:cursor-not-allowed px-2 text-white font-bold shadow-lg"
      disabled={@locked}
    >
      <span>{@text}</span>
    </button>
    """
  end

  attr :items, :list, required: true
  attr :page, :integer, default: 1
  attr :page_size, :integer, default: 5
  attr :selected_row, :map

  def custom_table(assigns) do
    ~H"""
    <table class="table-auto bg-white rounded-lg shadow-lg border-collapse select-none">
      <thead class="bg-pink-500 opacity-75">
        <tr class="text-white">
          <th scope="col" class="px-4 py-2 border border-white rounded-tl-lg">
            Key
          </th>
          <th scope="col" class="px-4 py-2 border border-white rounded-tr-lg">
            Value
          </th>
        </tr>
      </thead>
      <tbody>
        <tr
          :for={row <- @items}
          phx-click={JS.push("select_row", value: row)}
          class={"border-b hover:cursor-pointer " <>if @selected_row == row, do: "selected-row", else: "hover:bg-pink-100"}
        >
          <td class="px-4 py-2 text-center font-bold border-e">
            {row["key"]}
          </td>
          <td class="relative px-4 py-2 text-center">
            {row["value"]}
            <svg :if={@selected_row == row} class="selected-icon size-6 rotate-90 text-pink-500">
              <use href="/images/sprites.svg#radish-icon"></use>
            </svg>
          </td>
        </tr>
        <tr class="border-b" :for={_row <- String.duplicate("0", @page_size - length(@items)) |> String.to_charlist}>
          <td class="px-4 py-2 text-center font-bold border-e">&nbsp;</td>
          <td class="relative px-4 py-2 text-center">&nbsp;</td>
        </tr>
      </tbody>
      <tfoot>
        <tr>
          <td class="px-4 py-2">
            <span class="text-pink-500 font-bold">
              Page: {@page}
            </span>
          </td>
          <td class="flex justify-end px-4 py-2">
            <svg class="size-6 rotate-180 text-pink-500 transition-transform duration-200 hover:scale-125 hover:cursor-pointer" phx-click="change_page" phx-value-dir="-1">
              <use href="/images/sprites.svg#arrow-left"></use>
            </svg>
            <svg class="size-6 text-pink-500 transition-transform duration-200 hover:scale-125 hover:cursor-pointer" phx-click="change_page" phx-value-dir="1">
              <use href="/images/sprites.svg#arrow-left"></use>
            </svg>
          </td>
        </tr>
      </tfoot>
    </table>
    """
  end
end
