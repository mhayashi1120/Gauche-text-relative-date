# Gauche-text-relative-date

Intended to use parse date text in command-line app.

Main entry procedures are:

- relative-date->date
- date->relative-date
- fuzzy-parse-relative-seconds

This package roughly computed as Year (= 365 days) Month (= 30 days) . 
And not been considered to try exact parsing.

## Examples (relative-date->date):

Can read followings:

- a day == a day later == 1 day later
- a day ago == an day ago
- 2 days ago == 2 day ago
- an hour ago == 1 hour ago
- 2 hours ago == 120 minutes ago
- an hour later == 1 hour later
- 1y1m1d == 1 year 1 month 1 day later
- 1h 2min 3sec == 1h 2minutes 3seconds
- 01:02:03 (TODO not yet supported)
- 01:02:03 ago (TODO not yet supported)

## Examples (date->relative-date)

- just now
- 1 day ago
- 2 days later
- 1 year later
- 1 year later 365 days ago (=> means "now")

## References

- [Configuration file measurement units](https://nginx.org/en/docs/syntax.html)
- TODO at
- [Date input formats (GNU Coreutils 9.1)](https://www.gnu.org/software/coreutils/manual/html_node/Date-input-formats.html#Date-input-formats) (Not exact same although)

