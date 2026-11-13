-- Pricing on a grid: one theta step of the log-price Black-Scholes scheme multiplies every grid wiggle e^(iφj) by (1 - (1-θ)p)/(1 + θp), which has size at most 1 for every dial θ ≥ 1/2, and the explicit step (θ = 0) blows the checkerboard up by more than 1 each step once the spreading ratio passes 1/2.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Tactic.NormNum

open Real

namespace BlackScholesGrid

/-- The spreading ratio ν = a k / h², with a = σ²/2, step h across and step k up. -/
noncomputable def spreadRatio (σ h k : ℝ) : ℝ := σ ^ 2 / 2 * k / h ^ 2

/-- The sliding ratio η = b k / (2h), with b = r - q - σ²/2. -/
noncomputable def slideRatio (σ r q h k : ℝ) : ℝ := (r - q - σ ^ 2 / 2) * k / (2 * h)

/-- One theta step of the card's scheme, at every node i of an endless row:
-θ(ν-η)V_{i-1}^{n+1} + (1 + θ(2ν + rk))V_i^{n+1} - θ(ν+η)V_{i+1}^{n+1}
  = V_i^n + (1-θ)[(ν-η)V_{i-1}^n - (2ν + rk)V_i^n + (ν+η)V_{i+1}^n].
`old` is row n, `new` is row n+1. Rows are complex so that wiggles e^(iφj) can be stepped. -/
def ThetaStep (θ ν η rk : ℝ) (old new : ℤ → ℂ) : Prop :=
  ∀ i : ℤ,
    -(θ * (ν - η) : ℝ) * new (i - 1) + ((1 + θ * (2 * ν + rk) : ℝ) : ℂ) * new i
        - (θ * (ν + η) : ℝ) * new (i + 1)
      = old i + ((1 - θ : ℝ) : ℂ) *
          ((ν - η : ℝ) * old (i - 1) - ((2 * ν + rk : ℝ) : ℂ) * old i + (ν + η : ℝ) * old (i + 1))

/-- The wiggle of angle φ and size c across the grid: c · e^(iφj) at node j.
At φ = π it is the checkerboard c, -c, c, -c, ... -/
noncomputable def wiggle (c : ℂ) (φ : ℝ) : ℤ → ℂ :=
  fun j => c * Complex.exp (Complex.I * (φ * j : ℝ))

/-- The checkerboard: plus, minus, plus, minus on consecutive nodes. -/
noncomputable def checkerboard (c : ℂ) : ℤ → ℂ :=
  fun j => c * (-1 : ℂ) ^ j

/-- The right-hand side of the equation times the time step, read on a wiggle of angle φ:
p = ν s + r k - 2iη sin φ, with s = 4 sin²(φ/2). -/
noncomputable def wiggleLoad (ν η rk φ : ℝ) : ℂ :=
  ((ν * (4 * Real.sin (φ / 2) ^ 2) + rk : ℝ) : ℂ) - 2 * Complex.I * ((η * Real.sin φ : ℝ) : ℂ)

/-- The factor one theta step multiplies a wiggle by: (1 - (1-θ)p)/(1 + θp). -/
noncomputable def thetaFactor (θ ν η rk φ : ℝ) : ℂ :=
  (1 - ((1 - θ : ℝ) : ℂ) * wiggleLoad ν η rk φ) / (1 + (θ : ℂ) * wiggleLoad ν η rk φ)

lemma cos_eq_half (φ : ℝ) : Real.cos φ = 1 - 2 * Real.sin (φ / 2) ^ 2 := by
  have h := Real.cos_sq (φ / 2)
  have h2 := Real.sin_sq_add_cos_sq (φ / 2)
  rw [show 2 * (φ / 2) = φ by ring] at h
  linarith

#print axioms cos_eq_half

lemma exp_shift (φ : ℝ) (i : ℤ) (s : ℤ) :
    Complex.exp (Complex.I * ((φ * ((i + s : ℤ) : ℝ) : ℝ) : ℂ))
      = Complex.exp (Complex.I * ((φ * (i : ℝ) : ℝ) : ℂ)) * Complex.exp (((φ * s : ℝ) : ℂ) * Complex.I) := by
  rw [← Complex.exp_add]
  congr 1
  push_cast
  ring

#print axioms exp_shift

