-- Transmission lines: at a load the reflected wave is the fraction Γ = (Z_L − Z₀)/(Z_L + Z₀) of the incident one, a passive load never gives |Γ| above 1, and the two waves together make the line look like Z₀ (Z_L + jZ₀ tan βℓ)/(Z₀ + jZ_L tan βℓ) from its input.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination

open Complex

/-! A lossless line has a real, positive characteristic impedance `Z₀ = √(L/C)`. At a steady
frequency the line carries an incident wave of complex amplitude `V⁺` and a reflected wave `V⁻`.
At the load the voltage is `V⁺ + V⁻` and the current is `(V⁺ − V⁻)/Z₀`. Here `j` is written
`Complex.I`. -/

/-- Step 4. The reflected wave fixes the mismatch. On a line with characteristic impedance
`Z₀ > 0`, let the incident wave `V⁺` be nonzero and the load `Z_L` satisfy `Z_L + Z₀ ≠ 0`. If the
load's rule "voltage equals `Z_L` times current" holds at the end of the line,
`V⁺ + V⁻ = Z_L (V⁺ − V⁻)/Z₀`, then the reflected wave is the fixed fraction
`Γ = V⁻/V⁺ = (Z_L − Z₀)/(Z_L + Z₀)` of the incident wave. -/
theorem reflection_coefficient_at_load (Z₀ : ℝ) (hZ₀ : 0 < Z₀) (ZL Vp Vm : ℂ)
    (hVp : Vp ≠ 0) (hsum : ZL + Z₀ ≠ 0)
    (hload : Vp + Vm = ZL * ((Vp - Vm) / Z₀)) :
    Vm / Vp = (ZL - Z₀) / (ZL + Z₀) := by
  have hZ : (Z₀ : ℂ) ≠ 0 := by exact_mod_cast hZ₀.ne'
  have h : (Z₀ : ℂ) * (Vp + Vm) = ZL * (Vp - Vm) := by
    rw [hload]; field_simp
  rw [div_eq_div_iff hVp hsum]
  linear_combination h

