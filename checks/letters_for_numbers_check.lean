-- Letters for numbers: for every number of miles m, two taxi fares 3 + 2m added together, the collected form 6 + 4m and the bracketed form 2(3 + 2m) are the same number, the fare built a mile at a time is 3 + 2m, a fare of 15 means exactly 6 whole miles, and the card's worked numbers and wrong readings come out as it says.
import Mathlib.Algebra.Ring.Defs
import Mathlib.Logic.Function.Iterate
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-- Two taxis on the same trip of `m` miles, where each charges 3 dollars to start plus
2 dollars a mile. Adding the two fares `3 + 2m` and collecting like terms gives `6 + 4m`, and
doubling one fare with a bracket, `2(3 + 2m)`, multiplies out to the same `6 + 4m`. Both taxis
share the one letter `m`, the 2 multiplies the `m`, and the start fee is charged by each taxi.
This uses only the rearranging laws, so it holds for any number `m` in any number system that
obeys them (a commutative semiring), whole numbers included. -/
theorem two_fares_collected_equals_bracketed {R : Type*} [CommSemiring R] (m : R) :
    (3 + 2 * m) + (3 + 2 * m) = 6 + 4 * m ∧ 2 * (3 + 2 * m) = 6 + 4 * m := by
  constructor <;> ring

/-- The fare built a mile at a time: start at 3 dollars and add 2 dollars once for each of the
`m` miles. That always lands on the recipe `3 + 2m`, whatever whole number `m` is. -/
theorem fare_a_mile_at_a_time (m : ℕ) : (fun total => total + 2)^[m] 3 = 3 + 2 * m := by
  induction m with
  | zero => rfl
  | succ n ih =>
    rw [Function.iterate_succ_apply', ih]
    omega

/-- The letter as an unknown: the meter reads 15 dollars on a whole number of miles `m`
exactly when `m` is 6. (The card tries every whole number up to 20; this holds for all of them.) -/
theorem fare_fifteen_means_six_miles (m : ℕ) : 3 + 2 * m = 15 ↔ m = 6 := by
  omega

-- Substituting into 3 + 2m: 6 miles, 10 miles and no miles at all.
example : 2 * 6 = 12 := by decide
example : 3 + 2 * 6 = 15 := by decide
example : 3 + 2 * 10 = 23 := by decide
example : 3 + 2 * 0 = 3 := by decide
-- A mile at a time for 6 miles.
example : 3 + 2 + 2 + 2 + 2 + 2 + 2 = 15 := by decide
-- The two-taxi fare three ways at 6 miles.
example : 15 + 15 = 30 := by decide
example : 6 + 4 * 6 = 30 := by decide
example : 2 * (3 + 2 * 6) = 30 := by decide
-- The plotted lines at 0, 2, 4, 6, 8 and 10 miles.
example : [0, 2, 4, 6, 8, 10].map (fun m => 3 + 2 * m) = [3, 7, 11, 15, 19, 23] := by decide
example : [0, 2, 4, 6, 8, 10].map (fun m => 6 + 4 * m) = [6, 14, 22, 30, 38, 46] := by decide
-- Only 6 of the whole numbers 0 to 20 gives a 15-dollar fare.
example : (List.range 21).filter (fun m => 3 + 2 * m = 15) = [6] := by decide
-- The four mistakes at 6 miles: 5m, 2 + m, 6 + 2m and 3 + 4m.
example : 5 * 6 = 30 := by decide
example : 3 + (2 + 6) = 11 := by decide
example : 6 + 2 * 6 = 18 := by decide
example : 3 + 4 * 6 = 27 := by decide

#print axioms two_fares_collected_equals_bracketed
#print axioms fare_a_mile_at_a_time
#print axioms fare_fifteen_means_six_miles
