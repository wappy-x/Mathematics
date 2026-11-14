-- The graph Laplacian: for a finite simple graph, the Laplacian's zero eigenvalues (with repeats) number exactly the connected pieces, it sums squared disagreement over links, and its second-smallest eigenvalue is at most four times the links cut by any half-and-half split divided by the number of vertices.
import Mathlib.Combinatorics.SimpleGraph.LapMatrix
import Mathlib.Analysis.Matrix.Spectrum

open Matrix Finset

variable {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V) [DecidableRel G.Adj]

lemma isHermitian_real_eigenvalues₀_mul_le {A : Matrix V V ℝ} (hA : A.IsHermitian)
    (i : Fin (Fintype.card V)) (hi : (i : ℕ) + 2 = Fintype.card V) (v : V → ℝ)
    (hv : v ⬝ᵥ ⇑(hA.eigenvectorBasis
      (Fintype.equivOfCardEq (Fintype.card_fin _) (⟨(i : ℕ) + 1, by omega⟩ : Fin _))) = 0) :
    hA.eigenvalues₀ i * (v ⬝ᵥ v) ≤ v ⬝ᵥ (A *ᵥ v) := by
  set e : Fin (Fintype.card V) ≃ V := Fintype.equivOfCardEq (Fintype.card_fin _) with he
  set k : Fin (Fintype.card V) := ⟨(i : ℕ) + 1, by omega⟩ with hk
  set U : Matrix V V ℝ := (hA.eigenvectorUnitary : Matrix V V ℝ) with hU
  have hspec : A = U * diagonal (RCLike.ofReal ∘ hA.eigenvalues) * star U := by
    conv_lhs => rw [hA.spectral_theorem]
    rfl
  have hUU : U * star U = 1 := Unitary.coe_mul_star_self _
  have hsU : star U = Uᵀ := by rw [star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial]
  rw [hsU] at hspec hUU
  set c : V → ℝ := Uᵀ *ᵥ v with hc
  have hq : v ⬝ᵥ (A *ᵥ v) = ∑ j, hA.eigenvalues j * c j ^ 2 := by
    have hAv : A *ᵥ v = U *ᵥ (diagonal (RCLike.ofReal ∘ hA.eigenvalues) *ᵥ (Uᵀ *ᵥ v)) := by
      conv_lhs => rw [hspec]
      rw [← mulVec_mulVec, ← mulVec_mulVec]
    rw [hAv, dotProduct_mulVec, ← mulVec_transpose, ← hc]
    simp only [dotProduct, mulVec_diagonal, Function.comp_apply, RCLike.ofReal_real_eq_id, id]
    refine Finset.sum_congr rfl fun j _ => ?_
    ring
  have hn : v ⬝ᵥ v = ∑ j, c j ^ 2 := by
    have h1 : v ⬝ᵥ v = v ⬝ᵥ ((U * Uᵀ) *ᵥ v) := by rw [hUU, one_mulVec]
    rw [h1, ← mulVec_mulVec, dotProduct_mulVec, ← mulVec_transpose, ← hc]
    simp only [dotProduct, sq]
  have hc0 : c (e k) = 0 := by
    rw [← hv, hc]
    simp only [mulVec, dotProduct, transpose_apply, hU,
      Matrix.IsHermitian.eigenvectorUnitary_apply]
    refine Finset.sum_congr rfl fun a _ => ?_
    ring
  rw [hq, hn, Finset.mul_sum]
  refine Finset.sum_le_sum fun j _ => ?_
  by_cases hj : j = e k
  · subst hj; rw [hc0]; simp
  · refine mul_le_mul_of_nonneg_right ?_ (sq_nonneg _)
    have h1 : hA.eigenvalues j = hA.eigenvalues₀ (e.symm j) := rfl
    rw [h1]
    apply hA.eigenvalues₀_antitone
    have h2 : e.symm j ≠ k := fun h => hj (by rw [← h]; simp)
    have h3 : ((e.symm j : Fin _) : ℕ) ≠ (i : ℕ) + 1 := fun h => h2 (Fin.ext h)
    have h4 := (e.symm j).isLt
    rw [Fin.le_def]; omega

#print axioms isHermitian_real_eigenvalues₀_mul_le

