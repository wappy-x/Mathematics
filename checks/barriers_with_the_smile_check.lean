-- Barriers on a smile: the reflection survival chance lies between 0 and 1, so the survival-weighted vanna-volga price lies between the flat price and the unweighted vanna-volga price; the overlay reprices its own pillar; and the Brownian-bridge crossing chance has the card's closed form.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse

open ProbabilityTheory Real Matrix

/-- The bell-curve area to the left of a point: the standard normal distribution function. -/
noncomputable def stdNormalCdf (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The card's survival chance: the chance in the pricing world that spot `S` never trades at the
wall `H` before `T`, with `μ = r_d - r_f - σ²/2`, by the reflection formula. -/
noncomputable def pSurv (S H rd rf σ T : ℝ) : ℝ :=
  let μ := rd - rf - σ ^ 2 / 2
  stdNormalCdf ((Real.log (H / S) - μ * T) / (σ * Real.sqrt T))
    - (H / S) ^ (2 * μ / σ ^ 2) * stdNormalCdf ((-Real.log (H / S) - μ * T) / (σ * Real.sqrt T))

/-- The vanna-volga overlay: hedge weights `x i` times each pillar's market price minus its flat price. -/
def vvOverlay (x Cmkt Cflat : Fin 3 → ℝ) : ℝ := ∑ i, x i * (Cmkt i - Cflat i)

/-- The card's recipe: `V_VV = V_flat + p_surv * Σ x_i (C_i^mkt - C_i^flat)`. -/
noncomputable def vvSurvPrice (Vflat S H rd rf σ T : ℝ) (x Cmkt Cflat : Fin 3 → ℝ) : ℝ :=
  Vflat + pSurv S H rd rf σ T * vvOverlay x Cmkt Cflat

open MeasureTheory in
/-- A normal distribution function with mean `c` and unit variance, as an integral of its density. -/
lemma gaussian_cdf_eq_integral (c a : ℝ) :
    cdf (gaussianReal c 1) a = ∫ x in Set.Iic a, gaussianPDFReal c 1 x := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun x _ => gaussianPDFReal_nonneg _ _ x)

open MeasureTheory in
/-- Shifting the argument of the standard normal distribution function is shifting the mean. -/
lemma stdNormalCdf_sub (a c : ℝ) : stdNormalCdf (a - c) = cdf (gaussianReal c 1) a := by
  unfold stdNormalCdf
  have h := gaussianReal_map_add_const (μ := 0) (v := 1) c
  rw [zero_add] at h
  rw [← h, cdf_eq_real, cdf_eq_real, measureReal_def, measureReal_def,
    Measure.map_apply (measurable_add_const c) measurableSet_Iic]
  congr 2
  ext x
  simp [le_sub_iff_add_le]

open MeasureTheory in
/-- If a weighted shifted density lies below the standard one up to `a`, so do the areas. -/
lemma weighted_shift_le (a c k : ℝ)
    (h : ∀ x ≤ a, k * gaussianPDFReal c 1 x ≤ gaussianPDFReal 0 1 x) :
    k * stdNormalCdf (a - c) ≤ stdNormalCdf a := by
  rw [stdNormalCdf_sub, stdNormalCdf, gaussian_cdf_eq_integral, gaussian_cdf_eq_integral,
    ← integral_const_mul]
  exact setIntegral_mono_on ((integrable_gaussianPDFReal _ _).restrict.const_mul k)
    (integrable_gaussianPDFReal _ _).restrict measurableSet_Iic h

/-- The exponent comparison behind the reflection formula. -/
lemma key_exponent (L m σ T x : ℝ) (hL : 0 ≤ L) (hσ : 0 < σ) (hT : 0 < T)
    (hx : x ≤ (L - m * T) / (σ * Real.sqrt T)) :
    L * (2 * m / σ ^ 2) - (x - 2 * L / (σ * Real.sqrt T)) ^ 2 / 2 ≤ -x ^ 2 / 2 := by
  have hsT : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
  have hsq : Real.sqrt T ^ 2 = T := Real.sq_sqrt hT.le
  have hs : 0 < σ * Real.sqrt T := mul_pos hσ hsT
  have hc : 0 ≤ 2 * L / (σ * Real.sqrt T) := div_nonneg (by linarith) hs.le
  have h1 : x * (2 * L / (σ * Real.sqrt T)) ≤
      (L - m * T) / (σ * Real.sqrt T) * (2 * L / (σ * Real.sqrt T)) :=
    mul_le_mul_of_nonneg_right hx hc
  have h2 : L * (2 * m / σ ^ 2) + (L - m * T) / (σ * Real.sqrt T) * (2 * L / (σ * Real.sqrt T))
      - (2 * L / (σ * Real.sqrt T)) ^ 2 / 2 = 0 := by
    field_simp
    rw [hsq]
    ring
  nlinarith

