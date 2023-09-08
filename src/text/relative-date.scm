;;;
;;; Relative(fuzzy) datetime
;;;

(define-module text.relative-date
  (use gauche.sequence)
  (use srfi-13)
  (use util.match)
  (use srfi-19)
  (use gauche.parameter)
  (export
   print-relative-date
   relative-date-weekend
   relative-date->date date->relative-date
   fuzzy-parse-relative-seconds parse-fuzzy-seconds
   ))
(select-module text.relative-date)

;;;
;;; Parameter
;;;

;; ## <parameter { <integer>[0, 6]}>
;; default `6` means "Saturday". This maybe "Sunday" (= 0) some of cases.
(define relative-date-weekend
  (make-parameter 6
    (^x (begin0 (assume-type x <integer>)
          (assume (<= 0 x 6))))))

;; ## <parameter <integer>>
;; Range represent as `just now`
(define just-now-range
  (make-parameter 0
    (^x (assume-type x <integer>))))

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

(define suffixed-ordinal-days
  (list->vector
   (map
    (^i
     (case (mod i 10)
       [(1)
        (format "~ast" i)]
       [(2)
        (format "~and" i)]
       [(3)
        (format "~ard" i)]
       [else
        (format "~ath" i)]))
    (iota 31 1))))

(define (ci-index-of v vec)
  (find-index (^x (string-ci=? v x)) vec))

;;;
;;; Tiny utility
;;;

(define (date->seconds d)
  ($ floor->exact $ time->seconds $ date->time-utc d))

