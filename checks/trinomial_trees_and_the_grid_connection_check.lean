-- Trinomial trees: the explicit finite-difference scheme for the Black-Scholes equation in log-price is the trinomial tree's recursion with coefficients that differ from the branch weights by one term proportional to the step, the branch weights are the only ones matching a step's drift and spread for any spacing, and the middle weight is non-negative exactly when the spacing is wide enough.
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Tactic

open Real

namespace TrinomialTree

/-! Notation, as on the card. `r` is the riskless rate, `q` the dividend yield, `σ` the
volatility, `Δt` one step's length in years and `Δx` the rung spacing in log-price. -/

/-- `ν = r - q - σ²/2`, the log-price's drift per year under the risk-neutral weights. -/
noncomputable def logDrift (r q σ : ℝ) : ℝ := r - q - σ ^ 2 / 2

/-- The spread term `(σ²Δt + ν²Δt²) / Δx²`, the sum of the up and down weights. -/
noncomputable def spreadTerm (r q σ Δt Δx : ℝ) : ℝ :=
  (σ ^ 2 * Δt + logDrift r q σ ^ 2 * Δt ^ 2) / Δx ^ 2

/-- The tilt term `ν Δt / Δx`, the up weight minus the down weight. -/
noncomputable def tiltTerm (r q σ Δt Δx : ℝ) : ℝ := logDrift r q σ * Δt / Δx

/-- The tree's up weight `p_u = ½ (spread + tilt)`. -/
noncomputable def treeUp (r q σ Δt Δx : ℝ) : ℝ :=
  (spreadTerm r q σ Δt Δx + tiltTerm r q σ Δt Δx) / 2

/-- The tree's middle weight `p_m = 1 - spread`. -/
noncomputable def treeMid (r q σ Δt Δx : ℝ) : ℝ := 1 - spreadTerm r q σ Δt Δx

/-- The tree's down weight `p_d = ½ (spread - tilt)`. -/
noncomputable def treeDown (r q σ Δt Δx : ℝ) : ℝ :=
  (spreadTerm r q σ Δt Δx - tiltTerm r q σ Δt Δx) / 2

/-- The grid's up coefficient `a_u = Δt (σ² / (2Δx²) + ν / (2Δx))`. -/
noncomputable def gridUp (r q σ Δt Δx : ℝ) : ℝ :=
  Δt * (σ ^ 2 / (2 * Δx ^ 2) + logDrift r q σ / (2 * Δx))

/-- The grid's middle coefficient `a_m = 1 - σ²Δt / Δx²`. -/
noncomputable def gridMid (σ Δt Δx : ℝ) : ℝ := 1 - σ ^ 2 * Δt / Δx ^ 2

/-- The grid's down coefficient `a_d = Δt (σ² / (2Δx²) - ν / (2Δx))`. -/
noncomputable def gridDown (r q σ Δt Δx : ℝ) : ℝ :=
  Δt * (σ ^ 2 / (2 * Δx ^ 2) - logDrift r q σ / (2 * Δx))

/-- The explicit difference form of the log-price Black-Scholes equation
`∂V/∂t + ν ∂V/∂x + ½σ² ∂²V/∂x² - rV = 0` at rung `j`: `Vnow` holds the values at step `i`,
`Vnext` those at step `i + 1`; the time derivative is the change over one step, the space
derivatives are the centred first difference and the three-point second difference taken at the
later step, and the rate-times-value term is taken at the earlier step. -/
def ExplicitScheme (r q σ Δt Δx : ℝ) (Vnow Vnext : ℤ → ℝ) (j : ℤ) : Prop :=
  (Vnext j - Vnow j) / Δt
      + logDrift r q σ * (Vnext (j + 1) - Vnext (j - 1)) / (2 * Δx)
      + σ ^ 2 / 2 * (Vnext (j + 1) - 2 * Vnext j + Vnext (j - 1)) / Δx ^ 2
      - r * Vnow j = 0

