-- Ends and shape: a Hermite cubic on a rising gap never falls when both end slopes lie between zero and three times the gap slope, and the weighted harmonic-mean slope rule always lands in that range.
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Tactic

open Set

namespace SplineShape

/-- The Hermite cubic on the gap from knot `a` to knot `b`: with `h = b - a` and
`p = (t - a)/h` the fraction of the gap already passed,
`S(t) = y₀(1 - 3p² + 2p³) + h s₀(p - 2p² + p³) + y₁(3p² - 2p³) + h s₁(p³ - p²)`.
It starts at the quote `y₀` with slope `s₀` and ends at the quote `y₁` with slope `s₁`. -/
noncomputable def hermite (a b y₀ y₁ s₀ s₁ t : ℝ) : ℝ :=
  y₀ * (1 - 3 * ((t - a) / (b - a)) ^ 2 + 2 * ((t - a) / (b - a)) ^ 3)
    + (b - a) * s₀ * ((t - a) / (b - a) - 2 * ((t - a) / (b - a)) ^ 2 + ((t - a) / (b - a)) ^ 3)
    + y₁ * (3 * ((t - a) / (b - a)) ^ 2 - 2 * ((t - a) / (b - a)) ^ 3)
    + (b - a) * s₁ * (((t - a) / (b - a)) ^ 3 - ((t - a) / (b - a)) ^ 2)

/-- Fritsch and Butland's slope at an inner knot, from the gap lengths `h₀ = h_{i-1}`,
`h₁ = h_i` and the gap slopes `Δ₀ = Δ_{i-1}`, `Δ₁ = Δ_i` on either side: the weighted harmonic
mean `3(h₀ + h₁) / ((2h₁ + h₀)/Δ₀ + (h₁ + 2h₀)/Δ₁)` when `Δ₀Δ₁ > 0`, and `0` otherwise. -/
noncomputable def fbSlope (h₀ h₁ Δ₀ Δ₁ : ℝ) : ℝ :=
  if 0 < Δ₀ * Δ₁ then 3 * (h₀ + h₁) / ((2 * h₁ + h₀) / Δ₀ + (h₁ + 2 * h₀) / Δ₁) else 0

/-- Helper: the slope of the Hermite cubic at every point. -/
theorem hermite_hasDerivAt (a b y₀ y₁ s₀ s₁ t : ℝ) (hab : a < b) :
    HasDerivAt (hermite a b y₀ y₁ s₀ s₁)
      (6 * ((y₁ - y₀) / (b - a)) * ((t - a) / (b - a) - ((t - a) / (b - a)) ^ 2)
        + s₀ * (1 - 4 * ((t - a) / (b - a)) + 3 * ((t - a) / (b - a)) ^ 2)
        + s₁ * (3 * ((t - a) / (b - a)) ^ 2 - 2 * ((t - a) / (b - a)))) t := by
  have hne : b - a ≠ 0 := sub_ne_zero.mpr hab.ne'
  have hp : HasDerivAt (fun t => (t - a) / (b - a)) (1 / (b - a)) t := by
    simpa using ((hasDerivAt_id t).sub_const a).div_const (b - a)
  have P2 := hp.fun_pow 2
  have P3 := hp.fun_pow 3
  have A := (((hasDerivAt_const t (1:ℝ)).sub (P2.const_mul 3)).add (P3.const_mul 2)).const_mul y₀
  have B := ((hp.sub (P2.const_mul 2)).add P3).const_mul ((b - a) * s₀)
  have C := ((P2.const_mul 3).sub (P3.const_mul 2)).const_mul y₁
  have E := (P3.sub P2).const_mul ((b - a) * s₁)
  have H := ((A.add B).add C).add E
  convert H using 1
  · ext y
    simp only [hermite, Pi.add_apply, Pi.sub_apply]
  · norm_num
    field_simp
    ring

#print axioms hermite_hasDerivAt

