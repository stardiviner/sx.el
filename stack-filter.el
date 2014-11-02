;;; stack-filter.el --- filters for stack-mode       -*- lexical-binding: t; -*-

;; Copyright (C) 2014  Sean Allred

;; Author: Sean Allred <code@seanallred.com>
;; Keywords: help, hypermedia, mail, news, tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;;; Code:


;;; Dependencies

(require 'stack-core)


;;; Customizations

(defconst stack-filter-cache-file
  "filters.el")

(defvar stack-filter
  'default
  "The current filter.
To customize the filter for the next call
to `stack-core-make-request', let-bind this variable to the
output of a call to `stack-core-compile-filter'.  Be careful!  If
you're going to be using this new filter a lot, create a variable
for it.  Creation requests count against
`stack-core-remaining-api-requests'!")


;;; Compilation

;;; TODO allow BASE to be a precompiled filter name
(defun stack-filter-compile (&optional include exclude base)
  "Compile INCLUDE and EXCLUDE into a filter derived from BASE.

INCLUDE and EXCLUDE must both be lists; BASE should be a symbol
or string."
  (let ((keyword-arguments
         `((include . ,(if include (mapconcat
                                    #'stack-core-thing-as-string
                                    include ";")))
           (exclude . ,(if exclude (mapconcat
                                    #'stack-core-thing-as-string
                                    exclude ";")))
           (base    . ,(if base base)))))
    (let ((response (stack-core-make-request
                     "filter/create"
                     keyword-arguments)))
      (url-hexify-string
       (cdr (assoc 'filter
                   (elt response 0)))))))


;;; Storage and Retrieval

(defun stack-filter-get (filter)
  "Retrieve named FILTER from `stack-filter-cache-file'."
  (with-current-buffer (stack-cache-get-file stack-filter-cache-file)
    (or (cdr (ignore-errors (assoc filter (read (buffer-string)))))
        nil)))

(defun stack-filter-store (name filter)
  "Store NAME as FILTER in `stack-filter-cache-file'.

NAME should be a symbol and FILTER is a string as compiled by
`stack-filter-compile'."
  (unless (symbolp name)
    (error "Name must be a symbol: %S" name))
  (with-current-buffer (stack-cache-get-file stack-filter-cache-file)
    (let* ((dict (or (ignore-errors
                       (read (buffer-string)))
                     nil))
           (entry (assoc name dict)))
      (if entry (setf (cdr entry) filter)
        (setq dict (cons (cons name filter) dict)))
      (erase-buffer)
      (insert (prin1-to-string dict))
      (save-buffer)
      dict)))

;;; TODO tail recursion should be made more efficient for the
;;; byte-compiler
(defun stack-filter-store-all (name-filter-alist)
  (when name-filter-alist
    (stack-filter-store
     (caar name-filter-alist)
     (cdar name-filter-alist))
    (stack-filter-store-all (cdr name-filter-alist))))

(provide 'stack-filter)
;;; stack-filter.el ends here
