% This module implements a concurrent calculator in Erlang.
% It demonstrates lightweight concurrency by handling multiple arithmetic operations
% simultaneously using separate processes for each calculation.
%
% Architecture:
% - A central server process receives calculation requests.
% - Each request spawns a worker process to perform the computation.
% - Results are sent back asynchronously via message passing.
% - Error handling is included for division by zero and other exceptions.

-module(app).
-export([start/0]).

% start/0: Entry point to start the calculator system.
% Spawns the server process and a client process to demonstrate concurrent calculations.
start() ->
    % Spawn the calculator server process.
    ServerPid = spawn(fun calculator_server/0),
    % Spawn a client process that sends multiple calculation requests concurrently.
    spawn(fun() -> calculator_client(ServerPid) end).

% calculator_server/0: The main server loop that waits for calculation requests.
% It receives messages in the form {calculate, Operation, A, B, From} and spawns
% a worker process to handle each request asynchronously.
calculator_server() ->
    receive
        {calculate, Operation, A, B, From} ->
            % Spawn a worker process to perform the calculation.
            spawn(fun() -> worker(Operation, A, B, From) end),
            % Recursively call itself to continue listening for more requests.
            calculator_server()
    end.

% worker/4: Handles the actual arithmetic computation based on the operation type.
% Each clause corresponds to a different operation and sends the result back to the requester.
% Uses try-catch for error handling, though arithmetic operations rarely fail.

% Addition operation.
worker('add', A, B, From) ->
    try From ! {result, A + B}
    catch error:Reason ->
        From ! {error, Reason}
    end;

% Subtraction operation.
worker('sub', A, B, From) ->
    try From ! {result, A - B}
    catch error:Reason ->
        From ! {error, Reason}
    end;

% Multiplication operation.
worker('mul', A, B, From) ->
    try From ! {result, A * B}
    catch error:Reason ->
        From ! {error, Reason}
    end;

% Division operation. Special handling for division by zero.
worker('div', _A, 0, From) ->
    From ! {error, "Division by zero"};

worker('div', A, B, From) ->
    try From ! {result, A / B}
    catch error:Reason ->
        From ! {error, Reason}
    end.

% calculator_client/1: Simulates a client that sends multiple calculation requests to the server.
% Sends two example requests (addition and subtraction) and waits for their results.
calculator_client(ServerPid) ->
    % Send an addition request: 5 + 3
    ServerPid ! {calculate, add, 5, 3, self()},
    % Send a subtraction request: 10 - 2
    ServerPid ! {calculate, sub, 10, 2, self()},
    % Wait for 2 results to be received.
    wait_results(2).

% wait_results/1: Recursively waits for and processes the specified number of results.
% Prints each result or error message to the console.
wait_results(0) ->
    ok;  % Base case: no more results to wait for.
wait_results(N) ->
    receive
        {result, Value} ->
            io:format("Result: ~p~n", [Value]),
            wait_results(N - 1);  % Decrement counter and continue waiting.
        {error, Msg} ->
            io:format("Error: ~p~n", [Msg]),
            wait_results(N - 1)  % Decrement counter and continue waiting.
    end.

% Future improvement: Put the server under a supervisor to automatically restart in case of a crash.
