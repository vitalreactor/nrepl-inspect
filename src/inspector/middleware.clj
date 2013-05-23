(ns inspector.middleware
  (:require [inspector.inspect :as inspect]
            [clojure.tools.nrepl.transport :as transport]
            [clojure.tools.nrepl.middleware.session :refer [session]]
            [clojure.tools.nrepl.middleware :refer [set-descriptor!]]
            [clojure.tools.nrepl.misc :refer [response-for]]))

;; TODO:
;; - Access values on this session's repl

;; I'm not sure if I should be hard-coding the decision to inspect the
;; var for macros and functions. Yet, in my opinion, the vars have
;; more valuable info than the values do in those cases.
(defn lookup
  [ns sym]
  (let [var (or (find-ns sym) (ns-resolve ns sym))]
    (if (or (instance? Class var) (instance? clojure.lang.Namespace var)
            (:macro (meta var)) (fn? @var))
      var
      (:value @var))))

(defn inspector-op [inspector {:keys [session op ns sym idx] :as msg}]
  (try
    (cond
     ;; new 
     (= op "inspect-start") (inspect/start inspector (lookup (symbol ns) (symbol sym)))
     (= op "inspect-pop")    (inspect/up inspector)
     (= op "inspect-push")  (inspect/down inspector (Integer/parseInt idx))
     (= op "inspect-reset") (inspect/clear inspector)
     :default nil)
    (catch java.lang.Throwable e
      (assoc inspector :rendered (list "Rendering error for op: " (str op))))))

(def ^:private current-inspector (atom nil))

(defn session-inspector-value [{:keys [session] :as msg}]
  (let [inspector (or @current-inspector (inspect/fresh))
        result (inspector-op inspector msg)]
    (when result
      (reset! current-inspector result)
      {:value (inspect/serialize-render result)})))

(defn wrap-inspect
  [handler]
  (fn [{:keys [transport] :as msg}]
    (if-let [result (session-inspector-value msg)]
      (transport/send transport (response-for msg {:status :done} result))
      (handler msg))))

(set-descriptor! #'wrap-inspect
  {:requires #{#'session}
   :handles {"inspect" {:doc "Print the results of inspector.inspect/inspect-print to stdout."
                        :requires {"sym" "Inspect the value bound to this symbol."
                                   "ns" "Resolve the symbol in this namespace."}}}})
