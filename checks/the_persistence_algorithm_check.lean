-- The persistence algorithm: over ℤ mod 2, once a filtered boundary matrix is reduced by adding earlier columns to later ones, each lowest 1 pairs a birth with a death and these pairs are exactly the bars, counting the holes alive between any two times.
import Mathlib.Data.ZMod.Basic
import Mathlib.LinearAlgebra.Matrix.Block
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.Algebra.Field.ZMod

namespace PersistenceAlgorithm

open Finset

variable {n : ℕ}

/-! Simplices are numbered `0, 1, …, n - 1` in arrival order. Column `j` of the boundary matrix `D`
lists the faces of simplex `j`, with all arithmetic mod 2; `deg i` is the dimension of simplex `i`.
The complex `L_t` is made of the simplices numbered at most `t`. -/

/-- `low R j`: the row of the lowest 1 in column `j` of `R`, or `⊥` when the column is zero. -/
def low (R : Matrix (Fin n) (Fin n) (ZMod 2)) (j : Fin n) : WithBot (Fin n) :=
  (univ.filter fun i => R i j ≠ 0).max

/-- `R` is reduced: no two nonzero columns have their lowest 1 in the same row. -/
def IsReduced (R : Matrix (Fin n) (Fin n) (ZMod 2)) : Prop :=
  ∀ j j', j ≠ j' → low R j ≠ ⊥ → low R j ≠ low R j'

/-- The k-chains of `L_t`: sums of k-simplices numbered at most `t`. -/
def chains (deg : Fin n → ℕ) (k : ℕ) (t : Fin n) : Submodule (ZMod 2) (Fin n → ZMod 2) :=
  Submodule.span (ZMod 2) ((fun i => Pi.single i 1) '' {i | i ≤ t ∧ deg i = k})

/-- The k-cycles `Z_k(L_t)`: k-chains of `L_t` with zero boundary. -/
def cycles (D : Matrix (Fin n) (Fin n) (ZMod 2)) (deg : Fin n → ℕ) (k : ℕ) (t : Fin n) :
    Submodule (ZMod 2) (Fin n → ZMod 2) :=
  chains deg k t ⊓ LinearMap.ker D.mulVecLin

/-- The k-boundaries `B_k(L_t)`: boundaries of (k+1)-chains of `L_t`. -/
def boundaries (D : Matrix (Fin n) (Fin n) (ZMod 2)) (deg : Fin n → ℕ) (k : ℕ) (t : Fin n) :
    Submodule (ZMod 2) (Fin n → ZMod 2) :=
  (chains deg (k + 1) t).map D.mulVecLin

/-- The rank of the map `H_k(L_s) → H_k(L_t)` that the inclusion induces, for `s ≤ t`: its image is
`(Z_k(L_s) + B_k(L_t)) / B_k(L_t)`. With `s = t` this is the Betti number mod 2 of `L_t`. -/
noncomputable def persistentBetti (D : Matrix (Fin n) (Fin n) (ZMod 2)) (deg : Fin n → ℕ)
    (k : ℕ) (s t : Fin n) : ℕ :=
  Module.finrank (ZMod 2) ↥(cycles D deg k s ⊔ boundaries D deg k t)
    - Module.finrank (ZMod 2) ↥(boundaries D deg k t)

/-- The k-dimensional bars of the reduced matrix `R` alive at both `s` and `t`: births `i ≤ s`
(simplices whose column of `R` is zero) that no column `j ≤ t` claims as its lowest 1. -/
def barsAlive (R : Matrix (Fin n) (Fin n) (ZMod 2)) (deg : Fin n → ℕ) (k : ℕ) (s t : Fin n) : ℕ :=
  (univ.filter fun i => deg i = k ∧ i ≤ s ∧ (∀ r, R r i = 0) ∧
    ∀ j, j ≤ t → low R j ≠ (i : WithBot (Fin n))).card

/-! Helper lemmas. -/

open scoped Matrix

theorem zmod2_ne_zero_iff : ∀ x : ZMod 2, x ≠ 0 ↔ x = 1 := by
  decide

theorem zmod2_mul_ne_zero : ∀ x y : ZMod 2, x ≠ 0 → y ≠ 0 → x * y ≠ 0 := by
  decide

theorem zmod2_add_eq_zero : ∀ x y : ZMod 2, x ≠ 0 → y ≠ 0 → x + y = 0 := by
  decide

theorem lowv_eq_coe_iff (v : Fin n → ZMod 2) (p : Fin n) :
    (univ.filter fun i => v i ≠ 0).max = (p : WithBot (Fin n)) ↔
      v p ≠ 0 ∧ ∀ q, p < q → v q = 0 := by
  constructor
  · intro h
    have hp := Finset.mem_of_max h
    simp only [mem_filter, mem_univ, true_and] at hp
    refine ⟨hp, fun q hq => ?_⟩
    by_contra hne
    have := Finset.le_max (s := univ.filter fun i => v i ≠ 0) (by simpa using hne)
    rw [h] at this
    exact absurd (WithBot.coe_le_coe.mp this) (not_le.mpr hq)
  · rintro ⟨hp, hq⟩
    apply le_antisymm
    · apply Finset.max_le
      intro a ha
      simp only [mem_filter, mem_univ, true_and] at ha
      exact WithBot.coe_le_coe.mpr (not_lt.mp fun hlt => ha (hq a hlt))
    · exact Finset.le_max (by simpa using hp)

