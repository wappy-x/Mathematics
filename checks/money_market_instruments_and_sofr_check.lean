-- Money markets: a bill's discount quote converts exactly to the return on its cash, price and quote and return each fix the others, and compounding positive overnight rates beats averaging them.
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Real.Basic
import Mathlib.Order.Monotone.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Algebra.BigOperators.Field

open Finset

/-- For nonnegative terms, `1 + ∑ a ≤ ∏ (1 + a)`. -/
theorem mm_one_add_sum_le_prod (m : ℕ) (a : Fin m → ℝ) (ha : ∀ j, 0 ≤ a j) :
    1 + ∑ j, a j ≤ ∏ j, (1 + a j) := by
  induction m with
  | zero => simp
  | succ k ih =>
    rw [Fin.sum_univ_succ, Fin.prod_univ_succ]
    have h1 := ih (fun j => a j.succ) (fun j => ha _)
    have h0 := ha 0
    have hs : 0 ≤ ∑ j : Fin k, a j.succ := Finset.sum_nonneg (fun j _ => ha _)
    nlinarith

/-- For at least two positive terms, `1 + ∑ a < ∏ (1 + a)`. -/
theorem mm_one_add_sum_lt_prod (m : ℕ) (hm : 2 ≤ m) (a : Fin m → ℝ) (ha : ∀ j, 0 < a j) :
    1 + ∑ j, a j < ∏ j, (1 + a j) := by
  obtain ⟨k, rfl⟩ : ∃ k, m = k + 2 := ⟨m - 2, by omega⟩
  rw [Fin.sum_univ_succ, Fin.prod_univ_succ]
  have h1 := mm_one_add_sum_le_prod (k + 1) (fun j => a j.succ) (fun j => (ha _).le)
  have h0 := ha 0
  have hs : 0 < ∑ j : Fin (k + 1), a j.succ :=
    Finset.sum_pos (fun j _ => ha _) Finset.univ_nonempty
  nlinarith

/-- A bill with face value `F > 0`, `n > 0` days left and discount quote `d` with `d·n/360 < 1`
is priced at `P = F(1 - d·n/360)`. Its return on the cash, `i = (F - P)/P · 360/n`, equals
`d / (1 - d·n/360)`, and the gap over the quote is the squared term
`i - d = d²·(n/360) / (1 - d·n/360)`: zero when the quote is zero, and the return is strictly
above the quote otherwise. -/
theorem money_market_yield_of_discount_quote (F d : ℝ) (n : ℕ) (hF : 0 < F) (hn : 0 < n)
    (hd : d * n / 360 < 1) :
    let P := F * (1 - d * n / 360)
    let i := (F - P) / P * (360 / n)
    i = d / (1 - d * n / 360) ∧
    i - d = d ^ 2 * (n / 360) / (1 - d * n / 360) ∧
    (d = 0 → i = d) ∧
    (d ≠ 0 → d < i) := by
  intro P i
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hk : 0 < 1 - d * n / 360 := by linarith
  have hP : P = F * (1 - d * n / 360) := rfl
  have hi1 : i = d / (1 - d * n / 360) := by
    show (F - F * (1 - d * n / 360)) / (F * (1 - d * n / 360)) * (360 / n) = _
    field_simp
    ring
  have hi2 : i - d = d ^ 2 * (n / 360) / (1 - d * n / 360) := by
    have hk0 : (1 - d * n / 360) ≠ 0 := hk.ne'
    rw [hi1, eq_div_iff hk0, sub_mul, div_mul_cancel₀ _ hk0]
    ring
  refine ⟨hi1, hi2, ?_, ?_⟩
  · intro h0; rw [hi1, h0]; simp
  · intro h0
    have : 0 < d ^ 2 * (n / 360) / (1 - d * n / 360) := by
      have : 0 < d ^ 2 := by positivity
      positivity
    linarith

