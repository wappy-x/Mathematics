-- Expected utility: a score for positive wealth bends down exactly when every gamble's average score is at most the score of its average wealth, the Arrow-Pratt ratio -u''/u' ignores rescaling and shifting the score, and power utility has relative risk aversion gamma at every wealth.
import Mathlib.Analysis.Convex.Jensen
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

open Finset

/-- Risk aversion is a downward bend: a score `u` for positive wealth is concave exactly when,
for every gamble on finitely many positive wealth levels `w i` with probabilities `p i`,
the average score is at most the score of the average wealth, `E[u(W)] ≤ u(E[W])`. -/
theorem concave_iff_risk_averse (u : ℝ → ℝ) :
    ConcaveOn ℝ (Set.Ioi 0) u ↔
      ∀ (n : ℕ) (p w : Fin n → ℝ), (∀ i, 0 ≤ p i) → ∑ i, p i = 1 → (∀ i, 0 < w i) →
        ∑ i, p i * u (w i) ≤ u (∑ i, p i * w i) := by
  constructor
  · intro h n p w hp hs hw
    have := h.le_map_sum (t := Finset.univ) (w := p) (p := w) (fun i _ => hp i) hs
      (fun i _ => hw i)
    simpa [smul_eq_mul] using this
  · intro h
    refine ⟨convex_Ioi 0, ?_⟩
    intro x hx y hy a b ha hb hab
    have := h 2 ![a, b] ![x, y] (fun i => by fin_cases i <;> simp [ha, hb])
      (by simp [Fin.sum_univ_two, hab])
      (fun i => by fin_cases i <;> simpa using (by assumption))
    simpa [Fin.sum_univ_two, smul_eq_mul] using this

/-- Measure the bend against the slope and the scale drops out: rescaling the score to
`a * u + b` with `a > 0` leaves the Arrow-Pratt coefficient `A(w) = -u''(w) / u'(w)` unchanged. -/
theorem arrow_pratt_invariant_under_rescaling (u : ℝ → ℝ) (a b w : ℝ) (ha : 0 < a) :
    -deriv (deriv fun x => a * u x + b) w / deriv (fun x => a * u x + b) w =
      -deriv (deriv u) w / deriv u w := by
  have h1 : (deriv fun x => a * u x + b) = fun x => a * deriv u x := by
    funext x
    rw [deriv_add_const, deriv_const_mul_field']
  have h2 : deriv (deriv fun x => a * u x + b) w = a * deriv (deriv u) w := by
    rw [h1, deriv_const_mul_field']
  rw [h2, h1]
  have ha' : a ≠ 0 := ha.ne'
  rw [neg_div, neg_div, mul_div_mul_left _ _ ha']

/-- Power utility has constant relative risk aversion: for `u(w) = w^(1-γ)/(1-γ)` with `γ ≠ 1`,
and for `u(w) = ln w` (the case `γ = 1`), `ρ(w) = w · (-u''(w)/u'(w))` equals `γ` at every
positive wealth `w`. -/
theorem power_utility_relative_risk_aversion (γ w : ℝ) (hw : 0 < w) :
    (γ ≠ 1 →
      w * (-deriv (deriv fun x : ℝ => x ^ (1 - γ) / (1 - γ)) w /
        deriv (fun x : ℝ => x ^ (1 - γ) / (1 - γ)) w) = γ) ∧
    w * (-deriv (deriv Real.log) w / deriv Real.log w) = 1 := by
  constructor
  · intro hγ
    have hγ' : (1 - γ) ≠ 0 := sub_ne_zero.mpr (Ne.symm hγ)
    have h1 : (deriv fun x : ℝ => x ^ (1 - γ) / (1 - γ)) = fun x => x ^ (-γ) := by
      funext x
      rw [deriv_div_const, Real.deriv_rpow_const]
      rw [mul_div_cancel_left₀ _ hγ']
      congr 1
      ring
    rw [h1, Real.deriv_rpow_const]
    have : w ^ (-γ - 1) = w ^ (-γ) / w := Real.rpow_sub_one hw.ne' _
    rw [this]
    have hp : 0 < w ^ (-γ) := Real.rpow_pos_of_pos hw _
    field_simp
  · rw [Real.deriv_log', deriv_inv']
    field_simp

-- The fund's average wealth: ½ × 12,300 + ½ × 9,300 = 10,800.
example : (1 / 2 : ℚ) * 12300 + 1 / 2 * 9300 = 10800 := by norm_num
-- Its variance: ½ × 1,500² + ½ × 1,500² = 2,250,000 dollars squared.
example : (1 / 2 : ℚ) * (12300 - 10800) ^ 2 + 1 / 2 * (9300 - 10800) ^ 2 = 2250000 := by norm_num
-- The log saver takes the fund: √(12,300 × 9,300) > 10,400, that is 12,300 × 9,300 > 10,400².
example : (10400 : ℕ) ^ 2 < 12300 * 9300 := by norm_num
-- γ = 2: the certainty equivalent is the harmonic mean, 2 / (1/12,300 + 1/9,300) = 10,591.67 (= 31,775/3).
example : (2 : ℚ) / (1 / 12300 + 1 / 9300) = 31775 / 3 := by norm_num
-- γ = 5 takes the deposit: (½ × 12,300^−4 + ½ × 9,300^−4)^(−1/4) < 10,400,
-- that is ½ × 12,300^−4 + ½ × 9,300^−4 > 10,400^−4.
example : (1 : ℚ) / 10400 ^ 4 < 1 / 2 * (1 / 12300 ^ 4) + 1 / 2 * (1 / 9300 ^ 4) := by norm_num
-- Pratt's rule for the log saver: ½ × (1/10,800) × 2,250,000 = 104.17 (= 625/6).
example : (1 / 2 : ℚ) * (1 / 10800) * 2250000 = 625 / 6 := by norm_num
-- Pratt's break-even γ: the $400 edge over 104.17 per unit of γ is 3.84.
example : ((10800 - 10400 : ℚ)) / (625 / 6) = 384 / 100 := by norm_num
-- The mistake of using γ = 1 as A: ½ × 1 × 2,250,000 = 1,125,000.
example : (1 / 2 : ℚ) * 1 * 2250000 = 1125000 := by norm_num

#print axioms concave_iff_risk_averse
#print axioms arrow_pratt_invariant_under_rescaling
#print axioms power_utility_relative_risk_aversion
