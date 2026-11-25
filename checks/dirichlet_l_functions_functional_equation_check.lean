-- The functional equation of L(s, chi): for a primitive, non-trivial Dirichlet character chi mod q, the completed L-function (q/pi)^((s+a)/2) Gamma((s+a)/2) L(s, chi) is finite at every s and equals g(chi)/(i^a sqrt q) times its value at 1 - s for the conjugate character.
import Mathlib.NumberTheory.LSeries.DirichletContinuation
import Mathlib.NumberTheory.LSeries.Nonvanishing
import Mathlib.NumberTheory.MulChar.Lemmas

open Complex DirichletCharacter

namespace CardDirichletFE

variable {N : ℕ} [NeZero N]

open scoped Classical in
/-- The parity a of a Dirichlet character: 0 when chi(-1) = 1 (even), 1 when chi(-1) = -1 (odd). -/
noncomputable def parity (χ : DirichletCharacter ℂ N) : ℕ := if χ.Even then 0 else 1

/-- The card's completed L-function Lambda(s, chi) = q^((s+a)/2) times Mathlib's completed
L-function, which carries pi^(-(s+a)/2) Gamma((s+a)/2) L(s, chi) and is continued to every s. -/
noncomputable def completedL (χ : DirichletCharacter ℂ N) (s : ℂ) : ℂ :=
  (N : ℂ) ^ ((s + parity χ) / 2) * completedLFunction χ s

/-- The card's root number epsilon(chi) = g(chi) / (i^a sqrt q), with g(chi) the Gauss sum
sum over n mod q of chi(n) e^(2 pi i n / q). -/
noncomputable def rootNum (χ : DirichletCharacter ℂ N) : ℂ :=
  gaussSum χ ZMod.stdAddChar / (I ^ parity χ * (Real.sqrt N : ℂ))

/-- Conjugating a character does not change its parity. -/
lemma even_star_iff (χ : DirichletCharacter ℂ N) : (star χ).Even ↔ χ.Even := by
  unfold DirichletCharacter.Even
  rw [MulChar.star_apply]
  constructor
  · intro h
    simpa using congrArg star h
  · intro h
    rw [h]
    simp

lemma parity_star (χ : DirichletCharacter ℂ N) : parity (star χ) = parity χ := by
  unfold parity
  by_cases h : χ.Even
  · rw [if_pos ((even_star_iff χ).mpr h), if_pos h]
  · rw [if_neg (fun h' => h ((even_star_iff χ).mp h')), if_neg h]

lemma gammaFactor_eq_parity (χ : DirichletCharacter ℂ N) (s : ℂ) :
    gammaFactor χ s = Gammaℝ (s + parity χ) := by
  rcases χ.even_or_odd with h | h
  · rw [h.gammaFactor_def, parity, if_pos h]
    simp
  · rw [h.gammaFactor_def, parity, if_neg h.not_even]
    simp

lemma rootNum_eq_rootNumber (χ : DirichletCharacter ℂ N) : rootNum χ = rootNumber χ := by
  rw [rootNum, rootNumber, div_div]
  congr 2
  rw [Real.sqrt_eq_rpow, ofReal_cpow (Nat.cast_nonneg _)]
  push_cast
  rfl

