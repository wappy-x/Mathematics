-- C-star algebras: in a C-star algebra a self-adjoint element's size equals its spectral radius, and any continuous function applied to it has size equal to the function's largest value on the spectrum.
import Mathlib.Analysis.CStarAlgebra.ContinuousFunctionalCalculus.Basic
import Mathlib.Analysis.CStarAlgebra.Spectrum
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.CStarAlgebra.ContinuousFunctionalCalculus.Isometric
import Mathlib.Analysis.CStarAlgebra.ContinuousFunctionalCalculus.Continuity
import Mathlib.Analysis.CStarAlgebra.ContinuousFunctionalCalculus.Instances

open Filter Topology Matrix

/-- The continuous functional calculus keeps sizes exactly.  In a C-star algebra
(a complete normed algebra over the complex numbers with a mirror `x ↦ x*` obeying
`‖x* x‖ = ‖x‖²`, and a unit `1 ≠ 0`), for a self-adjoint element `a` and a function
`f` that is continuous on the spectrum of `a`, the size of `f(a)` is the largest
value of `|f|` on the spectrum of `a`. -/
theorem norm_cfc_eq_max_on_spectrum {A : Type*} [CStarAlgebra A] [Nontrivial A]
    (a : A) (ha : IsSelfAdjoint a) (f : ℂ → ℂ) (hf : ContinuousOn f (spectrum ℂ a)) :
    IsGreatest ((fun x ↦ ‖f x‖) '' spectrum ℂ a) ‖cfc f a‖ := by
  exact IsGreatest.norm_cfc f a hf ha.isStarNormal

/-- The C-star identity forces size to equal spectral radius: in a C-star algebra,
a self-adjoint element `a` has spectral radius `r(a)` equal to its norm `‖a‖`. -/
theorem spectralRadius_eq_norm_of_isSelfAdjoint {A : Type*} [CStarAlgebra A]
    (a : A) (ha : IsSelfAdjoint a) :
    spectralRadius ℂ a = (‖a‖₊ : ENNReal) := by
  exact ha.spectralRadius_eq_nnnorm

/-- `f(a)` is the limit of polynomials in `a`: in a C-star algebra, if `a` is
self-adjoint, `f` is continuous on the spectrum of `a`, and polynomials `p k`
approach `f` uniformly on the spectrum, then `p k (a)` converges in norm to `f(a)`.
So the limit does not depend on which approximating polynomials are chosen. -/
theorem tendsto_aeval_cfc_of_tendstoUniformlyOn {A : Type*} [CStarAlgebra A]
    (a : A) (ha : IsSelfAdjoint a) (f : ℂ → ℂ) (hf : ContinuousOn f (spectrum ℂ a))
    (p : ℕ → Polynomial ℂ)
    (hp : TendstoUniformlyOn (fun k x ↦ (p k).eval x) f atTop (spectrum ℂ a)) :
    Tendsto (fun k ↦ Polynomial.aeval a (p k)) atTop (𝓝 (cfc f a)) := by
  have h := tendsto_cfc_fun (a := a) hp
    (Eventually.of_forall fun k ↦ (p k).continuous.continuousOn)
  refine h.congr fun k ↦ ?_
  exact cfc_polynomial (p k) a ha.isStarNormal

/-! Worked examples from the card, checked exactly. -/

-- V = [[4, 2], [2, 4]] sends (1, 1) to 6 times itself and (1, -1) to 2 times itself.
example : !![(4 : ℤ), 2; 2, 4] *ᵥ ![1, 1] = (6 : ℤ) • ![1, 1] := by decide
example : !![(4 : ℤ), 2; 2, 4] *ᵥ ![1, -1] = (2 : ℤ) • ![1, -1] := by decide

-- q(t) = t² - 7t + 11 has q(2) = 1 and q(6) = 5, so ‖q(V)‖ = 5.
example : ((2 : ℤ) ^ 2 - 7 * 2 + 11, (6 : ℤ) ^ 2 - 7 * 6 + 11) = (1, 5) := by decide

