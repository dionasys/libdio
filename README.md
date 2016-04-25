# SOOC: Self-Organized Overlay Construction
SOOC (or LIBDIO) is a library used to coordinate the construction of distributed overlays on SPLAY. This is a part of DIONASYS project. 



# The API:
* TMAN:set_distance_function(functionName):  sets the distance function used to rank nodes and create the target structure. *functionName* is the name of the function defined and implemented by the user.
* TMAN:set_payload(nodePayload): sets the node semantic. This can be seen as node's profile, which is used to calculate the distance between nodes. For instance, in Chord this is the node id. In a topic-based clustering overlay it is the set of topic a node is interested on.  

# How to use it (examples):
* There are current 2 examples available in the source code: myExample1.lua and myExample2.lua. The former creates a ring overlay by using a clockwise distance function. The latter, is an example of aa topic based overlay, where nodes are clustered according to the topics they have in their profiles (payload). 


# TODO:

# Versions:

