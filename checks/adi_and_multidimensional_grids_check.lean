-- Two space dimensions: one Peaceman-Rachford ADI step multiplies every grid sine wave by a factor g with |g| ≤ 1 at every step length, the two half steps together are the Crank-Nicolson step plus the term (r^2/4) δx² δy² (U^(n+1) - U^n), and explicit steps stay bounded on every wave only when r ≤ 1/4.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

open Real

/-- The second difference along a row, not yet divided by h²:
δx² U at (i, j) is U(i+1, j) - 2 U(i, j) + U(i-1, j). -/
def deltaX2 (U : ℤ → ℤ → ℝ) : ℤ → ℤ → ℝ :=
  fun i j => U (i + 1) j - 2 * U i j + U (i - 1) j

/-- The second difference along a column, not yet divided by h²:
δy² U at (i, j) is U(i, j+1) - 2 U(i, j) + U(i, j-1). -/
def deltaY2 (U : ℤ → ℤ → ℝ) : ℤ → ℤ → ℝ :=
  fun i j => U i (j + 1) - 2 * U i j + U i (j - 1)

/-- One factor of the ADI step: W + s · D W, for D one of the two second differences. With
s = -r/2 it is (1 - (r/2) D), with s = r/2 it is (1 + (r/2) D). -/
def adiFactor (s : ℝ) (D : (ℤ → ℤ → ℝ) → ℤ → ℤ → ℝ) (W : ℤ → ℤ → ℝ) : ℤ → ℤ → ℝ :=
  fun i j => W i j + s * D W i j

/-- The grid wave sin(pπx) sin(qπy) at the grid point x = i h, y = j h. -/
noncomputable def gridWave (p q h : ℝ) : ℤ → ℤ → ℝ :=
  fun i j => Real.sin (p * π * (i * h)) * Real.sin (q * π * (j * h))

/-- The weight a = 2 r sin²(pπh/2) of a wave with p humps across (the same formula with q gives
the weight c up the plate). -/
noncomputable def waveWeight (r p h : ℝ) : ℝ := 2 * r * Real.sin (p * π * h / 2) ^ 2

/-- The grid wave is an eigenvector of the row second difference. -/
theorem gridWave_deltaX2 (p q h : ℝ) (i j : ℤ) :
    deltaX2 (gridWave p q h) i j = -(4 * Real.sin (p * π * h / 2) ^ 2) * gridWave p q h i j := by
  simp only [deltaX2, gridWave]
  push_cast
  have e1 : p * π * (((i : ℝ) + 1) * h) = p * π * (i * h) + 2 * (p * π * h / 2) := by ring
  have e2 : p * π * (((i : ℝ) - 1) * h) = p * π * (i * h) - 2 * (p * π * h / 2) := by ring
  rw [e1, e2, Real.sin_add, Real.sin_sub, Real.cos_two_mul]
  have hs := Real.sin_sq_add_cos_sq (p * π * h / 2)
  linear_combination (4 * Real.sin (p * π * (↑i * h)) * Real.sin (q * π * (↑j * h))) * hs

/-- The grid wave is an eigenvector of the column second difference. -/
theorem gridWave_deltaY2 (p q h : ℝ) (i j : ℤ) :
    deltaY2 (gridWave p q h) i j = -(4 * Real.sin (q * π * h / 2) ^ 2) * gridWave p q h i j := by
  simp only [deltaY2, gridWave]
  push_cast
  have e1 : q * π * (((j : ℝ) + 1) * h) = q * π * (j * h) + 2 * (q * π * h / 2) := by ring
  have e2 : q * π * (((j : ℝ) - 1) * h) = q * π * (j * h) - 2 * (q * π * h / 2) := by ring
  rw [e1, e2, Real.sin_add, Real.sin_sub, Real.cos_two_mul]
  have hs := Real.sin_sq_add_cos_sq (q * π * h / 2)
  linear_combination (4 * Real.sin (p * π * (↑i * h)) * Real.sin (q * π * (↑j * h))) * hs

