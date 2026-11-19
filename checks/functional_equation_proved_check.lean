-- The functional equation: the completed zeta function ξ(s) = ½ s(s − 1) π^(−s/2) Γ(s/2) ζ(s) extends to a function that is finite at every complex s and takes the same value at s and 1 − s, and zeta is 0 left of the line σ = 0 exactly at −2, −4, −6, ….
import Mathlib.NumberTheory.LSeries.RiemannZeta
import Mathlib.NumberTheory.LSeries.HurwitzZetaValues
import Mathlib.NumberTheory.LSeries.Dirichlet
import Mathlib.NumberTheory.LSeries.Nonvanishing

open Complex

/-- Riemann's functional equation. There is a function ξ, finite and complex-differentiable at
every complex s, that equals ½ s(s − 1) π^(−s/2) Γ(s/2) ζ(s) wherever the gamma factor
π^(−s/2) Γ(s/2) is finite and zeta has no pole (s not 1 and not 0, −2, −4, …). It takes the same
value at s and at the mirror point 1 − s, and ξ(0) = ξ(1) = 1/2. -/
theorem completed_zeta_functional_equation :
    ∃ ξ : ℂ → ℂ, Differentiable ℂ ξ ∧
      (∀ s : ℂ, s ≠ 1 → (∀ n : ℕ, s ≠ -(2 * (n : ℂ))) →
        ξ s = s * (s - 1) / 2 * ((Real.pi : ℂ) ^ (-s / 2) * Gamma (s / 2)) * riemannZeta s) ∧
      (∀ s : ℂ, ξ (1 - s) = ξ s) ∧
      ξ 0 = 1 / 2 ∧ ξ 1 = 1 / 2 := by
  refine ⟨fun s => s * (s - 1) / 2 * completedRiemannZeta₀ s + 1 / 2, ?_, ?_, ?_, ?_, ?_⟩
  · intro s
    have h := differentiable_completedZeta₀ s
    fun_prop
  · intro s hs1 hs
    have hs0 : s ≠ 0 := by simpa using hs 0
    have hG : Gammaℝ s ≠ 0 := by
      intro h
      obtain ⟨n, hn⟩ := Gammaℝ_eq_zero_iff.mp h
      exact hs n hn
    have hz : riemannZeta s * Gammaℝ s = completedRiemannZeta s := by
      rw [riemannZeta_def_of_ne_zero hs0, div_mul_cancel₀ _ hG]
    rw [← Gammaℝ_def, mul_assoc, mul_comm (Gammaℝ s), hz, completedRiemannZeta_eq]
    have h1 : (1 : ℂ) - s ≠ 0 := sub_ne_zero.mpr (Ne.symm hs1)
    field_simp
    ring
  · intro s
    simp only [completedRiemannZeta₀_one_sub]
    ring
  · simp
  · simp

/-- The trivial zeros. To the left of the line σ = 0, zeta is 0 exactly at the negative even
integers −2, −4, −6, …, where the gamma factor has its poles. -/
theorem zeta_zero_left_of_strip_iff (s : ℂ) (hs : s.re < 0) :
    riemannZeta s = 0 ↔ ∃ n : ℕ, s = -2 * ((n : ℂ) + 1) := by
  exact riemannZeta_eq_zero_iff_of_re_nonpos hs.le

/-- The worked numbers. Dividing the gamma factor back out of ξ gives zeta's continued values
ζ(0) = −1/2 and ζ(−1) = −1/12. -/
theorem zeta_zero_and_zeta_neg_one :
    riemannZeta 0 = -1 / 2 ∧ riemannZeta (-1) = -1 / 12 := by
  refine ⟨riemannZeta_zero, ?_⟩
  have h := riemannZeta_neg_nat_eq_bernoulli 1
  rw [bernoulli_two] at h
  simp only [Nat.cast_one] at h
  rw [h]
  norm_num

-- The factor ½ s(s − 1) is 1 at s = 2 and at its mirror s = −1.
example : (1 / 2 : ℚ) * 2 * (2 - 1) = 1 := by norm_num
example : (1 / 2 : ℚ) * (-1) * (-1 - 1) = 1 := by norm_num
-- The mirror point of 2 is −1, and the trivial zero −2 is mirrored to 3, where ξ(3) is finite.
example : (1 : ℤ) - 2 = -1 := by norm_num
example : (1 : ℤ) - (-2) = 3 := by norm_num

#print axioms completed_zeta_functional_equation
#print axioms zeta_zero_left_of_strip_iff
#print axioms zeta_zero_and_zeta_neg_one
