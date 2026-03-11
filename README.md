





This document proposes a peer to peer messaging service with no central servers or direct connections to recipients. Users act as nodes on a distributed network and only have information about their immediate peers. Messages must traverse this network and, along the way, users can interact with these messages in fun ways.

Messages travel “physically” across the network, carried by virtual “pigeons” that move from one user’s computer to another. The network, and messages, only exist while people are actively running it. The “pigeons” themselves are limited in their abilities. Only able to travel a limited distance before needing to stop and rest at a user’s computer, where users can then interact with and feed them as they continue on their journey.

High Level Requirement

The product allows users to send messages to one another and to also interact with "pigeons" and messages that are moving through the network in ways that are familiar to that of a tamagotchi. It will have a simple but charming ascii interface.

Conceptual Design

The program would be written in Go, mainly because the standard library has easy to use networking and concurrency (though the latter may not be of much use).

The system has two main parts.

The Pigeons

Pigeons are small data structures that represent messages moving through the network. Each pigeon contains:
Destination - a unique user ID the pigeon is trying to reach
Message - The thing being delivered (plain ascii text)
Time To Live - A stamina value that decreases over time. When TTL reaches zero the pigeon “dies” and the message is lost
Routing metadata - Things like nodes already visited, hop count, age, etc. Things that might help guide local rounding decisions and avoid obvious loops

The Roosts (Running Clients)

Each running instance of the app is a roost. Each roost is responsible for:
Hosting pigeons while they rest
Maintaining connections to manually added peers
Choosing where pigeons fly next
Running a small loop that advances time, drains TTL, and allows for user interaction

The UI would be minimal. A simple but charming ascii interface showing basic info:
Currently roosting pigeons
Pigeon Interaction options
Message writing/recipient choosing interface
Hopefully some nice ascii art and animations to make it all worthwhile

Required Resources

To develop this project I'll need a couple computers with basic network functionality to test message routing. The most difficult parts of this project will be the algorithms involved with the distributed path-finding and the networking boilerplate. There are a couple things I've read regarding this but they seem pretty complicated so It'd be interesting to either come up with a simpler, though maybe not as efficient solution, or implement one of the ones out there.

Background & References

Not really sure what this would be similar to. Most modern messaging applications rely on
centralized servers or connect you directly to the recipient with some sort of guarantee that your messages will actually be delivered,

While this application is deliberately fragile and slow and insecure. It’s more of an art project than a real messaging service.

The closest thing I can think of is other distributed p2p services like torrenting clients and maybe some computer games.

This is also just a smaller scale, cordoned off version of the internet in general. With similar information distribution problems to solve.

Links to similar projects:
https://briarproject.org/

https://nlnet.nl/project/serval/ (<- this seems to be the closest to what I’m trying to build)







-------------------------------------------------------------------------------------------------------------------------------------------------

# Project Name
Put here a short paragraph describing your project. 
Adding an screenshot or a mockup of your application in action would be nice.  

![This is a screenshot.](images.png)
# How to run
Provide here instructions on how to use your application.   
- Download the latest binary from the Release section on the right on GitHub.  
- On the command line uncompress using
```
tar -xzf  
```
- On the command line run with
```
./hello
```
- You will see Hello World! on your terminal. 

# How to contribute
Follow this project board to know the latest status of the project: [http://...]([http://...])  

### How to build
https://github.com/orgs/cis3296s26/projects/31/views/1?system_template=kanban 