theorem lowv_eq_bot_iff (v : Fin n → ZMod 2) :
    (univ.filter fun i => v i ≠ 0).max = ⊥ ↔ v = 0 := by
  rw [Finset.max_eq_bot, Finset.filter_eq_empty_iff]
  simp [funext_iff]

theorem coe_le_lowv (v : Fin n → ZMod 2) (q : Fin n) (h : v q ≠ 0) :
    (q : WithBot (Fin n)) ≤ (univ.filter fun i => v i ≠ 0).max :=
  Finset.le_max (by simpa using h)

theorem lowv_lt_coe (v : Fin n → ZMod 2) (p : Fin n) (h : ∀ q, p ≤ q → v q = 0) :
    (univ.filter fun i => v i ≠ 0).max < (p : WithBot (Fin n)) := by
  by_cases hb : (univ.filter fun i => v i ≠ 0).max = ⊥
  · rw [hb]; exact WithBot.bot_lt_coe p
  · obtain ⟨q, hq⟩ := WithBot.ne_bot_iff_exists.mp hb
    rw [← hq]
    have := (lowv_eq_coe_iff v q).mp hq.symm
    exact WithBot.coe_lt_coe.mpr (not_le.mp fun hle => this.1 (h q hle))

/-- A combination of vectors whose nonzero members have distinct lowest entries has the lowest
entry of one of the vectors it really uses. -/
theorem lowv_sum {ι : Type*} [Fintype ι] (f : ι → Fin n → ZMod 2)
    (hf : ∀ a b, a ≠ b → f a ≠ 0 →
      (univ.filter fun i => f a i ≠ 0).max ≠ (univ.filter fun i => f b i ≠ 0).max)
    (c : ι → ZMod 2) (h : ∃ a, c a ≠ 0 ∧ f a ≠ 0) :
    ∃ a, c a ≠ 0 ∧ f a ≠ 0 ∧ (univ.filter fun i => (∑ b, c b • f b) i ≠ 0).max =
      (univ.filter fun i => f a i ≠ 0).max := by
  classical
  set T := univ.filter fun a => c a ≠ 0 ∧ f a ≠ 0 with hTdef
  have hT : T.Nonempty := by
    obtain ⟨a, ha⟩ := h
    exact ⟨a, by simp [T, ha]⟩
  obtain ⟨a, haT, hmax⟩ := T.exists_max_image (fun a => (univ.filter fun i => f a i ≠ 0).max) hT
  simp only [T, mem_filter, mem_univ, true_and] at haT
  obtain ⟨p, hp⟩ := WithBot.ne_bot_iff_exists.mp (mt (lowv_eq_bot_iff _).mp haT.2)
  have hpa := (lowv_eq_coe_iff _ p).mp hp.symm
  have hother : ∀ b, b ≠ a → ∀ q, p ≤ q → c b * f b q = 0 := by
    intro b hba q hq
    by_cases hcb : c b = 0
    · simp [hcb]
    by_cases hfb : f b = 0
    · simp [hfb]
    have hbT : b ∈ T := by simp [T, hcb, hfb]
    have hle := hmax b hbT
    have hne := hf b a hba hfb
    rw [← hp] at hle hne
    have hlt := lt_of_le_of_ne hle hne
    by_contra hz
    have h1 := coe_le_lowv (f b) q (fun h0 => hz (by rw [h0, mul_zero]))
    exact absurd (lt_of_le_of_lt h1 hlt) (not_lt.mpr (WithBot.coe_le_coe.mpr hq))
  refine ⟨a, haT.1, haT.2, ?_⟩
  rw [← hp, lowv_eq_coe_iff]
  simp only [Finset.sum_apply, Pi.smul_apply, smul_eq_mul]
  constructor
  · rw [Finset.sum_eq_single a (fun b _ hba => hother b hba p le_rfl) (by simp)]
    exact zmod2_mul_ne_zero _ _ haT.1 hpa.1
  · intro q hq
    apply Finset.sum_eq_zero
    intro b _
    by_cases hba : b = a
    · subst hba; rw [hpa.2 q hq, mul_zero]
    · exact hother b hba q hq.le

