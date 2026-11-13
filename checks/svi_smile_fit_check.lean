-- The SVI smile: for any smooth positive total-variance curve the implied density is Gatheral's g times a positive factor (so it is non-negative exactly where g is), and a legal SVI curve bottoms out at a + b s √(1 - ρ²) at k* = m - ρ s / √(1 - ρ²), has straight-line wings of slopes b(1 - ρ) and b(1 + ρ), and meets Lee's bound exactly when b(1 + |ρ|) ≤ 2.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Order.Filter.AtTopBot.Basic

open Real MeasureTheory ProbabilityTheory Filter Topology

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The SVI total variance at log-moneyness `k`:
`w(k) = a + b (ρ (k - m) + √((k - m)² + s²))`. -/
noncomputable def svi (a b ρ m s k : ℝ) : ℝ :=
  a + b * (ρ * (k - m) + √((k - m) ^ 2 + s ^ 2))

/-- The Black-Scholes `d₂` in log-moneyness and total variance: `d₂ = -k/√w - √w/2`. -/
noncomputable def bsD2 (k w : ℝ) : ℝ := -k / √w - √w / 2

/-- The call price per unit of forward, undiscounted, on a smile `w`:
`c(k) = N(d₁) - e^k N(d₂)` with `d₁ = d₂ + √w`, both read at `w = w(k)`. -/
noncomputable def forwardCall (w : ℝ → ℝ) (k : ℝ) : ℝ :=
  stdNormalCDF (bsD2 k (w k) + √(w k)) - exp k * stdNormalCDF (bsD2 k (w k))

