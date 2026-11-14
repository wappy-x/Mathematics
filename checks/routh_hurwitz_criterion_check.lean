-- Routh-Hurwitz: for a real polynomial whose Routh array has no zero in its first column, the number of roots with positive real part equals the number of sign changes down that column, so no sign change means every root has negative real part; for the workshop cubic s^3 + 6s^2 + 11s + (6 + 5K) that happens exactly when -6/5 < K < 12.
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Topology.MetricSpace.Sequences

open Polynomial

/-- One step of the Routh rule. With the row two above written `x` = x_0, x_1, ... and the row
just above written `y` = y_0, y_1, ..., the new row has entries
z_j = (y_0 x_(j+1) - x_0 y_(j+1)) / y_0, one fewer than `x`; a missing entry counts as 0. -/
noncomputable def routhNext (x y : List ℝ) : List ℝ :=
  (List.range (x.length - 1)).map fun j =>
    (y.getD 0 0 * x.getD (j + 1) 0 - x.getD 0 0 * y.getD (j + 1) 0) / y.getD 0 0

/-- The first entries of `k` rows of the Routh array that starts with rows `x` and `y`. -/
noncomputable def routhColumnFrom : ℕ → List ℝ → List ℝ → List ℝ
  | 0, _, _ => []
  | k + 1, x, y => x.getD 0 0 :: routhColumnFrom k y (routhNext x y)

/-- The first column of the Routh array of a real polynomial p of degree n: the top row is
a_n, a_(n-2), a_(n-4), ..., the next row is a_(n-1), a_(n-3), ..., and there are n + 1 rows,
s^n down to s^0. -/
noncomputable def routhColumn (p : ℝ[X]) : List ℝ :=
  let n := p.natDegree
  routhColumnFrom (n + 1)
    ((List.range (n / 2 + 1)).map fun i => p.coeff (n - 2 * i))
    ((List.range ((n + 1) / 2)).map fun i => p.coeff (n - 1 - 2 * i))

/-- The number of sign changes down a column c_0, c_1, ..., c_m: the number of k with
c_k c_(k+1) < 0. -/
noncomputable def signChanges (c : List ℝ) : ℕ :=
  ((c.zip c.tail).filter fun ab => decide (ab.1 * ab.2 < 0)).length

/-- The number of roots of a real polynomial in the right half-plane (positive real part),
each counted as often as it repeats. -/
noncomputable def rhpRootCount (p : ℝ[X]) : ℕ :=
  Multiset.card ((p.map (algebraMap ℝ ℂ)).roots.filter fun z => 0 < z.re)

lemma rh_root_norm_le (p : ℂ[X]) (b : ℕ → ℝ) (hc : p.leadingCoeff ≠ 0)
    (hb : ∀ i < p.natDegree, ‖p.coeff i‖ ≤ b i) {z : ℂ} (hz : p.eval z = 0) :
    ‖z‖ ≤ 1 + (∑ i ∈ Finset.range p.natDegree, b i) / ‖p.leadingCoeff‖ := by
  set n := p.natDegree with hn
  set S := ∑ i ∈ Finset.range n, b i
  have hS : 0 ≤ S := Finset.sum_nonneg fun i hi =>
    (norm_nonneg _).trans (hb i (Finset.mem_range.1 hi))
  have hcpos : 0 < ‖p.leadingCoeff‖ := norm_pos_iff.2 hc
  by_contra h
  push Not at h
  have hz1 : 1 < ‖z‖ := by
    have : 0 ≤ S / ‖p.leadingCoeff‖ := div_nonneg hS hcpos.le
    linarith
  have hSz : S < ‖p.leadingCoeff‖ * ‖z‖ := by
    have : S / ‖p.leadingCoeff‖ < ‖z‖ := by linarith
    rw [div_lt_iff₀ hcpos] at this; linarith
  rw [eval_eq_sum_range, Finset.sum_range_succ] at hz
  have hlead : p.coeff n * z ^ n = -∑ i ∈ Finset.range n, p.coeff i * z ^ i := by
    linear_combination hz
  have key : ‖∑ i ∈ Finset.range n, p.coeff i * z ^ i‖ ≤ S * ‖z‖ ^ n / ‖z‖ := by
    calc _ ≤ ∑ i ∈ Finset.range n, ‖p.coeff i * z ^ i‖ := norm_sum_le _ _
      _ ≤ ∑ i ∈ Finset.range n, b i * (‖z‖ ^ n / ‖z‖) := by
          apply Finset.sum_le_sum
          intro i hi
          rw [Finset.mem_range] at hi
          rw [norm_mul, norm_pow]
          apply mul_le_mul (hb i hi) _ (by positivity) ((norm_nonneg _).trans (hb i hi))
          rw [le_div_iff₀ (by linarith), ← pow_succ]
          exact pow_le_pow_right₀ hz1.le hi
      _ = S * ‖z‖ ^ n / ‖z‖ := by rw [← Finset.sum_mul]; ring
  have h2 : ‖p.coeff n * z ^ n‖ = ‖p.leadingCoeff‖ * ‖z‖ ^ n := by
    rw [norm_mul, norm_pow]; rfl
  rw [hlead, norm_neg] at h2
  have hzn : 0 < ‖z‖ ^ n := by positivity
  have : S * ‖z‖ ^ n / ‖z‖ < ‖p.leadingCoeff‖ * ‖z‖ ^ n := by
    rw [div_lt_iff₀ (by linarith)]; nlinarith
  linarith
#print axioms rh_root_norm_le