/-- The dimension of a space of mod-2 vectors is the number of rows that occur as lowest
entries of its nonzero members. -/
theorem finrank_eq_card_lows (W : Submodule (ZMod 2) (Fin n → ZMod 2)) (L : Finset (Fin n))
    (hL : ∀ p, p ∈ L ↔ ∃ w ∈ W, (univ.filter fun i => w i ≠ 0).max = (p : WithBot (Fin n))) :
    Module.finrank (ZMod 2) W = L.card := by
  classical
  apply le_antisymm
  · let φ : W →ₗ[ZMod 2] (L → ZMod 2) :=
      (LinearMap.funLeft (ZMod 2) (ZMod 2) (Subtype.val : L → Fin n)) ∘ₗ W.subtype
    have hφ : Function.Injective φ := by
      rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
      intro w hw
      by_contra hne
      have hw0 : (w : Fin n → ZMod 2) ≠ 0 := fun h => hne (Subtype.ext h)
      obtain ⟨p, hp⟩ := WithBot.ne_bot_iff_exists.mp (mt (lowv_eq_bot_iff _).mp hw0)
      have hpL : p ∈ L := (hL p).mpr ⟨w, w.2, hp.symm⟩
      have := congrFun hw ⟨p, hpL⟩
      exact ((lowv_eq_coe_iff _ p).mp hp.symm).1 this
    have := LinearMap.finrank_le_finrank_of_injective hφ
    rwa [Module.finrank_fintype_fun_eq_card, Fintype.card_coe] at this
  · have hex : ∀ p : L, ∃ w ∈ W, (univ.filter fun i => w i ≠ 0).max = ((p : Fin n) : WithBot (Fin n)) :=
      fun p => (hL p).mp p.2
    choose g hgW hglow using hex
    have hg0 : ∀ p, g p ≠ 0 := by
      intro p h0
      have := hglow p
      rw [(lowv_eq_bot_iff _).mpr h0] at this
      exact WithBot.bot_ne_coe this
    have hli : LinearIndependent (ZMod 2) g := by
      rw [Fintype.linearIndependent_iff]
      intro c hc i
      by_contra hci
      obtain ⟨a, -, -, ha⟩ := lowv_sum g (fun a b hab _ => by
        rw [hglow a, hglow b]
        exact fun h => hab (Subtype.ext (WithBot.coe_injective h))) c ⟨i, hci, hg0 i⟩
      rw [hc, hglow a] at ha
      simp at ha
    have h1 := finrank_span_eq_card hli
    have h2 : Submodule.span (ZMod 2) (Set.range g) ≤ W := by
      rw [Submodule.span_le]
      rintro _ ⟨p, rfl⟩
      exact hgW p
    have h3 := Submodule.finrank_mono h2
    rw [h1, Fintype.card_coe] at h3
    exact h3

theorem mem_chains_iff (deg : Fin n → ℕ) (k : ℕ) (t : Fin n) (w : Fin n → ZMod 2) :
    w ∈ chains deg k t ↔ ∀ q, w q ≠ 0 → q ≤ t ∧ deg q = k := by
  constructor
  · intro hw
    suffices h : ∀ q, ¬(q ≤ t ∧ deg q = k) → w q = 0 by
      intro q hq; by_contra hn; exact hq (h q hn)
    induction hw using Submodule.span_induction with
    | mem x hx =>
      obtain ⟨i, hi, rfl⟩ := hx
      intro q hq
      have : q ≠ i := fun h => hq (h ▸ hi)
      simp [this]
    | zero => intro q _; rfl
    | add x y _ _ hx hy => intro q hq; simp [hx q hq, hy q hq]
    | smul a x _ hx => intro q hq; simp [hx q hq]
  · intro h
    rw [← Finset.univ_sum_single w]
    apply Submodule.sum_mem
    intro q _
    by_cases hq : w q = 0
    · simp [hq]
    · rw [show (Pi.single q (w q) : Fin n → ZMod 2) = w q • (Pi.single q 1 : Fin n → ZMod 2) by
        ext i; simp [Pi.single_apply]]
      exact Submodule.smul_mem _ _ (Submodule.subset_span ⟨q, h q hq, rfl⟩)

theorem mulVec_proj (D : Matrix (Fin n) (Fin n) (ZMod 2)) (deg : Fin n → ℕ)
    (hdeg : ∀ i j, D i j ≠ 0 → deg j = deg i + 1) (m : ℕ) (x : Fin n → ZMod 2) :
    D *ᵥ (fun q => if deg q = m then x q else 0) =
      fun i => if deg i + 1 = m then (D *ᵥ x) i else 0 := by
  ext i
  simp only [Matrix.mulVec, dotProduct]
  split_ifs with h
  · apply Finset.sum_congr rfl
    intro q _
    by_cases hD : D i q = 0
    · simp [hD]
    · rw [if_pos (by rw [hdeg i q hD, h])]
  · apply Finset.sum_eq_zero
    intro q _
    by_cases hD : D i q = 0
    · simp [hD]
    · rw [if_neg (by rw [hdeg i q hD]; exact h)]; simp

theorem mul_col (D V : Matrix (Fin n) (Fin n) (ZMod 2)) (j : Fin n) :
    (fun i => (D * V) i j) = D *ᵥ (fun l => V l j) := by
  ext i; simp [Matrix.mul_apply, Matrix.mulVec, dotProduct]

theorem mulVec_eq_sum_cols (D : Matrix (Fin n) (Fin n) (ZMod 2)) (x : Fin n → ZMod 2) :
    D *ᵥ x = ∑ q, x q • (fun i => D i q) := by
  ext i; simp [Matrix.mulVec, dotProduct, Finset.sum_apply, mul_comm]

