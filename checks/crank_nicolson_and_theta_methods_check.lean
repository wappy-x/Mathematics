-- Crank-Nicolson and the theta family: the theta scheme multiplies every grid sine wave by g = (1 - (1-θ)·4rs)/(1 + θ·4rs), and |g| ≤ 1 for every wave exactly when θ ≥ 1/2 or r ≤ 1/(2 - 4θ); one step matches the exact decay e^z to within O(z³) exactly when θ = 1/2; and g tends to (θ - 1)/θ as the step grows, which is 0 only for the implicit scheme.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Analysis.Complex.Exponential
import Mathlib.Topology.Algebra.Order.Field

open Real Filter Topology Asymptotics

/-- One theta step on the grid, multiplied through by Δt, with r = αΔt/h²: at every node j,
Vⱼ - Uⱼ = r [θ (Vⱼ₋₁ - 2Vⱼ + Vⱼ₊₁) + (1 - θ)(Uⱼ₋₁ - 2Uⱼ + Uⱼ₊₁)],
where U is the old time row and V the new one. -/
def ThetaStep (θ r : ℝ) (U V : ℤ → ℝ) : Prop :=
  ∀ j : ℤ, V j - U j =
    r * (θ * (V (j - 1) - 2 * V j + V (j + 1)) + (1 - θ) * (U (j - 1) - 2 * U j + U (j + 1)))

/-- The grid wave sin(kπx) at the node x = j h. -/
noncomputable def gridWave (k h : ℝ) : ℤ → ℝ :=
  fun j => Real.sin (k * π * (j * h))

/-- The theta factor as a function of the damping p = 4rs: g = (1 - (1-θ)p)/(1 + θp). -/
noncomputable def thetaG (θ p : ℝ) : ℝ := (1 - (1 - θ) * p) / (1 + θ * p)

/-- The amplification factor of wave k: g = (1 - (1-θ)·4rs)/(1 + θ·4rs), s = sin²(kπh/2). -/
noncomputable def ampFactor (θ r k h : ℝ) : ℝ :=
  thetaG θ (4 * r * Real.sin (k * π * h / 2) ^ 2)

/-- Helper: the theta factor minus e^z equals (θ - 1/2)z² up to 3|z|³ for |z| ≤ 1/2. -/
lemma theta_exp_cubic (θ : ℝ) (hθ0 : 0 ≤ θ) (hθ1 : θ ≤ 1) (z : ℝ) (hz : |z| ≤ 1 / 2) :
    |thetaG θ (-z) - Real.exp z - (θ - 1 / 2) * z ^ 2| ≤ 3 * |z| ^ 3 := by
  have hz1 : |z| ≤ 1 := by linarith
  have hb := Real.exp_bound hz1 (n := 3) (by norm_num)
  simp [Finset.sum_range_succ, Nat.factorial] at hb
  have hzl := abs_le.mp hz
  have hden : 1 / 2 ≤ 1 - θ * z := by nlinarith
  have hden0 : 0 < 1 - θ * z := by linarith
  have hrat : thetaG θ (-z) = 1 + z + θ * z ^ 2 + θ ^ 2 * z ^ 3 / (1 - θ * z) := by
    unfold thetaG
    have hd : 1 + θ * -z = 1 - θ * z := by ring
    have hne := hden0.ne'
    rw [hd, div_eq_iff hne, add_mul, div_mul_cancel₀ _ hne]
    ring
  have hq : |θ ^ 2 * z ^ 3 / (1 - θ * z)| ≤ 2 * |z| ^ 3 := by
    rw [abs_div, abs_of_pos hden0, div_le_iff₀ hden0, abs_mul, abs_pow, abs_pow,
      abs_of_nonneg hθ0]
    have h1 : θ ^ 2 ≤ 1 := by nlinarith
    have h3 : 0 ≤ |z| ^ 3 := by positivity
    nlinarith
  have hsplit : thetaG θ (-z) - Real.exp z - (θ - 1 / 2) * z ^ 2 =
      θ ^ 2 * z ^ 3 / (1 - θ * z) - (Real.exp z - (1 + z + z ^ 2 / 2)) := by
    rw [hrat]; ring
  rw [hsplit]
  have h3 : 0 ≤ |z| ^ 3 := by positivity
  calc _ ≤ |θ ^ 2 * z ^ 3 / (1 - θ * z)| + |Real.exp z - (1 + z + z ^ 2 / 2)| := abs_sub _ _
    _ ≤ 2 * |z| ^ 3 + |z| ^ 3 * (4 / 18) := by
        gcongr
        convert hb using 2
        ring
    _ ≤ 3 * |z| ^ 3 := by nlinarith

