-- Filtration and persistent homology: over a field, the holes of a finite filtration of simplicial complexes are counted by one unique list of bars [b, d), and adding one simplex either creates one hole or kills one.
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.LinearAlgebra.Quotient.Basic
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.Data.ENat.Lattice
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum

namespace FiltrationsPersistentHomology

open Finset

variable {V : Type*} [LinearOrder V] [Fintype V]

/-- The k-simplices of a family of simplices: those with k + 1 corners. -/
def simplices (K : Finset (Finset V)) (k : ℕ) : Finset (Finset V) :=
  K.filter (fun s => s.card = k + 1)

/-- A finite simplicial complex: every nonempty face of every simplex is in the complex. -/
def IsComplex (K : Finset (Finset V)) : Prop :=
  ∀ s ∈ K, ∀ t ⊆ s, t.Nonempty → t ∈ K

/-- The signed coefficient of the face `t` in the boundary of the simplex `s`, corners listed in
increasing order: dropping the corner `v` gets sign `(-1)^i`, where `i` is the number of corners
of `s` below `v`. Over `ℤ mod 2` every sign is 1. -/
def bdCoeff (s t : Finset V) : ℤ :=
  ∑ v ∈ s, if s.erase v = t then (-1) ^ (s.filter (· < v)).card else 0

section Homology

variable (𝕜 : Type*) [Field 𝕜]

/-- The k-chains of `K` with coefficients in the field `𝕜`, inside the space of all coefficient
lists on finite sets of corners: the lists that vanish off the k-simplices of `K`. -/
def chains (K : Finset (Finset V)) (k : ℕ) : Submodule 𝕜 (Finset V → 𝕜) :=
  Submodule.pi {s | s ∉ simplices K k} (fun _ => ⊥)

/-- The boundary map `∂`, sending a chain to the signed sum of the faces of its simplices. -/
def bd : (Finset V → 𝕜) →ₗ[𝕜] (Finset V → 𝕜) :=
  Matrix.mulVecLin (fun t s => (bdCoeff s t : 𝕜))

/-- The k-cycles `Z_k` of `K`: every 0-chain, and the (k+1)-chains with zero boundary. -/
def cycles (K : Finset (Finset V)) : ℕ → Submodule 𝕜 (Finset V → 𝕜)
  | 0 => chains 𝕜 K 0
  | k + 1 => chains 𝕜 K (k + 1) ⊓ LinearMap.ker (bd 𝕜)

/-- The k-boundaries `B_k` of `K`: the boundaries of (k+1)-chains of `K`. -/
def boundaries (K : Finset (Finset V)) (k : ℕ) : Submodule 𝕜 (Finset V → 𝕜) :=
  (chains 𝕜 K (k + 1)).map (bd 𝕜)

/-- The persistent Betti number `β_k^{r,s}` for complexes `K ⊆ L`: the dimension of the
k-cycles of `K` modulo those that are boundaries in `L`, that is, how many independent k-holes of
`K` are still holes in `L`. -/
noncomputable def persistentBetti (K L : Finset (Finset V)) (k : ℕ) : ℕ :=
  Module.finrank 𝕜 (↥(cycles 𝕜 K k) ⧸ (boundaries 𝕜 L k).comap (cycles 𝕜 K k).subtype)

/-- The Betti number `β_k(K) = dim H_k(K)`: the persistent Betti number with `r = s`. -/
noncomputable def betti (K : Finset (Finset V)) (k : ℕ) : ℕ :=
  persistentBetti 𝕜 K K k

/-! ### Helper lemmas -/

/-- Dimension count for two pairs of nested subspaces. -/
lemma finrank_inf_quad {𝔽 W : Type*} [Field 𝔽] [AddCommGroup W] [Module 𝔽 W]
    [Module.Finite 𝔽 W] (A A' C C' : Submodule 𝔽 W) (hA : A ≤ A') (hC : C ≤ C') :
    Module.finrank 𝔽 ↥(A' ⊓ C) + Module.finrank 𝔽 ↥(A ⊓ C') ≤
      Module.finrank 𝔽 ↥(A' ⊓ C') + Module.finrank 𝔽 ↥(A ⊓ C) := by
  have h1 := Submodule.finrank_sup_add_finrank_inf_eq (A' ⊓ C) (A ⊓ C')
  have h2 : (A' ⊓ C) ⊓ (A ⊓ C') = A ⊓ C := by
    apply le_antisymm
    · exact le_inf (inf_le_right.trans inf_le_left) (inf_le_left.trans inf_le_right)
    · exact le_inf (inf_le_inf hA le_rfl) (inf_le_inf le_rfl hC)
  have h3 : (A' ⊓ C) ⊔ (A ⊓ C') ≤ A' ⊓ C' :=
    sup_le (inf_le_inf le_rfl hC) (inf_le_inf hA le_rfl)
  have h4 := Submodule.finrank_mono h3
  rw [h2] at h1
  omega

/-- Telescoping sum over an interval. -/
lemma sum_Ico_telescope (f : ℕ → ℤ) (s T : ℕ) (h : s ≤ T) :
    ∑ e ∈ Finset.Ico s T, (f e - f (e + 1)) = f s - f T := by
  induction T, h using Nat.le_induction with
  | base => simp
  | succ n hn ih => rw [Finset.sum_Ico_succ_top hn, ih]; ring

/-- Splitting a count by a second condition. -/
lemma countP_split {α : Type*} (p q : α → Prop) [DecidablePred p] [DecidablePred q]
    (M : Multiset α) :
    M.countP p = M.countP (fun x => p x ∧ q x) + M.countP (fun x => p x ∧ ¬ q x) := by
  induction M using Multiset.induction_on with
  | empty => simp
  | cons a M ih =>
    simp only [Multiset.countP_cons]
    rw [ih]
    by_cases hp : p a <;> by_cases hq : q a <;> simp [hp, hq] <;> omega

/-- Counting in a repeated element. -/
lemma countP_replicate' {α : Type*} (p : α → Prop) [DecidablePred p] (n : ℕ) (a : α) :
    (Multiset.replicate n a).countP p = if p a then n else 0 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Multiset.replicate_succ, Multiset.countP_cons, ih]
    split_ifs <;> simp

