-- Root systems and Dynkin diagrams: the connected positive-definite Cartan matrices are exactly those of types A, B, C, D, E6, E7, E8, F4 and G2, and every root system's Cartan matrix is one of them.
import Mathlib.LinearAlgebra.Matrix.Cartan.Basic
import Mathlib.LinearAlgebra.RootSystem.CartanMatrix
import Mathlib.LinearAlgebra.RootSystem.Finite.Lemmas

open Matrix CartanMatrix

/-! ## Part A: general tools -/

/-- A nonnegative nonzero test vector on which the Cartan matrix is nonpositive (on the support)
rules out positive-definiteness. -/
lemma dyn_forbid {ι : Type*} [Fintype ι] [DecidableEq ι] {N : Matrix ι ι ℤ}
    (hN : N.IsFiniteCartan) (v : ι → ℤ)
    (hv0 : ∀ i, 0 ≤ v i) (hv1 : v ≠ 0) (hloc : ∀ i, 0 < v i → (N *ᵥ v) i ≤ 0) : False := by
  obtain ⟨d, hd, hpd⟩ := hN.exists_posDef
  have h1 := hpd.dotProduct_mulVec_pos hv1
  rw [star_trivial, ← mulVec_mulVec] at h1
  have h3 : diagonal d *ᵥ (N *ᵥ v) = fun i => d i * (N *ᵥ v) i := by
    ext i; simp [mulVec_diagonal]
  rw [h3] at h1
  have h2 : v ⬝ᵥ (fun i => d i * (N *ᵥ v) i) ≤ 0 := by
    simp only [dotProduct]
    apply Finset.sum_nonpos
    intro i _
    rcases (hv0 i).lt_or_eq with h | h
    · have := hloc i h
      have := hd i
      have h4 : d i * (N *ᵥ v) i ≤ 0 := mul_nonpos_of_nonneg_of_nonpos this.le ‹_›
      exact mul_nonpos_of_nonneg_of_nonpos h.le h4
    · rw [← h]; simp
  linarith

lemma dyn_loc {ι : Type*} [Fintype ι] [DecidableEq ι] {N : Matrix ι ι ℤ}
    (hN : N.IsFiniteCartan) {v : ι → ℤ} (hv0 : ∀ i, 0 ≤ v i) (i : ι) (L : Finset ι)
    (hi : i ∉ L) : (N *ᵥ v) i ≤ 2 * v i + ∑ j ∈ L, N i j * v j := by
  have h1 : (N *ᵥ v) i = ∑ j, N i j * v j := rfl
  rw [h1, ← Finset.sum_add_sum_compl (insert i L), Finset.sum_insert hi, hN.diag]
  have : ∑ j ∈ (insert i L)ᶜ, N i j * v j ≤ 0 := Finset.sum_nonpos fun j hj => by
    have hji : j ≠ i := by intro h; simp [h] at hj
    exact mul_nonpos_of_nonpos_of_nonneg (hN.offDiag_nonpos i j hji.symm) (hv0 j)
  linarith

lemma dyn_loc1 {ι : Type*} [Fintype ι] [DecidableEq ι] {N : Matrix ι ι ℤ}
    (hN : N.IsFiniteCartan) {v : ι → ℤ} (hv0 : ∀ i, 0 ≤ v i) (i a : ι) (ha : a ≠ i) :
    (N *ᵥ v) i ≤ 2 * v i + N i a * v a := by
  simpa using dyn_loc hN hv0 i {a} (by simpa using ha.symm)

lemma dyn_loc2 {ι : Type*} [Fintype ι] [DecidableEq ι] {N : Matrix ι ι ℤ}
    (hN : N.IsFiniteCartan) {v : ι → ℤ} (hv0 : ∀ i, 0 ≤ v i) (i a b : ι) (ha : a ≠ i)
    (hb : b ≠ i) (hab : a ≠ b) :
    (N *ᵥ v) i ≤ 2 * v i + N i a * v a + N i b * v b := by
  have := dyn_loc hN hv0 i {a, b} (by simp [ha.symm, hb.symm])
  rw [Finset.sum_pair hab] at this
  linarith

lemma dyn_loc3 {ι : Type*} [Fintype ι] [DecidableEq ι] {N : Matrix ι ι ℤ}
    (hN : N.IsFiniteCartan) {v : ι → ℤ} (hv0 : ∀ i, 0 ≤ v i) (i a b c : ι) (ha : a ≠ i)
    (hb : b ≠ i) (hc : c ≠ i) (hab : a ≠ b) (hac : a ≠ c) (hbc : b ≠ c) :
    (N *ᵥ v) i ≤ 2 * v i + N i a * v a + N i b * v b + N i c * v c := by
  have := dyn_loc hN hv0 i {a, b, c} (by simp [ha.symm, hb.symm, hc.symm])
  rw [Finset.sum_insert (by simp [hab, hac]), Finset.sum_pair hbc] at this
  linarith

lemma dyn_loc4 {ι : Type*} [Fintype ι] [DecidableEq ι] {N : Matrix ι ι ℤ}
    (hN : N.IsFiniteCartan) {v : ι → ℤ} (hv0 : ∀ i, 0 ≤ v i) (i a b c e : ι) (ha : a ≠ i)
    (hb : b ≠ i) (hc : c ≠ i) (he : e ≠ i) (hab : a ≠ b) (hac : a ≠ c) (hae : a ≠ e)
    (hbc : b ≠ c) (hbe : b ≠ e) (hce : c ≠ e) :
    (N *ᵥ v) i ≤ 2 * v i + N i a * v a + N i b * v b + N i c * v c + N i e * v e := by
  have := dyn_loc hN hv0 i {a, b, c, e} (by simp [ha.symm, hb.symm, hc.symm, he.symm])
  rw [Finset.sum_insert (by simp [hab, hac, hae]), Finset.sum_insert (by simp [hbc, hbe]),
    Finset.sum_pair hce] at this
  linarith

/-- Reindexing keeps a finite-type Cartan matrix finite type. -/
lemma dyn_isFiniteCartan_submatrix {ι κ : Type*} [Fintype ι] [DecidableEq ι] [Fintype κ]
    [DecidableEq κ] {M : Matrix ι ι ℤ} (hM : M.IsFiniteCartan) (f : κ → ι)
    (hf : Function.Injective f) : (M.submatrix f f).IsFiniteCartan where
  diag i := by simp [hM.diag]
  offDiag_nonpos i j hij := hM.offDiag_nonpos _ _ (hf.ne hij)
  zero_comm i j := hM.zero_comm _ _
  exists_posDef := by
    obtain ⟨d, hd, hpd⟩ := hM.exists_posDef
    refine ⟨d ∘ f, fun i => hd _, ?_⟩
    have : diagonal (d ∘ f) * M.submatrix f f = (diagonal d * M).submatrix f f := by
      ext i j; simp [diagonal_mul]
    rw [this]
    exact hpd.submatrix hf

lemma dyn_isFiniteCartan_reindex {ι κ : Type*} [Fintype ι] [DecidableEq ι] [Fintype κ]
    [DecidableEq κ] {M : Matrix ι ι ℤ} (hM : M.IsFiniteCartan) (e : ι ≃ κ) :
    (M.reindex e e).IsFiniteCartan :=
  dyn_isFiniteCartan_submatrix hM e.symm e.symm.injective

/-- Connectedness of the diagram, in the form used by `isIndecomposable_iff_reflTransGen`. -/
def DConn {ι : Type*} (M : Matrix ι ι ℤ) : Prop :=
  ∀ i j, Relation.ReflTransGen (fun i j => M i j ≠ 0) i j

lemma dyn_conn_reindex {ι κ : Type*} {M : Matrix ι ι ℤ} (hM : DConn M) (e : ι ≃ κ) :
    DConn (M.reindex e e) := by
  intro i j
  have := hM (e.symm i) (e.symm j)
  have key : ∀ a b, Relation.ReflTransGen (fun i j => M i j ≠ 0) a b →
      Relation.ReflTransGen (fun i j => M.reindex e e i j ≠ 0) (e a) (e b) := by
    intro a b h
    induction h with
    | refl => exact .refl
    | tail _ h2 ih => exact ih.tail (by simpa using h2)
  simpa using key _ _ this

/-- The list of connected Dynkin diagrams, exactly as in the main statement. -/
def DL {ι : Type*} [Fintype ι] [DecidableEq ι] (M : Matrix ι ι ℤ) : Prop :=
      (∃ n, 1 ≤ n ∧ ∃ e : ι ≃ Fin n, M.reindex e e = A n) ∨
      (∃ n, 2 ≤ n ∧ ∃ e : ι ≃ Fin n, M.reindex e e = B n) ∨
      (∃ n, 2 ≤ n ∧ ∃ e : ι ≃ Fin n, M.reindex e e = C n) ∨
      (∃ n, 4 ≤ n ∧ ∃ e : ι ≃ Fin n, M.reindex e e = D n) ∨
      (∃ n, (n = 6 ∨ n = 7 ∨ n = 8) ∧ ∃ e : ι ≃ Fin n, M.reindex e e = E n) ∨
      (∃ e : ι ≃ Fin 4, M.reindex e e = F₄) ∨
      (∃ e : ι ≃ Fin 2, M.reindex e e = G₂)

lemma dyn_DL_of_reindex {ι κ : Type*} [Fintype ι] [DecidableEq ι] [Fintype κ] [DecidableEq κ]
    {M : Matrix ι ι ℤ} (f : ι ≃ κ) (h : DL (M.reindex f f)) : DL M := by
  have key : ∀ {m : Type} (e : κ ≃ m), (M.reindex f f).reindex e e = M.reindex (f.trans e) (f.trans e) := by
    intro m e; ext i j; simp
  rcases h with ⟨n, hn, e, he⟩ | ⟨n, hn, e, he⟩ | ⟨n, hn, e, he⟩ | ⟨n, hn, e, he⟩ | ⟨n, hn, e, he⟩ |
    ⟨e, he⟩ | ⟨e, he⟩ <;> rw [key] at he
  · exact Or.inl ⟨n, hn, _, he⟩
  · exact Or.inr <| Or.inl ⟨n, hn, _, he⟩
  · exact Or.inr <| Or.inr <| Or.inl ⟨n, hn, _, he⟩
  · exact Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨n, hn, _, he⟩
  · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨n, hn, _, he⟩
  · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨_, he⟩
  · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr ⟨_, he⟩

/-! ## Part B: leaves, extensions and the induction skeleton -/

lemma dyn_first_step {α : Type*} {R : α → α → Prop} {a b : α}
    (h : Relation.ReflTransGen R a b) (hab : a ≠ b) : ∃ c, c ≠ a ∧ R a c := by
  induction h using Relation.ReflTransGen.head_induction_on with
  | refl => exact absurd rfl hab
  | head h1 h2 ih =>
    rename_i a' c
    by_cases hc : c = a'
    · subst hc; exact ih hab
    · exact ⟨c, hc, h1⟩

lemma dyn_le_neg_one {ι : Type*} [Fintype ι] [DecidableEq ι] {M : Matrix ι ι ℤ}
    (hM : M.IsFiniteCartan) {i j : ι} (hij : i ≠ j) (h : M i j ≠ 0) : M i j ≤ -1 := by
  have := hM.offDiag_nonpos i j hij; omega

lemma dyn_exists_leaf {n : ℕ} {M : Matrix (Fin (n+2)) (Fin (n+2)) ℤ} (hM : M.IsFiniteCartan)
    (hc : DConn M) : ∃ z s, s ≠ z ∧ M z s ≠ 0 ∧ ∀ t, t ≠ z → t ≠ s → M z t = 0 := by
  have nb : ∀ i, ∃ j, j ≠ i ∧ M i j ≠ 0 := by
    intro i
    obtain ⟨j, hj⟩ : ∃ j : Fin (n+2), j ≠ i := by
      by_cases h : i = 0
      · exact ⟨1, by rw [h]; exact Fin.ne_of_val_ne (by simp)⟩
      · exact ⟨0, Ne.symm h⟩
    exact dyn_first_step (hc i j) (Ne.symm hj)
  by_contra H
  push Not at H
  apply dyn_forbid hM (fun _ => 1) (fun _ => by norm_num) (by
    intro h; have := congrFun h 0; simp at this)
  intro i _
  obtain ⟨a, ha, hMa⟩ := nb i
  obtain ⟨b, hb, hba, hMb⟩ := H i a ha hMa
  have h1 := dyn_le_neg_one hM (Ne.symm ha) hMa
  have h2 := dyn_le_neg_one hM (Ne.symm hb) hMb
  have := dyn_loc2 hM (v := fun _ => 1) (fun _ => by norm_num) i a b ha hb (Ne.symm hba)
  simp only [mul_one] at this
  linarith

lemma dyn_conn_remove_leaf {n : ℕ} {M : Matrix (Fin (n+2)) (Fin (n+2)) ℤ}
    (hM : M.IsFiniteCartan) (hc : DConn M) (s0 : Fin (n+1))
    (hrow : ∀ t : Fin (n+1), t ≠ s0 → M (Fin.last _) t.castSucc = 0) :
    DConn (M.submatrix Fin.castSucc Fin.castSucc) := by
  have hcol : ∀ t : Fin (n+1), t ≠ s0 → M t.castSucc (Fin.last _) = 0 := fun t ht =>
    (hM.zero_comm _ _).2 (hrow t ht)
  intro x0 y0
  have key : ∀ y, Relation.ReflTransGen (fun i j => M i j ≠ 0) x0.castSucc y →
      (∀ y0, y = y0.castSucc →
        Relation.ReflTransGen (fun i j => M.submatrix Fin.castSucc Fin.castSucc i j ≠ 0) x0 y0) ∧
      (y = Fin.last _ →
        Relation.ReflTransGen (fun i j => M.submatrix Fin.castSucc Fin.castSucc i j ≠ 0) x0 s0) := by
    intro y h
    induction h with
    | refl =>
      refine ⟨fun y0 hy => ?_, fun hy => absurd hy (Fin.castSucc_ne_last _)⟩
      rw [Fin.castSucc_inj.1 hy]
    | tail h1 h2 ih =>
      rename_i w y
      induction w using Fin.lastCases with
      | last =>
        refine ⟨fun y0 hy => ?_, fun _ => ih.2 rfl⟩
        subst hy
        by_cases hy0 : y0 = s0
        · rw [hy0]; exact ih.2 rfl
        · exact absurd (hrow y0 hy0) h2
      | cast w0 =>
        refine ⟨fun y0 hy => ?_, fun hy => ?_⟩
        · subst hy
          exact (ih.1 w0 rfl).tail (by simpa using h2)
        · subst hy
          by_cases hw : w0 = s0
          · rw [← hw]; exact ih.1 w0 rfl
          · exact absurd (hcol w0 hw) h2
  exact (key _ (hc _ _)).1 y0 rfl

/-- The five possible weights of a new edge. -/
def DPQ (p q : ℤ) : Prop :=
  (p = -1 ∧ q = -1) ∨ (p = -1 ∧ q = -2) ∨ (p = -2 ∧ q = -1) ∨ (p = -1 ∧ q = -3) ∨
    (p = -3 ∧ q = -1)

lemma dyn_pq {ι : Type*} [Fintype ι] [DecidableEq ι] {N : Matrix ι ι ℤ}
    (hN : N.IsFiniteCartan) (a b : ι) (hab : a ≠ b) (h : N a b ≠ 0) : DPQ (N a b) (N b a) := by
  have hp := dyn_le_neg_one hN hab h
  have hq := dyn_le_neg_one hN (Ne.symm hab) ((hN.zero_comm a b).not.1 h)
  have hpq : N a b * N b a ≤ 3 := by
    by_contra hcon
    push Not at hcon
    let v : ι → ℤ := fun i => if i = a then -N a b else if i = b then 2 else 0
    have hva : v a = -N a b := by simp [v]
    have hvb : v b = 2 := by simp [v, Ne.symm hab]
    have hv0 : ∀ i, 0 ≤ v i := by
      intro i; simp only [v]; split_ifs <;> omega
    apply dyn_forbid hN v hv0 (fun h0 => by have := congrFun h0 b; rw [hvb] at this; simp at this)
    intro i hi
    by_cases hia : i = a
    · subst hia
      have := dyn_loc1 hN hv0 i b (Ne.symm hab)
      rw [hva, hvb] at this; linarith
    by_cases hib : i = b
    · subst hib
      have := dyn_loc1 hN hv0 i a hab
      rw [hva, hvb] at this; nlinarith
    · simp [v, hia, hib] at hi
  have h1 : -3 ≤ N a b := by nlinarith
  have h2 : -3 ≤ N b a := by nlinarith
  unfold DPQ
  interval_cases (N a b) <;> interval_cases (N b a) <;> simp_all

