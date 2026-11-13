-- Calibrating Hull-White: volatility multiplies every option width alike while reversion shrinks long and late widths more than short and early ones, and the load, the variance clock and the forward-measure drift are the integrals the card says they are.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Convex.SpecificFunctions.Basic
import Mathlib.Data.Finset.Prod

open Real

/-- The load `b_κ(u) = (1 - e^{-κu}) / κ`: how much a `u`-year zero-coupon bond's log price
moves per unit move of the short rate. -/
noncomputable def hwLoad (κ u : ℝ) : ℝ := (1 - exp (-κ * u)) / κ

/-- The variance clock `v_κ(E) = (1 - e^{-2κE}) / (2κ)`: the short rate's spread at expiry `E`
is `σ² v_κ(E)`. -/
noncomputable def hwClock (κ E : ℝ) : ℝ := (1 - exp (-2 * κ * E)) / (2 * κ)

/-- The width `w = σ b_κ(u) √(v_κ(E))` of the option on a bond paid `u` years after expiry `E`. -/
noncomputable def hwWidth (κ σ u E : ℝ) : ℝ := σ * hwLoad κ u * sqrt (hwClock κ E)

lemma hw_ratio_pos {x : ℝ} (hx : 0 < x) : 0 < (1 - exp (-x)) / x := by
  have : exp (-x) < 1 := exp_lt_one_iff.mpr (by linarith)
  exact div_pos (by linarith) hx

lemma hw_ratio_lt_one {x : ℝ} (hx : 0 < x) : (1 - exp (-x)) / x < 1 := by
  have := add_one_lt_exp (show -x ≠ 0 by linarith)
  rw [div_lt_one hx]; linarith

lemma hw_ratio_strictAnti {p q : ℝ} (hp : 0 < p) (hpq : p < q) :
    (1 - exp (-q)) / q < (1 - exp (-p)) / p := by
  have h := strictConvexOn_exp.secant_strict_mono (a := 0) (x := -q) (y := -p)
    (Set.mem_univ _) (Set.mem_univ _) (Set.mem_univ _) (by linarith) (by linarith) (by linarith)
  simp only [exp_zero, sub_zero] at h
  have e1 : (exp (-q) - 1) / -q = (1 - exp (-q)) / q := by rw [← neg_div_neg_eq]; ring_nf
  have e2 : (exp (-p) - 1) / -p = (1 - exp (-p)) / p := by rw [← neg_div_neg_eq]; ring_nf
  rw [e1, e2] at h; exact h