/-- For a face value `F > 0` and `n > 0` days, the price and the quote determine each other
exactly: the price `F(1 - d·n/360)` is strictly decreasing in the quote, it is positive exactly
when `d·n/360 < 1`, every positive price comes from exactly one such quote, and that quote is
`d = (1 - P/F)·360/n`. On the other side, the return `(F/P - 1)·360/n` is strictly decreasing on
positive prices and stays above `-360/n`, each return above `-360/n` comes from exactly one
positive price, and that price is `P = F / (1 + i·n/360)`. -/
theorem price_quote_and_return_determine_each_other (F : ℝ) (n : ℕ) (hF : 0 < F) (hn : 0 < n) :
    StrictAnti (fun d : ℝ => F * (1 - d * n / 360)) ∧
    (∀ d : ℝ, 0 < F * (1 - d * n / 360) ↔ d * n / 360 < 1) ∧
    (∀ P : ℝ, 0 < P → ∃! d : ℝ, d * n / 360 < 1 ∧ F * (1 - d * n / 360) = P) ∧
    (∀ d P : ℝ, F * (1 - d * n / 360) = P ↔ d = (1 - P / F) * (360 / n)) ∧
    StrictAntiOn (fun P : ℝ => (F / P - 1) * (360 / n)) (Set.Ioi 0) ∧
    (∀ P : ℝ, 0 < P → -(360 / (n : ℝ)) < (F / P - 1) * (360 / n)) ∧
    (∀ i : ℝ, -(360 / (n : ℝ)) < i → ∃! P : ℝ, 0 < P ∧ (F / P - 1) * (360 / n) = i) ∧
    (∀ i P : ℝ, -(360 / (n : ℝ)) < i → 0 < P →
      ((F / P - 1) * (360 / n) = i ↔ P = F / (1 + i * n / 360))) := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hn0 : (n : ℝ) ≠ 0 := hn'.ne'
  have hF0 : F ≠ 0 := hF.ne'
  have hd : ∀ d P : ℝ, F * (1 - d * n / 360) = P ↔ d = (1 - P / F) * (360 / n) := by
    intro d P
    constructor
    · intro h; subst h; field_simp; ring
    · intro h; subst h; field_simp; ring
  have hpos : ∀ d : ℝ, 0 < F * (1 - d * n / 360) ↔ d * n / 360 < 1 := by
    intro d
    constructor
    · intro h
      by_contra hc
      push Not at hc
      nlinarith
    · intro h
      have : 0 < 1 - d * n / 360 := by linarith
      positivity
  have hkpos : ∀ i : ℝ, -(360 / (n : ℝ)) < i → 0 < 1 + i * n / 360 := by
    intro i hi
    have h360 : (360 / (n : ℝ)) * n = 360 := div_mul_cancel₀ _ hn0
    have : -(360 / (n : ℝ)) * n < i * n := mul_lt_mul_of_pos_right hi hn'
    nlinarith
  have hret : ∀ i P : ℝ, -(360 / (n : ℝ)) < i → 0 < P →
      ((F / P - 1) * (360 / n) = i ↔ P = F / (1 + i * n / 360)) := by
    intro i P hi hP
    have hk := hkpos i hi
    have hP0 : P ≠ 0 := hP.ne'
    constructor
    · intro h
      subst h
      have h1 : 1 + (F / P - 1) * (360 / n) * n / 360 = F / P := by
        field_simp
        ring
      rw [h1]
      field_simp
    · intro h
      subst h
      field_simp
      ring
  refine ⟨?_, hpos, ?_, hd, ?_, ?_, ?_, hret⟩
  · intro a b hab
    have : a * n < b * n := mul_lt_mul_of_pos_right hab hn'
    show F * (1 - b * n / 360) < F * (1 - a * n / 360)
    nlinarith
  · intro P hP
    refine ⟨(1 - P / F) * (360 / n), ⟨?_, ?_⟩, ?_⟩
    · rw [← hpos, (hd _ P).mpr rfl]; exact hP
    · exact (hd _ P).mpr rfl
    · rintro y ⟨_, hy⟩
      exact (hd y P).mp hy
  · intro a ha b hb hab
    have ha' : (0 : ℝ) < a := ha
    have hb' : (0 : ℝ) < b := hb
    have h1 : F / b < F / a := div_lt_div_of_pos_left hF ha' hab
    have h2 : 0 < 360 / (n : ℝ) := by positivity
    show (F / b - 1) * (360 / n) < (F / a - 1) * (360 / n)
    nlinarith
  · intro P hP
    have h1 : 0 < F / P := by positivity
    have h2 : 0 < 360 / (n : ℝ) := by positivity
    nlinarith
  · intro i hi
    have hk := hkpos i hi
    refine ⟨F / (1 + i * n / 360), ⟨by positivity, ?_⟩, ?_⟩
    · exact (hret i _ hi (by positivity)).mpr rfl
    · rintro y ⟨hy0, hy⟩
      exact (hret i y hi hy0).mp hy

