;;;
;;; Relative (and fuzzy) datetime (as text)
;;;

(define-module text.relative-date
  (use gauche.sequence)
  (use srfi-13)
  (use util.match)
  (use srfi-19)
  (use gauche.parameter)
  (use toolbox.rail)
  (export
   relative-date-weekend
   relative-date->date date->relative-date
   fuzzy-parse-relative-seconds
   ))
(select-module text.relative-date)

;;;
;;; Parameter
;;;

;; default `6` means "Saturday". This maybe "Sunday" (= 0) some of cases.
(define relative-date-weekend
  (make-parameter 6))

;;;
;;; Constants
;;;

(define abbreviate-weekdays
  #("Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat"))

(define formal-weekdays
  #("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday"))

(define abbreviate-months
  #(
    "Jan" "Feb" "Mar" "Apr" "May" "Jun"
    "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"
    ))

(define formal-months
  #(
    "January" "February" "March" "April"
    "May" "June" "July" "August"
    "September" "October" "November" "December"
    ))

(define (ci-index-of v vec)
  (find-index (^x (string-ci=? v x)) vec))

;;;
;;; Tiny utility
;;;

(define (date->seconds d)
  ($ floor->exact $ time->seconds $ date->time-utc d))

(define (seconds->date s :optional (zone #f))
  ;; TODO more smart
  (define time->date
    (if zone
      (cut time-utc->date <> zone)
      (cut time-utc->date <>)))

  ($ time->date
     $ seconds->time
     $ floor->exact s))

(define (add-seconds d n)
  ($ seconds->date $ + (date->seconds d) n))

(define (add-days d n)
  (add-seconds d (* 24 60 60)))

;; Just diff second part. (omit nanosecond part)
(define (date-diff d1 d2)
  (- (date->seconds d1) (date->seconds d2)))

(define (date-weekday d)
  (date-week-day d))

(define (weekday->weekday* n)
  (let* ([weekcnt (vector-length formal-weekdays)]
         [bow (mod (+ (relative-date-weekend) 1) weekcnt)]
         [n (- n bow)])
    (mod n weekcnt)))

(define (find-weekday-index s)
  (or (ci-index-of s abbreviate-weekdays)
      (ci-index-of s formal-weekdays)))

(define (date-weekday* d)
  (weekday->weekday* (date-weekday d)))

(define (find-weekday-index* s)
  (if-let1 i (find-weekday-index s)
    (weekday->weekday* i)
    #f))

;;;
;;; Unit handling
;;;

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
  (match (string-downcase (trim-plural u))
    [(or "year" "y")
     (* 24 60 60 365)]
    [(or "month" "m")
     (* 24 60 60 30)]
    [(or "day" "d")
     (* 24 60 60)]
    [(or "hour")
     (* 60 60)]
    [(or "minute" "min")
     60]
    [(or "second" "sec")
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

(define (trim-plural s)
  (cond
   [(#/s$/i s) =>
    (^m (m 'before))]
   [else
    s]))

;;;
;;; Parsing
;;;

;; Exact match whole text.
(define (try-parse-full-symbolic s)
  (cond
   [(member (string-trim-both s) '("just now" "now"))
    0]
   [else
    #f]))

(define (try-read-symbol-text s)
  (cond
   [(#/^tomorrow\b/ s) =>
    (^m (list (m 'after) (*  1 24 60 60)))]
   [(#/^yesterday\b/ s) =>
    (^m (list (m 'after) (* -1 24 60 60)))]
   [else
    #f]))

(define (try-read-unit s)
  (and-let1 m (#/^([-+]?([0-9]+[ \t]*)|(?:(?:an?)[ \t]+))/i s)
    (let1 n (ensure-number (string-trim-both (m 1)))
      (cond
       [(#/^((year|month|day|hour|minute|min|second|sec)s?|[ymd])[ \t]*/i (m 'after)) =>
        (^ [m2]
          (let1 unit (ensure-unit-seconds (m2 1))
            (if-let1 m3 (#/^(later|ago)/ (m2 'after))
              (let1 direction (ensure-direction (m3 1))
                (list (m3 'after) (* n unit direction)))
              ;; Default is "later"
              (list (m2 'after) (* n unit 1)))))]
       [else
        #f]))))

;; -> (REST DIFF-SEC)
(define (try-read-colon-separator s now)
  (define (->number m i)
    (string->number (m i)))

  (define (diff-time hh mm ss)
    (date-diff
     (make-date
      0 hh mm (or ss 0)
      (date-day now) (date-month now) (date-year now)
      (date-zone-offset now))
     now))

  (cond
   ;; Today's this time (hh:mm:ss).
   [(#/^([0-9]+):([0-9]+):([0-9]+)\b/ s) =>
    (^m (list (m 'after)
              (diff-time
               (->number m 1)
               (->number m 2)
               (->number m 3)
               )))]
   ;; Considered as hh:mm
   [(#/^([0-9]+):([0-9]+)\b/ s) =>
    (^m (list (m 'after)
              (diff-time
               (->number m 1)
               (->number m 2)
               0)))]
   [else
    #f]))

(define (vector->iregexp-reader . vs)
  ($ (cut string->regexp <> :case-fold #t)
     $ (cut format "^(~a)\\b" <>)
     $ (cut string-join <> "|")
     $ map regexp-quote
     $ append-map vector->list vs))

;; "last":
;;    ----
;; ---+
;; "this":
;; ---+---
;; "next":
;;     +--
;; -----

;; -> (REST DAYS)
(define (try-read-weekday s now)
  (define (compute-weekday prefix weekday)
    (let* ([now-wi* (date-weekday* now)]
           [pref (string-downcase prefix)]
           [direction (cond
                       [(member pref '("last"))
                        -1]
                       [(member pref '("this"))
                        0]
                       [(member pref '("next"))
                        1]
                       [else
                        (ASSERT #f)])]
           [wi* (find-weekday-index* weekday)])

      (unless wi*
        (error "Assert. Weekday must be found." weekday))

      ;; TODO FIXME: more elegant
      (cond
       [(zero? direction)
        (- wi* now-wi*)]
       [(negative? direction)
        (- (+ 7 (modulo (- now-wi* wi*) -7)))]
       [(positive? direction)
        (+ 7 (modulo (- wi* now-wi*) -7))]
       )
      ))

  (let* ([weekday-re (vector->iregexp-reader abbreviate-weekdays formal-weekdays)])
    (cond
     [(#/^(this|next|last)[ \t]+/i s) =>
      (^m 
       (and-let* ([prefix (m 1)]
                  [m2 (weekday-re (string-trim (m 'after)))]
                  [weekday (m2 1)])
         (list (m2 'after) (compute-weekday prefix weekday))))]
     [(weekday-re s) => 
      (^m (let ([weekday (m 1)])
            (list (m 'after) (compute-weekday "this" weekday))))]
     [else
      #f])))

;;;
;;; API
;;;

(define (print-relative-date d :optional (now (current-date)))
  (let* ([diff-sec (- (date->seconds d) (date->seconds now))]
         [diff-abs (abs diff-sec)]
         [sign (cond
                [(positive? diff-sec) 1]
                [(negative? diff-sec) -1]
                [else 0])]
         )
    (cond
     [(= diff-abs 0)
      (format #t "just now")]
     [(< diff-abs 60)
      (format #t "~a second" diff-abs)
      (when (< 1 diff-abs)
        (format #t "s"))]
     [(< diff-abs (* 60 60))
      (let1 diff-min (div diff-abs (* 60))
        (format #t "~a minute" diff-min)
        (when (< 1 diff-min)
          (format #t "s")))]
     [(< diff-abs (* 60 60 24))
      (let1 diff-hour (div diff-abs (* 60 60))
        (format #t "~a hour" diff-hour)
        (when (< 1 diff-hour)
          (format #t "s")))]
     [(< diff-abs (*  60 60 24 30))
      (let1 diff-day (div diff-abs (* 60 60 24))
        (format #t "~a day" diff-day)
        (when (< 1 diff-day)
          (format #t "s")))]
     [(< diff-abs (* 60 60 24 365))
      (let1 diff-month (div diff-abs (* 60 60 24 30))
        (format #t "~a month" diff-month)
        (when (< 1 diff-month)
          (format #t "s")))]
     [else
      (let1 diff-year (div diff-abs (* 60 60 24 365))
        (format #t "~a year" diff-year)
        (when (< 1 diff-year)
          (format #t "s")))])
    (cond
     [(positive? sign)
      (format #t " later")]
     [(negative? sign)
      (format #t " ago")])))

(define (date->relative-date d :optional (now (current-date)))
  (with-output-to-string
    (^[] (print-relative-date d now))))

(define (relative-date->date s :optional (now (current-date)))
  (and-let* ([sec (fuzzy-parse-relative-seconds s now)]
             [result-sec (+ (date->seconds now) sec)])
    (seconds->date result-sec (date-zone-offset now))))

;; return seconds if TEXT parse is succeeded.
;; return with if failed.
(define (fuzzy-parse-relative-seconds text :optional (now (current-date)))
  (or (try-parse-full-symbolic text)
      (let loop ([source (string-trim-right text)]
                 [diff 0])
        (let1 s (string-trim source)
          (cond
           [(string-null? s)
            diff]
           [(try-read-unit s) =>
            (match-lambda
             [(rest sec)
              (loop rest (+ diff sec))])]
           [(try-read-symbol-text s) =>
            (match-lambda
             [(rest sec)
              (loop rest (+ diff sec))])]
           [(try-read-colon-separator s now) =>
            (match-lambda
             [(rest sec)
              (loop rest (+ diff sec))])]
           [(try-read-weekday s now) =>
            (match-lambda
             [(rest days)
              (loop rest (+ diff (* days 24 60 60)))])]
           [else
            #f])))))
