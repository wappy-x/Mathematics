-- The Riemann hypothesis: this file proves that every zero of zeta other than -2, -4, -6, ... lies in the critical strip, and that Mathlib's statement RiemannHypothesis says the same as Clay's; the 2026 proof itself (about 17 million lines) is not reproduced here.
import Mathlib.NumberTheory.LSeries.Nonvanishing

/-- The critical strip (Hadamard and de la Vallée Poussin, 1896): every zero of zeta other than
the trivial zeros `-2, -4, -6, ...` has real part strictly between 0 and 1. -/
theorem nontrivial_zeros_in_critical_strip (s : ℂ) (hzero : riemannZeta s = 0)
    (hnontrivial : ¬∃ n : ℕ, s = -2 * (n + 1)) : 0 < s.re ∧ s.re < 1 := by
  constructor
  · by_contra hle
    push Not at hle
    exact hnontrivial ((riemannZeta_eq_zero_iff_of_re_nonpos hle).mp hzero)
  · by_contra hle
    push Not at hle
    exact riemannZeta_ne_zero_of_one_le_re hle hzero

/-- Mathlib's statement `RiemannHypothesis` says the same as Clay's statement: every zero of zeta
inside the critical strip `0 < Re s < 1` lies on the line `Re s = 1/2`. -/
theorem riemann_hypothesis_iff_clay_statement :
    RiemannHypothesis ↔
      ∀ s : ℂ, riemannZeta s = 0 → 0 < s.re → s.re < 1 → s.re = 1 / 2 := by
  constructor
  · intro h s hz h0 h1
    refine h s hz ?_ ?_
    · rintro ⟨n, rfl⟩
      have : (0 : ℝ) ≤ n := n.cast_nonneg
      simp at h0
      linarith
    · rintro rfl
      simp at h1
  · intro h s hz hnt _
    obtain ⟨h0, h1⟩ := nontrivial_zeros_in_critical_strip s hz hnt
    exact h s hz h0 h1

/-- Why "nontrivial" is part of the statement: zeta is 0 at -2, whose real part is -2, not 1/2. -/
example : riemannZeta (-2) = 0 ∧ (-2 : ℂ).re ≠ 1 / 2 := by
  refine ⟨?_, ?_⟩
  · simpa using riemannZeta_neg_two_mul_nat_add_one 0
  · norm_num

#print axioms nontrivial_zeros_in_critical_strip
#print axioms riemann_hypothesis_iff_clay_statement
