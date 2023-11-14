;;;
;;; Test text.relative-date
;;;

(use srfi-19)
(use gauche.test)

(test-start "text.relative-date")

(load "./__tests__/basic.spec.scm")

(test-end :exit-on-failure #t)
