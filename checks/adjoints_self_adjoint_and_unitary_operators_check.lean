-- Adjoints: every bounded operator on a Hilbert space has exactly one mirror partner T* with ⟨Tf, g⟩ = ⟨f, T*g⟩, a positive operator on a complex Hilbert space is self-adjoint, and T is normal exactly when T and T* give every field the same size.
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Tactic.NormNum

open scoped InnerProductSpace ComplexOrder

/-- The adjoint exists and is unique. Let `H` be a Hilbert space (complete, with real or complex
scalars `𝕜`) and `T` a bounded operator on it. Then there is exactly one bounded operator `T*`
with `⟨T f, g⟩ = ⟨f, T* g⟩` for every field `f` and every probe `g`. -/
theorem bounded_operator_has_unique_adjoint
    {𝕜 H : Type*} [RCLike 𝕜] [NormedAddCommGroup H] [InnerProductSpace 𝕜 H] [CompleteSpace H]
    (T : H →L[𝕜] H) :
    ∃! S : H →L[𝕜] H, ∀ f g : H, ⟪T f, g⟫_𝕜 = ⟪f, S g⟫_𝕜 := by
  refine ⟨ContinuousLinearMap.adjoint T, fun f g => ?_, fun S hS => ?_⟩
  · exact (ContinuousLinearMap.adjoint_inner_right T f g).symm
  · have h : T = ContinuousLinearMap.adjoint S := (ContinuousLinearMap.eq_adjoint_iff T S).mpr hS
    rw [h, ContinuousLinearMap.adjoint_adjoint]

/-- Positive implies self-adjoint, over complex scalars. If `T` is a bounded operator on a
complex Hilbert space and every reading `⟨f, T f⟩` is a nonnegative real number, then
`T* = T`. Here `0 ≤ z` on complex numbers means `z` is real and at least 0. (Over real scalars this fails: a quarter turn of the plane has every reading 0.) -/
theorem positive_operator_is_self_adjoint
    {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]
    (T : H →L[ℂ] H) (hpos : ∀ f : H, 0 ≤ ⟪f, T f⟫_ℂ) :
    ContinuousLinearMap.adjoint T = T := by
  have hsym : (T : H →ₗ[ℂ] H).IsSymmetric := by
    rw [LinearMap.isSymmetric_iff_inner_map_self_real]
    intro v
    have h := hpos v
    have him : (⟪v, T v⟫_ℂ).im = 0 := ((Complex.nonneg_iff.mp h).2).symm
    have hconj : (starRingEnd ℂ) ⟪v, T v⟫_ℂ = ⟪v, T v⟫_ℂ := Complex.conj_eq_iff_im.mpr him
    simp only [ContinuousLinearMap.coe_coe]
    rw [← inner_conj_symm (T v) v, hconj, hconj]
  exact hsym.isSelfAdjoint

/-- Normal means the operator and its mirror are the same size on every field. For a bounded
operator `T` on a Hilbert space, `T* T = T T*` exactly when `‖T f‖ = ‖T* f‖` for every `f`. -/
theorem normal_iff_norm_eq_norm_adjoint
    {𝕜 H : Type*} [RCLike 𝕜] [NormedAddCommGroup H] [InnerProductSpace 𝕜 H] [CompleteSpace H]
    (T : H →L[𝕜] H) :
    (ContinuousLinearMap.adjoint T).comp T = T.comp (ContinuousLinearMap.adjoint T) ↔
      ∀ f : H, ‖T f‖ = ‖ContinuousLinearMap.adjoint T f‖ := by
  rw [← ContinuousLinearMap.isStarNormal_iff_norm_eq_adjoint, isStarNormal_iff, Commute,
    SemiconjBy, ContinuousLinearMap.star_eq_adjoint]
  rfl


/- The card's worked numbers on the 8-speaker ring, N = 8, indices counted round the ring
(`Fin 8` wraps). The field is f = (4, 2, 0, 0, 0, 0, 0, 1), the probe g = (0, 1, 3, 0, 0, 0, 0, 0).
The turn is (Rf)(j) = f(j - 1) and its mirror (R*g)(j) = g(j + 1). -/