/-- The functional equation. Let chi be a primitive Dirichlet character mod q that is not the
trivial character. Then its completed L-function Lambda(s, chi), with gamma factor
(q/pi)^((s+a)/2) Gamma((s+a)/2), is finite (complex-differentiable) at every s, and
Lambda(s, chi) = epsilon(chi) Lambda(1 - s, chi-bar), where chi-bar is chi with every value
replaced by its complex conjugate and epsilon(chi) = g(chi) / (i^a sqrt q). -/
theorem completed_L_function_of_primitive_character_satisfies_functional_equation
    (χ : DirichletCharacter ℂ N) (hprim : χ.IsPrimitive) (hχ : χ ≠ 1) :
    Differentiable ℂ (completedL χ) ∧
      ∀ s : ℂ, completedL χ s = rootNum χ * completedL (star χ) (1 - s) := by
  have hN : (N : ℂ) ≠ 0 := Nat.cast_ne_zero.mpr (NeZero.ne N)
  refine ⟨fun s => ?_, fun s => ?_⟩
  · exact (DifferentiableAt.const_cpow (by fun_prop) (Or.inl hN)).mul
      (differentiable_completedLFunction hχ s)
  · have h := hprim.completedLFunction_one_sub (1 - s)
    rw [sub_sub_cancel] at h
    have hp : (N : ℂ) ^ ((s + parity χ) / 2) * (N : ℂ) ^ (1 - s - 1 / 2) =
        (N : ℂ) ^ ((1 - s + parity χ) / 2) := by
      rw [← cpow_add _ _ hN]
      ring_nf
    simp only [completedL]
    rw [h, parity_star, MulChar.star_eq_inv, rootNum_eq_rootNumber, ← hp]
    ring

/-- The completed L-function is the gamma factor times the L-function: wherever
Gamma((s+a)/2) is finite, Lambda(s, chi) = (q/pi)^((s+a)/2) Gamma((s+a)/2) L(s, chi), where
L(s, chi) is the sum of chi(n)/n^s continued to every s. -/
theorem completed_L_function_is_gamma_factor_times_L_function
    (χ : DirichletCharacter ℂ N) (s : ℂ) (hs : ∀ n : ℕ, (s + parity χ) / 2 ≠ -(n : ℂ)) :
    completedL χ s =
      ((N : ℂ) / (Real.pi : ℂ)) ^ ((s + parity χ) / 2) * Gamma ((s + parity χ) / 2) * LFunction χ s := by
  have hG : gammaFactor χ s ≠ 0 := by
    rw [gammaFactor_eq_parity, Ne, Gammaℝ_eq_zero_iff]
    rintro ⟨n, hn⟩
    apply hs n
    rw [hn]
    ring
  have hNs : s ≠ 0 ∨ N ≠ 1 := by
    by_contra h
    push_neg at h
    obtain ⟨rfl, hN1⟩ := h
    have h1 : χ = 1 := level_one' χ hN1
    apply hs 0
    simp [parity, h1]
  have hcp : ((N : ℂ) / (Real.pi : ℂ)) ^ ((s + parity χ) / 2) =
      (N : ℂ) ^ ((s + parity χ) / 2) / (Real.pi : ℂ) ^ ((s + parity χ) / 2) := by
    have := div_cpow_ofReal_nonneg (Nat.cast_nonneg N : (0 : ℝ) ≤ N) Real.pi_pos.le
      ((s + parity χ) / 2)
    simpa using this
  have hpi : (Real.pi : ℂ) ^ ((s + parity χ) / 2) ≠ 0 := by
    rw [Ne, cpow_eq_zero_iff]
    simp [Real.pi_ne_zero]
  rw [LFunction_eq_completed_div_gammaFactor χ s hNs]
  rw [gammaFactor_eq_parity, Gammaℝ_def] at hG ⊢
  rw [hcp, completedL]
  have hneg : (Real.pi : ℂ) ^ (-(s + parity χ) / 2) =
      ((Real.pi : ℂ) ^ ((s + parity χ) / 2))⁻¹ := by
    rw [neg_div, cpow_neg]
  rw [hneg] at hG ⊢
  have hΓ : Gamma ((s + parity χ) / 2) ≠ 0 := by
    intro h0
    apply hG
    rw [h0, mul_zero]
  field_simp

