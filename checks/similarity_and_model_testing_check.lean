-- Similarity: if a model and the full-size body obey the same drag law C_D = φ(Re, Ma) and have equal Reynolds and Mach numbers, the full-size drag is the model drag times ρ_p U_p² D_p² / (ρ_m U_m² D_m²), and both groups can be matched only when ν_m/ν_p = λ c_m/c_p.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

open Real

/-- Similarity: a model and a full-size body of the same shape share one drag law
`C_D = F / (½ ρ U² (π D²/4)) = φ(Re, Ma)` with `Re = ρ U D / μ` and `Ma = U / c`.
If the model's Reynolds number and Mach number equal the full-size ones, then the
full-size drag is the model's drag times `ρ_p U_p² D_p² / (ρ_m U_m² D_m²)`.
Nothing about the shape of `φ` is used. -/
theorem drag_scales_when_groups_matched (φ : ℝ → ℝ → ℝ)
    (F_m F_p ρ_m ρ_p U_m U_p D_m D_p μ_m μ_p c_m c_p : ℝ)
    (hρm : 0 < ρ_m) (hUm : 0 < U_m) (hDm : 0 < D_m)
    (hρp : 0 < ρ_p) (hUp : 0 < U_p) (hDp : 0 < D_p)
    (law_m : F_m / (1 / 2 * ρ_m * U_m ^ 2 * (π * D_m ^ 2 / 4))
        = φ (ρ_m * U_m * D_m / μ_m) (U_m / c_m))
    (law_p : F_p / (1 / 2 * ρ_p * U_p ^ 2 * (π * D_p ^ 2 / 4))
        = φ (ρ_p * U_p * D_p / μ_p) (U_p / c_p))
    (hRe : ρ_m * U_m * D_m / μ_m = ρ_p * U_p * D_p / μ_p)
    (hMa : U_m / c_m = U_p / c_p) :
    F_p = F_m * (ρ_p * U_p ^ 2 * D_p ^ 2) / (ρ_m * U_m ^ 2 * D_m ^ 2) := by
  have hpi : 0 < π := Real.pi_pos
  rw [hRe, hMa, ← law_p] at law_m
  have hAm : 1 / 2 * ρ_m * U_m ^ 2 * (π * D_m ^ 2 / 4) ≠ 0 := by positivity
  have hAp : 1 / 2 * ρ_p * U_p ^ 2 * (π * D_p ^ 2 / 4) ≠ 0 := by positivity
  rw [div_eq_div_iff hAm hAp] at law_m
  have hden : ρ_m * U_m ^ 2 * D_m ^ 2 ≠ 0 := by positivity
  rw [eq_div_iff hden]
  have hpi' : π ≠ 0 := hpi.ne'
  apply mul_left_cancel₀ hpi'
  nlinarith [law_m]

/-- Both groups at once: with kinematic viscosity `ν = μ/ρ` (so `Re = U D / ν`) and scale
`λ = D_m / D_p`, some tunnel speed matches both the Reynolds number and the Mach number
exactly when the two airs satisfy `ν_m / ν_p = λ · c_m / c_p`. -/
theorem re_and_ma_matchable_iff (U_p D_m D_p ν_m ν_p c_m c_p : ℝ)
    (hUp : 0 < U_p) (hDm : 0 < D_m) (hDp : 0 < D_p)
    (hνm : 0 < ν_m) (hνp : 0 < ν_p) (hcm : 0 < c_m) (hcp : 0 < c_p) :
    (∃ U_m > 0, U_m * D_m / ν_m = U_p * D_p / ν_p ∧ U_m / c_m = U_p / c_p)
      ↔ ν_m / ν_p = (D_m / D_p) * (c_m / c_p) := by
  constructor
  · rintro ⟨U_m, hUm, hRe, hMa⟩
    rw [div_eq_div_iff hcm.ne' hcp.ne'] at hMa
    rw [div_eq_div_iff hνm.ne' hνp.ne'] at hRe
    rw [div_eq_iff hνp.ne', div_mul_div_comm, div_mul_eq_mul_div, eq_div_iff (by positivity)]
    apply mul_left_cancel₀ hUp.ne'
    apply mul_left_cancel₀ hcp.ne'
    linear_combination (-(c_p * c_p)) * hRe + (c_p * D_m * ν_p) * hMa
  · intro h
    refine ⟨U_p * c_m / c_p, by positivity, ?_, ?_⟩
    · rw [div_eq_div_iff hνm.ne' hνp.ne']
      rw [div_eq_iff hνp.ne', div_mul_div_comm, div_mul_eq_mul_div, eq_div_iff (by positivity)] at h
      field_simp
      linear_combination (-1 : ℝ) * h
    · field_simp

/-- In one fixed air (the same `ν` and `c` on model and full size), a tunnel speed that
matches both the Reynolds number and the Mach number exists only at scale 1:
the model must be full size. -/
theorem same_air_both_groups_only_at_full_scale (U_m U_p D_m D_p ν c : ℝ)
    (hUp : 0 < U_p) (hDp : 0 < D_p) (hν : 0 < ν) (hc : 0 < c)
    (hRe : U_m * D_m / ν = U_p * D_p / ν) (hMa : U_m / c = U_p / c) :
    D_m = D_p := by
  have h1 : U_m = U_p := by
    rw [div_left_inj' hc.ne'] at hMa
    exact hMa
  rw [div_left_inj' hν.ne', h1] at hRe
  exact mul_left_cancel₀ hUp.ne' hRe

-- 45 km/h is 12.5 m/s.
example : (45 : ℚ) * 1000 / 3600 = 25 / 2 := by norm_num
-- Re-matching tunnel speed: 12.5 × 0.22 / 0.055 = 50 m/s.
example : (25 / 2 : ℚ) * (22 / 100) / (55 / 1000) = 50 := by norm_num
-- Force ratio at that speed: (50/12.5)² × (0.055/0.22)² = 16 × 1/16 = 1.
example : ((50 : ℚ) / (25 / 2)) ^ 2 * ((55 / 1000) / (22 / 100)) ^ 2 = 1 := by norm_num
-- Pressure for complete similarity: 1 atm × 0.22 / 0.055 = 4 atm.
example : (1 : ℚ) * (22 / 100) / (55 / 1000) = 4 := by norm_num
-- Mach ratio at 50 m/s in the same air: 50 / 12.5 = 4.
example : (50 : ℚ) / (25 / 2) = 4 := by norm_num
-- Wrong-way speed: 12.5 / 4 = 3.125 m/s.
example : (25 / 2 : ℚ) / 4 = 25 / 8 := by norm_num
-- Force scaled by area alone: 16 times the true value, an error of +1500 %.
example : ((55 / 1000 : ℚ) / (22 / 100)) ^ (-2 : ℤ) = 16 ∧ ((16 : ℚ) - 1) * 100 = 1500 := by norm_num
-- 4 atm and 50 m/s together: Re ratio = 4 (pressure) × 4 (speed) × 1/4 (size) = 4.
example : (4 : ℚ) * 4 * (1 / 4) = 4 := by norm_num

#print axioms drag_scales_when_groups_matched
#print axioms re_and_ma_matchable_iff
#print axioms same_air_both_groups_only_at_full_scale
