defmodule SuperCollider.OSC do
  alias Elixir.OSC.Message
  alias __MODULE__, as: M

  @doc """
  quit program

  Exits the synthesis server.
  Asynchronous. Replies to sender with /done just before completion.
  """
  def quit do
    ["/quit"]
    |> list_to_msg()
  end

  @doc """
  register to receive notifications from server

  If argument is one, server will remember your return address and send you
  notifications. if argument is zero, server will stop sending you notifications.

  Asynchronous. Replies to sender with /done when complete.
  """
  def notify(:on) do
    notify(1)
  end
  def notify(:off) do
    notify(0)
  end
  def notify(i) when i in [0, 1] do
    ["/notify", i]
    |> list_to_msg()
  end

  @doc """
  query the status

  Replies to sender with the following message.

  status.reply
  	int - 1. unused.
  	int - number of unit generators.
  	int - number of synths.
  	int - number of groups.
  	int - number of loaded synth definitions.
  	float - average percent CPU usage for signal processing
  	float - peak percent CPU usage for signal processing
  	double - nominal sample rate
  	double - actual sample rate
  """
  def status() do
    ["/status"]
    |> list_to_msg()
  end

  @doc """
  plug-in defined command

  Commands are defined by plug-ins.
  """
  def cmd(arguments) do
    ["/cmd" | arguments]
    |> list_to_msg()
  end

  @doc """
  display incoming OSC messages

  Turns on and off printing of the contents of incoming Open Sound Control
  messages. This is useful when debugging your command stream.
  """
  def dump_osc(:off) do
    dump_osc(0)
  end
  def dump_osc(:parsed) do
    dump_osc(1)
  end
  def dump_osc(:hex) do
    dump_osc(2)
  end
  def dump_osc(:both) do
    dump_osc(3)
  end
  def dump_osc(i) when i in 0..3 do
    ["/dumpOSC", i]
    |> list_to_msg()
  end

  @doc """
  notify when async commands have completed.

  Replies with a /synced message when all asynchronous commands received before
  this one have completed. The reply will contain the sent unique ID.

  Asynchronous. Replies to sender with /synced, ID when complete.
  """
  def sync(id \\ :erlang.phash2(:erlang.unique_integer())) when is_integer(id) do
    ["/sync", id]
    |> list_to_msg()
  end

  @doc """
  clear all scheduled bundles.

  Removes all bundles from the scheduling queue.
  """
  def clear_scheduled() do
    ["/clearSched"]
    |> list_to_msg()
  end

  @doc """
  enable/disable error message posting

  Turn on or off error messages sent to the SuperCollider post window. Useful
  when sending a message, such as /n_free, whose failure does not necessarily
  indicate anything wrong.

  These "temporary" states accumulate within a single bundle -- so if you have
  nested calls to methods that use bundle-local error suppression, error posting
  remains off until all the layers have been unwrapped. If you use
  ['/error', -1] within a self-bundling method, you should always close it with
  ['/error', -2] so that subsequent bundled messages will take the correct
  error posting status. However, even if this is not done, the next bundle or
  message received will begin with the standard error posting status, as set
  by modes 0 or 1.

  Temporary error suppression may not affect asynchronous commands in every case.
  """
  def error(:off) do
    error(0)
  end
  def error(:on) do
    error(1)
  end
  def error(:temp_off) do
    error(-1)
  end
  def error(:temp_on) do
    error(-2)
  end
  def error(i) when i in -2..1 do
    ["/error", i]
    |> list_to_msg()
  end

  defmodule Definition do
    @doc """
    receive a synth definition file

    Loads a file of synth definitions from a buffer in the message.
    Resident definitions with the same names are overwritten.

    Asynchronous. Replies to sender with /done when complete.
    """
    def receive(data, message \\ nil)
    def receive(data, nil) when is_binary(data) do
      ["/d_recv", data]
      |> M.list_to_msg()
    end
    def receive(data, message = %Message{}) when is_binary(data) do
      ["/d_recv", data, message]
      |> M.list_to_msg()
    end

    @doc """
    load synth definition

    Loads a file of synth definitions. Resident definitions with the same names
    are overwritten.

    Asynchronous. Replies to sender with /done when complete.
    """
    def load(path, message \\ nil)
    def load(path, nil) when is_binary(path) do
      ["/d_load", path]
      |> M.list_to_msg()
    end
    def load(path, message = %Message{}) when is_binary(path) do
      ["/d_load", path, message]
      |> M.list_to_msg()
    end

    @doc """
    load a directory of synth definitions

    Loads a directory of synth definitions files. Resident definitions with the
    same names are overwritten.

    Asynchronous. Replies to sender with /done when complete.
    """
    def load_dir(path, message \\ nil)
    def load_dir(path, nil) when is_binary(path) do
      ["/d_loadDir", path]
      |> M.list_to_msg()
    end
    def load_dir(path, message = %Message{}) when is_binary(path) do
      ["/d_loadDir", path, message]
      |> M.list_to_msg()
    end

    @doc """
    delete synth definition

    Removes a synth definition once all synths using it have ended.
    """
    def free(name) when is_binary(name) do
      ["/d_free", name]
      |> M.list_to_msg()
    end
    def free(names) do
      ["d_free" | Enum.map(names, fn(n) when is_binary(n) -> n end)]
      |> M.list_to_msg()
    end
  end

  defmodule Node do
    @doc """
    delete a node.

    Stops a node abruptly, removes it from its group, and frees its memory. A
    list of node IDs may be specified. Using this method can cause a click if
    the node is not silent at the time it is freed.
    """
    def free(id) when is_integer(id) do
      ["/n_free", id]
      |> M.list_to_msg()
    end
    def free(ids) do
      ["/n_free" | Enum.map(ids, fn(id) when is_integer(id) -> id end)]
      |> M.list_to_msg()
    end

    @doc """
    turn the list of nodes on or off

    Using this method to start and stop nodes can cause a click if the node is
    not silent at the time run flag is toggled.
    """
    def run(list) do
      args = list
      |> Enum.flat_map(fn({id, flag}) when is_integer(id) ->
        [id, map_run_flag(flag)]
      end)
      ["/n_run" | args]
      |> M.list_to_msg()
    end

    @doc """
    turn node on or off

    Using this method to start and stop nodes can cause a click if the node is
    not silent at the time run flag is toggled.
    """
    def run(id, flag) when is_integer(id) do
      ["/n_run", id, map_run_flag(flag)]
      |> M.list_to_msg()
    end

    defp map_run_flag(:off), do: 0
    defp map_run_flag(:on), do: 1
    defp map_run_flag(i) when i in [0, 1], do: i

    @doc """
    set a node's control value(s)

    Takes a list of pairs of control indices and values and sets the controls
    to those values. If the node is a group, then it sets the controls of every
    node in the group.
    """
    def set(id, values) do
      args = values
      |> Enum.flat_map(fn({name, value}) when is_binary(name) or is_integer(name) and is_float(value) ->
        [name, value]
      end)
      ["/n_set", id | args]
      |> M.list_to_msg()
    end

    def set(id, name, value) do
      set(id, [{name, value}])
    end

    @doc """
    set ranges of a node's control value(s)

    Set contiguous ranges of control indices to sets of values. For each range,
    the starting control index is given followed by the number of controls to
    change, followed by the values. If the node is a group, then it sets the
    controls of every node in the group.
    """
    def setn(id, values) do
      args = values
      |> Enum.flat_map(fn({name, values}) when is_binary(name) or is_integer(name) ->
        values = Enum.map(values, fn(v) when is_float(v) -> v end)
        [name, length(values) | values]
      end)
      ["/n_setn", id | args]
      |> M.list_to_msg()
    end

    @doc """
    fill ranges of a node's control value(s)

    Set contiguous ranges of control indices to single values. For each range,
    the starting control index is given followed by the number of controls to
    change, followed by the value to fill. If the node is a group, then it sets
    the controls of every node in the group.
    """
    def fill(id, values) do
      args = values
      |> Enum.flat_map(fn({name, {count, value}}) when is_binary(name) or is_integer(name) and is_integer(count) and is_float(value) ->
        [name, count, value]
      end)
      ["/n_fill", id | args]
      |> M.list_to_msg()
    end

    @doc """
    map a node's controls to read from a bus

    Takes a list of pairs of control names or indices and bus indices and causes
    those controls to be read continuously from a global control bus. If the
    node is a group, then it maps the controls of every node in the group. If
    the control bus index is -1 then any current mapping is undone. Any n_set,
    n_setn and n_fill command will also unmap the control.
    """
    def map(id, names) do
      args = names
      |> Enum.flat_map(fn({name, index}) when is_binary(name) or is_integer(name) and is_integer(index) ->
        [name, index]
      end)
      ["/n_map", id | args]
      |> M.list_to_msg()
    end

    # TODO
    # def mapn(id, names)
    # def before(ids)
    # def before(a, b)
    # def after(ids)
    # def after(a, b)
    # def query(ids)
    # def trace(ids)
  end

  defmodule Synth do
    @doc """
    create a new synth

    Create a new synth from a synth definition, give it an ID, and add it to the
    tree of nodes. There are four ways to add the node to the tree as
    determined by the add action argument which is defined as follows:

        0 - add the new node to the the head of the group specified by the add target ID.
      	1 - add the new node to the the tail of the group specified by the add target ID.
      	2 - add the new node just before the node specified by the add target ID.
      	3 - add the new node just after the node specified by the add target ID.
      	4 - the new node replaces the node specified by the add target ID. The target node is freed.

    Controls may be set when creating the synth. The control arguments are the same as for the n_set command.

    If you send /s_new with a synth ID of -1, then the server will generate an
    ID for you. The server reserves all negative IDs. Since you don't know what
    the ID is, you cannot talk to this node directly later. So this is useful
    for nodes that are of finite duration and that get the control information
    they need from arguments and buses or messages directed to their group.
    In addition no notifications are sent when there are changes of state for
    this node, such as /go, /end, /on, /off.

    If you use a node ID of -1 for any other command, such as /n_map, then it
    refers to the most recently created node by /s_new (auto generated ID or
    not). This is how you can map  the controls of a node with an auto generated
    ID. In a multi-client situation, the only way you can be sure what node -1
    refers to is to put the messages in a bundle.
    """
    def new(name, id, action, target, values \\ []) when is_binary(name) and is_integer(id) and is_integer(target) do
      args = values
      |> Enum.flat_map(fn({name, value}) when is_binary(name) or is_integer(name) and is_float(value) ->
        [name, value]
      end)
      ["/s_new", name, id, map_action(action), target | args]
      |> M.list_to_msg()
    end

    defp map_action(:head), do: 0
    defp map_action(:tail), do: 1
    defp map_action(:before), do: 2
    defp map_action(:after), do: 3
    defp map_action(:replace), do: 4
    defp map_action(i) when i in 0..4, do: i

    @doc """
    get control value(s)

    Replies to sender with the corresponding /n_set command.
    """
    def get(id, names) when is_integer(id) do
      args = names
      |> Enum.map(fn(n) when is_integer(n) or is_binary(n) ->
        n
      end)
      ["/s_get", id | args]
      |> M.list_to_msg()
    end

    @doc """
    get ranges of control value(s)

    Get contiguous ranges of controls. Replies to sender with the corresponding
    /n_setn command.
    """
    def getn(id, names) do
      args = names
      |> Enum.flat_map(fn({name, count}) when is_integer(name) or is_binary(name) and is_integer(count) ->
        [name, count]
      end)
      ["/s_getn", id | args]
      |> M.list_to_msg()
    end

    @doc """
    auto-reassign synth's ID to a reserved value

    This command is used when the client no longer needs to communicate with the
    synth and wants to have the freedom to reuse the ID. The server will
    reassign this synth to a reserved negative number. This command is purely
    for bookkeeping convenience of the client. No notification is sent when
    this occurs.
    """
    def noid(id) when is_integer(id) do
      ["/s_noid", id]
      |> M.list_to_msg()
    end
    def noid(ids) do
      ["/s_noid" | Enum.map(ids, fn(id) when is_integer(id) -> id end)]
      |> M.list_to_msg()
    end
  end

  defmodule Group do
    @doc """
    Create a new group and add it to the tree of nodes.
    There are four ways to add the group to the tree as determined by the add
    action argument which is defined as follows (the same as for "/s_new"):
    add actions:

      	0 - add the new group to the the head of the group specified by the add target ID.
      	1 - add the new group to the the tail of the group specified by the add target ID.
      	2 - add the new group just before the node specified by the add target ID.
      	3 - add the new group just after the node specified by the add target ID.
      	4 - the new node replaces the node specified by the add target ID. The target node is freed.

    Multiple groups may be created in one command by adding arguments.
    """
    def new(groups) do
      args = groups
      |> Enum.flat_map(fn({id, {action, target}}) when is_integer(id) and is_integer(target) ->
        [id, map_action(action), target]
      end)
      ["/g_new" | args]
      |> M.list_to_msg()
    end

    def new(id, action, target) do
      [{id, {action, target}}]
      |> new()
    end

    defp map_action(:head), do: 0
    defp map_action(:tail), do: 1
    defp map_action(:before), do: 2
    defp map_action(:after), do: 3
    defp map_action(:replace), do: 4
    defp map_action(i) when i in 0..4, do: i

    for name <- [:head, :tail] do
      @doc """
      add node to #{name} of group

      Adds the node to the #{name} of the group.
      """
      def unquote(name)(groups) do
        args = groups
        |> Enum.flat_map(fn({id, node}) when is_integer(id) and is_integer(node) ->
          [id, node]
        end)
        [unquote("/g_#{name}") | args]
        |> M.list_to_msg()
      end

      def unquote(name)(group, node) do
        [{group, node}]
        |> unquote(name)()
      end
    end

    def free(id) when is_integer(id) do
      ["/g_freeAll", id]
      |> M.list_to_msg()
    end
    def free(ids) do
      ["/g_freeAll" | Enum.map(ids, fn(id) when is_integer(id) -> id end)]
      |> M.list_to_msg()
    end

    def deep_free(id) when is_integer(id) do
      ["/g_deepFree", id]
      |> M.list_to_msg()
    end
    def deep_free(ids) do
      ["/g_deepFree" | Enum.map(ids, fn(id) when is_integer(id) -> id end)]
      |> M.list_to_msg()
    end

    def dump_tree(ids) do
      args = ids
      |> Enum.flat_map(fn({id, flag}) when is_integer(id) ->
        [id, map_tree_flag(flag)]
      end)
      ["/g_dumpTree" | args]
      |> M.list_to_msg()
    end

    def dump_tree(id, flag) do
      [{id, flag}]
      |> dump_tree()
    end

    def query_tree(ids) do
      args = ids
      |> Enum.flat_map(fn({id, flag}) when is_integer(id) ->
        [id, map_tree_flag(flag)]
      end)
      ["/g_queryTree" | args]
      |> M.list_to_msg()
    end

    def query_tree(id, flag) do
      [{id, flag}]
      |> query_tree()
    end

    defp map_tree_flag(:on), do: 1
    defp map_tree_flag(:off), do: 0
    defp map_tree_flag(i) when i in 0..1, do: i
  end

  defmodule Buffer do
    def alloc(id, frames, channels \\ 1, message \\ nil)
    def alloc(id, frames, channels, nil) when is_integer(id) and is_integer(frames) and is_integer(channels) do
      ["/b_alloc", id, frames, channels]
      |> M.list_to_msg()
    end
    def alloc(id, frames, channels, message = %Message{}) when is_integer(id) and is_integer(frames) and is_integer(channels) do
      ["/b_alloc", id, frames, channels, message]
      |> M.list_to_msg()
    end

    def alloc_read(id, path, start_frame \\ 0, frames \\ 0, message \\ nil)
    def alloc_read(id, path, start_frame, frames, nil) do
      ["/b_allocRead", id, path, start_frame, frames]
      |> M.list_to_msg()
    end
    def alloc_read(id, path, start_frame, frames, message = %Message{}) do
      ["/b_allocRead", id, path, start_frame, frames, message]
      |> M.list_to_msg()
    end

    def query(id) when is_integer(id) do
      ["/b_query", id]
      |> M.list_to_msg()
    end
    def query(ids) do
      args = Enum.map(ids, fn(id) when is_integer(id) -> id end)
      ["/b_query" | args]
      |> M.list_to_msg()
    end
  end

  def list_to_msg([address | arguments]) do
    %Message{address: address, arguments: arguments}
  end
end