/-- Adding one new vertex (index `k`) to `X`, joined to vertex `s` only, with entries `p` in
column `k` and `q` in row `k`. -/
def dmk {k : ℕ} (X : Matrix (Fin k) (Fin k) ℤ) (s : ℕ) (p q : ℤ) :
    Matrix (Fin (k+1)) (Fin (k+1)) ℤ :=
  Matrix.of fun i j =>
    if hi : i.val < k then
      if hj : j.val < k then X ⟨i, hi⟩ ⟨j, hj⟩ else if i.val = s then p else 0
    else if hj : j.val < k then (if j.val = s then q else 0) else 2

/-- Extend an equivalence by fixing the last index. -/
def dext {m k : ℕ} (e : Fin m ≃ Fin k) : Fin (m+1) ≃ Fin (k+1) :=
  finSuccEquivLast.trans ((Equiv.optionCongr e).trans finSuccEquivLast.symm)

lemma dext_symm_castSucc {m k : ℕ} (e : Fin m ≃ Fin k) (i : Fin k) :
    (dext e).symm i.castSucc = (e.symm i).castSucc := by
  rw [Equiv.symm_apply_eq]; simp [dext]

lemma dext_symm_last {m k : ℕ} (e : Fin m ≃ Fin k) : (dext e).symm (Fin.last k) = Fin.last m := by
  rw [Equiv.symm_apply_eq]; simp [dext]

lemma dyn_reindex_dmk {m k : ℕ} (M : Matrix (Fin (m+1)) (Fin (m+1)) ℤ) (e : Fin m ≃ Fin k)
    (s0 : Fin m) (hd : M (Fin.last m) (Fin.last m) = 2)
    (hrow : ∀ t : Fin m, t ≠ s0 → M (Fin.last m) t.castSucc = 0)
    (hcol : ∀ t : Fin m, t ≠ s0 → M t.castSucc (Fin.last m) = 0) :
    M.reindex (dext e) (dext e) = dmk ((M.submatrix Fin.castSucc Fin.castSucc).reindex e e)
      (e s0).val (M s0.castSucc (Fin.last m)) (M (Fin.last m) s0.castSucc) := by
  ext i j
  induction i using Fin.lastCases with
  | last =>
    induction j using Fin.lastCases with
    | last => simp [dmk, dext_symm_last, hd]
    | cast j =>
      simp only [reindex_apply, submatrix_apply, dext_symm_last, dext_symm_castSucc, dmk, of_apply,
        Fin.val_last, lt_irrefl, dite_false, Fin.val_castSucc, Fin.is_lt, dite_true]
      by_cases hj : j = e s0
      · subst hj; simp
      · have h1 : ¬ (j.val = (e s0).val) := fun h => hj (Fin.ext h)
        have h2 : e.symm j ≠ s0 := fun h => hj (by rw [← h]; simp)
        simp only [h1, ite_false]; exact hrow _ h2
  | cast i =>
    induction j using Fin.lastCases with
    | last =>
      simp only [reindex_apply, submatrix_apply, dext_symm_last, dext_symm_castSucc, dmk, of_apply,
        Fin.val_last, lt_irrefl, dite_false, Fin.val_castSucc, Fin.is_lt, dite_true]
      by_cases hi : i = e s0
      · subst hi; simp
      · have h1 : ¬ (i.val = (e s0).val) := fun h => hi (Fin.ext h)
        have h2 : e.symm i ≠ s0 := fun h => hi (by rw [← h]; simp)
        simp only [h1, ite_false]; exact hcol _ h2
    | cast j =>
      simp [dmk, dext_symm_castSucc]


/-! ## Part C: forbidden windows -/

/-- The check that a small pattern is not of finite type, decided by computation. -/
def DCheck {r : ℕ} (P : Matrix (Fin r) (Fin r) ℤ) (w : Fin r → ℤ) : Prop :=
  (∀ a, P a a = 2) ∧ (∀ a, 0 ≤ w a) ∧ (∃ a, w a ≠ 0) ∧ (∀ a, 0 < w a → (P *ᵥ w) a ≤ 0)

instance {r : ℕ} (P : Matrix (Fin r) (Fin r) ℤ) (w : Fin r → ℤ) : Decidable (DCheck P w) := by
  unfold DCheck; infer_instance

/-- The pattern with the given weighted edges and `2` on the diagonal. -/
def dpat {r : ℕ} (E : List (Fin r × Fin r × ℤ)) : Matrix (Fin r) (Fin r) ℤ :=
  Matrix.of fun a b => if a = b then 2 else
    ((E.find? fun e => decide (e.1 = a ∧ e.2.1 = b)).map fun e => e.2.2).getD 0

lemma dyn_window {n r : ℕ} {N : Matrix (Fin n) (Fin n) ℤ} (hN : N.IsFiniteCartan)
    (f : Fin r → Fin n) (hf : (List.ofFn fun a => (f a).val).Nodup)
    (E : List (Fin r × Fin r × ℤ)) (w : Fin r → ℤ) (hw : DCheck (dpat E) w)
    (hE : ∀ e ∈ E, N (f e.1) (f e.2.1) ≤ e.2.2) : False := by
  have hinj : Function.Injective f := by
    intro a b h
    have : Function.Injective fun a => (f a).val := List.nodup_ofFn.1 hf
    exact this (by simp [h])
  obtain ⟨hPd, hw0, ⟨a0, ha0⟩, hwl⟩ := hw
  have hS := dyn_isFiniteCartan_submatrix hN f hinj
  apply dyn_forbid hS w hw0 (fun h => ha0 (congrFun h a0))
  intro a ha
  refine le_trans ?_ (hwl a ha)
  simp only [mulVec, dotProduct, submatrix_apply]
  apply Finset.sum_le_sum
  intro b _
  by_cases hab : a = b
  · subst hab; rw [hN.diag, hPd]
  apply mul_le_mul_of_nonneg_right _ (hw0 b)
  show N (f a) (f b) ≤ dpat E a b
  unfold dpat
  rw [of_apply, if_neg hab]
  have key : ∀ o : Option (Fin r × Fin r × ℤ),
      E.find? (fun e => decide (e.1 = a ∧ e.2.1 = b)) = o →
      N (f a) (f b) ≤ (o.map fun e => e.2.2).getD 0 := by
    intro o ho
    cases o with
    | none => exact hN.offDiag_nonpos _ _ (hinj.ne hab)
    | some e =>
      have hmem := List.mem_of_find?_eq_some ho
      have hprop := List.find?_some ho
      simp only [decide_eq_true_eq] at hprop
      obtain ⟨h1, h2⟩ := hprop
      have := hE e hmem
      rw [h1, h2] at this
      simpa using this
  exact key _ rfl

def eG2a : List (Fin 3 × Fin 3 × ℤ) := [(0, 1, -1), (1, 0, -1), (1, 2, -1), (2, 1, -3)]
lemma eG2a_check : DCheck (dpat eG2a) ![1, 2, 3] := by decide
def eG2b : List (Fin 3 × Fin 3 × ℤ) := [(0, 1, -1), (1, 0, -1), (1, 2, -3), (2, 1, -1)]
lemma eG2b_check : DCheck (dpat eG2b) ![1, 2, 1] := by decide
def eStA : List (Fin 4 × Fin 4 × ℤ) := [(0, 1, -1), (0, 2, -1), (0, 3, -1), (1, 0, -1), (2, 0, -1), (3, 0, -2)]
lemma eStA_check : DCheck (dpat eStA) ![2, 1, 1, 2] := by decide
def eStB : List (Fin 4 × Fin 4 × ℤ) := [(0, 1, -1), (0, 2, -1), (0, 3, -2), (1, 0, -1), (2, 0, -1), (3, 0, -1)]
lemma eStB_check : DCheck (dpat eStB) ![2, 1, 1, 1] := by decide
def eF4 : List (Fin 5 × Fin 5 × ℤ) := [(0, 1, -1), (1, 0, -1), (1, 2, -1), (2, 1, -1), (2, 3, -2), (3, 2, -1), (3, 4, -1), (4, 3, -1)]
lemma eF4_check : DCheck (dpat eF4) ![1, 2, 3, 2, 1] := by decide
def eW5a : List (Fin 3 × Fin 3 × ℤ) := [(0, 1, -2), (1, 0, -1), (1, 2, -1), (2, 1, -2)]
lemma eW5a_check : DCheck (dpat eW5a) ![1, 1, 1] := by decide
def eW5b : List (Fin 3 × Fin 3 × ℤ) := [(0, 1, -2), (1, 0, -1), (1, 2, -2), (2, 1, -1)]
lemma eW5b_check : DCheck (dpat eW5b) ![2, 2, 1] := by decide
def eB3a : List (Fin 5 × Fin 5 × ℤ) := [(0, 1, -1), (0, 2, -1), (0, 3, -1), (1, 0, -1), (2, 0, -1), (3, 0, -1), (3, 4, -1), (4, 3, -2)]
lemma eB3a_check : DCheck (dpat eB3a) ![2, 1, 1, 2, 2] := by decide
def eB3b : List (Fin 5 × Fin 5 × ℤ) := [(0, 1, -1), (0, 2, -1), (0, 3, -1), (1, 0, -1), (2, 0, -1), (3, 0, -1), (3, 4, -2), (4, 3, -1)]
lemma eB3b_check : DCheck (dpat eB3b) ![2, 1, 1, 2, 1] := by decide
def eD4 : List (Fin 5 × Fin 5 × ℤ) := [(0, 1, -1), (0, 2, -1), (0, 3, -1), (0, 4, -1), (1, 0, -1), (2, 0, -1), (3, 0, -1), (4, 0, -1)]
lemma eD4_check : DCheck (dpat eD4) ![2, 1, 1, 1, 1] := by decide
def eE7 : List (Fin 8 × Fin 8 × ℤ) := [(0, 1, -1), (0, 2, -1), (0, 5, -1), (1, 0, -1), (2, 0, -1), (2, 3, -1), (3, 2, -1), (3, 4, -1), (4, 3, -1), (5, 0, -1), (5, 6, -1), (6, 5, -1), (6, 7, -1), (7, 6, -1)]
lemma eE7_check : DCheck (dpat eE7) ![4, 2, 3, 2, 1, 3, 2, 1] := by decide
def eE8 : List (Fin 9 × Fin 9 × ℤ) := [(0, 1, -1), (0, 2, -1), (0, 4, -1), (1, 0, -1), (2, 0, -1), (2, 3, -1), (3, 2, -1), (4, 0, -1), (4, 5, -1), (5, 4, -1), (5, 6, -1), (6, 5, -1), (6, 7, -1), (7, 6, -1), (7, 8, -1), (8, 7, -1)]
lemma eE8_check : DCheck (dpat eE8) ![6, 3, 4, 2, 5, 4, 3, 2, 1] := by decide

