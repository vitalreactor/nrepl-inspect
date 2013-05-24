nrepl-inspect
=============

Successor to javert, provides nrepl middleware and nrepl.el plugin to
do extensible slime-style object inspection.

## Installation


NOTE: We are working to package this for distribution via Clojars and ELPA, bear with us

- Clone this repository to your local system
- 'lein install'
- Add [nrepl-inspect "0.3.0-SNAPSHOT"] to profile or project :dependencies
- Add inspector.middleware/wrap-inspect to your :repl-options -> :nrepl-middleware
- Copy nrepl-inspect.el to your emacs loader path 
- Add (require 'nrepl-inspect) to your init.el

Example ~/.lein/profiles.clj

```clj
{:user {:plugins [[lein-ritz "0.7.0"]]
        :dependencies [[nrepl-inspect "0.3.0-SNAPSHOT"]
                       [ritz/ritz-nrepl-middleware "0.7.0"]]
        :repl-options {:nrepl-middleware
                       [inspector.middleware/wrap-inspect
                        ritz.nrepl.middleware.javadoc/wrap-javadoc
                        ritz.nrepl.middleware.apropos/wrap-apropos]}}}
```

## Usage

- C-c C-i on any variable will inspect that variable
- Tab and Shift-Tab navigate inspectable sub-objects
- Return to navigate into sub-object
- 'l' to return to parent
- 'g' to refresh


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

## Extending

You can extend the inspector.inspect/inspect generic function by type
or using dispatch on the metadata value :inspector-tag.  See
inspect.clj for examples.

## TODO

High Priority:
- Example extension and loader (per technomancy's suggestion)
    - Search classpath for: inspector.ext.*
    - Load any sub-packages
    - Sub-packages depend on inspector namespace, extend inspect
    - e.g. (defun inspector.ext.datomic/inspect datomic.Entity [inspector entity])
- Paging for long sequences
- Needs a good test suite!

Future tasks:
- Evaluation and editing
- Actions


## License

Copyright © 2013, Vital Reactor, LLC

(Original Javert port of slime/swank copyright © 2013, Seattle Clojure Group, Jeffrey Chu)

Distributed under the Eclipse Public License, the same as Clojure.