lemma dotProduct_lapMatrix_mulVec_sign (S : Finset V) :
    (fun w => if w ∈ S then (1 : ℝ) else -1) ⬝ᵥ
        (G.lapMatrix ℝ *ᵥ (fun w => if w ∈ S then (1 : ℝ) else -1)) =
      4 * (((S ×ˢ Sᶜ).filter fun p : V × V => G.Adj p.1 p.2).card : ℝ) := by
  rw [← toLinearMap₂'_apply', SimpleGraph.lapMatrix_toLinearMap₂']
  have key : ∀ i j : V,
      (if G.Adj i j then ((if i ∈ S then (1 : ℝ) else -1) - (if j ∈ S then (1 : ℝ) else -1)) ^ 2
        else 0) =
      (if G.Adj i j ∧ i ∈ S ∧ j ∉ S then (4 : ℝ) else 0) +
        (if G.Adj j i ∧ j ∈ S ∧ i ∉ S then (4 : ℝ) else 0) := by
    intro i j
    by_cases hij : G.Adj i j <;> by_cases hi : i ∈ S <;> by_cases hj : j ∈ S <;>
      simp [hij, hi, hj, G.adj_comm j i] <;> norm_num
  simp_rw [key, sum_add_distrib]
  rw [Finset.sum_comm (f := fun i j => if G.Adj j i ∧ j ∈ S ∧ i ∉ S then (4 : ℝ) else 0)]
  have hcut : ∑ i, ∑ j, (if G.Adj i j ∧ i ∈ S ∧ j ∉ S then (4 : ℝ) else 0) =
      4 * (((S ×ˢ Sᶜ).filter fun p : V × V => G.Adj p.1 p.2).card : ℝ) := by
    rw [← Fintype.sum_prod_type' (fun i j => if G.Adj i j ∧ i ∈ S ∧ j ∉ S then (4 : ℝ) else 0),
      Finset.sum_ite, sum_const_zero, add_zero, sum_const, nsmul_eq_mul, mul_comm]
    congr 3
    ext p
    simp only [mem_filter, mem_univ, true_and, mem_product, mem_compl]
    tauto
  rw [hcut]; ring

#print axioms dotProduct_lapMatrix_mulVec_sign

/-- Zero eigenvalues count the pieces: the number of eigenvalues of the graph Laplacian
`L = D - A` that equal 0, counted with repeats, is the number of connected pieces
of the graph. -/
theorem card_zero_eigenvalues_lapMatrix_eq_card_connectedComponent :
    (univ.filter fun i : V => (G.isHermitian_lapMatrix ℝ).eigenvalues i = 0).card =
      Fintype.card G.ConnectedComponent := by
  classical
  have hr := (G.isHermitian_lapMatrix ℝ).rank_eq_card_non_zero_eigs
  have hk := G.card_connectedComponent_eq_finrank_ker_toLin'_lapMatrix
  have hf := (G.lapMatrix ℝ).mulVecLin.finrank_range_add_finrank_ker
  rw [Module.finrank_fintype_fun_eq_card] at hf
  rw [Matrix.toLin'_apply'] at hk
  rw [Matrix.rank] at hr
  rw [Fintype.card_subtype] at hr
  have hc := Finset.card_filter_add_card_filter_not
    (s := (univ : Finset V)) (fun i => (G.isHermitian_lapMatrix ℝ).eigenvalues i = 0)
  rw [card_univ] at hc
  simp only [ne_eq] at hr
  omega

/-- The sum-of-squares identity: fed a labelling `x`, the Laplacian returns the total squared
disagreement across the links, `xᵀ L x = ∑ over links {u, v} of (x u - x v)²`. -/
theorem dotProduct_lapMatrix_mulVec_eq_sum_edges (x : V → ℝ) :
    x ⬝ᵥ (G.lapMatrix ℝ *ᵥ x) =
      ∑ e ∈ G.edgeFinset,
        Sym2.lift ⟨fun u v => (x u - x v) ^ 2, fun u v => by ring⟩ e := by
  set f : Sym2 V → ℝ := Sym2.lift ⟨fun u v => (x u - x v) ^ 2, fun u v => by ring⟩ with hf
  have h1 : x ⬝ᵥ (G.lapMatrix ℝ *ᵥ x) =
      (∑ i, ∑ j, if G.Adj i j then (x i - x j) ^ 2 else 0) / 2 := by
    rw [← G.lapMatrix_toLinearMap₂' ℝ x, Matrix.toLinearMap₂'_apply']
  have h2 : (∑ i, ∑ j, if G.Adj i j then (x i - x j) ^ 2 else 0) = ∑ d : G.Dart, f d.edge := by
    rw [← Fintype.sum_prod_type' (fun i j => if G.Adj i j then (x i - x j) ^ 2 else 0),
      ← Finset.sum_filter]
    symm
    refine Finset.sum_bij' (fun d _ => d.toProd) (fun p hp => ⟨p, (mem_filter.1 hp).2⟩)
      ?_ ?_ ?_ ?_ ?_
    · intro d _; simp
    · intro p _; simp
    · intro d _; rfl
    · intro p _; rfl
    · intro d _; rfl
  have h3 : ∑ d : G.Dart, f d.edge = 2 * ∑ e ∈ G.edgeFinset, f e := by
    rw [← Finset.sum_fiberwise_of_maps_to (g := SimpleGraph.Dart.edge) (t := G.edgeFinset)
      (fun d _ => by rw [SimpleGraph.mem_edgeFinset]; exact d.edge_mem), Finset.mul_sum]
    refine Finset.sum_congr rfl fun e he => ?_
    rw [Finset.sum_congr rfl (g := fun _ => f e) (fun d hd => by rw [(mem_filter.1 hd).2]),
      sum_const, nsmul_eq_mul]
    rw [G.dart_edge_fiber_card e (SimpleGraph.mem_edgeFinset.1 he)]
    norm_num
  rw [h1, h2, h3]; ring

/-- The second eigenvalue bounds every balanced cut from below: for every half-and-half split
`S` of the `n` vertices, the second-smallest Laplacian eigenvalue `λ₂` is at most
`4 · cut(S) / n`, where `cut(S)` is the number of links from `S` to the rest.
(Mathlib's `eigenvalues₀` lists the eigenvalues largest first, so `λ₂` is the entry at
position `n - 2`.) -/
theorem second_eigenvalue_lapMatrix_le_four_mul_cut_div (S : Finset V)
    (hS : 2 * S.card = Fintype.card V)
    (i : Fin (Fintype.card V)) (hi : (i : ℕ) + 2 = Fintype.card V) :
    (G.isHermitian_lapMatrix ℝ).eigenvalues₀ i ≤
      4 * (((S ×ˢ Sᶜ).filter fun p : V × V => G.Adj p.1 p.2).card : ℝ) /
        (Fintype.card V : ℝ) := by
  set hA := G.isHermitian_lapMatrix ℝ with hhA
  set u : V → ℝ := ⇑(hA.eigenvectorBasis
      (Fintype.equivOfCardEq (Fintype.card_fin _) (⟨(i : ℕ) + 1, by omega⟩ : Fin _))) with hu
  set x : V → ℝ := fun w => if w ∈ S then (1 : ℝ) else -1 with hx
  set one : V → ℝ := 1 with hone
  set cut : ℝ := (((S ×ˢ Sᶜ).filter fun p : V × V => G.Adj p.1 p.2).card : ℝ) with hcut
  set n : ℝ := (Fintype.card V : ℝ) with hn
  have hnpos : 0 < n := by rw [hn]; exact_mod_cast (by omega : 0 < Fintype.card V)
  have hQ : x ⬝ᵥ (G.lapMatrix ℝ *ᵥ x) = 4 * cut := dotProduct_lapMatrix_mulVec_sign G S
  have hcut0 : 0 ≤ cut := by positivity
  have h1x : one ⬝ᵥ x = 0 := by
    have hc := Finset.card_filter_add_card_filter_not (s := (univ : Finset V)) (· ∈ S)
    rw [card_univ, Finset.filter_mem_eq_inter, univ_inter] at hc
    simp only [hone, hx, one_dotProduct, Finset.sum_ite, sum_const, nsmul_eq_mul, mul_one,
      mul_neg, Finset.filter_mem_eq_inter, univ_inter]
    have : ((univ.filter fun a => a ∉ S).card : ℝ) = (S.card : ℝ) := by
      have : (univ.filter fun a => a ∉ S).card = S.card := by omega
      exact_mod_cast this
    rw [this]; ring
  have h11 : one ⬝ᵥ one = n := by simp [hone, hn, dotProduct]
  have hxx : x ⬝ᵥ x = n := by
    simp only [hx, hn, dotProduct]
    rw [← card_univ, Finset.card_eq_sum_ones, Nat.cast_sum]
    refine Finset.sum_congr rfl fun w _ => ?_
    split_ifs <;> norm_num
  have hL1 : G.lapMatrix ℝ *ᵥ one = 0 := G.lapMatrix_mulVec_one_eq_zero (R := ℝ)
  have h1Lx : one ⬝ᵥ (G.lapMatrix ℝ *ᵥ x) = 0 := by
    rw [dotProduct_mulVec, ← mulVec_transpose, (G.isSymm_lapMatrix (R := ℝ)).eq, hL1,
      zero_dotProduct]
  obtain ⟨a, c, hac, hvu⟩ : ∃ a c : ℝ, (a ≠ 0 ∨ c ≠ 0) ∧ (a • one + c • x) ⬝ᵥ u = 0 := by
    by_cases hp : x ⬝ᵥ u = 0
    · exact ⟨0, 1, Or.inr one_ne_zero, by simp [hp]⟩
    · exact ⟨x ⬝ᵥ u, -(one ⬝ᵥ u), Or.inl hp, by
        simp only [add_dotProduct, smul_dotProduct, smul_eq_mul]; ring⟩
  have hlow := isHermitian_real_eigenvalues₀_mul_le hA i hi (a • one + c • x) hvu
  have hvv : (a • one + c • x) ⬝ᵥ (a • one + c • x) = n * (a ^ 2 + c ^ 2) := by
    simp only [add_dotProduct, dotProduct_add, smul_dotProduct, dotProduct_smul, smul_eq_mul,
      h11, hxx, h1x, dotProduct_comm x one]
    ring
  have hvLv : (a • one + c • x) ⬝ᵥ (G.lapMatrix ℝ *ᵥ (a • one + c • x)) = c ^ 2 * (4 * cut) := by
    simp only [mulVec_add, mulVec_smul, hL1, smul_zero, zero_add, add_dotProduct,
      dotProduct_smul, smul_dotProduct, smul_eq_mul, h1Lx, hQ]
    ring
  rw [hvv, hvLv] at hlow
  have hpos : 0 < a ^ 2 + c ^ 2 := by
    rcases hac with h | h
    · have := pow_pos (abs_pos.2 h) 2; rw [sq_abs] at this; positivity
    · have := pow_pos (abs_pos.2 h) 2; rw [sq_abs] at this; positivity
  rw [le_div_iff₀ hnpos]
  have h2 : c ^ 2 * (4 * cut) ≤ (a ^ 2 + c ^ 2) * (4 * cut) := by
    apply mul_le_mul_of_nonneg_right _ (by positivity); nlinarith [sq_nonneg a]
  have h3 : (hA.eigenvalues₀ i * n) * (a ^ 2 + c ^ 2) ≤ (4 * cut) * (a ^ 2 + c ^ 2) := by
    nlinarith
  exact le_of_mul_le_mul_right h3 hpos

/-! ## The card's six friends: Ana 0, Ben 1, Cal 2, Dev 3, Eve 4, Fay 5, one bridge Cal–Dev -/

/-- The seven links of the six friends. -/
def sixEdges : List (ℕ × ℕ) := [(0, 1), (0, 2), (1, 2), (2, 3), (3, 4), (3, 5), (4, 5)]

/-- The six friends as a simple graph on `Fin 6`. -/
def sixFriends : SimpleGraph (Fin 6) where
  Adj a b := (a.val, b.val) ∈ sixEdges ∨ (b.val, a.val) ∈ sixEdges
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel sixFriends.Adj := fun a b =>
  inferInstanceAs (Decidable ((a.val, b.val) ∈ sixEdges ∨ (b.val, a.val) ∈ sixEdges))

-- Degrees, Ana to Fay: 2, 2, 3, 3, 2, 2.
example : (List.finRange 6).map (fun v => sixFriends.degree v) = [2, 2, 3, 3, 2, 2] := by
  decide

-- Cal's row of L: -1, -1, 3, -1, 0, 0.
example : (List.finRange 6).map (fun v => sixFriends.lapMatrix ℤ 2 v) = [-1, -1, 3, -1, 0, 0] := by
  decide

-- The sign split Ana, Ben, Cal | Dev, Eve, Fay cuts exactly 1 link.
example : ((({0, 1, 2} : Finset (Fin 6)) ×ˢ ({0, 1, 2} : Finset (Fin 6))ᶜ).filter
    (fun p => sixFriends.Adj p.1 p.2)).card = 1 := by
  decide

-- The 5,000 people: the planted town split cuts 1,250 links, so 4 · 1250 / 5000 = 1;
-- with 20,000 links across, 4 · 20000 / 5000 = 16.
example : (4 * 1250 : ℚ) / 5000 = 1 := by norm_num
example : (4 * 20000 : ℚ) / 5000 = 16 := by norm_num

#print axioms card_zero_eigenvalues_lapMatrix_eq_card_connectedComponent
#print axioms dotProduct_lapMatrix_mulVec_eq_sum_edges
#print axioms second_eigenvalue_lapMatrix_le_four_mul_cut_div