macro "dyn_nodup" : tactic => `(tactic| (simp [List.ofFn_succ, List.nodup_cons] <;> omega))

syntax "dyn_edges" "[" Lean.Parser.Tactic.simpLemma,* "]" "[" Lean.Parser.Tactic.simpLemma,* "]" :
  tactic
macro_rules
  | `(tactic| dyn_edges [$pat,*] [$fam,*]) => `(tactic| (
      simp only [$pat,*, List.forall_mem_cons, List.not_mem_nil, IsEmpty.forall_iff, implies_true,
        forall_const, and_true, Matrix.cons_val, Matrix.cons_val_zero, Fin.isValue] <;>
      (repeat' apply And.intro) <;> simp [dmk, $fam,*] <;> (try split_ifs) <;> omega))

lemma dyn_mult_split {p q : ℤ} (h : DPQ p q) (hm : ¬(p = -1 ∧ q = -1)) :
    (p = -1 ∧ q ≤ -2) ∨ (p ≤ -2 ∧ q = -1) := by
  unfold DPQ at h; omega

/-! ## Part D: relabelling, and the extensions of type A -/

lemma dyn_relabel {k : ℕ} (X : Matrix (Fin k) (Fin k) ℤ) (e : Fin k ≃ Fin k) (s : ℕ) (hs : s < k)
    (p q : ℤ) : (dmk X s p q).reindex (dext e) (dext e) =
      dmk (X.reindex e e) (e ⟨s, hs⟩).val p q := by
  have key : ∀ t : Fin k, ((e.symm t).val = s ↔ t.val = (e ⟨s, hs⟩).val) := by
    intro t
    constructor
    · intro h; rw [← Fin.ext_iff]; rw [← Equiv.symm_apply_eq]; exact Fin.ext h
    · intro h; rw [← Fin.ext_iff] at h; rw [h]; simp
  ext i j
  induction i using Fin.lastCases with
  | last =>
    induction j using Fin.lastCases with
    | last => simp [dmk, dext_symm_last]
    | cast j => simp [dmk, dext_symm_last, dext_symm_castSucc, key]
  | cast i =>
    induction j using Fin.lastCases with
    | last => simp [dmk, dext_symm_last, dext_symm_castSucc, key]
    | cast j => simp [dmk, dext_symm_castSucc]

lemma dyn_transfer {n m : ℕ} {N : Matrix (Fin n) (Fin n) ℤ} {Y : Matrix (Fin m) (Fin m) ℤ}
    (σ : Fin n ≃ Fin m) (h : N.reindex σ σ = Y) (hN : N.IsFiniteCartan)
    (hY : Y.IsFiniteCartan → DL Y) : DL N := by
  apply dyn_DL_of_reindex σ
  rw [h]
  apply hY
  rw [← h]
  exact dyn_isFiniteCartan_reindex hN σ

/-- A permutation given by a table and its inverse table. -/
def dperm {n : ℕ} (f g : Fin n → Fin n) (h1 : ∀ i, g (f i) = i) (h2 : ∀ i, f (g i) = i) :
    Fin n ≃ Fin n := ⟨f, g, h1, h2⟩

lemma dyn_A_rev (k : ℕ) : (A k).reindex Fin.revPerm Fin.revPerm = A k := by
  ext i j
  simp only [reindex_apply, submatrix_apply, Fin.revPerm_symm, Fin.revPerm_apply, A, of_apply,
    Fin.ext_iff, Fin.val_rev]
  split_ifs <;> omega

syntax "dyn_mat" "[" Lean.Parser.Tactic.simpLemma,* "]" : tactic
macro_rules
  | `(tactic| dyn_mat [$fam,*]) => `(tactic| ((ext i j) <;>
      (simp only [reindex_apply, submatrix_apply, Equiv.refl_symm, Equiv.refl_apply, dmk, of_apply,
        Fin.mk.injEq, Fin.ext_iff, $fam,*]) <;>
      split_ifs <;> (try simp only [true_or, or_true, not_true_eq_false, and_true, true_and] at *) <;>
      omega))

lemma dyn_ext_A_last (k : ℕ) (hk : 1 ≤ k) (p q : ℤ) (hpq : DPQ p q)
    (hN : (dmk (A k) (k-1) p q).IsFiniteCartan) : DL (dmk (A k) (k-1) p q) := by
  rcases hpq with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
  · exact Or.inl ⟨k+1, by omega, Equiv.refl _, by dyn_mat [A]⟩
  · exact Or.inr <| Or.inr <| Or.inl ⟨k+1, by omega, Equiv.refl _, by dyn_mat [A, C]⟩
  · exact Or.inr <| Or.inl ⟨k+1, by omega, Equiv.refl _, by dyn_mat [A, B]⟩
  · rcases Nat.lt_or_ge k 2 with h | h
    · obtain rfl : k = 1 := by omega
      exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr ⟨Equiv.swap 0 1, by decide⟩
    · obtain ⟨K, rfl⟩ : ∃ K, k = K + 2 := ⟨k - 2, by omega⟩
      exact (dyn_window hN ![⟨K, by omega⟩, ⟨K+1, by omega⟩, ⟨K+2, by omega⟩] (by dyn_nodup)
        eG2a _ eG2a_check (by dyn_edges [eG2a] [A])).elim
  · rcases Nat.lt_or_ge k 2 with h | h
    · obtain rfl : k = 1 := by omega
      exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr ⟨Equiv.refl _, by decide⟩
    · obtain ⟨K, rfl⟩ : ∃ K, k = K + 2 := ⟨k - 2, by omega⟩
      exact (dyn_window hN ![⟨K, by omega⟩, ⟨K+1, by omega⟩, ⟨K+2, by omega⟩] (by dyn_nodup)
        eG2b _ eG2b_check (by dyn_edges [eG2b] [A])).elim

lemma dyn_ext_A_half (k s : ℕ) (h1 : 2 ≤ s) (h2 : 2 * s + 1 ≤ k)
    (hN : (dmk (A k) s (-1) (-1)).IsFiniteCartan) : DL (dmk (A k) s (-1) (-1)) := by
  rcases Nat.lt_or_ge s 3 with hs | hs
  · have hs2 : s = 2 := by omega
    rcases Nat.lt_or_ge k 8 with hk | hk
    · subst hs2
      interval_cases k
      · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨6, by omega,
          dperm ![0, 2, 3, 4, 5, 1] ![0, 5, 1, 2, 3, 4] (by decide) (by decide), by decide⟩
      · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨7, by omega,
          dperm ![0, 2, 3, 4, 5, 6, 1] ![0, 6, 1, 2, 3, 4, 5] (by decide) (by decide), by decide⟩
      · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨8, by omega,
          dperm ![0, 2, 3, 4, 5, 6, 7, 1] ![0, 7, 1, 2, 3, 4, 5, 6] (by decide) (by decide),
          by decide⟩
    · subst hs2
      obtain ⟨K, rfl⟩ : ∃ K, k = K + 8 := ⟨k - 8, by omega⟩
      exact (dyn_window hN ![⟨2, by omega⟩, ⟨K+8, by omega⟩, ⟨1, by omega⟩, ⟨0, by omega⟩,
        ⟨3, by omega⟩, ⟨4, by omega⟩, ⟨5, by omega⟩, ⟨6, by omega⟩, ⟨7, by omega⟩] (by dyn_nodup)
        eE8 _ eE8_check (by dyn_edges [eE8] [A])).elim
  · obtain ⟨S, rfl⟩ : ∃ S, s = S + 3 := ⟨s - 3, by omega⟩
    obtain ⟨T, rfl⟩ : ∃ T, k = S + T + 7 := ⟨k - S - 7, by omega⟩
    exact (dyn_window hN ![⟨S+3, by omega⟩, ⟨S+T+7, by omega⟩, ⟨S+2, by omega⟩, ⟨S+1, by omega⟩,
        ⟨S, by omega⟩, ⟨S+4, by omega⟩, ⟨S+5, by omega⟩, ⟨S+6, by omega⟩] (by dyn_nodup)
        eE7 _ eE7_check (by dyn_edges [eE7] [A])).elim

lemma dyn_A_rev_dmk (k s : ℕ) (hs : s < k) (p q : ℤ) :
    (dmk (A k) s p q).reindex (dext Fin.revPerm) (dext Fin.revPerm) = dmk (A k) (k-1-s) p q := by
  rw [dyn_relabel _ _ s hs, dyn_A_rev]
  simp only [Fin.revPerm_apply, Fin.val_rev]
  congr 1
  omega

lemma dyn_ext_A_mult (k s : ℕ) (h1 : 1 ≤ s) (h2 : s + 2 ≤ k) (p q : ℤ) (hpq : DPQ p q)
    (hm : ¬(p = -1 ∧ q = -1)) (hN : (dmk (A k) s p q).IsFiniteCartan) : False := by
  obtain ⟨S, rfl⟩ : ∃ S, s = S + 1 := ⟨s - 1, by omega⟩
  obtain ⟨T, rfl⟩ : ∃ T, k = S + T + 3 := ⟨k - S - 3, by omega⟩
  rcases dyn_mult_split hpq hm with ⟨hp, hq⟩ | ⟨hp, hq⟩
  · exact dyn_window hN ![⟨S+1, by omega⟩, ⟨S, by omega⟩, ⟨S+2, by omega⟩, ⟨S+T+3, by omega⟩]
      (by dyn_nodup) eStA _ eStA_check (by dyn_edges [eStA] [A, hp, hq])
  · exact dyn_window hN ![⟨S+1, by omega⟩, ⟨S, by omega⟩, ⟨S+2, by omega⟩, ⟨S+T+3, by omega⟩]
      (by dyn_nodup) eStB _ eStB_check (by dyn_edges [eStB] [A, hp, hq])

lemma dyn_ext_A (k : ℕ) (hk : 1 ≤ k) (s : ℕ) (hs : s < k) (p q : ℤ) (hpq : DPQ p q)
    (hN : (dmk (A k) s p q).IsFiniteCartan) : DL (dmk (A k) s p q) := by
  -- reversing the path sends `s` to `k - 1 - s`
  have rev : ∀ s', s' < k → ((dmk (A k) (k-1-s') p q).IsFiniteCartan →
      DL (dmk (A k) (k-1-s') p q)) → (dmk (A k) s' p q).IsFiniteCartan →
      DL (dmk (A k) s' p q) := fun s' hs' hD hN' =>
    dyn_transfer _ (dyn_A_rev_dmk k s' hs' p q) hN' hD
  have last : ∀ p q, DPQ p q → (dmk (A k) (k-1) p q).IsFiniteCartan →
      DL (dmk (A k) (k-1) p q) := fun p q hpq hN => dyn_ext_A_last k hk p q hpq hN
  rcases Nat.lt_or_ge (s + 1) k with hs1 | hs1
  · rcases Nat.eq_zero_or_pos s with hs0 | hs0
    · subst hs0
      exact rev 0 (by omega) (by simpa using last p q hpq) hN
    by_cases hm : p = -1 ∧ q = -1
    · obtain ⟨rfl, rfl⟩ := hm
      have hD : ∀ s', s' + 2 = k → (dmk (A k) s' (-1) (-1)).IsFiniteCartan →
          DL (dmk (A k) s' (-1) (-1)) := by
        intro s' hs' _
        refine Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨k+1, by omega, Equiv.refl _, ?_⟩
        subst hs'
        dyn_mat [A, D]
      rcases Nat.lt_or_ge (s + 2) k with hs2 | hs2
      · rcases Nat.lt_or_ge s 2 with hs3 | hs3
        · obtain rfl : s = 1 := by omega
          exact rev 1 hs (hD _ (by omega)) hN
        · rcases Nat.lt_or_ge (k - 1 - s) 2 with hs4 | hs4
          · exact rev s hs (hD _ (by omega)) hN
          rcases Nat.lt_or_ge k (2 * s + 1) with hs5 | hs5
          · exact rev s hs (fun h => dyn_ext_A_half k (k-1-s) hs4 (by omega) h) hN
          · exact dyn_ext_A_half k s hs3 hs5 hN
      · exact hD s (by omega) hN
    · exact (dyn_ext_A_mult k s hs0 (by omega) p q hpq hm hN).elim
  · obtain rfl : s = k - 1 := by omega
    exact last p q hpq hN

/-! ## Part F: the extensions of type B -/

/-- Move the new last vertex to the front. -/
def dshift (k : ℕ) : Fin (k+1) ≃ Fin (k+1) :=
  dperm (fun i => if h : i.val < k then ⟨i.val + 1, by omega⟩ else ⟨0, by omega⟩)
    (fun i => if h : 0 < i.val then ⟨i.val - 1, by omega⟩ else ⟨k, by omega⟩)
    (fun i => by
      apply Fin.ext
      by_cases h : i.val < k
      · simp [h]
      · simp [h]; omega)
    (fun i => by
      apply Fin.ext
      by_cases h : 0 < i.val
      · have h2 : i.val - 1 < k := by omega
        simp [h, h2]; omega
      · simp [h]; omega)

lemma dshift_symm_val (k : ℕ) (i : Fin (k+1)) :
    ((dshift k).symm i).val = if 0 < i.val then i.val - 1 else k := by
  simp only [dshift, dperm, Equiv.coe_fn_symm_mk]
  split_ifs <;> rfl

macro "dyn_ne" : tactic => `(tactic| (rw [Ne, Fin.ext_iff]; dsimp only; omega))

syntax "dyn_vec" "[" Lean.Parser.Tactic.simpLemma,* "]" : tactic
macro_rules
  | `(tactic| dyn_vec [$fam,*]) => `(tactic| (
      simp (disch := omega) only [dmk, of_apply, Fin.mk.injEq, dif_pos, dif_neg, if_pos, if_neg,
        ite_true, ite_false, dite_true, dite_false, true_or, or_true, and_true, true_and, $fam,*] <;>
      (try split_ifs) <;> first | omega | linarith))

lemma dyn_B_U1 (k : ℕ) (hk : 2 ≤ k) (p q x : ℤ) (hx0 : 1 ≤ x) (hx1 : p * x ≤ -2)
    (hx2 : x + q ≤ 0) (hN : (dmk (B k) 0 p q).IsFiniteCartan) : False := by
  obtain ⟨v, hv⟩ : ∃ v : Fin (k+1) → ℤ,
    v = fun i => if i.val = k then x else if i.val + 1 < k then 2 else 1 := ⟨_, rfl⟩
  have hv0 : ∀ i, 0 ≤ v i := by intro i; rw [hv]; dsimp only; split_ifs <;> omega
  refine dyn_forbid hN v hv0 (fun h => by
    have := congrFun h ⟨k, by omega⟩; rw [hv] at this; simp at this; omega) ?_
  intro i _
  have hi := i.isLt
  rcases Nat.lt_or_ge i.val k with h1 | h1
  · rcases Nat.eq_zero_or_pos i.val with h2 | h2
    · refine le_trans (dyn_loc2 hN hv0 i ⟨k, by omega⟩ ⟨1, by omega⟩ (by dyn_ne)
        (by dyn_ne) (by dyn_ne)) ?_
      clear hN hv0; subst hv; dyn_vec [B]
    · rcases Nat.lt_or_ge (i.val + 1) k with h3 | h3
      · refine le_trans (dyn_loc2 hN hv0 i ⟨i.val - 1, by omega⟩ ⟨i.val + 1, by omega⟩
          (by dyn_ne) (by dyn_ne) (by dyn_ne)) ?_
        clear hN hv0; subst hv; dyn_vec [B]
      · refine le_trans (dyn_loc1 hN hv0 i ⟨i.val - 1, by omega⟩ (by dyn_ne)) ?_
        clear hN hv0; subst hv; dyn_vec [B]
  · refine le_trans (dyn_loc1 hN hv0 i ⟨0, by omega⟩ (by dyn_ne)) ?_
    clear hN hv0; subst hv; dyn_vec [B]

/-- A fork at `s` (leaves `s - 1` and the new vertex) and the double edge at the far end. -/
lemma dyn_B_U2 (k s : ℕ) (h1 : 1 ≤ s) (h2 : s + 3 ≤ k)
    (hN : (dmk (B k) s (-1) (-1)).IsFiniteCartan) : False := by
  obtain ⟨v, hv⟩ : ∃ v : Fin (k+1) → ℤ, v = fun i => if i.val = k then 1 else
    if i.val + 1 = s then 1 else if s ≤ i.val ∧ i.val + 2 ≤ k then 2 else
    if i.val + 1 = k then 1 else 0 := ⟨_, rfl⟩
  have hv0 : ∀ i, 0 ≤ v i := by intro i; rw [hv]; dsimp only; split_ifs <;> omega
  refine dyn_forbid hN v hv0 (fun h => by
    have := congrFun h ⟨k, by omega⟩; rw [hv] at this; simp at this) ?_
  intro i hpos
  have hi := i.isLt
  have hsupp : i.val = k ∨ i.val + 1 = s ∨ (s ≤ i.val ∧ i.val + 2 ≤ k) ∨ i.val + 1 = k := by
    rw [hv] at hpos; dsimp only at hpos; split_ifs at hpos <;> omega
  rcases hsupp with h3 | h3 | ⟨h3, h4⟩ | h3
  · refine le_trans (dyn_loc1 hN hv0 i ⟨s, by omega⟩ (by dyn_ne)) ?_
    clear hN hv0 hpos; subst hv; dyn_vec [B]
  · refine le_trans (dyn_loc1 hN hv0 i ⟨s, by omega⟩ (by dyn_ne)) ?_
    clear hN hv0 hpos; subst hv; dyn_vec [B]
  · rcases Nat.eq_or_lt_of_le h3 with h5 | h5
    · refine le_trans (dyn_loc3 hN hv0 i ⟨s - 1, by omega⟩ ⟨k, by omega⟩ ⟨s + 1, by omega⟩
        (by dyn_ne) (by dyn_ne) (by dyn_ne) (by dyn_ne) (by dyn_ne) (by dyn_ne)) ?_
      clear hN hv0 hpos; subst hv; dyn_vec [B]
    · refine le_trans (dyn_loc2 hN hv0 i ⟨i.val - 1, by omega⟩ ⟨i.val + 1, by omega⟩
        (by dyn_ne) (by dyn_ne) (by dyn_ne)) ?_
      clear hN hv0 hpos; subst hv; dyn_vec [B]
  · refine le_trans (dyn_loc1 hN hv0 i ⟨i.val - 1, by omega⟩ (by dyn_ne)) ?_
    clear hN hv0 hpos; subst hv; dyn_vec [B]

lemma dyn_B_shift (k : ℕ) (hk : 2 ≤ k) :
    (dmk (B k) 0 (-1) (-1)).reindex (dshift k) (dshift k) = B (k+1) := by
  ext i j
  simp only [reindex_apply, submatrix_apply, dmk, of_apply, B, Fin.mk.injEq, dshift_symm_val,
    Fin.ext_iff]
  split_ifs <;> omega

lemma dyn_ext_B (k : ℕ) (hk : 2 ≤ k) (s : ℕ) (hs : s < k) (p q : ℤ) (hpq : DPQ p q)
    (hN : (dmk (B k) s p q).IsFiniteCartan) : DL (dmk (B k) s p q) := by
  rcases Nat.eq_zero_or_pos s with rfl | hs0
  · -- the simple end
    by_cases hm : p = -1 ∧ q = -1
    · obtain ⟨rfl, rfl⟩ := hm
      exact Or.inr <| Or.inl ⟨k+1, by omega, dshift k, dyn_B_shift k hk⟩
    rcases dyn_mult_split hpq hm with ⟨rfl, hq⟩ | ⟨hp, rfl⟩
    · exact (dyn_B_U1 k hk (-1) q 2 (by norm_num) (by norm_num) (by omega) hN).elim
    · exact (dyn_B_U1 k hk p (-1) 1 (by norm_num) (by omega) (by norm_num) hN).elim
  rcases Nat.lt_or_ge (s + 1) k with hs1 | hs1
  · -- an inner vertex
    by_cases hm : p = -1 ∧ q = -1
    · obtain ⟨rfl, rfl⟩ := hm
      rcases Nat.lt_or_ge (s + 2) k with hs2 | hs2
      · exact (dyn_B_U2 k s hs0 (by omega) hN).elim
      · obtain rfl : s = k - 2 := by omega
        obtain ⟨K, rfl⟩ : ∃ K, k = K + 3 := ⟨k - 3, by omega⟩
        exact (dyn_window hN ![⟨K+1, by omega⟩, ⟨K, by omega⟩, ⟨K+3, by omega⟩, ⟨K+2, by omega⟩]
          (by dyn_nodup) eStB _ eStB_check (by dyn_edges [eStB] [B])).elim
    · obtain ⟨S, rfl⟩ : ∃ S, s = S + 1 := ⟨s - 1, by omega⟩
      obtain ⟨T, rfl⟩ : ∃ T, k = S + T + 3 := ⟨k - S - 3, by omega⟩
      rcases dyn_mult_split hpq hm with ⟨hp, hq⟩ | ⟨hp, hq⟩
      · exact (dyn_window hN ![⟨S+1, by omega⟩, ⟨S, by omega⟩, ⟨S+2, by omega⟩, ⟨S+T+3, by omega⟩]
          (by dyn_nodup) eStA _ eStA_check (by dyn_edges [eStA] [B, hp, hq])).elim
      · exact (dyn_window hN ![⟨S+1, by omega⟩, ⟨S, by omega⟩, ⟨S+2, by omega⟩, ⟨S+T+3, by omega⟩]
          (by dyn_nodup) eStB _ eStB_check (by dyn_edges [eStB] [B, hp, hq])).elim
  · -- the double end
    obtain rfl : s = k - 1 := by omega
    by_cases hm : p = -1 ∧ q = -1
    · obtain ⟨rfl, rfl⟩ := hm
      rcases Nat.lt_or_ge k 4 with hk4 | hk4
      · interval_cases k
        · exact Or.inr <| Or.inr <| Or.inl ⟨3, by omega,
            dperm ![2, 1, 0] ![2, 1, 0] (by decide) (by decide), by decide⟩
        · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨Equiv.refl _, by decide⟩
      · obtain ⟨K, rfl⟩ : ∃ K, k = K + 4 := ⟨k - 4, by omega⟩
        exact (dyn_window hN ![⟨K, by omega⟩, ⟨K+1, by omega⟩, ⟨K+2, by omega⟩, ⟨K+3, by omega⟩,
          ⟨K+4, by omega⟩] (by dyn_nodup) eF4 _ eF4_check (by dyn_edges [eF4] [B])).elim
    · obtain ⟨K, rfl⟩ : ∃ K, k = K + 2 := ⟨k - 2, by omega⟩
      rcases dyn_mult_split hpq hm with ⟨hp, hq⟩ | ⟨hp, hq⟩
      · exact (dyn_window hN ![⟨K, by omega⟩, ⟨K+1, by omega⟩, ⟨K+2, by omega⟩]
          (by dyn_nodup) eW5a _ eW5a_check (by dyn_edges [eW5a] [B, hp, hq])).elim
      · exact (dyn_window hN ![⟨K, by omega⟩, ⟨K+1, by omega⟩, ⟨K+2, by omega⟩]
          (by dyn_nodup) eW5b _ eW5b_check (by dyn_edges [eW5b] [B, hp, hq])).elim

