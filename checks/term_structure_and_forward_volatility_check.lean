-- Term structure and forward volatility: total variances of back-to-back periods add, so the forward volatility between two expiries exists exactly when total variance does not fall, and it is then the unique square root of the variance in between per year.
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Probability.Distributions.Gaussian.Real

open MeasureTheory ProbabilityTheory

/-- The forward volatility. Take a near expiry `T₁` and a far expiry `T₂ > T₁`, with implied
volatilities `σ₁` and `σ₂`, so total variances `w₁ = σ₁² T₁` and `w₂ = σ₂² T₂`. A non-negative
volatility `σ_f` for the stretch between them rebuilds the far total variance,
`w₁ + σ_f² (T₂ - T₁) = w₂`, exactly when `w₁ ≤ w₂` and `σ_f = √((w₂ - w₁)/(T₂ - T₁))`.
So there is one answer when total variance does not fall, and none when it falls. -/
theorem forward_volatility_iff (σ₁ σ₂ T₁ T₂ σf : ℝ) (hT : T₁ < T₂) (hσf : 0 ≤ σf) :
    σ₁ ^ 2 * T₁ + σf ^ 2 * (T₂ - T₁) = σ₂ ^ 2 * T₂ ↔
      (σ₁ ^ 2 * T₁ ≤ σ₂ ^ 2 * T₂ ∧
        σf = Real.sqrt ((σ₂ ^ 2 * T₂ - σ₁ ^ 2 * T₁) / (T₂ - T₁))) := by
  have hd : 0 < T₂ - T₁ := sub_pos.mpr hT
  constructor
  · intro h
    have hx : σf ^ 2 = (σ₂ ^ 2 * T₂ - σ₁ ^ 2 * T₁) / (T₂ - T₁) := by
      rw [eq_div_iff hd.ne']; linarith
    refine ⟨by nlinarith [sq_nonneg σf], ?_⟩
    rw [← hx, Real.sqrt_sq hσf]
  · rintro ⟨hle, hf⟩
    have hnn : 0 ≤ (σ₂ ^ 2 * T₂ - σ₁ ^ 2 * T₁) / (T₂ - T₁) := div_nonneg (by linarith) hd.le
    rw [hf, Real.sq_sqrt hnn, div_mul_cancel₀ _ hd.ne']
    ring

/-- Independent moves add their variances: if `Z₁` and `Z₂` are independent standard bell-curve
draws, then `a Z₁ + b Z₂` is a bell curve with mean 0 and variance `a² + b²`. With
`a = σ₁ √T₁` and `b = σ_f √(T₂ - T₁)` this says the one-year log move has variance
`w₁ + σ_f² (T₂ - T₁)`. -/
theorem independent_bell_curves_add_variances {Ω : Type*} {mΩ : MeasurableSpace Ω}
    {P : Measure Ω} {Z₁ Z₂ : Ω → ℝ} (hind : IndepFun Z₁ Z₂ P)
    (h₁ : HasLaw Z₁ (gaussianReal 0 1) P) (h₂ : HasLaw Z₂ (gaussianReal 0 1) P) (a b : ℝ) :
    P.map (fun ω => a * Z₁ ω + b * Z₂ ω) = gaussianReal 0 (a ^ 2 + b ^ 2).toNNReal := by
  have hX := gaussianReal_const_mul h₁ a
  have hY := gaussianReal_const_mul h₂ b
  have hXY : IndepFun (fun ω => a * Z₁ ω) (fun ω => b * Z₂ ω) P :=
    hind.comp (measurable_const_mul a) (measurable_const_mul b)
  have := gaussianReal_add_gaussianReal_of_indepFun hXY hX hY
  have e : (fun ω => a * Z₁ ω + b * Z₂ ω) = (fun ω => a * Z₁ ω) + (fun ω => b * Z₂ ω) := rfl
  rw [e, this]
  congr 1
  · simp
  · ext
    simp [Real.coe_toNNReal _ (by positivity : (0:ℝ) ≤ a ^ 2 + b ^ 2)]

/-- With a volatility path `σ(t)` fixed in advance, the total variance to `T` is
`w(T) = ∫₀ᵀ σ(t)² dt`. For `0 ≤ T₁ ≤ T₂` it splits into the near total plus the variance in
between, and so it never falls as expiry lengthens. -/
theorem total_variance_adds_and_never_falls (σ : ℝ → ℝ) (T₁ T₂ : ℝ)
    (h0 : 0 ≤ T₁) (h12 : T₁ ≤ T₂)
    (hσ : IntervalIntegrable (fun t => σ t ^ 2) volume 0 T₂) :
    (∫ t in (0 : ℝ)..T₂, σ t ^ 2) =
        (∫ t in (0 : ℝ)..T₁, σ t ^ 2) + ∫ t in T₁..T₂, σ t ^ 2 ∧
      (∫ t in (0 : ℝ)..T₁, σ t ^ 2) ≤ ∫ t in (0 : ℝ)..T₂, σ t ^ 2 := by
  have h1 : IntervalIntegrable (fun t => σ t ^ 2) volume 0 T₁ :=
    hσ.mono_set (by rw [Set.uIcc_of_le (h0.trans h12), Set.uIcc_of_le h0]; exact Set.Icc_subset_Icc le_rfl h12)
  have h2 : IntervalIntegrable (fun t => σ t ^ 2) volume T₁ T₂ :=
    hσ.mono_set (by rw [Set.uIcc_of_le (h0.trans h12), Set.uIcc_of_le h12]; exact Set.Icc_subset_Icc h0 le_rfl)
  have hsplit := (intervalIntegral.integral_add_adjacent_intervals h1 h2).symm
  refine ⟨hsplit, ?_⟩
  rw [hsplit]
  have : 0 ≤ ∫ t in T₁..T₂, σ t ^ 2 :=
    intervalIntegral.integral_nonneg h12 (fun t _ => sq_nonneg _)
  linarith

-- House sheet, exact: w₁ = 0.18² × 0.5 = 0.0162, w₂ = 0.20² × 1 = 0.04.
example : ((18 : ℚ) / 100) ^ 2 * (1 / 2) = 162 / 10000 := by norm_num
example : ((20 : ℚ) / 100) ^ 2 * 1 = 4 / 100 := by norm_num
-- Variance per year in between: (0.04 - 0.0162) / (1 - 0.5) = 0.0476.
example : ((4 : ℚ) / 100 - 162 / 10000) / (1 - 1 / 2) = 476 / 10000 := by norm_num
-- Broken sheet: w₁ = 0.21² × 0.5 = 0.02205 exceeds w₂ = 0.14² × 1 = 0.0196, so no forward vol.
example : ((21 : ℚ) / 100) ^ 2 * (1 / 2) = 2205 / 100000 := by norm_num
example : ((14 : ℚ) / 100) ^ 2 * 1 = 196 / 10000 := by norm_num
example : ((14 : ℚ) / 100) ^ 2 * 1 < ((21 : ℚ) / 100) ^ 2 * (1 / 2) := by norm_num
-- Falling vols are fine: 25% then 20% gives w₁ = 0.03125 ≤ w₂ = 0.04.
example : ((25 : ℚ) / 100) ^ 2 * (1 / 2) ≤ ((20 : ℚ) / 100) ^ 2 * 1 := by norm_num

#print axioms forward_volatility_iff
#print axioms independent_bell_curves_add_variances
#print axioms total_variance_adds_and_never_falls
