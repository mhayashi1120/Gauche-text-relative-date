;;;
;;; Test gauche_text_relative_date
;;;

(use srfi-19)
(use gauche.test)

(test-start "text.relative-date")

(use text.relative-date)
(test-module 'text.relative-date)

(load "./__tests__/basic.spec.scm")

(test-end :exit-on-failure #t)
