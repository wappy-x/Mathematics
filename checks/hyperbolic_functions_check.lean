-- Hyperbolic functions: cosh and sinh are the even and odd halves of exp with cosh² − sinh² = 1, each is the other's rate, and the three log formulas undo sinh, cosh (on t ≥ 0) and tanh.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Arsinh
import Mathlib.Analysis.SpecialFunctions.Arcosh
import Mathlib.Analysis.SpecialFunctions.Artanh

open Real

/-- For every real t, cosh t is the average of e^t and e^−t and sinh t is half their
difference; cosh is even and sinh is odd; they add to e^t and subtract to e^−t; and
cosh squared minus sinh squared is exactly 1. -/
theorem cosh_sq_sub_sinh_sq_eq_one_halves_of_exp (t : ℝ) :
    cosh t = (exp t + exp (-t)) / 2 ∧ sinh t = (exp t - exp (-t)) / 2 ∧
    cosh (-t) = cosh t ∧ sinh (-t) = -sinh t ∧
    cosh t + sinh t = exp t ∧ cosh t - sinh t = exp (-t) ∧
    cosh t ^ 2 - sinh t ^ 2 = 1 := by
  refine ⟨cosh_eq t, sinh_eq t, cosh_neg t, sinh_neg t, cosh_add_sinh t, cosh_sub_sinh t,
    cosh_sq_sub_sinh_sq t⟩

/-- Each is the other's rate, with no minus sign: at every real t the rate of sinh is cosh t,
the rate of cosh is sinh t, and the rate of tanh is 1 / cosh² t. -/
theorem sinh_cosh_each_others_rate (t : ℝ) :
    HasDerivAt sinh (cosh t) t ∧ HasDerivAt cosh (sinh t) t ∧
    HasDerivAt tanh (1 / cosh t ^ 2) t := by
  refine ⟨hasDerivAt_sinh t, hasDerivAt_cosh t, ?_⟩
  have hc : cosh t ≠ 0 := (cosh_pos t).ne'
  have h : HasDerivAt (fun s => sinh s / cosh s)
      ((cosh t * cosh t - sinh t * sinh t) / cosh t ^ 2) t :=
    (hasDerivAt_sinh t).div (hasDerivAt_cosh t) hc
  have hf : (fun s => sinh s / cosh s) = tanh := by
    funext s; exact (tanh_eq_sinh_div_cosh s).symm
  rw [hf] at h
  convert h using 1
  have := cosh_sq_sub_sinh_sq t
  rw [← this]; ring

/-- The log formulas undo the three functions: for every real x, sinh y = x exactly when
y = ln(x + √(x² + 1)); for x ≥ 1 and y ≥ 0, cosh y = x exactly when y = ln(x + √(x² − 1));
for −1 < x < 1, tanh y = x exactly when y = ½ ln((1 + x)/(1 − x)). -/
theorem log_formulas_undo_sinh_cosh_tanh :
    (∀ x y : ℝ, sinh y = x ↔ y = log (x + √(x ^ 2 + 1))) ∧
    (∀ x y : ℝ, 1 ≤ x → 0 ≤ y → (cosh y = x ↔ y = log (x + √(x ^ 2 - 1)))) ∧
    (∀ x y : ℝ, -1 < x → x < 1 → (tanh y = x ↔ y = 1 / 2 * log ((1 + x) / (1 - x)))) := by
  refine ⟨?_, ?_, ?_⟩
  · intro x y
    have hx : log (x + √(x ^ 2 + 1)) = arsinh x := by rw [arsinh, add_comm (x ^ 2) 1]
    rw [hx]
    constructor
    · rintro rfl; exact (arsinh_sinh y).symm
    · rintro rfl; exact sinh_arsinh x
  · intro x y hx hy
    change cosh y = x ↔ y = arcosh x
    constructor
    · rintro rfl; exact (arcosh_cosh hy).symm
    · rintro rfl; exact cosh_arcosh hx
  · intro x y h1 h2
    rw [← artanh_eq_half_log ⟨h1.le, h2.le⟩]
    constructor
    · rintro rfl; exact (artanh_tanh y).symm
    · rintro rfl; exact tanh_artanh ⟨h1, h2⟩

-- The chain's bottom: 8 cosh 0 = 8, and its slope there, sinh 0, is 0.
example : 8 * cosh 0 = 8 := by simp
example : sinh 0 = 0 := by simp
-- The chain is 2 m above its bottom where cosh(x/8) = 1.25: arcosh 1.25 is ln 2, at both ±ln 2.
example : cosh (log 2) = 5 / 4 := by rw [cosh_eq, exp_neg, exp_log (by norm_num)]; norm_num
example : cosh (-log 2) = 5 / 4 := by rw [cosh_neg, cosh_eq, exp_neg, exp_log (by norm_num)]; norm_num
example : arcosh (5 / 4) = log 2 := by
  have h : cosh (log 2) = 5 / 4 := by rw [cosh_eq, exp_neg, exp_log (by norm_num)]; norm_num
  rw [← h, arcosh_cosh (log_nonneg (by norm_num))]

#print axioms cosh_sq_sub_sinh_sq_eq_one_halves_of_exp
#print axioms sinh_cosh_each_others_rate
#print axioms log_formulas_undo_sinh_cosh_tanh
