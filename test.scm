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
(define (parsed== additional-seconds t)
  (== (add-second test-now additional-seconds)
      (relative-date->date t test-now)))

;; Examples
(parsed== (* 0) "just now")
(parsed== (* -1 24 60 60) "1 day ago")
(parsed== (* 2 24 60 60) "2 days later")
(parsed== (* 365 24 60 60) "1 year later")
(parsed== (* 0) "1 year later 365 days ago")

(parsed== (* 0) "now")
(parsed== (* 0) "just now")
(parsed== (* 0) "365 days ago 1 year later")
(parsed== (* 0) "1 second 1 second ago")
(parsed== (* 1) "1 second")
(parsed== (* 1) "1 seconds")
(parsed== (* 1) "1second")
(parsed== (* 365 24 60 60) "1year")
(parsed== (* 365 24 60 60) "1 year")
(parsed== (* 365 24 60 60) "1y")
(parsed== (* 60 60) "1hour")
(parsed== (* 30 24 60 60) "1 month")
(parsed== (* 30 24 60 60) "1 months")
(parsed== (+ (* 365 24 60 60) (* 60 60) (* 30 24 60 60)) "1y1hour1month")
(parsed== (+ (* 365 24 60 60) (* 60 60) (* 30 24 60 60)) "1y 1hour 1month")

(let ([now (make-date 0 1 2 3 4 6 2020 12345)])
  (== (make-date 0 0 4 3 4 6 2020 12345) (relative-date->date "03:04" now))
  (== (make-date 0 0 58 23 3 6 2020 12345) (relative-date->date "23:58" now))
  )

(let ([now (make-date 0 1 2 3 30 12 2022 31400)])
  (== (make-date 0 0 0 0 15 12 2022 31400) (relative-date->date "December, 15" now))
  (== (make-date 0 0 0 0 16 11 2022 31400) (relative-date->date "November, 16" now))
  (== (make-date 0 0 0 0 17 5 2023 31400) (relative-date->date "May 17" now))
  (== (make-date 0 0 0 0 2 1 2023 31400) (relative-date->date "Jan, 02" now))
  (== (make-date 0 0 0 0 3 1 2023 31400) (relative-date->date "Jan 3" now))
  ;; can handle unexists day
  (== (make-date 0 0 0 0 1 3 2023 31400) (relative-date->date "Feb 29" now))
  )

(let ([now (make-date 0 1 2 3 4 6 2020 12345)]) ;; Thu
  (== (make-date 0 0 30 3 4 6 2020 12345) (relative-date->date "03:30" now))
  (== (make-date 0 0 35 5 4 6 2020 12345) (relative-date->date "05:35" now))
  (== (make-date 0 0 0 3 4 6 2020 12345) (relative-date->date "03:00" now))
  (== (make-date 0 0 58 23 3 6 2020 12345) (relative-date->date "23:58" now))
  (== (make-date 0 0 58 23 4 6 2020 12345) (relative-date->date "23:58" now :direction-weight :today))
  )

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

(let ([now (make-date 0 1 2 3 14 5 2022 32600)]) ;; Sat
  ;; default parameter
  (parameterize ([relative-date-weekend 6])
    (== (make-date 0 1 2 3 20 5 2022 32600) (relative-date->date "next fri" now))
    (== (make-date 0 1 2 3 13 5 2022 32600) (relative-date->date "last fri" now))
    (== (make-date 0 1 2 3 13 5 2022 32600) (relative-date->date "this fri" now))

    (== (make-date 0 1 2 3 21 5 2022 32600) (relative-date->date "next sat" now))
    (== (make-date 0 1 2 3  7 5 2022 32600) (relative-date->date "last sat" now))
    (== (make-date 0 1 2 3 14 5 2022 32600) (relative-date->date "this sat" now))

    (== (make-date 0 1 2 3 15 5 2022 32600) (relative-date->date "next sun" now))
    (== (make-date 0 1 2 3  8 5 2022 32600) (relative-date->date "last sun" now))
    (== (make-date 0 1 2 3  8 5 2022 32600) (relative-date->date "this sun" now))
    )
  ;; Weekend as Sunday
  (parameterize ([relative-date-weekend 0])
    (== (make-date 0 1 2 3 20 5 2022 32600) (relative-date->date "next fri" now))
    (== (make-date 0 1 2 3 13 5 2022 32600) (relative-date->date "last fri" now))
    (== (make-date 0 1 2 3 13 5 2022 32600) (relative-date->date "this fri" now))

    (== (make-date 0 1 2 3 21 5 2022 32600) (relative-date->date "next sat" now))
    (== (make-date 0 1 2 3  7 5 2022 32600) (relative-date->date "last sat" now))
    (== (make-date 0 1 2 3 14 5 2022 32600) (relative-date->date "this sat" now))

    (== (make-date 0 1 2 3 15 5 2022 32600) (relative-date->date "next sun" now))
    (== (make-date 0 1 2 3  8 5 2022 32600) (relative-date->date "last sun" now))
    (== (make-date 0 1 2 3 15 5 2022 32600) (relative-date->date "this sun" now)) ;only differ
    )
  )


(define (text== t additional-seconds)
  (== t
      (date->relative-date (add-second test-now additional-seconds) test-now)))

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
(inverse== "5 seconds ago")
(inverse== "30 seconds later")
(inverse== "30 seconds ago")
(inverse== "1 minute later")
(inverse== "2 minutes later")
(inverse== "3 minutes ago")
(inverse== "2 days ago")
(inverse== "1 day later")
(inverse== "2 days later")
(inverse== "1 month later")
(inverse== "1 month later")
(inverse== "1 month later")
(inverse== "2 months later")
(inverse== "3 months ago")
(inverse== "2 months later")
(inverse== "12 months later")
(inverse== "1 year later")
(inverse== "1 year later")
(inverse== "1 year later")
(inverse== "2 years later")
(inverse== "3 years ago")

(define (synonym== t1 t2 . ts)
  (let* ([d1 (relative-date->date t1 test-now)]
         [d2 (relative-date->date t2 test-now)])
    (test* #"~|t1| == ~|t2|" d1 d2)
    (cond
     [(pair? ts)
      (apply synonym== t2 ts)]
     [else
      #t])))

(synonym== "a day" "a day later" "1 day later" "tomorrow")
(synonym== "a day ago" "an day ago" "yesterday")
(synonym== "2 days ago" "2 day ago")
(synonym== "an hour ago" "1 hour ago")
(synonym== "2 hours ago" "120 minutes ago")
(synonym== "an hour later" "1 hour later")
(synonym== "1y1m1d" "1 year 1 month 1 day later")
(synonym== "1hour 2min 3sec" "1hour 2minutes 3seconds")
(synonym== "2 days ago" "1 day ago 1 day ago")
(synonym== "next thu" "next Thursday")
(synonym== "next mon" "Next Monday")
(synonym== "next mon next thu" "Next Monday Next Thursday")


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

(define (inconvertible? text)
  (test* #"~|text|" #f (relative-date->date text)))

;; TODO more negative test
(inconvertible? "a day invalid trailing")
(inconvertible? "invalid preceeding a day")

(test-end :exit-on-failure #t)