/-- The reflection term never exceeds the direct term. -/
lemma pSurv_core (L m σ T k : ℝ) (hL : 0 ≤ L) (hσ : 0 < σ) (hT : 0 < T)
    (hk : k = Real.exp (L * (2 * m / σ ^ 2))) :
    k * stdNormalCdf ((-L - m * T) / (σ * Real.sqrt T)) ≤
      stdNormalCdf ((L - m * T) / (σ * Real.sqrt T)) := by
  have hs : 0 < σ * Real.sqrt T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  have hb : (-L - m * T) / (σ * Real.sqrt T) =
      (L - m * T) / (σ * Real.sqrt T) - 2 * L / (σ * Real.sqrt T) := by
    field_simp; ring
  rw [hb]
  apply weighted_shift_le
  intro x hx
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  rw [mul_left_comm]
  apply mul_le_mul_of_nonneg_left _ (inv_nonneg.mpr (Real.sqrt_nonneg _))
  rw [hk, ← Real.exp_add, Real.exp_le_exp]
  have := key_exponent L m σ T x hL hσ hT hx
  linarith

#print axioms gaussian_cdf_eq_integral
#print axioms stdNormalCdf_sub
#print axioms weighted_shift_le
#print axioms key_exponent
#print axioms pSurv_core

/-- Main claim. The survival chance from the reflection formula is a genuine chance, between 0 and 1,
for any spot at or below the wall, any rates, any positive volatility and any positive time. So the
survival-weighted recipe charges only a fraction of the full overlay: its price always lies between
the flat price and the unweighted vanna-volga price (54.40 ≤ 64.12 ≤ 71.62 pips on the house contract). -/
theorem survival_weighted_price_between_flat_and_full_overlay
    (S H rd rf σ T Vflat : ℝ) (x Cmkt Cflat : Fin 3 → ℝ)
    (hS : 0 < S) (hSH : S ≤ H) (hσ : 0 < σ) (hT : 0 < T) :
    0 ≤ pSurv S H rd rf σ T ∧ pSurv S H rd rf σ T ≤ 1 ∧
      min Vflat (Vflat + vvOverlay x Cmkt Cflat) ≤ vvSurvPrice Vflat S H rd rf σ T x Cmkt Cflat ∧
      vvSurvPrice Vflat S H rd rf σ T x Cmkt Cflat ≤ max Vflat (Vflat + vvOverlay x Cmkt Cflat) := by
  have hHS : 0 < H / S := div_pos (hS.trans_le hSH) hS
  have hL : 0 ≤ Real.log (H / S) := Real.log_nonneg ((one_le_div hS).mpr hSH)
  have hk : (H / S) ^ (2 * (rd - rf - σ ^ 2 / 2) / σ ^ 2) =
      Real.exp (Real.log (H / S) * (2 * (rd - rf - σ ^ 2 / 2) / σ ^ 2)) :=
    Real.rpow_def_of_pos hHS _
  have hcore := pSurv_core (Real.log (H / S)) (rd - rf - σ ^ 2 / 2) σ T _ hL hσ hT hk
  have hp0 : 0 ≤ pSurv S H rd rf σ T := by
    simp only [pSurv]
    linarith
  have hp1 : pSurv S H rd rf σ T ≤ 1 := by
    simp only [pSurv]
    have h1 := cdf_le_one (gaussianReal 0 1) ((Real.log (H / S) - (rd - rf - σ ^ 2 / 2) * T) /
      (σ * Real.sqrt T))
    have h2 := mul_nonneg (Real.rpow_nonneg hHS.le (2 * (rd - rf - σ ^ 2 / 2) / σ ^ 2))
      (cdf_nonneg (gaussianReal 0 1) ((-Real.log (H / S) - (rd - rf - σ ^ 2 / 2) * T) /
        (σ * Real.sqrt T)))
    unfold stdNormalCdf at h1 ⊢
    linarith
  refine ⟨hp0, hp1, ?_, ?_⟩
  · simp only [vvSurvPrice]
    rcases le_total 0 (vvOverlay x Cmkt Cflat) with hO | hO
    · rw [min_eq_left (by linarith)]
      nlinarith
    · rw [min_eq_right (by linarith)]
      nlinarith
  · simp only [vvSurvPrice]
    rcases le_total 0 (vvOverlay x Cmkt Cflat) with hO | hO
    · rw [max_eq_right (by linarith)]
      nlinarith
    · rw [max_eq_left (by linarith)]
      nlinarith

