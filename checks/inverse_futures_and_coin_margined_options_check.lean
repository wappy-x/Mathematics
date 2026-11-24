-- Inverse contracts: the coin value Q/P of a fixed dollar amount is strictly convex in the bitcoin price, the coin gain is linear once counted in dollars, and the two averages of 1/S_T are exp(σ²T)/F and 1/F.
import Mathlib.Analysis.Convex.SpecificFunctions.Deriv
import Mathlib.Probability.Distributions.Gaussian.Real

open MeasureTheory ProbabilityTheory

/-- Helper: the standard bell-curve average of `exp (c z)` is `exp (c² / 2)`. -/
theorem gauss_exp_integral (c : ℝ) :
    (∫ z, Real.exp (c * z) ∂(gaussianReal 0 1)) = Real.exp (c ^ 2 / 2) := by
  have h := congrFun (mgf_id_gaussianReal (μ := 0) (v := 1)) c
  simp only [mgf, id] at h
  rw [h]
  congr 1
  push_cast
  ring

#print axioms gauss_exp_integral

/-- An inverse contract is a fixed number of dollars `Q > 0` counted in coins. At a bitcoin
price `P > 0` it is worth `Q / P` coins, and that coin value is strictly convex in the price.
So the long's coin gain `Q / F₀ - Q / F₁` is strictly concave in the closing price `F₁`:
it gains fewer coins on a rise than it loses on an equal fall. -/
theorem inverse_contract_coin_value_strictly_convex (Q : ℝ) (hQ : 0 < Q) :
    StrictConvexOn ℝ (Set.Ioi 0) (fun P : ℝ => Q / P) ∧
      ∀ F₀ : ℝ, StrictConcaveOn ℝ (Set.Ioi 0) (fun F₁ : ℝ => Q / F₀ - Q / F₁) := by
  have hc : StrictConvexOn ℝ (Set.Ioi 0) (fun P : ℝ => Q / P) := by
    have h := strictConvexOn_zpow (m := -1) (by decide) (by decide)
    refine ⟨h.1, fun x hx y hy hxy a b ha hb hab => ?_⟩
    have := h.2 hx hy hxy ha hb hab
    simp only [zpow_neg, zpow_one, smul_eq_mul] at this ⊢
    simp only [div_eq_mul_inv]
    nlinarith [mul_lt_mul_of_pos_left this hQ]
  refine ⟨hc, fun F₀ => ?_⟩
  have h2 : StrictConcaveOn ℝ (Set.Ioi 0) (-(fun P : ℝ => Q / P)) := hc.neg
  have h3 := h2.add_const (Q / F₀)
  convert h3 using 1
  funext x
  simp only [Pi.neg_apply, Pi.add_apply]
  ring

/-- Counted in dollars at the closing price, the long's coin gain is the straight line
`Q (F₁ / F₀ - 1)`. And the coin-settled call's coin payoff `(S_T - K)^+ / S_T`, converted to
dollars at `S_T`, is the ordinary call payoff `(S_T - K)^+`. -/
theorem inverse_gain_in_dollars_is_linear (Q F₀ F₁ S_T K : ℝ) (h₀ : 0 < F₀) (h₁ : 0 < F₁)
    (hS : 0 < S_T) :
    (Q / F₀ - Q / F₁) * F₁ = Q * (F₁ / F₀ - 1) ∧
      max (S_T - K) 0 / S_T * S_T = max (S_T - K) 0 := by
  refine ⟨?_, ?_⟩
  · field_simp
  · field_simp