/-! ## Part H: type C by transposing -/

lemma dyn_DL_transpose {n : ℕ} {M : Matrix (Fin n) (Fin n) ℤ} (h : DL M) : DL Mᵀ := by
  have key : ∀ {m : ℕ} (e : Fin n ≃ Fin m), Mᵀ.reindex e e = (M.reindex e e)ᵀ := by
    intro m e; rw [transpose_reindex]
  rcases h with ⟨k, hk, e, he⟩ | ⟨k, hk, e, he⟩ | ⟨k, hk, e, he⟩ | ⟨k, hk, e, he⟩ |
    ⟨k, hk, e, he⟩ | ⟨e, he⟩ | ⟨e, he⟩
  · exact Or.inl ⟨k, hk, e, by rw [key, he, A_transpose]⟩
  · exact Or.inr <| Or.inr <| Or.inl ⟨k, hk, e, by rw [key, he, B_transpose]⟩
  · exact Or.inr <| Or.inl ⟨k, hk, e, by rw [key, he, C_transpose]⟩
  · exact Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨k, hk, e, by rw [key, he, D_transpose]⟩
  · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨k, hk, e, by rw [key, he, E_transpose]⟩
  · refine Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨e.trans Fin.revPerm, ?_⟩
    have : Mᵀ.reindex (e.trans Fin.revPerm) (e.trans Fin.revPerm) =
        ((Mᵀ).reindex e e).reindex Fin.revPerm Fin.revPerm := by ext i j; simp
    rw [this, key, he]; decide
  · refine Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inr ⟨e.trans (Equiv.swap 0 1), ?_⟩
    have : Mᵀ.reindex (e.trans (Equiv.swap 0 1)) (e.trans (Equiv.swap 0 1)) =
        ((Mᵀ).reindex e e).reindex (Equiv.swap 0 1) (Equiv.swap 0 1) := by ext i j; simp
    rw [this, key, he]; decide

lemma dyn_dmk_transpose {k : ℕ} (X : Matrix (Fin k) (Fin k) ℤ) (s : ℕ) (p q : ℤ) :
    (dmk X s p q)ᵀ = dmk Xᵀ s q p := by
  ext i j
  simp only [transpose_apply, dmk, of_apply]
  split_ifs <;> rfl

lemma dyn_DPQ_swap {p q : ℤ} (h : DPQ p q) : DPQ q p := by
  unfold DPQ at *; omega

lemma dyn_ext_C (k : ℕ) (hk : 2 ≤ k) (s : ℕ) (hs : s < k) (p q : ℤ) (hpq : DPQ p q)
    (hN : (dmk (C k) s p q).IsFiniteCartan) : DL (dmk (C k) s p q) := by
  have e1 : dmk (C k) s p q = (dmk (B k) s q p)ᵀ := by
    rw [dyn_dmk_transpose, B_transpose]
  rw [e1] at hN ⊢
  exact dyn_DL_transpose (dyn_ext_B k hk s hs q p (dyn_DPQ_swap hpq) (by simpa using hN.transpose))

/-! ## Part I: the extensions of type D -/

set_option maxHeartbeats 1000000 in
lemma dyn_D_U2 (k : ℕ) (hk : 4 ≤ k) (p q x : ℤ) (hx0 : 1 ≤ x) (hx1 : p * x ≤ -2)
    (hx2 : x + q ≤ 0) (hN : (dmk (D k) 0 p q).IsFiniteCartan) : False := by
  obtain ⟨v, hv⟩ : ∃ v : Fin (k+1) → ℤ,
    v = fun i => if i.val = k then x else if i.val + 3 ≤ k then 2 else 1 := ⟨_, rfl⟩
  have hv0 : ∀ i, 0 ≤ v i := by intro i; rw [hv]; dsimp only; split_ifs <;> omega
  refine dyn_forbid hN v hv0 (fun h => by
    have := congrFun h ⟨k, by omega⟩; rw [hv] at this; simp at this; omega) ?_
  intro i _
  have hi := i.isLt
  rcases Nat.lt_or_ge i.val k with h1 | h1
  · rcases Nat.eq_zero_or_pos i.val with h2 | h2
    · refine le_trans (dyn_loc2 hN hv0 i ⟨k, by omega⟩ ⟨1, by omega⟩ (by dyn_ne)
        (by dyn_ne) (by dyn_ne)) ?_
      clear hN hv0; subst hv; dyn_vec [D]
    · rcases Nat.lt_or_ge (i.val + 3) k with h3 | h3
      · refine le_trans (dyn_loc2 hN hv0 i ⟨i.val - 1, by omega⟩ ⟨i.val + 1, by omega⟩
          (by dyn_ne) (by dyn_ne) (by dyn_ne)) ?_
        clear hN hv0; subst hv; dyn_vec [D]
      · rcases Nat.eq_or_lt_of_le h3 with h4 | h4
        · refine le_trans (dyn_loc3 hN hv0 i ⟨k - 4, by omega⟩ ⟨k - 2, by omega⟩ ⟨k - 1, by omega⟩
            (by dyn_ne) (by dyn_ne) (by dyn_ne) (by dyn_ne) (by dyn_ne) (by dyn_ne)) ?_
          clear hN hv0; subst hv; dyn_vec [D]
        · refine le_trans (dyn_loc1 hN hv0 i ⟨k - 3, by omega⟩ (by dyn_ne)) ?_
          clear hN hv0; subst hv; dyn_vec [D]
  · refine le_trans (dyn_loc1 hN hv0 i ⟨0, by omega⟩ (by dyn_ne)) ?_
    clear hN hv0; subst hv; dyn_vec [D]

set_option maxHeartbeats 1000000 in
/-- A second branch point at `s`. -/
lemma dyn_D_U3 (k s : ℕ) (h1 : 1 ≤ s) (h2 : s + 4 ≤ k)
    (hN : (dmk (D k) s (-1) (-1)).IsFiniteCartan) : False := by
  obtain ⟨v, hv⟩ : ∃ v : Fin (k+1) → ℤ, v = fun i => if i.val = k then 1 else
    if i.val + 1 = s then 1 else if s ≤ i.val ∧ i.val + 3 ≤ k then 2 else
    if s ≤ i.val then 1 else 0 := ⟨_, rfl⟩
  have hv0 : ∀ i, 0 ≤ v i := by intro i; rw [hv]; dsimp only; split_ifs <;> omega
  refine dyn_forbid hN v hv0 (fun h => by
    have := congrFun h ⟨k, by omega⟩; rw [hv] at this; simp at this) ?_
  intro i hpos
  have hi := i.isLt
  have hsupp : i.val = k ∨ i.val + 1 = s ∨ (s ≤ i.val ∧ i.val + 3 ≤ k) ∨
      (i.val + 3 > k ∧ i.val < k) := by
    rw [hv] at hpos; dsimp only at hpos; split_ifs at hpos <;> omega
  rcases hsupp with h3 | h3 | ⟨h3, h4⟩ | ⟨h3, h4⟩
  · refine le_trans (dyn_loc1 hN hv0 i ⟨s, by omega⟩ (by dyn_ne)) ?_
    clear hN hv0 hpos; subst hv; dyn_vec [D]
  · refine le_trans (dyn_loc1 hN hv0 i ⟨s, by omega⟩ (by dyn_ne)) ?_
    clear hN hv0 hpos; subst hv; dyn_vec [D]
  · rcases Nat.eq_or_lt_of_le h3 with h5 | h5
    · refine le_trans (dyn_loc3 hN hv0 i ⟨s - 1, by omega⟩ ⟨k, by omega⟩ ⟨s + 1, by omega⟩
        (by dyn_ne) (by dyn_ne) (by dyn_ne) (by dyn_ne) (by dyn_ne) (by dyn_ne)) ?_
      clear hN hv0 hpos; subst hv; dyn_vec [D]
    · rcases Nat.eq_or_lt_of_le h4 with h6 | h6
      · refine le_trans (dyn_loc3 hN hv0 i ⟨k - 4, by omega⟩ ⟨k - 2, by omega⟩ ⟨k - 1, by omega⟩
          (by dyn_ne) (by dyn_ne) (by dyn_ne) (by dyn_ne) (by dyn_ne) (by dyn_ne)) ?_
        clear hN hv0 hpos; subst hv; dyn_vec [D]
      · refine le_trans (dyn_loc2 hN hv0 i ⟨i.val - 1, by omega⟩ ⟨i.val + 1, by omega⟩
          (by dyn_ne) (by dyn_ne) (by dyn_ne)) ?_
        clear hN hv0 hpos; subst hv; dyn_vec [D]
  · refine le_trans (dyn_loc1 hN hv0 i ⟨k - 3, by omega⟩ (by dyn_ne)) ?_
    clear hN hv0 hpos; subst hv; dyn_vec [D]

lemma dyn_D_shift (k : ℕ) (hk : 4 ≤ k) :
    (dmk (D k) 0 (-1) (-1)).reindex (dshift k) (dshift k) = D (k+1) := by
  obtain ⟨K, rfl⟩ : ∃ K, k = K + 4 := ⟨k - 4, by omega⟩
  ext ⟨i, hi⟩ ⟨j, hj⟩
  simp only [reindex_apply, submatrix_apply, dshift, dperm, Equiv.coe_fn_symm_mk]
  rcases i with _ | i <;> rcases j with _ | j <;>
    simp [dmk, D] <;> (try split_ifs) <;> omega

set_option maxHeartbeats 1000000 in
lemma dyn_ext_D_leaf (k : ℕ) (hk : 4 ≤ k) (s : ℕ) (hs : s = k - 2 ∨ s = k - 1) (p q : ℤ)
    (hpq : DPQ p q) (hN : (dmk (D k) s p q).IsFiniteCartan) : DL (dmk (D k) s p q) := by
  by_cases hm : p = -1 ∧ q = -1
  · obtain ⟨rfl, rfl⟩ := hm
    rcases Nat.lt_or_ge k 8 with hk8 | hk8
    · interval_cases k <;> rcases hs with rfl | rfl
      · exact Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨5, by omega,
          dperm ![3, 2, 1, 4, 0] ![4, 2, 1, 0, 3] (by decide) (by decide), by decide⟩
      · exact Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨5, by omega,
          dperm ![3, 2, 4, 1, 0] ![4, 3, 1, 0, 2] (by decide) (by decide), by decide⟩
      · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨6, by omega,
          dperm ![0, 2, 3, 4, 1, 5] ![0, 4, 1, 2, 3, 5] (by decide) (by decide), by decide⟩
      · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨6, by omega,
          dperm ![0, 2, 3, 1, 4, 5] ![0, 3, 1, 2, 4, 5] (by decide) (by decide), by decide⟩
      · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨7, by omega,
          dperm ![6, 5, 4, 3, 2, 1, 0] ![6, 5, 4, 3, 2, 1, 0] (by decide) (by decide), by decide⟩
      · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨7, by omega,
          dperm ![6, 5, 4, 3, 1, 2, 0] ![6, 4, 5, 3, 2, 1, 0] (by decide) (by decide), by decide⟩
      · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨8, by omega,
          dperm ![7, 6, 5, 4, 3, 2, 1, 0] ![7, 6, 5, 4, 3, 2, 1, 0] (by decide) (by decide),
          by decide⟩
      · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨8, by omega,
          dperm ![7, 6, 5, 4, 3, 1, 2, 0] ![7, 5, 6, 4, 3, 2, 1, 0] (by decide) (by decide),
          by decide⟩
    · obtain ⟨K, rfl⟩ : ∃ K, k = K + 8 := ⟨k - 8, by omega⟩
      rcases hs with rfl | rfl
      · exact (dyn_window hN ![⟨K+5, by omega⟩, ⟨K+7, by omega⟩, ⟨K+6, by omega⟩, ⟨K+8, by omega⟩,
          ⟨K+4, by omega⟩, ⟨K+3, by omega⟩, ⟨K+2, by omega⟩, ⟨K+1, by omega⟩, ⟨K, by omega⟩]
          (by dyn_nodup) eE8 _ eE8_check (by dyn_edges [eE8] [D])).elim
      · exact (dyn_window hN ![⟨K+5, by omega⟩, ⟨K+6, by omega⟩, ⟨K+7, by omega⟩, ⟨K+8, by omega⟩,
          ⟨K+4, by omega⟩, ⟨K+3, by omega⟩, ⟨K+2, by omega⟩, ⟨K+1, by omega⟩, ⟨K, by omega⟩]
          (by dyn_nodup) eE8 _ eE8_check (by dyn_edges [eE8] [D])).elim
  · obtain ⟨K, rfl⟩ : ∃ K, k = K + 4 := ⟨k - 4, by omega⟩
    rcases dyn_mult_split hpq hm with ⟨hp, hq⟩ | ⟨hp, hq⟩ <;> rcases hs with rfl | rfl
    · exact (dyn_window hN ![⟨K+1, by omega⟩, ⟨K, by omega⟩, ⟨K+3, by omega⟩, ⟨K+2, by omega⟩,
        ⟨K+4, by omega⟩] (by dyn_nodup) eB3a _ eB3a_check (by dyn_edges [eB3a] [D, hp, hq])).elim
    · exact (dyn_window hN ![⟨K+1, by omega⟩, ⟨K, by omega⟩, ⟨K+2, by omega⟩, ⟨K+3, by omega⟩,
        ⟨K+4, by omega⟩] (by dyn_nodup) eB3a _ eB3a_check (by dyn_edges [eB3a] [D, hp, hq])).elim
    · exact (dyn_window hN ![⟨K+1, by omega⟩, ⟨K, by omega⟩, ⟨K+3, by omega⟩, ⟨K+2, by omega⟩,
        ⟨K+4, by omega⟩] (by dyn_nodup) eB3b _ eB3b_check (by dyn_edges [eB3b] [D, hp, hq])).elim
    · exact (dyn_window hN ![⟨K+1, by omega⟩, ⟨K, by omega⟩, ⟨K+2, by omega⟩, ⟨K+3, by omega⟩,
        ⟨K+4, by omega⟩] (by dyn_nodup) eB3b _ eB3b_check (by dyn_edges [eB3b] [D, hp, hq])).elim

set_option maxHeartbeats 1000000 in
lemma dyn_ext_D (k : ℕ) (hk : 4 ≤ k) (s : ℕ) (hs : s < k) (p q : ℤ) (hpq : DPQ p q)
    (hN : (dmk (D k) s p q).IsFiniteCartan) : DL (dmk (D k) s p q) := by
  rcases Nat.eq_zero_or_pos s with rfl | hs0
  · by_cases hm : p = -1 ∧ q = -1
    · obtain ⟨rfl, rfl⟩ := hm
      exact Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨k+1, by omega, dshift k, dyn_D_shift k hk⟩
    rcases dyn_mult_split hpq hm with ⟨rfl, hq⟩ | ⟨hp, rfl⟩
    · exact (dyn_D_U2 k hk (-1) q 2 (by norm_num) (by norm_num) (by omega) hN).elim
    · exact (dyn_D_U2 k hk p (-1) 1 (by norm_num) (by omega) (by norm_num) hN).elim
  rcases Nat.lt_or_ge (s + 2) k with hs1 | hs1
  · by_cases hm : p = -1 ∧ q = -1
    · obtain ⟨rfl, rfl⟩ := hm
      rcases Nat.lt_or_ge (s + 3) k with hs2 | hs2
      · exact (dyn_D_U3 k s hs0 (by omega) hN).elim
      · obtain rfl : s = k - 3 := by omega
        obtain ⟨K, rfl⟩ : ∃ K, k = K + 4 := ⟨k - 4, by omega⟩
        exact (dyn_window hN ![⟨K+1, by omega⟩, ⟨K, by omega⟩, ⟨K+2, by omega⟩, ⟨K+3, by omega⟩,
          ⟨K+4, by omega⟩] (by dyn_nodup) eD4 _ eD4_check (by dyn_edges [eD4] [D])).elim
    · rcases Nat.lt_or_ge (s + 3) k with hs2 | hs2
      · obtain ⟨S, rfl⟩ : ∃ S, s = S + 1 := ⟨s - 1, by omega⟩
        obtain ⟨T, rfl⟩ : ∃ T, k = S + T + 5 := ⟨k - S - 5, by omega⟩
        rcases dyn_mult_split hpq hm with ⟨hp, hq⟩ | ⟨hp, hq⟩
        · exact (dyn_window hN ![⟨S+1, by omega⟩, ⟨S, by omega⟩, ⟨S+2, by omega⟩,
            ⟨S+T+5, by omega⟩] (by dyn_nodup) eStA _ eStA_check (by dyn_edges [eStA] [D, hp, hq])).elim
        · exact (dyn_window hN ![⟨S+1, by omega⟩, ⟨S, by omega⟩, ⟨S+2, by omega⟩,
            ⟨S+T+5, by omega⟩] (by dyn_nodup) eStB _ eStB_check (by dyn_edges [eStB] [D, hp, hq])).elim
      · obtain rfl : s = k - 3 := by omega
        obtain ⟨K, rfl⟩ : ∃ K, k = K + 4 := ⟨k - 4, by omega⟩
        rcases dyn_mult_split hpq hm with ⟨hp, hq⟩ | ⟨hp, hq⟩
        · exact (dyn_window hN ![⟨K+1, by omega⟩, ⟨K, by omega⟩, ⟨K+2, by omega⟩,
            ⟨K+4, by omega⟩] (by dyn_nodup) eStA _ eStA_check (by dyn_edges [eStA] [D, hp, hq])).elim
        · exact (dyn_window hN ![⟨K+1, by omega⟩, ⟨K, by omega⟩, ⟨K+2, by omega⟩,
            ⟨K+4, by omega⟩] (by dyn_nodup) eStB _ eStB_check (by dyn_edges [eStB] [D, hp, hq])).elim
  · exact dyn_ext_D_leaf k hk s (by omega) p q hpq hN

