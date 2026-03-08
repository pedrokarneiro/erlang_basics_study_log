-module(app).
-export([hello_world/0, all_together_now/1]).

hello_world() ->
    io:format("Hello, World ~n").

all_together_now(N) ->
    [spawn(fun hello_world/0) || _ <-lists:seq(1, N)].
