-- Commodity swap: the swap is worth nothing exactly at the discount-weighted average of the strip, after a move its mark equals the offsetting-swap value, and on a rising strip that fixed price sits at or below the plain average.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.Order.Chebyshev

open Finset

/-- The fair fixed price. A swap over `n ≥ 1` months on `Q > 0` barrels a month, month `i`
settling at `t i` years with discount factor `D(t i) = e^{−r t i}` and strip price `F i`, is worth
`V = Q · ∑ D(t i) (F i − K)` to the side paying fixed. That value is zero exactly when the fixed
price `K` is the strip averaged with the discount factors as weights:
`K* = (∑ D(t i) F i) / (∑ D(t i))`. No volatility enters. -/
theorem swap_value_zero_iff_fixed_price_eq_discount_weighted_strip
    (n : ℕ) (hn : 0 < n) (Q r : ℝ) (hQ : 0 < Q) (t F : Fin n → ℝ) (K : ℝ) :
    Q * ∑ i, Real.exp (-r * t i) * (F i - K) = 0 ↔
      K = (∑ i, Real.exp (-r * t i) * F i) / ∑ i, Real.exp (-r * t i) := by
  have hA : 0 < ∑ i, Real.exp (-r * t i) := by
    have : Nonempty (Fin n) := ⟨⟨0, hn⟩⟩
    exact Finset.sum_pos (fun i _ => Real.exp_pos _) Finset.univ_nonempty
  have hS : ∑ i, Real.exp (-r * t i) * (F i - K) =
      ∑ i, Real.exp (-r * t i) * F i - K * ∑ i, Real.exp (-r * t i) := by
    simp only [mul_sub, Finset.sum_sub_distrib, Finset.mul_sum]
    congr 1
    exact Finset.sum_congr rfl (fun i _ => by ring)
  rw [hS, mul_eq_zero, eq_div_iff hA.ne']
  constructor
  · rintro (h | h)
    · exact absurd h hQ.ne'
    · linarith
  · intro h
    right
    linarith

/-- The mark after the strip moves. With the contract's fixed price `K` and a new strip `F'`,
the discounted sum of the gaps, `Q · ∑ D(t i) (F' i − K)`, equals the value of entering the
offsetting swap at the new fair price `K' = (∑ D(t i) F' i) / A`: `Q · (K' − K) · A`, where
`A = ∑ D(t i)` is the annuity. -/
theorem swap_mark_eq_offsetting_swap
    (n : ℕ) (Q r K : ℝ) (t F' : Fin n → ℝ) :
    Q * ∑ i, Real.exp (-r * t i) * (F' i - K) =
      Q * ((∑ i, Real.exp (-r * t i) * F' i) / (∑ i, Real.exp (-r * t i)) - K) *
        ∑ i, Real.exp (-r * t i) := by
  have hS : ∑ i, Real.exp (-r * t i) * (F' i - K) =
      ∑ i, Real.exp (-r * t i) * F' i - K * ∑ i, Real.exp (-r * t i) := by
    simp only [mul_sub, Finset.sum_sub_distrib, Finset.mul_sum]
    congr 1
    exact Finset.sum_congr rfl (fun i _ => by ring)
  rw [hS]
  rcases Nat.eq_zero_or_pos n with h0 | hn
  · subst h0
    simp
  · have hA : 0 < ∑ i, Real.exp (-r * t i) := by
      have : Nonempty (Fin n) := ⟨⟨0, hn⟩⟩
      exact Finset.sum_pos (fun i _ => Real.exp_pos _) Finset.univ_nonempty
    have hc : (∑ i, Real.exp (-r * t i) * F' i) / (∑ i, Real.exp (-r * t i)) *
        (∑ i, Real.exp (-r * t i)) = ∑ i, Real.exp (-r * t i) * F' i :=
      div_mul_cancel₀ _ hA.ne'
    linear_combination (-Q) * hc

/-- Contango pulls the fixed price below the plain average. If the strip rises month by month,
the settlement dates come later month by month and the rate is not negative, then the
discount-weighted average of the strip is at most the plain average `(∑ F i) / n`. -/
theorem fair_fixed_price_le_plain_average_of_rising_strip
    (n : ℕ) (hn : 0 < n) (r : ℝ) (hr : 0 ≤ r) (t F : Fin n → ℝ)
    (ht : Monotone t) (hF : Monotone F) :
    (∑ i, Real.exp (-r * t i) * F i) / (∑ i, Real.exp (-r * t i)) ≤ (∑ i, F i) / n := by
  have hA : 0 < ∑ i, Real.exp (-r * t i) := by
    have : Nonempty (Fin n) := ⟨⟨0, hn⟩⟩
    exact Finset.sum_pos (fun i _ => Real.exp_pos _) Finset.univ_nonempty
  have hw : Antitone (fun i => Real.exp (-r * t i)) := by
    intro i j hij
    apply Real.exp_le_exp.mpr
    have := ht hij
    nlinarith
  have key := (hw.antivary hF).card_mul_sum_le_sum_mul_sum
  simp only [Fintype.card_fin] at key
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  rw [div_le_div_iff₀ hA hnR]
  linarith

/-- The card's strip runs from $100 to $104 in eleven equal steps; its plain average is $102. -/
example : (∑ i : Fin 12, ((100 : ℚ) + 4 * (i : ℕ) / 11)) / 12 = 102 := by
  simp [Fin.sum_univ_succ]
  norm_num

/-- Half-way through month 1, 11 of its 22 fixings are left, so 10,000 · 11 / 22 = 5,000
barrels are still exposed to the price; with 22 left all 10,000 are, with 0 left none. -/
example : (10000 : ℚ) * 11 / 22 = 5000 ∧ (10000 : ℚ) * 22 / 22 = 10000 ∧
    (10000 : ℚ) * 0 / 22 = 0 := by
  norm_num

#print axioms swap_value_zero_iff_fixed_price_eq_discount_weighted_strip
#print axioms swap_mark_eq_offsetting_swap
#print axioms fair_fixed_price_le_plain_average_of_rising_strip
