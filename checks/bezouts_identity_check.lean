-- Bezout's identity: for whole numbers a and b, not both 0, every mix a × x + b × y is a multiple of their gcd, the gcd itself is such a mix, a target is reachable exactly when the gcd divides it, and the mixing counts are never unique.
import Mathlib.Data.Int.GCD
import Mathlib.Data.Int.Interval
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Tactic.NormNum.GCD
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination

/-- Bezout's identity. Take two whole numbers a and b, not both 0. Any whole-number mix of them,
a × x + b × y (counts x and y may be negative), lands on a multiple of their gcd, and the gcd
itself is always reachable: some whole-number counts x and y give a × x + b × y = gcd(a, b). -/
theorem gcd_is_a_mix_and_every_mix_is_a_multiple_of_gcd (a b : ℤ) (h : a ≠ 0 ∨ b ≠ 0) :
    (∀ x y : ℤ, (Int.gcd a b : ℤ) ∣ a * x + b * y) ∧
      ∃ x y : ℤ, a * x + b * y = Int.gcd a b := by
  refine ⟨fun x y => ?_, ⟨Int.gcdA a b, Int.gcdB a b, (Int.gcd_eq_gcd_ab a b).symm⟩⟩
  exact dvd_add (Dvd.dvd.mul_right (Int.gcd_dvd_left a b) _) (Dvd.dvd.mul_right (Int.gcd_dvd_right a b) _)

/-- Measuring puzzles: with two whole numbers a and b, not both 0, a target c can be reached by
a whole-number mix a × x + b × y = c exactly when the gcd of a and b divides c. -/
theorem target_is_a_mix_iff_gcd_divides (a b c : ℤ) (h : a ≠ 0 ∨ b ≠ 0) :
    (∃ x y : ℤ, a * x + b * y = c) ↔ (Int.gcd a b : ℤ) ∣ c := by
  constructor
  · rintro ⟨x, y, rfl⟩
    exact dvd_add (Dvd.dvd.mul_right (Int.gcd_dvd_left a b) _) (Dvd.dvd.mul_right (Int.gcd_dvd_right a b) _)
  · rintro ⟨k, rfl⟩
    have := Int.gcd_eq_gcd_ab a b
    refine ⟨Int.gcdA a b * k, Int.gcdB a b * k, ?_⟩
    rw [this]
    ring

/-- There is never just one answer. If counts x and y give a × x + b × y = gcd(a, b), then sliding
x up by k × (b ÷ gcd) and y down by k × (a ÷ gcd) gives the gcd again, for every whole number k;
so infinitely many pairs of counts reach the gcd. -/
theorem bezout_counts_slide_and_are_infinitely_many (a b : ℤ) (h : a ≠ 0 ∨ b ≠ 0) :
    (∀ x y k : ℤ, a * x + b * y = Int.gcd a b →
        a * (x + k * (b / Int.gcd a b)) + b * (y - k * (a / Int.gcd a b)) = Int.gcd a b) ∧
      {p : ℤ × ℤ | a * p.1 + b * p.2 = Int.gcd a b}.Infinite := by
  have hg : (0 : ℤ) < Int.gcd a b := by
    exact_mod_cast Int.gcd_pos_iff.mpr h
  obtain ⟨a', ha⟩ : (Int.gcd a b : ℤ) ∣ a := Int.gcd_dvd_left a b
  obtain ⟨b', hb⟩ : (Int.gcd a b : ℤ) ∣ b := Int.gcd_dvd_right a b
  have hga : a / Int.gcd a b = a' := by
    exact Int.ediv_eq_of_eq_mul_right hg.ne' ha
  have hgb : b / Int.gcd a b = b' := by
    exact Int.ediv_eq_of_eq_mul_right hg.ne' hb
  have key : ∀ x y k : ℤ, a * x + b * y = Int.gcd a b →
      a * (x + k * (b / Int.gcd a b)) + b * (y - k * (a / Int.gcd a b)) = Int.gcd a b := by
    intro x y k hxy
    rw [hga, hgb]
    calc a * (x + k * b') + b * (y - k * a')
        = (a * x + b * y) + k * (a * b' - b * a') := by ring
      _ = _ := by
        have : a * b' - b * a' = 0 := by linear_combination b' * ha - a' * hb
        rw [this, hxy]; ring
  refine ⟨key, ?_⟩
  obtain ⟨x0, y0, h0⟩ := (gcd_is_a_mix_and_every_mix_is_a_multiple_of_gcd a b h).2
  have hne : b' ≠ 0 ∨ a' ≠ 0 := by
    by_contra hc
    rw [not_or, not_not, not_not] at hc
    have h1 : a = 0 := ha.trans (by rw [hc.2, mul_zero])
    have h2 : b = 0 := hb.trans (by rw [hc.1, mul_zero])
    rcases h with h | h
    · exact h h1
    · exact h h2
  refine Set.infinite_of_injective_forall_mem
    (f := fun k : ℤ => ((x0 + k * (b / Int.gcd a b), y0 - k * (a / Int.gcd a b)) : ℤ × ℤ))
    ?_ (fun k => key x0 y0 k h0)
  intro k l hkl
  simp only [Prod.mk.injEq, hga, hgb] at hkl
  obtain ⟨h1, h2⟩ := hkl
  rcases hne with hn | hn
  · have : k * b' = l * b' := by linarith
    exact mul_right_cancel₀ hn this
  · have : k * a' = l * a' := by linarith
    exact mul_right_cancel₀ hn this

