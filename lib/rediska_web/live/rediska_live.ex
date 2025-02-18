defmodule RediskaWeb.RediskaLive do
  use RediskaWeb, :live_view
  alias Rediska.Schema, as: Item

  @page_size 5
  def mount(_params, _session, socket) do
    items = Rediska.Utils.get_items()
    form = Item.changeset(%{}) |> to_form()

    {:ok,
     socket
     |> assign(
       form: form,
       selected_row: nil,
       page: 1,
       page_count: Float.ceil(length(items) / @page_size) |> trunc(),
       items: items,
       modal_enabled: true
     )}
  end

  def handle_event("select_row", params, socket) do
    {:noreply, socket |> assign(selected_row: params)}
  end

  def handle_event("clean_select", _, socket) do
    {:noreply, socket |> assign(selected_row: nil)}
  end

  def handle_event("enable_modals", _, socket) do
    {:noreply, socket |> assign(modal_enabled: true)}
  end

  def handle_event("update_form", _, %{assigns: %{selected_row: row}} = socket) do
    key = row |> Map.keys() |> hd()
    value = row[key]

    form_data =
      Item.changeset(%Item{red_key: key, red_value: value}, %{red_key: key, red_value: value})

    {:noreply, socket |> assign(form: to_form(form_data))}
  end

  def handle_event("change_page", %{"dir" => dir}, socket) do
    new_page =
      socket.assigns.page
      |> then(&(&1 + String.to_integer(dir)))
      |> max(1)
      |> min(socket.assigns.page_count)

    {:noreply, socket |> assign(page: new_page, selected_row: nil)}
  end

  def handle_event("delete", %{"row" => row}, socket) do
    key = row |> Map.keys() |> hd()

    socket =
      case Rediska.Utils.delete_item(key) do
        {:ok, message} ->
          Process.send_after(self(), :clear_flash, 3000)
          Process.send_after(self(), :enable_modal, 1)

          socket
          |> push_event("hide_modal", %{id: "delete-modal"})
          |> update(:items, &(&1 -- [row]))
          |> assign(page_count: Float.ceil(length(socket.assigns.items) / @page_size) |> trunc())
          |> put_flash(:info, message)

        {:error, reason} ->
          Process.send_after(self(), :clear_flash, 3000)

          socket
          |> push_event("hide_modal", %{id: "delete-modal"})
          |> put_flash(:error, reason)
      end

    {:noreply, socket |> assign(modal_enabled: false, selected_row: nil)}
  end

  def handle_event("save", %{"schema" => %{"red_key" => key, "red_value" => value}}, socket) do
    socket =
      case Rediska.Utils.create_item(key, value) do
        {:ok, pair} ->
          Process.send_after(self(), :clear_flash, 3000)
          Process.send_after(self(), :enable_modal, 1)

          socket
          |> push_event("hide_modal", %{id: "redis-modal"})
          |> update(:items, &List.insert_at(&1, -0, pair))
          |> assign(form: Item.changeset(%{}) |> to_form(), modal_enabled: false)
          |> put_flash(:info, "Success! Key-Value pair was stored to the database.")

        {:error, changeset} ->
          socket
          |> assign(form: to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event(
        "update",
        %{"schema" => %{"red_key" => key, "red_value" => value}},
        %{assigns: %{selected_row: row}} = socket
      ) do
    socket =
      case Rediska.Utils.update_item(row, key, value) do
        {:ok, pair} ->
          Process.send_after(self(), :clear_flash, 3000)
          Process.send_after(self(), :enable_modal, 1)

          socket
          |> push_event("hide_modal", %{id: "redis-modal"})
          |> update(:items, &List.insert_at(&1 -- [row], -0, pair))
          |> assign(
            form: Item.changeset(%{}) |> to_form(),
            modal_enabled: false,
            selected_row: nil
          )
          |> put_flash(:info, "Success! Key-Value pair was stored to the database.")

        {:error, changeset} ->
          socket
          |> assign(form: to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, socket |> assign(form: Item.changeset(%{}) |> to_form())}
  end

  def handle_info(:clear_flash, socket) do
    {:noreply, socket |> clear_flash}
  end

  def handle_info(:enable_modal, socket) do
    {:noreply, socket |> assign(modal_enabled: true)}
  end

  attr :text, :string
  attr :type, :string
  attr :locked, :boolean
  attr :on_click, :fun

  def custom_button(%{type: "regular"} = assigns) do
    ~H"""
    <button
      phx-click={@on_click}
      class="size-fit rounded-full bg-green-500 px-4 py-2 text-white font-bold shadow-lg hover:bg-green-600 transition"
      phx-click={@on_click}
    >
      <span>{@text}</span>
    </button>
    """
  end

  def custom_button(%{type: "lockable"} = assigns) do
    ~H"""
    <button
      phx-click={@on_click}
      class="size-fit rounded-full bg-pink-500 px-4 py-2 text-white font-bold shadow-lg hover:bg-pink-600 transition disabled:bg-pink-100 disabled:border disabled:cursor-not-allowed"
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
    assigns =
      assign(assigns,
        visible_items:
          assigns.items |> Enum.drop((assigns.page - 1) * @page_size) |> Enum.take(@page_size)
      )

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
          :for={row <- @visible_items}
          phx-click={JS.push("select_row", value: row)}
          class={"border-b hover:cursor-pointer " <>if @selected_row == row, do: "selected-row", else: "hover:bg-pink-100"}
        >
          <td class="px-4 py-2 text-center font-bold border-e">
            {row |> Map.keys() |> Enum.at(0)}
          </td>
          <td class="relative px-4 py-2 text-center">
            {row |> Map.values() |> Enum.at(0)}
            <svg :if={@selected_row == row} class="selected-icon size-6 rotate-90 text-pink-500">
              <use href="/images/sprites.svg#radish-icon"></use>
            </svg>
          </td>
        </tr>
        <tr
          :for={
            _row <- String.duplicate("0", @page_size - length(@visible_items)) |> String.to_charlist()
          }
          class="border-b"
        >
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
            <svg
              class="size-6 rotate-180 text-pink-500 transition-transform duration-200 hover:scale-125 hover:cursor-pointer"
              phx-click="change_page"
              phx-value-dir="-1"
            >
              <use href="/images/sprites.svg#arrow-left"></use>
            </svg>
            <svg
              class="size-6 text-pink-500 transition-transform duration-200 hover:scale-125 hover:cursor-pointer"
              phx-click="change_page"
              phx-value-dir="1"
            >
              <use href="/images/sprites.svg#arrow-left"></use>
            </svg>
          </td>
        </tr>
      </tfoot>
    </table>
    """
  end
end
