;;;
;;; Test gauche_text_relative_date
;;;

(use srfi-19)
(use gauche.test)

(test-start "text.relative-date")

(use text.relative-date)
(test-module 'text.relative-date)

(define test-now (make-date 0 1 2 3 4 5 2020 12345))

(define (add-second d sec)
  (let* ([date->sec (with-module text.relative-date date->seconds)]
         [sec->date (with-module text.relative-date seconds->date)])
    (sec->date (+ (date->sec d) sec) (date-zone-offset d))))

;; simple test
(define (== expected result)
  (test* #"== ~|result|" expected result))

;; TODO should add Examples (relative-date->date)
(define (leeway== leeway-seconds t)
  (== (add-second test-now leeway-seconds)
      (relative-date->date t test-now)))

(leeway== (* 0) "now")
(leeway== (* 0) "just now")
(leeway== (* 0) "365 days ago 1 year later")
(leeway== (* 0) "1 second 1 second ago")
(leeway== (* 1) "1 second")
(leeway== (* 1) "1 seconds")
(leeway== (* 1) "1second")
(leeway== (* 365 24 60 60) "1year")
(leeway== (* 365 24 60 60) "1 year")
(leeway== (* 365 24 60 60) "1y")
(leeway== (* 60 60) "1h")
(leeway== (* 30 24 60 60) "1 month")
(leeway== (* 30 24 60 60) "1 months")
(leeway== (+ (* 365 24 60 60) (* 60 60) (* 30 24 60 60)) "1y1h1m")
(leeway== (+ (* 365 24 60 60) (* 60 60) (* 30 24 60 60)) "1y 1h 1m")

(let ([now (make-date 0 1 2 3 4 6 2020 12345)]) ;; Thu
  (== (make-date 0 1 2 3 10 6 2020 12345) (relative-date->date "next wed" now))
  (== (make-date 0 1 2 3 3 6 2020 12345) (relative-date->date "last wed" now))
  (== (make-date 0 1 2 3 3 6 2020 12345) (relative-date->date "this wed" now))

  (== (make-date 0 1 2 3 11 6 2020 12345) (relative-date->date "next thu" now))
  (== (make-date 0 1 2 3 28 5 2020 12345) (relative-date->date "last thu" now))
  (== (make-date 0 1 2 3 4 6 2020 12345) (relative-date->date "this thu" now))

  (== (make-date 0 1 2 3 5 6 2020 12345) (relative-date->date "next fri" now))
  (== (make-date 0 1 2 3 29 5 2020 12345) (relative-date->date "last fri" now))
  (== (make-date 0 1 2 3 5 6 2020 12345) (relative-date->date "this fri" now))
  )

(define (text== t leeway-seconds)
  (== t
      (date->relative-date (add-second test-now leeway-seconds) test-now)))

(text== "just now"         0)
(text== "1 second later"   1)
(text== "30 seconds later" 30)
(text== "30 seconds ago"   -30)
(text== "1 minute later"   60)
(text== "2 minutes later"  120)
(text== "1 day later"      (* 24 60 60))
(text== "2 days later"     (* 2 24 60 60))
(text== "1 month later"    (* 30 24 60 60))
(text== "1 month later"    (* 31 24 60 60))
(text== "1 month later"    (* 59 24 60 60))
(text== "2 months later"   (* 60 24 60 60))
(text== "2 months later"   (* 61 24 60 60))
(text== "12 months later"  (* 364 24 60 60))
(text== "1 year later"     (* 365 24 60 60))
(text== "1 year later"     (* 366 24 60 60))
(text== "1 year later"     (* 729 24 60 60))
(text== "2 years later"    (* 730 24 60 60))

;; Check inversible TEXT
(define (inverse== text)
  (let1 d (relative-date->date text test-now)
    (test* #"~|text| -> ~|d|" text (date->relative-date d test-now))))

(inverse== "just now")
(inverse== "1 second later")
(inverse== "30 seconds later")
(inverse== "30 seconds ago")
(inverse== "1 minute later")
(inverse== "2 minutes later")
(inverse== "1 day later")
(inverse== "2 days later")
(inverse== "1 month later")
(inverse== "1 month later")
(inverse== "1 month later")
(inverse== "2 months later")
(inverse== "2 months later")
(inverse== "12 months later")
(inverse== "1 year later")
(inverse== "1 year later")
(inverse== "1 year later")
(inverse== "2 years later")

(define (synonym== t1 t2 . ts)
  (let* ([d1 (relative-date->date t1 test-now)]
         [d2 (relative-date->date t2 test-now)])
    (test* #"~|t1| == ~|t2|" d1 d2)
    (cond
     [(pair? ts)
      (apply synonym== t2 ts)]
     [else
      #t])))

(synonym== "2 days ago" "1 day ago 1 day ago")
(synonym== "next thu" "next Thursday")
(synonym== "next mon" "Next Monday")
(synonym== "next mon next thu" "Next Monday Next Thursday")

(synonym== "a day" "a day later" "1 day later")
(synonym== "a day ago" "an day ago")
(synonym== "2 days ago" "2 day ago")
(synonym== "an hour ago" "1 hour ago")
(synonym== "2 hours ago" "120 minutes ago")
(synonym== "an hour later" "1 hour later")
(synonym== "1y1m1d" "1 year 1 month 1 day later")
(synonym== "1h 2min 3sec" "1h 2minutes 3seconds")

;; Private procedure test

(let1 proc (with-module text.relative-date date-weekday*)
  (parameterize ([relative-date-weekend 6])
    (== 1 (proc (add-second test-now (* 0 24 60 60))))
    (== 2 (proc (add-second test-now (* 1 24 60 60))))
    (== 3 (proc (add-second test-now (* 2 24 60 60))))
    (== 0 (proc (add-second test-now (* 6 24 60 60))))
    (== 1 (proc (add-second test-now (* 7 24 60 60))))
    )
  (parameterize ([relative-date-weekend 0])
    (== 0 (proc (add-second test-now (* 0 24 60 60))))
    (== 1 (proc (add-second test-now (* 1 24 60 60))))
    (== 2 (proc (add-second test-now (* 2 24 60 60))))
    (== 6 (proc (add-second test-now (* 6 24 60 60))))
    (== 0 (proc (add-second test-now (* 7 24 60 60))))
    )
  )


;; TODO error test

;; If you don't want `gosh' to exit with nonzero status even if
;; the test fails, pass #f to :exit-on-failure.
(test-end :exit-on-failure #t)