/-- Compounding is not averaging: for `m ≥ 2` blocks with positive overnight rates `r j` and
positive day counts `n j`, the compounded-in-arrears rate `(G - 1)·360/n`, where
`G = ∏ (1 + r j · n j / 360)` and `n = ∑ n j`, is strictly larger than the day-weighted average
rate `(∑ r j · n j) / n`. -/
theorem compounded_in_arrears_rate_exceeds_average_rate (m : ℕ) (hm : 2 ≤ m)
    (r : Fin m → ℝ) (nb : Fin m → ℕ) (hr : ∀ j, 0 < r j) (hnb : ∀ j, 0 < nb j) :
    let n : ℝ := ∑ j, (nb j : ℝ)
    let G : ℝ := ∏ j, (1 + r j * nb j / 360)
    (∑ j, r j * nb j) / n < (G - 1) * (360 / n) := by
  intro n G
  have hn : 0 < n := by
    have : (0 : ℝ) < (nb ⟨0, by omega⟩ : ℝ) := by exact_mod_cast hnb _
    exact Finset.sum_pos (fun j _ => by exact_mod_cast hnb j)
      ⟨⟨0, by omega⟩, Finset.mem_univ _⟩
  have hlt := mm_one_add_sum_lt_prod m hm (fun j => r j * nb j / 360)
    (fun j => by
      have := hr j
      have : (0 : ℝ) < nb j := by exact_mod_cast hnb j
      positivity)
  have hsum : ∑ j, r j * (nb j : ℝ) / 360 = (∑ j, r j * nb j) / 360 := by
    rw [Finset.sum_div]
  rw [hsum] at hlt
  have hG : (∑ j, r j * (nb j : ℝ)) / 360 < G - 1 := by
    show _ < (∏ j, (1 + r j * nb j / 360)) - 1
    linarith
  have h2 : 0 < 360 / n := by positivity
  calc (∑ j, r j * nb j) / n = (∑ j, r j * (nb j : ℝ)) / 360 * (360 / n) := by
        field_simp
    _ < (G - 1) * (360 / n) := mul_lt_mul_of_pos_right hG h2

-- The card's bill: face 1,000,000, 91 days, quote 4.90% = 49/1000.
-- The discount is 1,000,000 × 0.049 × 91/360 = 111475/9 dollars (12,386.11 to the cent).
example : (1000000 : ℚ) * (49 / 1000) * (91 / 360) = 111475 / 9 := by norm_num

-- The price before rounding, times 36, is the whole number 35,554,100.
example : (1000000 : ℚ) * (1 - 49 / 1000 * 91 / 360) * 36 = 35554100 := by norm_num

-- The return on the cash is exactly 17640/355541, which rounds to 4.9615%.
example : ((1000000 : ℚ) - 1000000 * (1 - 49 / 1000 * 91 / 360)) /
    (1000000 * (1 - 49 / 1000 * 91 / 360)) * (360 / 91) = 17640 / 355541 := by norm_num

example : (496145 : ℚ) / 10000000 ≤ 17640 / 355541 ∧ (17640 : ℚ) / 355541 < 496155 / 10000000 := by
  norm_num

-- At 91 days the price stays positive for quotes under 360/91, about 395.6% a year.
example : (3956 : ℚ) / 1000 < 360 / 91 ∧ (360 : ℚ) / 91 < 3957 / 1000 := by norm_num

-- The overnight path: 52 one-day blocks and 13 three-day weekend blocks, 65 blocks, 91 days.
example : 52 + 13 = 65 ∧ 52 * 1 + 13 * 3 = 91 := by decide

#print axioms mm_one_add_sum_le_prod
#print axioms mm_one_add_sum_lt_prod
#print axioms money_market_yield_of_discount_quote
#print axioms price_quote_and_return_determine_each_other
#print axioms compounded_in_arrears_rate_exceeds_average_rate