/-- The two averages of `1 / S_T` when bitcoin's log price has one steady volatility `σ`
and rates are constant. With `Z` a standard bell-curve draw, the dollar world has
`S_T = S exp((r_d - r_f - σ²/2) T + σ √T Z)` and the coin world has drift
`r_d - r_f + σ²/2`. With the forward `F = S exp((r_d - r_f) T)`:
the dollar-world average of `1 / S_T` is `exp(σ² T) / F` (Jensen's gap),
and the coin-world average is exactly `1 / F`. -/
theorem average_of_inverse_price_dollar_and_coin_world (S σ T r_d r_f : ℝ) (hS : 0 < S)
    (hσ : 0 < σ) (hT : 0 < T) :
    (∫ z, (S * Real.exp ((r_d - r_f - σ ^ 2 / 2) * T + σ * Real.sqrt T * z))⁻¹
        ∂(gaussianReal 0 1)) = Real.exp (σ ^ 2 * T) / (S * Real.exp ((r_d - r_f) * T)) ∧
      (∫ z, (S * Real.exp ((r_d - r_f + σ ^ 2 / 2) * T + σ * Real.sqrt T * z))⁻¹
        ∂(gaussianReal 0 1)) = 1 / (S * Real.exp ((r_d - r_f) * T)) := by
  have key : ∀ a : ℝ, (∫ z, (S * Real.exp (a + σ * Real.sqrt T * z))⁻¹ ∂(gaussianReal 0 1))
      = S⁻¹ * Real.exp (-a) * Real.exp ((σ * Real.sqrt T) ^ 2 / 2) := by
    intro a
    have hf : (fun z => (S * Real.exp (a + σ * Real.sqrt T * z))⁻¹)
        = fun z => S⁻¹ * Real.exp (-a) * Real.exp ((-(σ * Real.sqrt T)) * z) := by
      funext z
      rw [mul_inv, ← Real.exp_neg, mul_assoc S⁻¹ (Real.exp (-a)), ← Real.exp_add]
      congr 2
      ring
    rw [hf, integral_const_mul, gauss_exp_integral, neg_sq]
  have hsq : (σ * Real.sqrt T) ^ 2 = σ ^ 2 * T := by
    rw [mul_pow, Real.sq_sqrt hT.le]
  have hr : ∀ u v : ℝ, Real.exp u / (S * Real.exp v) = S⁻¹ * Real.exp (u - v) := by
    intro u v
    rw [Real.exp_sub]
    field_simp
  refine ⟨?_, ?_⟩
  · rw [key, hsq, hr, mul_assoc, ← Real.exp_add]
    congr 2
    ring
  · rw [key, hsq, ← Real.exp_zero, hr, mul_assoc, ← Real.exp_add]
    congr 2
    ring

-- The card's whole-number examples: 100 USD a contract, bought at 60,000.
-- Up to 61,000: the long gains exactly 1/36,600 BTC.
example : (100 : ℚ) / 60000 - 100 / 61000 = 1 / 36600 := by norm_num
-- Its dollar value at 61,000 is 100 × (61,000/60,000 − 1) = 5/3 USD.
example : ((100 : ℚ) / 60000 - 100 / 61000) * 61000 = 100 * (61000 / 60000 - 1) := by norm_num
example : (100 : ℚ) * (61000 / 60000 - 1) = 5 / 3 := by norm_num
-- Down to 59,000: the long loses exactly 1/35,400 BTC.
example : (100 : ℚ) / 60000 - 100 / 59000 = -1 / 35400 := by norm_num
-- An equal move up and down nets a coin loss for the long.
example : ((100 : ℚ) / 60000 - 100 / 61000) + (100 / 60000 - 100 / 59000) < 0 := by norm_num
-- The straight-line guess 100 × 1,000 / 60,000² = 1/36,000 BTC sits between the two.
example : (1 : ℚ) / 36600 < 100 * 1000 / 60000 ^ 2 ∧
    (100 : ℚ) * 1000 / 60000 ^ 2 < 1 / 35400 := by norm_num
-- Synthetic dollar: 1 BTC and short 600 contracts at 60,000 hold 60,000/F₁ coins.
example : (1 : ℚ) - 600 * (100 / 60000 - 100 / 40000) = 3 / 2 := by norm_num
example : (1 : ℚ) - 600 * (100 / 60000 - 100 / 80000) = 3 / 4 := by norm_num
example : ((1 : ℚ) - 600 * (100 / 60000 - 100 / 40000)) * 40000 = 60000 := by norm_num
example : ((1 : ℚ) - 600 * (100 / 60000 - 100 / 80000)) * 80000 = 60000 := by norm_num

#print axioms inverse_contract_coin_value_strictly_convex
#print axioms inverse_gain_in_dollars_is_linear
#print axioms average_of_inverse_price_dollar_and_coin_world
