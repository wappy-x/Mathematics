-- Leland's volatility: the expected cost of one rebalance is the Leland number times the gamma rent, the average size of a standard bell-curve draw is the square root of two over pi, and a target mark above mid fixes exactly one hedging interval.
import Mathlib.Probability.Distributions.Gaussian.Real

open MeasureTheory ProbabilityTheory Real

/-- The Leland number for round-trip cost `k`, volatility `σ` and hedging interval `δt`:
`√(2/π) · k / (σ √δt)`. -/
noncomputable def lelandNumber (k σ δt : ℝ) : ℝ := √(2 / π) * k / (σ * √δt)

/-- Helper: `∫₀^∞ x e^{-x²/2} dx = 1`. -/
theorem integral_Ioi_mul_exp_neg_half_sq :
    ∫ x in Set.Ioi (0 : ℝ), x * rexp (-(1 / 2) * x ^ 2) = 1 := by
  have hd : ∀ x ∈ Set.Ici (0 : ℝ),
      HasDerivAt (fun y : ℝ => -rexp (-(1 / 2) * y ^ 2)) (x * rexp (-(1 / 2) * x ^ 2)) x := by
    intro x _
    have := (((hasDerivAt_pow 2 x).const_mul (-(1 / 2 : ℝ))).exp).neg
    convert this using 1
    simp only [Nat.cast_ofNat]
    ring
  have hint : MeasureTheory.IntegrableOn (fun x : ℝ => x * rexp (-(1 / 2) * x ^ 2)) (Set.Ioi 0) :=
    (integrable_mul_exp_neg_mul_sq (by norm_num : (0 : ℝ) < 1 / 2)).integrableOn
  have hlim : Filter.Tendsto (fun y : ℝ => -rexp (-(1 / 2) * y ^ 2)) Filter.atTop (nhds (-0)) := by
    refine Filter.Tendsto.neg ?_
    exact tendsto_exp_atBot.comp
      ((Filter.tendsto_pow_atTop two_ne_zero).const_mul_atTop_of_neg (by norm_num))
  rw [integral_Ioi_of_hasDerivAt_of_tendsto' hd hint hlim]
  simp

#print axioms integral_Ioi_mul_exp_neg_half_sq

/-- Helper: `E|Z| = √(2/π)` (same as `integral_abs_standard_gaussian`, proved first so the main
theorem can use it). -/
theorem integral_abs_std_gaussian_aux :
    ∫ z, |z| ∂(gaussianReal 0 1) = √(2 / π) := by
  rw [integral_gaussianReal_eq_integral_smul (by norm_num)]
  have hfun : (fun x : ℝ => gaussianPDFReal 0 1 x • |x|)
      = fun x => (fun y : ℝ => (√(2 * π))⁻¹ * (y * rexp (-(1 / 2) * y ^ 2))) |x| := by
    funext x
    simp only [gaussianPDFReal, smul_eq_mul, sq_abs, NNReal.coe_one, mul_one, sub_zero]
    have : -x ^ 2 / 2 = -(1 / 2) * x ^ 2 := by ring
    rw [this]; ring
  rw [hfun, integral_comp_abs (f := fun y : ℝ => (√(2 * π))⁻¹ * (y * rexp (-(1 / 2) * y ^ 2))),
    integral_const_mul, integral_Ioi_mul_exp_neg_half_sq]
  have hpi : 0 < π := Real.pi_pos
  rw [Real.sqrt_div (by norm_num : (0 : ℝ) ≤ 2), Real.sqrt_mul (by norm_num : (0 : ℝ) ≤ 2)]
  have h2 : √(2 : ℝ) * √2 = 2 := Real.mul_self_sqrt (by norm_num)
  have hs2 : 0 < √(2 : ℝ) := by positivity
  have hsp : 0 < √π := Real.sqrt_pos.mpr hpi
  field_simp
  linarith [h2]

#print axioms integral_abs_std_gaussian_aux

/-- The card's main step (Step 3): over one interval the share moves by `σ S √δt Z` with `Z` a
standard bell-curve draw, and the hedge trades `Γ |δS|` shares at `k/2` of their price `S`.
The expected cost of that rebalance is exactly the gamma rent `½ Γ S² σ² δt` times the
Leland number `√(2/π) k / (σ √δt)`. -/
theorem expected_rebalance_cost_eq_leland_number_mul_gamma_rent
    (k S Γ σ δt : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hδt : 0 < δt) :
    k / 2 * S * Γ * ∫ z, |σ * S * √δt * z| ∂(gaussianReal 0 1)
      = (1 / 2 * Γ * S ^ 2 * σ ^ 2 * δt) * lelandNumber k σ δt := by
  have hsd : 0 < √δt := Real.sqrt_pos.mpr hδt
  have habs : (fun z : ℝ => |σ * S * √δt * z|) = fun z => (σ * S * √δt) * |z| := by
    funext z
    rw [abs_mul, abs_of_pos (by positivity : 0 < σ * S * √δt)]
  rw [habs, integral_const_mul, integral_abs_std_gaussian_aux]
  unfold lelandNumber
  field_simp
  rw [Real.sq_sqrt hδt.le]

/-- Step 2's fact: the average size of a standard bell-curve draw, ignoring its sign,
is `E|Z| = √(2/π)`. -/
theorem integral_abs_standard_gaussian :
    ∫ z, |z| ∂(gaussianReal 0 1) = √(2 / π) := by
  exact integral_abs_std_gaussian_aux

/-- The inverse (Step 6): for a positive cost and a target mark `σ*` above the mid volatility
`σ`, the seller's mark `σ √(1 + Le)` equals `σ*` at exactly one hedging interval,
`δt* = (√(2/π) k / (σ Le*))²` with `Le* = (σ*/σ)² - 1`. -/
theorem leland_mark_eq_target_iff_interval
    (k σ σstar : ℝ) (hk : 0 < k) (hσ : 0 < σ) (htarget : σ < σstar) (δt : ℝ) (hδt : 0 < δt) :
    σ * √(1 + lelandNumber k σ δt) = σstar ↔
      δt = (√(2 / π) * k / (σ * ((σstar / σ) ^ 2 - 1))) ^ 2 := by
  have hsd : 0 < √δt := Real.sqrt_pos.mpr hδt
  have hc : 0 < √(2 / π) := Real.sqrt_pos.mpr (by positivity)
  have hr : 1 < σstar / σ := (one_lt_div hσ).mpr htarget
  have hL : 0 < (σstar / σ) ^ 2 - 1 := by nlinarith
  have hLe : lelandNumber k σ δt = √(2 / π) * k / (σ * √δt) := rfl
  constructor
  · intro h
    have h1 : √(1 + lelandNumber k σ δt) = σstar / σ := by
      field_simp; linarith
    have hLe0 : 0 < lelandNumber k σ δt := by rw [hLe]; positivity
    have h2 : 1 + lelandNumber k σ δt = (σstar / σ) ^ 2 := by
      rw [← h1, Real.sq_sqrt (by linarith)]
    have h3 : √(2 / π) * k / (σ * √δt) = (σstar / σ) ^ 2 - 1 := by
      rw [← hLe]; linarith
    have h4 : √δt = √(2 / π) * k / (σ * ((σstar / σ) ^ 2 - 1)) := by
      rw [← h3]; field_simp
    rw [← h4, Real.sq_sqrt hδt.le]
  · intro h
    have h4 : √δt = √(2 / π) * k / (σ * ((σstar / σ) ^ 2 - 1)) := by
      rw [h, Real.sqrt_sq (by positivity)]
    have h3 : lelandNumber k σ δt = (σstar / σ) ^ 2 - 1 := by
      rw [hLe, h4]; field_simp
    rw [h3, add_sub_cancel, Real.sqrt_sq (by positivity)]
    field_simp

/-- The card's target: a 21% mark over a 20% mid gives `Le* = (21/20)² - 1 = 0.1025`. -/
example : ((21 : ℚ) / 20) ^ 2 - 1 = 41 / 400 := by norm_num

#print axioms expected_rebalance_cost_eq_leland_number_mul_gamma_rent
#print axioms integral_abs_standard_gaussian
#print axioms leland_mark_eq_target_iff_interval