#print axioms theta_exp_cubic

/-- The theta scheme and its stability. Take a constant diffusivity α > 0, a time step Δt > 0,
an even space step h > 0, r = αΔt/h², and a dial θ between 0 and 1. Then one theta step carries
every grid wave sin(kπx) to g times itself, with g = (1 - (1-θ)·4rs)/(1 + θ·4rs) and
s = sin²(kπh/2); and no wave grows, |g| ≤ 1 for every k, exactly when θ ≥ 1/2 or
r ≤ 1/(2 - 4θ). So at θ ≥ 1/2 (Crank-Nicolson and the implicit scheme) every step length is
stable, and below one half the step is limited. -/
theorem theta_scheme_stable_iff (α Δt h θ : ℝ) (hα : 0 < α) (hΔt : 0 < Δt) (hh : 0 < h)
    (hθ0 : 0 ≤ θ) (hθ1 : θ ≤ 1) :
    let r := α * Δt / h ^ 2
    (∀ k : ℝ, ThetaStep θ r (gridWave k h) (fun j => ampFactor θ r k h * gridWave k h j)) ∧
    ((∀ k : ℝ, |ampFactor θ r k h| ≤ 1) ↔ (1 / 2 ≤ θ ∨ r ≤ 1 / (2 - 4 * θ))) := by
  intro r
  have hr : 0 < r := div_pos (mul_pos hα hΔt) (pow_pos hh 2)
  refine ⟨fun k j => ?_, ?_⟩
  · simp only [gridWave, ampFactor]
    have e1 : k * π * (((j - 1 : ℤ) : ℝ) * h) = k * π * (j * h) - 2 * (k * π * h / 2) := by
      push_cast; ring
    have e2 : k * π * (((j + 1 : ℤ) : ℝ) * h) = k * π * (j * h) + 2 * (k * π * h / 2) := by
      push_cast; ring
    rw [e1, e2, Real.sin_sub, Real.sin_add, Real.sin_two_mul, Real.cos_two_mul, Real.cos_sq']
    have hden : 0 < 1 + θ * (4 * r * Real.sin (k * π * h / 2) ^ 2) :=
      add_pos_of_pos_of_nonneg one_pos (mul_nonneg hθ0 (by positivity))
    have hg : thetaG θ (4 * r * Real.sin (k * π * h / 2) ^ 2) *
        (1 + θ * (4 * r * Real.sin (k * π * h / 2) ^ 2)) =
        1 - (1 - θ) * (4 * r * Real.sin (k * π * h / 2) ^ 2) := by
      unfold thetaG; exact div_mul_cancel₀ _ hden.ne'
    generalize thetaG θ (4 * r * Real.sin (k * π * h / 2) ^ 2) = g at hg ⊢
    linear_combination Real.sin (k * π * (j * h)) * hg
  constructor
  · intro hall
    have hk := hall (1 / h)
    have hs : Real.sin (1 / h * π * h / 2) = 1 := by
      rw [show 1 / h * π * h / 2 = π / 2 by field_simp]
      exact Real.sin_pi_div_two
    simp only [ampFactor, hs, one_pow, mul_one, thetaG] at hk
    have hden : 0 < 1 + θ * (4 * r) := by nlinarith
    rw [abs_le, le_div_iff₀ hden] at hk
    have h1 := hk.1
    by_cases hθ : 1 / 2 ≤ θ
    · exact Or.inl hθ
    · right
      push Not at hθ
      rw [le_div_iff₀ (by linarith)]
      nlinarith
  · intro hcond k
    simp only [ampFactor, thetaG]
    have hs2 : Real.sin (k * π * h / 2) ^ 2 ≤ 1 := Real.sin_sq_le_one _
    have hs0 : 0 ≤ Real.sin (k * π * h / 2) ^ 2 := sq_nonneg _
    generalize Real.sin (k * π * h / 2) ^ 2 = t at hs2 hs0 ⊢
    have hp0 : 0 ≤ 4 * r * t := by positivity
    have hp4 : 4 * r * t ≤ 4 * r := by nlinarith
    generalize 4 * r * t = p at hp0 hp4 ⊢
    have hden : 0 < 1 + θ * p := add_pos_of_pos_of_nonneg one_pos (mul_nonneg hθ0 hp0)
    rw [abs_le, le_div_iff₀ hden, div_le_iff₀ hden]
    have key : (1 - 2 * θ) * p ≤ 2 := by
      by_cases hθ : 1 / 2 ≤ θ
      · nlinarith
      · push Not at hθ
        rcases hcond with h | h
        · linarith
        · rw [le_div_iff₀ (by linarith)] at h
          nlinarith [mul_le_mul_of_nonneg_left hp4 (by linarith : (0:ℝ) ≤ 1 - 2 * θ)]
    constructor <;> nlinarith [mul_nonneg hθ0 hp0]

/-- Crank-Nicolson is second order, and only it. A wave whose exact decay over one step is e^z
(z = -λΔt) is multiplied by the theta scheme by g = (1 + (1-θ)z)/(1 - θz). That one-step factor
differs from e^z by O(z³) as z → 0, which makes the scheme second order in time, exactly when
θ = 1/2; every other dial leaves an error of order z², a first-order scheme. -/
theorem theta_factor_third_order_iff_crank_nicolson (θ : ℝ) (hθ0 : 0 ≤ θ) (hθ1 : θ ≤ 1) :
    (fun z : ℝ => thetaG θ (-z) - Real.exp z) =O[𝓝 0] (fun z : ℝ => z ^ 3) ↔ θ = 1 / 2 := by
  have hev : ∀ᶠ z in 𝓝 (0:ℝ), |z| < 1 / 2 :=
    Metric.eventually_nhds_iff.mpr ⟨1 / 2, by norm_num, fun h => by simpa [Real.dist_eq] using h⟩
  constructor
  · intro h
    rw [isBigO_iff] at h
    obtain ⟨C, hC⟩ := h
    obtain ⟨δ, hδ, hδ'⟩ := Metric.eventually_nhds_iff.mp (hC.and hev)
    by_contra hne
    have hc : 0 < |θ - 1 / 2| := abs_pos.mpr (sub_ne_zero.mpr hne)
    have hK : 0 < |C| + 3 := by positivity
    set z := min (δ / 2) (|θ - 1 / 2| / (2 * (|C| + 3))) with hz
    have hz0 : 0 < z := lt_min (by linarith) (by positivity)
    have hzδ : dist z 0 < δ := by
      rw [Real.dist_eq, sub_zero, abs_of_pos hz0]
      exact lt_of_le_of_lt (min_le_left _ _) (by linarith)
    obtain ⟨hb1, hb2⟩ := hδ' hzδ
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_pow] at hb1
    have hb3 := theta_exp_cubic θ hθ0 hθ1 z hb2.le
    rw [abs_of_pos hz0] at hb1 hb3
    have hz3 : 0 ≤ z ^ 3 := by positivity
    have key : |θ - 1 / 2| * z ^ 2 ≤ (|C| + 3) * z ^ 3 := by
      have e : (θ - 1 / 2) * z ^ 2 = (thetaG θ (-z) - Real.exp z) -
          (thetaG θ (-z) - Real.exp z - (θ - 1 / 2) * z ^ 2) := by ring
      have := abs_sub (thetaG θ (-z) - Real.exp z)
        (thetaG θ (-z) - Real.exp z - (θ - 1 / 2) * z ^ 2)
      rw [← e, abs_mul, abs_of_nonneg (sq_nonneg z)] at this
      nlinarith [le_abs_self C]
    have k2 : |θ - 1 / 2| ≤ (|C| + 3) * z := by
      have hz2 : 0 < z ^ 2 := by positivity
      have : z ^ 2 * (|θ - 1 / 2| - (|C| + 3) * z) ≤ 0 := by nlinarith
      nlinarith [(mul_nonpos_iff.mp this)]
    have k3 : (|C| + 3) * z ≤ |θ - 1 / 2| / 2 := by
      calc (|C| + 3) * z ≤ (|C| + 3) * (|θ - 1 / 2| / (2 * (|C| + 3))) :=
            mul_le_mul_of_nonneg_left (min_le_right _ _) hK.le
        _ = |θ - 1 / 2| / 2 := by field_simp
    linarith
  · intro hθ
    subst hθ
    rw [isBigO_iff]
    refine ⟨3, ?_⟩
    filter_upwards [hev] with z hz
    have := theta_exp_cubic (1 / 2) (by norm_num) (by norm_num) z hz.le
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_pow]
    simpa using this