/-- In a reduced matrix, a nonzero combination of columns has the lowest 1 of one of those
columns. -/
theorem exists_low_of_mem_span (R : Matrix (Fin n) (Fin n) (ZMod 2)) (hR : IsReduced R)
    (S : Set (Fin n)) (w : Fin n → ZMod 2)
    (hw : w ∈ Submodule.span (ZMod 2) ((fun l i => R i l) '' S)) (hw0 : w ≠ 0) :
    ∃ l ∈ S, (fun i => R i l) ≠ 0 ∧ (univ.filter fun i => w i ≠ 0).max = low R l := by
  classical
  obtain ⟨c, hc⟩ := (Fintype.mem_span_image_iff_exists_fun (ZMod 2)).mp hw
  have hex : ∃ a : S, c a ≠ 0 ∧ (fun i => R i (a : Fin n)) ≠ 0 := by
    by_contra hno
    push_neg at hno
    apply hw0
    rw [← hc]
    apply Finset.sum_eq_zero
    intro a _
    by_cases hca : c a = 0
    · simp [hca]
    · simp [hno a hca]
  obtain ⟨a, -, hfa, ha⟩ := lowv_sum (fun (a : S) i => R i (a : Fin n)) (fun a b hab hfa => by
      have h1 : low R a ≠ ⊥ := fun h => hfa ((lowv_eq_bot_iff _).mp h)
      exact hR a b (fun h => hab (Subtype.ext h)) h1) c hex
  refine ⟨a, a.2, hfa, ?_⟩
  rw [← hc]
  exact ha

section Reduced

variable (D V : Matrix (Fin n) (Fin n) (ZMod 2))

/-- Each column of `D` differs from the same column of `R = D V` by earlier columns of `R`. -/
theorem col_sub_mem (hV : V.IsUpperTriangular) (hVdiag : ∀ i, V i i = 1) (q : Fin n) :
    (fun i => D i q) - (fun i => (D * V) i q) ∈
      Submodule.span (ZMod 2) ((fun l i => (D * V) i l) '' {l : Fin n | l.val < q.val}) := by
  suffices hsuff : ∀ m, ∀ q : Fin n, q.val = m → (fun i => D i q) - (fun i => (D * V) i q) ∈
      Submodule.span (ZMod 2) ((fun l i => (D * V) i l) '' {l : Fin n | l.val < q.val}) from
    hsuff _ q rfl
  intro m
  induction m using Nat.strong_induction_on with
  | _ m ih =>
  intro q hqm
  subst hqm
  have hR : (fun i => (D * V) i q) =
      (fun i => D i q) + ∑ l ∈ univ.erase q, V l q • (fun i => D i l) := by
    rw [mul_col, mulVec_eq_sum_cols, ← Finset.add_sum_erase _ _ (mem_univ q), hVdiag, one_smul]
  rw [hR, sub_add_cancel_left]
  apply Submodule.neg_mem
  apply Submodule.sum_mem
  intro l hl
  by_cases hVl : V l q = 0
  · simp [hVl]
  have hlq : l < q := by
    rcases lt_or_gt_of_ne (Finset.ne_of_mem_erase hl) with h | h
    · exact h
    · exact absurd (hV h) hVl
  apply Submodule.smul_mem
  have h1 := ih l.val hlq l rfl
  have hmono : Submodule.span (ZMod 2) ((fun l' i => (D * V) i l') '' {l' : Fin n | l'.val < l.val}) ≤
      Submodule.span (ZMod 2) ((fun l' i => (D * V) i l') '' {l' : Fin n | l'.val < q.val}) :=
    Submodule.span_mono (Set.image_mono fun l' (h : l'.val < l.val) => lt_trans h hlq)
  have h2 : (fun i => (D * V) i l) ∈
      Submodule.span (ZMod 2) ((fun l' i => (D * V) i l') '' {l' : Fin n | l'.val < q.val}) :=
    Submodule.subset_span ⟨l, hlq, rfl⟩
  have := Submodule.add_mem _ (hmono h1) h2
  rwa [sub_add_cancel] at this

/-- `D x` lies in the span of the columns of `R` before the end of `x`'s support. -/
theorem mulVec_mem_span (hV : V.IsUpperTriangular) (hVdiag : ∀ i, V i i = 1) (m : ℕ)
    (x : Fin n → ZMod 2) (hx : ∀ q : Fin n, m ≤ q.val → x q = 0) :
    D *ᵥ x ∈ Submodule.span (ZMod 2) ((fun l i => (D * V) i l) '' {l : Fin n | l.val < m}) := by
  rw [mulVec_eq_sum_cols]
  apply Submodule.sum_mem
  intro q _
  by_cases hxq : x q = 0
  · simp [hxq]
  have hqm : q.val < m := by
    by_contra h; exact hxq (hx q (not_lt.mp h))
  apply Submodule.smul_mem
  have h1 := col_sub_mem D V hV hVdiag q
  have hmono : Submodule.span (ZMod 2) ((fun l' i => (D * V) i l') '' {l' : Fin n | l'.val < q.val}) ≤
      Submodule.span (ZMod 2) ((fun l' i => (D * V) i l') '' {l' : Fin n | l'.val < m}) :=
    Submodule.span_mono (Set.image_mono fun l' (h : l'.val < q.val) => lt_trans h hqm)
  have h2 : (fun i => (D * V) i q) ∈
      Submodule.span (ZMod 2) ((fun l' i => (D * V) i l') '' {l' : Fin n | l'.val < m}) :=
    Submodule.subset_span ⟨q, hqm, rfl⟩
  have := Submodule.add_mem _ (hmono h1) h2
  rwa [sub_add_cancel] at this