-- ⟨Rf, g⟩ = 10.
example :
    (∑ j : Fin 8, (![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℤ) (j - 1) * (![0, 1, 3, 0, 0, 0, 0, 0] : Fin 8 → ℤ) j)
      = 10 := by decide
-- ⟨f, R*g⟩ = 10.
example :
    (∑ j : Fin 8, (![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℤ) j * (![0, 1, 3, 0, 0, 0, 0, 0] : Fin 8 → ℤ) (j + 1))
      = 10 := by decide
-- Energy kept: ‖f‖² = ‖Rf‖² = 21.
example : (∑ j : Fin 8, ((![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℤ) j) ^ 2) = 21 := by decide
example : (∑ j : Fin 8, ((![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℤ) (j - 1)) ^ 2) = 21 := by decide
-- What breaks: taking R* = R gives ⟨f, Rg⟩ = 0, not 10.
example :
    (∑ j : Fin 8, (![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℤ) j * (![0, 1, 3, 0, 0, 0, 0, 0] : Fin 8 → ℤ) (j - 1))
      = 0 := by decide

/- The causal blur (Af)(j) = (f(j) + f(j - 1))/2, its mirror (A*g)(j) = (g(j) + g(j + 1))/2, the
binomial blur (Bf)(j) = f(j - 1)/4 + f(j)/2 + f(j + 1)/4, and the box blur
(Cf)(j) = (f(j - 1) + f(j) + f(j + 1))/3, on the same f and g. -/

-- ⟨Af, g⟩ = 6.
example :
    (∑ j : Fin 8, ((![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℚ) j + (![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℚ) (j - 1)) / 2
        * (![0, 1, 3, 0, 0, 0, 0, 0] : Fin 8 → ℚ) j) = 6 := by
  norm_num [Fin.sum_univ_eight]
-- ⟨f, A*g⟩ = 6.
example :
    (∑ j : Fin 8, (![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℚ) j
        * (((![0, 1, 3, 0, 0, 0, 0, 0] : Fin 8 → ℚ) j + (![0, 1, 3, 0, 0, 0, 0, 0] : Fin 8 → ℚ) (j + 1)) / 2))
      = 6 := by
  norm_num [Fin.sum_univ_eight]
-- What breaks: taking A* = A gives ⟨f, Ag⟩ = 1, not 6.
example :
    (∑ j : Fin 8, (![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℚ) j
        * (((![0, 1, 3, 0, 0, 0, 0, 0] : Fin 8 → ℚ) j + (![0, 1, 3, 0, 0, 0, 0, 0] : Fin 8 → ℚ) (j - 1)) / 2))
      = 1 := by
  norm_num [Fin.sum_univ_eight]
-- ⟨f, Bf⟩ = 33/2 (16.5).
example :
    (∑ j : Fin 8, (![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℚ) j
        * ((![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℚ) (j - 1) / 4 + (![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℚ) j / 2
          + (![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℚ) (j + 1) / 4)) = 33 / 2 := by
  norm_num [Fin.sum_univ_eight]
-- ‖Af‖² = 33/2 (16.5), the same number, since B = A*A.
example :
    (∑ j : Fin 8, (((![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℚ) j
        + (![4, 2, 0, 0, 0, 0, 0, 1] : Fin 8 → ℚ) (j - 1)) / 2) ^ 2) = 33 / 2 := by
  norm_num [Fin.sum_univ_eight]
-- The box blur on the alternating pattern h = (1, -1, 1, ...): ⟨h, Ch⟩ = -8/3 (-2.666667).
example :
    (∑ j : Fin 8, (![1, -1, 1, -1, 1, -1, 1, -1] : Fin 8 → ℚ) j
        * (((![1, -1, 1, -1, 1, -1, 1, -1] : Fin 8 → ℚ) (j - 1) + (![1, -1, 1, -1, 1, -1, 1, -1] : Fin 8 → ℚ) j
          + (![1, -1, 1, -1, 1, -1, 1, -1] : Fin 8 → ℚ) (j + 1)) / 3)) = -8 / 3 := by
  norm_num [Fin.sum_univ_eight]

#print axioms bounded_operator_has_unique_adjoint
#print axioms positive_operator_is_self_adjoint
#print axioms normal_iff_norm_eq_norm_adjoint
