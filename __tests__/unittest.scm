(define-module unittest
  (use srfi-19)
  (use text.relative-date)
  (use gauche.test)
  (export-all))
(select-module unittest)


;; Easy to generate date. This package didn't use nanosec.
(define (build-date y m d H M S tz)
  (make-date 0 S M H d m y tz))

(define test-now (build-date 2020 5 4 3 2 1 12345))

(define (add-second d sec)
  (let* ([date->sec (with-module text.relative-date date->seconds)]
         [sec->date (with-module text.relative-date seconds->date)])
    (sec->date (+ (date->sec d) sec) (date-zone-offset d))))

;; simple test
(define (== expected result)
  (test* #"== ~|result|" expected result))

;; TODO should add Examples (relative-date->date)
(define (parsed== additional-seconds t)
  (== (add-second test-now additional-seconds)
      (relative-date->date t test-now)))