/-! ## Part K: extensions of E6, E7, E8, F4 and G2 (finite case checks) -/

lemma dyn_forbid_dec {n : ℕ} {N : Matrix (Fin n) (Fin n) ℤ} (hN : N.IsFiniteCartan) (w : Fin n → ℤ)
    (h : (∀ i, 0 ≤ w i) ∧ (∃ i, w i ≠ 0) ∧ (∀ i, 0 < w i → (N *ᵥ w) i ≤ 0)) : False := by
  obtain ⟨h1, ⟨i, hi⟩, h3⟩ := h
  exact dyn_forbid hN w h1 (fun h0 => hi (congrFun h0 i)) h3

set_option maxHeartbeats 4000000 in
lemma dyn_ext_E6 (s : ℕ) (hs : s < 6) (p q : ℤ) (hpq : DPQ p q)
    (hN : (dmk (E 6) s p q).IsFiniteCartan) : DL (dmk (E 6) s p q) := by
  interval_cases s <;>
    rcases hpq with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
  · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨7, by omega,
      dperm ![5, 1, 4, 3, 2, 0, 6] ![5, 1, 4, 3, 2, 0, 6] (by decide) (by decide), by decide⟩
  · exact (dyn_forbid_dec hN ![2, 1, 2, 2, 1, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 1, 2, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 0, 1, 0, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 0, 1, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 2, 2, 3, 2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 1, 2, 1, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 1, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 0, 1, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 0, 1, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 1, 2, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 0, 2, 1, 0, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 0, 2, 1, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 0, 2, 0, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 0, 2, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 0, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 0, 2, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 0, 2, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 1, 2, 1, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 1, 2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 1, 2, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 1, 2, 0, 1] (by decide)).elim
  · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨7, by omega,
      dperm ![0, 1, 2, 3, 4, 5, 6] ![0, 1, 2, 3, 4, 5, 6] (by decide) (by decide), by decide⟩
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 2, 2, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 2, 2, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 1, 2, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 1, 2, 1] (by decide)).elim

set_option maxHeartbeats 4000000 in
lemma dyn_ext_E7 (s : ℕ) (hs : s < 7) (p q : ℤ) (hpq : DPQ p q)
    (hN : (dmk (E 7) s p q).IsFiniteCartan) : DL (dmk (E 7) s p q) := by
  interval_cases s <;>
    rcases hpq with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
  · exact (dyn_forbid_dec hN ![2, 2, 3, 4, 3, 2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 1, 2, 2, 1, 0, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 1, 2, 2, 1, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 0, 1, 0, 0, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 0, 1, 0, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 2, 2, 3, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 1, 2, 1, 0, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 1, 2, 1, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 0, 1, 0, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 0, 1, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 1, 2, 2, 1, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 0, 2, 1, 0, 0, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 0, 2, 1, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 0, 2, 0, 0, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 0, 2, 0, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 1, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 0, 0, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 0, 2, 0, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 0, 2, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 1, 2, 1, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 1, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 1, 2, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 1, 2, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 2, 2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 1, 2, 1, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 1, 2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 1, 2, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 1, 2, 0, 1] (by decide)).elim
  · exact Or.inr <| Or.inr <| Or.inr <| Or.inr <| Or.inl ⟨8, by omega,
      dperm ![0, 1, 2, 3, 4, 5, 6, 7] ![0, 1, 2, 3, 4, 5, 6, 7] (by decide) (by decide), by decide⟩
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 2, 2, 2, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 2, 2, 2, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 0, 1, 2, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 0, 1, 2, 1] (by decide)).elim

set_option maxHeartbeats 4000000 in
lemma dyn_ext_E8 (s : ℕ) (hs : s < 8) (p q : ℤ) (hpq : DPQ p q)
    (hN : (dmk (E 8) s p q).IsFiniteCartan) : DL (dmk (E 8) s p q) := by
  interval_cases s <;>
    rcases hpq with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
  · exact (dyn_forbid_dec hN ![2, 2, 3, 4, 3, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 1, 2, 2, 1, 0, 0, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 1, 2, 2, 1, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 0, 1, 0, 0, 0, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 0, 1, 0, 0, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 2, 2, 3, 2, 1, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 1, 2, 1, 0, 0, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 1, 2, 1, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 0, 1, 0, 0, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 0, 1, 0, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 1, 2, 2, 1, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 0, 2, 1, 0, 0, 0, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 0, 2, 1, 0, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 0, 2, 0, 0, 0, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 0, 2, 0, 0, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 1, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 0, 0, 0, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 0, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 0, 2, 0, 0, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 0, 2, 0, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 2, 1, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 1, 2, 1, 0, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 1, 2, 1, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 1, 2, 0, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 1, 2, 0, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 2, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 1, 2, 1, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 1, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 1, 2, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 1, 2, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 2, 2, 2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 0, 1, 2, 1, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 0, 1, 2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 0, 1, 2, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 0, 1, 2, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 3, 4, 6, 5, 4, 3, 2, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 2, 2, 2, 2, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 2, 2, 2, 2, 2, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 0, 0, 1, 2, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 0, 0, 0, 0, 1, 2, 1] (by decide)).elim

set_option maxHeartbeats 4000000 in
lemma dyn_ext_F4 (s : ℕ) (hs : s < 4) (p q : ℤ) (hpq : DPQ p q)
    (hN : (dmk (F₄) s p q).IsFiniteCartan) : DL (dmk (F₄) s p q) := by
  interval_cases s <;>
    rcases hpq with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
  · exact (dyn_forbid_dec hN ![2, 3, 2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 2, 1, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 1, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 1, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 1, 0, 2] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 2, 0, 0, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 2, 0, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 2, 0, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 2, 1, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 4, 3, 2, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 1, 1, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 2, 2, 2, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 1, 2, 3] (by decide)).elim
  · exact (dyn_forbid_dec hN ![0, 0, 1, 2, 1] (by decide)).elim

