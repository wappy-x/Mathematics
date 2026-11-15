-- Compact operators: a norm limit of finite-rank operators is compact, compact operators form a closed two-sided ideal, and so on an infinite-dimensional space no bounded operator can undo a compact one.
import Mathlib.Analysis.Normed.Operator.Compact.FiniteDimension
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Tactic.NormNum

open Filter Topology

/-- A norm limit of finite-rank operators is compact. Let `E` be a real normed space and `H` a
complete real normed space (on the card, both are the profile space L²(0, 1)). Suppose each
`K_N : E → H` is a bounded operator of rank at most `N`: its outputs fill a finite-dimensional
space of dimension at most `N`. If the operator-norm gap `‖K - K_N‖` tends to 0 as `N` grows,
then `K` is compact. -/
theorem compact_of_norm_limit_of_finite_rank
    {E H : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [NormedAddCommGroup H] [NormedSpace ℝ H] [CompleteSpace H]
    (K : E →L[ℝ] H) (KN : ℕ → E →L[ℝ] H)
    (hfin : ∀ N, FiniteDimensional ℝ (LinearMap.range (KN N : E →ₗ[ℝ] H)))
    (hrank : ∀ N, Module.finrank ℝ (LinearMap.range (KN N : E →ₗ[ℝ] H)) ≤ N)
    (hlim : Tendsto (fun N => ‖K - KN N‖) atTop (𝓝 0)) :
    IsCompactOperator K := by
  have hcomp : ∀ N, IsCompactOperator (KN N) := by
    intro N
    have := hfin N
    let R := LinearMap.range (KN N : E →ₗ[ℝ] H)
    let T : E →L[ℝ] R := (KN N).codRestrict R (fun x => LinearMap.mem_range_self _ x)
    have hT : IsCompactOperator T := isCompactOperator_of_locallyCompactSpace_dom T
    have h2 := hT.clm_comp (R.subtypeL)
    convert h2 using 1
    rfl
  have ht : Tendsto KN atTop (𝓝 K) := by
    rw [tendsto_iff_norm_sub_tendsto_zero]
    simpa [norm_sub_rev] using hlim
  exact isCompactOperator_of_tendsto ht (Eventually.of_forall hcomp)

/-- The closed-ideal rule. On a complete real normed space `H` (on the card, L²(0, 1)), take
compact operators `K` and `L`, bounded operators `A` and `B`, and a number `α`. Then `K + L`,
`α K` and `A K B` are compact; and a limit, in the operator norm, of compact operators is
compact: the set of compact operators is closed among the bounded ones. -/
theorem compact_operators_closed_ideal
    {H : Type*} [NormedAddCommGroup H] [NormedSpace ℝ H] [CompleteSpace H]
    (K L A B : H →L[ℝ] H) (α : ℝ) (hK : IsCompactOperator K) (hL : IsCompactOperator L) :
    IsCompactOperator (K + L) ∧ IsCompactOperator (α • K) ∧
      IsCompactOperator (A.comp (K.comp B)) ∧
      IsClosed {T : H →L[ℝ] H | IsCompactOperator T} := by
  refine ⟨hK.add hL, hK.smul α, ?_, isClosed_setOfPred_isCompactOperator⟩
  exact (hK.comp_clm B).clm_comp A

/-- No bounded un-smoother. On an infinite-dimensional complete real normed space `H` (such as
L²(0, 1)), a compact operator `K` has no bounded left inverse: there is no bounded `B` with
`B K = I`, because that would make the identity compact. -/
theorem no_bounded_left_inverse_of_compact
    {H : Type*} [NormedAddCommGroup H] [NormedSpace ℝ H] [CompleteSpace H]
    (hinf : ¬ FiniteDimensional ℝ H) (K : H →L[ℝ] H) (hK : IsCompactOperator K) :
    ¬ ∃ B : H →L[ℝ] H, B.comp K = ContinuousLinearMap.id ℝ H := by
  rintro ⟨B, hB⟩
  apply hinf
  have h : IsCompactOperator (B.comp K) := hK.clm_comp B
  rw [hB] at h
  exact FiniteDimensional.of_isCompactOperator_id h

/-- Modes 1 and 2 have size 1 and stay √2 = 1.414214 apart: in two coordinates, the squared
distance between the unit vectors e₁ and e₂ is exactly 2. -/
example : ‖(EuclideanSpace.single 0 1 - EuclideanSpace.single 1 1 : EuclideanSpace ℝ (Fin 2))‖ ^ 2
    = 2 := by
  rw [EuclideanSpace.real_norm_sq_eq]
  norm_num [Fin.sum_univ_two]

#print axioms compact_of_norm_limit_of_finite_rank
#print axioms compact_operators_closed_ideal
#print axioms no_bounded_left_inverse_of_compact
