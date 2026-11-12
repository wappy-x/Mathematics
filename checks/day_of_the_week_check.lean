-- Day of the week for any date: for every real date from 1900 to 2099, the card's sum (day of the month, plus the month's offset, plus years since 1900, plus leap days, with one taken back in January and February of a leap year) leaves the same remainder mod 7 as counting every day from Monday 1 January 1900, the month offsets are the month lengths shrunk mod 7, from 2100 the rule runs one day late, and the card's numbers come out as it says.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.IntervalCases

/-! Days of the week are the remainders 0 to 6: 0 Sunday, 1 Monday, 2 Tuesday, 3 Wednesday,
4 Thursday, 5 Friday, 6 Saturday. Dates are written day `d`, month `m` (1 to 12), year `y`. -/

/-- The Gregorian leap-year rule: every fourth year, but a century year only if it divides
by 400. So 1904 and 2000 are leap years, and 1900 and 2100 are not. -/
def IsLeap (y : ℕ) : Prop := 4 ∣ y ∧ (¬ 100 ∣ y ∨ 400 ∣ y)

instance : DecidablePred IsLeap := fun y => by unfold IsLeap; infer_instance

/-- How many days month `m` of year `y` has: February 28, or 29 in a leap year; April, June,
September and November 30; the rest 31. -/
def monthLength (y m : ℕ) : ℕ :=
  if m = 2 then (if IsLeap y then 29 else 28)
  else if m = 4 ∨ m = 6 ∨ m = 9 ∨ m = 11 then 30
  else 31

/-- A real date: the month is 1 to 12 and the day is 1 up to that month's length. -/
def ValidDate (d m y : ℕ) : Prop := 1 ≤ m ∧ m ≤ 12 ∧ 1 ≤ d ∧ d ≤ monthLength y m

/-- The long road: the number of days from 1 January 1900 to day `d` of month `m` of year `y`,
counting 365 or 366 for each whole year since 1900 and the full length of each whole month
so far this year. -/
def daysSince1900 (d m y : ℕ) : ℕ :=
  (∑ yr ∈ Finset.Ico 1900 y, if IsLeap yr then 366 else 365) +
    (∑ k ∈ Finset.Ico 1 m, monthLength y k) + (d - 1)

/-- The card's twelve month offsets, January to December: 0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5. -/
def monthOffset (m : ℕ) : ℕ := [0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5].getD (m - 1) 0

/-- The card's step back: take 1 off in January or February of a leap year. -/
def stepBack (m y : ℕ) : ℕ := if IsLeap y ∧ m ≤ 2 then 1 else 0

/-- Finite check behind the rule for 1900 to 2099. -/
theorem key_1900_2099 : ∀ y ∈ Finset.Ico 1900 2100, ∀ m ∈ Finset.Icc 1 12,
    (monthOffset m + (y - 1900) + (y - 1900) / 4 + 7 - stepBack m y) % 7 =
      ((∑ yr ∈ Finset.Ico 1900 y, if IsLeap yr then 366 else 365) +
        ∑ k ∈ Finset.Ico 1 m, monthLength y k) % 7 := by
  decide +kernel

#print axioms key_1900_2099

/-- Finite check behind the rule for 2100 to 2199. -/
theorem key_2100_2199 : ∀ y ∈ Finset.Ico 2100 2200, ∀ m ∈ Finset.Icc 1 12,
    (monthOffset m + (y - 1900) + (y - 1900) / 4 + 7 - stepBack m y) % 7 =
      ((∑ yr ∈ Finset.Ico 1900 y, if IsLeap yr then 366 else 365) +
        ∑ k ∈ Finset.Ico 1 m, monthLength y k + 1) % 7 := by
  decide +kernel

#print axioms key_2100_2199

theorem stepBack_le_one (m y : ℕ) : stepBack m y ≤ 1 := by
  unfold stepBack; split_ifs <;> omega

#print axioms stepBack_le_one

/-- The card's rule. For any real date from 1900 to 2099, add the day of the month, the
month's offset, the years since 1900 and the leap days in those years (the years since 1900
divided by 4, fraction dropped), take 1 back in January or February of a leap year, and divide
by 7. The leftover is the same as the leftover from 1 plus the count of days since
1 January 1900, which was a Monday (leftover 1). So the leftover names the true day of the
week, 0 being Sunday. -/
theorem day_of_week_rule_mod_seven (d m y : ℕ) (hy : 1900 ≤ y ∧ y ≤ 2099)
    (hdate : ValidDate d m y) :
    (d + monthOffset m + (y - 1900) + (y - 1900) / 4 - stepBack m y) % 7 =
      (1 + daysSince1900 d m y) % 7 := by
  obtain ⟨hm1, hm2, hd1, _⟩ := hdate
  have h := key_1900_2099 y (Finset.mem_Ico.2 ⟨hy.1, by omega⟩) m (Finset.mem_Icc.2 ⟨hm1, hm2⟩)
  have hs := stepBack_le_one m y
  unfold daysSince1900
  omega

