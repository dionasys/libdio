# SOOC-Lib: Self-Organized Overlay Construction
SOOC (or LIBDIO) is a library used to coordinate the construction of distributed overlays on SPLAY. This work is developed as a part of DIONASYS project. 


# The API:
* **Coordinator.addProtocol(id, prot_obj)**: adds the protocol to be executed. the parameter *id* is a string representing the current instance. prot_obj is the object. 
* **Coordinator:getView(prot_id)**: method that exposes the state (view, connections) to the application. It returns the current view of a TMAN instance.
* **TMAN:set_distance_function(functionName)**: sets the distance function used to rank nodes and create the target structure. The parameter *functionName* is the name of the function defined and implemented by the user.
* **TMAN:set_payload(pl)**: sets the node semantic. This can be seen as node's profile, which is used to calculate the distance between nodes. For instance, in Chord this is the node id. In a topic-based clustering overlay it is the set of topics a node is interested in. 




# Architeture:


# How to use it (examples):
* There are current 2 examples available in the source code: myExample1.lua and myExample2.lua. The former creates a ring overlay by using a clockwise distance function. The latter, is an example of aa topic based overlay, where nodes are clustered according to the topics they have in their profiles (payload). 


# TODO:
* update doc.
* update and add scripts to parse the views in the doc.

# Versions:
v 0.1

# Note:
This documentation is under construction.