lemma hw_width_ratio (κ σ u E : ℝ) (hκ : 0 < κ) (hσ : 0 < σ) (hu : 0 < u) (hE : 0 < E) :
    hwWidth κ σ u E / (σ * u * sqrt E) =
      (1 - exp (-(κ * u))) / (κ * u) * sqrt ((1 - exp (-(2 * κ * E))) / (2 * κ * E)) := by
  unfold hwWidth hwLoad hwClock
  have hsE : 0 < sqrt E := sqrt_pos.mpr hE
  have h1 : sqrt ((1 - exp (-(2 * κ * E))) / (2 * κ * E)) =
      sqrt ((1 - exp (-2 * κ * E)) / (2 * κ)) / sqrt E := by
    rw [← sqrt_div' _ hE.le]; congr 1; rw [neg_mul, neg_mul, div_div]
  rw [h1, neg_mul]
  field_simp

#print axioms hw_ratio_pos
#print axioms hw_ratio_lt_one
#print axioms hw_ratio_strictAnti
#print axioms hw_width_ratio

/-- Volatility scales every width alike, and reversion shrinks long and late widths more than
short and early ones: for reversion `κ > 0` and volatility `σ > 0`, multiplying `σ` by `c`
multiplies every width by `c`; every width is strictly below its no-pull value `σ u √E`; and the
ratio of width to no-pull width is strictly smaller for a later payment `u' ≥ u` and a later
expiry `E' ≥ E` when at least one of them is strictly later. -/
theorem reversion_shrinks_long_late_widths_more (κ σ : ℝ) (hκ : 0 < κ) (hσ : 0 < σ)
    {u u' E E' : ℝ} (hu : 0 < u) (hE : 0 < E) (huu : u ≤ u') (hEE : E ≤ E')
    (hlater : u < u' ∨ E < E') :
    (∀ c : ℝ, hwWidth κ (c * σ) u E = c * hwWidth κ σ u E) ∧
    hwWidth κ σ u E / (σ * u * sqrt E) < 1 ∧
    hwWidth κ σ u' E' / (σ * u' * sqrt E') < hwWidth κ σ u E / (σ * u * sqrt E) := by
  refine ⟨fun c => by unfold hwWidth; ring, ?_, ?_⟩
  · rw [hw_width_ratio κ σ u E hκ hσ hu hE]
    have a1 := hw_ratio_lt_one (mul_pos hκ hu)
    have a0 := hw_ratio_pos (mul_pos hκ hu)
    have b1 := hw_ratio_lt_one (show 0 < 2 * κ * E by positivity)
    have b0 := hw_ratio_pos (show 0 < 2 * κ * E by positivity)
    have s1 : sqrt ((1 - exp (-(2 * κ * E))) / (2 * κ * E)) < 1 := by
      rw [sqrt_lt' one_pos]; simpa using b1
    have s0 : 0 ≤ sqrt ((1 - exp (-(2 * κ * E))) / (2 * κ * E)) := sqrt_nonneg _
    nlinarith
  · have hu' : 0 < u' := by linarith
    have hE' : 0 < E' := by linarith
    rw [hw_width_ratio κ σ u E hκ hσ hu hE, hw_width_ratio κ σ u' E' hκ hσ hu' hE']
    set A := (1 - exp (-(κ * u))) / (κ * u)
    set A' := (1 - exp (-(κ * u'))) / (κ * u')
    set B := (1 - exp (-(2 * κ * E))) / (2 * κ * E)
    set B' := (1 - exp (-(2 * κ * E'))) / (2 * κ * E')
    have hA' : 0 < A' := hw_ratio_pos (mul_pos hκ hu')
    have hB : 0 < B := hw_ratio_pos (by positivity)
    have hB' : 0 < B' := hw_ratio_pos (by positivity)
    have hAA : A' ≤ A := by
      rcases huu.lt_or_eq with h | h
      · exact (hw_ratio_strictAnti (mul_pos hκ hu) (by nlinarith)).le
      · simp only [A, A', h]; rfl
    have hBB : B' ≤ B := by
      rcases hEE.lt_or_eq with h | h
      · exact (hw_ratio_strictAnti (by positivity) (by nlinarith)).le
      · simp only [B, B', h]; rfl
    have sB : 0 < sqrt B := sqrt_pos.mpr hB
    have sB' : 0 < sqrt B' := sqrt_pos.mpr hB'
    have sBB : sqrt B' ≤ sqrt B := sqrt_le_sqrt hBB
    rcases hlater with h | h
    · have : A' < A := hw_ratio_strictAnti (mul_pos hκ hu) (by nlinarith)
      nlinarith
    · have : B' < B := hw_ratio_strictAnti (by positivity) (by nlinarith)
      have : sqrt B' < sqrt B := sqrt_lt_sqrt hB'.le this
      nlinarith

lemma hw_integral_exp (a x : ℝ) (ha : a ≠ 0) :
    ∫ s in (0 : ℝ)..x, exp (-a * s) = (1 - exp (-a * x)) / a := by
  rw [intervalIntegral.integral_comp_mul_left (fun t => exp t) (neg_ne_zero.mpr ha), integral_exp]
  simp only [mul_zero, exp_zero, smul_eq_mul]
  field_simp
  ring

#print axioms hw_integral_exp

/-- The load and the variance clock equal the integrals that define them:
`b_κ(u) = ∫₀ᵘ e^{-κs} ds` and `v_κ(E) = ∫₀ᴱ e^{-2κs} ds`, for reversion `κ > 0`. -/
theorem load_and_clock_are_integrals (κ u E : ℝ) (hκ : 0 < κ) :
    hwLoad κ u = ∫ s in (0 : ℝ)..u, exp (-κ * s) ∧
    hwClock κ E = ∫ s in (0 : ℝ)..E, exp (-2 * κ * s) := by
  refine ⟨?_, ?_⟩
  · rw [hw_integral_exp κ u hκ.ne']; rfl
  · have := hw_integral_exp (2 * κ) E (by positivity)
    simp only [neg_mul] at this ⊢
    rw [this]; unfold hwClock; rw [neg_mul, neg_mul]

/-- Under the `E`-forward measure the rate's random part at expiry has mean
`-σ² ∫₀ᴱ e^{-κ(E-s)} b_κ(E-s) ds = -½ σ² b_κ(E)²`, which cancels the `½ σ² b_κ(E)²` in the
curve-fitting target, so the short rate at expiry is centred on today's forward rate. -/
theorem forward_drift_cancels_target_term (κ σ E : ℝ) (hκ : 0 < κ) :
    -σ ^ 2 * ∫ s in (0 : ℝ)..E, exp (-κ * (E - s)) * hwLoad κ (E - s) =
      -(1 / 2) * σ ^ 2 * hwLoad κ E ^ 2 := by
  have hsub := intervalIntegral.integral_comp_sub_left
    (fun t => exp (-κ * t) * hwLoad κ t) (a := 0) (b := E) E
  simp only [sub_self, sub_zero] at hsub
  rw [hsub]
  have hfun : (fun t => exp (-κ * t) * hwLoad κ t) =
      fun t => exp (-κ * t) / κ - exp (-(2 * κ) * t) / κ := by
    funext t; unfold hwLoad
    have : exp (-(2 * κ) * t) = exp (-κ * t) * exp (-κ * t) := by rw [← exp_add]; ring_nf
    rw [this]; field_simp
  rw [hfun, intervalIntegral.integral_sub, intervalIntegral.integral_div, intervalIntegral.integral_div,
    hw_integral_exp κ E hκ.ne', hw_integral_exp (2 * κ) E (by positivity)]
  · unfold hwLoad
    have : exp (-(2 * κ) * E) = exp (-κ * E) * exp (-κ * E) := by rw [← exp_add]; ring_nf
    rw [this]; field_simp; ring
  · exact (by fun_prop : Continuous fun t => exp (-κ * t) / κ).intervalIntegrable _ _
  · exact (by fun_prop : Continuous fun t => exp (-(2 * κ) * t) / κ).intervalIntegrable _ _

/-- Road A searches an exhaustive grid of 21 reversion speeds by 21 volatilities: 441 pairs. -/
example : (Finset.range 21 ×ˢ Finset.range 21).card = 441 := by norm_num

/-- Three expiries, each with two swap lengths: six quotes. -/
example : (Finset.range 3 ×ˢ Finset.range 2).card = 6 := by norm_num

#print axioms reversion_shrinks_long_late_widths_more
#print axioms load_and_clock_are_integrals
#print axioms forward_drift_cancels_target_term
