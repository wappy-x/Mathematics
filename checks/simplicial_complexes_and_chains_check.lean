-- Simplicial complexes and chains: in every simplicial complex, the signed boundary of the boundary of every chain is zero, and the boundary of a chain of the complex is again a chain of the complex.
import Mathlib.AlgebraicTopology.SimplicialComplex.Basic
import Mathlib.Data.Finset.Sort
import Mathlib.LinearAlgebra.Finsupp.LinearCombination
import Mathlib.LinearAlgebra.Matrix.Notation

open Finsupp

namespace SimplicialChains

variable {ι : Type*} [LinearOrder ι]

/-- The face of the simplex `s` that leaves out the vertex at position `i`,
with the vertices of `s` listed in increasing order. -/
def face (s : Finset ι) (i : Fin s.card) : Finset ι :=
  s.erase (s.orderEmbOfFin rfl i)

/-- The signed boundary of one simplex `[v_0, ..., v_k]`: the sum over `i` of
`(-1)^i [v_0, ..., v_i left out, ..., v_k]`. A single vertex (or the empty set) has
boundary `0`. -/
noncomputable def boundarySimplex (s : Finset ι) : Finset ι →₀ ℤ :=
  if s.card ≤ 1 then 0
  else ∑ i : Fin s.card, ((-1 : ℤ) ^ (i : ℕ)) • Finsupp.single (face s i) 1

/-- The boundary of a chain (a finite sum of simplices with integer coefficients),
taken term by term. -/
noncomputable def boundary : (Finset ι →₀ ℤ) →ₗ[ℤ] (Finset ι →₀ ℤ) :=
  Finsupp.linearCombination ℤ boundarySimplex

/-- `C_k(K)`: the k-chains of the simplicial complex `K`, the integer combinations of its
k-simplices (simplices with `k + 1` vertices). -/
def chains (K : PreAbstractSimplicialComplex ι) (k : ℕ) : Submodule ℤ (Finset ι →₀ ℤ) :=
  Finsupp.supported ℤ ℤ {s | s ∈ K ∧ s.card = k + 1}

/-- The sign of vertex `v` in `s`: `(-1)` to the number of vertices of `s` below `v`. -/
noncomputable def sgn (s : Finset ι) (v : ι) : ℤ := (-1 : ℤ) ^ (s.filter (· < v)).card

/-- The signed boundary written as a sum over the vertices left out. -/
noncomputable def bsum (s : Finset ι) : Finset ι →₀ ℤ :=
  ∑ v ∈ s, sgn s v • Finsupp.single (s.erase v) 1

theorem card_filter_lt_orderEmbOfFin (s : Finset ι) (i : Fin s.card) :
    (s.filter (· < s.orderEmbOfFin rfl i)).card = i := by
  have h : s.filter (· < s.orderEmbOfFin rfl i) =
      (Finset.Iio i).map (s.orderEmbOfFin rfl).toEmbedding := by
    ext x
    simp only [Finset.mem_filter, Finset.mem_map, Finset.mem_Iio,
      RelEmbedding.coe_toEmbedding]
    constructor
    · rintro ⟨hx, hlt⟩
      have : x ∈ Set.range (s.orderEmbOfFin rfl) := by
        rw [Finset.range_orderEmbOfFin]; exact hx
      obtain ⟨j, rfl⟩ := this
      exact ⟨j, (s.orderEmbOfFin rfl).lt_iff_lt.mp hlt, rfl⟩
    · rintro ⟨j, hj, rfl⟩
      exact ⟨Finset.orderEmbOfFin_mem _ _ _, (s.orderEmbOfFin rfl).lt_iff_lt.mpr hj⟩
  rw [h, Finset.card_map, Fin.card_Iio]

