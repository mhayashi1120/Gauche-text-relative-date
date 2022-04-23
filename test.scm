;;;
;;; Test gauche_text_relative_date
;;;

(use srfi-19)
(use gauche.test)

(test-start "gauche_text_relative_date")
(use text.relative-date)
(test-module 'text.relative-date)

(define test-now (make-date 0 1 2 3 4 5 2020 12345))

;; The following is a dummy test code.
;; Replace it for your tests.
#?= (relative-date->date "1year" test-now)
#?= (relative-date->date "1 year" test-now)
#?= (relative-date->date "1 month" test-now)
;; TODO
;; #?= (relative-date->date "1 monthes" test-now)
#?= (relative-date->date "1 months" test-now)


;; If you don't want `gosh' to exit with nonzero status even if
;; the test fails, pass #f to :exit-on-failure.
(test-end :exit-on-failure #t)