(define (seconds->date s :optional (zone #f))
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
  (add-seconds d (* n 24 60 60)))

(define (add-year d n)
  (make-date
   (date-nanosecond d) (date-second d) (date-minute d)
   (date-hour d) (date-day d) (date-month d)
   (+ (date-year d) n)
   (date-zone-offset d)))

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

(define (find-month-index s)
  (or (ci-index-of s abbreviate-months)
      (ci-index-of s formal-months)))

(define (find-day-index s)
  (or (ci-index-of s suffixed-ordinal-days)
      (and-let1 n (string->number s)
        (- n 1))))

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
        (^ [m-unit]
          (let1 unit (ensure-unit-seconds (m-unit 1))
            (if-let1 m-direction (#/^(later|ago)/ (m-unit 'after))
              (let1 direction (ensure-direction (m-direction 1))
                (list (m-direction 'after) (* n unit direction)))
              ;; Default is "later"
              (list (m-unit 'after) (* n unit 1)))))]
       [else
        #f]))))

;; -> (REST DIFF-SEC)
(define (try-read-colon-separator s now weight)
  (define (->number m i)
    (string->number (m i)))

  (define (diff-time hh mm ss)
    (let* ([today (make-date
                   0 (or ss 0) mm hh
                   (date-day now) (date-month now) (date-year now)
                   (date-zone-offset now))]
           [today* (date-diff today now)]
           [a-day* (* 24 60 60)])

      (ecase weight
        [(:today)
         today*]
        [(:fuzzy)
         (cond
          [(<= (abs today*) (div a-day* 2))
           today*]
          [(positive? today*)
           (- today* a-day*)]
          [else
           (+ today* a-day*)])]
        [(:past)
         (if (positive? today*)
           (- today* a-day*)
           today*)]
        [(:future)
         (if (positive? today*)
           today*
           (+ today* a-day*))])))

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

(define (try-read-common-day s now weight)

  (define (compute-day month-i day-i)
    (let* ([month (+ month-i 1)]
           [day (+ day-i 1)]
           [this-year (make-date
                       0 0 0 0
                       day month (date-year now)
                       (date-zone-offset now))]
           [this-year* (date-diff this-year now)]
           [a-year* (* 24 60 60 365)])

      (ecase weight
        [(:today)
         this-year*]
        [(:fuzzy)
         (cond
          [(<= (abs this-year*) (div a-year* 2))
           this-year*]
          [(positive? this-year*)
           (date-diff (add-year this-year -1) now)]
          [else
           (date-diff (add-year this-year 1) now)])]
        [(:past)
         (if (positive? this-year*)
           (date-diff (add-year this-year -1) now)
           this-year*)]
        [(:future)
         (if (positive? this-year*)
           this-year*
           (date-diff (add-year this-year 1) now))])))

  ;; ## can read following examples:
  ;; -  "Jan, 1th"
  ;; - "05 Feb"
  ;; - "29, Feb"
  ;; - "31th December"
  ;; - "November 31"
  ;; - "Oct 28"
  (define month* (vector->regexp-string abbreviate-months formal-months))
  (define day* (vector->regexp-string suffixed-ordinal-days))
  (define day** "([0-9]{1,2})\\b")
  (define skip* "[, \t]+")

  (cond
   [((string->regexp #"^~|month*|~|skip*|~|day*|") s) =>
    (^m
     (list
      (m 'after)
      (compute-day (find-month-index (m 1))
                   (find-day-index (m 2)))))]
   [((string->regexp #"^~|month*|~|skip*|~|day**|") s) =>
    (^m
     (list
      (m 'after)
      (compute-day (find-month-index (m 1))
                   (find-day-index (m 2)))))]
   [((string->regexp #"^~|day*|~|skip*|~|month*|") s) =>
    (^m
     (list
      (m 'after)
      (compute-day (find-month-index (m 2))
                   (find-day-index (m 1)))))]
   [((string->regexp #"^~|day**|~|skip*|~|month*|") s) =>
    (^m
     (list
      (m 'after)
      (compute-day (find-month-index (m 2))
                   (find-day-index (m 1)))))]
   [else #f]))

(define (vector->regexp-string . vs)
  ($ (cut format "(~a)\\b" <>)
     $ (cut string-join <> "|")
     $ map regexp-quote
     $ append-map vector->list vs))

(define (vector->iregexp-reader . vs)
  ($ (cut string->regexp <> :case-fold #t)
     $ apply vector->regexp-string vs))

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
                        (error "Assert")])]
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
                  [m-day (weekday-re (string-trim (m 'after)))]
                  [weekday (m-day 1)])
         (list (m-day 'after) (compute-weekday prefix weekday))))]
     [(weekday-re s) =>
      (^m (let ([weekday (m 1)])
            (list (m 'after) (compute-weekday "this" weekday))))]
     [else
      #f])))

;;;
;;; # API
;;;

;; ## Print <date> to `current-output-port`
;; -> <void>
(define (print-relative-date d :optional (now (current-date)))
  (assume-type d <date>)
  (assume-type now <date>)

  (let* ([diff-sec (- (date->seconds d) (date->seconds now))]
         [diff-abs (abs diff-sec)]
         ;; Maybe destructively changed.
         [sign (cond
                [(positive? diff-sec) 1]
                [(negative? diff-sec) -1]
                [else 0])]
         )
    (cond
     [(<= diff-abs (just-now-range))
      (format #t "just now")
      (set! sign #f)]
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
     [(not (integer? sign))]
     [(positive? sign)
      (format #t " later")]
     [(negative? sign)
      (format #t " ago")])))

;; ## Pretty print <date>
;; <date> -> <string>
(define (date->relative-date d :optional (now (current-date)))
  (assume-type d <date>)

  (with-output-to-string
    (^[] (print-relative-date d now))))

;; ## Parse relative date S as <date>
;; <string> -> <date> | #f
(define (relative-date->date
         s
         :optional (now (current-date))
         :key (direction-weight :fuzzy))
  (assume-type s <string>)
  (assume-type now (<?> <date>))
  (assume-type direction-weight <keyword>)

  (and-let* ([now (or now (current-date))]
             [sec (parse-fuzzy-seconds
                   s
                   :now now
                   :direction-weight direction-weight)]
             [result-sec (+ (date->seconds now) sec)])
    (seconds->date result-sec (date-zone-offset now))))

;; ## Parse relative TEXT as seconds.
;; - :now : <date>
;; - :direction-weight : :fuzzy (default) / :today / :future / :past
;;     Some of inexact date specific unit (e.g. "03:04", "Jan, 05"), that should return in
;;     any context.  If you are working on `2023-01-18 23:50` then type `00:20`
;;        almost case want to be pointed `2023-01-19 00:20`.
;;     This option doesn't affect any exact date unit.
;;     - :fuzzy : The nearest point of time from `now`.
;;     - :today : Time part as today based on `now`. (This is previous default behavior)
;;     - :future : Never return past time from `now`. (Use-case schedule ...)
;;     - :past : Never return future time from `now`. (Use-case blog ...)
;; -> SECOND:<number> | #f
(define (parse-fuzzy-seconds text :key (now (current-date)) (direction-weight :fuzzy))
  (assume-type text <string>)
  (assume-type now <date>)
  (assume-type direction-weight <keyword>)

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
           [(try-read-colon-separator s now direction-weight) =>
            (match-lambda
             [(rest sec)
              (loop rest (+ diff sec))])]
           [(try-read-common-day s now direction-weight) =>
            (match-lambda
             [(rest sec)
              (loop rest (+ diff sec))])]
           [(try-read-weekday s now) =>
            (match-lambda
             [(rest days)
              (loop rest (+ diff (* days 24 60 60)))])]
           [else
            #f])))))

;; ## Parse relative TEXT as seconds.
;; Old interface. Should consider to use `parse-fuzzy-seconds`
;; - :now : <date>
;; -> <number> | #f
(define (fuzzy-parse-relative-seconds text :optional (now (current-date)))
  (parse-fuzzy-seconds text :now now :direction-weight :fuzzy))
