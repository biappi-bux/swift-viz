# swift-viz

Generates a simple class hierarchy diagram from a bunch of swift code in HTML format.


## Hacking

Due to `swift-syntax` being tied to the C++ ABI of the compiler,
the easiest way to build & run is using the swift package manager
from the command line, or using the deprecated `generate-xcodeproj`
command.


## TODOs

- Issues
    - Check and fix uses of `node.identifier` and `node.inheritanceClause`
- Todos
    - Support more than class / subclass relation
    - Improve graph layout
    - Support search / filtering  of nodes
    - Dynamic toggling of type relations, when we support more
- Wannahave
    - Click to expand
    - Links to source files

