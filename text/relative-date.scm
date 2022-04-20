(define-module text.relative-date
  (use srfi-13)
  (use util.match)
  (use srfi-19)
  (export
   relative-date->date
   fuzzy-parse-relative-date))
(select-module text.relative-date)

;; TODO just for the first purpose
(define (relative-date->date s :optional (now (current-date)))
  (time-utc->date (seconds->time (+ (time->seconds (date->time-utc now)) (fuzzy-parse-relative-date s)))))

(define (ensure-number s)
  (cond
   [(member s '("a" "an") string-ci=?)
    1]
   [(#/^[0-9.]+$/ s)
    (string->number s)]
   [else
    (error "Assert" s)]))

(define (ensure-unit-seconds u)
  (match u
    ["year"
     (* 24 60 60 365)]
    ["month"
     ;; TODO how to handle it
     (* 24 60 60 30)]
    ["day"
     (* 24 60 60)]
    ["hour"
     (* 60 60)]
    [(or "min" "minute")
     60]
    [(or "sec" "second")
     1]
    ))

(define (ensure-direction d)
  (cond
   [(string=? d "later")
    1]
   [(string=? d "ago")
    -1]
   [else
    (error "Assert" d)]))

(define (fuzzy-parse-relative-date text)
  (let loop ([s text]
             [diff 0])
    (cond
     [(string-null? s)
      diff]
     ;; TODO monthes
     [(#/^(an?|[0-9]+)[\s\t](year|month|day|hour|min|minute|sec|second)s?[\s\t](later|ago)/ s) =>
      (^m
       (let ([n (ensure-number (m 1))]
             [unit (ensure-unit-seconds (m 2))]
             [direction (ensure-direction (m 3))])
         (loop (m 'after) (+ diff (* n unit direction)))))]
     [else
      (error "Not a valid input text" s)])))

