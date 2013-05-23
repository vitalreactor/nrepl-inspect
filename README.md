nrepl-inspect
=============

Successor to javert, provides nrepl middleware and nrepl.el plugin to
do extensible slime-style object inspection.

## Usage

```clj
(require '[inspector.inspect :only [inspect-print]])
(inspect-print java.io.File)
```

```
Type: class java.lang.Class

--- Interfaces: 
  interface java.io.Serializable
  interface java.lang.Comparable
[...]
```

## License

Copyright © 2013, Vital Reactor, LLC

(Original Javert Copyright © 2013, Seattle Clojure Group, Jeffrey Chu)

Distributed under the Eclipse Public License, the same as Clojure.

