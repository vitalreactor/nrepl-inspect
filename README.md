nrepl-inspect
=============

Successor to javert, provides nrepl middleware and nrepl.el plugin to
do extensible slime-style object inspection.

## Installation


NOTE: We are working to package this for distribution via Clojars and ELPA, bear with us

- Add [nrepl-inspect "0.3.0"] to profile or project :dependencies
- Add inspector.middleware/wrap-inspect to your :repl-options -> :nrepl-middleware
- Copy nrepl-inspect.el to your emacs loader path 
- Add (require 'nrepl-inspect) to your init.el

Example ~/.lein/profiles.clj

```clj
{:user {:plugins [[lein-ritz "0.7.0"]]
        :dependencies [[nrepl-inspect "0.3.0"]
                       [ritz/ritz-nrepl-middleware "0.7.0"]]
        :repl-options {:nrepl-middleware
                       [inspector.middleware/wrap-inspect
                        ritz.nrepl.middleware.javadoc/wrap-javadoc
                        ritz.nrepl.middleware.apropos/wrap-apropos]}}}
```

## Usage

- C-c C-i on any expression, will prompt to accept
    - If empty, type any expression to inspect result
    - Evaluation happens in buffer namespace
- 'Tab' and 'Shift-Tab' navigate inspectable sub-objects
- 'Return' to inspect sub-objects
- 'l' to pop to the parent object
- 'g' to refresh the inspector (e.g. if viewing an atom/ref/agent)

You can extend the inspector by adding a new method for inspector.inspect/inspect.  (See inspector.ext.datomic for example).  To load all extensions with the inspector.ext.* prefix:

```clj
(inspector.middleware/load-extensions)
```

To use the plaintext inspector at a non-Emacs REPL.

```clj
(require '[inspector.inspect :only [inspect-print]])
(inspect-print java.io.File)
```
Which will return:

```
Type: class java.lang.Class

--- Interfaces: 
  interface java.io.Serializable
  interface java.lang.Comparable
[...]
```

## Extending the Inspector

You can extend the inspector.inspect/inspect generic function by type
or using dispatch on the metadata value :inspector-tag.  See
inspect.clj for examples.

## TODO

High Priority:
- Paging for long sequences
- Needs a good test suite!
- Automatically use extension loader (per technomancy's suggestion)
    - Search classpath for: inspector.ext.* (DONE)
    - Load any sub-packages (DONE)
    - Sub-packages depend on inspector namespace, extend inspect (SEE inspect.ext.*)
    - e.g. (defun inspector.ext.datomic/inspect datomic.query.EntityMap [inspector entity])
    - Problem: this will pull in example inspect/ext/datomic.clj

Future tasks:
- Evaluation and editing
- Actions


## License

Copyright © 2013, Vital Reactor, LLC

(Original Javert port of slime/swank copyright © 2013, Seattle Clojure Group, Jeffrey Chu)

Distributed under the Eclipse Public License, the same as Clojure.

