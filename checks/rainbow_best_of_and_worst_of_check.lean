-- Rainbow options: a best-of call and a worst-of call on two shares always add up to two vanilla calls, so whatever one gains when the correlation changes the other loses.
import Mathlib.MeasureTheory.Integral.Bochner.Basic

open MeasureTheory

/-- On every ending, the best-of call payoff plus the worst-of call payoff equals the
payoff of a vanilla call on the first share plus a vanilla call on the second share:
`max(max(S₁,S₂) - K, 0) + max(min(S₁,S₂) - K, 0) = max(S₁ - K, 0) + max(S₂ - K, 0)`. -/
theorem best_of_payoff_add_worst_of_payoff (s₁ s₂ K : ℝ) :
    max (max s₁ s₂ - K) 0 + max (min s₁ s₂ - K) 0 =
      max (s₁ - K) 0 + max (s₂ - K) 0 := by
  rcases le_total s₁ s₂ with h | h
  · rw [max_eq_right h, min_eq_left h, add_comm]
  · rw [max_eq_left h, min_eq_right h]

/-- Prices are discounted averages of payoffs, so the price of the best-of call plus the
price of the worst-of call equals the price of two vanilla calls, one on each share,
whatever the joint law of the two final prices (in particular, whatever the correlation).
Here `μ` is the pricing-world joint law of the two final prices `(S₁_T, S₂_T)`, `K` the
strike, `r` the bank rate and `T` the life of the contract. -/
theorem best_of_price_add_worst_of_price_eq_two_calls
    (μ : Measure (ℝ × ℝ)) [IsProbabilityMeasure μ] (K r T : ℝ)
    (h₁ : Integrable (fun p : ℝ × ℝ => p.1) μ) (h₂ : Integrable (fun p : ℝ × ℝ => p.2) μ) :
    Real.exp (-r * T) * ∫ p, max (max p.1 p.2 - K) 0 ∂μ +
        Real.exp (-r * T) * ∫ p, max (min p.1 p.2 - K) 0 ∂μ =
      Real.exp (-r * T) * ∫ p, max (p.1 - K) 0 ∂μ +
        Real.exp (-r * T) * ∫ p, max (p.2 - K) 0 ∂μ := by
  have hK : Integrable (fun _ : ℝ × ℝ => K) μ := integrable_const K
  have i1 : Integrable (fun p : ℝ × ℝ => max (max p.1 p.2 - K) 0) μ :=
    ((h₁.sup h₂).sub hK).pos_part
  have i2 : Integrable (fun p : ℝ × ℝ => max (min p.1 p.2 - K) 0) μ :=
    ((h₁.inf h₂).sub hK).pos_part
  have i3 : Integrable (fun p : ℝ × ℝ => max (p.1 - K) 0) μ := (h₁.sub hK).pos_part
  have i4 : Integrable (fun p : ℝ × ℝ => max (p.2 - K) 0) μ := (h₂.sub hK).pos_part
  rw [← mul_add, ← mul_add, ← integral_add i1 i2, ← integral_add i3 i4]
  congr 1
  refine integral_congr_ae (Filter.Eventually.of_forall fun p => ?_)
  exact best_of_payoff_add_worst_of_payoff p.1 p.2 K

/-- The correlation sign flip: take two joint laws `μ` and `ν` of the two final prices
with the same law for each share on its own (for instance the same two lognormal shares
at two different correlations). Then whatever the best-of call gains in moving from `ν`
to `μ`, the worst-of call loses exactly that amount. -/
theorem best_of_change_eq_neg_worst_of_change
    (μ ν : Measure (ℝ × ℝ)) [IsProbabilityMeasure μ] [IsProbabilityMeasure ν] (K r T : ℝ)
    (hμ₁ : Integrable (fun p : ℝ × ℝ => p.1) μ) (hμ₂ : Integrable (fun p : ℝ × ℝ => p.2) μ)
    (hν₁ : Integrable (fun p : ℝ × ℝ => p.1) ν) (hν₂ : Integrable (fun p : ℝ × ℝ => p.2) ν)
    (hfst : μ.map Prod.fst = ν.map Prod.fst) (hsnd : μ.map Prod.snd = ν.map Prod.snd) :
    Real.exp (-r * T) * ∫ p, max (max p.1 p.2 - K) 0 ∂μ -
        Real.exp (-r * T) * ∫ p, max (max p.1 p.2 - K) 0 ∂ν =
      -(Real.exp (-r * T) * ∫ p, max (min p.1 p.2 - K) 0 ∂μ -
        Real.exp (-r * T) * ∫ p, max (min p.1 p.2 - K) 0 ∂ν) := by
  have hμ := best_of_price_add_worst_of_price_eq_two_calls μ K r T hμ₁ hμ₂
  have hν := best_of_price_add_worst_of_price_eq_two_calls ν K r T hν₁ hν₂
  have g : Continuous (fun x : ℝ => max (x - K) 0) := by fun_prop
  have e1 : ∫ p, max (p.1 - K) 0 ∂μ = ∫ p, max (p.1 - K) 0 ∂ν := by
    have a := integral_map (μ := μ) measurable_fst.aemeasurable g.aestronglyMeasurable
    have b := integral_map (μ := ν) measurable_fst.aemeasurable g.aestronglyMeasurable
    rw [← a, ← b, hfst]
  have e2 : ∫ p, max (p.2 - K) 0 ∂μ = ∫ p, max (p.2 - K) 0 ∂ν := by
    have a := integral_map (μ := μ) measurable_snd.aemeasurable g.aestronglyMeasurable
    have b := integral_map (μ := ν) measurable_snd.aemeasurable g.aestronglyMeasurable
    rw [← a, ← b, hsnd]
  rw [e1, e2] at hμ
  linarith

-- The card's payoff examples, strike $100.
-- Acme ends at $120, Bolt at $90: the best-of pays $20, the worst-of pays nothing.
example : max (max (120 : ℤ) 90 - 100) 0 = 20 := by decide
example : max (min (120 : ℤ) 90 - 100) 0 = 0 := by decide
-- Bolt ends at $130, Acme at $105: the best-of pays $30.
example : max (max (105 : ℤ) 130 - 100) 0 = 30 := by decide
-- The payoff chart with Bolt at $110: Acme at $80, $105, $130.
example : max (max (80 : ℤ) 110 - 100) 0 = 10 ∧ max (min (80 : ℤ) 110 - 100) 0 = 0 := by decide
example : max (max (105 : ℤ) 110 - 100) 0 = 10 ∧ max (min (105 : ℤ) 110 - 100) 0 = 5 := by decide
example : max (max (130 : ℤ) 110 - 100) 0 = 30 ∧ max (min (130 : ℤ) 110 - 100) 0 = 10 := by decide

#print axioms best_of_payoff_add_worst_of_payoff
#print axioms best_of_price_add_worst_of_price_eq_two_calls
#print axioms best_of_change_eq_neg_worst_of_change