theorem boundarySimplex_eq (s : Finset ι) :
    boundarySimplex s = if s.card ≤ 1 then 0 else bsum s := by
  unfold boundarySimplex bsum
  split_ifs with h
  · rfl
  · have hm := s.map_orderEmbOfFin_univ rfl
    calc ∑ i : Fin s.card, ((-1 : ℤ) ^ (i : ℕ)) • Finsupp.single (face s i) (1 : ℤ)
        = ∑ i : Fin s.card, sgn s (s.orderEmbOfFin rfl i) •
            Finsupp.single (s.erase (s.orderEmbOfFin rfl i)) 1 := by
          refine Finset.sum_congr rfl fun i _ => ?_
          rw [sgn, card_filter_lt_orderEmbOfFin]; rfl
      _ = ∑ v ∈ Finset.univ.map (s.orderEmbOfFin rfl).toEmbedding,
            sgn s v • Finsupp.single (s.erase v) 1 := by
          rw [Finset.sum_map]; rfl
      _ = ∑ v ∈ s, sgn s v • Finsupp.single (s.erase v) 1 := by rw [hm]

theorem sgn_swap_of_lt (s : Finset ι) {v w : ι} (_hv : v ∈ s) (hw : w ∈ s) (hwv : w < v) :
    sgn s w * sgn (s.erase w) v = -(sgn s v * sgn (s.erase v) w) := by
  have h1 : (s.erase v).filter (· < w) = s.filter (· < w) := by
    rw [Finset.filter_erase]
    exact Finset.erase_eq_of_notMem (by simp [not_lt.mpr hwv.le])
  have h2 : ((s.erase w).filter (· < v)).card + 1 = (s.filter (· < v)).card := by
    rw [Finset.filter_erase, Finset.card_erase_add_one]
    simp [hw, hwv]
  unfold sgn
  rw [h1, ← h2, pow_succ]
  ring

theorem sgn_swap (s : Finset ι) {v w : ι} (hv : v ∈ s) (hw : w ∈ s) (hne : v ≠ w) :
    sgn s w * sgn (s.erase w) v = -(sgn s v * sgn (s.erase v) w) := by
  rcases lt_or_gt_of_ne hne with h | h
  · have := sgn_swap_of_lt s hw hv h
    rw [this]; ring
  · exact sgn_swap_of_lt s hv hw h