-- The card's jugs: 21 and 15 litres, gcd 3.
example : Int.gcd 21 15 = 3 := by norm_num
-- Euclid's chain, down.
example : (21 : ℤ) = 1 * 15 + 6 ∧ (15 : ℤ) = 2 * 6 + 3 ∧ (6 : ℤ) = 2 * 3 + 0 := by decide
-- Walking back up: swap the 6 out, then gather.
example : (15 : ℤ) - 2 * (21 - 1 * 15) = 3 := by decide
example : (21 : ℤ) * (-2) + 15 * 3 = 3 ∧ (21 : ℤ) * (-2) = -42 ∧ (15 : ℤ) * 3 = 45 := by decide
-- Slide one step: 21 × 5 = 15 × 7 = 105, and the new pair 3, -4 also leaves 3.
example : (21 : ℤ) * 5 = 105 ∧ (15 : ℤ) * 7 = 105 := by decide
example : (21 : ℤ) * 3 + 15 * (-4) = 3 ∧ (21 : ℤ) * 3 = 63 ∧ (15 : ℤ) * (-4) = -60 := by decide
-- The three mistakes come out at 87, -27 and 33.
example : (21 : ℤ) * 2 + 15 * 3 = 87 ∧ (15 : ℤ) - 2 * 21 = -27 ∧ (21 : ℤ) * 3 + 15 * (-2) = 33 :=
  by decide
-- The search: counts from -9 to 9 never land on 1 or 2 litres, and 3 is reached.
example : ∀ i ∈ Finset.Icc (-9 : ℤ) 9, ∀ j ∈ Finset.Icc (-9 : ℤ) 9,
    21 * i + 15 * j ≠ 1 ∧ 21 * i + 15 * j ≠ 2 := by decide
-- Pouring in only (counts 0 to 9), the smallest mix above zero is 15, not 3.
example : ∀ i ∈ Finset.range 10, ∀ j ∈ Finset.range 10,
    0 < 21 * i + 15 * j → 15 ≤ 21 * i + 15 * j := by decide
-- Jugs 21 and 14: the gcd becomes 7, and 3 litres is impossible.
example : Int.gcd 21 14 = 7 ∧ ¬ ((7 : ℤ) ∣ 3) := by norm_num
-- 21 and 15 can leave 6 or 9 litres, never 4.
example : (3 : ℤ) ∣ 6 ∧ (3 : ℤ) ∣ 9 ∧ ¬ ((3 : ℤ) ∣ 4) := by decide

#print axioms gcd_is_a_mix_and_every_mix_is_a_multiple_of_gcd
#print axioms target_is_a_mix_iff_gcd_divides
#print axioms bezout_counts_slide_and_are_infinitely_many
