-- Basis and dimension: in any real vector space, a list of vectors that spans and has nothing spare gives every vector exactly one list of amounts, every two such lists have the same length and that length is the dimension, every basis of the plane has exactly two vectors, and the card's buoy numbers come out as it says.
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.Dimension.StrongRankCondition
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Module.Pi
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.LinearAlgebra.Basis.Basic
import Mathlib.LinearAlgebra.Dimension.Constructions
import Mathlib.LinearAlgebra.Finsupp.LinearCombination

/-! A list of `n` vectors in an order is a function `b : Fin n → V`: `b 0` is the first
vector, `b 1` the second, and so on, so the order is built in. The list "spans the space" when
the span of its vectors is everything (`Submodule.span ℝ (Set.range b) = ⊤`), and "nothing in
it is spare" is Mathlib's `LinearIndependent ℝ b`. A point of the plane is a list of two real
numbers, `Fin 2 → ℝ`, and `![5, 3]` is the pair (5, 3). Mathlib's `Module.finrank ℝ V` is the
dimension of `V`. -/

/-- The count never changes. In any real vector space, take two finite lists of vectors, each
in an order, each spanning the space and each with nothing spare. Then the two lists have the
same length, and that length is the dimension of the space. -/
theorem every_basis_has_the_same_length {V : Type*} [AddCommGroup V] [Module ℝ V] {m n : ℕ}
    (b : Fin m → V) (hb_spans : Submodule.span ℝ (Set.range b) = ⊤)
    (hb_indep : LinearIndependent ℝ b)
    (b' : Fin n → V) (hb'_spans : Submodule.span ℝ (Set.range b') = ⊤)
    (hb'_indep : LinearIndependent ℝ b') :
    m = n ∧ Module.finrank ℝ V = n := by
  classical
  have hm : Module.finrank ℝ V = m := by
    rw [Module.finrank_eq_card_basis (Module.Basis.mk hb_indep hb_spans.ge), Fintype.card_fin]
  have hn : Module.finrank ℝ V = n := by
    rw [Module.finrank_eq_card_basis (Module.Basis.mk hb'_indep hb'_spans.ge), Fintype.card_fin]
  exact ⟨hm.symm.trans hn, hn⟩

/-- One address per point. In any real vector space, if a finite list `b` of vectors, in an
order, spans the space and has nothing spare, then every vector `v` is reached by exactly one
list of amounts `c`: `c 0` of the first vector plus `c 1` of the second, and so on, lands on
`v` for this `c` and for no other. -/
theorem basis_gives_exactly_one_address {V : Type*} [AddCommGroup V] [Module ℝ V] {n : ℕ}
    (b : Fin n → V) (h_spans : Submodule.span ℝ (Set.range b) = ⊤)
    (h_indep : LinearIndependent ℝ b) (v : V) :
    ∃! c : Fin n → ℝ, ∑ i, c i • b i = v := by
  classical
  have hv : v ∈ Submodule.span ℝ (Set.range b) := by rw [h_spans]; exact Submodule.mem_top
  obtain ⟨c, hc⟩ := (Submodule.mem_span_range_iff_exists_fun ℝ).mp hv
  refine ⟨c, hc, fun d hd => ?_⟩
  have h0 : ∑ i, (d - c) i • b i = 0 := by
    simp only [Pi.sub_apply, sub_smul, Finset.sum_sub_distrib, hc, hd, sub_self]
  funext i
  have := Fintype.linearIndependent_iff.mp h_indep (d - c) h0 i
  simpa [sub_eq_zero] using this

/-- Every basis of the plane has exactly two vectors: a finite list of points of the plane that
spans the plane and has nothing spare has length 2, since one vector never spans it and three
are never independent. -/
theorem every_basis_of_the_plane_has_two_vectors {n : ℕ} (b : Fin n → (Fin 2 → ℝ))
    (h_spans : Submodule.span ℝ (Set.range b) = ⊤) (h_indep : LinearIndependent ℝ b) :
    n = 2 := by
  classical
  have h := Module.finrank_eq_card_basis (Module.Basis.mk h_indep h_spans.ge)
  rw [Fintype.card_fin, Module.finrank_fin_fun] at h
  exact h.symm

-- The cross-numbers: river basis 1 × 1 − (-1) × 1 = 2, east-north basis 1, and (1, 1) with (2, 2) gives 0.
example : (1 : ℤ) * 1 - (-1) * 1 = 2 ∧ (1 : ℤ) * 1 - 0 * 0 = 1 ∧ (1 : ℤ) * 2 - 2 * 1 = 0 := by
  norm_num
-- Step 3, the solve: x − y = 5 and x + y = 3; adding gives 2x = 8, so x = 4 and y = 3 − 4 = -1.
example : (2 : ℤ) * 4 = 5 + 3 ∧ (3 : ℤ) - 4 = -1 ∧ (4 : ℤ) - (-1) = 5 ∧ (4 : ℤ) + (-1) = 3 := by
  norm_num
-- The buoy rebuilt from the river basis: 4 × (1, 1) − 1 × (-1, 1) = (5, 3).
example : (4 : ℤ) • (![1, 1] : Fin 2 → ℤ) + (-1 : ℤ) • ![-1, 1] = ![5, 3] := by decide
-- The buoy in the standard basis: 5 × (1, 0) + 3 × (0, 1) = (5, 3).
example : (5 : ℤ) • (![1, 0] : Fin 2 → ℤ) + (3 : ℤ) • ![0, 1] = ![5, 3] := by decide
-- The finish marker (0, 6): 3 downstream, 3 across.
example : (3 : ℤ) • (![1, 1] : Fin 2 → ℤ) + (3 : ℤ) • ![-1, 1] = ![0, 6] := by decide
-- The mistakes: east-north numbers used as river coordinates land at (2, 8); the pair the
-- other way round lands at (-5, 3); (2, 2) is twice (1, 1).
example : (5 : ℤ) • (![1, 1] : Fin 2 → ℤ) + (3 : ℤ) • ![-1, 1] = ![2, 8] := by decide
example : (-1 : ℤ) • (![1, 1] : Fin 2 → ℤ) + (4 : ℤ) • ![-1, 1] = ![-5, 3] := by decide
example : (2 : ℤ) • (![1, 1] : Fin 2 → ℤ) = ![2, 2] := by decide
-- A spare third vector (1, 0): two different addresses, (4, -1, 0) and (3, 0, 2), both reach the buoy.
example : (4 : ℤ) • (![1, 1] : Fin 2 → ℤ) + (-1 : ℤ) • ![-1, 1] + (0 : ℤ) • ![1, 0] = ![5, 3] ∧
    (3 : ℤ) • (![1, 1] : Fin 2 → ℤ) + (0 : ℤ) • ![-1, 1] + (2 : ℤ) • ![1, 0] = ![5, 3] ∧
    (![4, -1, 0] : Fin 3 → ℤ) ≠ ![3, 0, 2] := by decide
-- Try changing: across vector (1, -1) has cross-number -2 and the buoy's address is (4, 1);
-- the point (7, 1) has river address (4, -3).
example : (1 : ℤ) * (-1) - 1 * 1 = -2 ∧
    (4 : ℤ) • (![1, 1] : Fin 2 → ℤ) + (1 : ℤ) • ![1, -1] = ![5, 3] := by decide
example : (4 : ℤ) • (![1, 1] : Fin 2 → ℤ) + (-3 : ℤ) • ![-1, 1] = ![7, 1] := by decide

#print axioms every_basis_has_the_same_length
#print axioms basis_gives_exactly_one_address
#print axioms every_basis_of_the_plane_has_two_vectors