/-- Existence of a barcode for two growing families of subspaces. -/
lemma barcode_exists_of_subspaces {𝔽 W : Type*} [Field 𝔽] [AddCommGroup W] [Module 𝔽 W]
    [Module.Finite 𝔽 W] (Z B : ℕ → Submodule 𝔽 W) (hZ : Monotone Z) (hB : Monotone B) :
    ∃ M : Multiset (ℕ × ℕ∞), (∀ bar ∈ M, (bar.1 : ℕ∞) < bar.2) ∧
      ∀ r s : ℕ, r ≤ s →
        ((M.filter (fun bar => bar.1 ≤ r ∧ (s : ℕ∞) < bar.2)).card : ℤ)
          = (Module.finrank 𝔽 ↥(Z r) : ℤ) - Module.finrank 𝔽 ↥(Z r ⊓ B s) := by
  obtain ⟨T1, hT1⟩ := WellFoundedGT.monotone_chain_condition (⟨Z, hZ⟩ : ℕ →o Submodule 𝔽 W)
  obtain ⟨T2, hT2⟩ := WellFoundedGT.monotone_chain_condition (⟨B, hB⟩ : ℕ →o Submodule 𝔽 W)
  set T := max T1 T2 with hTdef
  have hZT : ∀ n, T ≤ n → Z n = Z T := fun n hn => by
    have a := hT1 n (le_trans (le_max_left _ _) hn)
    have b := hT1 T (le_max_left _ _)
    simp only [OrderHom.coe_mk] at a b
    rw [← a, ← b]
  have hBT : ∀ n, T ≤ n → B n = B T := fun n hn => by
    have a := hT2 n (le_trans (le_max_right _ _) hn)
    have b := hT2 T (le_max_right _ _)
    simp only [OrderHom.coe_mk] at a b
    rw [← a, ← b]
  let Zx : ℕ → Submodule 𝔽 W := fun i => if i = 0 then ⊥ else Z (i - 1)
  have hZx : ∀ i, Zx i ≤ Zx (i + 1) := by
    intro i
    rcases i with _ | i
    · simp [Zx]
    · simp only [Zx, if_neg (Nat.succ_ne_zero _)]
      exact hZ (by omega)
  let g : ℕ → ℕ → ℤ := fun i s =>
    (Module.finrank 𝔽 ↥(Zx i) : ℤ) - Module.finrank 𝔽 ↥(Zx i ⊓ B s)
  let D : ℕ → ℕ → ℤ := fun b s => g (b + 1) s - g b s
  have hN1 : ∀ b s, 0 ≤ D b s - D b (s + 1) := by
    intro b s
    have := finrank_inf_quad (Zx b) (Zx (b + 1)) (B s) (B (s + 1)) (hZx b) (hB (Nat.le_succ s))
    simp only [D, g]
    omega
  have hN2 : ∀ b, 0 ≤ D b T := by
    intro b
    have := finrank_inf_quad (Zx b) (Zx (b + 1)) (B T) ⊤ (hZx b) le_top
    rw [inf_top_eq, inf_top_eq] at this
    simp only [D, g]
    omega
  have hg0 : ∀ s, g 0 s = 0 := by intro s; simp [g, Zx]
  have hgB : ∀ i s, T ≤ s → g i s = g i T := by
    intro i s hs; simp only [g]; rw [hBT s hs]
  let blk : ℕ → Multiset (ℕ × ℕ∞) := fun b =>
    (∑ e ∈ Finset.Ico b T, Multiset.replicate (D b e - D b (e + 1)).toNat (b, ((e + 1 : ℕ) : ℕ∞)))
      + Multiset.replicate (D b T).toNat (b, ⊤)
  refine ⟨∑ b ∈ Finset.range (T + 1), blk b, ?_, ?_⟩
  · intro bar hbar
    rw [Multiset.mem_sum] at hbar
    obtain ⟨b, -, hb⟩ := hbar
    simp only [blk, Multiset.mem_add, Multiset.mem_sum] at hb
    rcases hb with ⟨e, he, hm⟩ | hm
    · rw [Multiset.mem_replicate] at hm
      rw [hm.2]
      simp only [Finset.mem_Ico] at he
      show ((b : ℕ) : ℕ∞) < ((e + 1 : ℕ) : ℕ∞)
      exact_mod_cast (by omega : b < e + 1)
    · rw [Multiset.mem_replicate] at hm
      rw [hm.2]
      exact ENat.natCast_lt_top b
  · intro r s hrs
    set p : ℕ × ℕ∞ → Prop := fun bar => bar.1 ≤ r ∧ (s : ℕ∞) < bar.2 with hp
    rw [← Multiset.countP_eq_card_filter]
    have hsum : ∀ (S : Finset ℕ) (f : ℕ → Multiset (ℕ × ℕ∞)),
        (∑ i ∈ S, f i).countP p = ∑ i ∈ S, (f i).countP p := fun S f =>
      map_sum (Multiset.countPAddMonoidHom p) f S
    have key : ∀ b, (((blk b).countP p : ℕ) : ℤ) = if b ≤ r then D b s else 0 := by
      intro b
      simp only [blk, Multiset.countP_add, hsum, countP_replicate']
      by_cases hb : b ≤ r
      · rw [if_pos hb]
        have hpe : ∀ e : ℕ, p (b, ((e + 1 : ℕ) : ℕ∞)) ↔ s ≤ e := by
          intro e; simp only [hp]; constructor
          · rintro ⟨-, h⟩; exact_mod_cast (Nat.lt_succ_iff.mp (by exact_mod_cast h))
          · intro h; exact ⟨hb, by exact_mod_cast Nat.lt_succ_of_le h⟩
        have hpt : p (b, ⊤) := ⟨hb, ENat.natCast_lt_top s⟩
        simp only [hpe, if_pos hpt]
        push_cast
        rw [Int.toNat_of_nonneg (hN2 b)]
        have hinner : ∑ e ∈ Finset.Ico b T,
            ((if s ≤ e then (D b e - D b (e + 1)).toNat else 0 : ℕ) : ℤ)
              = ∑ e ∈ Finset.Ico s T, (D b e - D b (e + 1)) := by
          rw [← Finset.sum_filter_add_sum_filter_not (Finset.Ico b T) (fun e => s ≤ e)]
          rw [Finset.sum_eq_zero (s := Finset.filter (fun e => ¬ s ≤ e) (Finset.Ico b T))
            (fun e he => by simp only [Finset.mem_filter] at he; simp [he.2])]
          rw [add_zero]
          have hfil : Finset.filter (fun e => s ≤ e) (Finset.Ico b T) = Finset.Ico s T := by
            ext e; simp only [Finset.mem_filter, Finset.mem_Ico]; omega
          rw [hfil]
          refine Finset.sum_congr rfl fun e he => ?_
          simp only [Finset.mem_Ico] at he
          rw [if_pos he.1, Int.toNat_of_nonneg (hN1 b e)]
        push_cast at hinner ⊢
        rw [hinner]
        by_cases hsT : s ≤ T
        · rw [sum_Ico_telescope (fun e => D b e) s T hsT]; ring
        · rw [Finset.Ico_eq_empty (by omega), Finset.sum_empty]
          simp only [D]
          rw [hgB _ s (by omega), hgB _ s (by omega)]
          ring
      · rw [if_neg hb]
        have hpe : ∀ x : ℕ∞, ¬ p (b, x) := fun x h => hb h.1
        simp [hpe]
    rw [hsum]
    push_cast
    rw [Finset.sum_congr rfl (fun b _ => key b)]
    rw [← Finset.sum_filter]
    have hfil : Finset.filter (fun b => b ≤ r) (Finset.range (T + 1))
        = Finset.range (min r T + 1) := by
      ext b; simp only [Finset.mem_filter, Finset.mem_range]; omega
    rw [hfil, Finset.sum_range_sub (fun i => g i s), hg0, sub_zero]
    have hZx' : ∀ i, Zx (i + 1) = Z i := fun i => by simp [Zx]
    simp only [g]
    rw [hZx']
    by_cases hrT : r ≤ T
    · rw [min_eq_left hrT]
    · rw [min_eq_right (by omega), hZT r (by omega)]

/-- Uniqueness of a barcode from its counts. -/
lemma barcode_unique_of_counts (M1 M2 : Multiset (ℕ × ℕ∞))
    (h1 : ∀ bar ∈ M1, (bar.1 : ℕ∞) < bar.2) (h2 : ∀ bar ∈ M2, (bar.1 : ℕ∞) < bar.2)
    (h : ∀ r s : ℕ, r ≤ s → (M1.filter (fun bar => bar.1 ≤ r ∧ (s : ℕ∞) < bar.2)).card
          = (M2.filter (fun bar => bar.1 ≤ r ∧ (s : ℕ∞) < bar.2)).card) : M1 = M2 := by
  have hG : ∀ r s : ℕ, r ≤ s → M1.countP (fun bar => bar.1 ≤ r ∧ (s : ℕ∞) < bar.2)
      = M2.countP (fun bar => bar.1 ≤ r ∧ (s : ℕ∞) < bar.2) := by
    intro r s hrs; rw [Multiset.countP_eq_card_filter, Multiset.countP_eq_card_filter]
    exact h r s hrs
  -- the count of bars born exactly at b and alive after s
  have hsplitG : ∀ (M : Multiset (ℕ × ℕ∞)) (b s : ℕ),
      M.countP (fun bar => bar.1 ≤ b + 1 ∧ (s : ℕ∞) < bar.2)
        = M.countP (fun bar => bar.1 = b + 1 ∧ (s : ℕ∞) < bar.2)
          + M.countP (fun bar => bar.1 ≤ b ∧ (s : ℕ∞) < bar.2) := by
    intro M b s
    rw [countP_split _ (fun bar : ℕ × ℕ∞ => bar.1 = b + 1) M]
    congr 1
    · exact Multiset.countP_congr rfl fun x _ => by
        apply propext; constructor
        · rintro ⟨⟨-, h⟩, h'⟩; exact ⟨h', h⟩
        · rintro ⟨h', h⟩; exact ⟨⟨h'.le, h⟩, h'⟩
    · exact Multiset.countP_congr rfl fun x _ => by
        apply propext; constructor
        · rintro ⟨⟨h1, h⟩, h'⟩; exact ⟨by omega, h⟩
        · rintro ⟨h1, h⟩; exact ⟨⟨by omega, h⟩, by omega⟩
  have hH : ∀ b s : ℕ, b ≤ s → M1.countP (fun bar => bar.1 = b ∧ (s : ℕ∞) < bar.2)
      = M2.countP (fun bar => bar.1 = b ∧ (s : ℕ∞) < bar.2) := by
    intro b s hbs
    rcases b with _ | b
    · have e : ∀ M : Multiset (ℕ × ℕ∞), M.countP (fun bar => bar.1 = 0 ∧ (s : ℕ∞) < bar.2)
          = M.countP (fun bar => bar.1 ≤ 0 ∧ (s : ℕ∞) < bar.2) := fun M =>
        Multiset.countP_congr rfl fun x _ => by simp
      rw [e, e]; exact hG 0 s hbs
    · have a1 := hsplitG M1 b s
      have a2 := hsplitG M2 b s
      have g1 := hG (b + 1) s hbs
      have g2 := hG b s (by omega)
      omega
  apply Multiset.ext'
  rintro ⟨b, d⟩
  induction d using ENat.recTopCoe with
  | top =>
    let S := b + (M1.map (fun x => x.2.toNat)).sum + (M2.map (fun x => x.2.toNat)).sum
    have e : ∀ M : Multiset (ℕ × ℕ∞), (∀ x ∈ M, x.2.toNat ≤ S) →
        M.count (b, ⊤) = M.countP (fun bar => bar.1 = b ∧ (S : ℕ∞) < bar.2) := by
      intro M hM
      rw [Multiset.count]
      apply Multiset.countP_congr rfl
      intro x hx
      obtain ⟨x1, x2⟩ := x
      apply propext
      induction x2 using ENat.recTopCoe with
      | top => simp [eq_comm]
      | coe n =>
        have := hM _ hx
        simp only [ENat.toNat_natCast] at this
        simp only [Prod.mk.injEq, ENat.top_ne_natCast, and_false, false_iff, not_and, Nat.cast_lt]
        intro _; omega
    rw [e M1, e M2]
    · exact hH b S (by omega)
    · intro x hx
      have := Multiset.le_sum_of_mem (Multiset.mem_map_of_mem (fun x => x.2.toNat) hx)
      omega
    · intro x hx
      have := Multiset.le_sum_of_mem (Multiset.mem_map_of_mem (fun x => x.2.toNat) hx)
      omega
  | coe e =>
    by_cases hbe : e ≤ b
    · have z : ∀ M : Multiset (ℕ × ℕ∞), (∀ bar ∈ M, (bar.1 : ℕ∞) < bar.2) →
          M.count (b, (e : ℕ∞)) = 0 := by
        intro M hM
        rw [Multiset.count_eq_zero]
        intro hmem
        have := hM _ hmem
        simp only [Nat.cast_lt] at this
        omega
      rw [z M1 h1, z M2 h2]
    · obtain ⟨e', rfl⟩ : ∃ e', e = e' + 1 := ⟨e - 1, by omega⟩
      have sp : ∀ M : Multiset (ℕ × ℕ∞),
          M.countP (fun bar => bar.1 = b ∧ (e' : ℕ∞) < bar.2)
            = M.count (b, ((e' + 1 : ℕ) : ℕ∞))
              + M.countP (fun bar => bar.1 = b ∧ ((e' + 1 : ℕ) : ℕ∞) < bar.2) := by
        intro M
        rw [countP_split _ (fun bar : ℕ × ℕ∞ => bar.2 = ((e' + 1 : ℕ) : ℕ∞)) M, Multiset.count]
        congr 1
        · exact Multiset.countP_congr rfl fun x _ => by
            obtain ⟨x1, x2⟩ := x
            apply propext
            induction x2 using ENat.recTopCoe with
            | top =>
              simp only [ENat.top_ne_natCast, ENat.natCast_ne_top, ENat.natCast_lt_top, Prod.mk.injEq,
                and_false, and_true, not_false_eq_true]
            | coe n =>
              simp only [Prod.mk.injEq, Nat.cast_lt, Nat.cast_inj]
              omega
        · exact Multiset.countP_congr rfl fun x _ => by
            obtain ⟨x1, x2⟩ := x
            apply propext
            induction x2 using ENat.recTopCoe with
            | top =>
              simp only [ENat.top_ne_natCast, ENat.natCast_ne_top, ENat.natCast_lt_top, Prod.mk.injEq,
                and_false, and_true, not_false_eq_true]
            | coe n =>
              simp only [Nat.cast_lt, Nat.cast_inj]
              omega
      have a1 := sp M1
      have a2 := sp M2
      have g1 := hH b e' (by omega)
      have g2 := hH b (e' + 1) (by omega)
      omega


/-- Membership in the chains. -/
lemma mem_chains {K : Finset (Finset V)} {j : ℕ} {x : Finset V → 𝕜} :
    x ∈ chains 𝕜 K j ↔ ∀ s, s ∉ simplices K j → x s = 0 := by
  simp [chains, Submodule.mem_pi]

/-- The boundary map as a matrix. -/
lemma bd_eq : bd 𝕜 = Matrix.mulVecLin (Matrix.of fun t s => (bdCoeff s t : 𝕜) :
    Matrix (Finset V) (Finset V) 𝕜) := rfl

/-- The boundary map, entry by entry. -/
lemma bd_apply (x : Finset V → 𝕜) (t : Finset V) :
    bd 𝕜 x t = ∑ s, (bdCoeff s t : 𝕜) * x s := by
  rw [bd_eq, Matrix.mulVecLin_apply]
  simp [Matrix.mulVec, dotProduct]

/-- A nonzero boundary coefficient comes from dropping one corner. -/
lemma bdCoeff_ne_zero {s t : Finset V} (h : bdCoeff s t ≠ 0) : ∃ v ∈ s, s.erase v = t := by
  by_contra hc
  push_neg at hc
  exact h (Finset.sum_eq_zero fun v hv => if_neg (hc v hv))

/-- Corners below `w` after removing a smaller corner `v`. -/
lemma card_filter_erase_lt {σ : Finset V} {v w : V} (hv : v ∈ σ) (hvw : v < w) :
    ((σ.erase v).filter (· < w)).card + 1 = (σ.filter (· < w)).card := by
  rw [Finset.filter_erase, Finset.card_erase_add_one]
  exact Finset.mem_filter.mpr ⟨hv, hvw⟩

/-- Corners below `v` after removing a larger corner `w`. -/
lemma card_filter_erase_gt {σ : Finset V} {v w : V} (hvw : v < w) :
    ((σ.erase w).filter (· < v)).card = (σ.filter (· < v)).card := by
  rw [Finset.filter_erase, Finset.erase_eq_of_notMem]
  simp [not_lt.mpr hvw.le]

/-- The two ways of dropping two corners cancel. -/
lemma bd_pair_cancel (σ t : Finset V) {v w : V} (hv : v ∈ σ) (hvw : v < w) :
    ((if (σ.erase v).erase w = t then (-1 : ℤ) ^ ((σ.erase v).filter (· < w)).card else 0)
        * (-1) ^ (σ.filter (· < v)).card)
      + ((if (σ.erase w).erase v = t then (-1 : ℤ) ^ ((σ.erase w).filter (· < v)).card else 0)
        * (-1) ^ (σ.filter (· < w)).card) = 0 := by
  rw [Finset.erase_right_comm (s := σ) (a := w) (b := v)]
  split_ifs
  · rw [card_filter_erase_gt hvw]
    have h1 := card_filter_erase_lt hv hvw
    obtain ⟨n, hn⟩ : ∃ n, (σ.filter (· < w)).card = n + 1 := ⟨_, h1.symm⟩
    rw [hn] at h1 ⊢
    rw [show ((σ.erase v).filter (· < w)).card = n by omega]
    ring
  · simp

/-- The boundary of a boundary is zero, coefficient by coefficient. -/
lemma bdCoeff_bdCoeff (σ t : Finset V) : ∑ u : Finset V, bdCoeff u t * bdCoeff σ u = 0 := by
  have hsplit : ∀ (f : V → ℤ) (v : V), ∑ w ∈ σ.erase v, f w = ∑ w ∈ σ, if w ≠ v then f w else 0 :=
    fun f v => by rw [← Finset.sum_filter, Finset.filter_ne']
  let G : V → V → ℤ := fun v w =>
    if w ≠ v then
      (if (σ.erase v).erase w = t then (-1 : ℤ) ^ ((σ.erase v).filter (· < w)).card else 0)
        * (-1) ^ (σ.filter (· < v)).card
    else 0
  have step : ∑ u : Finset V, bdCoeff u t * bdCoeff σ u = ∑ p ∈ σ ×ˢ σ, G p.1 p.2 := by
    rw [Finset.sum_product]
    calc ∑ u : Finset V, bdCoeff u t * bdCoeff σ u
        = ∑ u : Finset V, ∑ v ∈ σ,
            (if σ.erase v = u then bdCoeff u t * (-1) ^ (σ.filter (· < v)).card else 0) := by
          refine Finset.sum_congr rfl fun u _ => ?_
          rw [show bdCoeff σ u = ∑ v ∈ σ,
            if σ.erase v = u then (-1) ^ (σ.filter (· < v)).card else 0 from rfl,
            Finset.mul_sum]
          refine Finset.sum_congr rfl fun v _ => ?_
          split_ifs <;> simp
      _ = ∑ v ∈ σ, ∑ u : Finset V,
            (if σ.erase v = u then bdCoeff u t * (-1) ^ (σ.filter (· < v)).card else 0) :=
          Finset.sum_comm
      _ = ∑ v ∈ σ, bdCoeff (σ.erase v) t * (-1) ^ (σ.filter (· < v)).card := by
          refine Finset.sum_congr rfl fun v _ => ?_
          rw [Finset.sum_ite_eq]
          simp
      _ = ∑ v ∈ σ, ∑ w ∈ σ, G v w := by
          refine Finset.sum_congr rfl fun v _ => ?_
          rw [show bdCoeff (σ.erase v) t = ∑ w ∈ σ.erase v,
            if (σ.erase v).erase w = t then (-1) ^ ((σ.erase v).filter (· < w)).card else 0
            from rfl, hsplit, Finset.sum_mul]
          refine Finset.sum_congr rfl fun w _ => ?_
          simp only [G]
          split_ifs <;> simp
  rw [step]
  refine Finset.sum_involution (fun p _ => (p.2, p.1)) ?_ ?_ ?_ ?_
  · rintro ⟨v, w⟩ hp
    simp only [Finset.mem_product] at hp
    rcases lt_trichotomy v w with h | h | h
    · simp only [G, if_pos h.ne', if_pos h.ne]
      exact bd_pair_cancel σ t hp.1 h
    · subst h; simp [G]
    · simp only [G, if_pos h.ne', if_pos h.ne]
      rw [add_comm]
      exact bd_pair_cancel σ t hp.2 h
  · rintro ⟨v, w⟩ _ hne heq
    simp only [Prod.mk.injEq] at heq
    apply hne
    simp only [G, heq.1, ne_eq, not_true_eq_false, if_false]
  · rintro ⟨v, w⟩ hp
    simp only [Finset.mem_product] at hp ⊢
    exact ⟨hp.2, hp.1⟩
  · rintro ⟨v, w⟩ _
    rfl

/-- `∂ ∘ ∂ = 0`. -/
lemma bd_bd (x : Finset V → 𝕜) : bd 𝕜 (bd 𝕜 x) = 0 := by
  have hA : (Matrix.of fun t s => (bdCoeff s t : 𝕜) : Matrix (Finset V) (Finset V) 𝕜)
      * (Matrix.of fun t s => (bdCoeff s t : 𝕜)) = 0 := by
    ext t s
    simp only [Matrix.mul_apply, Matrix.zero_apply, Matrix.of_apply]
    have := congrArg (fun z : ℤ => (z : 𝕜)) (bdCoeff_bdCoeff s t)
    push_cast at this
    exact this
  rw [bd_eq, Matrix.mulVecLin_apply, Matrix.mulVecLin_apply, Matrix.mulVec_mulVec, hA,
    Matrix.zero_mulVec]

/-- In a complex, the boundary of a (j+1)-chain is a j-chain. -/
lemma bd_mem_chains {K : Finset (Finset V)} (hK : IsComplex K) {j : ℕ} {x : Finset V → 𝕜}
    (hx : x ∈ chains 𝕜 K (j + 1)) : bd 𝕜 x ∈ chains 𝕜 K j := by
  rw [mem_chains] at hx ⊢
  intro t ht
  rw [bd_apply]
  refine Finset.sum_eq_zero fun s _ => ?_
  by_cases hs : s ∈ simplices K (j + 1)
  · by_cases hc : bdCoeff s t = 0
    · simp [hc]
    · exfalso
      obtain ⟨v, hv, rfl⟩ := bdCoeff_ne_zero hc
      apply ht
      simp only [simplices, Finset.mem_filter] at hs ⊢
      have hcard : (s.erase v).card = j + 1 := by
        rw [Finset.card_erase_of_mem hv, hs.2]; rfl
      refine ⟨hK s hs.1 _ (Finset.erase_subset v s) ?_, hcard⟩
      rw [← Finset.card_pos, hcard]; omega
  · simp [hx s hs]

lemma chains_mono {K L : Finset (Finset V)} (h : K ⊆ L) (j : ℕ) :
    chains 𝕜 K j ≤ chains 𝕜 L j := by
  intro x hx
  rw [mem_chains] at hx ⊢
  intro s hs
  apply hx
  intro hs'
  apply hs
  simp only [simplices, Finset.mem_filter] at hs' ⊢
  exact ⟨h hs'.1, hs'.2⟩

lemma cycles_mono {K L : Finset (Finset V)} (h : K ⊆ L) (j : ℕ) :
    cycles 𝕜 K j ≤ cycles 𝕜 L j := by
  rcases j with _ | j
  · exact chains_mono 𝕜 h 0
  · exact inf_le_inf_right _ (chains_mono 𝕜 h _)

lemma boundaries_mono {K L : Finset (Finset V)} (h : K ⊆ L) (j : ℕ) :
    boundaries 𝕜 K j ≤ boundaries 𝕜 L j :=
  Submodule.map_mono (chains_mono 𝕜 h _)

lemma chains_inf_ker_le_cycles (K : Finset (Finset V)) (j : ℕ) :
    chains 𝕜 K j ⊓ LinearMap.ker (bd 𝕜) ≤ cycles 𝕜 K j := by
  rcases j with _ | j
  · exact inf_le_left
  · exact le_rfl

/-- Persistent Betti number as a difference of dimensions. -/
lemma persistentBetti_add (K L : Finset (Finset V)) (j : ℕ) :
    persistentBetti 𝕜 K L j + Module.finrank 𝕜 ↥(cycles 𝕜 K j ⊓ boundaries 𝕜 L j)
      = Module.finrank 𝕜 ↥(cycles 𝕜 K j) := by
  unfold persistentBetti
  rw [← Submodule.map_comap_subtype, Submodule.finrank_map_subtype_eq]
  exact Submodule.finrank_quotient_add_finrank _

/-- Adding a vector outside a subspace raises the dimension by one. -/
lemma finrank_sup_span_singleton {W : Type*} [AddCommGroup W] [Module 𝕜 W]
    [Module.Finite 𝕜 W] (p : Submodule 𝕜 W) {w : W} (hw : w ∉ p) :
    Module.finrank 𝕜 ↥(p ⊔ Submodule.span 𝕜 {w}) = Module.finrank 𝕜 ↥p + 1 := by
  have hw0 : w ≠ 0 := fun h => hw (h ▸ p.zero_mem)
  have h1 := Submodule.finrank_sup_add_finrank_inf_eq p (Submodule.span 𝕜 {w})
  rw [disjoint_iff.mp (Submodule.disjoint_span_singleton_of_notMem hw), finrank_bot,
    finrank_span_singleton hw0] at h1
  omega

#print axioms finrank_inf_quad
#print axioms sum_Ico_telescope
#print axioms countP_split
#print axioms countP_replicate'
#print axioms barcode_exists_of_subspaces
#print axioms barcode_unique_of_counts
#print axioms mem_chains
#print axioms bd_eq
#print axioms bd_apply
#print axioms bdCoeff_ne_zero
#print axioms card_filter_erase_lt
#print axioms card_filter_erase_gt
#print axioms bd_pair_cancel
#print axioms bdCoeff_bdCoeff
#print axioms bd_bd
#print axioms bd_mem_chains
#print axioms chains_mono
#print axioms cycles_mono
#print axioms boundaries_mono
#print axioms chains_inf_ker_le_cycles
#print axioms persistentBetti_add
#print axioms finrank_sup_span_singleton

/-- **Structure theorem for persistence, as the barcode formula.** Over a field, let
`K_0 ⊆ K_1 ⊆ K_2 ⊆ ...` be a filtration: every stage is a simplicial complex, stages only grow,
and the corners come from a finite set, so the filtration is finite. Then for each dimension k
there is one and only one finite list of bars `[b, d)`, with `b < d` and `d = ⊤` for a hole that
never dies, such that for all stages `r ≤ s` the number of k-holes present at `r` that are still
holes at `s` equals the number of bars with `b ≤ r` and `s < d`. -/
theorem barcode_exists_unique (𝕜 : Type*) [Field 𝕜] (F : ℕ → Finset (Finset V))
    (hF : ∀ i, IsComplex (F i)) (hmono : Monotone F) (k : ℕ) :
    ∃! M : Multiset (ℕ × ℕ∞), (∀ bar ∈ M, (bar.1 : ℕ∞) < bar.2) ∧
      ∀ r s : ℕ, r ≤ s →
        persistentBetti 𝕜 (F r) (F s) k
          = (M.filter (fun bar => bar.1 ≤ r ∧ (s : ℕ∞) < bar.2)).card := by
  obtain ⟨M, hM1, hM2⟩ := barcode_exists_of_subspaces (fun r => cycles 𝕜 (F r) k)
    (fun s => boundaries 𝕜 (F s) k) (fun a b hab => cycles_mono 𝕜 (hmono hab) k)
    (fun a b hab => boundaries_mono 𝕜 (hmono hab) k)
  refine ⟨M, ⟨hM1, fun r s hrs => ?_⟩, fun M' hM' => ?_⟩
  · have h1 := hM2 r s hrs
    have h2 := persistentBetti_add 𝕜 (F r) (F s) k
    omega
  · refine barcode_unique_of_counts M' M hM'.1 hM1 (fun r s hrs => ?_)
    rw [← hM'.2 r s hrs]
    have h1 := hM2 r s hrs
    have h2 := persistentBetti_add 𝕜 (F r) (F s) k
    omega

/-- **One simplex, one change.** Add to a complex `K` one new (k+1)-simplex `σ` whose faces are
already in `K`. Then exactly one of two things happens: either `β_{k+1}` rises by 1 and `β_k` is
unchanged (a birth), or `β_k` falls by 1 and `β_{k+1}` is unchanged (a death). -/
theorem add_simplex_birth_or_death (𝕜 : Type*) [Field 𝕜] (K : Finset (Finset V))
    (hK : IsComplex K) (σ : Finset V) (hσ : σ ∉ K) (hσK : IsComplex (insert σ K)) (k : ℕ)
    (hcard : σ.card = k + 2) :
    (betti 𝕜 (insert σ K) (k + 1) = betti 𝕜 K (k + 1) + 1 ∧
        betti 𝕜 (insert σ K) k = betti 𝕜 K k) ∨
      (betti 𝕜 (insert σ K) k + 1 = betti 𝕜 K k ∧
        betti 𝕜 (insert σ K) (k + 1) = betti 𝕜 K (k + 1)) := by
  classical
  set K' := insert σ K with hK'
  have hsimp_ne : ∀ j, j ≠ k + 1 → simplices K' j = simplices K j := by
    intro j hj
    simp only [simplices, hK', Finset.filter_insert]
    rw [if_neg (by omega)]
  have hsimp_eq : simplices K' (k + 1) = insert σ (simplices K (k + 1)) := by
    simp only [simplices, hK', Finset.filter_insert]
    rw [if_pos hcard]
  have hchains_ne : ∀ j, j ≠ k + 1 → chains 𝕜 K' j = chains 𝕜 K j := by
    intro j hj; unfold chains; rw [hsimp_ne j hj]
  have hZk : cycles 𝕜 K' k = cycles 𝕜 K k := by
    rcases k with _ | k
    · exact hchains_ne 0 (by omega)
    · show chains 𝕜 K' (k + 1) ⊓ _ = chains 𝕜 K (k + 1) ⊓ _
      rw [hchains_ne (k + 1) (by omega)]
  have hB1 : boundaries 𝕜 K' (k + 1) = boundaries 𝕜 K (k + 1) := by
    unfold boundaries; rw [hchains_ne (k + 1 + 1) (by omega)]
  set C := chains 𝕜 K (k + 1) with hCdef
  set C' := chains 𝕜 K' (k + 1) with hC'def
  set e : Finset V → 𝕜 := Pi.single σ 1 with hedef
  set c := bd 𝕜 e with hcdef
  have hσK' : σ ∈ simplices K' (k + 1) := by rw [hsimp_eq]; exact Finset.mem_insert_self _ _
  have hσnot : σ ∉ simplices K (k + 1) := fun h => hσ (Finset.mem_filter.mp h).1
  have he_mem : e ∈ C' := by
    rw [hC'def, mem_chains]; intro s hs
    have : s ≠ σ := fun h => hs (h ▸ hσK')
    simp [e, Pi.single_apply, this]
  have he_not : e ∉ C := by
    rw [hCdef, mem_chains]; intro h
    have := h σ hσnot; simp [e] at this
  have hCC' : C ≤ C' := chains_mono 𝕜 (Finset.subset_insert σ K) (k + 1)
  have hdecomp : ∀ y ∈ C', ∃ y0 ∈ C, y = y0 + y σ • e := by
    intro y hy
    refine ⟨y - y σ • e, ?_, by abel⟩
    rw [hC'def, mem_chains] at hy
    rw [hCdef, mem_chains]
    intro s hs
    by_cases hsσ : s = σ
    · subst hsσ; simp [e]
    · have : s ∉ simplices K' (k + 1) := by rw [hsimp_eq, Finset.mem_insert]; tauto
      simp [hy s this, e, Pi.single_apply, hsσ]
  have hC'eq : C' = C ⊔ Submodule.span 𝕜 {e} := by
    apply le_antisymm
    · intro y hy
      obtain ⟨y0, hy0, hy⟩ := hdecomp y hy
      rw [hy]
      exact Submodule.add_mem_sup hy0
        (Submodule.smul_mem _ _ (Submodule.mem_span_singleton_self e))
    · exact sup_le hCC' ((Submodule.span_singleton_le_iff_mem _ _).mpr he_mem)
  have hBk : boundaries 𝕜 K' k = boundaries 𝕜 K k ⊔ Submodule.span 𝕜 {c} := by
    show C'.map (bd 𝕜) = C.map (bd 𝕜) ⊔ _
    rw [hC'eq, Submodule.map_sup, Submodule.map_span, Set.image_singleton]
  have hB1C : boundaries 𝕜 K (k + 1) ≤ C := by
    rw [boundaries, Submodule.map_le_iff_le_comap]
    intro x hx; exact bd_mem_chains 𝕜 hK hx
  have hc_cyc : c ∈ cycles 𝕜 K k := by
    apply chains_inf_ker_le_cycles
    rw [Submodule.mem_inf]
    refine ⟨?_, ?_⟩
    · rw [← hchains_ne k (by omega)]; exact bd_mem_chains 𝕜 hσK he_mem
    · rw [LinearMap.mem_ker]; exact bd_bd 𝕜 e
  have hZ1' : cycles 𝕜 K' (k + 1) = C' ⊓ LinearMap.ker (bd 𝕜) := rfl
  have hZ1 : cycles 𝕜 K (k + 1) = C ⊓ LinearMap.ker (bd 𝕜) := rfl
  have hZB1 : cycles 𝕜 K' (k + 1) ⊓ boundaries 𝕜 K' (k + 1)
      = cycles 𝕜 K (k + 1) ⊓ boundaries 𝕜 K (k + 1) := by
    rw [hZ1', hZ1, hB1]
    apply le_antisymm
    · exact le_inf (le_inf (inf_le_right.trans hB1C) (inf_le_left.trans inf_le_right))
        inf_le_right
    · exact inf_le_inf_right _ (inf_le_inf_right _ hCC')
  have pK1 := persistentBetti_add 𝕜 K K (k + 1)
  have pK'1 := persistentBetti_add 𝕜 K' K' (k + 1)
  have pK := persistentBetti_add 𝕜 K K k
  have pK' := persistentBetti_add 𝕜 K' K' k
  unfold betti
  rw [hZB1] at pK'1
  rw [hZk] at pK'
  by_cases hcB : c ∈ boundaries 𝕜 K k
  · left
    have hBeq : boundaries 𝕜 K' k = boundaries 𝕜 K k := by
      rw [hBk]; exact sup_eq_left.mpr ((Submodule.span_singleton_le_iff_mem _ _).mpr hcB)
    obtain ⟨x, hxC, hxc⟩ := Submodule.mem_map.mp hcB
    have hw_not : e - x ∉ cycles 𝕜 K (k + 1) := by
      intro h
      rw [hZ1, Submodule.mem_inf] at h
      apply he_not
      have := C.add_mem h.1 hxC
      simpa using this
    have hZeq : cycles 𝕜 K' (k + 1) = cycles 𝕜 K (k + 1) ⊔ Submodule.span 𝕜 {e - x} := by
      apply le_antisymm
      · intro y hy
        rw [hZ1', Submodule.mem_inf] at hy
        obtain ⟨hyC', hyker⟩ := hy
        obtain ⟨y0, hy0, hy⟩ := hdecomp y hyC'
        have hmem : y - y σ • (e - x) ∈ cycles 𝕜 K (k + 1) := by
          rw [hZ1, Submodule.mem_inf]
          refine ⟨?_, ?_⟩
          · have : y - y σ • (e - x) = y0 + y σ • x := by
              calc y - y σ • (e - x) = (y0 + y σ • e) - y σ • (e - x) := by rw [← hy]
                _ = y0 + y σ • x := by module
            rw [this]; exact C.add_mem hy0 (C.smul_mem _ hxC)
          · rw [LinearMap.mem_ker] at hyker ⊢
            rw [map_sub, map_smul, map_sub, hyker, hxc, ← hcdef]; simp
        have : y = (y - y σ • (e - x)) + y σ • (e - x) := by abel
        rw [this]
        exact Submodule.add_mem_sup hmem
          (Submodule.smul_mem _ _ (Submodule.mem_span_singleton_self _))
      · apply sup_le
        · rw [hZ1, hZ1']; exact inf_le_inf_right _ hCC'
        · rw [Submodule.span_singleton_le_iff_mem, hZ1', Submodule.mem_inf]
          refine ⟨C'.sub_mem he_mem (hCC' hxC), ?_⟩
          rw [LinearMap.mem_ker, map_sub, hxc, ← hcdef, sub_self]
    have hdim := finrank_sup_span_singleton 𝕜 (cycles 𝕜 K (k + 1)) hw_not
    rw [← hZeq] at hdim
    rw [hBeq] at pK'
    constructor <;> omega
  · right
    have hZeq : cycles 𝕜 K' (k + 1) = cycles 𝕜 K (k + 1) := by
      apply le_antisymm
      · intro y hy
        rw [hZ1', Submodule.mem_inf] at hy
        obtain ⟨hyC', hyker⟩ := hy
        obtain ⟨y0, hy0, hy⟩ := hdecomp y hyC'
        by_cases ha : y σ = 0
        · rw [hZ1, Submodule.mem_inf]
          refine ⟨?_, hyker⟩
          rw [hy, ha, zero_smul, add_zero]; exact hy0
        · exfalso; apply hcB
          rw [LinearMap.mem_ker, hy, map_add, map_smul] at hyker
          refine Submodule.mem_map.mpr ⟨-(y σ)⁻¹ • y0, C.smul_mem _ hy0, ?_⟩
          rw [map_smul]
          have : bd 𝕜 y0 = -(y σ • c) := eq_neg_of_add_eq_zero_left hyker
          rw [this, smul_neg, smul_smul, neg_mul, inv_mul_cancel₀ ha, neg_smul, one_smul,
            neg_neg]
      · rw [hZ1, hZ1']; exact inf_le_inf_right _ hCC'
    rw [hZeq] at pK'1
    have hle : Submodule.span 𝕜 {c} ≤ cycles 𝕜 K k :=
      (Submodule.span_singleton_le_iff_mem _ _).mpr hc_cyc
    have hnot : c ∉ cycles 𝕜 K k ⊓ boundaries 𝕜 K k := fun h => hcB h.2
    have heq : cycles 𝕜 K k ⊓ (boundaries 𝕜 K k ⊔ Submodule.span 𝕜 {c})
        = cycles 𝕜 K k ⊓ boundaries 𝕜 K k ⊔ Submodule.span 𝕜 {c} := by
      calc cycles 𝕜 K k ⊓ (boundaries 𝕜 K k ⊔ Submodule.span 𝕜 {c})
          = (Submodule.span 𝕜 {c} ⊔ boundaries 𝕜 K k) ⊓ cycles 𝕜 K k := by
            rw [inf_comm, sup_comm]
        _ = Submodule.span 𝕜 {c} ⊔ boundaries 𝕜 K k ⊓ cycles 𝕜 K k :=
            sup_inf_assoc_of_le _ hle
        _ = cycles 𝕜 K k ⊓ boundaries 𝕜 K k ⊔ Submodule.span 𝕜 {c} := by
            rw [sup_comm, inf_comm]
    have hdim := finrank_sup_span_singleton 𝕜 (cycles 𝕜 K k ⊓ boundaries 𝕜 K k) hnot
    rw [hBk, heq, hdim] at pK'
    constructor <;> omega

end Homology

/-! ### The card's worked examples -/

/-- The simulated daily returns in percent, repeating every six days. -/
def returns : Fin 6 → ℤ := ![1, 2, 1, -1, -2, -1]

/-- The m-day window starting on day t, wrapping round. -/
def window (m : ℕ) (t : Fin 6) : Fin m → ℤ :=
  fun j => returns ⟨(t.val + j.val) % 6, Nat.mod_lt _ (by decide)⟩

/-- The squared straight-line distance between two windows. -/
def sqDist {m : ℕ} (p q : Fin m → ℤ) : ℤ :=
  ∑ j, (p j - q j) ^ 2

-- the six three-day windows (1,2,1) (2,1,-1) (1,-1,-2) (-1,-2,-1) (-2,-1,1) (-1,1,2)
example : window 3 0 = ![1, 2, 1] ∧ window 3 1 = ![2, 1, -1] ∧ window 3 2 = ![1, -1, -2] ∧
    window 3 3 = ![-1, -2, -1] ∧ window 3 4 = ![-2, -1, 1] ∧ window 3 5 = ![-1, 1, 2] := by
  decide

-- neighbours 1 + 1 + 4 = 6, two apart 0 + 9 + 9 = 18, opposite 4 + 16 + 4 = 24
example : sqDist (window 3 0) (window 3 1) = 6 ∧ sqDist (window 3 0) (window 3 2) = 18 ∧
    sqDist (window 3 0) (window 3 3) = 24 := by
  decide

-- only three distances occur: 6 edges at squared distance 6, 6 at 18, 3 at 24, 15 in all
example :
    ((univ : Finset (Fin 6 × Fin 6)).filter
        (fun p => p.1 < p.2 ∧ sqDist (window 3 p.1) (window 3 p.2) = 6)).card = 6 ∧
    ((univ : Finset (Fin 6 × Fin 6)).filter
        (fun p => p.1 < p.2 ∧ sqDist (window 3 p.1) (window 3 p.2) = 18)).card = 6 ∧
    ((univ : Finset (Fin 6 × Fin 6)).filter
        (fun p => p.1 < p.2 ∧ sqDist (window 3 p.1) (window 3 p.2) = 24)).card = 3 ∧
    ((univ : Finset (Fin 6 × Fin 6)).filter (fun p => p.1 < p.2)).card = 15 := by
  decide

-- over ℤ mod 2, ∂([0,1,2] + [2,3,4] + [0,4,5] + [0,2,4]) = 01 + 12 + 23 + 34 + 45 + 05:
-- the diagonals 02, 24, 04 appear twice and cancel
example : ∀ e : Finset (Fin 6), e.card = 2 →
    ((bdCoeff {0, 1, 2} e + bdCoeff {2, 3, 4} e + bdCoeff {0, 4, 5} e + bdCoeff {0, 2, 4} e : ℤ)
        : ZMod 2)
      = if e ∈ ({{0, 1}, {1, 2}, {2, 3}, {3, 4}, {4, 5}, {0, 5}} : Finset (Finset (Fin 6)))
        then 1 else 0 := by
  decide

-- loops after the sides: edges - corners + pieces = 6 - 6 + 1 = 1;
-- edges only, no triangles: 15 - 6 + 1 = 10 loop bars that never end
example : (6 : ℤ) - 6 + 1 = 1 ∧ (15 : ℤ) - 6 + 1 = 10 := by norm_num

-- two-day windows: sides of squared length 2, 5, 5, 2, 5, 5, and the short chord w2 w5 of 8
example : sqDist (window 2 0) (window 2 1) = 2 ∧ sqDist (window 2 1) (window 2 2) = 5 ∧
    sqDist (window 2 2) (window 2 3) = 5 ∧ sqDist (window 2 3) (window 2 4) = 2 ∧
    sqDist (window 2 4) (window 2 5) = 5 ∧ sqDist (window 2 5) (window 2 0) = 5 ∧
    sqDist (window 2 2) (window 2 5) = 8 := by
  decide

-- the barcode read back, stages 0: below 1.2247, 1: up to 2.1213, 2: up to 2.4495, 3: beyond.
-- H1 = {[1, 2)}: β_1 = 1 at r = 1.5, persists to s = 2 (stage 1), gone by s = 2.5 (stage 3);
-- H0 = five bars [0, 1) and one [0, ⊤): 6 pieces at stage 0, 1 piece at stage 1
example :
    (({(1, 2)} : Multiset (ℕ × ℕ∞)).filter (fun bar => bar.1 ≤ 1 ∧ ((1 : ℕ) : ℕ∞) < bar.2)).card
      = 1 ∧
    (({(1, 2)} : Multiset (ℕ × ℕ∞)).filter (fun bar => bar.1 ≤ 1 ∧ ((3 : ℕ) : ℕ∞) < bar.2)).card
      = 0 ∧
    ((Multiset.replicate 5 ((0 : ℕ), (1 : ℕ∞)) + {(0, ⊤)}).filter
        (fun bar => bar.1 ≤ 0 ∧ ((0 : ℕ) : ℕ∞) < bar.2)).card = 6 ∧
    ((Multiset.replicate 5 ((0 : ℕ), (1 : ℕ∞)) + {(0, ⊤)}).filter
        (fun bar => bar.1 ≤ 1 ∧ ((1 : ℕ) : ℕ∞) < bar.2)).card = 1 := by
  decide

#print axioms barcode_exists_unique
#print axioms add_simplex_birth_or_death

end FiltrationsPersistentHomology