set_option maxHeartbeats 4000000 in
lemma dyn_ext_G2 (s : ℕ) (hs : s < 2) (p q : ℤ) (hpq : DPQ p q)
    (hN : (dmk (G₂) s p q).IsFiniteCartan) : DL (dmk (G₂) s p q) := by
  interval_cases s <;>
    rcases hpq with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
  · exact (dyn_forbid_dec hN ![2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![3, 2, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![2, 2, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 1, 1] (by decide)).elim
  · exact (dyn_forbid_dec hN ![1, 2, 1] (by decide)).elim

lemma dyn_ext_E (k : ℕ) (hk : k = 6 ∨ k = 7 ∨ k = 8) (s : ℕ) (hs : s < k) (p q : ℤ)
    (hpq : DPQ p q) (hN : (dmk (E k) s p q).IsFiniteCartan) : DL (dmk (E k) s p q) := by
  rcases hk with rfl | rfl | rfl
  · exact dyn_ext_E6 s hs p q hpq hN
  · exact dyn_ext_E7 s hs p q hpq hN
  · exact dyn_ext_E8 s hs p q hpq hN

lemma dyn_ext_F (s : ℕ) (hs : s < 4) (p q : ℤ) (hpq : DPQ p q)
    (hN : (dmk F₄ s p q).IsFiniteCartan) : DL (dmk F₄ s p q) := dyn_ext_F4 s hs p q hpq hN

lemma dyn_ext_G (s : ℕ) (hs : s < 2) (p q : ℤ) (hpq : DPQ p q)
    (hN : (dmk G₂ s p q).IsFiniteCartan) : DL (dmk G₂ s p q) := dyn_ext_G2 s hs p q hpq hN

lemma dyn_main (n : ℕ) :
    ∀ M : Matrix (Fin (n+1)) (Fin (n+1)) ℤ, M.IsFiniteCartan → DConn M → DL M := by
  induction n with
  | zero =>
    intro M hM _
    refine Or.inl ⟨1, le_rfl, Equiv.refl _, ?_⟩
    ext i j
    fin_cases i; fin_cases j
    simp [hM.diag, A]
  | succ n ih =>
    intro M hM hc
    obtain ⟨z, s, hsz, hzs, hleaf⟩ := dyn_exists_leaf hM hc
    let τ := Equiv.swap z (Fin.last (n+1))
    let M1 := M.reindex τ τ
    apply dyn_DL_of_reindex τ
    have h1 : M1.IsFiniteCartan := dyn_isFiniteCartan_reindex hM τ
    have hc1 : DConn M1 := dyn_conn_reindex hc τ
    have hτs : τ s ≠ Fin.last (n+1) := by
      intro h
      have : s = z := by
        have := congrArg τ.symm h
        simpa [τ, Equiv.swap_apply_right] using this
      exact hsz this
    obtain ⟨s0, hs0⟩ : ∃ s0 : Fin (n+1), τ s = s0.castSucc :=
      ⟨(τ s).castPred hτs, by simp⟩
    have hM1 : ∀ i j, M1 i j = M (τ i) (τ j) := by
      intro i j; simp [M1, τ, Equiv.symm_swap]
    have hlast : τ (Fin.last (n+1)) = z := by simp [τ]
    have hτs' : τ s0.castSucc = s := by rw [← hs0]; simp [τ]
    have hrow : ∀ t : Fin (n+1), t ≠ s0 → M1 (Fin.last _) t.castSucc = 0 := by
      intro t ht
      rw [hM1, hlast]
      apply hleaf
      · intro h
        have : t.castSucc = Fin.last (n+1) := by
          have := congrArg τ h; simpa [τ] using this
        exact Fin.castSucc_ne_last _ this
      · intro h
        apply ht
        rw [← hτs'] at h
        exact Fin.castSucc_inj.1 (τ.injective h)
    have hcol : ∀ t : Fin (n+1), t ≠ s0 → M1 t.castSucc (Fin.last _) = 0 := fun t ht =>
      (h1.zero_comm _ _).2 (hrow t ht)
    have hne : M1 (Fin.last _) s0.castSucc ≠ 0 := by rw [hM1, hlast, hτs']; exact hzs
    have hpq := dyn_pq h1 s0.castSucc (Fin.last _) (Fin.castSucc_ne_last _)
      ((h1.zero_comm _ _).not.2 hne)
    have hd : M1 (Fin.last _) (Fin.last _) = 2 := h1.diag _
    have hM2 := dyn_isFiniteCartan_submatrix h1 Fin.castSucc (Fin.castSucc_injective _)
    have hc2 := dyn_conn_remove_leaf h1 hc1 s0 hrow
    have key : ∀ {k : ℕ} (e : Fin (n+1) ≃ Fin k) (X : Matrix (Fin k) (Fin k) ℤ),
        (M1.submatrix Fin.castSucc Fin.castSucc).reindex e e = X →
        (∀ s, s < k → (dmk X s (M1 s0.castSucc (Fin.last _)) (M1 (Fin.last _) s0.castSucc)).IsFiniteCartan →
          DL (dmk X s (M1 s0.castSucc (Fin.last _)) (M1 (Fin.last _) s0.castSucc))) → DL M1 := by
      intro k e X hX hext
      apply dyn_DL_of_reindex (dext e)
      have := dyn_reindex_dmk M1 e s0 hd hrow hcol
      rw [hX] at this
      rw [this]
      apply hext _ (e s0).isLt
      rw [← this]
      exact dyn_isFiniteCartan_reindex h1 _
    rcases ih _ hM2 hc2 with ⟨k, hk, e, he⟩ | ⟨k, hk, e, he⟩ | ⟨k, hk, e, he⟩ | ⟨k, hk, e, he⟩ |
      ⟨k, hk, e, he⟩ | ⟨e, he⟩ | ⟨e, he⟩
    · exact key e _ he fun s hs hN => dyn_ext_A k hk s hs _ _ hpq hN
    · exact key e _ he fun s hs hN => dyn_ext_B k hk s hs _ _ hpq hN
    · exact key e _ he fun s hs hN => dyn_ext_C k hk s hs _ _ hpq hN
    · exact key e _ he fun s hs hN => dyn_ext_D k hk s hs _ _ hpq hN
    · exact key e _ he fun s hs hN => dyn_ext_E k hk s hs _ _ hpq hN
    · exact key e _ he fun s hs hN => dyn_ext_F s hs _ _ hpq hN
    · exact key e _ he fun s hs hN => dyn_ext_G s hs _ _ hpq hN

lemma dyn_forward {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι] (M : Matrix ι ι ℤ)
    (hM : M.IsFiniteCartan) (hI : M.IsIndecomposable) : DL M := by
  obtain ⟨n, hn⟩ : ∃ n, Fintype.card ι = n + 1 :=
    Nat.exists_eq_succ_of_ne_zero Fintype.card_ne_zero
  let e : ι ≃ Fin (n+1) := (Fintype.equivFin ι).trans (finCongr hn)
  apply dyn_DL_of_reindex e
  refine dyn_main n _ (dyn_isFiniteCartan_reindex hM e) (dyn_conn_reindex ?_ e)
  exact (isIndecomposable_iff_reflTransGen M).1 hI

/-! ## Part R: the listed matrices are connected and of finite type -/

lemma dyn_Q_succ {n : ℕ} (S : Matrix (Fin (n+1)) (Fin (n+1)) ℤ) (x : Fin (n+1) → ℤ) :
    x ⬝ᵥ (S *ᵥ x) = (x ∘ Fin.castSucc) ⬝ᵥ (S.submatrix Fin.castSucc Fin.castSucc *ᵥ
      (x ∘ Fin.castSucc)) + (∑ i : Fin n, x i.castSucc * (S i.castSucc (Fin.last n) +
        S (Fin.last n) i.castSucc)) * x (Fin.last n) +
      S (Fin.last n) (Fin.last n) * x (Fin.last n) ^ 2 := by
  simp only [dotProduct, mulVec, Fin.sum_univ_castSucc, submatrix_apply, Function.comp_apply,
    mul_add, add_mul, Finset.sum_add_distrib, Finset.mul_sum, Finset.sum_mul]
  have h1 : ∑ i : Fin n, x (Fin.last n) * (S (Fin.last n) i.castSucc * x i.castSucc) =
      ∑ i : Fin n, x i.castSucc * S (Fin.last n) i.castSucc * x (Fin.last n) :=
    Finset.sum_congr rfl (fun i _ => by ring)
  have h2 : ∑ i : Fin n, x i.castSucc * (S i.castSucc (Fin.last n) * x (Fin.last n)) =
      ∑ i : Fin n, x i.castSucc * S i.castSucc (Fin.last n) * x (Fin.last n) :=
    Finset.sum_congr rfl (fun i _ => by ring)
  rw [h1, h2]; ring

lemma dyn_cross_sum {n : ℕ} (y : Fin (n+1) → ℤ) (c : ℤ) (f : Fin (n+1) → ℤ)
    (hf : ∀ i, f i = if i = Fin.last n then c else 0) : ∑ i, y i * f i = c * y (Fin.last n) := by
  simp only [hf, mul_ite, mul_zero, Finset.sum_ite_eq', Finset.mem_univ, if_true]
  ring

lemma dyn_ne_zero_split {n : ℕ} {x : Fin (n+1) → ℤ} (hx : x ≠ 0) (ht : x (Fin.last n) = 0) :
    x ∘ Fin.castSucc ≠ 0 := by
  intro h
  apply hx
  funext i
  induction i using Fin.lastCases with
  | last => exact ht
  | cast i => exact congrFun h i

lemma dyn_A_sub (n : ℕ) : (A (n+1)).submatrix Fin.castSucc Fin.castSucc = A n := by
  ext i j; simp [A]

lemma dyn_A_inv (n : ℕ) : ∀ x : Fin (n+1) → ℤ,
    ((n:ℤ)+2) * x (Fin.last n) ^ 2 ≤ ((n:ℤ)+1) * (x ⬝ᵥ (A (n+1) *ᵥ x)) ∧
      (x ≠ 0 → 0 < x ⬝ᵥ (A (n+1) *ᵥ x)) := by
  induction n with
  | zero =>
    intro x
    have hQ : x ⬝ᵥ (A 1 *ᵥ x) = 2 * x 0 ^ 2 := by
      simp [dotProduct, mulVec, A]; ring
    have hl : (Fin.last 0) = 0 := rfl
    rw [hQ, hl]
    refine ⟨by push_cast; nlinarith, fun hx => ?_⟩
    have : x 0 ≠ 0 := fun h => hx (funext fun i => by fin_cases i; exact h)
    positivity
  | succ n ih =>
    intro x
    obtain ⟨h1, h2⟩ := ih (x ∘ Fin.castSucc)
    have hc : ∀ i : Fin (n+1), A (n+2) i.castSucc (Fin.last (n+1)) +
        A (n+2) (Fin.last (n+1)) i.castSucc = if i = Fin.last n then -2 else 0 := by
      intro i
      simp only [A, of_apply, Fin.ext_iff, Fin.val_castSucc, Fin.val_last]
      split_ifs <;> omega
    have hQ : x ⬝ᵥ (A (n+2) *ᵥ x) = (x ∘ Fin.castSucc) ⬝ᵥ (A (n+1) *ᵥ (x ∘ Fin.castSucc)) -
        2 * x (Fin.last n).castSucc * x (Fin.last (n+1)) + 2 * x (Fin.last (n+1)) ^ 2 := by
      rw [dyn_Q_succ, dyn_A_sub, dyn_cross_sum _ (-2) _ hc]
      simp [A]; ring
    rw [hQ]
    set a := x (Fin.last n).castSucc
    set t := x (Fin.last (n+1))
    set Q := (x ∘ Fin.castSucc) ⬝ᵥ (A (n+1) *ᵥ (x ∘ Fin.castSucc))
    have ha : (x ∘ Fin.castSucc) (Fin.last n) = a := rfl
    rw [ha] at h1
    have hn : (0:ℤ) ≤ n := by positivity
    have key : ((n:ℤ)+3) * t ^ 2 ≤ ((n:ℤ)+2) * (Q - 2 * a * t + 2 * t ^ 2) := by
      nlinarith [sq_nonneg (((n:ℤ)+2) * a - ((n:ℤ)+1) * t)]
    refine ⟨by push_cast; linarith, fun hx => ?_⟩
    by_cases ht : t = 0
    · have := h2 (dyn_ne_zero_split hx ht)
      rw [ht]; linarith
    · have : 0 < t ^ 2 := by positivity
      nlinarith

/-- Positive-definiteness from the quadratic form, for a path with one end edge changed. -/
lemma dyn_pd_path_end (n : ℕ) (S : Matrix (Fin (n+2)) (Fin (n+2)) ℤ) (α β γ : ℤ)
    (hS : S.IsHermitian) (hsub : S.submatrix Fin.castSucc Fin.castSucc = α • A (n+1))
    (hcross : ∀ i : Fin (n+1), S i.castSucc (Fin.last (n+1)) + S (Fin.last (n+1)) i.castSucc =
      if i = Fin.last n then β else 0)
    (hll : S (Fin.last (n+1)) (Fin.last (n+1)) = γ) (hα : 0 < α)
    (hpos : ∀ a t Q : ℤ, ((n:ℤ)+2) * a ^ 2 ≤ ((n:ℤ)+1) * Q → t ≠ 0 →
      0 < α * Q + β * a * t + γ * t ^ 2) : S.PosDef := by
  rw [posDef_iff_dotProduct_mulVec]
  refine ⟨hS, fun x hx => ?_⟩
  rw [star_trivial, dyn_Q_succ, hsub, dyn_cross_sum _ β _ hcross, hll, smul_mulVec,
    dotProduct_smul, smul_eq_mul]
  obtain ⟨h1, h2⟩ := dyn_A_inv n (x ∘ Fin.castSucc)
  by_cases ht : x (Fin.last (n+1)) = 0
  · rw [ht]
    have := h2 (dyn_ne_zero_split hx ht)
    simp only [mul_zero, add_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true,
      zero_pow]
    positivity
  · have := hpos _ _ _ h1 ht
    simp only [Function.comp_apply] at this ⊢
    linarith

lemma dyn_B_pd (n : ℕ) :
    (diagonal (fun i : Fin (n+2) => if i = Fin.last (n+1) then (2:ℤ) else 1) * B (n+2)).PosDef := by
  apply dyn_pd_path_end n _ 1 (-4) 4
  · ext i j
    simp only [conjTranspose_apply, star_trivial, diagonal_mul, B, of_apply, Fin.ext_iff,
      Fin.val_last]
    split_ifs <;> omega
  · ext i j
    simp only [submatrix_apply, diagonal_mul, B, A, of_apply, one_smul, Fin.ext_iff,
      Fin.val_castSucc, Fin.val_last]
    split_ifs <;> omega
  · intro i
    simp only [diagonal_mul, B, of_apply, Fin.ext_iff, Fin.val_castSucc, Fin.val_last]
    split_ifs <;> omega
  · simp [diagonal_mul, B]
  · norm_num
  · intro a t Q h ht
    have : 0 < t ^ 2 := by positivity
    have hn : (0:ℤ) ≤ n := by positivity
    have h' := mul_le_mul_of_nonneg_left h (by positivity : (0:ℤ) ≤ (n:ℤ) + 2)
    have key : (((n:ℤ)+1) * ((n:ℤ)+2)) * (1 * Q + -4 * a * t + 4 * t ^ 2) ≥
        (((n:ℤ)+2) * a - 2 * ((n:ℤ)+1) * t) ^ 2 + 4 * ((n:ℤ)+1) * t ^ 2 := by
      nlinarith
    have hpos : 0 < (((n:ℤ)+2) * a - 2 * ((n:ℤ)+1) * t) ^ 2 + 4 * ((n:ℤ)+1) * t ^ 2 := by
      positivity
    exact pos_of_mul_pos_right (lt_of_lt_of_le hpos key) (by positivity)

lemma dyn_C_pd (n : ℕ) :
    (diagonal (fun i : Fin (n+2) => if i = Fin.last (n+1) then (1:ℤ) else 2) * C (n+2)).PosDef := by
  apply dyn_pd_path_end n _ 2 (-4) 2
  · ext i j
    simp only [conjTranspose_apply, star_trivial, diagonal_mul, C, of_apply, Fin.ext_iff,
      Fin.val_last]
    split_ifs <;> omega
  · ext i j
    simp only [submatrix_apply, diagonal_mul, C, A, Matrix.smul_apply, of_apply, smul_eq_mul, Fin.ext_iff,
      Fin.val_castSucc, Fin.val_last]
    split_ifs <;> omega
  · intro i
    simp only [diagonal_mul, C, of_apply, Fin.ext_iff, Fin.val_castSucc, Fin.val_last]
    split_ifs <;> omega
  · simp [diagonal_mul, C]
  · norm_num
  · intro a t Q h ht
    have : 0 < t ^ 2 := by positivity
    have hn : (0:ℤ) ≤ n := by positivity
    have h' := mul_le_mul_of_nonneg_left h (by positivity : (0:ℤ) ≤ (n:ℤ) + 2)
    have key : (((n:ℤ)+1) * ((n:ℤ)+2)) * (2 * Q + -4 * a * t + 2 * t ^ 2) ≥
        2 * (((n:ℤ)+2) * a - ((n:ℤ)+1) * t) ^ 2 + 2 * ((n:ℤ)+1) * t ^ 2 := by
      nlinarith
    have hpos : 0 < 2 * (((n:ℤ)+2) * a - ((n:ℤ)+1) * t) ^ 2 + 2 * ((n:ℤ)+1) * t ^ 2 := by
      positivity
    exact pos_of_mul_pos_right (lt_of_lt_of_le hpos key) (by positivity)

lemma dyn_A_Q_succ (n : ℕ) (x : Fin (n+2) → ℤ) : x ⬝ᵥ (A (n+2) *ᵥ x) =
    (x ∘ Fin.castSucc) ⬝ᵥ (A (n+1) *ᵥ (x ∘ Fin.castSucc)) -
      2 * x (Fin.last n).castSucc * x (Fin.last (n+1)) + 2 * x (Fin.last (n+1)) ^ 2 := by
  have hc : ∀ i : Fin (n+1), A (n+2) i.castSucc (Fin.last (n+1)) +
      A (n+2) (Fin.last (n+1)) i.castSucc = if i = Fin.last n then -2 else 0 := by
    intro i
    simp only [A, of_apply, Fin.ext_iff, Fin.val_castSucc, Fin.val_last]
    split_ifs <;> omega
  rw [dyn_Q_succ, dyn_A_sub, dyn_cross_sum _ (-2) _ hc]
  simp [A]; ring

lemma dyn_D_pd (n : ℕ) : (D (n+4)).PosDef := by
  rw [posDef_iff_dotProduct_mulVec]
  refine ⟨?_, fun x hx => ?_⟩
  · ext i j
    simp only [conjTranspose_apply, star_trivial]
    exact congrFun (congrFun (D_transpose (n+4)) i) j
  have hsub : (D (n+4)).submatrix Fin.castSucc Fin.castSucc = A (n+3) := by
    ext i j
    simp only [submatrix_apply, D, A, of_apply, Fin.ext_iff, Fin.val_castSucc]
    split_ifs <;> omega
  have hc : ∀ i : Fin (n+3), D (n+4) i.castSucc (Fin.last (n+3)) +
      D (n+4) (Fin.last (n+3)) i.castSucc =
        if i = (Fin.last (n+1)).castSucc then -2 else 0 := by
    intro i
    simp only [D, of_apply, Fin.ext_iff, Fin.val_castSucc, Fin.val_last, or_true, true_or,
      and_true, true_and]
    split_ifs <;> omega
  have hcs : ∀ (y : Fin (n+3) → ℤ), ∑ i, y i * (if i = (Fin.last (n+1)).castSucc then -2 else 0) =
      -2 * y (Fin.last (n+1)).castSucc := by
    intro y
    simp only [mul_ite, mul_zero, Finset.sum_ite_eq', Finset.mem_univ, if_true]; ring
  rw [star_trivial, dyn_Q_succ, hsub]
  simp only [hc, hcs]
  rw [dyn_A_Q_succ (n+1)]
  have hll : D (n+4) (Fin.last (n+3)) (Fin.last (n+3)) = 2 := by simp [D]
  rw [hll]
  obtain ⟨h1, h2⟩ := dyn_A_inv (n+1) ((x ∘ Fin.castSucc) ∘ Fin.castSucc)
  simp only [Function.comp_apply] at h1 h2 ⊢
  set b := x (Fin.last (n+1)).castSucc.castSucc
  set c := x (Fin.last (n+2)).castSucc
  set t := x (Fin.last (n+3))
  set Q := ((x ∘ Fin.castSucc) ∘ Fin.castSucc) ⬝ᵥ (A (n+2) *ᵥ ((x ∘ Fin.castSucc) ∘ Fin.castSucc))
  have hn : (0:ℤ) ≤ n := by positivity
  by_cases hct : c = 0 ∧ t = 0
  · obtain ⟨hc0, ht0⟩ := hct
    have hy : (x ∘ Fin.castSucc) ∘ Fin.castSucc ≠ 0 := by
      apply dyn_ne_zero_split (dyn_ne_zero_split hx ht0)
      exact hc0
    have := h2 hy
    rw [hc0, ht0]; push_cast at this ⊢; linarith
  · have hpos : 0 < c ^ 2 + t ^ 2 := by
      rcases not_and_or.1 hct with h | h
      · have : 0 < c ^ 2 := by positivity
        positivity
      · have : 0 < t ^ 2 := by positivity
        positivity
    have h' := mul_le_mul_of_nonneg_left h1 (by positivity : (0:ℤ) ≤ (n:ℤ) + 1 + 2)
    have key : ((((n:ℤ)+2)) * ((n:ℤ)+3)) * (Q - 2 * b * c + 2 * c ^ 2 + -2 * b * t + 2 * t ^ 2) ≥
        (((n:ℤ)+3) * b - ((n:ℤ)+2) * (c + t)) ^ 2 + ((n:ℤ)+2) ^ 2 * (c - t) ^ 2 +
          2 * ((n:ℤ)+2) * (c ^ 2 + t ^ 2) := by
      push_cast at h'
      nlinarith
    have hp2 : 0 < (((n:ℤ)+3) * b - ((n:ℤ)+2) * (c + t)) ^ 2 + ((n:ℤ)+2) ^ 2 * (c - t) ^ 2 +
          2 * ((n:ℤ)+2) * (c ^ 2 + t ^ 2) := by positivity
    have := pos_of_mul_pos_right (lt_of_lt_of_le hp2 key) (by positivity)
    linarith

lemma dyn_E6_pd : (E 6).PosDef := by
  rw [posDef_iff_dotProduct_mulVec]
  refine ⟨by decide, fun x hx => ?_⟩
  have hQ : star x ⬝ᵥ ((E 6) *ᵥ x) = x 0 * (2 * x 0) + x 0 * (-1 * x 2) + x 1 * (2 * x 1) + x 1 * (-1 * x 3) + x 2 * (-1 * x 0) + x 2 * (2 * x 2) + x 2 * (-1 * x 3) + x 3 * (-1 * x 1) + x 3 * (-1 * x 2) + x 3 * (2 * x 3) + x 3 * (-1 * x 4) + x 4 * (-1 * x 3) + x 4 * (2 * x 4) + x 4 * (-1 * x 5) + x 5 * (-1 * x 4) + x 5 * (2 * x 5) := by
    simp [dotProduct, mulVec, Fin.sum_univ_succ, diagonal_mul, E]
    ring
  rw [hQ]
  have key : 60 * (x 0 * (2 * x 0) + x 0 * (-1 * x 2) + x 1 * (2 * x 1) + x 1 * (-1 * x 3) + x 2 * (-1 * x 0) + x 2 * (2 * x 2) + x 2 * (-1 * x 3) + x 3 * (-1 * x 1) + x 3 * (-1 * x 2) + x 3 * (2 * x 3) + x 3 * (-1 * x 4) + x 4 * (-1 * x 3) + x 4 * (2 * x 4) + x 4 * (-1 * x 5) + x 5 * (-1 * x 4) + x 5 * (2 * x 5)) = 30 * (2 * x 0 + -1 * x 2) ^ 2 + 30 * (2 * x 1 + -1 * x 3) ^ 2 + 10 * (3 * x 2 + -2 * x 3) ^ 2 + 2 * (5 * x 3 + -6 * x 4) ^ 2 + 3 * (4 * x 4 + -5 * x 5) ^ 2 + 45 * (x 5) ^ 2 := by ring
  by_contra hle
  push Not at hle
  have e0 : (2 * x 0 + -1 * x 2) = 0 := by
    have : (2 * x 0 + -1 * x 2) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (x 5)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e1 : (2 * x 1 + -1 * x 3) = 0 := by
    have : (2 * x 1 + -1 * x 3) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (x 5)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e2 : (3 * x 2 + -2 * x 3) = 0 := by
    have : (3 * x 2 + -2 * x 3) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (x 5)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e3 : (5 * x 3 + -6 * x 4) = 0 := by
    have : (5 * x 3 + -6 * x 4) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (x 5)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e4 : (4 * x 4 + -5 * x 5) = 0 := by
    have : (4 * x 4 + -5 * x 5) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (x 5)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e5 : (x 5) = 0 := by
    have : (x 5) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (x 5)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have z0 : x 0 = 0 := by omega
  have z1 : x 1 = 0 := by omega
  have z2 : x 2 = 0 := by omega
  have z3 : x 3 = 0 := by omega
  have z4 : x 4 = 0 := by omega
  have z5 : x 5 = 0 := by omega
  apply hx
  funext i
  fin_cases i <;> first | exact z0 | exact z1 | exact z2 | exact z3 | exact z4 | exact z5

lemma dyn_E7_pd : (E 7).PosDef := by
  rw [posDef_iff_dotProduct_mulVec]
  refine ⟨by decide, fun x hx => ?_⟩
  have hQ : star x ⬝ᵥ ((E 7) *ᵥ x) = x 0 * (2 * x 0) + x 0 * (-1 * x 2) + x 1 * (2 * x 1) + x 1 * (-1 * x 3) + x 2 * (-1 * x 0) + x 2 * (2 * x 2) + x 2 * (-1 * x 3) + x 3 * (-1 * x 1) + x 3 * (-1 * x 2) + x 3 * (2 * x 3) + x 3 * (-1 * x 4) + x 4 * (-1 * x 3) + x 4 * (2 * x 4) + x 4 * (-1 * x 5) + x 5 * (-1 * x 4) + x 5 * (2 * x 5) + x 5 * (-1 * x 6) + x 6 * (-1 * x 5) + x 6 * (2 * x 6) := by
    simp [dotProduct, mulVec, Fin.sum_univ_succ, diagonal_mul, E]
    ring
  rw [hQ]
  have key : 60 * (x 0 * (2 * x 0) + x 0 * (-1 * x 2) + x 1 * (2 * x 1) + x 1 * (-1 * x 3) + x 2 * (-1 * x 0) + x 2 * (2 * x 2) + x 2 * (-1 * x 3) + x 3 * (-1 * x 1) + x 3 * (-1 * x 2) + x 3 * (2 * x 3) + x 3 * (-1 * x 4) + x 4 * (-1 * x 3) + x 4 * (2 * x 4) + x 4 * (-1 * x 5) + x 5 * (-1 * x 4) + x 5 * (2 * x 5) + x 5 * (-1 * x 6) + x 6 * (-1 * x 5) + x 6 * (2 * x 6)) = 30 * (2 * x 0 + -1 * x 2) ^ 2 + 30 * (2 * x 1 + -1 * x 3) ^ 2 + 10 * (3 * x 2 + -2 * x 3) ^ 2 + 2 * (5 * x 3 + -6 * x 4) ^ 2 + 3 * (4 * x 4 + -5 * x 5) ^ 2 + 5 * (3 * x 5 + -4 * x 6) ^ 2 + 40 * (x 6) ^ 2 := by ring
  by_contra hle
  push Not at hle
  have e0 : (2 * x 0 + -1 * x 2) = 0 := by
    have : (2 * x 0 + -1 * x 2) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (x 6)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e1 : (2 * x 1 + -1 * x 3) = 0 := by
    have : (2 * x 1 + -1 * x 3) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (x 6)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e2 : (3 * x 2 + -2 * x 3) = 0 := by
    have : (3 * x 2 + -2 * x 3) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (x 6)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e3 : (5 * x 3 + -6 * x 4) = 0 := by
    have : (5 * x 3 + -6 * x 4) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (x 6)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e4 : (4 * x 4 + -5 * x 5) = 0 := by
    have : (4 * x 4 + -5 * x 5) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (x 6)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e5 : (3 * x 5 + -4 * x 6) = 0 := by
    have : (3 * x 5 + -4 * x 6) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (x 6)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e6 : (x 6) = 0 := by
    have : (x 6) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (x 6)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have z0 : x 0 = 0 := by omega
  have z1 : x 1 = 0 := by omega
  have z2 : x 2 = 0 := by omega
  have z3 : x 3 = 0 := by omega
  have z4 : x 4 = 0 := by omega
  have z5 : x 5 = 0 := by omega
  have z6 : x 6 = 0 := by omega
  apply hx
  funext i
  fin_cases i <;> first | exact z0 | exact z1 | exact z2 | exact z3 | exact z4 | exact z5 | exact z6

lemma dyn_E8_pd : (E 8).PosDef := by
  rw [posDef_iff_dotProduct_mulVec]
  refine ⟨by decide, fun x hx => ?_⟩
  have hQ : star x ⬝ᵥ ((E 8) *ᵥ x) = x 0 * (2 * x 0) + x 0 * (-1 * x 2) + x 1 * (2 * x 1) + x 1 * (-1 * x 3) + x 2 * (-1 * x 0) + x 2 * (2 * x 2) + x 2 * (-1 * x 3) + x 3 * (-1 * x 1) + x 3 * (-1 * x 2) + x 3 * (2 * x 3) + x 3 * (-1 * x 4) + x 4 * (-1 * x 3) + x 4 * (2 * x 4) + x 4 * (-1 * x 5) + x 5 * (-1 * x 4) + x 5 * (2 * x 5) + x 5 * (-1 * x 6) + x 6 * (-1 * x 5) + x 6 * (2 * x 6) + x 6 * (-1 * x 7) + x 7 * (-1 * x 6) + x 7 * (2 * x 7) := by
    simp [dotProduct, mulVec, Fin.sum_univ_succ, diagonal_mul, E]
    ring
  rw [hQ]
  have key : 60 * (x 0 * (2 * x 0) + x 0 * (-1 * x 2) + x 1 * (2 * x 1) + x 1 * (-1 * x 3) + x 2 * (-1 * x 0) + x 2 * (2 * x 2) + x 2 * (-1 * x 3) + x 3 * (-1 * x 1) + x 3 * (-1 * x 2) + x 3 * (2 * x 3) + x 3 * (-1 * x 4) + x 4 * (-1 * x 3) + x 4 * (2 * x 4) + x 4 * (-1 * x 5) + x 5 * (-1 * x 4) + x 5 * (2 * x 5) + x 5 * (-1 * x 6) + x 6 * (-1 * x 5) + x 6 * (2 * x 6) + x 6 * (-1 * x 7) + x 7 * (-1 * x 6) + x 7 * (2 * x 7)) = 30 * (2 * x 0 + -1 * x 2) ^ 2 + 30 * (2 * x 1 + -1 * x 3) ^ 2 + 10 * (3 * x 2 + -2 * x 3) ^ 2 + 2 * (5 * x 3 + -6 * x 4) ^ 2 + 3 * (4 * x 4 + -5 * x 5) ^ 2 + 5 * (3 * x 5 + -4 * x 6) ^ 2 + 10 * (2 * x 6 + -3 * x 7) ^ 2 + 30 * (x 7) ^ 2 := by ring
  by_contra hle
  push Not at hle
  have e0 : (2 * x 0 + -1 * x 2) = 0 := by
    have : (2 * x 0 + -1 * x 2) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (2 * x 6 + -3 * x 7), sq_nonneg (x 7)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e1 : (2 * x 1 + -1 * x 3) = 0 := by
    have : (2 * x 1 + -1 * x 3) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (2 * x 6 + -3 * x 7), sq_nonneg (x 7)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e2 : (3 * x 2 + -2 * x 3) = 0 := by
    have : (3 * x 2 + -2 * x 3) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (2 * x 6 + -3 * x 7), sq_nonneg (x 7)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e3 : (5 * x 3 + -6 * x 4) = 0 := by
    have : (5 * x 3 + -6 * x 4) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (2 * x 6 + -3 * x 7), sq_nonneg (x 7)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e4 : (4 * x 4 + -5 * x 5) = 0 := by
    have : (4 * x 4 + -5 * x 5) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (2 * x 6 + -3 * x 7), sq_nonneg (x 7)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e5 : (3 * x 5 + -4 * x 6) = 0 := by
    have : (3 * x 5 + -4 * x 6) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (2 * x 6 + -3 * x 7), sq_nonneg (x 7)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e6 : (2 * x 6 + -3 * x 7) = 0 := by
    have : (2 * x 6 + -3 * x 7) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (2 * x 6 + -3 * x 7), sq_nonneg (x 7)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e7 : (x 7) = 0 := by
    have : (x 7) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 2), sq_nonneg (2 * x 1 + -1 * x 3), sq_nonneg (3 * x 2 + -2 * x 3), sq_nonneg (5 * x 3 + -6 * x 4), sq_nonneg (4 * x 4 + -5 * x 5), sq_nonneg (3 * x 5 + -4 * x 6), sq_nonneg (2 * x 6 + -3 * x 7), sq_nonneg (x 7)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have z0 : x 0 = 0 := by omega
  have z1 : x 1 = 0 := by omega
  have z2 : x 2 = 0 := by omega
  have z3 : x 3 = 0 := by omega
  have z4 : x 4 = 0 := by omega
  have z5 : x 5 = 0 := by omega
  have z6 : x 6 = 0 := by omega
  have z7 : x 7 = 0 := by omega
  apply hx
  funext i
  fin_cases i <;> first | exact z0 | exact z1 | exact z2 | exact z3 | exact z4 | exact z5 | exact z6 | exact z7

lemma dyn_F4_pd : (diagonal ![1, 1, 2, 2] * F₄).PosDef := by
  rw [posDef_iff_dotProduct_mulVec]
  refine ⟨by decide, fun x hx => ?_⟩
  have hQ : star x ⬝ᵥ ((diagonal ![1, 1, 2, 2] * F₄) *ᵥ x) = x 0 * (2 * x 0) + x 0 * (-1 * x 1) + x 1 * (-1 * x 0) + x 1 * (2 * x 1) + x 1 * (-2 * x 2) + x 2 * (-2 * x 1) + x 2 * (4 * x 2) + x 2 * (-2 * x 3) + x 3 * (-2 * x 2) + x 3 * (4 * x 3) := by
    simp [dotProduct, mulVec, Fin.sum_univ_succ, diagonal_mul, F₄]
    ring
  rw [hQ]
  have key : 6 * (x 0 * (2 * x 0) + x 0 * (-1 * x 1) + x 1 * (-1 * x 0) + x 1 * (2 * x 1) + x 1 * (-2 * x 2) + x 2 * (-2 * x 1) + x 2 * (4 * x 2) + x 2 * (-2 * x 3) + x 3 * (-2 * x 2) + x 3 * (4 * x 3)) = 3 * (2 * x 0 + -1 * x 1) ^ 2 + 1 * (3 * x 1 + -4 * x 2) ^ 2 + 2 * (2 * x 2 + -3 * x 3) ^ 2 + 6 * (x 3) ^ 2 := by ring
  by_contra hle
  push Not at hle
  have e0 : (2 * x 0 + -1 * x 1) = 0 := by
    have : (2 * x 0 + -1 * x 1) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 1), sq_nonneg (3 * x 1 + -4 * x 2), sq_nonneg (2 * x 2 + -3 * x 3), sq_nonneg (x 3)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e1 : (3 * x 1 + -4 * x 2) = 0 := by
    have : (3 * x 1 + -4 * x 2) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 1), sq_nonneg (3 * x 1 + -4 * x 2), sq_nonneg (2 * x 2 + -3 * x 3), sq_nonneg (x 3)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e2 : (2 * x 2 + -3 * x 3) = 0 := by
    have : (2 * x 2 + -3 * x 3) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 1), sq_nonneg (3 * x 1 + -4 * x 2), sq_nonneg (2 * x 2 + -3 * x 3), sq_nonneg (x 3)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e3 : (x 3) = 0 := by
    have : (x 3) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -1 * x 1), sq_nonneg (3 * x 1 + -4 * x 2), sq_nonneg (2 * x 2 + -3 * x 3), sq_nonneg (x 3)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have z0 : x 0 = 0 := by omega
  have z1 : x 1 = 0 := by omega
  have z2 : x 2 = 0 := by omega
  have z3 : x 3 = 0 := by omega
  apply hx
  funext i
  fin_cases i <;> first | exact z0 | exact z1 | exact z2 | exact z3

lemma dyn_G2_pd : (diagonal ![1, 3] * G₂).PosDef := by
  rw [posDef_iff_dotProduct_mulVec]
  refine ⟨by decide, fun x hx => ?_⟩
  have hQ : star x ⬝ᵥ ((diagonal ![1, 3] * G₂) *ᵥ x) = x 0 * (2 * x 0) + x 0 * (-3 * x 1) + x 1 * (-3 * x 0) + x 1 * (6 * x 1) := by
    simp [dotProduct, mulVec, Fin.sum_univ_succ, diagonal_mul, G₂]
    ring
  rw [hQ]
  have key : 2 * (x 0 * (2 * x 0) + x 0 * (-3 * x 1) + x 1 * (-3 * x 0) + x 1 * (6 * x 1)) = 1 * (2 * x 0 + -3 * x 1) ^ 2 + 3 * (x 1) ^ 2 := by ring
  by_contra hle
  push Not at hle
  have e0 : (2 * x 0 + -3 * x 1) = 0 := by
    have : (2 * x 0 + -3 * x 1) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -3 * x 1), sq_nonneg (x 1)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have e1 : (x 1) = 0 := by
    have : (x 1) ^ 2 ≤ 0 := by linarith [sq_nonneg (2 * x 0 + -3 * x 1), sq_nonneg (x 1)]
    exact pow_eq_zero_iff (two_ne_zero) |>.1 (le_antisymm this (sq_nonneg _))
  have z0 : x 0 = 0 := by omega
  have z1 : x 1 = 0 := by omega
  apply hx
  funext i
  fin_cases i <;> first | exact z0 | exact z1

