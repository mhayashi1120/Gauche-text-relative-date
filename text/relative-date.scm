;;;
;;; Relative (and fuzzy) datetime (as text)
;;;

(define-module text.relative-date
  (use srfi-13)
  (use util.match)
  (use srfi-19)
  (use gauche.parameter)
  (export
   relative-date->date date->relative-date
   fuzzy-parse-relative-seconds
   ))
(select-module text.relative-date)

;; ref: https://nginx.org/en/docs/syntax.html
;; consider unit
;; 1year 1y, 1m, 1s ...

;;;
;;; Tiny utility
;;;

(define (date->seconds d)
  ($ floor->exact $ time->seconds $ date->time-utc d))

(define (seconds->date s)
  ($ time-utc->date $ seconds->time $ floor->exact s))

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
    [(or "hour" "h")
     (* 60 60)]
    [(or "minute" "min")
     60]
    [(or "second" "sec" "s")
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

(define (try-parse-full-text s)

  (cond
   [(member (string-trim-both s) '("just now" "now"))
    0]
   [else
    #f]))

(define (try-read-unit s)
  (and-let1 m (#/^(([0-9]+[ \t]*)|(?:(?:an?)[ \t]+))/i s)
    (let1 n (ensure-number (string-trim-both (m 1)))
      (cond
       [(#/^((year|month|day|hour|minute|min|second|sec)s?|[ymdhs])[ \t]*/i (m 'after)) =>
        (^ [m2]
          (let1 unit (ensure-unit-seconds (m2 1))
            (if-let1 m3 (#/^(later|ago)/ (m2 'after))
              (let1 direction (ensure-direction (m3 1))
                (list (m3 'after) (* n unit direction)))
              ;; Default is "later"
              (list (m2 'after) (* n unit 1)))))]
       [else
        #f]))))

;; Just plan
;; (define (try-read-colon-separator s)
;;   (define (->number m i)
;;     (string->number (m i)))

;;   (cond
;;    [(#/^([0-9]+):([0-9]+):([0-9]+)\b/ s) =>
;;     (^m (list (m 'after)
;;               (+ (* (->number m 1) 60 60)
;;                  (* (->number m 2) 60)
;;                  (->number m 3))))]
;;    [(#/^([0-9]+):([0-9]+)\b/ s) =>
;;     (^m (list (m 'after)
;;               (+ (* (->number m 1) 60 60)
;;                  (* (->number m 2) 60))))]
;;    [else
;;     #f]))

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
     [(< diff-abs (* 24 60 60))
      (let1 diff-hour (div diff-abs (* 60 60))
        (format #t "~a hour" diff-hour)
        (when (< 1 diff-hour)
          (format #t "s")))]
     [(< diff-abs (* 24 60 60 30))
      (let1 diff-day (div diff-abs (* 24 60 60))
        (format #t "~a day" diff-day)
        (when (< 1 diff-day)
          (format #t "s")))]
     [(< diff-abs (* 24 60 60 365))
      (let1 diff-month (div diff-abs (* 24 60 60 30))
        (format #t "~a month" diff-month)
        (when (< 1 diff-month)
          (format #t "s")))]
     [else
      (let1 diff-year (div diff-abs (* 24 60 60 365))
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
  (and-let* ([sec (fuzzy-parse-relative-seconds s)]
             [result-sec (+ (date->seconds now) sec)])
    (seconds->date result-sec)))

;; return seconds if TEXT parse is succeeded.
;; return with if failed.
(define (fuzzy-parse-relative-seconds text)
  (or (try-parse-full-text text)
      (let loop ([s text]
                 [diff 0])
        (cond
         [(string-null? s)
          diff]
         [(try-read-unit s) =>
          (match-lambda
           [(rest sec)
            (loop rest (+ diff sec))])]
         ;; [(try-read-colon-separator s) =>
         ;;  (match-lambda
         ;;   [(rest sec)
         ;;    (loop rest (+ diff sec))])]
         [else
          #f]))))