/-- The trivial zeros. For a primitive, non-trivial chi of parity a, at every point
s = -2n - a (s = -1, -3, -5, ... for odd chi; s = 0, -2, -4, ... for even chi) the gamma
factor has a pole while Lambda(s, chi) stays finite and non-zero, so L(s, chi) = 0. -/
theorem L_function_vanishes_at_trivial_zeros
    (χ : DirichletCharacter ℂ N) (hprim : χ.IsPrimitive) (hχ : χ ≠ 1) (n : ℕ) :
    LFunction χ (-(2 * n : ℂ) - parity χ) = 0 ∧ completedL χ (-(2 * n : ℂ) - parity χ) ≠ 0 := by
  have hN1 : N ≠ 1 := fun h => hχ (level_one' χ h)
  have hN : (N : ℂ) ≠ 0 := Nat.cast_ne_zero.mpr (NeZero.ne N)
  constructor
  · rw [LFunction_eq_completed_div_gammaFactor χ _ (Or.inr hN1), gammaFactor_eq_parity,
      show -(2 * n : ℂ) - parity χ + parity χ = -(2 * n) by ring,
      Gammaℝ_eq_zero_iff.mpr ⟨n, rfl⟩, div_zero]
  · simp only [completedL]
    refine mul_ne_zero ?_ ?_
    · rw [Ne, cpow_eq_zero_iff]
      tauto
    · have e : completedLFunction χ (-(2 * n : ℂ) - parity χ) =
          completedLFunction χ (1 - (1 - (-(2 * n : ℂ) - parity χ))) := by
        rw [sub_sub_cancel]
      rw [e, hprim.completedLFunction_one_sub]
      refine mul_ne_zero (mul_ne_zero ?_ (rootNumber_ne_zero hprim))
        (completedLFunction_ne_zero_of_one_le_re χ⁻¹ (Or.inl (inv_ne_one.mpr hχ)) ?_)
      · rw [Ne, cpow_eq_zero_iff]
        tauto
      · simp
        have h1 : (0 : ℝ) ≤ n := Nat.cast_nonneg n
        have h2 : (0 : ℝ) ≤ parity χ := Nat.cast_nonneg _
        linarith

end CardDirichletFE

-- Worked numbers for chi_4 (values 1, 0, -1, 0 at n = 1, 2, 3, 0 mod 4; odd, so a = 1).
-- The Gauss sum: chi_4(1) i + chi_4(3) (-i) = i + i = 2i.
example : (1 : ℂ) * I + (-1) * (-I) = 2 * I := by
  ring
-- The root number: 2i / (i sqrt 4) = 1.
example : 2 * I / (I * (Real.sqrt 4 : ℂ)) = 1 := by
  have h4 : Real.sqrt 4 = 2 := by
    rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  rw [h4]
  push_cast
  field_simp
-- Lambda(1, chi_4) = (4/pi)^1 Gamma(1) (pi/4) = 1.
example : (4 / Real.pi) * Real.Gamma 1 * (Real.pi / 4) = 1 := by
  rw [Real.Gamma_one]
  field_simp
-- The gamma factor at 0: (4/pi)^(1/2) Gamma(1/2) = 2, so L(0, chi_4) = 1 / 2.
example : (4 / Real.pi) ^ (1 / 2 : ℝ) * Real.Gamma (1 / 2) = 2 := by
  rw [Real.Gamma_one_half_eq, ← Real.sqrt_eq_rpow, Real.sqrt_div' _ Real.pi_pos.le]
  have h4 : Real.sqrt 4 = 2 := by
    rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
  rw [h4]
  have : Real.sqrt Real.pi ≠ 0 := (Real.sqrt_pos.mpr Real.pi_pos).ne'
  field_simp

open CardDirichletFE

#print axioms even_star_iff
#print axioms parity_star
#print axioms gammaFactor_eq_parity
#print axioms rootNum_eq_rootNumber
#print axioms completed_L_function_of_primitive_character_satisfies_functional_equation
#print axioms completed_L_function_is_gamma_factor_times_L_function
#print axioms L_function_vanishes_at_trivial_zeros