/-- For x ≥ 0 the ratio (1 - x)/(1 + x) lies between -1 and 1. -/
theorem abs_one_sub_div_one_add_le_one (x : ℝ) (hx : 0 ≤ x) : |(1 - x) / (1 + x)| ≤ 1 := by
  rw [abs_div, abs_of_pos (by linarith : (0 : ℝ) < 1 + x), div_le_one (by linarith)]
  exact abs_le.mpr ⟨by linarith, by linarith⟩

#print axioms gridWave_deltaX2
#print axioms gridWave_deltaY2
#print axioms abs_one_sub_div_one_add_le_one

/-- ADI is stable at every step length. Take a constant diffusivity α > 0, a time step Δt > 0,
a grid spacing h > 0 and the mesh ratio r = αΔt/h². Put a = 2r sin²(pπh/2) and
c = 2r sin²(qπh/2), and g = ((1 - a)/(1 + a)) · ((1 - c)/(1 + c)). Start from the grid wave
sin(pπx) sin(qπy). Then the half-step value U* = ((1 - c)/(1 + a)) · wave and the new value
g · wave satisfy the row sweep (1 - (r/2)δx²) U* = (1 + (r/2)δy²) Uⁿ and the column sweep
(1 - (r/2)δy²) Uⁿ⁺¹ = (1 + (r/2)δx²) U* at every grid point, so one step multiplies the wave by g;
and |g| ≤ 1, whatever the step length: no wave can grow. -/
theorem adi_stable_at_every_step_length (α Δt h p q : ℝ) (hα : 0 < α) (hΔt : 0 < Δt)
    (hh : 0 < h) :
    let r := α * Δt / h ^ 2
    let a := waveWeight r p h
    let c := waveWeight r q h
    let g := (1 - a) / (1 + a) * ((1 - c) / (1 + c))
    let Un := gridWave p q h
    let Ustar : ℤ → ℤ → ℝ := fun i j => (1 - c) / (1 + a) * Un i j
    let Unext : ℤ → ℤ → ℝ := fun i j => g * Un i j
    adiFactor (-(r / 2)) deltaX2 Ustar = adiFactor (r / 2) deltaY2 Un ∧
    adiFactor (-(r / 2)) deltaY2 Unext = adiFactor (r / 2) deltaX2 Ustar ∧
    |g| ≤ 1 := by
  intro r a c g Un Ustar Unext
  have hr : 0 ≤ r := by positivity
  have ha : 0 ≤ a := by simp only [a, waveWeight]; positivity
  have hc : 0 ≤ c := by simp only [c, waveWeight]; positivity
  have hX : ∀ i j, r / 2 * deltaX2 Un i j = -a * Un i j := by
    intro i j
    simp only [Un, a, waveWeight]
    rw [gridWave_deltaX2]; ring
  have hY : ∀ i j, r / 2 * deltaY2 Un i j = -c * Un i j := by
    intro i j
    simp only [Un, c, waveWeight]
    rw [gridWave_deltaY2]; ring
  have hXs : ∀ i j, deltaX2 Ustar i j = (1 - c) / (1 + a) * deltaX2 Un i j := by
    intro i j; simp only [Ustar, deltaX2]; ring
  have hYn : ∀ i j, deltaY2 Unext i j = g * deltaY2 Un i j := by
    intro i j; simp only [Unext, deltaY2]; ring
  have ha1 : (1 + a) ≠ 0 := by positivity
  have hc1 : (1 + c) ≠ 0 := by positivity
  have hK : (1 - c) / (1 + a) * (1 + a) = 1 - c := by field_simp
  have hg : g * (1 + c) = (1 - c) / (1 + a) * (1 - a) := by
    simp only [g]; field_simp
  refine ⟨funext₂ fun i j => ?_, funext₂ fun i j => ?_, ?_⟩
  · simp only [adiFactor]
    rw [hXs i j]
    simp only [Ustar]
    linear_combination (-((1 - c) / (1 + a))) * hX i j - hY i j + Un i j * hK
  · simp only [adiFactor]
    rw [hYn i j, hXs i j]
    simp only [Ustar, Unext]
    linear_combination (-g) * hY i j - ((1 - c) / (1 + a)) * hX i j + Un i j * hg
  · simp only [g]
    rw [abs_mul]
    have h1 := abs_one_sub_div_one_add_le_one a ha
    have h2 := abs_one_sub_div_one_add_le_one c hc
    nlinarith [abs_nonneg ((1 - a) / (1 + a)), abs_nonneg ((1 - c) / (1 + c))]