/-- Where the month offsets come from: each month's 1st sits as many days past 1 January as
the lengths of the months before it in an ordinary year, and the offset is that count with the
whole weeks thrown away. -/
theorem month_offset_is_days_before_mod_seven (m : ℕ) (hm : 1 ≤ m ∧ m ≤ 12) :
    monthOffset m = (∑ k ∈ Finset.Ico 1 m, monthLength 1900 k) % 7 := by
  obtain ⟨h1, h2⟩ := hm
  interval_cases m <;> decide

/-- Past 2099 the rule breaks: 2100 is not a leap year, but dividing by 4 counts it as one.
So from 1 January 2100 (until 2200, the next skipped leap year) every answer comes out one day
late: the rule's leftover is the true day plus 1. -/
theorem day_of_week_rule_one_day_late_from_2100 (d m y : ℕ) (hy : 2100 ≤ y ∧ y ≤ 2199)
    (hdate : ValidDate d m y) :
    (d + monthOffset m + (y - 1900) + (y - 1900) / 4 - stepBack m y) % 7 =
      (1 + daysSince1900 d m y + 1) % 7 := by
  obtain ⟨hm1, hm2, hd1, _⟩ := hdate
  have h := key_2100_2199 y (Finset.mem_Ico.2 ⟨hy.1, by omega⟩) m (Finset.mem_Icc.2 ⟨hm1, hm2⟩)
  have hs := stepBack_le_one m y
  unfold daysSince1900
  omega

-- 20 July 1969, piece by piece: 20, July's offset 6, 69 years, 69 ÷ 4 = 17 leap days.
example : monthOffset 7 = 6 := by decide
example : 1969 - 1900 = 69 ∧ 69 / 4 = 17 := by decide
example : 20 + 6 = 26 ∧ 26 + 69 = 95 ∧ 95 + 17 = 112 := by decide
-- 112 = 16 × 7 + 0, leftover 0: a Sunday. July 1969 is not a leap-year January or February.
example : 112 = 16 * 7 + 0 ∧ 112 % 7 = 0 := by decide
example : stepBack 7 1969 = 0 := by decide
-- The long road: 25402 days since Monday 1 January 1900, and 25402 = 3628 × 7 + 6, a Sunday.
example : daysSince1900 20 7 1969 = 25402 := by decide
example : 25402 = 3628 * 7 + 6 ∧ (1 + 25402) % 7 = 0 := by decide
-- 1 January 1900 was a Monday: 1 + 0 + 0 + 0 = 1.
example : (1 + monthOffset 1 + 0 + 0 / 4 - stepBack 1 1900) % 7 = 1 := by decide
-- 1 January 1904 is a Friday (leftover 5) with the step back, Saturday (6) without it.
example : (1 + monthOffset 1 + 4 + 4 / 4 - stepBack 1 1904) % 7 = 5 := by decide
example : (1 + 0 + 4 + 1) % 7 = 6 := by decide
-- 6 September 2026: 6 + 5 + 126 + 31 = 168 = 24 × 7, a Sunday.
example : (6 + monthOffset 9 + 126 + 126 / 4 - stepBack 9 2026) % 7 = 0 := by decide
-- The three mistakes: no leap days gives 95, leftover 4, Thursday; no month offset gives 106,
-- leftover 1, Monday.
example : (112 - 17) % 7 = 4 ∧ (112 - 6) % 7 = 1 := by decide
-- The year steps and month steps behind the offsets.
example : 365 = 52 * 7 + 1 ∧ 366 = 52 * 7 + 2 := by decide
example : 31 % 7 = 3 ∧ 28 % 7 = 0 := by decide
-- The leap-year rule: 1900 was not a leap year, 2000 was, 2100 will not be.
example : ¬ IsLeap 1900 ∧ IsLeap 2000 ∧ ¬ IsLeap 2100 := by decide
-- Ninety days on lands one day earlier in the week: 90 ≡ 6 (mod 7).
example : 90 % 7 = 6 := by decide

#print axioms day_of_week_rule_mod_seven
#print axioms month_offset_is_days_before_mod_seven
#print axioms day_of_week_rule_one_day_late_from_2100