/-- Gatheral's butterfly function, built from `w`, its slope `w'` and its bend `w''`:
`g(k) = (1 - k w'/(2w))² - (w')²/4 (1/w + 1/4) + w''/2`. -/
noncomputable def gatheralG (w : ℝ → ℝ) (k : ℝ) : ℝ :=
  (1 - k * deriv w k / (2 * w k)) ^ 2
    - (deriv w k) ^ 2 / 4 * (1 / w k + 1 / 4) + deriv (deriv w) k / 2

theorem stdNormalCDF_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  unfold stdNormalCDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg 0 1 t))]

#print axioms stdNormalCDF_eq_integral

theorem stdNormalCDF_hasDerivAt (x : ℝ) :
    HasDerivAt stdNormalCDF ((√(2 * π))⁻¹ * exp (-x ^ 2 / 2)) x := by
  have hc : Continuous (gaussianPDFReal 0 1) := by
    rw [gaussianPDFReal_def]; fun_prop
  have hI : ∀ y, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic y) :=
    fun y => (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : stdNormalCDF = fun y => (∫ t in Set.Iic 0, gaussianPDFReal 0 1 t)
      + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [stdNormalCDF_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI y)]
    ring
  have h := intervalIntegral.integral_hasDerivAt_right (hc.intervalIntegrable 0 x)
    hc.aestronglyMeasurable.stronglyMeasurableAtFilter hc.continuousAt
  rw [heq]
  convert h.const_add _ using 1
  simp [gaussianPDFReal]

#print axioms stdNormalCDF_hasDerivAt

theorem bsD2_hasDerivAt (w : ℝ → ℝ) (hpos : ∀ k, 0 < w k) (k w' : ℝ)
    (hw : HasDerivAt w w' k) :
    HasDerivAt (fun k => bsD2 k (w k))
      (-1 / √(w k) + k * (w' / (2 * √(w k))) / w k - w' / (2 * √(w k)) / 2) k := by
  have hu := hw.sqrt (hpos k).ne'
  have hne : √(w k) ≠ 0 := (Real.sqrt_pos.mpr (hpos k)).ne'
  have h := ((hasDerivAt_id k).neg.div hu hne).sub (hu.div_const 2)
  convert h using 1
  · funext x; simp [bsD2]
  · have hq := Real.sq_sqrt (hpos k).le
    have hwne : w k ≠ 0 := (hpos k).ne'
    simp only [Pi.neg_apply, id]
    rw [hq]
    field_simp
    rw [hq]
    ring

#print axioms bsD2_hasDerivAt

theorem forwardCall_hasDerivAt (w : ℝ → ℝ) (hpos : ∀ k, 0 < w k) (k w' : ℝ)
    (hw : HasDerivAt w w' k) :
    HasDerivAt (forwardCall w)
      (exp k * ((√(2 * π))⁻¹ * exp (-(bsD2 k (w k)) ^ 2 / 2)) * (w' / (2 * √(w k)))
        - exp k * stdNormalCDF (bsD2 k (w k))) k := by
  have hu := hw.sqrt (hpos k).ne'
  have hd := bsD2_hasDerivAt w hpos k w' hw
  have h1 := (stdNormalCDF_hasDerivAt (bsD2 k (w k) + √(w k))).comp k (hd.add hu)
  have h2 := (Real.hasDerivAt_exp k).mul ((stdNormalCDF_hasDerivAt (bsD2 k (w k))).comp k hd)
  have h := h1.sub h2
  convert h using 1
  · funext x; simp [forwardCall]
  have hne : √(w k) ≠ 0 := (Real.sqrt_pos.mpr (hpos k)).ne'
  have hE : exp (-(bsD2 k (w k) + √(w k)) ^ 2 / 2) = exp k * exp (-(bsD2 k (w k)) ^ 2 / 2) := by
    rw [← Real.exp_add]; congr 1; unfold bsD2; field_simp; ring
  simp only [Function.comp]
  rw [hE]
  ring

#print axioms forwardCall_hasDerivAt

theorem sqrt_sub_tendsto (s : ℝ) :
    Tendsto (fun y : ℝ => √(y ^ 2 + s ^ 2) - y) atTop (𝓝 0) := by
  have hlim : Tendsto (fun y : ℝ => s ^ 2 / y) atTop (𝓝 0) :=
    tendsto_const_nhds.div_atTop tendsto_id
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hlim ?_ ?_
  · filter_upwards with y
    have : y ≤ √(y ^ 2 + s ^ 2) :=
      (le_abs_self _).trans (Real.abs_le_sqrt (by nlinarith [sq_nonneg s]))
    linarith
  · filter_upwards [eventually_gt_atTop 0] with y hy
    have hq := Real.sq_sqrt (show 0 ≤ y ^ 2 + s ^ 2 by positivity)
    have hge : y ≤ √(y ^ 2 + s ^ 2) :=
      (le_abs_self _).trans (Real.abs_le_sqrt (by nlinarith [sq_nonneg s]))
    rw [le_div_iff₀ hy]
    nlinarith

#print axioms sqrt_sub_tendsto

/-- **The butterfly test** (Why it works, Step 4 and its detailed proof). Take any total-variance
curve `w` of log-moneyness that is twice continuously differentiable and positive everywhere,
and price calls on it by Black-Scholes, per unit of forward and undiscounted:
`c(k) = N(d₁) - e^k N(d₂)`. Then the density of `ln(S_T/F)` that the prices imply,
`e^(-k) (c'' - c')`, equals `g(k) / √(2π w) · exp(-d₂²/2)` at every `k`; since the factor
beside `g` is positive, that density is non-negative exactly where `g(k)` is non-negative. -/
theorem implied_density_eq_gatheral_g_times_positive_factor
    (w : ℝ → ℝ) (hw : ContDiff ℝ 2 w) (hpos : ∀ k, 0 < w k) (k : ℝ) :
    exp (-k) * (deriv (deriv (forwardCall w)) k - deriv (forwardCall w) k)
        = gatheralG w k / √(2 * π * w k) * exp (-(bsD2 k (w k)) ^ 2 / 2) ∧
      (0 ≤ exp (-k) * (deriv (deriv (forwardCall w)) k - deriv (forwardCall w) k)
        ↔ 0 ≤ gatheralG w k) := by
  have hd1 : Differentiable ℝ w := hw.differentiable (by norm_num)
  have hd2 : Differentiable ℝ (deriv w) :=
    ((contDiff_succ_iff_deriv (n := 1)).mp hw).2.2.differentiable (by norm_num)
  have hC1 : deriv (forwardCall w) = fun k =>
      exp k * ((√(2 * π))⁻¹ * exp (-(bsD2 k (w k)) ^ 2 / 2)) * (deriv w k / (2 * √(w k)))
        - exp k * stdNormalCDF (bsD2 k (w k)) := by
    funext x
    exact (forwardCall_hasDerivAt w hpos x _ (hd1 x).hasDerivAt).deriv
  have hne : √(w k) ≠ 0 := (Real.sqrt_pos.mpr (hpos k)).ne'
  have hdd := bsD2_hasDerivAt w hpos k _ (hd1 k).hasDerivAt
  have hu := (hd1 k).hasDerivAt.sqrt (hpos k).ne'
  have hD := (((Real.hasDerivAt_exp k).mul
      ((((hdd.pow 2).neg.div_const 2).exp).const_mul (√(2 * π))⁻¹)).mul
      ((hd2 k).hasDerivAt.div (hu.const_mul 2) (mul_ne_zero two_ne_zero hne))).sub
      ((Real.hasDerivAt_exp k).mul ((stdNormalCDF_hasDerivAt _).comp k hdd))
  have e := HasDerivAt.deriv (f := fun k =>
      exp k * ((√(2 * π))⁻¹ * exp (-(bsD2 k (w k)) ^ 2 / 2)) * (deriv w k / (2 * √(w k)))
        - exp k * stdNormalCDF (bsD2 k (w k))) hD
  have hL : exp (-k) * (deriv (deriv (forwardCall w)) k - deriv (forwardCall w) k)
      = gatheralG w k / √(2 * π * w k) * exp (-(bsD2 k (w k)) ^ 2 / 2) := by
    rw [hC1, e]
    have hsq : √(2 * π * w k) = √(2 * π) * √(w k) := Real.sqrt_mul (by positivity) _
    have hwk := Real.sq_sqrt (hpos k).le
    have hpi : √(2 * π) ≠ 0 := by positivity
    rw [hsq, Real.exp_neg]
    simp only [Pi.mul_apply, Pi.div_apply, Pi.neg_apply, Pi.pow_apply, Function.comp_apply,
      Nat.cast_ofNat, Nat.reduceSub, pow_one]
    generalize exp (-(bsD2 k (w k)) ^ 2 / 2) = E
    unfold gatheralG bsD2
    generalize deriv w k = a1
    generalize deriv (deriv w) k = a2
    obtain ⟨u, hu_def⟩ : ∃ u, u = √(w k) := ⟨_, rfl⟩
    rw [← hu_def] at hwk hne ⊢
    rw [← hwk]
    have hek := Real.exp_pos k
    field_simp
    ring
  refine ⟨hL, ?_⟩
  rw [hL]
  have hfac : 0 < exp (-(bsD2 k (w k)) ^ 2 / 2) / √(2 * π * w k) := by
    have := hpos k
    positivity
  rw [show gatheralG w k / √(2 * π * w k) * exp (-(bsD2 k (w k)) ^ 2 / 2)
      = gatheralG w k * (exp (-(bsD2 k (w k)) ^ 2 / 2) / √(2 * π * w k)) by ring]
  exact mul_nonneg_iff_of_pos_right hfac

/-- **The bottom of the smile** (The formula, and Why it works, Step 1). For an SVI curve with
`b ≥ 0`, `ρ` strictly between -1 and 1 and `s > 0`, total variance is never below
`w_min = a + b s √(1 - ρ²)`, and it reaches that value at `k* = m - ρ s / √(1 - ρ²)`. -/
theorem svi_minimum_at_bottom
    (a b ρ m s : ℝ) (hb : 0 ≤ b) (hρl : -1 < ρ) (hρr : ρ < 1) (hs : 0 < s) :
    (∀ k, a + b * s * √(1 - ρ ^ 2) ≤ svi a b ρ m s k) ∧
      svi a b ρ m s (m - ρ * s / √(1 - ρ ^ 2)) = a + b * s * √(1 - ρ ^ 2) := by
  have h1 : 0 < 1 - ρ ^ 2 := by nlinarith
  have hr : 0 < √(1 - ρ ^ 2) := Real.sqrt_pos.mpr h1
  have hr2 : √(1 - ρ ^ 2) ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt h1.le
  set r := √(1 - ρ ^ 2) with hr_def
  constructor
  · intro k
    unfold svi
    set x := k - m
    have key : s * r - ρ * x ≤ √(x ^ 2 + s ^ 2) :=
      (le_abs_self _).trans (Real.abs_le_sqrt (by nlinarith [sq_nonneg (r * x + ρ * s)]))
    nlinarith [mul_le_mul_of_nonneg_left key hb]
  · unfold svi
    have hx : (m - ρ * s / r - m) ^ 2 + s ^ 2 = (s / r) ^ 2 := by
      field_simp
      nlinarith [hr2]
    rw [hx, Real.sqrt_sq (by positivity)]
    have : ρ * (m - ρ * s / r - m) + s / r = s * r := by
      field_simp
      nlinarith [hr2]
    rw [this]; ring

/-- **Straight wings and Lee's bound** (The formula, Steps 1 and 5). For an SVI curve with
`b ≥ 0`, `ρ` strictly between -1 and 1 and `s > 0`, the curve hugs a straight line of slope
`b(1 + ρ)` far to the right and climbs leftward along a straight line of slope `b(1 - ρ)` far to
the left (the gap to each line tends to 0); and both wing slopes are at most Lee's ceiling of 2
exactly when `b(1 + |ρ|) ≤ 2`. -/
theorem svi_wings_straight_and_lee_bound
    (a b ρ m s : ℝ) (hb : 0 ≤ b) (hρl : -1 < ρ) (hρr : ρ < 1) (hs : 0 < s) :
    Tendsto (fun k => svi a b ρ m s k - (a + b * (1 + ρ) * (k - m))) atTop (𝓝 0) ∧
      Tendsto (fun k => svi a b ρ m s k - (a - b * (1 - ρ) * (k - m))) atBot (𝓝 0) ∧
      (b * (1 - ρ) ≤ 2 ∧ b * (1 + ρ) ≤ 2 ↔ b * (1 + |ρ|) ≤ 2) := by
  refine ⟨?_, ?_, ?_⟩
  · have hm : Tendsto (fun k : ℝ => k - m) atTop atTop := tendsto_atTop_add_const_right _ (-m) tendsto_id
    have := ((sqrt_sub_tendsto s).comp hm).const_mul b
    rw [mul_zero] at this
    refine this.congr (fun k => ?_)
    simp only [Function.comp, svi]; ring
  · have hm : Tendsto (fun k : ℝ => -(k - m)) atBot atTop :=
      tendsto_neg_atBot_atTop.comp (tendsto_atBot_add_const_right _ (-m) tendsto_id)
    have := ((sqrt_sub_tendsto s).comp hm).const_mul b
    rw [mul_zero] at this
    refine this.congr (fun k => ?_)
    simp only [Function.comp, svi, neg_sq]; ring
  · rcases abs_cases ρ with ⟨h, _⟩ | ⟨h, _⟩ <;> rw [h] <;> constructor
    · intro h; exact h.2
    · intro h; constructor <;> nlinarith
    · intro h; exact h.1
    · intro h; constructor <;> nlinarith

#print axioms implied_density_eq_gatheral_g_times_positive_factor
#print axioms svi_minimum_at_bottom
#print axioms svi_wings_straight_and_lee_bound
