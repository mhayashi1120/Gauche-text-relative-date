;;;
;;; Test gauche_text_relative_date
;;;

(use gauche.test)

(test-start "gauche_text_relative_date")
(use gauche_text_relative_date)
(test-module 'gauche_text_relative_date)

;; The following is a dummy test code.
;; Replace it for your tests.
(test* "test-gauche_text_relative_date" "gauche_text_relative_date is working"
       (test-gauche_text_relative_date))

;; If you don't want `gosh' to exit with nonzero status even if
;; the test fails, pass #f to :exit-on-failure.
(test-end :exit-on-failure #t)
