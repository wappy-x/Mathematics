-- SABR from three quotes: at exponent 1 the at-the-money equation is a quadratic in the level whose small positive root, 2σ/(c₁ + √(c₁² + 4c₂σ)), is the one rising-side fit (the only positive one when the correlation is not negative), c₁ stays positive while ν²T is below 24, and χ is the integral of 1/√(1 - 2ρs + s²).
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity

/-! The setting, SABR with exponent `β = 1`. `α` is the level, `ρ` the correlation, `ν` the
volatility of volatility, `T` the years to expiry and `σ` the at-the-money quote, struck at the
forward. At the forward `z = 0` and the smile factor `z/χ(z)` is 1, so Hagan's implied volatility
there is `α (1 + [ρνα/4 + (2 - 3ρ²)ν²/24] T)`, which multiplies out to `c₁ α + c₂ α²` with
`c₁ = 1 + (2 - 3ρ²)ν²T/24` and `c₂ = ρνT/4`. -/

/-- The coefficient `c₁ = 1 + (2 - 3ρ²) ν² T / 24` of the at-the-money equation. -/
noncomputable def atmC1 (ρ ν T : ℝ) : ℝ := 1 + (2 - 3 * ρ ^ 2) * ν ^ 2 * T / 24

/-- The coefficient `c₂ = ρ ν T / 4` of the at-the-money equation. -/
noncomputable def atmC2 (ρ ν T : ℝ) : ℝ := ρ * ν * T / 4

/-- Hagan's implied volatility at the forward, `β = 1`: the level times the time factor. -/
noncomputable def haganATM (α ρ ν T : ℝ) : ℝ :=
  α * (1 + (ρ * ν * α / 4 + (2 - 3 * ρ ^ 2) * ν ^ 2 / 24) * T)

/-- Hagan's `χ(z) = ln((√(1 - 2ρz + z²) + z - ρ) / (1 - ρ))`. -/
noncomputable def sabrChi (ρ z : ℝ) : ℝ :=
  Real.log ((Real.sqrt (1 - 2 * ρ * z + z ^ 2) + z - ρ) / (1 - ρ))

lemma sabr_Q_pos (ρ z : ℝ) (hρ : -1 < ρ ∧ ρ < 1) : 0 < 1 - 2 * ρ * z + z ^ 2 := by
  nlinarith [sq_nonneg (z - ρ), mul_pos (by linarith : (0:ℝ) < 1 - ρ) (by linarith : (0:ℝ) < 1 + ρ)]

lemma sabr_g_pos (ρ z : ℝ) (hρ : -1 < ρ ∧ ρ < 1) :
    0 < Real.sqrt (1 - 2 * ρ * z + z ^ 2) + z - ρ := by
  have hQ := sabr_Q_pos ρ z hρ
  have h1 := Real.sq_sqrt hQ.le
  have h2 := Real.sqrt_nonneg (1 - 2 * ρ * z + z ^ 2)
  have h3 : 0 < (1 - ρ) * (1 + ρ) := mul_pos (by linarith) (by linarith)
  by_contra h
  push Not at h
  nlinarith