lemma rh_prod_map_eq (f : ℂ → ℂ) : ∀ l : List ℂ,
    (l.map f).prod = ∏ i ∈ Finset.range l.length, f (l.getD i 0)
  | [] => by simp
  | a :: l => by
    rw [List.map_cons, List.prod_cons, rh_prod_map_eq f l, List.length_cons,
      Finset.prod_range_succ']
    simp [mul_comm]
#print axioms rh_prod_map_eq

lemma rh_getD_of_lt {l : List ℂ} {i : ℕ} (h : i < l.length) : l.getD i 0 = l[i] := by
  simp [List.getD_eq_getElem?_getD, h]
#print axioms rh_getD_of_lt

lemma rh_getD_append_left (a b : List ℂ) {i : ℕ} (h : i < a.length) :
    (a ++ b).getD i 0 = a[i] := by
  rw [rh_getD_of_lt (by simp; omega), List.getElem_append_left h]
#print axioms rh_getD_append_left

lemma rh_getD_append_right (a b : List ℂ) {i : ℕ} (h1 : a.length ≤ i)
    (h2 : i - a.length < b.length) : (a ++ b).getD i 0 = b[i - a.length] := by
  rw [rh_getD_of_lt (by simp; omega), List.getElem_append_right h1]
#print axioms rh_getD_append_right

lemma rh_root_repr (p : ℂ[X]) (hp : p ≠ 0) (P : ℂ → Prop) [DecidablePred P] :
    ∃ r : Fin p.natDegree → ℂ, (∀ i, p.eval (r i) = 0) ∧
      (∀ i : Fin p.natDegree, (i : ℕ) < Multiset.card (p.roots.filter P) → P (r i)) ∧
      (∀ i : Fin p.natDegree, Multiset.card (p.roots.filter P) ≤ i → ¬ P (r i)) ∧
      ∀ z, p.eval z = p.leadingCoeff * ∏ i, (z - r i) := by
  set A := p.roots.filter P with hA
  set B := p.roots.filter (fun z => ¬ P z) with hB
  set l := A.toList ++ B.toList with hl
  have hAB : (l : Multiset ℂ) = p.roots := by
    rw [hl, ← Multiset.coe_add, Multiset.coe_toList, Multiset.coe_toList, hA, hB,
      Multiset.filter_add_not]
  have hlen : l.length = p.natDegree := by
    rw [← Multiset.coe_card, hAB, IsAlgClosed.card_roots_eq_natDegree]
  have hmem : ∀ i < l.length, l.getD i 0 ∈ p.roots := by
    intro i hi
    rw [← hAB, Multiset.mem_coe, rh_getD_of_lt hi]
    exact List.getElem_mem hi
  refine ⟨fun i => l.getD i 0, ?_, ?_, ?_, ?_⟩
  · intro i
    have := hmem i (by omega)
    exact (mem_roots hp).1 this
  · intro i hi
    have hiA : (i : ℕ) < A.toList.length := by rwa [Multiset.length_toList]
    have : l.getD i 0 = A.toList[(i : ℕ)] := by
      exact rh_getD_append_left _ _ hiA
    simp only [this]
    have hm := List.getElem_mem hiA
    rw [Multiset.mem_toList] at hm
    exact (Multiset.mem_filter.1 hm).2
  · intro i hi
    have hiA : A.toList.length ≤ (i : ℕ) := by rwa [Multiset.length_toList]
    have hi2 : (i : ℕ) < l.length := by omega
    have hiB : (i : ℕ) - A.toList.length < B.toList.length := by
      rw [hl, List.length_append] at hi2; omega
    have : l.getD i 0 = B.toList[(i : ℕ) - A.toList.length] := by
      exact rh_getD_append_right _ _ hiA hiB
    simp only [this]
    have hm := List.getElem_mem hiB
    rw [Multiset.mem_toList] at hm
    exact (Multiset.mem_filter.1 hm).2
  · intro z
    conv_lhs => rw [← C_leadingCoeff_mul_prod_multiset_X_sub_C (p := p)
      IsAlgClosed.card_roots_eq_natDegree]
    rw [eval_mul, eval_C, eval_multiset_prod, Multiset.map_map, ← hAB, Multiset.map_coe,
      Multiset.prod_coe]
    congr 1
    rw [rh_prod_map_eq, hlen, ← Fin.prod_univ_eq_prod_range]
    simp
#print axioms rh_root_repr

lemma rh_root_repr' (p : ℂ[X]) (hp : p ≠ 0) (P : ℂ → Prop) [DecidablePred P] (n : ℕ)
    (hn : p.natDegree = n) :
    ∃ r : Fin n → ℂ, (∀ i, p.eval (r i) = 0) ∧
      (∀ i : Fin n, (i : ℕ) < Multiset.card (p.roots.filter P) → P (r i)) ∧
      (∀ i : Fin n, Multiset.card (p.roots.filter P) ≤ i → ¬ P (r i)) ∧
      ∀ z, p.eval z = p.leadingCoeff * ∏ i, (z - r i) := by
  subst hn; exact rh_root_repr p hp P
#print axioms rh_root_repr'

lemma rh_level_closed (F G : ℝ[X]) (hG : G.degree < F.degree)
    (hax : ∀ t ∈ Set.Icc (0:ℝ) 1, ∀ s : ℂ, s.re = 0 → aeval s (F + C t * G) ≠ 0) (d : ℕ) :
    IsClosed {t : ℝ | t ∈ Set.Icc (0:ℝ) 1 ∧ rhpRootCount (F + C t * G) = d} := by
  apply IsSeqClosed.isClosed
  intro tk ts htk hlim
  have hts : ts ∈ Set.Icc (0:ℝ) 1 :=
    isClosed_Icc.mem_of_tendsto hlim (Filter.Eventually.of_forall fun k => (htk k).1)
  refine ⟨hts, ?_⟩
  set n := F.natDegree
  set c := F.leadingCoeff
  have hF : F ≠ 0 := by rintro rfl; simp at hG
  have hc : c ≠ 0 := leadingCoeff_ne_zero.2 hF
  have hcC : (c : ℂ) ≠ 0 := by exact_mod_cast hc
  set H : ℝ → ℂ[X] := fun t => (F + C t * G).map (algebraMap ℝ ℂ) with hH
  have hdegt : ∀ t : ℝ, (C t * G).degree < F.degree := by
    intro t; by_cases ht : t = 0
    · subst ht; simp only [map_zero, zero_mul, degree_zero]; exact lt_of_le_of_lt bot_le hG
    · rw [degree_C_mul ht]; exact hG
  have hnat : ∀ t : ℝ, (H t).natDegree = n := fun t => by
    simp only [H]; rw [natDegree_map, natDegree_add_eq_left_of_degree_lt (hdegt t)]
  have hlc : ∀ t : ℝ, (H t).leadingCoeff = (c : ℂ) := fun t => by
    simp only [H]; rw [leadingCoeff_map, leadingCoeff_add_of_degree_lt' (hdegt t)]; rfl
  have hHne : ∀ t, H t ≠ 0 := fun t h => by
    have := hlc t; rw [h, leadingCoeff_zero] at this; exact hcC this.symm
  have heval : ∀ (t : ℝ) (z : ℂ), (H t).eval z = aeval z F + (t:ℂ) * aeval z G := by
    intro t z; simp [H, eval_map_algebraMap]
  set R : ℝ := 1 + (∑ i ∈ Finset.range n, (|F.coeff i| + |G.coeff i|)) / ‖(c : ℂ)‖ with hR
  have hR0 : 0 ≤ R := by positivity
  have hbound : ∀ t ∈ Set.Icc (0:ℝ) 1, ∀ z, (H t).eval z = 0 → ‖z‖ ≤ R := by
    intro t ht z hz
    have := rh_root_norm_le (H t) (fun i => |F.coeff i| + |G.coeff i|) (by rw [hlc]; exact hcC)
      ?_ hz
    · rwa [hnat, hlc] at this
    · intro i _
      simp only [H, coeff_map, coeff_add, coeff_C_mul, Complex.coe_algebraMap, Complex.norm_real,
        Real.norm_eq_abs]
      have h1 := abs_add_le (F.coeff i) (t * G.coeff i)
      rw [abs_mul, abs_of_nonneg ht.1] at h1
      have h2 : t * |G.coeff i| ≤ |G.coeff i| := by
        nlinarith [abs_nonneg (G.coeff i), ht.2]
      linarith
  have hcount : ∀ k, Multiset.card ((H (tk k)).roots.filter fun z => 0 < z.re) = d :=
    fun k => (htk k).2
  have hd : d ≤ n := by
    rw [← hcount 0, ← hnat (tk 0), ← IsAlgClosed.card_roots_eq_natDegree]
    exact Multiset.card_le_card (Multiset.filter_le _ _)
  choose r hr0 hr1 hr2 hr3 using
    fun k => rh_root_repr' (H (tk k)) (hHne _) (fun z : ℂ => 0 < z.re) n (hnat _)
  have hrb : ∀ k, r k ∈ Metric.closedBall (0 : Fin n → ℂ) R := by
    intro k
    rw [mem_closedBall_zero_iff, pi_norm_le_iff_of_nonneg hR0]
    intro i; exact hbound _ (htk k).1 _ (hr0 k i)
  obtain ⟨rs, -, φ, hφ, hlimr⟩ := tendsto_subseq_of_bounded Metric.isBounded_closedBall hrb
  have hlim_i : ∀ i, Filter.Tendsto (fun k => r (φ k) i) Filter.atTop (nhds (rs i)) :=
    fun i => ((continuous_apply i).tendsto rs).comp hlimr
  have htφ : Filter.Tendsto (fun k => tk (φ k)) Filter.atTop (nhds ts) :=
    hlim.comp hφ.tendsto_atTop
  have hevalS : ∀ z, (H ts).eval z = (c:ℂ) * ∏ i, (z - rs i) := by
    intro z
    have h1 : Filter.Tendsto (fun k => (H (tk (φ k))).eval z) Filter.atTop
        (nhds ((H ts).eval z)) := by
      simp only [heval]
      exact tendsto_const_nhds.add
        (((Complex.continuous_ofReal.tendsto ts).comp htφ).mul tendsto_const_nhds)
    have h2 : Filter.Tendsto (fun k => (H (tk (φ k))).eval z) Filter.atTop
        (nhds ((c:ℂ) * ∏ i, (z - rs i))) := by
      have : (fun k => (H (tk (φ k))).eval z) = fun k => (c:ℂ) * ∏ i, (z - r (φ k) i) := by
        funext k; rw [hr3, hlc]
      rw [this]
      exact tendsto_const_nhds.mul
        (tendsto_finsetProd _ fun i _ => tendsto_const_nhds.sub (hlim_i i))
    exact tendsto_nhds_unique h1 h2
  have hHs : H ts = C (c:ℂ) * ((Finset.univ.val.map rs).map fun a => X - C a).prod := by
    apply Polynomial.funext; intro z
    rw [hevalS, eval_mul, eval_C, eval_multiset_prod, Multiset.map_map, Multiset.map_map]
    congr 1
    simp [Finset.prod_eq_multiset_prod]
  have hroots : (H ts).roots = Finset.univ.val.map rs := by
    rw [hHs, roots_C_mul _ hcC, roots_multiset_prod_X_sub_C]
  show Multiset.card ((H ts).roots.filter fun z => 0 < z.re) = d
  rw [hroots, Multiset.filter_map, Multiset.card_map]
  have hset : Finset.univ.filter (fun i : Fin n => 0 < (rs i).re) =
      Finset.univ.filter (fun i : Fin n => (i:ℕ) < d) := by
    ext i
    simp only [Finset.mem_filter, Finset.mem_univ, true_and]
    constructor
    · intro h
      by_contra h'
      push Not at h'
      have : (rs i).re ≤ 0 :=
        le_of_tendsto' ((Complex.continuous_re.tendsto _).comp (hlim_i i)) (fun k => by
          have := hr2 (φ k) i (by rw [hcount]; exact h')
          push Not at this; exact this)
      linarith
    · intro h
      have hge : 0 ≤ (rs i).re :=
        ge_of_tendsto' ((Complex.continuous_re.tendsto _).comp (hlim_i i))
          (fun k => (hr1 (φ k) i (by rw [hcount]; exact h)).le)
      rcases hge.lt_or_eq with h1 | h1
      · exact h1
      · exfalso
        apply hax ts hts (rs i) h1.symm
        have : (H ts).eval (rs i) = 0 := by
          rw [hevalS, Finset.prod_eq_zero (Finset.mem_univ i) (sub_self _), mul_zero]
        simpa [H, eval_map_algebraMap] using this
  have hc2 := congrArg Finset.card hset
  rw [Fin.card_filter_val_lt, min_eq_right hd] at hc2
  rw [← hc2]
  rfl
#print axioms rh_level_closed

lemma rh_homotopy (F G : ℝ[X]) (hG : G.degree < F.degree)
    (hax : ∀ t ∈ Set.Icc (0:ℝ) 1, ∀ s : ℂ, s.re = 0 → aeval s (F + C t * G) ≠ 0) :
    rhpRootCount F = rhpRootCount (F + G) := by
  set N := fun t : ℝ => rhpRootCount (F + C t * G) with hNdef
  have hN0 : N 0 = rhpRootCount F := by simp [N]
  have hN1 : N 1 = rhpRootCount (F + G) := by simp [N]
  have hdegt : ∀ t : ℝ, (C t * G).degree < F.degree := by
    intro t; by_cases ht : t = 0
    · subst ht; simp only [map_zero, zero_mul, degree_zero]; exact lt_of_le_of_lt bot_le hG
    · rw [degree_C_mul ht]; exact hG
  have hbd : ∀ t, N t ≤ F.natDegree := by
    intro t
    simp only [N, rhpRootCount]
    calc _ ≤ Multiset.card ((F + C t * G).map (algebraMap ℝ ℂ)).roots :=
          Multiset.card_le_card (Multiset.filter_le _ _)
      _ ≤ ((F + C t * G).map (algebraMap ℝ ℂ)).natDegree := card_roots' _
      _ = F.natDegree := by rw [natDegree_map, natDegree_add_eq_left_of_degree_lt (hdegt t)]
  set L : ℕ → Set ℝ := fun d => {t : ℝ | t ∈ Set.Icc (0:ℝ) 1 ∧ N t = d} with hL
  have hcl : ∀ d, IsClosed (L d) := rh_level_closed F G hG hax
  have key := (isPreconnected_iff_subset_of_disjoint_closed.1 (isPreconnected_Icc (a := (0:ℝ)) (b := 1))) (L (N 0))
    (⋃ d ∈ (Finset.range (F.natDegree + 1)).erase (N 0), L d) (hcl _)
    (isClosed_biUnion_finset fun d _ => hcl d) ?cover ?disj
  · rcases key with h | h
    · have := (h ⟨zero_le_one, le_refl (1:ℝ)⟩)
      rw [← hN0, ← hN1]; exact this.2.symm
    · exfalso
      have := h ⟨le_refl (0:ℝ), zero_le_one⟩
      simp only [Set.mem_iUnion, Finset.mem_erase, Finset.mem_range] at this
      obtain ⟨d, ⟨hd1, _⟩, hd2⟩ := this
      exact hd1 hd2.2.symm
  · intro t ht
    by_cases h : N t = N 0
    · exact Or.inl ⟨ht, h⟩
    · refine Or.inr ?_
      simp only [Set.mem_iUnion, Finset.mem_erase, Finset.mem_range]
      exact ⟨N t, ⟨h, Nat.lt_succ_of_le (hbd t)⟩, ht, rfl⟩
  · ext t
    simp only [Set.mem_inter_iff, Set.mem_iUnion, Finset.mem_erase, Finset.mem_range,
      Set.mem_empty_iff_false, iff_false]
    rintro ⟨_, ⟨_, h1⟩, d, ⟨hd, _⟩, _, h2⟩
    exact hd (h2.symm.trans h1)
#print axioms rh_homotopy

lemma rh_getD_map_range (f : ℕ → ℝ) (n i : ℕ) :
    ((List.range n).map f).getD i 0 = if i < n then f i else 0 := by
  by_cases h : i < n <;> simp [List.getD_eq_getElem?_getD, h]
#print axioms rh_getD_map_range

lemma rh_getD_of_length_le (l : List ℝ) {i : ℕ} (h : l.length ≤ i) : l.getD i 0 = 0 := by
  simp [List.getD_eq_getElem?_getD, h]
#print axioms rh_getD_of_length_le

lemma rh_routhNext_getD (x y : List ℝ) (j : ℕ) :
    (routhNext x y).getD j 0 = if j < x.length - 1 then
      (y.getD 0 0 * x.getD (j + 1) 0 - x.getD 0 0 * y.getD (j + 1) 0) / y.getD 0 0 else 0 := by
  rw [routhNext, rh_getD_map_range]
#print axioms rh_routhNext_getD

lemma rh_routhNext_length (x y : List ℝ) : (routhNext x y).length = x.length - 1 := by
  simp [routhNext]
#print axioms rh_routhNext_length

/-- The polynomial carried by one row of the Routh array, read from degree `m` down in steps
of two. -/
noncomputable def rhRowPoly (m : ℕ) (x : List ℝ) : ℝ[X] :=
  ∑ i ∈ Finset.range (m / 2 + 1), C (x.getD i 0) * X ^ (m - 2 * i)
#print axioms rhRowPoly

lemma rh_coeff_rowPoly (m : ℕ) (x : List ℝ) (k : ℕ) :
    (rhRowPoly m x).coeff k =
      if k ≤ m ∧ (m - k) % 2 = 0 then x.getD ((m - k) / 2) 0 else 0 := by
  simp only [rhRowPoly, finsetSum_coeff, coeff_C_mul_X_pow]
  split_ifs with h
  · rw [Finset.sum_eq_single ((m - k) / 2)]
    · rw [if_pos (by omega)]
    · intro b hb1 hb; rw [Finset.mem_range] at hb1; rw [if_neg (by omega)]
    · intro hn; exfalso; apply hn; rw [Finset.mem_range]; omega
  · apply Finset.sum_eq_zero; intro i hi; rw [Finset.mem_range] at hi; rw [if_neg (by omega)]
#print axioms rh_coeff_rowPoly

lemma rh_aeval_neg_rowPoly (m : ℕ) (x : List ℝ) (s : ℂ) :
    aeval (-s) (rhRowPoly m x) = (-1) ^ m * aeval s (rhRowPoly m x) := by
  simp only [rhRowPoly, map_sum, map_mul, aeval_C, map_pow, aeval_X, Finset.mul_sum]
  apply Finset.sum_congr rfl
  intro i hi
  rw [Finset.mem_range] at hi
  have h : (-1 : ℂ) ^ m = (-1) ^ (m - 2 * i) := by
    conv_lhs => rw [show m = (m - 2 * i) + 2 * i by omega]
    rw [pow_add, pow_mul]; norm_num
  rw [neg_pow, h]; ring
#print axioms rh_aeval_neg_rowPoly

lemma rh_aeval_conj (p : ℝ[X]) (s : ℂ) :
    aeval ((starRingEnd ℂ) s) p = (starRingEnd ℂ) (aeval s p) := by
  have := aeval_algHom_apply (Complex.conjAe.toAlgHom) s p
  simpa using this
#print axioms rh_aeval_conj

lemma rh_signChanges_cons_cons (a b : ℝ) (l : List ℝ) :
    signChanges (a :: b :: l) = (if a * b < 0 then 1 else 0) + signChanges (b :: l) := by
  simp only [signChanges, List.tail_cons, List.zip_cons_cons, List.filter_cons]
  split_ifs <;> simp_all <;> omega
#print axioms rh_signChanges_cons_cons

lemma rh_step_identity (m : ℕ) (x y : List ℝ) (hx : x.length = (m + 1) / 2 + 1)
    (hy : y.length = (m + 2) / 2) (hy0 : y.getD 0 0 ≠ 0) :
    rhRowPoly (m + 1) x = C (x.getD 0 0 / y.getD 0 0) * X * rhRowPoly m y +
      rhRowPoly (m - 1) (routhNext x y) := by
  ext k
  rw [coeff_add, mul_assoc, coeff_C_mul]
  rcases k with _ | j
  · simp only [mul_coeff_zero, coeff_X_zero, zero_mul, mul_zero, zero_add, rh_coeff_rowPoly,
      rh_routhNext_getD, hx]
    by_cases hm : m % 2 = 1
    · rw [if_pos (by omega), if_pos (by omega), if_pos (by omega)]
      have e2 : (m - 1 - 0) / 2 + 1 = (m + 1 - 0) / 2 := by omega
      rw [e2, rh_getD_of_length_le y (i := (m + 1 - 0) / 2) (by omega)]
      field_simp
      ring
    · rw [if_neg (by omega)]
      split_ifs <;> first | (exfalso; omega) | rfl
  · simp only [coeff_X_mul, rh_coeff_rowPoly, rh_routhNext_getD, hx]
    by_cases hA : j ≤ m ∧ (m - j) % 2 = 0
    · rw [if_pos (by omega), if_pos hA]
      have e1 : (m + 1 - (j + 1)) / 2 = (m - j) / 2 := by omega
      rw [e1]
      by_cases hj : j = m
      · subst hj
        rw [if_neg (by omega)]
        simp only [Nat.sub_self, Nat.zero_div]
        field_simp
        ring
      · rw [if_pos (by omega), if_pos (by omega)]
        have e2 : (m - 1 - (j + 1)) / 2 + 1 = (m - j) / 2 := by omega
        rw [e2]
        field_simp
        ring
    · rw [if_neg (by omega), if_neg hA, if_neg (by omega)]
      ring
#print axioms rh_step_identity

lemma rh_count_mul_linear (β : ℝ) (hβ : β ≠ 0) (Q : ℝ[X]) (hQ : Q ≠ 0) :
    rhpRootCount ((C β * X + 1) * Q) = rhpRootCount Q + (if β < 0 then 1 else 0) := by
  unfold rhpRootCount
  have hβC : (β : ℂ) ≠ 0 := by exact_mod_cast hβ
  have h1 : (C β * X + 1 : ℝ[X]).map (algebraMap ℝ ℂ) = C (β : ℂ) * (X - C (-(1 / (β : ℂ)))) := by
    rw [mul_sub, ← C_mul]
    have : (β : ℂ) * -(1 / β) = -1 := by field_simp
    rw [this]
    simp
  have hlin : C (β : ℂ) * (X - C (-(1 / (β : ℂ)))) ≠ 0 :=
    mul_ne_zero (by simpa using hβC) (X_sub_C_ne_zero _)
  have hQc : Q.map (algebraMap ℝ ℂ) ≠ 0 := (Polynomial.map_ne_zero_iff
    (algebraMap ℝ ℂ).injective).2 hQ
  rw [Polynomial.map_mul, h1, roots_mul (mul_ne_zero hlin hQc), roots_C_mul _ hβC,
    roots_X_sub_C, Multiset.filter_add, Multiset.card_add, Multiset.filter_singleton]
  have hre : (-(1 / (β : ℂ))).re = -(1 / β) := by
    rw [show (-(1 / (β : ℂ))) = ((-(1 / β) : ℝ) : ℂ) by push_cast; ring, Complex.ofReal_re]
  by_cases hb : β < 0
  · have h2 : 0 < (-(1 / (β : ℂ))).re := by
      rw [hre]; have : 1 / β < 0 := by rw [one_div]; exact inv_lt_zero.2 hb
      linarith
    rw [if_pos h2, if_pos hb]
    simp [add_comm]
  · have h2 : ¬ 0 < (-(1 / (β : ℂ))).re := by
      rw [hre]
      have : 0 < 1 / β := by
        rw [one_div]; exact inv_pos.2 (lt_of_le_of_ne (not_lt.1 hb) (Ne.symm hβ))
      linarith
    rw [if_neg h2, if_neg hb]
    simp
#print axioms rh_count_mul_linear

lemma rh_main (m : ℕ) : ∀ x y : List ℝ, x.length = m / 2 + 1 → y.length = (m + 1) / 2 →
    (∀ c ∈ routhColumnFrom (m + 1) x y, c ≠ 0) →
    (∀ s : ℂ, s.re = 0 → aeval s (rhRowPoly m x + rhRowPoly (m - 1) y) ≠ 0) ∧
    rhpRootCount (rhRowPoly m x + rhRowPoly (m - 1) y) =
      signChanges (routhColumnFrom (m + 1) x y) := by
  induction m with
  | zero =>
    intro x y hx hy hne
    have hy' : y = [] := List.length_eq_zero_iff.1 (by simpa using hy)
    subst hy'
    have hx0 : x.getD 0 0 ≠ 0 := hne _ (by simp [routhColumnFrom])
    have hP : rhRowPoly 0 x + rhRowPoly (0 - 1) [] = C (x.getD 0 0) := by
      simp [rhRowPoly]
    rw [hP]
    refine ⟨fun s _ => by simpa using hx0, ?_⟩
    simp [rhpRootCount, signChanges, routhColumnFrom]
  | succ m ih =>
    intro x y hx hy hne
    set z := routhNext x y with hz
    set x0 := x.getD 0 0 with hx0def
    set y0 := y.getD 0 0 with hy0def
    have hcol : routhColumnFrom (m + 1 + 1) x y = x0 :: routhColumnFrom (m + 1) y z := rfl
    have hcol2 : routhColumnFrom (m + 1) y z = y0 :: routhColumnFrom m z (routhNext y z) := rfl
    have hx0 : x0 ≠ 0 := hne _ (by rw [hcol]; exact List.mem_cons_self ..)
    have hy0 : y0 ≠ 0 := hne _ (by rw [hcol, hcol2]; simp)
    have hne' : ∀ c ∈ routhColumnFrom (m + 1) y z, c ≠ 0 := fun c hc =>
      hne c (by rw [hcol]; exact List.mem_cons_of_mem _ hc)
    have hylen : y.length = m / 2 + 1 := by rw [hy]; omega
    have hzlen : z.length = (m + 1) / 2 := by rw [hz, rh_routhNext_length, hx]; omega
    obtain ⟨ihax, ihcount⟩ := ih y z hylen hzlen hne'
    have hid : rhRowPoly (m + 1) x = C (x0 / y0) * X * rhRowPoly m y + rhRowPoly (m - 1) z :=
      rh_step_identity m x y hx (by omega) hy0
    have hP : rhRowPoly (m + 1) x + rhRowPoly (m + 1 - 1) y =
        C (x0 / y0) * X * rhRowPoly m y + rhRowPoly (m - 1) z + rhRowPoly m y := by
      rw [hid, Nat.add_sub_cancel]
    have hpar1 : ∀ s : ℂ, aeval (-s) (rhRowPoly m y) = (-1) ^ m * aeval s (rhRowPoly m y) :=
      fun s => rh_aeval_neg_rowPoly m y s
    have hpar2 : ∀ s : ℂ, aeval (-s) (rhRowPoly (m - 1) z) =
        -((-1) ^ m * aeval s (rhRowPoly (m - 1) z)) := by
      intro s
      rcases Nat.eq_zero_or_pos m with h0 | hpos
      · have hz0 : z = [] := List.length_eq_zero_iff.1 (by rw [hzlen, h0])
        rw [hz0, h0]; simp [rhRowPoly]
      · rw [rh_aeval_neg_rowPoly]
        have h : (-1 : ℂ) ^ m = -(-1) ^ (m - 1) := by
          conv_lhs => rw [show m = m - 1 + 1 by omega]
          rw [pow_succ]; ring
        rw [h]; ring
    have hfam : ∀ t ∈ Set.Icc (0:ℝ) 1, ∀ s : ℂ, s.re = 0 →
        aeval s (rhRowPoly (m + 1) x + rhRowPoly (m + 1 - 1) y +
          C t * (C (x0 / y0) * X * rhRowPoly (m - 1) z)) ≠ 0 := by
      intro t ht s hs h
      rw [hP] at h
      have hconj : (starRingEnd ℂ) s = -s := by
        apply Complex.ext <;> simp [hs]
      have h' := congrArg (starRingEnd ℂ) h
      rw [← rh_aeval_conj, hconj, map_zero] at h'
      simp only [map_add, map_mul, aeval_C, aeval_X, hpar1, hpar2] at h h'
      have hε : ((-1 : ℂ) ^ m) ^ 2 = 1 := by
        rw [← pow_mul, mul_comm, pow_mul]; norm_num
      set A := aeval s (rhRowPoly m y)
      set B := aeval s (rhRowPoly (m - 1) z)
      set ε := (-1 : ℂ) ^ m
      set b : ℂ := algebraMap ℝ ℂ (x0 / y0)
      set tt : ℂ := algebraMap ℝ ℂ t with htt
      have h'' : (1 - b * s) * A - B + tt * b * s * B = 0 := by
        linear_combination ε * h' - ((1 - b * s) * A - B + tt * b * s * B) * hε
      have hA : A * (1 - tt * b ^ 2 * s ^ 2) = 0 := by
        linear_combination (1/2 : ℂ) * h + (1/2 : ℂ) * h'' - (tt * b * s / 2) * (h - h'')
      have hne1 : (1 - tt * b ^ 2 * s ^ 2) ≠ 0 := by
        intro h0
        have := congrArg Complex.re h0
        simp [tt, b, pow_two, Complex.mul_re, hs] at this
        nlinarith [mul_nonneg ht.1 (mul_nonneg (sq_nonneg (x0 / y0)) (sq_nonneg s.im))]
      have hA0 : A = 0 := by
        rcases mul_eq_zero.1 hA with h1 | h1
        · exact h1
        · exact absurd h1 hne1
      have hB0 : B = 0 := by
        linear_combination (1/2 : ℂ) * (h - h'') - b * s * hA0
      apply ihax s hs
      rw [map_add]
      linear_combination hA0 + hB0
    have hQne : rhRowPoly m y + rhRowPoly (m - 1) z ≠ 0 := by
      intro h0; apply ihax 0 (by simp); rw [h0, map_zero]
    have hdegF : (rhRowPoly (m + 1) x + rhRowPoly (m + 1 - 1) y).degree = ((m + 1 : ℕ) : WithBot ℕ) := by
      apply degree_eq_of_le_of_coeff_ne_zero
      · rw [degree_le_iff_coeff_zero]; intro k hk
        have hk' : m + 1 < k := by exact_mod_cast hk
        rw [coeff_add, rh_coeff_rowPoly, rh_coeff_rowPoly, if_neg (by omega), if_neg (by omega),
          add_zero]
      · rw [coeff_add, rh_coeff_rowPoly, rh_coeff_rowPoly, if_pos (by omega), if_neg (by omega),
          add_zero, Nat.sub_self, Nat.zero_div]
        exact hx0
    have hdegG : (C (x0 / y0) * X * rhRowPoly (m - 1) z).degree < ((m + 1 : ℕ) : WithBot ℕ) := by
      rw [degree_lt_iff_coeff_zero]; intro k hk
      rcases k with _ | j
      · omega
      rw [mul_assoc, coeff_C_mul, coeff_X_mul, rh_coeff_rowPoly]
      rcases Nat.eq_zero_or_pos m with h0 | hpos
      · have hz0 : z = [] := List.length_eq_zero_iff.1 (by rw [hzlen, h0])
        rw [hz0]; simp
      · rw [if_neg (by omega), mul_zero]
    have hhom := rh_homotopy (rhRowPoly (m + 1) x + rhRowPoly (m + 1 - 1) y)
      (C (x0 / y0) * X * rhRowPoly (m - 1) z) (by rw [hdegF]; exact hdegG) hfam
    have hsum : rhRowPoly (m + 1) x + rhRowPoly (m + 1 - 1) y +
        C (x0 / y0) * X * rhRowPoly (m - 1) z =
        (C (x0 / y0) * X + 1) * (rhRowPoly m y + rhRowPoly (m - 1) z) := by
      rw [hP]; ring
    have hβ0 : x0 / y0 ≠ 0 := div_ne_zero hx0 hy0
    refine ⟨fun s hs => by simpa using hfam 0 ⟨le_refl _, zero_le_one⟩ s hs, ?_⟩
    rw [hhom, hsum, rh_count_mul_linear _ hβ0 _ hQne, ihcount, hcol, hcol2,
      rh_signChanges_cons_cons]
    have hiff : (x0 / y0 < 0) ↔ (x0 * y0 < 0) := by rw [div_neg_iff, mul_neg_iff]
    by_cases h : x0 * y0 < 0
    · rw [if_pos h, if_pos (hiff.2 h)]; omega
    · rw [if_neg h, if_neg (fun h' => h (hiff.1 h'))]; omega
#print axioms rh_main

lemma rh_bridge (p : ℝ[X]) :
    rhRowPoly p.natDegree ((List.range (p.natDegree / 2 + 1)).map
        fun i => p.coeff (p.natDegree - 2 * i)) +
      rhRowPoly (p.natDegree - 1) ((List.range ((p.natDegree + 1) / 2)).map
        fun i => p.coeff (p.natDegree - 1 - 2 * i)) = p := by
  ext k
  rw [coeff_add, rh_coeff_rowPoly, rh_coeff_rowPoly]
  simp only [rh_getD_map_range]
  by_cases hk : k ≤ p.natDegree
  · by_cases hpar : (p.natDegree - k) % 2 = 0
    · rw [if_pos ⟨hk, hpar⟩, if_pos (by omega)]
      have e : p.natDegree - 2 * ((p.natDegree - k) / 2) = k := by omega
      rw [e]
      split_ifs <;> first | (exfalso; omega) | simp
    · rw [if_neg (by omega), zero_add, if_pos (by omega), if_pos (by omega)]
      congr 1; omega
  · rw [if_neg (by omega), if_neg (by omega), add_zero,
      coeff_eq_zero_of_natDegree_lt (by omega)]
#print axioms rh_bridge

lemma rh_main_poly (p : ℝ[X]) (hne : ∀ c ∈ routhColumn p, c ≠ 0) :
    (∀ s : ℂ, s.re = 0 → aeval s p ≠ 0) ∧ rhpRootCount p = signChanges (routhColumn p) := by
  have h := rh_main p.natDegree
    ((List.range (p.natDegree / 2 + 1)).map fun i => p.coeff (p.natDegree - 2 * i))
    ((List.range ((p.natDegree + 1) / 2)).map fun i => p.coeff (p.natDegree - 1 - 2 * i))
    (by simp) (by simp) hne
  rw [rh_bridge] at h
  exact h
#print axioms rh_main_poly

lemma rh_exists_rhp_root (p : ℝ[X]) (h : 0 < rhpRootCount p) :
    ∃ z : ℂ, aeval z p = 0 ∧ 0 < z.re := by
  by_cases hp : p = 0
  · subst hp; simp [rhpRootCount] at h
  obtain ⟨z, hz⟩ := Multiset.card_pos_iff_exists_mem.1 h
  rw [Multiset.mem_filter, mem_roots_map hp] at hz
  exact ⟨z, by rw [aeval_def]; exact hz.1, hz.2⟩
#print axioms rh_exists_rhp_root

lemma rh_workshop_column (K : ℝ) (hK : K ≠ 12) :
    routhColumn (X ^ 3 + C 6 * X ^ 2 + C 11 * X + C (6 + 5 * K)) =
      [1, 6, (60 - 5 * K) / 6, 6 + 5 * K] := by
  have h : (X ^ 3 + C 6 * X ^ 2 + C 11 * X + C (6 + 5 * K) : ℝ[X]).natDegree = 3 := by
    compute_degree!
  simp only [routhColumn, h]
  norm_num [routhColumnFrom, routhNext, List.range_succ, coeff_X, coeff_C, coeff_X_pow]
  have h2 : (66 - (6 + 5 * K)) / 6 ≠ 0 := by
    intro h0; apply hK; linarith
  have h3 : 66 - (6 + 5 * K) ≠ 0 := by
    intro h0; apply hK; linarith
  refine ⟨by ring, ?_⟩
  field_simp
#print axioms rh_workshop_column

lemma rh_signChanges_single (a : ℝ) : signChanges [a] = 0 := by
  simp [signChanges]
#print axioms rh_signChanges_single

lemma rh_workshop_sc (a b : ℝ) : signChanges [1, 6, a, b] =
    (if 6 * a < 0 then 1 else 0) + (if a * b < 0 then 1 else 0) := by
  rw [rh_signChanges_cons_cons, rh_signChanges_cons_cons, rh_signChanges_cons_cons,
    rh_signChanges_single, if_neg (by norm_num)]
  omega
#print axioms rh_workshop_sc


/-- Routh-Hurwitz criterion: for a polynomial with real coefficients whose Routh array has no
zero entry in its first column, the number of roots with positive real part (counted with
repetition) is exactly the number of sign changes down the first column. -/
theorem rhp_root_count_eq_sign_changes (p : ℝ[X])
    (hne : ∀ c ∈ routhColumn p, c ≠ 0) :
    rhpRootCount p = signChanges (routhColumn p) := by
  exact (rh_main_poly p hne).2

/-- No sign change means stable: for a polynomial with real coefficients whose Routh array has
no zero entry in its first column and no sign change down that column, every root has negative
real part, so every mode of the loop decays. -/
theorem every_root_decays_of_no_sign_change (p : ℝ[X])
    (hne : ∀ c ∈ routhColumn p, c ≠ 0) (hsign : signChanges (routhColumn p) = 0) :
    ∀ z : ℂ, aeval z p = 0 → z.re < 0 := by
  obtain ⟨hax, hcount⟩ := rh_main_poly p hne
  intro z hz
  by_contra hre
  push Not at hre
  rcases hre.lt_or_eq with h1 | h1
  · have hpos : 0 < rhpRootCount p := by
      by_cases hp : p = 0
      · exact absurd (by rw [hp, map_zero]) (hax 0 (by simp))
      unfold rhpRootCount
      refine Multiset.card_pos_iff_exists_mem.2 ⟨z, ?_⟩
      rw [Multiset.mem_filter, mem_roots_map hp]
      exact ⟨by rw [← aeval_def]; exact hz, h1⟩
    omega
  · exact hax z h1.symm hz

/-- The workshop: the closed loop's characteristic polynomial s^3 + 6s^2 + 11s + (6 + 5K) has
every root with negative real part exactly when -1.2 < K < 12 kW per degC. -/
theorem workshop_stable_iff (K : ℝ) :
    (∀ z : ℂ, z ^ 3 + 6 * z ^ 2 + 11 * z + (6 + 5 * K) = 0 → z.re < 0) ↔
      -6 / 5 < K ∧ K < 12 := by
  have heval : ∀ z : ℂ, aeval z (X ^ 3 + C 6 * X ^ 2 + C 11 * X + C (6 + 5 * K) : ℝ[X]) =
      z ^ 3 + 6 * z ^ 2 + 11 * z + (6 + 5 * K) := by
    intro z; simp
  have hcolne : K ≠ 12 → 6 + 5 * K ≠ 0 →
      ∀ c ∈ routhColumn (X ^ 3 + C 6 * X ^ 2 + C 11 * X + C (6 + 5 * K) : ℝ[X]), c ≠ 0 := by
    intro hK hb c hc
    rw [rh_workshop_column K hK] at hc
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hc
    have ha : (60 - 5 * K) / 6 ≠ 0 := by intro h; apply hK; linarith
    rcases hc with rfl | rfl | rfl | rfl
    · norm_num
    · norm_num
    · exact ha
    · exact hb
  have hunst : K ≠ 12 → 6 + 5 * K ≠ 0 → 0 < signChanges [1, 6, (60 - 5 * K) / 6, 6 + 5 * K] →
      ∃ z : ℂ, z ^ 3 + 6 * z ^ 2 + 11 * z + (6 + 5 * K) = 0 ∧ 0 < z.re := by
    intro hK hb hs
    have := (rh_main_poly _ (hcolne hK hb)).2
    rw [rh_workshop_column K hK] at this
    obtain ⟨z, hz, hre⟩ := rh_exists_rhp_root _ (by rw [this]; exact hs)
    exact ⟨z, by rw [← heval]; exact hz, hre⟩
  constructor
  · intro H
    by_contra hK
    rcases le_or_gt K (-6 / 5) with h1 | h1
    · rcases h1.lt_or_eq with h2 | h2
      · have ha : 0 < (60 - 5 * K) / 6 := by linarith
        have hb : 6 + 5 * K < 0 := by linarith
        obtain ⟨z, hz, hre⟩ := hunst (by linarith) (by linarith) (by
          rw [rh_workshop_sc, if_neg (by linarith), if_pos (mul_neg_of_pos_of_neg ha hb)]
          norm_num)
        exact absurd (H z hz) (not_lt.2 hre.le)
      · have := H 0 (by rw [h2]; push_cast; ring)
        simp at this
    · have h3 : 12 ≤ K := by
        by_contra h
        exact hK ⟨h1, by linarith⟩
      rcases h3.lt_or_eq with h4 | h4
      · have ha : (60 - 5 * K) / 6 < 0 := by linarith
        have hb : 0 < 6 + 5 * K := by linarith
        obtain ⟨z, hz, hre⟩ := hunst (by linarith) (by linarith) (by
          rw [rh_workshop_sc, if_pos (by linarith), if_pos (mul_neg_of_neg_of_pos ha hb)]
          norm_num)
        exact absurd (H z hz) (not_lt.2 hre.le)
      · have hs : ((Real.sqrt 11 : ℝ) : ℂ) ^ 2 = 11 := by
          rw [← Complex.ofReal_pow, Real.sq_sqrt (by norm_num)]; norm_num
        have hI : Complex.I ^ 2 = -1 := Complex.I_sq
        have := H ((Real.sqrt 11 : ℂ) * Complex.I) (by
          rw [← h4]; push_cast
          linear_combination ((Real.sqrt 11 : ℂ) * Complex.I ^ 3 + 6 * Complex.I ^ 2) * hs +
            (11 * (Real.sqrt 11 : ℂ) * Complex.I + 66) * hI)
        simp at this
  · rintro ⟨h1, h2⟩ z hz
    have ha : 0 < (60 - 5 * K) / 6 := by linarith
    have hb : 0 < 6 + 5 * K := by linarith
    have hsc : signChanges (routhColumn (X ^ 3 + C 6 * X ^ 2 + C 11 * X + C (6 + 5 * K) : ℝ[X]))
        = 0 := by
      rw [rh_workshop_column K (by linarith), rh_workshop_sc, if_neg (by linarith),
        if_neg (not_lt.2 (mul_pos ha hb).le)]
    exact every_root_decays_of_no_sign_change _ (hcolne (by linarith) (by linarith)) hsc z
      (by rw [heval]; exact hz)

-- Closing the loop: (s+1)(s+2)(s+3) + 5K = s^3 + 6s^2 + 11s + (6 + 5K).
example (K : ℤ) : ∀ s : ℤ, (s + 1) * (s + 2) * (s + 3) + 5 * K = s ^ 3 + 6 * s ^ 2 + 11 * s + (6 + 5 * K) := by
  intro s; ring
-- The Routh array at K = 4, s^3 + 6s^2 + 11s + 26: first column 1, 6, 40/6, 26, no sign change.
example : routhColumnFrom 4 [1, 11] [6, 26] = [1, 6, 40 / 6, 26] := by
  norm_num [routhColumnFrom, routhNext, List.range_succ]
example : routhColumn (X ^ 3 + C 6 * X ^ 2 + C 11 * X + C 26) = [1, 6, 40 / 6, 26] := by
  have h : (X ^ 3 + C 6 * X ^ 2 + C 11 * X + C 26 : ℝ[X]).natDegree = 3 := by compute_degree!
  simp only [routhColumn, h]
  norm_num [routhColumnFrom, routhNext, List.range_succ, coeff_X, coeff_C, coeff_X_pow]
example : signChanges [1, 6, 40 / 6, 26] = 0 := by
  norm_num [signChanges]
-- The s^1 entry for any K: (6 * 11 - 1 * (6 + 5K))/6 = (60 - 5K)/6; edges 60 - 5K = 0 and 6 + 5K = 0.
example (K : ℚ) : (6 * 11 - 1 * (6 + 5 * K)) / 6 = (60 - 5 * K) / 6 := by ring
example : (60 : ℚ) - 5 * 12 = 0 ∧ (6 : ℚ) + 5 * (-6 / 5) = 0 := by norm_num
-- Hurwitz determinant at K = 4: a_2 a_1 - a_3 a_0 = 6 * 11 - 1 * 26 = 40.
example : (6 : ℤ) * 11 - 1 * 26 = 40 := by norm_num
-- K = 13: every coefficient positive (1, 6, 11, 71), yet the s^1 entry (60 - 65)/6 is negative.
example : (6 : ℚ) + 5 * 13 = 71 ∧ (60 - 5 * 13 : ℚ) / 6 < 0 := by norm_num
-- K = 12: the zero s^1 row; the auxiliary polynomial 6s^2 + 66 divides p, s^3 + 6s^2 + 11s + 66 = (s + 6)(s^2 + 11).
example : (60 : ℚ) - 5 * 12 = 0 := by norm_num
example : ∀ s : ℤ, s ^ 3 + 6 * s ^ 2 + 11 * s + 66 = (s + 6) * (s ^ 2 + 11) := by
  intro s; ring
-- Gain margin at K = 4: 12 / 4 = 3.
example : (12 : ℚ) / 4 = 3 := by norm_num

#print axioms rhp_root_count_eq_sign_changes
#print axioms every_root_decays_of_no_sign_change
#print axioms workshop_stable_iff