/-- ADI is Crank-Nicolson plus a small term. If U* comes from Uⁿ by the row sweep
(1 - (r/2)δx²) U* = (1 + (r/2)δy²) Uⁿ, and Uⁿ⁺¹ comes from U* by the column sweep
(1 - (r/2)δy²) Uⁿ⁺¹ = (1 + (r/2)δx²) U*, then the two half steps combine into the factored form
(1 - (r/2)δx²)(1 - (r/2)δy²) Uⁿ⁺¹ = (1 + (r/2)δx²)(1 + (r/2)δy²) Uⁿ, which multiplied out reads
(Uⁿ⁺¹ - Uⁿ) + (r²/4) δx² δy² (Uⁿ⁺¹ - Uⁿ) = (r/2)(δx² + δy²)(Uⁿ⁺¹ + Uⁿ):
the Crank-Nicolson step plus the one extra term (r²/4) δx² δy² (Uⁿ⁺¹ - Uⁿ). -/
theorem adi_eq_crank_nicolson_plus_small_term (r : ℝ) (Un Ustar Unext : ℤ → ℤ → ℝ)
    (hrow : adiFactor (-(r / 2)) deltaX2 Ustar = adiFactor (r / 2) deltaY2 Un)
    (hcol : adiFactor (-(r / 2)) deltaY2 Unext = adiFactor (r / 2) deltaX2 Ustar) :
    adiFactor (-(r / 2)) deltaX2 (adiFactor (-(r / 2)) deltaY2 Unext) =
      adiFactor (r / 2) deltaX2 (adiFactor (r / 2) deltaY2 Un) ∧
    ∀ i j : ℤ,
      (Unext i j - Un i j) + r ^ 2 / 4 * deltaX2 (deltaY2 (fun k l => Unext k l - Un k l)) i j =
        r / 2 * (deltaX2 (fun k l => Unext k l + Un k l) i j +
          deltaY2 (fun k l => Unext k l + Un k l) i j) := by
  have key : ∀ V : ℤ → ℤ → ℝ,
      adiFactor (-(r / 2)) deltaX2 (adiFactor (r / 2) deltaX2 V) =
        adiFactor (r / 2) deltaX2 (adiFactor (-(r / 2)) deltaX2 V) := by
    intro V; funext i j; simp only [adiFactor, deltaX2]; ring
  have hF : adiFactor (-(r / 2)) deltaX2 (adiFactor (-(r / 2)) deltaY2 Unext) =
      adiFactor (r / 2) deltaX2 (adiFactor (r / 2) deltaY2 Un) := by
    rw [hcol, key, hrow]
  refine ⟨hF, fun i j => ?_⟩
  have h := congrFun (congrFun hF i) j
  simp only [adiFactor, deltaX2, deltaY2] at h ⊢
  linear_combination h

/-- Explicit steps have a limit, half the one-dimensional one. With constant diffusivity α > 0,
time step Δt > 0, spacing h > 0 and r = αΔt/h², an explicit step multiplies the grid wave with
weights a = 2r sin²(pπh/2) and c = 2r sin²(qπh/2) by 1 - 2a - 2c. That factor stays between
-1 and 1 for every wave exactly when r ≤ 1/4. -/
theorem explicit_step_stable_iff_mesh_ratio_le_quarter (α Δt h : ℝ) (hα : 0 < α)
    (hΔt : 0 < Δt) (hh : 0 < h) :
    (∀ p q : ℝ,
      |1 - 2 * waveWeight (α * Δt / h ^ 2) p h - 2 * waveWeight (α * Δt / h ^ 2) q h| ≤ 1) ↔
      α * Δt / h ^ 2 ≤ 1 / 4 := by
  have hr : 0 ≤ α * Δt / h ^ 2 := by positivity
  constructor
  · intro H
    have h1 := H (1 / h) (1 / h)
    have e : 1 / h * π * h / 2 = π / 2 := by field_simp
    simp only [waveWeight, e, Real.sin_pi_div_two] at h1
    have := (abs_le.mp h1).1
    linarith
  · intro H p q
    simp only [waveWeight]
    have s1 := Real.sin_sq_le_one (p * π * h / 2)
    have s2 := Real.sin_sq_le_one (q * π * h / 2)
    have t1 := sq_nonneg (Real.sin (p * π * h / 2))
    have t2 := sq_nonneg (Real.sin (q * π * h / 2))
    rw [abs_le]
    constructor <;> nlinarith [mul_le_mul_of_nonneg_left s1 hr, mul_le_mul_of_nonneg_left s2 hr,
      mul_nonneg hr t1, mul_nonneg hr t2]

