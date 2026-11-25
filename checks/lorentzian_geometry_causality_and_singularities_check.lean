-- Lorentzian geometry: a matter-only universe a(t) = (t/t₀)^(2/3) solves the pressure-free Friedmann equation with H = 2/(3t), a Kerr black hole's horizons are r = M ± √(M² − b²), and a Lorentz boost keeps the sign of every step's square.
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum

/-- A flat universe of pressure-free matter grows like `a(t) = (t/t₀)^(2/3)`: this scale factor is
`1` today (`t = t₀`), it solves the pressure-free Friedmann equation `G_xx = 0`, that is
`2 ä/a + (ȧ/a)² = 0`, at every time `t > 0`, its Hubble rate is `H = ȧ/a = 2/(3t)`, and so the
age is `t₀ = 2/(3 H₀)` with `H₀` the Hubble rate today. -/
theorem matter_universe_scale_factor_two_thirds (t₀ : ℝ) (ht₀ : 0 < t₀) (a : ℝ → ℝ)
    (ha : ∀ t, a t = (t / t₀) ^ ((2 : ℝ) / 3)) :
    a t₀ = 1 ∧
    (∀ t, 0 < t →
      deriv a t / a t = 2 / (3 * t) ∧
      2 * (deriv (deriv a) t / a t) + (deriv a t / a t) ^ 2 = 0) ∧
    t₀ = 2 / (3 * (deriv a t₀ / a t₀)) := by
  set c : ℝ := (2 : ℝ) / 3 with hcdef
  have hfun : a = fun t => (t / t₀) ^ c := funext ha
  subst hfun
  -- first derivative on t > 0
  have hd1 : ∀ x : ℝ, 0 < x →
      HasDerivAt (fun t => (t / t₀) ^ c) (c * (x / t₀) ^ (c - 1) / t₀) x := by
    intro x hx
    have hu : x / t₀ ≠ 0 := (div_pos hx ht₀).ne'
    have := ((hasDerivAt_id' x).div_const t₀).rpow_const (p := c) (Or.inl hu)
    convert this using 1
    ring
  have hd1' : ∀ x : ℝ, 0 < x → deriv (fun t => (t / t₀) ^ c) x = c * (x / t₀) ^ (c - 1) / t₀ :=
    fun x hx => (hd1 x hx).deriv
  have hd2 : ∀ x : ℝ, 0 < x →
      deriv (deriv (fun t => (t / t₀) ^ c)) x = c * ((c - 1) * (x / t₀) ^ (c - 1 - 1) / t₀) / t₀ := by
    intro x hx
    have hev : deriv (fun t => (t / t₀) ^ c) =ᶠ[nhds x] fun y => c * (y / t₀) ^ (c - 1) / t₀ := by
      filter_upwards [lt_mem_nhds hx] with y hy
      exact hd1' y hy
    rw [hev.deriv_eq]
    have hu : x / t₀ ≠ 0 := (div_pos hx ht₀).ne'
    have := ((((hasDerivAt_id' x).div_const t₀).rpow_const (p := c - 1) (Or.inl hu)).const_mul c).div_const t₀
    rw [this.deriv]
    ring
  have key : ∀ x : ℝ, 0 < x →
      deriv (fun t => (t / t₀) ^ c) x / (x / t₀) ^ c = 2 / (3 * x) ∧
      2 * (deriv (deriv (fun t => (t / t₀) ^ c)) x / (x / t₀) ^ c) +
        (deriv (fun t => (t / t₀) ^ c) x / (x / t₀) ^ c) ^ 2 = 0 := by
    intro x hx
    have hu : 0 < x / t₀ := div_pos hx ht₀
    have hp : 0 < (x / t₀) ^ c := Real.rpow_pos_of_pos hu c
    have e1 : (x / t₀) ^ (c - 1) = (x / t₀) ^ c / (x / t₀) := by
      rw [Real.rpow_sub hu, Real.rpow_one]
    have e2 : (x / t₀) ^ (c - 1 - 1) = (x / t₀) ^ c / (x / t₀) / (x / t₀) := by
      rw [Real.rpow_sub hu, Real.rpow_sub hu, Real.rpow_one]
    rw [hd1' x hx, hd2 x hx, e2, e1]
    have hx0 : x ≠ 0 := hx.ne'
    have ht0 : t₀ ≠ 0 := ht₀.ne'
    have hp0 : (x / t₀) ^ c ≠ 0 := hp.ne'
    constructor
    · rw [hcdef]; field_simp
    · rw [hcdef]; field_simp; ring
  refine ⟨?_, fun t ht => ?_, ?_⟩
  · simp [div_self ht₀.ne']
  · exact key t ht
  · have := (key t₀ ht₀).1
    rw [this]
    field_simp

/-- The horizons of a Kerr black hole of mass `M` and spin length `b`, with `0 ≤ b ≤ M`, are the
radii where `Δ = r² − 2Mr + b²` vanishes, and these are exactly `r = M ± √(M² − b²)`. -/
theorem kerr_horizons (M b r : ℝ) (hb : 0 ≤ b) (hbM : b ≤ M) :
    r ^ 2 - 2 * M * r + b ^ 2 = 0 ↔
      r = M + Real.sqrt (M ^ 2 - b ^ 2) ∨ r = M - Real.sqrt (M ^ 2 - b ^ 2) := by
  have hd : 0 ≤ M ^ 2 - b ^ 2 := by nlinarith
  have hs := Real.sq_sqrt hd
  constructor
  · intro h
    have : (r - (M + Real.sqrt (M ^ 2 - b ^ 2))) * (r - (M - Real.sqrt (M ^ 2 - b ^ 2))) = 0 := by
      nlinarith
    rcases mul_eq_zero.mp this with h1 | h1
    · left; linarith
    · right; linarith
  · rintro (h | h) <;> subst h <;> nlinarith

/-- The causal character of a step does not depend on the observer: a ship moving at speed `β`,
with `|β| < 1`, sees the step `(Δt, Δx)` as `((Δt − βΔx), (Δx − βΔt))/√(1 − β²)`, and the square
`−Δt² + Δx²` is unchanged. -/
theorem lorentz_boost_preserves_square (β Δt Δx : ℝ) (hβ : |β| < 1) :
    -((Δt - β * Δx) / Real.sqrt (1 - β ^ 2)) ^ 2 + ((Δx - β * Δt) / Real.sqrt (1 - β ^ 2)) ^ 2 =
      -Δt ^ 2 + Δx ^ 2 := by
  have hb2 : β ^ 2 < 1 := by
    have := sq_abs β
    nlinarith [abs_nonneg β]
  have hpos : 0 < 1 - β ^ 2 := by linarith
  have hs : Real.sqrt (1 - β ^ 2) ^ 2 = 1 - β ^ 2 := Real.sq_sqrt hpos.le
  have hne : Real.sqrt (1 - β ^ 2) ≠ 0 := (Real.sqrt_pos.mpr hpos).ne'
  rw [div_pow, div_pow, hs]
  field_simp
  ring

-- Step 2: a = t^n solves G_xx = 0 when 2n(n − 1) + n² = 0; n = 2/3 does, and G_tt = 3n² = 4/3 at t = 1.
example : (2 : ℚ) * (2 / 3) * (2 / 3 - 1) + (2 / 3) ^ 2 = 0 ∧ (3 : ℚ) * (2 / 3) ^ 2 = 4 / 3 := by
  norm_num

-- Step 2: a = t^(1/2) gives G_xx = 1/4, a third of G_tt = 3/4: pressure ρ/3, radiation, not matter.
example : -((2 : ℚ) * (1 / 2) * (1 / 2 - 1) + (1 / 2) ^ 2) = 1 / 4 ∧
    (3 : ℚ) * (1 / 2) ^ 2 = 3 / 4 ∧ (1 / 4 : ℚ) = (1 / 3) * (3 / 4) := by
  norm_num

-- Kerr with M = 5, b = 3 (so b = 0.6M): Δ vanishes at r = 9 = 1.8M and r = 1 = 0.2M.
example : (9 : ℚ) ^ 2 - 2 * 5 * 9 + 3 ^ 2 = 0 ∧ (1 : ℚ) ^ 2 - 2 * 5 * 1 + 3 ^ 2 = 0 ∧
    (9 : ℚ) = (9 / 5) * 5 ∧ (1 : ℚ) = (1 / 5) * 5 := by
  norm_num

-- Kerr with M = 5, b = 3, on the equator at r = M: g_rr = Σ/Δ = 25/(−16) = −1.5625.
example : (5 : ℚ) ^ 2 / ((5 : ℚ) ^ 2 - 2 * 5 * 5 + 3 ^ 2) = -25 / 16 := by
  norm_num

-- On the equator g_tt = −(1 − 2M/r): +1/19 at r = 1.9M (inside the ergosurface), −1/5 at r = 2.5M.
example : -(1 - 2 / (19 / 10 : ℚ)) = 1 / 19 ∧ -(1 - 2 / (5 / 2 : ℚ)) = -1 / 5 := by
  norm_num

-- Spin past the limit, M = 5, b = 6 (b = 1.2M): at r = M, Δ = 11 = 0.44 M².
example : (5 : ℚ) ^ 2 - 2 * 5 * 5 + 6 ^ 2 = 11 ∧ (11 : ℚ) = (44 / 100) * 5 ^ 2 := by
  norm_num

-- Step 1: squares of one-year steps: ship at 0.6 c, light pulse, 2 light-years apart.
example : -(1 : ℚ) ^ 2 + (3 / 5) ^ 2 = -16 / 25 ∧ -(1 : ℚ) ^ 2 + 1 ^ 2 = 0 ∧
    -(1 : ℚ) ^ 2 + 2 ^ 2 = 3 := by
  norm_num

-- Step 1: boosting at β = 3/5 (γ = 5/4) sends the ship's step to (4/5, 0), the light pulse to
-- (1/2, 1/2) and the spacelike step to (−1/4, 7/4), whose time order has reversed.
example : (5 / 4 : ℚ) * (1 - 3 / 5 * (3 / 5)) = 4 / 5 ∧ (5 / 4 : ℚ) * (3 / 5 - 3 / 5 * 1) = 0 ∧
    (5 / 4 : ℚ) * (1 - 3 / 5 * 1) = 1 / 2 ∧ (5 / 4 : ℚ) * (1 - 3 / 5 * 1) = 1 / 2 ∧
    (5 / 4 : ℚ) * (1 - 3 / 5 * 2) = -1 / 4 ∧ (5 / 4 : ℚ) * (2 - 3 / 5 * 1) = 7 / 4 ∧
    (1 : ℚ) / (1 - (3 / 5) ^ 2) = (5 / 4) ^ 2 := by
  norm_num

#print axioms matter_universe_scale_factor_two_thirds
#print axioms kerr_horizons
#print axioms lorentz_boost_preserves_square
