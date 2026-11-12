-- Liouville's theorem: a bounded function with a complex derivative everywhere is constant, so every complex polynomial of degree at least 1 has a root and splits into one bracket per root.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Algebra.Polynomial.Degree.Defs
import Mathlib.Algebra.BigOperators.Group.Multiset.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Complex.Liouville
import Mathlib.Analysis.Complex.Polynomial.Basic

open Polynomial

/-- Liouville's theorem: if f is entire (has a complex derivative at every point of the
plane) and its size never passes a fixed ceiling M, then f is constant. -/
theorem bounded_entire_function_is_constant
    (f : ℂ → ℂ) (hf : Differentiable ℂ f) (M : ℝ) (hM : ∀ z, ‖f z‖ ≤ M) :
    ∀ z w, f z = f w := by
  intro z w
  apply hf.apply_eq_apply_of_bounded _ z w
  rw [Metric.isBounded_iff_subset_closedBall 0]
  refine ⟨M, ?_⟩
  rintro _ ⟨x, rfl⟩
  simpa using hM x

/-- The fundamental theorem of algebra: every complex polynomial of degree 1 or more
has a complex root. -/
theorem polynomial_of_positive_degree_has_root
    (p : ℂ[X]) (hp : 1 ≤ p.natDegree) :
    ∃ z : ℂ, p.eval z = 0 := by
  have h : 0 < p.degree := by
    exact Polynomial.natDegree_pos_iff_degree_pos.mp hp
  obtain ⟨z, hz⟩ := Complex.exists_root h
  exact ⟨z, hz⟩

/-- Peeling roots one at a time: a complex polynomial p of degree n ≥ 1 with leading
coefficient a_n has roots z_1, ..., z_n (repeats allowed) with
p(z) = a_n (z - z_1)(z - z_2) ... (z - z_n). -/
theorem polynomial_splits_into_degree_many_brackets
    (p : ℂ[X]) (hp : 1 ≤ p.natDegree) :
    ∃ s : Multiset ℂ, Multiset.card s = p.natDegree ∧
      p = C p.leadingCoeff * (s.map (fun z => X - C z)).prod := by
  have hs := IsAlgClosed.splits p
  refine ⟨p.roots, ?_, hs.eq_prod_roots⟩
  exact hs.natDegree_eq_card_roots.symm

-- p(z) = z^4 + 1 at 1: p(1) = 2 and p'(1) = 4 × 1^3 = 4.
example : (1 : ℤ) ^ 4 + 1 = 2 ∧ 4 * (1 : ℤ) ^ 3 = 4 := by decide
-- The slope of 1/p at 1 by the reciprocal rule: -p'(1)/p(1)^2 = -4/2^2 = -1.
example : -(4 : ℚ) / 2 ^ 2 = -1 := by norm_num
-- On |z| = 2 the size of z^4 + 1 is at least 2^4 - 1 = 15.
example : (2 : ℤ) ^ 4 - 1 = 15 := by decide
-- The football: 5z^2 - 20z + 25 = 5((z - 2)^2 + 1), with roots 2 + i and 2 - i.
example (z : ℂ) : 5 * z ^ 2 - 20 * z + 25 = 5 * ((z - 2) ^ 2 + 1) := by ring
example : 5 * (2 + Complex.I) ^ 2 - 20 * (2 + Complex.I) + 25 = 0 := by
  ring_nf; rw [Complex.I_sq]; ring
example : 5 * (2 - Complex.I) ^ 2 - 20 * (2 - Complex.I) + 25 = 0 := by
  ring_nf; rw [Complex.I_sq]; ring
-- Mirror pairs: z^4 + 1 = (z^2 - √2 z + 1)(z^2 + √2 z + 1).
example (z : ℂ) :
    z ^ 4 + 1 = (z ^ 2 - (Real.sqrt 2 : ℂ) * z + 1) * (z ^ 2 + (Real.sqrt 2 : ℂ) * z + 1) := by
  have h : ((Real.sqrt 2 : ℝ) : ℂ) ^ 2 = 2 := by
    rw [← Complex.ofReal_pow, Real.sq_sqrt (by norm_num)]; norm_num
  linear_combination z ^ 2 * h

#print axioms bounded_entire_function_is_constant
#print axioms polynomial_of_positive_degree_has_root
#print axioms polynomial_splits_into_degree_many_brackets