-- The square root of V by the functional calculus squares back to V.
example :
    !![(Real.sqrt 6 + Real.sqrt 2) / 2, (Real.sqrt 6 - Real.sqrt 2) / 2;
       (Real.sqrt 6 - Real.sqrt 2) / 2, (Real.sqrt 6 + Real.sqrt 2) / 2] *
    !![(Real.sqrt 6 + Real.sqrt 2) / 2, (Real.sqrt 6 - Real.sqrt 2) / 2;
       (Real.sqrt 6 - Real.sqrt 2) / 2, (Real.sqrt 6 + Real.sqrt 2) / 2] =
    !![(4 : ℝ), 2; 2, 4] := by
  have h6 : Real.sqrt 6 ^ 2 = 6 := Real.sq_sqrt (by norm_num)
  have h2 : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  ext i j; fin_cases i <;> fin_cases j <;>
    simp [Matrix.mul_apply, Fin.sum_univ_two] <;> ring_nf <;> rw [h6, h2] <;> norm_num

-- Entry-by-entry roots fail: [[2, √2], [√2, 2]] squares to [[6, 4√2], [4√2, 6]], not V.
example :
    !![(2 : ℝ), Real.sqrt 2; Real.sqrt 2, 2] * !![(2 : ℝ), Real.sqrt 2; Real.sqrt 2, 2] =
    !![(6 : ℝ), 4 * Real.sqrt 2; 4 * Real.sqrt 2, 6] := by
  have h2 : Real.sqrt 2 * Real.sqrt 2 = 2 := Real.mul_self_sqrt (by norm_num)
  ext i j; fin_cases i <;> fin_cases j <;>
    simp [Matrix.mul_apply, Fin.sum_univ_two, h2] <;> ring

-- The Cholesky factor fails as a root: L = [[2, 0], [1, √3]] gives L L* = V.
example :
    !![(2 : ℝ), 0; 1, Real.sqrt 3] * !![(2 : ℝ), 1; 0, Real.sqrt 3] = !![(4 : ℝ), 2; 2, 4] := by
  have h3 : Real.sqrt 3 * Real.sqrt 3 = 3 := Real.mul_self_sqrt (by norm_num)
  ext i j; fin_cases i <;> fin_cases j <;>
    simp [Matrix.mul_apply, Fin.sum_univ_two, h3] <;> norm_num

-- The shear B = [[1, 2], [0, 1]]: B* B = [[1, 2], [2, 5]], and ‖B‖² = (1 + √2)² = 3 + 2√2.
example : !![(1 : ℤ), 0; 2, 1] * !![1, 2; 0, 1] = !![1, 2; 2, 5] := by decide
example : (1 + Real.sqrt 2) ^ 2 = 3 + 2 * Real.sqrt 2 := by
  have h2 : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  ring_nf; rw [h2]; ring

-- The ℓ¹ counterexample: x = 1, 1, -1 at 0, 1, 2.  Then x* x is the sequence
-- -1, 0, 3, 0, -1 at -2, ..., 2, so ‖x‖₁ = 3 but ‖x* x‖₁ = 5, not 3² = 9.
example :
    let x : List ℤ := [1, 1, -1]
    let xsx : List ℤ := (List.range 5).map fun k =>
      ((List.range 3).map fun n =>
        x.getD n 0 * x.getD (n + k - 2) 0 * (if n + k < 2 then 0 else 1)).sum
    xsx = [-1, 0, 3, 0, -1] ∧ (x.map Int.natAbs).sum = 3 ∧
      (xsx.map Int.natAbs).sum = 5 ∧ 3 ^ 2 ≠ 5 := by
  decide

#print axioms norm_cfc_eq_max_on_spectrum
#print axioms spectralRadius_eq_norm_of_isSelfAdjoint
#print axioms tendsto_aeval_cfc_of_tendstoUniformlyOn
