% This project demonstrates how to build a key-value store,
% where multiple clients can store and retrieve values simultaneously
% using Erlang processes.
% 
% Core idea:
% - A single store process maintains the key-value map.
% - Clients interact with the store via messages.
% - Operations include:
%   -> put(Key, Value) to store a value,
%   -> get(Key) to retrieve a value,
%   -> and delete(Key) to remove a value.
%
% Erlang modules must declare their name and export any functions that are
% intended to be called from outside the module (e.g., from the shell).

% The module name `app` matches the file name `app.erl`.
% Exported functions are callable from the Erlang shell (e.g. `app:start().`).
% kv_store/1 and kv_client/1 are exported to make it easy to test or run
% them directly from the shell if desired.
-module(app).
-export([start/0, kv_store/1, kv_client/1]).

% START:
% ======
% Spawns the store process with an empty map.
% Spawns a client process that interacts with the store.
start() ->
    StorePid = spawn(fun() -> kv_store(#{} ) end),
    spawn(fun() -> kv_client(StorePid) end).

% Store Process:
% ==============
% kv_store/1 is a recursive loop holding the current state in Map.
% Messages are pattern matched to determine the action.
% Responses are sent back to the client.
%
% kv_store(Map) is the main function for the key-value store process.
% It takes a Map (an Erlang map data structure) as its current state,
% which holds the key-value pairs.
%
% This function runs in an infinite loop (via recursion) waiting for messages.
% In Erlang, processes communicate by sending messages to each other.
% The 'receive' keyword waits for incoming messages and pattern matches them.
%
% Each message is a tuple with the operation type, parameters, and the sender's PID (From).
% After processing, it sends a response back to the sender and recurses with the updated state.
kv_store(Map) ->
    % Wait for incoming messages. This is a blocking operation.
    receive
        % Pattern match for a 'put' message: {put, Key, Value, From}
        % This adds or updates a key-value pair in the store.
        {put, Key, Value, From} ->
            % Use maps:put/3 to add the Key-Value pair to the Map.
            % This returns a new map with the updated data.
            NewMap = maps:put(Key, Value, Map),
            % Send a success response back to the sender (From).
            % The response is {ok, Key} to confirm the operation.
            From ! {ok, Key},
            % Recurse with the new map to continue the loop.
            kv_store(NewMap);

        % Pattern match for a 'get' message: {get, Key, From}
        % This retrieves the value associated with the Key.
        {get, Key, From} ->
            % Use maps:get/3 to look up the Key in the Map.
            % If the key doesn't exist, it returns 'undefined'.
            case maps:get(Key, Map, undefined) of
                % If the key was not found (undefined), send an error message.
                undefined -> From ! {error, "Key not found"};
                % If the key was found, send the Value back.
                Value -> From ! {ok, Value}
            end,
            % Recurse with the same Map (no changes for get operation).
            kv_store(Map);

        % Pattern match for a 'delete' message: {delete, Key, From}
        % This removes the key-value pair from the store.
        {delete, Key, From} ->
            % Use maps:remove/2 to delete the Key from the Map.
            % This returns a new map without that key.
            NewMap = maps:remove(Key, Map),
            % Send a success response back to the sender.
            From ! {ok, Key},
            % Recurse with the new map.
            kv_store(NewMap)
    end.

% Client Process:
% ===============
% This function demonstrates how a client can interact with the store process.
% It sends several messages to the store and then waits for the replies.
%
% In Erlang, each process has a process identifier (PID). The client uses
% its own PID (returned by self()) so the store knows where to send replies.
kv_client(StorePid) ->
    % Send a put request to store "Alice" under the key 'name'.
    % Message shape: {put, Key, Value, FromPid}
    StorePid ! {put, name, "Alice", self()},

    % Send another put request to store 30 under the key 'age'.
    StorePid ! {put, age, 30, self()},

    % Send a get request to retrieve the value stored under 'name'.
    StorePid ! {get, name, self()},

    % Send a delete request to remove the value for 'age'.
    StorePid ! {delete, age, self()},

    % Wait for 4 responses (one for each request sent above).
    wait_responses(4).

% WAIT_RESPONSES:
% =====
% wait_responses/1 recursively waits for a fixed number of reply messages.
% It uses the receive block to match on the expected response tuple formats.
wait_responses(0) ->
    % When no more responses are expected, return ok.
    ok;
wait_responses(N) ->
    receive
        % Successful operation replies use the tuple {ok, Key}.
        % This prints the key for which the operation succeeded.
        {ok, Key} ->
            io:format("Operation succeeded for key: ~p~n", [Key]),
            wait_responses(N - 1);

        % Error replies use the tuple {error, Msg}.
        % This prints the error message.
        {error, Msg} ->
            io:format("Error: ~s~n", [Msg]),
            wait_responses(N - 1)
    end.