theorem sum_sgn_bsum (s : Finset ι) :
    ∑ v ∈ s, sgn s v • bsum (s.erase v) = 0 := by
  set F : ι → ι → Finset ι →₀ ℤ := fun v w =>
    (sgn s v * sgn (s.erase v) w) • Finsupp.single ((s.erase v).erase w) 1 with hF
  have hS : ∑ v ∈ s, sgn s v • bsum (s.erase v) = ∑ v ∈ s, ∑ w ∈ s.erase v, F v w := by
    refine Finset.sum_congr rfl fun v _ => ?_
    rw [bsum, Finset.smul_sum]
    refine Finset.sum_congr rfl fun w _ => ?_
    simp only [hF]
    rw [mul_smul]
  have hswap : ∑ v ∈ s, ∑ w ∈ s.erase v, F v w = ∑ v ∈ s, ∑ w ∈ s.erase v, F w v :=
    Finset.sum_comm' (fun x y => by
      simp only [Finset.mem_erase]; tauto)
  have hneg : ∑ v ∈ s, ∑ w ∈ s.erase v, F w v = -∑ v ∈ s, ∑ w ∈ s.erase v, F v w := by
    rw [← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl fun v hv => ?_
    rw [← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl fun w hw => ?_
    obtain ⟨hne, hw⟩ := Finset.mem_erase.mp hw
    simp only [hF]
    rw [sgn_swap s hv hw (Ne.symm hne), Finset.erase_right_comm, neg_smul]
  rw [hS]
  set S := ∑ v ∈ s, ∑ w ∈ s.erase v, F v w
  have h : S = -S := hswap.trans hneg
  ext t
  have := congrArg (fun f : Finset ι →₀ ℤ => f t) h
  simp only [Finsupp.coe_neg, Pi.neg_apply] at this
  simp only [Finsupp.coe_zero, Pi.zero_apply]
  omega

theorem boundary_single (s : Finset ι) (b : ℤ) :
    boundary (Finsupp.single s b) = b • boundarySimplex s := by
  simp [boundary, Finsupp.linearCombination_single]

theorem boundary_boundarySimplex (s : Finset ι) : boundary (boundarySimplex s) = 0 := by
  rw [boundarySimplex_eq s]
  split_ifs with h
  · exact map_zero _
  · rw [bsum, map_sum]
    simp only [map_zsmul, boundary_single, one_smul]
    by_cases h2 : s.card = 2
    · refine Finset.sum_eq_zero fun v hv => ?_
      rw [boundarySimplex_eq, ite_eq_left_of_eq_true _ _ (eq_true (by rw [Finset.card_erase_of_mem hv]; omega)), smul_zero]
    · rw [Finset.sum_congr rfl fun v hv => by
        rw [boundarySimplex_eq, ite_eq_right_of_eq_false _ _ (eq_false (by rw [Finset.card_erase_of_mem hv]; omega))]]
      exact sum_sgn_bsum s

theorem boundarySimplex_apply (s t : Finset ι) :
    boundarySimplex s t =
      if s.card ≤ 1 then 0 else ∑ v ∈ s, if s.erase v = t then sgn s v else 0 := by
  rw [boundarySimplex_eq]
  split_ifs
  · rfl
  · simp [bsum, Finsupp.single_apply]

#print axioms card_filter_lt_orderEmbOfFin
#print axioms boundarySimplex_eq
#print axioms sgn_swap_of_lt
#print axioms sgn_swap
#print axioms sum_sgn_bsum
#print axioms boundary_single
#print axioms boundary_boundarySimplex
#print axioms boundarySimplex_apply

/-- The boundary taken twice is zero: in every simplicial complex `K`, for every `k` and
every k-chain `c` of `K`, the boundary of the boundary of `c` is `0`. -/
theorem boundary_boundary_eq_zero (K : PreAbstractSimplicialComplex ι) (k : ℕ)
    (c : Finset ι →₀ ℤ) (hc : c ∈ chains K k) :
    boundary (boundary c) = 0 := by
  -- every chain works, so the hypothesis `hc` is not needed
  have _ := hc
  have h : boundary ∘ₗ boundary = (0 : (Finset ι →₀ ℤ) →ₗ[ℤ] (Finset ι →₀ ℤ)) :=
    Finsupp.lhom_ext fun s b => by
      rw [LinearMap.comp_apply, boundary_single, map_zsmul, boundary_boundarySimplex,
        smul_zero, LinearMap.zero_apply]
  exact LinearMap.congr_fun h c

/-- Because every face of a listed simplex is listed, the boundary of a (k+1)-chain of `K`
is a k-chain of `K`: the boundary is a map `C_{k+1}(K) → C_k(K)`. -/
theorem boundary_mem_chains (K : PreAbstractSimplicialComplex ι) (k : ℕ)
    (c : Finset ι →₀ ℤ) (hc : c ∈ chains K (k + 1)) :
    boundary c ∈ chains K k := by
  rw [boundary, Finsupp.linearCombination_apply]
  refine Submodule.finsuppSum_mem (S := chains K k) (f := c)
    (g := fun s a => a • boundarySimplex s) (h := fun s hs => ?_)
  apply Submodule.smul_mem
  have hsK : s ∈ K ∧ s.card = k + 1 + 1 :=
    (Finsupp.mem_supported ℤ c).mp hc (Finset.mem_coe.mpr (Finsupp.mem_support_iff.mpr hs))
  rw [boundarySimplex_eq, ite_eq_right_of_eq_false _ _ (eq_false (by omega)), bsum]
  refine Submodule.sum_mem _ fun v hv => ?_
  apply Submodule.smul_mem
  refine Finsupp.single_mem_supported ℤ _ ⟨?_, ?_⟩
  · refine K.isRelLowerSet_faces.mem_of_le hsK.1 (Finset.erase_subset v s) ?_
    rw [← Finset.card_pos, Finset.card_erase_of_mem hv]; omega
  · rw [Finset.card_erase_of_mem hv]; omega

/-! The hollow tetrahedron, with the card's orders: edges [0,1], [0,2], [0,3], [1,2], [1,3],
[2,3]; triangles [0,1,2], [0,1,3], [0,2,3], [1,2,3]. -/

/-- The card's first boundary matrix, rows = vertices, columns = edges. -/
def d1 : Matrix (Fin 4) (Fin 6) ℤ :=
  !![-1, -1, -1, 0, 0, 0;
      1, 0, 0, -1, -1, 0;
      0, 1, 0, 1, 0, -1;
      0, 0, 1, 0, 1, 1]

/-- The card's second boundary matrix, rows = edges, columns = triangles. -/
def d2 : Matrix (Fin 6) (Fin 4) ℤ :=
  !![1, 1, 0, 0;
     -1, 0, 1, 0;
      0, -1, -1, 0;
      1, 0, 0, 1;
      0, 1, 0, -1;
      0, 0, 1, 1]

def tetVertices : Fin 4 → Finset ℕ := ![{0}, {1}, {2}, {3}]
def tetEdges : Fin 6 → Finset ℕ := ![{0, 1}, {0, 2}, {0, 3}, {1, 2}, {1, 3}, {2, 3}]
def tetTriangles : Fin 4 → Finset ℕ := ![{0, 1, 2}, {0, 1, 3}, {0, 2, 3}, {1, 2, 3}]

-- The boundary of the panel [0,1,2] is [1,2] - [0,2] + [0,1].
example : boundarySimplex ({0, 1, 2} : Finset ℕ) =
    Finsupp.single {1, 2} 1 - Finsupp.single {0, 2} 1 + Finsupp.single {0, 1} 1 := by
  rw [boundarySimplex_eq, ite_eq_right_of_eq_false _ _ (eq_false (by decide)), bsum, Finset.sum_insert (by decide),
    Finset.sum_insert (by decide), Finset.sum_singleton]
  have e0 : ({0, 1, 2} : Finset ℕ).erase 0 = {1, 2} := by decide
  have e1 : ({0, 1, 2} : Finset ℕ).erase 1 = {0, 2} := by decide
  have e2 : ({0, 1, 2} : Finset ℕ).erase 2 = {0, 1} := by decide
  have s0 : sgn ({0, 1, 2} : Finset ℕ) 0 = 1 := by decide
  have s1 : sgn ({0, 1, 2} : Finset ℕ) 1 = -1 := by decide
  have s2 : sgn ({0, 1, 2} : Finset ℕ) 2 = 1 := by decide
  rw [e0, e1, e2, s0, s1, s2, one_smul, one_smul, neg_one_smul, sub_eq_add_neg, add_assoc]

-- The card's matrices are the boundary rule written out: column j holds the boundary of the
-- j-th simplex.
example : ∀ i j, d1 i j = boundarySimplex (tetEdges j) (tetVertices i) := by
  intro i j
  fin_cases i <;> fin_cases j <;> simp only [boundarySimplex_apply, sgn] <;> decide

example : ∀ i j, d2 i j = boundarySimplex (tetTriangles j) (tetEdges i) := by
  intro i j
  fin_cases i <;> fin_cases j <;> simp only [boundarySimplex_apply, sgn] <;> decide

-- The 4 by 4 product of the two boundary matrices: all 16 entries are 0.
example : d1 * d2 = 0 := by decide

-- The shell (-1, 1, -1, 1) has boundary six zeros: it is a cycle.
example : d2.mulVec ![-1, 1, -1, 1] = 0 := by decide

-- Panel [0,1,2] lifted out: the boundary of the rest is its rim [0,1] - [0,2] + [1,2].
example : d2.mulVec ![0, 1, -1, 1] = ![1, -1, 0, 1, 0, 0] := by decide

-- The parts list: 4 vertices, 6 edges, 4 triangles of [0,1,2,3], and 4 - 6 + 4 = 2.
example : ((Finset.range 4).powerset.filter (fun s => s.card = 1)).card = 4 ∧
    ((Finset.range 4).powerset.filter (fun s => s.card = 2)).card = 6 ∧
    ((Finset.range 4).powerset.filter (fun s => s.card = 3)).card = 4 ∧
    (4 : ℤ) - 6 + 4 = 2 := by decide

#print axioms boundary_boundary_eq_zero
#print axioms boundary_mem_chains

end SimplicialChains