/-- A passive load never sends back more than it gets. With `Z₀ > 0` and a load with
`Re Z_L ≥ 0`, the reflection coefficient has `|Γ| ≤ 1`, and `|Γ| = 1` exactly when
`Re Z_L = 0` (a short, an open, or a pure coil or capacitor). -/
theorem passive_load_reflection_le_one (Z₀ : ℝ) (hZ₀ : 0 < Z₀) (ZL : ℂ) (hpass : 0 ≤ ZL.re) :
    ‖(ZL - Z₀) / (ZL + Z₀)‖ ≤ 1 ∧ (‖(ZL - Z₀) / (ZL + Z₀)‖ = 1 ↔ ZL.re = 0) := by
  have hsq : normSq (ZL - Z₀) + 4 * ZL.re * Z₀ = normSq (ZL + Z₀) := by
    simp only [normSq_apply, sub_re, add_re, sub_im, add_im, ofReal_re, ofReal_im]
    ring
  have hpos : 0 < ‖ZL + Z₀‖ := by
    rw [norm_pos_iff]
    intro h
    have := congrArg Complex.re h
    simp at this
    linarith
  rw [norm_div]
  constructor
  · rw [div_le_one hpos, norm_def, norm_def]
    apply Real.sqrt_le_sqrt
    nlinarith
  · rw [div_eq_one_iff_eq hpos.ne', norm_def, norm_def]
    constructor
    · intro h
      have h2 := congrArg (fun x => x ^ 2) h
      rw [Real.sq_sqrt (normSq_nonneg _), Real.sq_sqrt (normSq_nonneg _)] at h2
      have : ZL.re * Z₀ = 0 := by linarith
      rcases mul_eq_zero.mp this with h | h
      · exact h
      · exact absurd h hZ₀.ne'
    · intro h
      rw [← hsq, h]
      simp

/-- Step 6. The input impedance. A line of characteristic impedance `Z₀ > 0` ends in a load
`Z_L` with `Z_L + Z₀ ≠ 0`, so `Γ = (Z_L − Z₀)/(Z_L + Z₀)`. At electrical length `βℓ` back from
the load, voltage over current is `Z₀ (1 + Γe^{−2jβℓ})/(1 − Γe^{−2jβℓ})`. Where that is finite
(`1 − Γe^{−2jβℓ} ≠ 0`) and `cos βℓ ≠ 0`, it equals the card's tan form
`Z₀ (Z_L + jZ₀ tan βℓ)/(Z₀ + jZ_L tan βℓ)`. -/
theorem input_impedance_tan_form (Z₀ : ℝ) (hZ₀ : 0 < Z₀) (ZL : ℂ) (hsum : ZL + Z₀ ≠ 0)
    (β ℓ : ℝ) (hcos : Real.cos (β * ℓ) ≠ 0)
    (hfin : 1 - (ZL - Z₀) / (ZL + Z₀) * Complex.exp (-2 * I * (β * ℓ)) ≠ 0) :
    (Z₀ : ℂ) * ((1 + (ZL - Z₀) / (ZL + Z₀) * Complex.exp (-2 * I * (β * ℓ))) /
        (1 - (ZL - Z₀) / (ZL + Z₀) * Complex.exp (-2 * I * (β * ℓ)))) =
      Z₀ * ((ZL + I * Z₀ * (Real.tan (β * ℓ) : ℂ)) / (Z₀ + I * ZL * (Real.tan (β * ℓ) : ℂ))) := by
  clear hZ₀
  have e : (β : ℂ) * (ℓ : ℂ) = ((β * ℓ : ℝ) : ℂ) := by push_cast; ring
  rw [e] at hfin ⊢
  generalize β * ℓ = θ at *
  set E := Complex.exp (-2 * I * (θ : ℂ)) with hEdef
  set Γ := (ZL - Z₀) / (ZL + Z₀) with hΓdef
  set c : ℂ := (Real.cos θ : ℂ) with hc
  set s : ℂ := (Real.sin θ : ℂ) with hs
  set t : ℂ := (Real.tan θ : ℂ) with ht
  have hc0 : c ≠ 0 := ofReal_ne_zero.mpr hcos
  have hT : t * c = s := by
    rw [ht, Real.tan_eq_sin_div_cos, ofReal_div, ← hc, ← hs]; field_simp
  have hexp : Complex.exp ((θ : ℂ) * I) = c + s * I := by
    rw [Complex.exp_mul_I, hc, hs, ← ofReal_cos, ← ofReal_sin]
  have hexpn : Complex.exp (-((θ : ℂ) * I)) = c - s * I := by
    rw [← neg_mul, ← ofReal_neg, Complex.exp_mul_I, hc, hs, ofReal_neg, Complex.cos_neg,
      Complex.sin_neg, ← ofReal_cos, ← ofReal_sin]; ring
  have hE : E * (c + s * I) = c - s * I := by
    rw [← hexp, ← hexpn, hEdef, ← Complex.exp_add]; congr 1; ring
  have hcs : c + s * I ≠ 0 := by rw [← hexp]; exact Complex.exp_ne_zero _
  have hΓ : Γ * (ZL + Z₀) = ZL - Z₀ := by rw [hΓdef]; field_simp
  have hK : (ZL + Z₀) * (c + s * I) ≠ 0 := mul_ne_zero hsum hcs
  -- key identities
  have hA : (ZL + Z₀) * (c + s * I) * (1 + Γ * E) = 2 * c * (ZL + I * Z₀ * t) := by
    linear_combination (c + s * I) * E * hΓ + (ZL - Z₀) * hE - 2 * I * Z₀ * hT
  have hB : (ZL + Z₀) * (c + s * I) * (1 - Γ * E) = 2 * c * (Z₀ + I * ZL * t) := by
    linear_combination -(c + s * I) * E * hΓ - (ZL - Z₀) * hE - 2 * I * ZL * hT
  have hD : (Z₀ + I * ZL * t) ≠ 0 := by
    intro h0
    apply hK
    have := hB
    rw [h0, mul_zero] at this
    exact (mul_eq_zero.mp this).resolve_right hfin
  congr 1
  rw [div_eq_div_iff hfin hD]
  apply mul_left_cancel₀ hK
  linear_combination (Z₀ + I * ZL * t) * hA - (ZL + I * Z₀ * t) * hB

-- The radio's antenna lead: 50 Ω coax into a 75 Ω antenna gives Γ = 25/125 = 1/5.
example : ((75 : ℚ) - 50) / (75 + 50) = 1 / 5 := by norm_num
-- Standing-wave ratio 1.2/0.8 = 3/2.
example : (1 + (1 : ℚ) / 5) / (1 - 1 / 5) = 3 / 2 := by norm_num
-- Reflected power fraction Γ² = 1/25 = 4%.
example : ((1 : ℚ) / 5) ^ 2 = 4 / 100 := by norm_num
-- Antenna voltage 0.50 × 1.2 = 0.60 V and the low point 0.50 × 0.8 = 0.40 V.
example : (1 : ℚ) / 2 * (1 + 1 / 5) = 3 / 5 ∧ (1 : ℚ) / 2 * (1 - 1 / 5) = 2 / 5 := by norm_num
-- Power: incident 0.5²/(2·50) = 2.5 mW, delivered 0.6²/(2·75) = 2.4 mW, 96% of it.
example : ((3 : ℚ) / 5) ^ 2 / (2 * 75) = (1 - 4 / 100) * (((1 : ℚ) / 2) ^ 2 / (2 * 50)) := by norm_num
-- Three-quarter-wave lead: Z_in = Z₀²/Z_L = 2500/75 = 100/3 Ω, and the set sees 1 V × (100/3)/(100/3 + 50) = 0.4 V.
example : (50 : ℚ) ^ 2 / 75 = 100 / 3 ∧ ((100 : ℚ) / 3) / (100 / 3 + 50) = 2 / 5 := by norm_num
-- Matched load gives Γ = 0, a short gives −1.
example : ((50 : ℚ) - 50) / (50 + 50) = 0 ∧ ((0 : ℚ) - 50) / (0 + 50) = -1 := by norm_num

#print axioms reflection_coefficient_at_load
#print axioms passive_load_reflection_le_one
#print axioms input_impedance_tan_form
