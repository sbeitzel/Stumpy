# Further Reading

There's lots of good to be found in [RFC-5321](https://tools.ietf.org/html/rfc5321)
# Architecture

## Well, This Is Outdated

This is how it worked before NIO.

The server is a state machine, with this explicitly embodied in the design. When a client connects to the server,
the server creates a session object to keep track of that client's state. The general client session loop then looks
like:

1. Server sends the state message to the client
1. Client sends a string to the server
1. Server parses the string into a command + parameters, data, whatever
1. The session evaluates what the next state should be, based on the current state and the command
1. The session updates its state accordingly
1. If the session is still ongoing (we haven't hit an end state), start the loop over again.
