(ns inspector.ext.datomic
  (:use [inspector.inspect])
  (:require [datomic.api :as d]))

(defmethod inspect datomic.query.EntityMap [inspector entity]
  (-> inspector
      (render-labeled-value "Class" (class entity))
      (render-labeled-value "Count" (count entity))
      (render-meta-information entity)
      (render-ln "Contents: ")
      (render-ln "  :db/id = " (str (:db/id entity)))
      (render-map-values entity)))

;;(defmethod inspect datomic.db.Db [inspector entity]
;;  (-> inspector
;;      (render-labeled-value "Class" (class entity))
;;      (render-labeled-value "Count" (count entity))
;;      (render-meta-information entity)
;;      (render-ln "Contents: ")
;;      (render-map-values entity)))