/-- If a cycle has its lowest entry in row `p`, column `p` of the reduced matrix is zero. -/
theorem col_zero_of_cycle (hV : V.IsUpperTriangular) (hVdiag : ∀ i, V i i = 1)
    (hR : IsReduced (D * V)) (w : Fin n → ZMod 2) (hw : D *ᵥ w = 0) (p : Fin n)
    (hp : (univ.filter fun i => w i ≠ 0).max = (p : WithBot (Fin n))) :
    ∀ r, (D * V) r p = 0 := by
  have hwp := (lowv_eq_coe_iff w p).mp hp
  have hmem : (fun i => (D * V) i p) ∈
      Submodule.span (ZMod 2) ((fun l i => (D * V) i l) '' {l : Fin n | l.val < p.val}) := by
    have : (fun i => (D * V) i p) = D *ᵥ ((fun l => V l p) - w) := by
      rw [Matrix.mulVec_sub, hw, sub_zero, mul_col]
    rw [this]
    apply mulVec_mem_span D V hV hVdiag
    intro q hq
    rcases eq_or_lt_of_le (show p ≤ q from hq) with h | h
    · subst h
      simp [hVdiag, (zmod2_ne_zero_iff _).mp hwp.1]
    · simp [hV h, hwp.2 q h]
  by_contra hne
  push_neg at hne
  obtain ⟨r, hr⟩ := hne
  have hne0 : (fun i => (D * V) i p) ≠ 0 := fun h => hr (congrFun h r)
  obtain ⟨l, hl, -, hlow⟩ := exists_low_of_mem_span (D * V) hR _ _ hmem hne0
  have hlp : p ≠ l := fun h => by subst h; exact lt_irrefl _ (show p.val < p.val from hl)
  exact hR p l hlp (fun h => hne0 ((lowv_eq_bot_iff _).mp h)) hlow

end Reduced