/-- Stable is not the same as damped. For a dial 0 < θ ≤ 1, as a wave's damping 4rs grows
without limit the factor g tends to (θ - 1)/θ; that limit is 0 (L-stable) only for the implicit
scheme θ = 1, and for Crank-Nicolson it is -1, so its sharpest waves flip sign instead of dying. -/
theorem theta_factor_limit_at_infinity (θ : ℝ) (hθ0 : 0 < θ) (hθ1 : θ ≤ 1) :
    Tendsto (thetaG θ) atTop (𝓝 ((θ - 1) / θ)) ∧ ((θ - 1) / θ = 0 ↔ θ = 1) := by
  constructor
  · have h1 : Tendsto (fun p : ℝ => (p⁻¹ - (1 - θ)) / (p⁻¹ + θ)) atTop
        (𝓝 ((0 - (1 - θ)) / (0 + θ))) :=
      (tendsto_inv_atTop_zero.sub_const _).div (tendsto_inv_atTop_zero.add_const _)
        (by simpa using hθ0.ne')
    have h2 : (0 - (1 - θ)) / (0 + θ) = (θ - 1) / θ := by ring
    rw [h2] at h1
    refine h1.congr' ?_
    filter_upwards [eventually_gt_atTop 0] with p hp
    unfold thetaG
    have hd1 : 0 < 1 + θ * p := by positivity
    have hd2 : 0 < p⁻¹ + θ := by positivity
    rw [div_eq_div_iff hd2.ne' hd1.ne']
    field_simp
  · rw [div_eq_zero_iff, sub_eq_zero]
    constructor
    · rintro (h | h)
      · exact h
      · exact absurd h hθ0.ne'
    · intro h; exact Or.inl h

-- The card's worked numbers, as exact fractions.
-- r = αΔt/h² with α = 1e-5 m²/s, Δt = 200 s, h = 0.02 m.
example : (1 / 100000 : ℚ) * 200 / (1 / 50) ^ 2 = 5 := by norm_num
-- The explicit limit h²/(2α) is 20 s; the hour is 180 such steps or 18 steps of 200 s.
example : ((1 / 50 : ℚ) ^ 2) / (2 * (1 / 100000)) = 20 := by norm_num
example : (3600 : ℚ) / 20 = 180 ∧ (3600 : ℚ) / 200 = 18 := by norm_num
-- The Crank-Nicolson row at r = 5: -r/2, 1 + r, -r/2.
example : -(5 : ℚ) / 2 = -5 / 2 ∧ 1 + (5 : ℚ) = 6 := by norm_num
-- Right side at node 1 and at an inner node.
example : (100 : ℚ) + 5 / 2 * (0 - 2 * 100 + 100) = -150 := by norm_num
example : (100 : ℚ) + 5 / 2 * (100 - 2 * 100 + 100) = 100 := by norm_num
-- Sweep down, row 1: c'₁ = -2.5/6 and d'₁ = -150/6 = -25.
example : (-5 / 2 : ℚ) / 6 = -5 / 12 ∧ (-150 : ℚ) / 6 = -25 := by norm_num
-- Step limits r ≤ 1/(2 - 4θ): 1/2 for θ = 0, 5/2 for θ = 0.4.
example : (1 : ℚ) / (2 - 4 * 0) = 1 / 2 ∧ (1 : ℚ) / (2 - 4 * (2 / 5)) = 5 / 2 := by norm_num
-- Crank-Nicolson's limit factor (θ - 1)/θ at θ = 1/2 is -1.
example : ((1 / 2 : ℚ) - 1) / (1 / 2) = -1 := by norm_num
-- Flop counts: Thomas 8·49 - 7 = 385; right side 5·49 = 245; runs to 1 pm.
example : 8 * 49 - 7 = 385 ∧ 5 * 49 = 245 := by decide
example : 18 * (385 + 245) = 11340 ∧ 2 * 385 + 17 * (385 + 245) = 11480 ∧
    180 * 245 = 44100 := by decide

#print axioms theta_scheme_stable_iff
#print axioms theta_factor_third_order_iff_crank_nicolson
#print axioms theta_factor_limit_at_infinity
