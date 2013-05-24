nrepl-inspect
=============

Successor to javert, provides nrepl middleware and nrepl.el plugin to
do extensible slime-style object inspection.

## Usage


```
Type: class java.lang.Class

--- Interfaces: 
  interface java.io.Serializable
  interface java.lang.Comparable
[...]
```

```clj
(require '[inspector.inspect :only [inspect-print]])
(inspect-print java.io.File)
```

## TODO

High Priority:
- Example of loading extensions to inspect multimethod for custom types
  e.g. datomic Entities
- Paging for long sequences
- Needs a good test suite!

Future tasks:
- Evaluation and editing
- Actions


## License

Copyright © 2013, Vital Reactor, LLC

(Original Javert Copyright © 2013, Seattle Clojure Group, Jeffrey Chu)

Distributed under the Eclipse Public License, the same as Clojure.