/-! ## Part T: every listed matrix is connected and of finite type -/

lemma dyn_conn_of {n : ℕ} (M : Matrix (Fin (n+1)) (Fin (n+1)) ℤ)
    (hsym : ∀ i j, M i j ≠ 0 → M j i ≠ 0)
    (hroot : ∀ i, Relation.ReflTransGen (fun i j => M i j ≠ 0) 0 i) : M.IsIndecomposable := by
  rw [isIndecomposable_iff_reflTransGen]
  intro i j
  have rev : ∀ a b, Relation.ReflTransGen (fun i j => M i j ≠ 0) a b →
      Relation.ReflTransGen (fun i j => M i j ≠ 0) b a := by
    intro a b h
    induction h with
    | refl => exact .refl
    | tail _ hbc ih => exact Relation.ReflTransGen.head (hsym _ _ hbc) ih
  exact (rev _ _ (hroot i)).trans (hroot j)

lemma dyn_path_reach {n : ℕ} (M : Matrix (Fin (n+1)) (Fin (n+1)) ℤ) (b : ℕ)
    (hstep : ∀ i : ℕ, (h : i + 1 ≤ b) → (hb : b < n + 1) →
      M ⟨i, by omega⟩ ⟨i+1, by omega⟩ ≠ 0) :
    ∀ m : ℕ, (hm : m ≤ b) → (hb : b < n + 1) →
      Relation.ReflTransGen (fun i j => M i j ≠ 0) 0 ⟨m, by omega⟩ := by
  intro m
  induction m with
  | zero => intro _ _; exact .refl
  | succ m ih =>
    intro hm hb
    exact (ih (by omega) hb).tail (hstep m hm hb)

lemma dyn_A_fin (n : ℕ) (hn : 1 ≤ n) : (A n).IsFiniteCartan ∧ (A n).IsIndecomposable := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  refine ⟨⟨fun i => by simp [A], fun i j h => A_apply_le_zero_of_ne _ i j h,
    fun i j => by
      rw [show A (m+1) j i = A (m+1) i j by
        simpa using congrFun (congrFun (A_transpose (m+1)) i) j], ⟨fun _ => 1, fun _ => one_pos, ?_⟩⟩, ?_⟩
  · rw [diagonal_one, one_mul, posDef_iff_dotProduct_mulVec]
    refine ⟨?_, fun x hx => by rw [star_trivial]; exact (dyn_A_inv m x).2 hx⟩
    ext i j; simp only [conjTranspose_apply, star_trivial]
    exact congrFun (congrFun (A_transpose (m+1)) i) j
  · apply dyn_conn_of
    · intro i j h; rwa [← A_transpose, transpose_apply] at h
    · intro i
      have := dyn_path_reach (A (m+1)) m (fun i h hb => by simp [A]) i.val (by omega) (by omega)
      simpa using this

lemma dyn_B_fin (n : ℕ) (hn : 2 ≤ n) : (B n).IsFiniteCartan ∧ (B n).IsIndecomposable := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
  refine ⟨⟨fun i => by simp, fun i j h => B_off_diag_nonpos _ i j h,
    fun i j => ?_, ⟨_, fun i => ?_, dyn_B_pd m⟩⟩, ?_⟩
  · simp only [B, of_apply, Fin.ext_iff]; split_ifs <;> (try simp) <;> omega
  · split_ifs <;> norm_num
  · apply dyn_conn_of
    · intro i j; simp only [B, of_apply, Fin.ext_iff]; split_ifs <;> (try simp) <;> omega
    · intro i
      have := dyn_path_reach (B (m+2)) (m+1) (fun i h hb => by
        simp only [B, of_apply, Fin.mk.injEq]; split_ifs <;> omega) i.val (by omega) (by omega)
      simpa using this

lemma dyn_C_fin (n : ℕ) (hn : 2 ≤ n) : (C n).IsFiniteCartan ∧ (C n).IsIndecomposable := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
  refine ⟨⟨fun i => by simp, fun i j h => C_off_diag_nonpos _ i j h,
    fun i j => ?_, ⟨_, fun i => ?_, dyn_C_pd m⟩⟩, ?_⟩
  · simp only [C, of_apply, Fin.ext_iff]; split_ifs <;> (try simp) <;> omega
  · split_ifs <;> norm_num
  · apply dyn_conn_of
    · intro i j; simp only [C, of_apply, Fin.ext_iff]; split_ifs <;> (try simp) <;> omega
    · intro i
      have := dyn_path_reach (C (m+2)) (m+1) (fun i h hb => by
        simp only [C, of_apply, Fin.mk.injEq]; split_ifs <;> omega) i.val (by omega) (by omega)
      simpa using this