/-- **The pairs are the bars.** Let `D` be the boundary matrix mod 2 of a finite filtration, every
simplex arriving after its faces, and let `R = D V` be reduced, where `V` records additions of
earlier columns to later ones (upper triangular with 1s on its diagonal). Then for any times
`s ≤ t`, the number of k-dimensional holes of `L_s` still alive in `L_t` equals the number of
k-dimensional bars read off `R` that have started by `s` and not ended by `t`. -/
theorem pairs_of_reduced_matrix_are_the_bars (D V : Matrix (Fin n) (Fin n) (ZMod 2))
    (deg : Fin n → ℕ) (hdeg : ∀ i j, D i j ≠ 0 → deg j = deg i + 1) (hDD : D * D = 0)
    (hfaces : ∀ i j, D i j ≠ 0 → i < j)
    (hV : V.IsUpperTriangular) (hVdiag : ∀ i, V i i = 1) (hR : IsReduced (D * V))
    (k : ℕ) (s t : Fin n) (hst : s ≤ t) :
    persistentBetti D deg k s t = barsAlive (D * V) deg k s t := by
  classical
  have hV' : ∀ i j, j < i → V i j = 0 := fun i j h => hV h
  have hDR : ∀ j, D *ᵥ (fun i => (D * V) i j) = 0 := by
    intro j; rw [mul_col, Matrix.mulVec_mulVec, hDD, Matrix.zero_mulVec]
  have memZ : ∀ w, w ∈ cycles D deg k s ↔ w ∈ chains deg k s ∧ D *ᵥ w = 0 := by
    intro w; simp [cycles, Submodule.mem_inf, LinearMap.mem_ker]
  have charZ_mp : ∀ w ∈ cycles D deg k s, ∀ p : Fin n,
      (univ.filter fun i => w i ≠ 0).max = (p : WithBot (Fin n)) →
        deg p = k ∧ p ≤ s ∧ ∀ r, (D * V) r p = 0 := by
    intro w hw p hp
    rw [memZ] at hw
    have hwp := (lowv_eq_coe_iff w p).mp hp
    obtain ⟨h1, h2⟩ := (mem_chains_iff deg k s w).mp hw.1 p hwp.1
    exact ⟨h2, h1, col_zero_of_cycle D V hV hVdiag hR w hw.2 p hp⟩
  have hZ : Module.finrank (ZMod 2) ↥(cycles D deg k s) =
      (univ.filter fun p : Fin n => deg p = k ∧ p ≤ s ∧ ∀ r, (D * V) r p = 0).card := by
    refine finrank_eq_card_lows _ _ fun p => ?_
    simp only [mem_filter, mem_univ, true_and]
    constructor
    · rintro ⟨hdp, hps, hRp⟩
      refine ⟨fun q => if deg q = k then V q p else 0, ?_, ?_⟩
      · rw [memZ, mem_chains_iff]
        refine ⟨fun q hq => ?_, ?_⟩
        · by_cases hdq : deg q = k
          · rw [if_pos hdq] at hq
            exact ⟨le_trans (not_lt.mp fun h => hq (hV' q p h)) hps, hdq⟩
          · rw [if_neg hdq] at hq; exact absurd rfl hq
        · rw [mulVec_proj D deg hdeg, ← mul_col]
          ext i; simp [hRp]
      · rw [lowv_eq_coe_iff]
        exact ⟨by simp [hdp, hVdiag], fun q hq => by simp [hV' q p hq]⟩
    · rintro ⟨w, hw, hp⟩
      exact charZ_mp w hw p hp
  have hZB : Module.finrank (ZMod 2) ↥(cycles D deg k s ⊓ boundaries D deg k t) =
      (univ.filter fun p : Fin n => (deg p = k ∧ p ≤ s ∧ ∀ r, (D * V) r p = 0) ∧
        ∃ j, j ≤ t ∧ low (D * V) j = (p : WithBot (Fin n))).card := by
    refine finrank_eq_card_lows _ _ fun p => ?_
    simp only [mem_filter, mem_univ, true_and]
    constructor
    · rintro ⟨⟨hdp, hps, hRp⟩, j, hjt, hj⟩
      have hjp := (lowv_eq_coe_iff (fun i => (D * V) i j) p).mp hj
      refine ⟨fun q => if deg q = k then (D * V) q j else 0, Submodule.mem_inf.mpr ⟨?_, ?_⟩, ?_⟩
      · rw [memZ, mem_chains_iff]
        refine ⟨fun q hq => ?_, ?_⟩
        · by_cases hdq : deg q = k
          · rw [if_pos hdq] at hq
            have hle : (q : WithBot (Fin n)) ≤ low (D * V) j := coe_le_lowv (fun i => (D * V) i j) q hq
            rw [hj] at hle
            exact ⟨le_trans (WithBot.coe_le_coe.mp hle) hps, hdq⟩
          · rw [if_neg hdq] at hq; exact absurd rfl hq
        · rw [mulVec_proj D deg hdeg, hDR j]
          ext i; simp
      · refine Submodule.mem_map.mpr ⟨fun q => if deg q = k + 1 then V q j else 0, ?_, ?_⟩
        · rw [mem_chains_iff]
          intro q hq
          by_cases hdq : deg q = k + 1
          · rw [if_pos hdq] at hq
            exact ⟨le_trans (not_lt.mp fun h => hq (hV' q j h)) hjt, hdq⟩
          · rw [if_neg hdq] at hq; exact absurd rfl hq
        · rw [Matrix.mulVecLin_apply, mulVec_proj D deg hdeg, ← mul_col]
          ext i; simp
      · rw [lowv_eq_coe_iff]
        exact ⟨by simpa [hdp] using hjp.1, fun q hq => by simp [hjp.2 q hq]⟩
    · rintro ⟨w, hw, hp⟩
      obtain ⟨hwZ, hwB⟩ := Submodule.mem_inf.mp hw
      refine ⟨charZ_mp w hwZ p hp, ?_⟩
      obtain ⟨y, hy, rfl⟩ := Submodule.mem_map.mp hwB
      have hymem := mulVec_mem_span D V hV hVdiag (t.val + 1) y (fun q hq => by
        by_contra hne
        have := ((mem_chains_iff deg (k + 1) t y).mp hy q hne).1
        rw [Fin.le_def] at this
        omega)
      have hw0 : D *ᵥ y ≠ 0 := by
        intro h0
        rw [Matrix.mulVecLin_apply, h0, (lowv_eq_bot_iff _).mpr rfl] at hp
        exact WithBot.bot_ne_coe hp
      obtain ⟨l, hl, -, hlow⟩ := exists_low_of_mem_span (D * V) hR _ (D *ᵥ y) hymem hw0
      refine ⟨l, Fin.le_def.mpr (by simp only [Set.mem_setOf_eq] at hl; omega), ?_⟩
      rw [← hlow]; exact hp
  have hsum := Submodule.finrank_sup_add_finrank_inf_eq (K := ZMod 2) (cycles D deg k s) (boundaries D deg k t)
  have hc := card_filter_add_card_filter_not
    (s := univ.filter fun p : Fin n => deg p = k ∧ p ≤ s ∧ ∀ r, (D * V) r p = 0)
    (fun p => ∃ j, j ≤ t ∧ low (D * V) j = (p : WithBot (Fin n)))
  rw [Finset.filter_filter, Finset.filter_filter] at hc
  have e2 : (univ.filter fun p : Fin n => (deg p = k ∧ p ≤ s ∧ ∀ r, (D * V) r p = 0) ∧
      ¬ ∃ j, j ≤ t ∧ low (D * V) j = (p : WithBot (Fin n))) =
      univ.filter fun i => deg i = k ∧ i ≤ s ∧ (∀ r, (D * V) r i = 0) ∧
        ∀ j, j ≤ t → low (D * V) j ≠ (i : WithBot (Fin n)) := by
    ext p; simp only [mem_filter, mem_univ, true_and, not_exists, not_and]; tauto
  rw [e2] at hc
  unfold persistentBetti barsAlive
  omega

/-- **The reduction always finishes.** Adding earlier columns to later ones mod 2 reduces any
finite boundary matrix: there is an upper triangular `V` with 1s on its diagonal such that no two
nonzero columns of `D V` share a lowest 1. -/
theorem column_reduction_terminates (D : Matrix (Fin n) (Fin n) (ZMod 2)) :
    ∃ V : Matrix (Fin n) (Fin n) (ZMod 2), V.IsUpperTriangular ∧ (∀ i, V i i = 1) ∧
      IsReduced (D * V) := by
  classical
  have key : ∀ j : Fin n, ∃ w : Fin n → ZMod 2, (∀ l, j ≤ l → w l = 0) ∧
      ∀ w' : Fin n → ZMod 2, (∀ l, j ≤ l → w' l = 0) →
        (univ.filter fun i => (D *ᵥ (Pi.single j 1 + w)) i ≠ 0).max ≤
          (univ.filter fun i => (D *ᵥ (Pi.single j 1 + w')) i ≠ 0).max := by
    intro j
    obtain ⟨x, ⟨w, hw, rfl⟩, hmin⟩ := WellFounded.has_min wellFounded_lt
      {x | ∃ w : Fin n → ZMod 2, (∀ l, j ≤ l → w l = 0) ∧
        (univ.filter fun i => (D *ᵥ (Pi.single j 1 + w)) i ≠ 0).max = x}
      ⟨_, 0, fun _ _ => rfl, rfl⟩
    exact ⟨w, hw, fun w' hw' => not_lt.mp (hmin _ ⟨w', hw', rfl⟩)⟩
  choose w hw hmin using key
  let V : Matrix (Fin n) (Fin n) (ZMod 2) := Matrix.of fun i j => ((Pi.single j (1 : ZMod 2) : Fin n → ZMod 2) + w j) i
  have hcol : ∀ j, (fun i => (D * V) i j) = D *ᵥ (Pi.single j 1 + w j) := by
    intro j; rw [mul_col]; rfl
  refine ⟨V, ?_, ?_, ?_⟩
  · intro i j hji
    have hji' : j < i := hji
    have hij : i ≠ j := ne_of_gt hji'
    simp [V, Pi.single_apply, hij, hw j i hji'.le]
  · intro i; simp [V, hw i i le_rfl]
  · have claim : ∀ a b : Fin n, a < b → low (D * V) a ≠ ⊥ → low (D * V) a ≠ low (D * V) b := by
      intro a b hab hbot heq
      obtain ⟨p, hp⟩ := WithBot.ne_bot_iff_exists.mp hbot
      have hpa := (lowv_eq_coe_iff (D *ᵥ (Pi.single a 1 + w a)) p).mp
        (by rw [← hcol]; exact hp.symm)
      have hpb := (lowv_eq_coe_iff (D *ᵥ (Pi.single b 1 + w b)) p).mp
        (by have hpb' : low (D * V) b = ↑p := by rw [← heq]; exact hp.symm
            rw [← hcol]; exact hpb')
      have hadm : ∀ l, b ≤ l → ((w b + Pi.single a 1 + w a : Fin n → ZMod 2)) l = 0 := by
        intro l hl
        have hla : l ≠ a := fun h => by subst h; exact absurd hab (not_lt.mpr hl)
        simp [hw b l hl, hw a l (le_trans hab.le hl), hla]
      have h1 := hmin b (w b + Pi.single a 1 + w a) hadm
      have hsum : (Pi.single b 1 + (w b + Pi.single a 1 + w a) : Fin n → ZMod 2) =
          (Pi.single b 1 + w b) + (Pi.single a 1 + w a) := by abel
      rw [hsum] at h1
      have h2 := lowv_lt_coe (D *ᵥ ((Pi.single b 1 + w b) + (Pi.single a 1 + w a))) p (by
        intro q hq
        rw [Matrix.mulVec_add]
        rcases eq_or_lt_of_le hq with h | h
        · subst h; simp only [Pi.add_apply]; exact zmod2_add_eq_zero _ _ hpb.1 hpa.1
        · simp [hpa.2 q h, hpb.2 q h])
      have h3 := (lowv_eq_coe_iff _ p).mpr hpb
      rw [h3] at h1
      exact absurd (lt_of_le_of_lt h1 h2) (lt_irrefl _)
    intro a b hab hbot
    rcases lt_or_gt_of_ne hab with h | h
    · exact claim a b h hbot
    · intro heq
      exact claim b a h (heq ▸ hbot) heq.symm

/-- **Every death is paired with a birth.** If column `j` of the reduced matrix `R = D V` has its
lowest 1 in row `i`, then column `i` of `R` is zero: simplex `i` opened the hole that simplex `j`
closes. -/
theorem lowest_one_row_is_a_birth (D V : Matrix (Fin n) (Fin n) (ZMod 2)) (hDD : D * D = 0)
    (hV : V.IsUpperTriangular) (hVdiag : ∀ i, V i i = 1) (hR : IsReduced (D * V))
    (i j : Fin n) (hij : low (D * V) j = i) : ∀ r, (D * V) r i = 0 := by
  apply col_zero_of_cycle D V hV hVdiag hR (fun r => (D * V) r j)
  · rw [mul_col, Matrix.mulVec_mulVec, hDD, Matrix.zero_mulVec]
  · exact hij

/-! The card's 4-by-3 rectangle. Arrival order: A B C D AD BC AB CD AC BD ABC ABD ACD BCD,
numbered 0 to 13. -/

/-- The rectangle's faces, as (face, simplex) pairs. -/
def rectFaces : List (ℕ × ℕ) :=
  [(0, 4), (3, 4), (1, 5), (2, 5), (0, 6), (1, 6), (2, 7), (3, 7), (0, 8), (2, 8), (1, 9), (3, 9),
   (5, 10), (6, 10), (8, 10), (4, 11), (6, 11), (9, 11), (4, 12), (7, 12), (8, 12),
   (5, 13), (7, 13), (9, 13)]

/-- The rectangle's boundary matrix mod 2. -/
def rectD : Matrix (Fin 14) (Fin 14) (ZMod 2) :=
  Matrix.of fun i j => if (i.val, j.val) ∈ rectFaces then 1 else 0

/-- The record of additions from the hand table: CD + AD + BC + AB, AC + BC + AB, BD + AD + AB,
ACD + ABC, and BCD + ABD + ACD (where ACD already holds ABC). -/
def rectV : Matrix (Fin 14) (Fin 14) (ZMod 2) :=
  Matrix.of fun i j => if i = j ∨ (i.val, j.val) ∈
    [(4, 7), (5, 7), (6, 7), (5, 8), (6, 8), (4, 9), (6, 9), (10, 12), (10, 13), (11, 13), (12, 13)]
    then 1 else 0

/-- Dimensions: 4 points, 6 edges, 4 triangles. -/
def rectDeg (i : Fin 14) : ℕ := if i.val < 4 then 0 else if i.val < 10 then 1 else 2

-- The rectangle's matrix is a boundary matrix in arrival order: ∂∂ = 0, every simplex arrives
-- after its faces, and each face is one dimension down.
example : rectD * rectD = 0 ∧ (∀ p : Fin 14 × Fin 14, rectD p.1 p.2 ≠ 0 → p.1 < p.2) ∧
    (∀ p : Fin 14 × Fin 14, rectD p.1 p.2 ≠ 0 → rectDeg p.2 = rectDeg p.1 + 1) := by
  decide +kernel

-- The record of additions only adds earlier columns to later ones: upper triangular, 1s on the
-- diagonal.
example : (∀ p : Fin 14 × Fin 14, p.2 < p.1 → rectV p.1 p.2 = 0) ∧ (∀ i : Fin 14, rectV i i = 1) := by
  decide +kernel

-- The reduced matrix has no two lowest 1s in the same row.
example : IsReduced (rectD * rectV) := by
  unfold IsReduced
  decide +kernel

-- The pairs: (D, AD), (C, BC), (B, AB), (AC, ABC), (BD, ABD), (CD, ACD).
example : low (rectD * rectV) 4 = (3 : Fin 14) ∧ low (rectD * rectV) 5 = (2 : Fin 14) ∧
    low (rectD * rectV) 6 = (1 : Fin 14) ∧ low (rectD * rectV) 10 = (8 : Fin 14) ∧
    low (rectD * rectV) 11 = (9 : Fin 14) ∧ low (rectD * rectV) 12 = (7 : Fin 14) := by
  decide +kernel

-- CD, AC, BD and BCD reduce to zero: births.
example : low (rectD * rectV) 7 = ⊥ ∧ low (rectD * rectV) 8 = ⊥ ∧
    low (rectD * rectV) 9 = ⊥ ∧ low (rectD * rectV) 13 = ⊥ := by
  decide +kernel

-- The H1 bar: the loop is alive from CD (7) up to just before ACD (12), and dead at 12.
example : barsAlive (rectD * rectV) rectDeg 1 7 11 = 1 ∧
    barsAlive (rectD * rectV) rectDeg 1 12 12 = 0 := by
  decide +kernel

-- At the end one cluster is left: one H0 bar never dies.
example : barsAlive (rectD * rectV) rectDeg 0 13 13 = 1 := by
  decide +kernel

-- Unreduced, all 6 edge columns are nonzero (4 - 6 = -2 clusters); reduced, only 3 are.
example : (univ.filter fun j => rectDeg j = 1 ∧ low rectD j ≠ ⊥).card = 6 ∧
    (univ.filter fun j => rectDeg j = 1 ∧ low (rectD * rectV) j ≠ ⊥).card = 3 := by
  decide +kernel

#print axioms zmod2_ne_zero_iff
#print axioms zmod2_mul_ne_zero
#print axioms zmod2_add_eq_zero
#print axioms lowv_eq_coe_iff
#print axioms lowv_eq_bot_iff
#print axioms coe_le_lowv
#print axioms lowv_lt_coe
#print axioms lowv_sum
#print axioms finrank_eq_card_lows
#print axioms mem_chains_iff
#print axioms mulVec_proj
#print axioms mul_col
#print axioms mulVec_eq_sum_cols
#print axioms exists_low_of_mem_span
#print axioms col_sub_mem
#print axioms mulVec_mem_span
#print axioms col_zero_of_cycle
#print axioms pairs_of_reduced_matrix_are_the_bars
#print axioms column_reduction_terminates
#print axioms lowest_one_row_is_a_birth

end PersistenceAlgorithm