/-- The square of safe slopes. On a gap from `a` to `b` with the knots in order, if the quotes
rise across the gap (gap slope `Δ = (y₁ - y₀)/(b - a) > 0`) and each end slope divided by the
gap slope, `α = s₀/Δ` and `β = s₁/Δ`, lies between 0 and 3, then the Hermite cubic never falls
anywhere on the gap. -/
theorem hermite_never_falls_in_slope_square (a b y₀ y₁ s₀ s₁ : ℝ) (hab : a < b)
    (hΔ : 0 < (y₁ - y₀) / (b - a))
    (hα₀ : 0 ≤ s₀ / ((y₁ - y₀) / (b - a))) (hα₃ : s₀ / ((y₁ - y₀) / (b - a)) ≤ 3)
    (hβ₀ : 0 ≤ s₁ / ((y₁ - y₀) / (b - a))) (hβ₃ : s₁ / ((y₁ - y₀) / (b - a)) ≤ 3) :
    MonotoneOn (hermite a b y₀ y₁ s₀ s₁) (Icc a b) := by
  have hne : b - a ≠ 0 := sub_ne_zero.mpr hab.ne'
  have hba : 0 < b - a := sub_pos.mpr hab
  set Δ := (y₁ - y₀) / (b - a) with hΔdef
  set α := s₀ / Δ with hαdef
  set β := s₁ / Δ with hβdef
  have hs₀ : s₀ = α * Δ := by rw [hαdef]; field_simp
  have hs₁ : s₁ = β * Δ := by rw [hβdef]; field_simp
  apply monotoneOn_of_deriv_nonneg (convex_Icc a b)
  · intro t _
    exact (hermite_hasDerivAt a b y₀ y₁ s₀ s₁ t hab).continuousAt.continuousWithinAt
  · intro t _
    exact (hermite_hasDerivAt a b y₀ y₁ s₀ s₁ t hab).differentiableAt.differentiableWithinAt
  · intro t ht
    rw [interior_Icc] at ht
    rw [(hermite_hasDerivAt a b y₀ y₁ s₀ s₁ t hab).deriv]
    set p := (t - a) / (b - a) with hpdef
    have hp0 : 0 ≤ p := div_nonneg (by linarith [ht.1]) hba.le
    have hp1 : p ≤ 1 := by rw [div_le_one hba]; linarith [ht.2]
    rw [hs₀, hs₁]
    have u0 : 0 ≤ α / 3 := by linarith
    have u1 : 0 ≤ 1 - α / 3 := by linarith
    have v0 : 0 ≤ β / 3 := by linarith
    have v1 : 0 ≤ 1 - β / 3 := by linarith
    have key : 0 ≤ 6 * (p - p ^ 2) + α * (1 - 4 * p + 3 * p ^ 2) + β * (3 * p ^ 2 - 2 * p) := by
      have e : 6 * (p - p ^ 2) + α * (1 - 4 * p + 3 * p ^ 2) + β * (3 * p ^ 2 - 2 * p)
          = (1 - α / 3) * (1 - β / 3) * (6 * (p * (1 - p)))
            + α / 3 * (1 - β / 3) * (3 * (1 - p) ^ 2)
            + (1 - α / 3) * (β / 3) * (3 * p ^ 2)
            + α / 3 * (β / 3) * (3 * (2 * p - 1) ^ 2) := by ring
      rw [e]
      have q : 0 ≤ p * (1 - p) := mul_nonneg hp0 (by linarith)
      positivity
    have : 6 * Δ * (p - p ^ 2) + α * Δ * (1 - 4 * p + 3 * p ^ 2) + β * Δ * (3 * p ^ 2 - 2 * p)
        = Δ * (6 * (p - p ^ 2) + α * (1 - 4 * p + 3 * p ^ 2) + β * (3 * p ^ 2 - 2 * p)) := by ring
    rw [this]
    exact mul_nonneg hΔ.le key

