;;; nrepl.el --- Client for Clojure nREPL

;; Copyright © 2013 Vital Reactor, LLC
;;
;; Author: Ian Eslick <ian@vitalreactor.com>
;; URL: http://www.github.com/vitalreactor/nrepl-inspect
;; Version: 0.1.0
;; Keywords: languages, clojure, nrepl
;; Package-Requires: ((clojure-mode "2.0.0"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

(require 'cl)
(require 'nrepl)

;; ===================================
;; Inspector Key Map and Derived Mode
;; ===================================

(defvar nrepl-inspector-mode-map
  (let ((map (make-sparse-keymap)))
	(define-key map [return] 'nrepl-inspector-operate-on-point)
	(define-key map "\C-m"   'nrepl-inspector-operate-on-point)
	(define-key map [mouse-1] 'nrepl-inspector-operate-on-click)
	(define-key map "l" 'nrepl-inspector-pop)
;;	(define-key map "n" 'nrepl-inspector-next)
;;	(define-key map " " 'nrepl-inspector-next)
;;  ("d" 'nrepl-inspector-describe)
;;  ("p" 'nrepl-inspector-pprint)
;;  ("e" 'nrepl-inspector-eval)
;;  ("h" 'slime-inspector-history)
;;  ("v" 'slime-inspector-toggle-verbose)
    (define-key map "g" 'nrepl-inspector-refresh)
	(define-key map [tab] 'nrepl-inspector-next-inspectable-object)
	(define-key map "\C-i" 'nrepl-inspector-next-inspectable-object)
	(define-key map [(shift tab)] 
	  'nrepl-inspector-previous-inspectable-object) ; Emacs translates S-TAB
	(define-key map [backtab] 'nrepl-inspector-previous-inspectable-object) ; to BACKTAB on X.
;;  ("." 'nrepl-inspector-show-source)
;;  (">" 'nrepl-inspector-fetch-all)
	map))

(set-keymap-parent nrepl-inspector-mode-map nrepl-popup-buffer-mode-map)

(define-minor-mode nrepl-inspector-buffer-mode
  "nREPL Inspector Buffer Mode."
  nil
  (" nREPL Inspector")
  nrepl-inspector-mode-map
  (set-syntax-table clojure-mode-syntax-table)
  (setq buffer-read-only t)
  (set (make-local-variable 'truncate-lines) t))

;; 
;; Top level
;;

(defvar nrepl-minibuffer-map
  (let ((map (make-sparse-keymap)))
	(set-keymap-parent map minibuffer-local-map)
	(define-key map "\t" 'completion-at-point)
	(define-key map "\M-\t" 'completion-at-point)
	map))

(defun nrepl-inspect (string)
  "Eval an expression and inspect the result"
  (interactive
   (list (read-from-minibuffer "Inspect value (evaluated): "
							   (or (nrepl-sexp-at-point)
								   (save-excursion
									 (unless (equal (string (char-before)) " ")
									   (backward-char)
									   (nrepl-sexp-at-point))))
							   nrepl-minibuffer-map
							   nil '())))
  (nrepl-inspect-sym string nrepl-buffer-ns))

(defun nrepl-inspect-debug (output)
  (with-current-buffer (get-buffer-create "nrepl-inspect-debug")
	(nrepl-inspector-buffer-mode 1)
    (if (= (point) (point-max))
        (insert output))
    (save-excursion
      (goto-char (point-max))
      (insert output))))


;; Operations
(defun nrepl-render-response (buffer)
  (nrepl-make-response-handler
   buffer
   (lambda (buffer str)
	 (nrepl-irender buffer str))
   '()
   (lambda (buffer str)
	 (nrepl-emit-into-popup-buffer buffer "Oops"))
   '()))

(defun nrepl-inspect-sym (sym ns)
  (let ((buffer (nrepl-popup-buffer "*nREPL inspect*" t)))
	(nrepl-send-request (list "op" "inspect-start" "sym" sym "ns" ns)
						(nrepl-render-response buffer))))

(defun nrepl-inspector-pop ()
  (interactive)
  (let ((buffer (nrepl-popup-buffer "*nREPL inspect*" t)))
	(nrepl-send-request (list "op" "inspect-pop")
						(nrepl-render-response buffer))))

(defun nrepl-inspector-push (idx)
  (let ((buffer (nrepl-popup-buffer "*nREPL inspect*" t)))
	(nrepl-send-request (list "op" "inspect-push" "idx" (number-to-string idx))
						(nrepl-render-response buffer))))

(defun nrepl-inspector-refresh ()
  (interactive)
  (let ((buffer (nrepl-popup-buffer "*nREPL inspect*" t)))
	(nrepl-send-request (list "op" "inspect-refresh")
						(nrepl-render-response buffer))))

(defun nrepl-test ()
  (nrepl-inspect-sym "testing" "inspector.javert"))


;; Utilities
(defmacro nrepl-propertize-region (props &rest body)
  "Execute BODY and add PROPS to all the text it inserts.
More precisely, PROPS are added to the region between the point's
positions before and after executing BODY."
  (let ((start (gensym)))
    `(let ((,start (point)))
       (prog1 (progn ,@body)
		 (add-text-properties ,start (point) ,props)))))


;; Render Inspector from Structured Values
(defun nrepl-irender (buffer str)
  (with-current-buffer buffer
    (nrepl-inspector-buffer-mode 1)
	(let ((inhibit-read-only t))
	  (condition-case nil
		  (nrepl-irender* (car (read-from-string str)))
		(error (newline) (insert "Inspector error for: " str))))
	(goto-char (point-min))))

(defun nrepl-irender* (elements)
  (setq nrepl-irender-temp elements)
  (dolist (el elements)
	(nrepl-irender-el* el)))

(defun nrepl-irender-el* (el)
  (cond ((symbolp el) (insert (symbol-name el)))
		((stringp el) (insert el))
		((and (consp el) (eq (car el) :newline))
		 (newline))
		((and (consp el) (eq (car el) :value))
		 (nrepl-irender-value (cadr el) (caddr el)))
		(t (message "Unrecognized inspector object: " el))))

(defun nrepl-irender-value (value idx)
  (nrepl-propertize-region
	  (list 'nrepl-value-idx idx
			'mouse-face 'highlight
			'face 'font-lock-keyword-face)
	(nrepl-irender-el* value)))


;; ===================================================
;; Inspector Navigation (lifted from SLIME inspector)
;; ===================================================

(defun nrepl-find-inspectable-object (direction limit)
  "Find the next/previous inspectable object.
DIRECTION can be either 'next or 'prev.  
LIMIT is the maximum or minimum position in the current buffer.

Return a list of two values: If an object could be found, the
starting position of the found object and T is returned;
otherwise LIMIT and NIL is returned."
  (let ((finder (ecase direction
                  (next 'next-single-property-change)
                  (prev 'previous-single-property-change))))
    (let ((prop nil) (curpos (point)))
      (while (and (not prop) (not (= curpos limit)))
        (let ((newpos (funcall finder curpos 'nrepl-value-idx nil limit)))
          (setq prop (get-text-property newpos 'nrepl-value-idx))
          (setq curpos newpos)))
      (list curpos (and prop t)))))

(defun nrepl-inspector-next-inspectable-object (arg)
  "Move point to the next inspectable object.
With optional ARG, move across that many objects.
If ARG is negative, move backwards."
  (interactive "p")
  (let ((maxpos (point-max)) (minpos (point-min))
        (previously-wrapped-p nil))
    ;; Forward.
    (while (> arg 0)
      (destructuring-bind (pos foundp)
          (nrepl-find-inspectable-object 'next maxpos)
        (if foundp
            (progn (goto-char pos) (setq arg (1- arg))
                   (setq previously-wrapped-p nil))
            (if (not previously-wrapped-p) ; cycle detection
                (progn (goto-char minpos) (setq previously-wrapped-p t))
                (error "No inspectable objects")))))
    ;; Backward.
    (while (< arg 0)
      (destructuring-bind (pos foundp)
          (nrepl-find-inspectable-object 'prev minpos)
        ;; NREPL-OPEN-INSPECTOR inserts the title of an inspector page
        ;; as a presentation at the beginning of the buffer; skip
        ;; that.  (Notice how this problem can not arise in ``Forward.'')
        (if (and foundp (/= pos minpos))
            (progn (goto-char pos) (setq arg (1+ arg))
                   (setq previously-wrapped-p nil))
            (if (not previously-wrapped-p) ; cycle detection
                (progn (goto-char maxpos) (setq previously-wrapped-p t))
                (error "No inspectable objects")))))))

(defun nrepl-inspector-previous-inspectable-object (arg)
  "Move point to the previous inspectable object.
With optional ARG, move across that many objects.
If ARG is negative, move forwards."
  (interactive "p")
  (nrepl-inspector-next-inspectable-object (- arg)))

(defun nrepl-inspector-property-at-point ()
  (let* ((properties '(nrepl-value-idx nrepl-range-button
									   nrepl-action-number))
         (find-property
          (lambda (point)
            (loop for property in properties
                  for value = (get-text-property point property)
                  when value
                  return (list property value)))))
      (or (funcall find-property (point))
          (funcall find-property (1- (point))))))

(defun nrepl-inspector-operate-on-point ()
  "Invoke the command for the text at point.
1. If point is on a value then recursivly call the inspector on
that value.  
2. If point is on an action then call that action.
3. If point is on a range-button fetch and insert the range."
  (interactive)
  (destructuring-bind (property value)
	  (nrepl-inspector-property-at-point)
	(case property
	  (nrepl-value-idx
	   (nrepl-inspector-push value))
	  ;; TODO: range and action handlers 
	  (t (error "No object at point")))))

(defun nrepl-inspector-operate-on-click (event)
  "Move to events' position and operate the part."
  (interactive "@e")
  (let ((point (posn-point (event-end event))))
    (cond ((and point
                (or (get-text-property point 'nrepl-value-idx)))
;;                    (get-text-property point 'nrepl-range-button)
;;                    (get-text-property point 'nrepl-action-number)))
           (goto-char point)
           (slime-inspector-operate-on-point))
          (t
           (error "No clickable part here")))))

(provide 'nrepl-inspect)