/-- The overlay reprices its own pillar. If the rows of `A` are the pillars' vega, vanna and volga
(one column per pillar), `A` is invertible, and the weights `x` match the greeks of pillar `j`
itself, then the flat price of pillar `j` plus the overlay is exactly its market price. -/
theorem overlay_reprices_own_pillar
    (A : Matrix (Fin 3) (Fin 3) ℝ) (hA : A.det ≠ 0) (x Cmkt Cflat : Fin 3 → ℝ) (j : Fin 3)
    (hx : A *ᵥ x = A *ᵥ Pi.single j 1) :
    Cflat j + vvOverlay x Cmkt Cflat = Cmkt j := by
  have hu : IsUnit A.det := isUnit_iff_ne_zero.mpr hA
  have hxj : x = Pi.single j 1 := by
    have h := congrArg (fun v => A⁻¹ *ᵥ v) hx
    simp only [mulVec_mulVec, nonsing_inv_mul _ hu, one_mulVec] at h
    exact h
  subst hxj
  simp [vvOverlay, Pi.single_apply]

/-- The Brownian-bridge crossing chance. Between two checks `Δt` apart, with both ends `S` and `S'`
below the wall `H`, the mirrored path's density divided by the free path's density is
`exp (-2 ln(H/S) ln(H/S') / (σ² Δt))`, and this chance of touching lies in `(0, 1]`. -/
theorem bridge_crossing_chance
    (S S' H σ Δt : ℝ) (hS : 0 < S) (hS' : 0 < S') (hSH : S < H) (hS'H : S' < H)
    (hσ : 0 < σ) (hΔt : 0 < Δt) :
    Real.exp (-(Real.log (H / S) + Real.log (H / S')) ^ 2 / (2 * σ ^ 2 * Δt))
        / Real.exp (-(Real.log (H / S) - Real.log (H / S')) ^ 2 / (2 * σ ^ 2 * Δt))
      = Real.exp (-2 * Real.log (H / S) * Real.log (H / S') / (σ ^ 2 * Δt)) ∧
    0 < Real.exp (-2 * Real.log (H / S) * Real.log (H / S') / (σ ^ 2 * Δt)) ∧
    Real.exp (-2 * Real.log (H / S) * Real.log (H / S') / (σ ^ 2 * Δt)) ≤ 1 := by
  have hl1 : 0 < Real.log (H / S) := Real.log_pos ((one_lt_div hS).mpr hSH)
  have hl2 : 0 < Real.log (H / S') := Real.log_pos ((one_lt_div hS').mpr hS'H)
  have hd : 0 < σ ^ 2 * Δt := by positivity
  refine ⟨?_, Real.exp_pos _, ?_⟩
  · rw [← Real.exp_sub]
    congr 1
    field_simp
    ring
  · rw [Real.exp_le_one_iff]
    apply div_nonpos_of_nonpos_of_nonneg _ hd.le
    have := mul_pos hl1 hl2
    nlinarith

-- The card's worked arithmetic, in hundredths of a pip.
-- Recipe: flat 54.40 plus weighted overlay 9.72 is 64.12.
example : (5440 : ℕ) + 972 = 6412 := by decide
-- No survival weight: flat 54.40 plus full overlay 17.22 is 71.62.
example : (5440 : ℕ) + 1722 = 7162 := by decide
-- Recipe 1.91 pips below the model's 66.03; unweighted overlay 5.59 above it.
example : (6603 : ℤ) - 6412 = 191 ∧ (7162 : ℤ) - 6603 = 559 := by decide
-- Week case: recipe minus model is 0.31 - (-4.18) = 4.49 pips.
example : (31 : ℤ) - (-418) = 449 := by decide
-- Payoff at expiry with EURUSD at 1.19 and strike 1.10 is 900 pips (0.09 dollars per euro).
example : (11900 : ℕ) - 11000 = 900 := by decide

#print axioms survival_weighted_price_between_flat_and_full_overlay
#print axioms overlay_reprices_own_pillar
#print axioms bridge_crossing_chance
