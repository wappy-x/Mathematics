-- The keyhole contour: for every power a strictly between 0 and 1, the area under x^(a-1)/(1+x) from 0 to infinity is finite and equals π/sin(πa).
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Analysis.SpecialFunctions.Gamma.Beta
import Mathlib.MeasureTheory.Function.JacobianOneDim

open Real MeasureTheory Set

/-- Helper: the real Beta integral B(a, 1 - a) on (0, 1) is finite and equals π / sin(πa). -/
lemma keyhole_beta_real (a : ℝ) (ha0 : 0 < a) (ha1 : a < 1) :
    IntegrableOn (fun t : ℝ => t ^ (a - 1) * (1 - t) ^ ((1 - a) - 1)) (Ioo 0 1) ∧
      ∫ t in Ioo (0 : ℝ) 1, t ^ (a - 1) * (1 - t) ^ ((1 - a) - 1) = π / Real.sin (π * a) := by
  have hu : 0 < (a : ℂ).re := by simpa using ha0
  have hv : 0 < (1 - (a : ℂ)).re := by simp; linarith
  have hc := Complex.betaIntegral_convergent hu hv
  have hval : Complex.betaIntegral a (1 - a) = ((π / Real.sin (π * a) : ℝ) : ℂ) := by
    rw [Complex.betaIntegral_eq_Gamma_mul_div _ _ hu hv, show (a : ℂ) + (1 - a) = 1 by ring,
      Complex.Gamma_one, div_one, Complex.Gamma_mul_Gamma_one_sub]
    push_cast; rfl
  have heq : EqOn (fun x : ℝ => (x : ℂ) ^ ((a : ℂ) - 1) * (1 - (x : ℂ)) ^ ((1 - (a : ℂ)) - 1))
      (fun t : ℝ => ((t ^ (a - 1) * (1 - t) ^ ((1 - a) - 1) : ℝ) : ℂ)) (Ioo 0 1) := by
    intro x hx
    simp only
    rw [Complex.ofReal_mul, Complex.ofReal_cpow hx.1.le, Complex.ofReal_cpow (by linarith [hx.2])]
    push_cast; ring_nf
  rw [intervalIntegrable_iff_integrableOn_Ioc_of_le zero_le_one] at hc
  have hc' := hc.mono_set Ioo_subset_Ioc_self
  have hR := (hc'.congr_fun heq measurableSet_Ioo)
  constructor
  · simpa using hR.re
  · have h1 : Complex.betaIntegral a (1 - a) = ∫ t in Ioo (0 : ℝ) 1,
        ((t ^ (a - 1) * (1 - t) ^ ((1 - a) - 1) : ℝ) : ℂ) := by
      rw [Complex.betaIntegral, intervalIntegral.integral_of_le zero_le_one,
        integral_Ioc_eq_integral_Ioo]
      exact setIntegral_congr_fun measurableSet_Ioo heq
    have h2 : (∫ t in Ioo (0 : ℝ) 1, ((t ^ (a - 1) * (1 - t) ^ ((1 - a) - 1) : ℝ) : ℂ)) =
        ((∫ t in Ioo (0 : ℝ) 1, t ^ (a - 1) * (1 - t) ^ ((1 - a) - 1) : ℝ) : ℂ) := integral_ofReal
    rw [h2, hval] at h1
    exact_mod_cast h1.symm

#print axioms keyhole_beta_real

/-- For 0 < a < 1, the function x^(a-1)/(1+x) has finite area over the positive real axis,
and that area is exactly π / sin(πa). -/
theorem integral_rpow_div_one_add_eq_pi_div_sin (a : ℝ) (ha0 : 0 < a) (ha1 : a < 1) :
    IntegrableOn (fun x : ℝ => x ^ (a - 1) / (1 + x)) (Ioi 0) ∧
      ∫ x in Ioi (0 : ℝ), x ^ (a - 1) / (1 + x) = π / Real.sin (π * a) := by
  set g : ℝ → ℝ := fun t => t ^ (a - 1) * (1 - t) ^ ((1 - a) - 1) with hg
  set f : ℝ → ℝ := fun x => x / (1 + x) with hf
  set f' : ℝ → ℝ := fun x => 1 / (1 + x) ^ 2 with hf'
  have himg : f '' Ioi 0 = Ioo 0 1 := by
    ext t
    simp only [mem_image, mem_Ioi, mem_Ioo, hf]
    constructor
    · rintro ⟨x, hx, rfl⟩
      refine ⟨by positivity, ?_⟩
      rw [div_lt_one (by linarith)]; linarith
    · rintro ⟨h0, h1⟩
      refine ⟨t / (1 - t), div_pos h0 (by linarith), ?_⟩
      have : (1 - t) ≠ 0 := by linarith
      field_simp
      ring
  have hder : ∀ x ∈ Ioi (0 : ℝ), HasDerivWithinAt f (f' x) (Ioi 0) x := by
    intro x hx
    have hx' : (1 + x) ≠ 0 := by simp at hx; linarith
    have := ((hasDerivAt_id x).div ((hasDerivAt_id x).const_add 1) hx')
    refine HasDerivAt.hasDerivWithinAt ?_
    convert this using 1
    · funext y; simp [hf]
    · simp only [hf', id]
      field_simp
      ring
  have hinj : InjOn f (Ioi 0) := by
    intro x hx y hy hxy
    simp only [mem_Ioi, hf] at hx hy hxy
    have h1 : (1 + x) ≠ 0 := by linarith
    have h2 : (1 + y) ≠ 0 := by linarith
    field_simp at hxy
    linarith
  have hpt : EqOn (fun x => |f' x| • g (f x)) (fun x : ℝ => x ^ (a - 1) / (1 + x)) (Ioi 0) := by
    intro x hx
    simp only [mem_Ioi] at hx
    have hy : 0 < 1 + x := by linarith
    simp only [hf', hg, hf, smul_eq_mul]
    rw [abs_of_pos (by positivity)]
    have e1 : 1 - x / (1 + x) = (1 + x)⁻¹ := by field_simp; ring
    rw [e1, div_rpow hx.le hy.le, inv_rpow hy.le, show 1 - a - 1 = -a by ring, rpow_neg hy.le,
      inv_inv]
    have e2 : (1 + x) ^ a = (1 + x) ^ (a - 1) * (1 + x) := by
      rw [← rpow_add_one hy.ne']; ring_nf
    rw [e2]
    have : (1 + x) ^ (a - 1) ≠ 0 := (rpow_pos_of_pos hy _).ne'
    field_simp
  obtain ⟨hI, hE⟩ := keyhole_beta_real a ha0 ha1
  constructor
  · rw [← himg] at hI
    exact ((integrableOn_image_iff_integrableOn_abs_deriv_smul measurableSet_Ioi hder hinj g).1
      hI).congr_fun hpt measurableSet_Ioi
  · rw [← setIntegral_congr_fun measurableSet_Ioi hpt,
      ← integral_image_eq_integral_abs_deriv_smul measurableSet_Ioi hder hinj, himg, hE]

/-- Step 5, the solve: for 0 < a < 1, the area π / sin(πa) is the number I that makes the
banks' factor times I equal 2πi times the residue at -1, namely
(1 - e^(2πia)) · I = 2πi · e^(iπ(a-1)). -/
theorem keyhole_banks_solve (a : ℝ) (ha0 : 0 < a) (ha1 : a < 1) :
    (1 - Complex.exp (2 * π * Complex.I * a)) * ((π / Real.sin (π * a) : ℝ) : ℂ) =
      2 * π * Complex.I * Complex.exp (π * Complex.I * (a - 1)) := by
  have hs : Real.sin (π * a) ≠ 0 := (Real.sin_pos_of_pos_of_lt_pi (by positivity)
    (by nlinarith [Real.pi_pos])).ne'
  have hs' : Complex.sin (π * a) ≠ 0 := by exact_mod_cast hs
  have e1 : Complex.exp (2 * π * Complex.I * a) =
      Complex.cos (2 * (π * a)) + Complex.sin (2 * (π * a)) * Complex.I := by
    rw [← Complex.exp_mul_I]; ring_nf
  have e2 : Complex.exp (π * Complex.I * (a - 1)) =
      Complex.cos (π * a - π) + Complex.sin (π * a - π) * Complex.I := by
    rw [← Complex.exp_mul_I]; ring_nf
  rw [e1, e2, Complex.cos_sub_pi, Complex.sin_sub_pi, Complex.cos_two_mul, Complex.sin_two_mul]
  push_cast
  field_simp
  linear_combination (-2 : ℂ) * Complex.sin_sq_add_cos_sq (π * a)
    + 2 * Complex.sin (π * a) ^ 2 * Complex.I_sq

/-- The swap x = 1/u: the area for the power a equals the area for the power 1 - a,
so I(3/4) = I(1/4). -/
theorem integral_rpow_div_one_add_symm (a : ℝ) (ha0 : 0 < a) (ha1 : a < 1) :
    ∫ x in Ioi (0 : ℝ), x ^ (a - 1) / (1 + x) = ∫ x in Ioi (0 : ℝ), x ^ ((1 - a) - 1) / (1 + x) := by
  rw [(integral_rpow_div_one_add_eq_pi_div_sin a ha0 ha1).2,
    (integral_rpow_div_one_add_eq_pi_div_sin (1 - a) (by linarith) (by linarith)).2,
    mul_sub, mul_one, Real.sin_pi_sub]

-- Worked numbers at a = 1/2: the bottom-bank factor e^(iπ) is -1.
example : Complex.exp (2 * π * Complex.I * (1 / 2 : ℝ)) = -1 := by
  push_cast
  rw [show 2 * (π : ℂ) * Complex.I * (1 / 2) = π * Complex.I by ring, Complex.exp_pi_mul_I]
-- The residue at -1 is e^(iπ(1/2 - 1)) = -i.
example : Complex.exp (π * Complex.I * ((1 / 2 : ℝ) - 1)) = -Complex.I := by
  rw [show (π : ℂ) * Complex.I * ((1 / 2 : ℝ) - 1) = ((-(π / 2) : ℝ) : ℂ) * Complex.I by
    push_cast; ring, Complex.exp_mul_I]
  rw [← Complex.ofReal_cos, ← Complex.ofReal_sin, Real.cos_neg, Real.sin_neg, Real.cos_pi_div_two,
    Real.sin_pi_div_two]
  simp
-- The loop value is 2πi × (-i) = 2π.
example : 2 * π * Complex.I * (-Complex.I) = 2 * π := by
  linear_combination (-2 * (π : ℂ)) * Complex.I_sq
-- The answer: π / sin(π/2) = π.
example : π / Real.sin (π * (1 / 2)) = π := by
  rw [show π * (1 / 2) = π / 2 by ring, Real.sin_pi_div_two, div_one]
-- Second case: π / sin(π/4) = π√2.
example : π / Real.sin (π * (1 / 4)) = π * √2 := by
  rw [show π * (1 / 4) = π / 4 by ring, Real.sin_pi_div_four]
  have h : √2 * √2 = 2 := Real.mul_self_sqrt (by norm_num)
  have h2 : √2 ≠ 0 := by positivity
  field_simp
  linarith [h]

#print axioms integral_rpow_div_one_add_eq_pi_div_sin
#print axioms keyhole_banks_solve
#print axioms integral_rpow_div_one_add_symm
