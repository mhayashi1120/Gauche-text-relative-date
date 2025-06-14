# Gauche-text-relative-date

[![CI](https://github.com/mhayashi1120/Gauche-text-relative-date/actions/workflows/build.yml/badge.svg)](https://github.com/mhayashi1120/Gauche-text-relative-date/actions/workflows/build.yml)

Roughly parse date text and print relative time more user friendly.

Following use case are intended:

- Any configuration file.
- Parse command line argument.
- Print timeline datetime more friendly. (e.g. Twitter)

Main entry procedures are:

- relative-date->date
- date->relative-date
- parse-fuzzy-seconds

This package roughly computed as Year (= 365 days) Month (= 30 days) in some of conversion.
And **NOT** been considered to try exact parsing and point exact time.

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
- next thu == next Thursday
- next mon == Next Monday
- 03:04 == The nearest 03:04am (depend on the weight setting)
- 29, Feb == The nearest February 29 or March 1

## Examples (date->relative-date)

- just now
- 1 day ago
- 2 days later
- 1 year later
- 1 year later 365 days ago (=> means "now")

# API

Almost procedures optionally accept `now` as \<date>

## relative-date->date (Procedure: \<string> -> \<date> | #f)

Accept one argument as string and return date or #f

## date->relative-date (Procedure: \<date> -> \<string>)

Accept one argument as \<date> and return string

## print-relative-date (Procedure: \<date> -> \<void>)

Low level api of `date->relative-date`

## parse-fuzzy-seconds (Procedure: \<string> -> \<number> | #f)

return relative seconds.

## relative-date-weekend (Parameter)

Can change the weekend on your locale.

# External References

- [Configuration file measurement units](https://nginx.org/en/docs/syntax.html)
- ref: Debian /usr/share/doc/at/timespec
- [Date input formats (GNU Coreutils 9.1)](https://www.gnu.org/software/coreutils/manual/html_node/Date-input-formats.html#Date-input-formats) (Not exact same although)

