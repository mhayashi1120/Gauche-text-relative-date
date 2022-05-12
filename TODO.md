# Should "00:01" like string.

[(#/^([0-9]+):([0-9]+)$/ s) =>
 (^m (+ (* (->number m 1) 60 60) (* (->number m 2) 60)))]
[(#/^([0-9]+):([0-9]+):([0-9]+)$/ s) =>
 (^m (+ (* (->number m 1) 60 60) (* (->number m 2) 60) (->number m 3)))]


01:02 is confused with (1hour 1min) or (1min 1sec) .May be should not introduce.