/-- The harmonic-mean slope always lands in the square. With positive gap lengths on both sides
of a knot and gap slopes of the same sign (`Δ₀Δ₁ > 0`, the quotes keep rising or keep falling
through the knot), the slope `s` divided by either neighbouring gap slope lies strictly between
0 and 3. -/
theorem harmonic_mean_slope_in_square (h₀ h₁ Δ₀ Δ₁ : ℝ) (hh₀ : 0 < h₀) (hh₁ : 0 < h₁)
    (hΔ : 0 < Δ₀ * Δ₁) :
    0 < fbSlope h₀ h₁ Δ₀ Δ₁ / Δ₀ ∧ fbSlope h₀ h₁ Δ₀ Δ₁ / Δ₀ < 3 ∧
      0 < fbSlope h₀ h₁ Δ₀ Δ₁ / Δ₁ ∧ fbSlope h₀ h₁ Δ₀ Δ₁ / Δ₁ < 3 := by
  have h0 : Δ₀ ≠ 0 := by rintro rfl; simp at hΔ
  have h1 : Δ₁ ≠ 0 := by rintro rfl; simp at hΔ
  have hq0 : 0 < Δ₀ ^ 2 := by positivity
  have hq1 : 0 < Δ₁ ^ 2 := by positivity
  have hD : 0 < (2 * h₁ + h₀) * Δ₁ ^ 2 + (h₁ + 2 * h₀) * (Δ₀ * Δ₁) := by positivity
  have hD' : 0 < (h₁ + 2 * h₀) * Δ₀ ^ 2 + (2 * h₁ + h₀) * (Δ₀ * Δ₁) := by positivity
  have hden : (2 * h₁ + h₀) * Δ₁ + (h₁ + 2 * h₀) * Δ₀ ≠ 0 := by
    intro hz
    have : ((2 * h₁ + h₀) * Δ₁ + (h₁ + 2 * h₀) * Δ₀) * Δ₁
        = (2 * h₁ + h₀) * Δ₁ ^ 2 + (h₁ + 2 * h₀) * (Δ₀ * Δ₁) := by ring
    rw [hz, zero_mul] at this
    linarith
  have hs : fbSlope h₀ h₁ Δ₀ Δ₁
      = 3 * (h₀ + h₁) * (Δ₀ * Δ₁) / ((2 * h₁ + h₀) * Δ₁ + (h₁ + 2 * h₀) * Δ₀) := by
    simp only [fbSlope, hΔ, ↓reduceIte]
    rw [div_add_div _ _ h0 h1]
    field_simp
  have e0 : fbSlope h₀ h₁ Δ₀ Δ₁ / Δ₀
      = 3 * (h₀ + h₁) * Δ₁ ^ 2 / ((2 * h₁ + h₀) * Δ₁ ^ 2 + (h₁ + 2 * h₀) * (Δ₀ * Δ₁)) := by
    rw [hs, div_div, div_eq_div_iff (mul_ne_zero hden h0) hD.ne']
    ring
  have e1 : fbSlope h₀ h₁ Δ₀ Δ₁ / Δ₁
      = 3 * (h₀ + h₁) * Δ₀ ^ 2 / ((h₁ + 2 * h₀) * Δ₀ ^ 2 + (2 * h₁ + h₀) * (Δ₀ * Δ₁)) := by
    rw [hs, div_div, div_eq_div_iff (mul_ne_zero hden h1) hD'.ne']
    ring
  rw [e0, e1]
  refine ⟨by positivity, ?_, by positivity, ?_⟩
  · rw [div_lt_iff₀ hD]; nlinarith
  · rw [div_lt_iff₀ hD']; nlinarith

/-- Step 0: a cubic on a gap is fixed by two values and two slopes. For distinct knots
`a < b`, the Hermite cubic passes through `y₀` at `a` and `y₁` at `b`, and its slope is `s₀`
at `a` and `s₁` at `b`. -/
theorem hermite_matches_values_and_slopes (a b y₀ y₁ s₀ s₁ : ℝ) (hab : a < b) :
    hermite a b y₀ y₁ s₀ s₁ a = y₀ ∧ hermite a b y₀ y₁ s₀ s₁ b = y₁ ∧
      HasDerivAt (hermite a b y₀ y₁ s₀ s₁) s₀ a ∧
      HasDerivAt (hermite a b y₀ y₁ s₀ s₁) s₁ b := by
  have hne : b - a ≠ 0 := sub_ne_zero.mpr hab.ne'
  refine ⟨?_, ?_, ?_, ?_⟩
  · simp [hermite]
  · simp only [hermite, div_self hne]; ring
  · convert hermite_hasDerivAt a b y₀ y₁ s₀ s₁ a hab using 1
    simp
  · convert hermite_hasDerivAt a b y₀ y₁ s₀ s₁ b hab using 1
    simp only [div_self hne]; ring

-- The card's worked numbers, as exact fractions: rates in percent a year, slopes in
-- percentage points a year, gaps in years.

-- Monotone slope at 2 years: gap slopes 0 and 1/20, product not positive, so the slope is 0.
example : fbSlope 1 1 0 (1 / 20) = 0 := by norm_num [fbSlope]

-- Monotone slope at 3 years: 3 × (1 + 1) / (3/0.05 + 3/0.7) = 7/75 (0.0933).
example : fbSlope 1 1 (1 / 20) (7 / 10) = 7 / 75 := by norm_num [fbSlope]

-- Its ratio on the 2-to-3-year gap: β = (7/75)/(1/20) = 28/15 (1.8667), inside the square.
example : (7 / 75 : ℝ) / (1 / 20) = 28 / 15 ∧ (28 / 15 : ℝ) ≤ 3 := by norm_num

-- Monotone slope at 5 years, gaps 1 and 2: 9/(5/0.25 + 4/0.025) = 1/20 (0.05).
example : fbSlope 1 2 (1 / 4) (1 / 40) = 1 / 20 := by norm_num [fbSlope]

-- Monotone curve at 2.35 years: between 3.50665 and 3.50675, so it reads 3.5067%.
example : (350665 / 100000 : ℝ) ≤ hermite 2 3 (7 / 2) (71 / 20) 0 (7 / 75) (47 / 20) ∧
    hermite 2 3 (7 / 2) (71 / 20) 0 (7 / 75) (47 / 20) < 350675 / 100000 := by
  norm_num [hermite]

-- Plain average slopes at 3 years: (0.05 + 0.7)/2 = 3/8 (0.3750), so β = 15/2 (7.50), outside the square.
example : ((1 / 20 + 7 / 10) / 2 : ℝ) = 3 / 8 ∧ (3 / 8 : ℝ) / (1 / 20) = 15 / 2 ∧ (3 : ℝ) < 15 / 2 := by
  norm_num

#print axioms hermite_never_falls_in_slope_square
#print axioms harmonic_mean_slope_in_square
#print axioms hermite_matches_values_and_slopes

end SplineShape