lemma sabr_chi_hasDerivAt (ρ z : ℝ) (hρ : -1 < ρ ∧ ρ < 1) :
    HasDerivAt (sabrChi ρ) (1 / Real.sqrt (1 - 2 * ρ * z + z ^ 2)) z := by
  have hQ := sabr_Q_pos ρ z hρ
  have hg := sabr_g_pos ρ z hρ
  have hr : 0 < Real.sqrt (1 - 2 * ρ * z + z ^ 2) := Real.sqrt_pos.2 hQ
  have h1ρ : (1 - ρ) ≠ 0 := by linarith [hρ.2]
  have h1 : HasDerivAt (fun s : ℝ => 2 * ρ * s) (2 * ρ) z := by
    simpa using (hasDerivAt_id' z).const_mul (2 * ρ)
  have h2 : HasDerivAt (fun s : ℝ => s ^ 2) (2 * z) z := by
    simpa using hasDerivAt_pow 2 z
  have hQd : HasDerivAt (fun s : ℝ => 1 - 2 * ρ * s + s ^ 2) (-(2 * ρ) + 2 * z) z := by
    have := (h1.const_sub 1).add h2
    convert this using 1
  have hsd := hQd.sqrt hQ.ne'
  have hgd := ((hsd.add (hasDerivAt_id' z)).sub_const ρ).div_const (1 - ρ)
  have hld := hgd.log (div_ne_zero hg.ne' h1ρ)
  simp only [Pi.add_apply] at hld
  unfold sabrChi
  convert hld using 1
  have hg' := hg.ne'
  have hr' := hr.ne'
  field_simp
  ring

#print axioms sabr_Q_pos
#print axioms sabr_g_pos
#print axioms sabr_chi_hasDerivAt

lemma atmC1_pos_aux (ρ ν T : ℝ) (hρ : -1 ≤ ρ ∧ ρ ≤ 1) (hT : 0 ≤ T) (hνT : ν ^ 2 * T < 24) :
    0 < atmC1 ρ ν T := by
  unfold atmC1
  have hρ2 : ρ ^ 2 ≤ 1 := by nlinarith
  have hA : 0 ≤ ν ^ 2 * T := mul_nonneg (sq_nonneg _) hT
  nlinarith [mul_nonneg (by nlinarith : (0:ℝ) ≤ 3 - 3 * ρ ^ 2) hA]

#print axioms atmC1_pos_aux

/-- **Alpha from the at-the-money quote: the small positive root** (The formula; Why it works,
Step 1 and its detailed proof). Fix the exponent at 1, take a correlation strictly inside −1 to 1,
a volatility of volatility `ν ≥ 0`, an expiry `T > 0` with `ν²T` below 24, and a positive
at-the-money quote `σ` that is reachable: when `c₂ < 0` it sits at or below the ceiling
`c₁² / (4|c₂|)`. Then the level `α₀ = 2σ / (c₁ + √(c₁² + 4c₂σ))` is positive, makes Hagan's
at-the-money volatility equal the quote, and sits on the rising side of the curve
(slope `c₁ + 2c₂α₀ ≥ 0`). It is the only positive root on the rising side, it is the smallest
positive root, and when `ρ ≥ 0` it is the only positive root at all. -/
theorem sabr_atm_level_is_small_root
    (ρ ν T σ : ℝ) (hρ : -1 < ρ ∧ ρ < 1) (hν : 0 ≤ ν) (hT : 0 < T) (hνT : ν ^ 2 * T < 24)
    (hσ : 0 < σ)
    (hreach : atmC2 ρ ν T < 0 → σ ≤ atmC1 ρ ν T ^ 2 / (4 * -atmC2 ρ ν T)) :
    let α₀ := 2 * σ / (atmC1 ρ ν T + Real.sqrt (atmC1 ρ ν T ^ 2 + 4 * atmC2 ρ ν T * σ))
    0 < α₀ ∧ haganATM α₀ ρ ν T = σ ∧ 0 ≤ atmC1 ρ ν T + 2 * atmC2 ρ ν T * α₀ ∧
      (∀ α, 0 < α → haganATM α ρ ν T = σ → 0 ≤ atmC1 ρ ν T + 2 * atmC2 ρ ν T * α → α = α₀) ∧
      (∀ α, 0 < α → haganATM α ρ ν T = σ → α₀ ≤ α) ∧
      (0 ≤ ρ → ∀ α, 0 < α → haganATM α ρ ν T = σ → α = α₀) := by
  have hH : ∀ α, haganATM α ρ ν T = atmC1 ρ ν T * α + atmC2 ρ ν T * α ^ 2 := by
    intro α; unfold haganATM atmC1 atmC2; ring
  have hc1pos := atmC1_pos_aux ρ ν T ⟨hρ.1.le, hρ.2.le⟩ hT.le hνT
  have hc2nn : 0 ≤ ρ → 0 ≤ atmC2 ρ ν T := fun h => by unfold atmC2; positivity
  intro α₀
  simp only [hH]
  set c1 := atmC1 ρ ν T
  set c2 := atmC2 ρ ν T
  have hD : 0 ≤ c1 ^ 2 + 4 * c2 * σ := by
    by_cases h : c2 < 0
    · have := hreach h
      rw [le_div_iff₀ (by linarith)] at this
      nlinarith
    · push Not at h; positivity
  have hs0 : 0 ≤ Real.sqrt (c1 ^ 2 + 4 * c2 * σ) := Real.sqrt_nonneg _
  have hss : Real.sqrt (c1 ^ 2 + 4 * c2 * σ) ^ 2 = c1 ^ 2 + 4 * c2 * σ := Real.sq_sqrt hD
  have hα₀ : α₀ * (c1 + Real.sqrt (c1 ^ 2 + 4 * c2 * σ)) = 2 * σ := by
    show 2 * σ / (c1 + Real.sqrt (c1 ^ 2 + 4 * c2 * σ)) * (c1 + Real.sqrt (c1 ^ 2 + 4 * c2 * σ))
      = 2 * σ
    field_simp
  clear_value α₀
  set r := Real.sqrt (c1 ^ 2 + 4 * c2 * σ)
  have hden : 0 < c1 + r := by linarith
  have hα₀pos : 0 < α₀ := by
    by_contra h
    push Not at h
    nlinarith
  have hslope : c1 + 2 * c2 * α₀ = r := by
    have h : (c1 + 2 * c2 * α₀ - r) * (c1 + r) = 0 := by
      linear_combination (2 * c2) * hα₀ - hss
    rcases mul_eq_zero.1 h with h | h
    · linarith
    · linarith
  have hroot : c1 * α₀ + c2 * α₀ ^ 2 = σ := by
    linear_combination (α₀ / 2) * hslope + (1 / 2) * hα₀
  have hsq : ∀ α, c1 * α + c2 * α ^ 2 = σ → (c1 + 2 * c2 * α) ^ 2 = r ^ 2 := by
    intro α h
    rw [hss]
    linear_combination (4 * c2) * h
  have huniq : ∀ α, 0 < α → c1 * α + c2 * α ^ 2 = σ → 0 ≤ c1 + 2 * c2 * α → α = α₀ := by
    intro α hα h hsl
    have heq : c1 + 2 * c2 * α = r := by
      have := hsq α h
      nlinarith
    have : α * (c1 + r) = α₀ * (c1 + r) := by
      rw [hα₀]
      linear_combination (2 : ℝ) * h - α * heq
    exact (mul_right_cancel₀ hden.ne' this)
  refine ⟨hα₀pos, hroot, by rw [hslope]; exact hs0, huniq, ?_, ?_⟩
  · intro α hα h
    have hle : c1 + 2 * c2 * α ≤ r := by
      have := hsq α h
      nlinarith
    have : α₀ * (c1 + r) ≤ α * (c1 + r) := by
      rw [hα₀]
      nlinarith
    exact le_of_mul_le_mul_right this hden
  · intro hρ0 α hα h
    have := hc2nn hρ0
    exact huniq α hα h (by positivity)

/-- **`c₁` stays positive while `ν²T` is below 24** (When it holds; Step 1, detailed proof).
For every correlation in `[-1, 1]` and every expiry `T ≥ 0`, if `ν²T < 24` then
`c₁ = 1 + (2 - 3ρ²)ν²T/24 > 0`, since `2 - 3ρ² ≥ -1`. -/
theorem atm_c1_pos_of_nu_sq_T_lt_24
    (ρ ν T : ℝ) (hρ : -1 ≤ ρ ∧ ρ ≤ 1) (hT : 0 ≤ T) (hνT : ν ^ 2 * T < 24) :
    0 < atmC1 ρ ν T := by
  unfold atmC1
  have hρ2 : ρ ^ 2 ≤ 1 := by nlinarith
  have hA : 0 ≤ ν ^ 2 * T := mul_nonneg (sq_nonneg _) hT
  nlinarith [mul_nonneg (by nlinarith : (0:ℝ) ≤ 3 - 3 * ρ ^ 2) hA]

/-- **`χ` is the integral of `1/√(1 - 2ρs + s²)` from 0 to `z`** (The formula, symbol table;
the code's Simpson check). For every correlation strictly inside −1 to 1 and every `z`, the
closed form `χ(z) = ln((√(1 - 2ρz + z²) + z - ρ)/(1 - ρ))` equals
`∫₀^z ds / √(1 - 2ρs + s²)`. -/
theorem sabr_chi_eq_integral
    (ρ z : ℝ) (hρ : -1 < ρ ∧ ρ < 1) :
    ∫ s in (0 : ℝ)..z, 1 / Real.sqrt (1 - 2 * ρ * s + s ^ 2) = sabrChi ρ z := by
  have hcont : Continuous (fun s : ℝ => 1 / Real.sqrt (1 - 2 * ρ * s + s ^ 2)) :=
    Continuous.div continuous_const (by fun_prop)
      (fun x => (Real.sqrt_pos.2 (sabr_Q_pos ρ x hρ)).ne')
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (fun x _ => sabr_chi_hasDerivAt ρ x hρ) (hcont.intervalIntegrable _ _)]
  have h1ρ : (1 - ρ) ≠ 0 := by linarith [hρ.2]
  have h0 : sabrChi ρ 0 = 0 := by
    simp [sabrChi, div_self h1ρ]
  rw [h0, sub_zero]

-- Step 0: the three quotes 24%, 20%, 18% give a risk reversal of 18 - 24 = -6 volatility points
-- and a butterfly of (24 + 18)/2 - 20 = 1 point.
example : (18 : ℤ) - 24 = -6 := by norm_num
example : ((24 : ℚ) + 18) / 2 - 20 = 1 := by norm_num

-- Step 3: 35 restarts, seven correlations times five volatilities of volatility.
example : (7 : ℕ) * 5 = 35 := by norm_num

-- Step 1, the edge case: with ν = 0 SABR is Black's model and the small root is the quote itself.
example (ρ T σ : ℝ) (hσ : 0 < σ) :
    2 * σ / (atmC1 ρ 0 T + Real.sqrt (atmC1 ρ 0 T ^ 2 + 4 * atmC2 ρ 0 T * σ)) = σ := by
  norm_num [atmC1, atmC2]

#print axioms sabr_atm_level_is_small_root
#print axioms atm_c1_pos_of_nu_sq_T_lt_24
#print axioms sabr_chi_eq_integral