-- The 3-cell grid, settled: top points 75/2 = 37.5 C and bottom points 25/2 = 12.5 C.
-- At each, four times the value equals the sum of its four neighbours (100 C above the top row).
example : 4 * ((75 : ℚ) / 2) = 100 + 0 + 75 / 2 + 25 / 2 ∧
    4 * ((25 : ℚ) / 2) = 75 / 2 + 0 + 25 / 2 + 0 := by norm_num
-- The same as 3 × top - bottom = 100 and 3 × bottom - top = 0.
example : 3 * ((75 : ℚ) / 2) - 25 / 2 = 100 ∧ 3 * ((25 : ℚ) / 2) - 75 / 2 = 0 := by norm_num
-- The 3-cell mesh ratio for one hour: r = 1.2e-5 × 3600 × 9 = 0.3888.
example : (12 : ℚ) / 10 ^ 6 * 3600 * 9 = 3888 / 10000 := by norm_num
-- The 40-cell grid with 10-minute steps: r = 1.2e-5 × 600 × 1600 = 11.52.
example : (12 : ℚ) / 10 ^ 6 * 600 * 1600 = 1152 / 100 := by norm_num
-- The explicit limit r ≤ 1/4 on the 40-cell grid: Δt ≤ 625/48 s, about 13.0208 s.
example : (1 : ℚ) / 4 / (12 / 10 ^ 6 * 1600) = 625 / 48 := by norm_num
-- Explicit steps of 12 s give r = 0.2304 ≤ 1/4; steps of 15 s give r = 0.288 > 1/4, and 1 - 8r < -1.
example : (12 : ℚ) / 10 ^ 6 * 12 * 1600 = 2304 / 10000 ∧ (2304 : ℚ) / 10000 ≤ 1 / 4 := by norm_num
example : (12 : ℚ) / 10 ^ 6 * 15 * 1600 = 288 / 1000 ∧ 1 / 4 < (288 : ℚ) / 1000 ∧
    1 - 8 * ((288 : ℚ) / 1000) < -1 := by norm_num
-- Unknowns m = (N - 1)^2: 81, 361 and 1,521 at N = 10, 20, 40.
example : (10 - 1) ^ 2 = 81 ∧ (20 - 1) ^ 2 = 361 ∧ (40 - 1) ^ 2 = 1521 := by norm_num
-- ADI flops per step, 2n(13n - 2) with n = N - 1: 39,390 at N = 40 and 25,944,030 at N = 1000.
example : 2 * 39 * (13 * 39 - 2) = 39390 ∧ 2 * 999 * (13 * 999 - 2) = 25944030 := by norm_num
-- Banded estimates at N = 40 (m = 1521, w = 39): solve 4mw = 237,276, factor 2mw² = 4,626,882.
example : 4 * 1521 * 39 = 237276 ∧ 2 * 1521 * 39 ^ 2 = 4626882 := by norm_num
-- At N = 1000 (m = 998,001, w = 999): 4mw = 3,988,011,996 and 2mw² = 1,992,011,992,002.
example : 999 ^ 2 = 998001 ∧ 4 * 998001 * 999 = 3988011996 ∧
    2 * 998001 * 999 ^ 2 = 1992011992002 := by norm_num

#print axioms adi_stable_at_every_step_length
#print axioms adi_eq_crank_nicolson_plus_small_term
#print axioms explicit_step_stable_iff_mesh_ratio_le_quarter