lemma wiggle_step (θ ν η rk φ : ℝ) (c : ℂ) (hden : 1 + (θ : ℂ) * wiggleLoad ν η rk φ ≠ 0) :
    ThetaStep θ ν η rk (wiggle c φ) (fun j => thetaFactor θ ν η rk φ * wiggle c φ j) := by
  intro i
  have hG : thetaFactor θ ν η rk φ * (1 + (θ : ℂ) * wiggleLoad ν η rk φ)
      = 1 - ((1 - θ : ℝ) : ℂ) * wiggleLoad ν η rk φ := by
    unfold thetaFactor; exact div_mul_cancel₀ _ hden
  have hm := exp_shift φ i (-1)
  have hp := exp_shift φ i 1
  simp only [Int.cast_neg, Int.cast_one, mul_neg, mul_one, Complex.exp_mul_I] at hm hp
  rw [show i - 1 = i + -1 by ring] 
  simp only [wiggle]
  rw [hm, hp]
  set E := Complex.exp (Complex.I * ((φ * (i : ℝ) : ℝ) : ℂ))
  set G := thetaFactor θ ν η rk φ
  have hc := cos_eq_half φ
  unfold wiggleLoad at hG
  push_cast at hG ⊢
  rw [Complex.cos_neg, Complex.sin_neg]
  have hc' : Complex.cos (φ : ℂ) = 1 - 2 * Complex.sin ((φ : ℂ) / 2) ^ 2 := by
    exact_mod_cast hc
  rw [hc']
  linear_combination (c * E) * hG

#print axioms wiggle_step

lemma neg_one_zpow_sub_one (i : ℤ) : (-1 : ℂ) ^ (i - 1) = -(-1 : ℂ) ^ i := by
  rw [zpow_sub₀ (by norm_num), zpow_one]; ring

#print axioms neg_one_zpow_sub_one

lemma neg_one_zpow_add_one (i : ℤ) : (-1 : ℂ) ^ (i + 1) = -(-1 : ℂ) ^ i := by
  rw [zpow_add₀ (by norm_num), zpow_one]; ring

#print axioms neg_one_zpow_add_one

lemma wiggleLoad_re (ν η rk φ : ℝ) :
    (wiggleLoad ν η rk φ).re = ν * (4 * Real.sin (φ / 2) ^ 2) + rk := by
  simp only [wiggleLoad, Complex.sub_re, Complex.sub_im, Complex.mul_re, Complex.mul_im,
    Complex.ofReal_re, Complex.ofReal_im, Complex.I_re, Complex.I_im, Complex.re_ofNat,
    Complex.im_ofNat]
  ring

#print axioms wiggleLoad_re

lemma wiggleLoad_im (ν η rk φ : ℝ) :
    (wiggleLoad ν η rk φ).im = -(2 * (η * Real.sin φ)) := by
  simp only [wiggleLoad, Complex.sub_re, Complex.sub_im, Complex.mul_re, Complex.mul_im,
    Complex.ofReal_re, Complex.ofReal_im, Complex.I_re, Complex.I_im, Complex.re_ofNat,
    Complex.im_ofNat]
  ring

#print axioms wiggleLoad_im

/-- **No wiggle grows at a dial of one half or above.** Take the Black-Scholes equation in log
price with constant volatility σ, bank rate r ≥ 0 and dividend yield q, a grid with step h > 0
across and k > 0 up, spreading ratio ν = (σ²/2)k/h² and sliding ratio η = (r-q-σ²/2)k/(2h).
For any dial θ ≥ 1/2 (Crank-Nicolson at 1/2, implicit at 1), one theta step carries every wiggle
c·e^(iφj) to G·c·e^(iφj), with G = (1 - (1-θ)p)/(1 + θp) and p = νs + rk - 2iη sin φ, and
|G| ≤ 1: the scheme is unconditionally stable, whatever the size of the steps. -/
theorem theta_scheme_unconditionally_stable_from_one_half
    (σ r q h k θ : ℝ) (hh : 0 < h) (hk : 0 < k) (hr : 0 ≤ r) (hθ : 1 / 2 ≤ θ) :
    ∀ (c : ℂ) (φ : ℝ),
      ThetaStep θ (spreadRatio σ h k) (slideRatio σ r q h k) (r * k) (wiggle c φ)
        (fun j => thetaFactor θ (spreadRatio σ h k) (slideRatio σ r q h k) (r * k) φ
          * wiggle c φ j) ∧
      ‖thetaFactor θ (spreadRatio σ h k) (slideRatio σ r q h k) (r * k) φ‖ ≤ 1 := by
  intro c φ
  have hν : 0 ≤ spreadRatio σ h k := by unfold spreadRatio; positivity
  have hrk : 0 ≤ r * k := by positivity
  set ν := spreadRatio σ h k
  set η := slideRatio σ r q h k
  set x := ν * (4 * Real.sin (φ / 2) ^ 2) + r * k with hxdef
  have hx : 0 ≤ x := by positivity
  set y := -(2 * (η * Real.sin φ))
  have hre := wiggleLoad_re ν η (r * k) φ
  have him := wiggleLoad_im ν η (r * k) φ
  set W := wiggleLoad ν η (r * k) φ
  have hden_re : (1 + (θ : ℂ) * W).re = 1 + θ * x := by
    rw [Complex.add_re, Complex.one_re, Complex.mul_re, Complex.ofReal_re, Complex.ofReal_im,
      hre, him]
    ring
  have hden : 1 + (θ : ℂ) * W ≠ 0 := by
    intro h0
    rw [h0, Complex.zero_re] at hden_re
    nlinarith
  refine ⟨wiggle_step θ ν η (r * k) φ c hden, ?_⟩
  unfold thetaFactor
  rw [norm_div, div_le_one (norm_pos_iff.mpr hden)]
  have hsq : ‖1 - ((1 - θ : ℝ) : ℂ) * W‖ ^ 2 ≤ ‖1 + (θ : ℂ) * W‖ ^ 2 := by
    rw [Complex.sq_norm, Complex.sq_norm, Complex.normSq_apply, Complex.normSq_apply]
    simp only [Complex.sub_re, Complex.add_re, Complex.one_re, Complex.mul_re,
      Complex.ofReal_re, Complex.ofReal_im, Complex.sub_im, Complex.add_im, Complex.one_im,
      Complex.mul_im, hre, him]
    have h1 : 0 ≤ 2 * θ - 1 := by linarith
    nlinarith [mul_nonneg hx h1, mul_nonneg (mul_nonneg hx h1) hx, mul_nonneg h1 (sq_nonneg y)]
  nlinarith [norm_nonneg (1 - ((1 - θ : ℝ) : ℂ) * W), norm_nonneg (1 + (θ : ℂ) * W)]

/-- **The checkerboard multiplier (Step 6).** For any dial θ ≥ 0, with the same grid and
r ≥ 0, one theta step carries the checkerboard c, -c, c, ... to itself times
(1 - (1-θ)(4ν + rk))/(1 + θ(4ν + rk)): the drift η drops out. -/
theorem theta_step_checkerboard_multiplier
    (σ r q h k θ : ℝ) (hh : 0 < h) (hk : 0 < k) (hr : 0 ≤ r) (hθ0 : 0 ≤ θ)
    (c : ℂ) :
    ThetaStep θ (spreadRatio σ h k) (slideRatio σ r q h k) (r * k) (checkerboard c)
      (fun j => (((1 - (1 - θ) * (4 * spreadRatio σ h k + r * k))
          / (1 + θ * (4 * spreadRatio σ h k + r * k)) : ℝ) : ℂ) * checkerboard c j) := by
  have hν : 0 ≤ spreadRatio σ h k := by unfold spreadRatio; positivity
  have hrk : 0 ≤ r * k := by positivity
  set ν := spreadRatio σ h k
  set η := slideRatio σ r q h k
  have hD : (1 + θ * (4 * ν + r * k)) ≠ 0 := by positivity
  have hMr : (1 - (1 - θ) * (4 * ν + r * k)) / (1 + θ * (4 * ν + r * k))
      * (1 + θ * (4 * ν + r * k)) = 1 - (1 - θ) * (4 * ν + r * k) := div_mul_cancel₀ _ hD
  set M := (1 - (1 - θ) * (4 * ν + r * k)) / (1 + θ * (4 * ν + r * k))
  have hM : (M : ℂ) * (1 + θ * (4 * ν + r * k)) = 1 - (1 - θ) * (4 * ν + r * k) := by
    exact_mod_cast hMr
  intro i
  simp only [checkerboard]
  rw [neg_one_zpow_sub_one, neg_one_zpow_add_one]
  push_cast
  linear_combination (c * (-1 : ℂ) ^ i) * hM

/-- **The explicit scheme detonates past a spreading ratio of one half.** At dial 0 each new
value is fixed by the old row. If ν = (σ²/2)k/h² > 1/2 (with h, k > 0 and r ≥ 0), then the
explicit step turns the checkerboard into (1 - 4ν - rk) times itself, and that multiplier has
size greater than 1, so the checkerboard grows and flips sign every step. -/
theorem explicit_scheme_checkerboard_grows
    (σ r q h k : ℝ) (hh : 0 < h) (hk : 0 < k) (hr : 0 ≤ r)
    (hν : 1 / 2 < spreadRatio σ h k) (c : ℂ) (new : ℤ → ℂ)
    (hstep : ThetaStep 0 (spreadRatio σ h k) (slideRatio σ r q h k) (r * k)
      (checkerboard c) new) :
    (∀ j : ℤ, new j = ((1 - 4 * spreadRatio σ h k - r * k : ℝ) : ℂ) * checkerboard c j) ∧
    1 < |1 - 4 * spreadRatio σ h k - r * k| := by
  have hrk : 0 ≤ r * k := by positivity
  refine ⟨fun j => ?_, ?_⟩
  · have hj := hstep j
    simp only [checkerboard] at hj ⊢
    rw [neg_one_zpow_sub_one, neg_one_zpow_add_one] at hj
    push_cast at hj ⊢
    linear_combination hj
  · rw [abs_of_neg (by linarith)]
    linarith

-- The card's worked numbers, as exact fractions: σ = 1/5, r = 1/20, q = 1/50,
-- h = 2/200 = 1/100, k = 1/200 on the 200-by-200 grid.
-- Spreading ratio ν = 1.
example : spreadRatio (1 / 5) (1 / 100) (1 / 200) = 1 := by norm_num [spreadRatio]
-- Sliding ratio η = 0.0025 = 1/400.
example : slideRatio (1 / 5) (1 / 20) (1 / 50) (1 / 100) (1 / 200) = 1 / 400 := by
  norm_num [slideRatio]
-- The drain per step r k = 0.00025 = 1/4000.
example : (1 / 20 : ℝ) * (1 / 200) = 1 / 4000 := by norm_num
-- The Crank-Nicolson row: -0.498750, 2.000125, -0.501250.
example : -(1 / 2 : ℚ) * (1 - 1 / 400) = -399 / 800 := by norm_num
example : (1 : ℚ) + 1 + (1 / 4000) / 2 = 16001 / 8000 := by norm_num
example : -(1 / 2 : ℚ) * (1 + 1 / 400) = -401 / 800 := by norm_num
-- With 500 steps instead of 200 (k = 1/500): ν = 0.4, η = 0.001, r k = 0.0001.
example : spreadRatio (1 / 5) (1 / 100) (1 / 500) = 2 / 5 := by norm_num [spreadRatio]
example : slideRatio (1 / 5) (1 / 20) (1 / 50) (1 / 100) (1 / 500) = 1 / 1000 := by
  norm_num [slideRatio]
-- Its explicit weights ν - η, 1 - 2ν - rk, ν + η: 0.399000, 0.199900, 0.401000.
example : (2 / 5 : ℚ) - 1 / 1000 = 399 / 1000 := by norm_num
example : (1 : ℚ) - 2 * (2 / 5) - 1 / 10000 = 1999 / 10000 := by norm_num
example : (2 / 5 : ℚ) + 1 / 1000 = 401 / 1000 := by norm_num
-- The checkerboard multiplier on the 200-by-200 grid: explicit 1 - 4ν - rk, about -3 ...
example : (1 : ℚ) - 4 * 1 - 1 / 4000 = -12001 / 4000 := by norm_num
-- ... and Crank-Nicolson, about -1/3.
example : ((1 : ℚ) - (1 / 2) * (4 * 1 + 1 / 4000)) / (1 + (1 / 2) * (4 * 1 + 1 / 4000))
    = -8001 / 24001 := by norm_num

end BlackScholesGrid

open BlackScholesGrid

#print axioms theta_scheme_unconditionally_stable_from_one_half
#print axioms theta_step_checkerboard_multiplier
#print axioms explicit_scheme_checkerboard_grows
