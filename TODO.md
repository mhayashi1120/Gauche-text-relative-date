# bin

- create bin maintenance script to test how a relative text computed as date
- l10n
-- japanese yyyy年 MM 月 dd 日 hh 時 mm 分 ss 秒
-- mm/DD/yy DD/mm/yy each locale (en? us?)
-- l10n guideline (or (l10n-relative-parse-date s) (relative-date->date s)) or some parameter as list and process by fuzzy-parse-relative-seconds
- Next 5 (and Previous)
   - `Now` = 2022-01-02 then 2022-01-05
   - `Now` = 2022-01-06 then 2022-02-05
- define general Month (yyyy-MM)
- deifne generate Day (yyyy-MM-dd)
   - "05, Jan 2022" -> 2022-01-05
   - "2022-01-05" -> 2022-01-05
   - "05, Jan" -> Relative with 01-05
