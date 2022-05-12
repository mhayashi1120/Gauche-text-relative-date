;;;
;;; Test gauche_text_relative_date
;;;

(use srfi-19)
(use gauche.test)

(test-start "gauche_text_relative_date")
(use text.relative-date)
(test-module 'text.relative-date)

(define test-now (make-date 0 1 2 3 4 5 2020 12345))

(define (add-second d sec)
  (let* ([date->sec (with-module text.relative-date date->seconds)]
         [sec->date (with-module text.relative-date seconds->date)])
    (sec->date (+ (date->sec d) sec))))

;; The following is a dummy test code.
;; Replace it for your tests.
#?= (relative-date->date "1year" test-now)
#?= (relative-date->date "1 year" test-now)
#?= (relative-date->date "1y" test-now)
#?= (relative-date->date "1h" test-now)
#?= (relative-date->date "1 month" test-now)
;; TODO
;; #?= (relative-date->date "1 monthes" test-now)
#?= (relative-date->date "1 months" test-now)

#?= (relative-date->date "1y1h1m" test-now)
#?= (relative-date->date "1y1h1m" test-now)

#?= (relative-date->date "1y 1h 1m" test-now)

(define (== expected result)
  (test* #"~|result|" expected result))

(== "just now" (date->relative-date (add-second test-now 0) test-now))
(== "1 second later" (date->relative-date (add-second test-now 1) test-now))
(== "30 seconds later" (date->relative-date (add-second test-now 30) test-now))
(== "30 seconds ago" (date->relative-date (add-second test-now -30) test-now))
(== "1 minute later" (date->relative-date (add-second test-now 60) test-now))
(== "2 minutes later" (date->relative-date (add-second test-now 120) test-now))
(== "1 day later" (date->relative-date (add-second test-now (* 24 60 60)) test-now))
(== "2 days later" (date->relative-date (add-second test-now (* 2 24 60 60)) test-now))
(== "1 month later" (date->relative-date (add-second test-now (* 30 24 60 60)) test-now))
(== "1 month later" (date->relative-date (add-second test-now (* 31 24 60 60)) test-now))
(== "1 month later" (date->relative-date (add-second test-now (* 59 24 60 60)) test-now))
(== "2 months later" (date->relative-date (add-second test-now (* 60 24 60 60)) test-now))
(== "2 months later" (date->relative-date (add-second test-now (* 61 24 60 60)) test-now))
(== "12 months later" (date->relative-date (add-second test-now (* 364 24 60 60)) test-now))
(== "1 year later" (date->relative-date (add-second test-now (* 365 24 60 60)) test-now))
(== "1 year later" (date->relative-date (add-second test-now (* 366 24 60 60)) test-now))
(== "1 year later" (date->relative-date (add-second test-now (* 729 24 60 60)) test-now))
(== "2 years later" (date->relative-date (add-second test-now (* 730 24 60 60)) test-now))


;; If you don't want `gosh' to exit with nonzero status even if
;; the test fails, pass #f to :exit-on-failure.
(test-end :exit-on-failure #t)
