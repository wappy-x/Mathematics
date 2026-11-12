-- Corners are enough: a standard-form linear program that has an allowed plan and bounded profit has a best plan at a corner, the corners are exactly the basic feasible solutions, and there are at most n choose m of them.
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.LinearAlgebra.AffineSpace.Midpoint
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Set.Card
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic

open Matrix

/-- A basic feasible solution of the standard-form limits `A *ᵥ x = b`, `x ≥ 0`: pick one
column `β i` of `A` per limit so that the square matrix `B` made of those columns can be
inverted, set every other amount to zero, and solve the limits; every amount comes out at
least zero. -/
def IsBasicFeasible {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (x : Fin n → ℝ) : Prop :=
  ∃ β : Fin m → Fin n, IsUnit (A.submatrix id β).det ∧
    (∀ k, k ∉ Set.range β → x k = 0) ∧ A *ᵥ x = b ∧ 0 ≤ x

/-- A corner (vertex) of the allowed plans `A *ᵥ x = b`, `x ≥ 0`: an allowed plan that is not
the midpoint of two different allowed plans. -/
def IsCorner {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (x : Fin n → ℝ) : Prop :=
  A *ᵥ x = b ∧ 0 ≤ x ∧
    ∀ y z : Fin n → ℝ, A *ᵥ y = b → 0 ≤ y → A *ᵥ z = b → 0 ≤ z → midpoint ℝ y z = x → y = z

lemma lp_midpoint_apply {n : ℕ} (y z : Fin n → ℝ) (k : Fin n) :
    (midpoint ℝ y z) k = (y k + z k) / 2 := by
  rw [midpoint_eq_smul_add]; simp; ring

#print axioms lp_midpoint_apply

lemma lp_injective_of_det {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (β : Fin m → Fin n)
    (h : IsUnit (A.submatrix id β).det) : Function.Injective β := by
  intro j j' hjj
  by_contra hne
  have := Matrix.det_zero_of_column_eq (M := A.submatrix id β) hne (fun k => by simp [hjj])
  rw [this] at h
  exact not_isUnit_zero h

#print axioms lp_injective_of_det

lemma lp_mulVec_supported {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (β : Fin m → Fin n)
    (hβ : Function.Injective β) (y : Fin n → ℝ) (hy : ∀ k, k ∉ Set.range β → y k = 0) :
    A *ᵥ y = (A.submatrix id β) *ᵥ (y ∘ β) := by
  funext i
  simp only [mulVec, dotProduct, submatrix_apply, id, Function.comp]
  symm
  exact Fintype.sum_of_injective β hβ _ _ (fun k hk => by simp [hy k hk]) (fun j => rfl)

#print axioms lp_mulVec_supported

lemma lp_eq_zero_of_basis {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (β : Fin m → Fin n)
    (h : IsUnit (A.submatrix id β).det) (y : Fin n → ℝ) (hy : ∀ k, k ∉ Set.range β → y k = 0)
    (hA : A *ᵥ y = 0) : y = 0 := by
  have hβ := lp_injective_of_det A β h
  rw [lp_mulVec_supported A β hβ y hy] at hA
  set B := A.submatrix id β
  have hw : y ∘ β = 0 := by
    have : B⁻¹ *ᵥ (B *ᵥ (y ∘ β)) = y ∘ β := by
      rw [mulVec_mulVec, nonsing_inv_mul B h, one_mulVec]
    rw [← this, hA, mulVec_zero]
  funext k
  by_cases hk : k ∈ Set.range β
  · obtain ⟨j, rfl⟩ := hk
    exact congrFun hw j
  · exact hy k hk

#print axioms lp_eq_zero_of_basis

lemma lp_corner_of_bfs {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (x : Fin n → ℝ) (h : IsBasicFeasible A b x) : IsCorner A b x := by
  obtain ⟨β, hdet, hzero, hAx, hx0⟩ := h
  refine ⟨hAx, hx0, ?_⟩
  intro y z hAy hy hAz hz hmid
  have hk : ∀ k, x k = (y k + z k) / 2 := by
    intro k; rw [← hmid, lp_midpoint_apply]
  have hd := lp_eq_zero_of_basis A β hdet (y - z) ?_ ?_
  · exact sub_eq_zero.mp hd
  · intro k hkr
    have h1 := hzero k hkr
    have h2 := hk k
    have : 0 ≤ y k := hy k
    have : 0 ≤ z k := hz k
    simp only [Pi.sub_apply]
    linarith
  · rw [mulVec_sub, hAy, hAz, sub_self]

#print axioms lp_corner_of_bfs

lemma lp_dir_of_not_corner {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (x : Fin n → ℝ) (hAx : A *ᵥ x = b) (hx : 0 ≤ x) (h : ¬ IsCorner A b x) :
    ∃ d : Fin n → ℝ, d ≠ 0 ∧ A *ᵥ d = 0 ∧ ∀ k, x k = 0 → d k = 0 := by
  have h' : ¬ ∀ y z : Fin n → ℝ, A *ᵥ y = b → 0 ≤ y → A *ᵥ z = b → 0 ≤ z →
      midpoint ℝ y z = x → y = z := fun H => h ⟨hAx, hx, H⟩
  push Not at h'
  obtain ⟨y, z, hAy, hy, hAz, hz, hmid, hne⟩ := h'
  refine ⟨y - z, sub_ne_zero.mpr hne, by rw [mulVec_sub, hAy, hAz, sub_self], ?_⟩
  intro k hk
  have h2 : x k = (y k + z k) / 2 := by rw [← hmid, lp_midpoint_apply]
  have : 0 ≤ y k := hy k
  have : 0 ≤ z k := hz k
  simp only [Pi.sub_apply]
  linarith

#print axioms lp_dir_of_not_corner

lemma lp_not_corner_of_dir {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (x d : Fin n → ℝ) (hx : 0 ≤ x) (hd : d ≠ 0) (hAd : A *ᵥ d = 0)
    (hsupp : ∀ k, x k = 0 → d k = 0) : ¬ IsCorner A b x := by
  rintro ⟨hAx, -, hc⟩
  obtain ⟨ε, hε, hεk⟩ : ∃ ε : ℝ, 0 < ε ∧ ∀ k, ε * |d k| ≤ x k := by
    have hev : ∀ k, ∀ᶠ ε in nhdsWithin (0:ℝ) (Set.Ioi 0), ε * |d k| ≤ x k := by
      intro k
      by_cases hk : x k = 0
      · exact Filter.Eventually.of_forall (fun ε => by simp [hsupp k hk, hk])
      · have hpos : 0 < x k := lt_of_le_of_ne (hx k) (Ne.symm hk)
        have ht : Filter.Tendsto (fun ε : ℝ => ε * |d k|) (nhdsWithin 0 (Set.Ioi 0))
            (nhds 0) := by
          have : Filter.Tendsto (fun ε : ℝ => ε * |d k|) (nhds 0) (nhds (0 * |d k|)) :=
            (continuous_id.mul continuous_const).tendsto 0
          rw [zero_mul] at this
          exact this.mono_left nhdsWithin_le_nhds
        exact ht.eventually (Iic_mem_nhds hpos)
    have hall := Filter.eventually_all.mpr hev
    have hpos : ∀ᶠ ε in nhdsWithin (0:ℝ) (Set.Ioi 0), 0 < ε := self_mem_nhdsWithin
    obtain ⟨ε, h1, h2⟩ := (hpos.and hall).exists
    exact ⟨ε, h1, h2⟩
  have hy : 0 ≤ x + ε • d := fun k => by
    have := hεk k
    have := mul_le_mul_of_nonneg_left (neg_abs_le (d k)) hε.le
    simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply]
    nlinarith
  have hz : 0 ≤ x - ε • d := fun k => by
    have := hεk k
    have := mul_le_mul_of_nonneg_left (le_abs_self (d k)) hε.le
    simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply]
    nlinarith
  have heq := hc (x + ε • d) (x - ε • d)
    (by rw [mulVec_add, mulVec_smul, hAx, hAd, smul_zero, add_zero]) hy
    (by rw [mulVec_sub, mulVec_smul, hAx, hAd, smul_zero, sub_zero]) hz
    (by funext k; rw [lp_midpoint_apply]; simp only [Pi.add_apply, Pi.sub_apply,
      Pi.smul_apply, smul_eq_mul]; ring)
  apply hd
  funext k
  have h := congrFun heq k
  simp only [Pi.add_apply, Pi.sub_apply, Pi.smul_apply, smul_eq_mul] at h
  have : ε * d k = 0 := by linarith
  simpa [hε.ne'] using this

#print axioms lp_not_corner_of_dir

lemma lp_indep_of_corner {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (x : Fin n → ℝ) (h : IsCorner A b x) : LinearIndepOn ℝ A.col {k | x k ≠ 0} := by
  rw [linearIndepOn_iff]
  intro l hl hsum
  by_contra hne
  apply lp_not_corner_of_dir A b x (⇑l) h.2.1 ?_ ?_ ?_ h
  · intro h0; apply hne; ext k; exact congrFun h0 k
  · funext i
    have := congrFun hsum i
    rw [Finsupp.linearCombination_apply, Finsupp.sum_fintype _ _ (by simp)] at this
    simpa [mulVec, dotProduct, Matrix.col, mul_comm] using this
  · intro k hk
    by_contra hlk
    exact hl (Finsupp.mem_support_iff.mpr hlk) hk

#print axioms lp_indep_of_corner

lemma lp_bfs_of_corner {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (hrows : LinearIndependent ℝ A) (x : Fin n → ℝ) (h : IsCorner A b x) :
    IsBasicFeasible A b x := by
  classical
  have hS := lp_indep_of_corner A b x h
  obtain ⟨T, -, hST, hspan, hT⟩ := exists_linearIndepOn_extension hS (Set.subset_univ _)
  have hcols : Submodule.span ℝ (Set.range A.col) = ⊤ := by
    apply Submodule.eq_top_of_finrank_eq
    rw [← rank_eq_finrank_span_cols, rank_eq_finrank_span_row]
    rw [Module.finrank_fin_fun]
    exact (finrank_span_eq_card hrows).trans (Fintype.card_fin m)
  have hspanT : Submodule.span ℝ (Set.range (fun k : T => A.col k)) = ⊤ := by
    rw [eq_top_iff, ← hcols, Submodule.span_le, ← Set.image_eq_range]
    rintro _ ⟨k, rfl⟩
    exact hspan ⟨k, Set.mem_univ _, rfl⟩
  have hcard : Fintype.card T = m := by
    have := finrank_span_eq_card (R := ℝ) hT
    rw [hspanT, finrank_top] at this
    simpa using this.symm
  let e : Fin m ≃ T := (Fintype.equivFinOfCardEq hcard).symm
  refine ⟨fun j => (e j : Fin n), ?_, ?_, h.1, h.2.1⟩
  · rw [← Matrix.isUnit_iff_isUnit_det]
    apply linearIndependent_col_iff_isUnit.mp
    exact (hT.comp e e.injective : _)
  · intro k hk
    by_contra hxk
    apply hk
    refine ⟨e.symm ⟨k, hST hxk⟩, ?_⟩
    simp

#print axioms lp_bfs_of_corner

lemma lp_bfs_finite {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) :
    {x : Fin n → ℝ | IsBasicFeasible A b x}.Finite ∧
      {x : Fin n → ℝ | IsBasicFeasible A b x}.ncard ≤ n.choose m := by
  classical
  let g : Finset (Fin n) → (Fin n → ℝ) := fun S =>
    if h : ∃ y : Fin n → ℝ, (∀ k, k ∉ S → y k = 0) ∧ A *ᵥ y = b then h.choose else 0
  have hsub : {x | IsBasicFeasible A b x} ⊆
      ((Finset.univ.powersetCard m).image g : Set (Fin n → ℝ)) := by
    rintro x ⟨β, hdet, hzero, hAx, hx0⟩
    have hβ := lp_injective_of_det A β hdet
    rw [Finset.mem_coe, Finset.mem_image]
    refine ⟨Finset.univ.image β, ?_, ?_⟩
    · rw [Finset.mem_powersetCard]
      refine ⟨Finset.subset_univ _, ?_⟩
      rw [Finset.card_image_of_injective _ hβ]
      simp
    have hex : ∃ y : Fin n → ℝ, (∀ k, k ∉ Finset.univ.image β → y k = 0) ∧ A *ᵥ y = b :=
      ⟨x, fun k hk => hzero k (by simpa using hk), hAx⟩
    have hg : g (Finset.univ.image β) = hex.choose := dite_eq_left_of_eq_true (eq_true hex)
    rw [hg]
    have hspec := hex.choose_spec
    have := lp_eq_zero_of_basis A β hdet (hex.choose - x) ?_ ?_
    · exact sub_eq_zero.mp this
    · intro k hk
      have hk' : k ∉ Finset.univ.image β := by simpa using hk
      show hex.choose k - x k = 0
      rw [hspec.1 k hk', hzero k hk, sub_zero]
    · rw [mulVec_sub, hspec.2, hAx, sub_self]
  have hfin : ((Finset.univ.powersetCard m).image g : Set (Fin n → ℝ)).Finite :=
    Finset.finite_toSet _
  refine ⟨hfin.subset hsub, ?_⟩
  calc _ ≤ ((Finset.univ.powersetCard m).image g : Set (Fin n → ℝ)).ncard :=
        Set.ncard_le_ncard hsub hfin
    _ = ((Finset.univ.powersetCard m).image g).card := Set.ncard_coe_finset _
    _ ≤ (Finset.univ.powersetCard m).card := Finset.card_image_le
    _ = n.choose m := by simp [Finset.card_powersetCard]

#print axioms lp_bfs_finite

lemma lp_improve {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (hbdd : BddAbove ((fun x => c ⬝ᵥ x) '' {x : Fin n → ℝ | A *ᵥ x = b ∧ 0 ≤ x}))
    (x : Fin n → ℝ) (hAx : A *ᵥ x = b) (hx : 0 ≤ x) (hnc : ¬ IsCorner A b x) :
    ∃ x' : Fin n → ℝ, A *ᵥ x' = b ∧ 0 ≤ x' ∧ c ⬝ᵥ x ≤ c ⬝ᵥ x' ∧
      (Finset.univ.filter (fun k => x' k ≠ 0)).card <
        (Finset.univ.filter (fun k => x k ≠ 0)).card := by
  classical
  obtain ⟨d, hd, hAd, hsupp⟩ := lp_dir_of_not_corner A b x hAx hx hnc
  have hunb : ∀ e : Fin n → ℝ, A *ᵥ e = 0 → 0 ≤ e → ¬ 0 < c ⬝ᵥ e := by
    intro e hAe he hce
    obtain ⟨M, hM⟩ := hbdd
    have hxM : c ⬝ᵥ x ≤ M := hM ⟨x, ⟨hAx, hx⟩, rfl⟩
    set t := (M - c ⬝ᵥ x + 1) / (c ⬝ᵥ e) with ht_def
    have ht : 0 ≤ t := div_nonneg (by linarith) hce.le
    have hmem : c ⬝ᵥ (x + t • e) ≤ M := by
      refine hM ⟨x + t • e, ⟨?_, fun k => ?_⟩, rfl⟩
      · rw [mulVec_add, mulVec_smul, hAe, smul_zero, add_zero, hAx]
      · have h1 : 0 ≤ x k := hx k
        have h2 : 0 ≤ e k := he k
        simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply]
        nlinarith [mul_nonneg ht h2]
    rw [dotProduct_add, dotProduct_smul, smul_eq_mul] at hmem
    have : t * (c ⬝ᵥ e) = M - c ⬝ᵥ x + 1 := div_mul_cancel₀ _ hce.ne'
    linarith
  have key : ∀ e : Fin n → ℝ, e ≠ 0 → A *ᵥ e = 0 → (∀ k, x k = 0 → e k = 0) →
      0 ≤ c ⬝ᵥ e → ∃ d' : Fin n → ℝ, A *ᵥ d' = 0 ∧ (∀ k, x k = 0 → d' k = 0) ∧
        (∃ k, d' k < 0) ∧ 0 ≤ c ⬝ᵥ d' := by
    intro e he hAe hse hce
    by_cases hneg : ∃ k, e k < 0
    · exact ⟨e, hAe, hse, hneg, hce⟩
    · push Not at hneg
      have he0 : 0 ≤ e := hneg
      have hce0 : c ⬝ᵥ e = 0 := le_antisymm (not_lt.mp (hunb e hAe he0)) hce
      obtain ⟨k, hk⟩ : ∃ k, e k ≠ 0 := by
        by_contra hh
        push Not at hh
        exact he (funext hh)
      refine ⟨-e, by rw [mulVec_neg, hAe, neg_zero], fun j hj => by simp [hse j hj],
        ⟨k, ?_⟩, by rw [dotProduct_neg, hce0, neg_zero]⟩
      have := hneg k
      simp only [Pi.neg_apply]
      exact neg_neg_of_pos (lt_of_le_of_ne this (Ne.symm hk))
  obtain ⟨d', hAd', hsupp', ⟨k0, hk0⟩, hcd'⟩ :
      ∃ d' : Fin n → ℝ, A *ᵥ d' = 0 ∧ (∀ k, x k = 0 → d' k = 0) ∧
        (∃ k, d' k < 0) ∧ 0 ≤ c ⬝ᵥ d' := by
    rcases le_total 0 (c ⬝ᵥ d) with h | h
    · exact key d hd hAd hsupp h
    · refine key (-d) (neg_ne_zero.mpr hd) (by rw [mulVec_neg, hAd, neg_zero])
        (fun j hj => by simp [hsupp j hj]) ?_
      rw [dotProduct_neg]
      linarith
  set N := Finset.univ.filter (fun k => d' k < 0) with hN_def
  have hN : N.Nonempty := ⟨k0, by simp [N, hk0]⟩
  obtain ⟨k1, hk1N, hk1min⟩ := Finset.exists_min_image N (fun k => x k / (-d' k)) hN
  have hk1 : d' k1 < 0 := by simpa [N] using hk1N
  set t := x k1 / (-d' k1) with ht_def
  have ht : 0 ≤ t := div_nonneg (hx k1) (by linarith)
  refine ⟨x + t • d', by rw [mulVec_add, mulVec_smul, hAd', smul_zero, add_zero, hAx], ?_, ?_, ?_⟩
  · intro k
    have hxk : 0 ≤ x k := hx k
    simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply]
    by_cases hk : d' k < 0
    · have h1 : t ≤ x k / (-d' k) := hk1min k (by simp [N, hk])
      have h2 := (le_div_iff₀ (by linarith : 0 < -d' k)).mp h1
      nlinarith
    · push Not at hk
      have := mul_nonneg ht hk
      linarith
  · rw [dotProduct_add, dotProduct_smul, smul_eq_mul]
    nlinarith [mul_nonneg ht hcd']
  · apply Finset.card_lt_card
    rw [Finset.ssubset_iff_of_subset]
    · refine ⟨k1, ?_, ?_⟩
      · rw [Finset.mem_filter]
        refine ⟨Finset.mem_univ _, fun h0 => ?_⟩
        have := hsupp' k1 h0
        linarith
      · rw [Finset.mem_filter, not_and, not_not]
        intro _
        simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
        rw [ht_def, div_neg, neg_mul, div_mul_cancel₀ (x k1) hk1.ne]
        ring
    · intro k
      simp only [Finset.mem_filter, Finset.mem_univ, true_and]
      intro hk h0
      apply hk
      simp [h0, hsupp' k h0]

#print axioms lp_improve

lemma lp_exists_corner_ge {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (c : Fin n → ℝ)
    (hbdd : BddAbove ((fun x => c ⬝ᵥ x) '' {x : Fin n → ℝ | A *ᵥ x = b ∧ 0 ≤ x})) :
    ∀ N : ℕ, ∀ x : Fin n → ℝ, A *ᵥ x = b → 0 ≤ x →
      (Finset.univ.filter (fun k => x k ≠ 0)).card = N →
        ∃ x', IsCorner A b x' ∧ c ⬝ᵥ x ≤ c ⬝ᵥ x' := by
  intro N
  induction N using Nat.strong_induction_on with
  | _ N ih =>
    intro x hAx hx hN
    by_cases hc : IsCorner A b x
    · exact ⟨x, hc, le_rfl⟩
    · obtain ⟨x', hAx', hx', hcx, hlt⟩ := lp_improve A b c hbdd x hAx hx hc
      obtain ⟨x'', h1, h2⟩ := ih _ (hN ▸ hlt) x' hAx' hx' rfl
      exact ⟨x'', h1, hcx.trans h2⟩

#print axioms lp_exists_corner_ge

/-- The fundamental theorem of linear programming. Maximise the straight-line profit `c ⬝ᵥ x`
subject to `A *ᵥ x = b` and `x ≥ 0`, with real (fractional) amounts and independent rows of
`A`. If some plan is allowed and profit is bounded above on the allowed plans, then the best
profit is reached, and it is reached at a corner, which is also a basic feasible solution. -/
theorem bounded_linear_program_has_best_corner {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (hrows : LinearIndependent ℝ A)
    (hfeas : ∃ x : Fin n → ℝ, A *ᵥ x = b ∧ 0 ≤ x)
    (hbdd : BddAbove ((fun x => c ⬝ᵥ x) '' {x : Fin n → ℝ | A *ᵥ x = b ∧ 0 ≤ x})) :
    ∃ x : Fin n → ℝ, IsCorner A b x ∧ IsBasicFeasible A b x ∧
      ∀ y : Fin n → ℝ, A *ᵥ y = b → 0 ≤ y → c ⬝ᵥ y ≤ c ⬝ᵥ x := by
  obtain ⟨x0, hAx0, hx0⟩ := hfeas
  have hfinC : {x | IsCorner A b x}.Finite :=
    (lp_bfs_finite A b).1.subset (fun x hx => lp_bfs_of_corner A b hrows x hx)
  obtain ⟨x1, hx1C, -⟩ := lp_exists_corner_ge A b c hbdd _ x0 hAx0 hx0 rfl
  obtain ⟨xs, hxsC, hxsmax⟩ :=
    Set.exists_max_image {x | IsCorner A b x} (fun x => c ⬝ᵥ x) hfinC ⟨x1, hx1C⟩
  refine ⟨xs, hxsC, lp_bfs_of_corner A b hrows xs hxsC, fun y hAy hy => ?_⟩
  obtain ⟨y', hy'C, hyy'⟩ := lp_exists_corner_ge A b c hbdd _ y hAy hy rfl
  exact hyy'.trans (hxsmax y' hy'C)

/-- Corners in algebra. When the rows of `A` are independent, a plan is a corner of the
allowed region `A *ᵥ x = b`, `x ≥ 0` exactly when it is a basic feasible solution. -/
theorem corner_iff_basic_feasible {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (hrows : LinearIndependent ℝ A) (x : Fin n → ℝ) :
    IsCorner A b x ↔ IsBasicFeasible A b x := by
  exact ⟨lp_bfs_of_corner A b hrows x, lp_corner_of_bfs A b x⟩

/-- The corners are a finite list: there are finitely many basic feasible solutions, at most
the number of ways to choose `m` columns from `n`. -/
theorem basic_feasible_solutions_finite {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) :
    {x : Fin n → ℝ | IsBasicFeasible A b x}.Finite ∧
      {x : Fin n → ℝ | IsBasicFeasible A b x}.ncard ≤ n.choose m := by
  exact lp_bfs_finite A b

-- The workshop in standard form: amounts (t, c, s_timber, s_labour, s_finish).
-- The best plan x = (32, 16, 0, 8, 0) solves the three limits exactly.
example : !![(4 : ℤ), 2, 1, 0, 0; 3, 1, 0, 1, 0; 1, 2, 0, 0, 1] *ᵥ ![32, 16, 0, 8, 0]
    = ![160, 120, 64] := by
  decide
-- Its profit is 19 × 32 + 20 × 16 = 608 + 320 = £928.
example : ![(19 : ℤ), 20, 0, 0, 0] ⬝ᵥ ![32, 16, 0, 8, 0] = 928 := by decide
-- Its basis, columns t, c, s_labour, gives a square matrix B that can be inverted (det -6).
example : (!![(4 : ℤ), 2, 0; 3, 1, 1; 1, 2, 0]).det = -6 := by
  norm_num [Matrix.det_fin_three]
-- The other three corners: (40, 0, 0, 0, 24), (0, 32, 96, 88, 0), (0, 0, 160, 120, 64).
example : !![(4 : ℤ), 2, 1, 0, 0; 3, 1, 0, 1, 0; 1, 2, 0, 0, 1] *ᵥ ![40, 0, 0, 0, 24]
    = ![160, 120, 64] := by
  decide
example : !![(4 : ℤ), 2, 1, 0, 0; 3, 1, 0, 1, 0; 1, 2, 0, 0, 1] *ᵥ ![0, 32, 96, 88, 0]
    = ![160, 120, 64] := by
  decide
example : !![(4 : ℤ), 2, 1, 0, 0; 3, 1, 0, 1, 0; 1, 2, 0, 0, 1] *ᵥ ![0, 0, 160, 120, 64]
    = ![160, 120, 64] := by
  decide
-- The corners' profits: £0, £760, £928 and £640.
example : 19 * 0 + 20 * 0 = 0 ∧ 19 * 40 + 20 * 0 = 760 ∧ 19 * 32 + 20 * 16 = 928 ∧
    19 * 0 + 20 * 32 = 640 := by
  decide
-- By hand: timber minus finish gives 3t = 96, so t = 32; then 2c = 32, c = 16; labour slack 8.
example : 160 - 64 = 3 * 32 ∧ 64 - 32 = 2 * 16 ∧ 120 - 3 * 32 - 16 = 8 := by decide
-- Prices £3, £0, £7 value a table's inputs at 19 and a chair's at 20, and the stock at £928.
example : 4 * 3 + 3 * 0 + 1 * 7 = 19 ∧ 2 * 3 + 1 * 0 + 2 * 7 = 20 := by decide
example : 3 * 160 + 0 * 120 + 7 * 64 = 928 := by norm_num
-- Skipping the feasibility check: basis c, s_timber, s_finish gives (0, 120, -80, 0, -176),
-- which needs 240 m of timber and "earns" £2,400.
example : !![(4 : ℤ), 2, 1, 0, 0; 3, 1, 0, 1, 0; 1, 2, 0, 0, 1] *ᵥ ![0, 120, -80, 0, -176]
    = ![160, 120, 64] := by
  decide
example : 2 * 120 = 240 ∧ 20 * 120 = 2400 := by decide
-- With profit 10t + 20c, the midpoint (16, 24) of the finish edge earns £640, like both ends.
example : 10 * 16 + 20 * 24 = 640 ∧ 10 * 0 + 20 * 32 = 640 ∧ 10 * 32 + 20 * 16 = 640 := by
  decide
-- 3 limits and 5 amounts: 10 ways to choose the basis columns.
example : Nat.choose 5 3 = 10 := by decide

#print axioms bounded_linear_program_has_best_corner
#print axioms corner_iff_basic_feasible
#print axioms basic_feasible_solutions_finite