lemma dyn_D_fin (n : ℕ) (hn : 4 ≤ n) : (D n).IsFiniteCartan ∧ (D n).IsIndecomposable := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 4 := ⟨n - 4, by omega⟩
  refine ⟨⟨fun i => by simp, fun i j h => D_off_diag_nonpos _ i j h,
    fun i j => by
      rw [show D (m+4) j i = D (m+4) i j by
        simpa using congrFun (congrFun (D_transpose (m+4)) i) j], ⟨fun _ => 1, fun _ => one_pos, ?_⟩⟩, ?_⟩
  · rw [diagonal_one, one_mul]; exact dyn_D_pd m
  · apply dyn_conn_of
    · intro i j h; rwa [← D_transpose, transpose_apply] at h
    · intro i
      have hp := dyn_path_reach (D (m+4)) (m+1) (fun i h hb => by
        simp only [D, of_apply, Fin.mk.injEq, or_true, true_or, and_true, true_and]
        split_ifs <;> omega)
      rcases Nat.lt_or_ge i.val (m+2) with hi | hi
      · simpa using hp i.val (by omega) (by omega)
      · have h1 := hp (m+1) le_rfl (by omega)
        refine h1.tail ?_
        simp only [D, of_apply, Fin.ext_iff, Fin.val_mk, or_true, true_or, and_true, true_and]
        split_ifs <;> omega

lemma dyn_E_fin (n : ℕ) (hn : n = 6 ∨ n = 7 ∨ n = 8) :
    (E n).IsFiniteCartan ∧ (E n).IsIndecomposable := by
  have key : ∀ n, (E n).PosDef → (E n).IsIndecomposable →
      (E n).IsFiniteCartan ∧ (E n).IsIndecomposable := fun n hpd hI =>
    ⟨⟨fun i => by simp, fun i j h => E_off_diag_nonpos _ i j h,
      fun i j => by
        rw [show E n j i = E n i j by simpa using congrFun (congrFun (E_transpose n) i) j],
      ⟨fun _ => 1, fun _ => one_pos, by rw [diagonal_one, one_mul]; exact hpd⟩⟩, hI⟩
  rcases hn with rfl | rfl | rfl
  · exact key 6 dyn_E6_pd isIndecomposable_E_six
  · exact key 7 dyn_E7_pd isIndecomposable_E_seven
  · exact key 8 dyn_E8_pd isIndecomposable_E_eight

lemma dyn_F_fin : F₄.IsFiniteCartan ∧ F₄.IsIndecomposable :=
  ⟨⟨fun i => by simp, fun i j h => F₄_off_diag_nonpos i j h,
    by intro i j; fin_cases i <;> fin_cases j <;> decide,
    ⟨![1, 1, 2, 2], by decide, dyn_F4_pd⟩⟩, isIndecomposable_F₄⟩

lemma dyn_G_fin : G₂.IsFiniteCartan ∧ G₂.IsIndecomposable :=
  ⟨⟨fun i => by simp, fun i j h => G₂_off_diag_nonpos i j h,
    by intro i j; fin_cases i <;> fin_cases j <;> decide,
    ⟨![1, 3], by decide, dyn_G2_pd⟩⟩, isIndecomposable_G₂⟩

lemma dyn_back {ι : Type*} [Fintype ι] [DecidableEq ι] {m : ℕ} (M : Matrix ι ι ℤ)
    (X : Matrix (Fin m) (Fin m) ℤ) (e : ι ≃ Fin m) (he : M.reindex e e = X)
    (hX : X.IsFiniteCartan ∧ X.IsIndecomposable) : M.IsFiniteCartan ∧ M.IsIndecomposable := by
  have hM : M = X.reindex e.symm e.symm := by rw [← he]; ext i j; simp
  rw [hM]
  refine ⟨dyn_isFiniteCartan_reindex hX.1 _, ?_⟩
  rw [isIndecomposable_iff_reflTransGen]
  exact dyn_conn_reindex ((isIndecomposable_iff_reflTransGen X).1 hX.2) _


/-- The classification of Dynkin diagrams. A whole-number Cartan matrix with a positive-definite
symmetrised form (`IsFiniteCartan`) whose diagram is connected (`IsIndecomposable`) is, after
renumbering its dots, the Cartan matrix of exactly one of the types on the list: `A n` (n ≥ 1),
`B n` (n ≥ 2), `C n` (n ≥ 2), `D n` (n ≥ 4), `E 6`, `E 7`, `E 8`, `F₄` or `G₂`; and every
matrix on that list is a connected positive-definite Cartan matrix. -/
theorem connected_positive_definite_cartan_matrix_iff_dynkin_list
    {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι] (M : Matrix ι ι ℤ) :
    (M.IsFiniteCartan ∧ M.IsIndecomposable) ↔
      (∃ n, 1 ≤ n ∧ ∃ e : ι ≃ Fin n, M.reindex e e = A n) ∨
      (∃ n, 2 ≤ n ∧ ∃ e : ι ≃ Fin n, M.reindex e e = B n) ∨
      (∃ n, 2 ≤ n ∧ ∃ e : ι ≃ Fin n, M.reindex e e = C n) ∨
      (∃ n, 4 ≤ n ∧ ∃ e : ι ≃ Fin n, M.reindex e e = D n) ∨
      (∃ n, (n = 6 ∨ n = 7 ∨ n = 8) ∧ ∃ e : ι ≃ Fin n, M.reindex e e = E n) ∨
      (∃ e : ι ≃ Fin 4, M.reindex e e = F₄) ∨
      (∃ e : ι ≃ Fin 2, M.reindex e e = G₂) := by
  constructor
  · rintro ⟨h1, h2⟩
    exact dyn_forward M h1 h2
  · rintro (⟨n, hn, e, he⟩ | ⟨n, hn, e, he⟩ | ⟨n, hn, e, he⟩ | ⟨n, hn, e, he⟩ | ⟨n, hn, e, he⟩ |
      ⟨e, he⟩ | ⟨e, he⟩)
    · exact dyn_back M _ e he (dyn_A_fin n hn)
    · exact dyn_back M _ e he (dyn_B_fin n hn)
    · exact dyn_back M _ e he (dyn_C_fin n hn)
    · exact dyn_back M _ e he (dyn_D_fin n hn)
    · exact dyn_back M _ e he (dyn_E_fin n hn)
    · exact dyn_back M _ e he dyn_F_fin
    · exact dyn_back M _ e he dyn_G_fin

/-- Step 0, only a handful of angles. For any two roots of a finite root system with whole-number
reflection numbers (R4), the product of the two reflection numbers, which is `4 cos² θ`, is one of
0, 1, 2, 3 or 4. -/
theorem reflection_number_product_mem_zero_to_four
    {ι M N : Type*} [AddCommGroup M] [Module ℝ M] [AddCommGroup N] [Module ℝ N]
    (P : RootPairing ι ℝ M N) [Finite ι] [P.IsCrystallographic] (i j : ι) :
    P.pairing i j * P.pairing j i ∈ ({0, 1, 2, 3, 4} : Set ℝ) := by
  have h := P.coxeterWeightIn_mem_set_of_isCrystallographic i j
  have e : P.pairing i j * P.pairing j i = ((P.coxeterWeightIn ℤ i j : ℤ) : ℝ) := by
    have := P.algebraMap_coxeterWeightIn ℤ i j
    rw [algebraMap_int_eq, eq_intCast] at this
    rw [this]; rfl
  rw [e]
  simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at h ⊢
  rcases h with h | h | h | h | h <;> simp [h]

/-- From roots to the list. Take a finite real root system obeying R1 to R4 (`IsRootSystem`,
`IsReduced`, `IsCrystallographic`) that is irreducible (it comes from a simple algebra, so its
diagram is connected), and any choice of simple roots `b`. Its Cartan matrix, after renumbering the
simple roots, is one of `A n`, `B n`, `C n`, `D n`, `E 6`, `E 7`, `E 8`, `F₄` or `G₂`. -/
theorem root_system_cartan_matrix_mem_dynkin_list
    {ι M N : Type*} [AddCommGroup M] [Module ℝ M] [AddCommGroup N] [Module ℝ N]
    (P : RootPairing ι ℝ M N) [Finite ι] [P.IsRootSystem] [P.IsCrystallographic]
    [P.IsReduced] [P.IsIrreducible] (b : P.Base) :
      (∃ n, 1 ≤ n ∧ ∃ e : b.support ≃ Fin n, b.cartanMatrix.reindex e e = A n) ∨
      (∃ n, 2 ≤ n ∧ ∃ e : b.support ≃ Fin n, b.cartanMatrix.reindex e e = B n) ∨
      (∃ n, 2 ≤ n ∧ ∃ e : b.support ≃ Fin n, b.cartanMatrix.reindex e e = C n) ∨
      (∃ n, 4 ≤ n ∧ ∃ e : b.support ≃ Fin n, b.cartanMatrix.reindex e e = D n) ∨
      (∃ n, (n = 6 ∨ n = 7 ∨ n = 8) ∧ ∃ e : b.support ≃ Fin n, b.cartanMatrix.reindex e e = E n) ∨
      (∃ e : b.support ≃ Fin 4, b.cartanMatrix.reindex e e = F₄) ∨
      (∃ e : b.support ≃ Fin 2, b.cartanMatrix.reindex e e = G₂) := by
  classical
  have : Nonempty ι := by
    by_contra h
    rw [not_nonempty_iff] at h
    have := RootPairing.IsIrreducible.nontrivial P
    have h2 := RootPairing.IsRootSystem.span_root_eq_top (P := P)
    rw [Set.range_eq_empty, Submodule.span_empty] at h2
    exact bot_ne_top h2
  have : Nonempty b.support := (b.support_nonempty).to_subtype
  exact (connected_positive_definite_cartan_matrix_iff_dynkin_list b.cartanMatrix).1
    ⟨b.cartanMatrix_isFiniteCartan, b.cartanMatrix_isIndecomposable⟩

-- A2 from sl(3): alpha1 = e1 - e2, alpha2 = e2 - e3, dot product -1, squared lengths 2.
example : dotProduct ![(1 : ℤ), -1, 0] ![0, 1, -1] = -1 ∧
    dotProduct ![(1 : ℤ), -1, 0] ![1, -1, 0] = 2 ∧
    dotProduct ![(0 : ℤ), 1, -1] ![0, 1, -1] = 2 := by decide
-- Reflecting e2 - e3 in the mirror of e1 - e2 gives e1 - e3, another root.
example : ![(0 : ℤ), 1, -1] - (-1 : ℤ) • ![1, -1, 0] = ![1, 0, -1] := by decide
-- The A2 Cartan matrix [[2, -1], [-1, 2]], determinant 3, one line.
example : A 2 = !![2, -1; -1, 2] := by decide
example : (A 2).det = 3 := by decide
example : A 2 0 1 * A 2 1 0 = 1 := by decide
-- G2: short (0, 1, -1), long (1, -2, 1), dot product -3, squared lengths 2 and 6.
example : dotProduct ![(0 : ℤ), 1, -1] ![1, -2, 1] = -3 ∧
    dotProduct ![(0 : ℤ), 1, -1] ![0, 1, -1] = 2 ∧
    dotProduct ![(1 : ℤ), -2, 1] ![1, -2, 1] = 6 := by decide
-- Cartan entries 2(-3)/6 = -1 and 2(-3)/2 = -3: the card's G2 matrix, short root first,
-- is Mathlib's G₂ transposed (Mathlib lists the long root first); three lines, determinant 1.
example : (2 * -3 : ℤ) / 6 = -1 ∧ (2 * -3 : ℤ) / 2 = -3 := by decide
example : G₂.transpose = !![2, -1; -3, 2] := by decide
example : G₂ 0 1 * G₂ 1 0 = 3 := by decide
example : G₂.det = 1 := by decide
-- The table's Cartan determinants: B3 2, C3 2, D4 4, F4 1.
example : (B 3).det = 2 := by decide
example : (C 3).det = 2 := by decide
example : (D 4).det = 4 := by decide
example : F₄.det = 1 := by decide
-- Three dots in a triangle: Cartan determinant 0, not positive definite.
example : (!![2, -1, -1; -1, 2, -1; -1, -1, 2] : Matrix (Fin 3) (Fin 3) ℤ).det = 0 := by
  norm_num [Matrix.det_fin_three]
-- Dimensions: sl(3) is 6 roots + rank 2 = 8 = n(n + 2) at n = 2; B3 and C3 18 + 3 = 21 = 3 * 7;
-- D4 24 + 4 = 28 = 4 * 7; E8 has 4 * C(8, 2) + 2^7 = 240 roots and dimension 248.
example : 6 + 2 = 2 * (2 + 2) ∧ 18 + 3 = 3 * (2 * 3 + 1) ∧ 24 + 4 = 4 * (2 * 4 - 1) := by decide
example : 4 * Nat.choose 8 2 + 2 ^ 7 = 240 ∧ 240 + 8 = 248 := by decide
-- Weyl group orders: A2 is 2m = 6 = 3!, G2 is 2m = 12, B3 is 2^3 * 3! = 48, D4 is 2^3 * 4! = 192.
example : 2 * 3 = Nat.factorial 3 ∧ 2 * 6 = 12 ∧ 2 ^ 3 * Nat.factorial 3 = 48 ∧
    2 ^ 3 * Nat.factorial 4 = 192 := by decide

#print axioms dyn_forbid
#print axioms dyn_loc
#print axioms dyn_loc1
#print axioms dyn_loc2
#print axioms dyn_loc3
#print axioms dyn_loc4
#print axioms dyn_isFiniteCartan_submatrix
#print axioms dyn_isFiniteCartan_reindex
#print axioms dyn_conn_reindex
#print axioms dyn_DL_of_reindex
#print axioms dyn_first_step
#print axioms dyn_le_neg_one
#print axioms dyn_exists_leaf
#print axioms dyn_conn_remove_leaf
#print axioms dyn_pq
#print axioms dext_symm_castSucc
#print axioms dext_symm_last
#print axioms dyn_reindex_dmk
#print axioms dyn_window
#print axioms eG2a_check
#print axioms eG2b_check
#print axioms eStA_check
#print axioms eStB_check
#print axioms eF4_check
#print axioms eW5a_check
#print axioms eW5b_check
#print axioms eB3a_check
#print axioms eB3b_check
#print axioms eD4_check
#print axioms eE7_check
#print axioms eE8_check
#print axioms dyn_mult_split
#print axioms dyn_relabel
#print axioms dyn_transfer
#print axioms dyn_A_rev
#print axioms dyn_ext_A_last
#print axioms dyn_ext_A_half
#print axioms dyn_A_rev_dmk
#print axioms dyn_ext_A_mult
#print axioms dyn_ext_A
#print axioms dshift_symm_val
#print axioms dyn_B_U1
#print axioms dyn_B_U2
#print axioms dyn_B_shift
#print axioms dyn_ext_B
#print axioms dyn_DL_transpose
#print axioms dyn_dmk_transpose
#print axioms dyn_DPQ_swap
#print axioms dyn_ext_C
#print axioms dyn_D_U2
#print axioms dyn_D_U3
#print axioms dyn_D_shift
#print axioms dyn_ext_D_leaf
#print axioms dyn_ext_D
#print axioms dyn_forbid_dec
#print axioms dyn_ext_E6
#print axioms dyn_ext_E7
#print axioms dyn_ext_E8
#print axioms dyn_ext_F4
#print axioms dyn_ext_G2
#print axioms dyn_ext_E
#print axioms dyn_ext_F
#print axioms dyn_ext_G
#print axioms dyn_main
#print axioms dyn_forward
#print axioms dyn_Q_succ
#print axioms dyn_cross_sum
#print axioms dyn_ne_zero_split
#print axioms dyn_A_sub
#print axioms dyn_A_inv
#print axioms dyn_pd_path_end
#print axioms dyn_B_pd
#print axioms dyn_C_pd
#print axioms dyn_A_Q_succ
#print axioms dyn_D_pd
#print axioms dyn_E6_pd
#print axioms dyn_E7_pd
#print axioms dyn_E8_pd
#print axioms dyn_F4_pd
#print axioms dyn_G2_pd
#print axioms dyn_conn_of
#print axioms dyn_path_reach
#print axioms dyn_A_fin
#print axioms dyn_B_fin
#print axioms dyn_C_fin
#print axioms dyn_D_fin
#print axioms dyn_E_fin
#print axioms dyn_F_fin
#print axioms dyn_G_fin
#print axioms dyn_back
#print axioms connected_positive_definite_cartan_matrix_iff_dynkin_list
#print axioms reflection_number_product_mem_zero_to_four
#print axioms root_system_cartan_matrix_mem_dynkin_list
