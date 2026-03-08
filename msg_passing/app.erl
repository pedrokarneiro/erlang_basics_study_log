-module(app).
-export([start/0]).

% PONTO DE ENTRADA: Demonstra o ciclo de vida e a criação de processos.
start() ->
    % spawns a new process and passes it to the sender function.
    % CICLO DE VIDA: O spawn/1 cria um processo que vive enquanto sua
    % função receiver() estiver executando.
    Pid = spawn(fun() -> receiver() end),
    sender(Pid).

% COMUNICAÇÃO POR CÓPIA: O Erlang não compartilha memória.
sender(Pid) ->
    % Here we can use a bang! to send a message to itself with self.
    % O Erlang envia uma CÓPIA dos dados. Se este processo (sender)
    % morrer agora, o receiver ainda terá os dados seguros.
    % O operador '!' (bang) envia a mensagem para a Mailbox do Pid.
    Pid ! {self(), hello}.

% MAILBOX: Cada processo tem sua própria "caixa de entrada".
receiver() ->
    % Here we can handle that message.
    % O bloco 'receive' varre a fila de mensagens do processo.
    receive
        {From, Message} ->
            io:format("Received a message from ~p~n", [From]),
            io:format("Message content: ~p~n", [Message])
        % PONTO DE PARADA: Após processar, o processo morre aqui.
    after
        5000 ->
            io:format("No messages received within 5 seconds~n")
    end.