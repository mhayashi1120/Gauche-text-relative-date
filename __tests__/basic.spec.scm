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

(let ([now (build-date 2020 6 4 3 2 1 12345)])
  (== (build-date 2020 6 4 03 04 0 12345) (relative-date->date "03:04" now))
  (== (build-date 2020 6 3 23 58 0 12345) (relative-date->date "23:58" now))
  )

(let ([now (build-date 2022 12 30 3 2 1 31400)])
  (== (build-date 2022 12 15 0 0 0 31400) (relative-date->date "December, 15" now))
  (== (build-date 2022 11 16 0 0 0 31400) (relative-date->date "November, 16" now))
  (== (build-date 2023 05 17 0 0 0 31400) (relative-date->date "May 17" now))
  (== (build-date 2023 01 02 0 0 0 31400) (relative-date->date "Jan, 02" now))
  (== (build-date 2023 01 02 0 0 0 31400) (relative-date->date "2 Jan" now))
  (== (build-date 2023 01 03 0 0 0 31400) (relative-date->date "Jan 3" now))
  ;; can handle unexists day
  (== (build-date 2023 03 01 0 0 0 31400) (relative-date->date "Feb 29" now))
  (== (build-date 2023 03 01 0 0 0 31400) (relative-date->date "29 Feb" now))
  (== (build-date 2023 03 01 0 0 0 31400) (relative-date->date "29, Feb" now))
  )

(let ([now (build-date 2020 06 4 3 2 1 12345)]) ;; Thu
  (== (build-date 2020 6 4 03 30 0 12345) (relative-date->date "03:30" now))
  (== (build-date 2020 6 4 05 35 0 12345) (relative-date->date "05:35" now))
  (== (build-date 2020 6 4 03 0 0 12345) (relative-date->date "03:00" now))
  (== (build-date 2020 6 3 23 58 0 12345) (relative-date->date "23:58" now))
  (== (build-date 2020 6 4 23 58 0 12345) (relative-date->date "23:58" now :direction-weight :today))
  )

(let ([now (build-date 2020 6 4 3 2 1 12345)]) ;; Thu
  (== (build-date 2020 6 10 3 2 1 12345) (relative-date->date "next wed" now))
  (== (build-date 2020 6 03 3 2 1 12345) (relative-date->date "last wed" now))
  (== (build-date 2020 6 03 3 2 1 12345) (relative-date->date "this wed" now))

  (== (build-date 2020 6 11 3 2 1 12345) (relative-date->date "next thu" now))
  (== (build-date 2020 5 28 3 2 1 12345) (relative-date->date "last thu" now))
  (== (build-date 2020 6 04 3 2 1 12345) (relative-date->date "this thu" now))

  (== (build-date 2020 6 05 3 2 1 12345) (relative-date->date "next fri" now))
  (== (build-date 2020 5 29 3 2 1 12345) (relative-date->date "last fri" now))
  (== (build-date 2020 6 05 3 2 1 12345) (relative-date->date "this fri" now))

  )

(let ([now (build-date 2022 5 14 3 2 1 32600)]) ;; Sat
  ;; default parameter
  (parameterize ([relative-date-weekend 6])
    (== (build-date 2022 5 20 3 2 1 32600) (relative-date->date "next fri" now))
    (== (build-date 2022 5 13 3 2 1 32600) (relative-date->date "last fri" now))
    (== (build-date 2022 5 13 3 2 1 32600) (relative-date->date "this fri" now))

    (== (build-date 2022 5 21 3 2 1 32600) (relative-date->date "next sat" now))
    (== (build-date 2022 5 07 3 2 1 32600) (relative-date->date "last sat" now))
    (== (build-date 2022 5 14 3 2 1 32600) (relative-date->date "this sat" now))

    (== (build-date 2022 5 15 3 2 1 32600) (relative-date->date "next sun" now))
    (== (build-date 2022 5 08 3 2 1 32600) (relative-date->date "last sun" now))
    (== (build-date 2022 5 08 3 2 1 32600) (relative-date->date "this sun" now))
    )
  ;; Weekend as Sunday
  (parameterize ([relative-date-weekend 0])
    (== (build-date 2022 5 20 3 2 1 32600) (relative-date->date "next fri" now))
    (== (build-date 2022 5 13 3 2 1 32600) (relative-date->date "last fri" now))
    (== (build-date 2022 5 13 3 2 1 32600) (relative-date->date "this fri" now))

    (== (build-date 2022 5 21 3 2 1 32600) (relative-date->date "next sat" now))
    (== (build-date 2022 5 07 3 2 1 32600) (relative-date->date "last sat" now))
    (== (build-date 2022 5 14 3 2 1 32600) (relative-date->date "this sat" now))

    (== (build-date 2022 5 15 3 2 1 32600) (relative-date->date "next sun" now))
    (== (build-date 2022 5 08 3 2 1 32600) (relative-date->date "last sun" now))
    (== (build-date 2022 5 15 3 2 1 32600) (relative-date->date "this sun" now)) ;only differ
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