/-- **The tree is the explicit grid, bar one term** (Why it works, Step 4). For every rate `r`,
dividend yield `q`, volatility `σ`, step `Δt > 0` and spacing `Δx > 0`:
1. the explicit difference equation at a rung holds exactly when the earlier value times
   `1 + rΔt` is `a_d V_{i+1,j-1} + a_m V_{i+1,j} + a_u V_{i+1,j+1}`, the grid's recursion
   (dividing by `1 + rΔt` gives the card's display);
2. the three grid coefficients add to exactly one;
3. each outer tree weight exceeds its grid coefficient by `ν²Δt² / (2Δx²)`, and the middle
   weight falls short by twice that, so the coefficients agree bar that one term;
4. with the spacing written as `Δx = λσ√Δt` (stretch `λ > 0`, written `lam`, and `σ > 0`), that term is
   `ν² / (2λ²σ²)` times `Δt`, so it shrinks in proportion to the step. -/
theorem explicit_grid_is_trinomial_tree_bar_one_term
    (r q σ Δt Δx : ℝ) (hΔt : 0 < Δt) (hΔx : 0 < Δx) :
    (∀ (Vnow Vnext : ℤ → ℝ) (j : ℤ),
        ExplicitScheme r q σ Δt Δx Vnow Vnext j ↔
          (1 + r * Δt) * Vnow j =
            gridDown r q σ Δt Δx * Vnext (j - 1) + gridMid σ Δt Δx * Vnext j
              + gridUp r q σ Δt Δx * Vnext (j + 1)) ∧
      gridUp r q σ Δt Δx + gridMid σ Δt Δx + gridDown r q σ Δt Δx = 1 ∧
      treeUp r q σ Δt Δx - gridUp r q σ Δt Δx = logDrift r q σ ^ 2 * Δt ^ 2 / (2 * Δx ^ 2) ∧
      treeDown r q σ Δt Δx - gridDown r q σ Δt Δx =
        logDrift r q σ ^ 2 * Δt ^ 2 / (2 * Δx ^ 2) ∧
      treeMid r q σ Δt Δx - gridMid σ Δt Δx =
        -2 * (logDrift r q σ ^ 2 * Δt ^ 2 / (2 * Δx ^ 2)) ∧
      (∀ lam : ℝ, 0 < lam → 0 < σ → Δx = lam * σ * √Δt →
        logDrift r q σ ^ 2 * Δt ^ 2 / (2 * Δx ^ 2) =
          logDrift r q σ ^ 2 / (2 * lam ^ 2 * σ ^ 2) * Δt) := by
  have hΔt0 : Δt ≠ 0 := hΔt.ne'
  have hΔx0 : Δx ≠ 0 := hΔx.ne'
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro Vnow Vnext j
    unfold ExplicitScheme
    have key : (Vnext j - Vnow j) / Δt
        + logDrift r q σ * (Vnext (j + 1) - Vnext (j - 1)) / (2 * Δx)
        + σ ^ 2 / 2 * (Vnext (j + 1) - 2 * Vnext j + Vnext (j - 1)) / Δx ^ 2
        - r * Vnow j =
        ((gridDown r q σ Δt Δx * Vnext (j - 1) + gridMid σ Δt Δx * Vnext j
              + gridUp r q σ Δt Δx * Vnext (j + 1)) - (1 + r * Δt) * Vnow j) / Δt := by
      unfold gridDown gridMid gridUp
      field_simp
      ring
    rw [key, div_eq_zero_iff, sub_eq_zero]
    constructor
    · rintro (h | h)
      · exact h.symm
      · exact absurd h hΔt0
    · intro h
      exact Or.inl h.symm
  · unfold gridUp gridMid gridDown
    field_simp
    ring
  · unfold treeUp gridUp spreadTerm tiltTerm
    field_simp
    ring
  · unfold treeDown gridDown spreadTerm tiltTerm
    field_simp
    ring
  · unfold treeMid gridMid spreadTerm
    field_simp
    ring
  · intro lam hlam hσ hx
    have hsq : Δx ^ 2 = lam ^ 2 * σ ^ 2 * Δt := by
      rw [hx, mul_pow, mul_pow, Real.sq_sqrt hΔt.le]
    rw [hsq]
    have : lam ≠ 0 := hlam.ne'
    have : σ ≠ 0 := hσ.ne'
    field_simp

/-- **Three weights, three jobs, the spacing left free** (Steps 0, 1, 2 and 5; When it holds).
For every rate `r`, dividend yield `q`, volatility `σ`, step `Δt > 0` and spacing `Δx > 0`:
1. the tree's weights add to one, match one step's average log-move,
   `(p_u - p_d) Δx = νΔt`, and its average square, `(p_u + p_d) Δx² = σ²Δt + ν²Δt²`;
2. they are the only three numbers that do, whatever the spacing, so the spacing is a free choice;
3. the middle weight is non-negative exactly when `Δx² ≥ σ²Δt + ν²Δt²`;
4. when the drift `ν` is positive, the down weight is non-negative exactly when
   `Δx ≤ (σ² + ν²Δt) / ν`;
5. the grid's middle coefficient is non-negative exactly when `σ²Δt ≤ Δx²`, the explicit scheme's
   stability condition `Δt ≤ Δx² / σ²`. -/
theorem trinomial_weights_match_one_step_for_any_spacing
    (r q σ Δt Δx : ℝ) (hΔt : 0 < Δt) (hΔx : 0 < Δx) :
    (treeUp r q σ Δt Δx + treeMid r q σ Δt Δx + treeDown r q σ Δt Δx = 1 ∧
      (treeUp r q σ Δt Δx - treeDown r q σ Δt Δx) * Δx = logDrift r q σ * Δt ∧
      (treeUp r q σ Δt Δx + treeDown r q σ Δt Δx) * Δx ^ 2 =
        σ ^ 2 * Δt + logDrift r q σ ^ 2 * Δt ^ 2) ∧
      (∀ pu pm pd : ℝ, pu + pm + pd = 1 → (pu - pd) * Δx = logDrift r q σ * Δt →
        (pu + pd) * Δx ^ 2 = σ ^ 2 * Δt + logDrift r q σ ^ 2 * Δt ^ 2 →
        pu = treeUp r q σ Δt Δx ∧ pm = treeMid r q σ Δt Δx ∧ pd = treeDown r q σ Δt Δx) ∧
      (0 ≤ treeMid r q σ Δt Δx ↔ σ ^ 2 * Δt + logDrift r q σ ^ 2 * Δt ^ 2 ≤ Δx ^ 2) ∧
      (0 < logDrift r q σ →
        (0 ≤ treeDown r q σ Δt Δx ↔
          Δx ≤ (σ ^ 2 + logDrift r q σ ^ 2 * Δt) / logDrift r q σ)) ∧
      (0 ≤ gridMid σ Δt Δx ↔ σ ^ 2 * Δt ≤ Δx ^ 2) := by
  have hΔt0 : Δt ≠ 0 := hΔt.ne'
  have hΔx0 : Δx ≠ 0 := hΔx.ne'
  have hΔx2 : 0 < Δx ^ 2 := by positivity
  refine ⟨⟨?_, ?_, ?_⟩, ?_, ?_, ?_, ?_⟩
  · unfold treeUp treeMid treeDown
    ring
  · unfold treeUp treeDown tiltTerm
    field_simp
    ring
  · unfold treeUp treeDown spreadTerm
    field_simp
    ring
  · intro pu pm pd h1 h2 h3
    have e2 : pu - pd = tiltTerm r q σ Δt Δx := by
      unfold tiltTerm
      rw [eq_div_iff hΔx0]
      exact h2
    have e3 : pu + pd = spreadTerm r q σ Δt Δx := by
      unfold spreadTerm
      rw [eq_div_iff hΔx2.ne']
      exact h3
    refine ⟨?_, ?_, ?_⟩
    · unfold treeUp
      linarith
    · unfold treeMid
      linarith
    · unfold treeDown
      linarith
  · unfold treeMid spreadTerm
    rw [sub_nonneg, div_le_one hΔx2]
  · intro hν
    unfold treeDown spreadTerm tiltTerm
    rw [le_div_iff₀ hν]
    have e : (σ ^ 2 * Δt + logDrift r q σ ^ 2 * Δt ^ 2) / Δx ^ 2 - logDrift r q σ * Δt / Δx
        = Δt * ((σ ^ 2 + logDrift r q σ ^ 2 * Δt) - Δx * logDrift r q σ) / Δx ^ 2 := by
      field_simp
    rw [e]
    constructor
    · intro h
      have h' : 0 ≤ Δt * ((σ ^ 2 + logDrift r q σ ^ 2 * Δt) - Δx * logDrift r q σ) / Δx ^ 2 := by
        linarith
      have h'' : 0 ≤ Δt * ((σ ^ 2 + logDrift r q σ ^ 2 * Δt) - Δx * logDrift r q σ) := by
        have := mul_nonneg h' hΔx2.le
        rwa [div_mul_cancel₀ _ hΔx2.ne'] at this
      have := (mul_nonneg_iff_of_pos_left hΔt).mp h''
      linarith
    · intro h
      have : 0 ≤ Δt * ((σ ^ 2 + logDrift r q σ ^ 2 * Δt) - Δx * logDrift r q σ) / Δx ^ 2 := by
        apply div_nonneg _ hΔx2.le
        apply mul_nonneg hΔt.le
        linarith
      linarith
  · unfold gridMid
    rw [sub_nonneg, div_le_one hΔx2]

/-- **In log-price the Black-Scholes equation has constant coefficients** (Step 4, the change of
variable). Let `W t x` be the option's value as a function of time and log-price, twice
continuously differentiable in log-price, and `V t S = W t (log S)` the same value as a function
of the price. Then at every price `S > 0` the Black-Scholes expression
`∂V/∂t + (r - q) S ∂V/∂S + ½σ² S² ∂²V/∂S² - rV` equals
`∂W/∂t + ν ∂W/∂x + ½σ² ∂²W/∂x² - rW` at `x = log S`. -/
theorem black_scholes_in_log_price (r q σ : ℝ) (W : ℝ → ℝ → ℝ)
    (hW : ∀ t, ContDiff ℝ 2 (W t)) (t S : ℝ) (hS : 0 < S) :
    deriv (fun s => W s (Real.log S)) t
        + (r - q) * S * deriv (fun y => W t (Real.log y)) S
        + σ ^ 2 / 2 * S ^ 2 * deriv (deriv (fun y => W t (Real.log y))) S
        - r * W t (Real.log S) =
      deriv (fun s => W s (Real.log S)) t
        + logDrift r q σ * deriv (W t) (Real.log S)
        + σ ^ 2 / 2 * deriv (deriv (W t)) (Real.log S)
        - r * W t (Real.log S) := by
  have hS0 : S ≠ 0 := hS.ne'
  have hd : Differentiable ℝ (W t) :=
    (hW t).differentiable (by norm_num)
  have hd2 : Differentiable ℝ (deriv (W t)) := by
    have h2 := hW t
    rw [show (2 : WithTop ℕ∞) = 1 + 1 from rfl, contDiff_succ_iff_deriv] at h2
    exact h2.2.2.differentiable one_ne_zero
  have h1 : ∀ y : ℝ, 0 < y → deriv (fun y => W t (Real.log y)) y = deriv (W t) (Real.log y) * y⁻¹ := by
    intro y hy
    have := ((hd (Real.log y)).hasDerivAt.comp y (Real.hasDerivAt_log hy.ne'))
    exact this.deriv
  have hev : (deriv (fun y => W t (Real.log y))) =ᶠ[nhds S] (fun y => deriv (W t) (Real.log y) * y⁻¹) := by
    filter_upwards [lt_mem_nhds hS] with y hy
    exact h1 y hy
  have h2 : deriv (deriv (fun y => W t (Real.log y))) S =
      deriv (deriv (W t)) (Real.log S) * S⁻¹ * S⁻¹ + deriv (W t) (Real.log S) * (-(S ^ 2)⁻¹) := by
    rw [hev.deriv_eq]
    have ha := ((hd2 (Real.log S)).hasDerivAt.comp S (Real.hasDerivAt_log hS0))
    have hb := hasDerivAt_inv hS0
    exact (ha.mul hb).deriv
  rw [h1 S hS, h2]
  unfold logDrift
  field_simp
  ring

/-! The card's worked numbers. Acme: r = 5/100, q = 2/100, σ = 1/5, one year. -/

-- The log drift: ν = 0.05 - 0.02 - ½ · 0.04 = 0.01.
example : logDrift (1 / 20) (1 / 50) (1 / 5) = 1 / 100 := by unfold logDrift; norm_num

-- Three steps at the desk's stretch √3: Δx = √3 · 0.20 · √(1/3) = 0.2 exactly.
example : √3 * (1 / 5) * √(1 / 3) = (1 / 5 : ℝ) := by
  rw [mul_right_comm, ← Real.sqrt_mul (by norm_num)]
  norm_num

-- Three steps, Δt = 1/3, Δx = 1/5: spread term 1201/3600 = 0.333611, tilt term 1/60 = 0.016667.
example : spreadTerm (1 / 20) (1 / 50) (1 / 5) (1 / 3) (1 / 5) = 1201 / 3600 := by
  unfold spreadTerm logDrift; norm_num
example : tiltTerm (1 / 20) (1 / 50) (1 / 5) (1 / 3) (1 / 5) = 1 / 60 := by
  unfold tiltTerm logDrift; norm_num

-- The three-step weights: p_u = 1261/7200 = 0.175139, p_m = 2399/3600 = 0.666389,
-- p_d = 1141/7200 = 0.158472.
example : treeUp (1 / 20) (1 / 50) (1 / 5) (1 / 3) (1 / 5) = 1261 / 7200 := by
  unfold treeUp spreadTerm tiltTerm logDrift; norm_num
example : treeMid (1 / 20) (1 / 50) (1 / 5) (1 / 3) (1 / 5) = 2399 / 3600 := by
  unfold treeMid spreadTerm logDrift; norm_num
example : treeDown (1 / 20) (1 / 50) (1 / 5) (1 / 3) (1 / 5) = 1141 / 7200 := by
  unfold treeDown spreadTerm tiltTerm logDrift; norm_num

-- Where the three-step tree lands: rung +3 has weight p_u³ = 0.005372 and rung 0 has weight
-- p_m³ + 6 p_u p_m p_d = 0.406898, each to six decimals.
example : (5371.5 : ℚ) / 10 ^ 6 ≤ (1261 / 7200) ^ 3 ∧ (1261 / 7200 : ℚ) ^ 3 < 5372.5 / 10 ^ 6 := by
  norm_num
example : (406897.5 : ℚ) / 10 ^ 6 ≤ (2399 / 3600) ^ 3 + 6 * (1261 / 7200) * (2399 / 3600) * (1141 / 7200) ∧
    (2399 / 3600 : ℚ) ^ 3 + 6 * (1261 / 7200) * (2399 / 3600) * (1141 / 7200) < 406898.5 / 10 ^ 6 := by
  norm_num

-- Stretch 1 at three steps (Δx² = σ²Δt = 1/75): the middle weight is -1/1200 = -0.000833.
example : 1 - ((1 / 5 : ℚ) ^ 2 * (1 / 3) + (1 / 100) ^ 2 * (1 / 3) ^ 2) / (1 / 75) = -1 / 1200 := by
  norm_num

-- Stretch 0.8 at three steps (Δx² = 0.64 · 1/75): the middle weight is -433/768 = -0.563802.
example : 1 - ((1 / 5 : ℚ) ^ 2 * (1 / 3) + (1 / 100) ^ 2 * (1 / 3) ^ 2) / (64 / 100 * (1 / 75)) =
    -433 / 768 := by
  norm_num

-- The middle weight vanishes at λ² = 1201/1200, so λ = 1.000417 at three steps.
example : 1 - ((1 / 5 : ℚ) ^ 2 * (1 / 3) + (1 / 100) ^ 2 * (1 / 3) ^ 2) /
    (1201 / 1200 * (1 / 5) ^ 2 * (1 / 3)) = 0 := by
  norm_num

-- 200 steps at stretch √3 (Δt = 1/200, Δx² = 3/5000): the gap ν²Δt²/(2Δx²) is 1/480000
-- = 0.000002083, the tree's middle weight is 53333/80000 = 0.666662500, the grid's is 2/3.
example : (1 / 100 : ℚ) ^ 2 * (1 / 200) ^ 2 / (2 * (3 / 5000)) = 1 / 480000 := by norm_num
example : 1 - ((1 / 5 : ℚ) ^ 2 * (1 / 200) + (1 / 100) ^ 2 * (1 / 200) ^ 2) / (3 / 5000) =
    53333 / 80000 := by
  norm_num
example : 1 - (1 / 5 : ℚ) ^ 2 * (1 / 200) / (3 / 5000) = 2 / 3 := by norm_num

#print axioms explicit_grid_is_trinomial_tree_bar_one_term
#print axioms trinomial_weights_match_one_step_for_any_spacing
#print axioms black_scholes_in_log_price

end TrinomialTree
