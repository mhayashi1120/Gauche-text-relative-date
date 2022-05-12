# Gauche-text-relative-date

intended to use parse date text from command-line

- relative-date->date
- date->relative-date
- fuzzy-parse-relative-seconds

This package roughly computed as Year (= 365 days) Month (= 30 days) .

## Examples (relative-date->date):

Can read followings:

- a day == a day later == 1 day later
- a day ago == an day ago
- 2 days ago == 2 day ago
- an hour ago == 1 hour ago
- 2 hours ago == 120 minutes ago
- an hour later == 1 hour later
- 1y1m1d == 1 year 1 month 1 day later

## Examples (date->relative-date)

- just now
- 1 day ago
- 2 days later
- 1 year later

