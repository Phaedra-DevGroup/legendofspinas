class_name PersianUtils
extends RefCounted

## Shared Persian text helpers for RTL-safe UI labels.
## Converts Latin digits to extended-Arabic (۰..۹) so mixed text such as
## "کلیدسنگ‌ها: ۱/۲" keeps a stable right-to-left reading order.

const PERSIAN_DIGITS: Array[String] = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]

static func to_persian_number(n: int) -> String:
	var negative: bool = n < 0
	var latin: String = str(absi(n))
	var out: String = ""
	for i in range(latin.length()):
		out += PERSIAN_DIGITS[latin.unicode_at(i) - 48]
	if negative:
		out = "-" + out
	return out

static func to_persian_pair(a: int, b: int, separator: String = "/") -> String:
	return to_persian_number(a) + separator + to_persian_number(b)
