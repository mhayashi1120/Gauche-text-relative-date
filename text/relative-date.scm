(define-module text.relative-date
  (use srfi-13)
  (use util.match)
  (use srfi-19)
  (export
   relative-date->date
   fuzzy-parse-relative-seconds))
(select-module text.relative-date)

;; ref: https://nginx.org/en/docs/syntax.html
;; consider unit
;; 1year 1y, 1m, 1s ...

;; TODO just for the first purpose
(define (relative-date->date s :optional (now (current-date)))
  (time-utc->date (seconds->time (+ (time->seconds (date->time-utc now)) (fuzzy-parse-relative-seconds s)))))

(define (ensure-number s)
  (cond
   [(member s '("a" "an") string-ci=?)
    1]
   [(#/^[0-9.]+$/ s)
    (string->number s)]
   [else
    (error "Assert" s)]))

;; Example, nginx handle year as 365day month as 30 day
(define (ensure-unit-seconds u)
  (match u
    ["year"
     (* 24 60 60 365)]
    ["month"
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
  (match (string-downcase d)
    ["later"
     1]
    ["ago"
     -1]
    [else
     (error "Assert" d)]))

;; return seconds
(define (fuzzy-parse-relative-seconds text)
  (let loop ([s text]
             [diff 0])
    (cond
     [(string-null? s)
      diff]
     ;; TODO monthes
     [(#/^(([0-9]+[ \t]*)|(?:(?:an?)[ \t]+))/i s) =>
      (^m
       (let1 n (ensure-number (string-trim-both (m 1)))
         (if-let1 m2 (#/^(year|monthe?|day|hour|min|minute|sec|second)s?[ \t]*/i (m 'after))
           (let1 unit (ensure-unit-seconds (m2 1))
             (if-let1 m3 (#/^(later|ago)/ (m2 'after))
               (let1 direction (ensure-direction (m3 1))
                 (loop (m3 'after) (+ diff (* n unit direction))))
               ;; (error "Failed to detect direction.")
               (loop (m2 'after) (+ diff (* n unit 1)))))
           (error "Failed to detect unit."))))]
     [else
      (error "Not a valid input text" s)])))

