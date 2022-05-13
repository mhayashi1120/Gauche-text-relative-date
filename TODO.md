# Should "00:01" like string.

[(#/^([0-9]+):([0-9]+)$/ s) =>
 (^m (+ (* (->number m 1) 60 60) (* (->number m 2) 60)))]
[(#/^([0-9]+):([0-9]+):([0-9]+)$/ s) =>
 (^m (+ (* (->number m 1) 60 60) (* (->number m 2) 60) (->number m 3)))]


"01:02" is confused with (1hour 2min) or (1min 2sec) . May be should not introduce.
On the other hand, "01:02:03" is Not confused. Explicitly 1hour 2min 3sec

# Handle week number

"Next wednesday", "Next Wed", "Before wed", "This wed"

# Handle next/last/this

Next month, last month
Next year, last year
Next week, last week (-> maybe need parameter handle saturday, sunday as weekend)

# bin

create bin maintenance script to test what the relative text handle date
