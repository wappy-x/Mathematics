-- Hamming and Reed-Solomon: a code whose codewords sit d apart repairs any ⌊(d − 1)/2⌋ errors, Reed-Solomon codes have distance exactly n − k + 1, and no code of that size can do better.
import Mathlib.InformationTheory.Hamming
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.ZMod.Defs
import Mathlib.LinearAlgebra.Lagrange
import Mathlib.Data.Fintype.Pigeonhole
import Mathlib.Data.Fintype.Fin

open Polynomial Matrix

/-- Distance is a repair budget: if every two different codewords differ in at least `d`
places, and the word read back differs from the sent codeword `c` in at most `⌊(d − 1)/2⌋`
places, then `c` is strictly nearer the read word than every other codeword, so
"pick the nearest codeword" recovers what was sent. -/
theorem nearest_codeword_repairs_half_distance {α : Type*} [DecidableEq α] {n d : ℕ}
    (C : Set (Fin n → α))
    (hd : ∀ c₁ ∈ C, ∀ c₂ ∈ C, c₁ ≠ c₂ → d ≤ hammingDist c₁ c₂)
    {c r : Fin n → α} (hc : c ∈ C) (hr : hammingDist r c ≤ (d - 1) / 2) :
    ∀ c' ∈ C, c' ≠ c → hammingDist r c < hammingDist r c' := by
  intro c' hc' hne
  have h1 : 0 < hammingDist c c' := hammingDist_pos.mpr (Ne.symm hne)
  have h2 : d ≤ hammingDist c c' := hd c hc c' hc' (Ne.symm hne)
  have h3 := hammingDist_triangle c r c'
  have h4 : hammingDist c r = hammingDist r c := hammingDist_comm c r
  omega

/-- Reed-Solomon has distance n − k + 1: over a field, store the values of every message
polynomial of degree below `k` at `n` distinct points (`k ≤ n`). Any two different messages
give codewords that differ in at least `n − k + 1` places, and some two differ in exactly
`n − k + 1`. -/
theorem reed_solomon_min_distance {F : Type*} [Field F] [DecidableEq F] {n k : ℕ}
    (hk : 0 < k) (hkn : k ≤ n) (x : Fin n → F) (hx : Function.Injective x) :
    (∀ p q : F[X], p.degree < k → q.degree < k → p ≠ q →
        n - k + 1 ≤ hammingDist (fun i => p.eval (x i)) (fun i => q.eval (x i))) ∧
    ∃ p q : F[X], p.degree < k ∧ q.degree < k ∧ p ≠ q ∧
        hammingDist (fun i => p.eval (x i)) (fun i => q.eval (x i)) = n - k + 1 := by
  -- the set of positions where two codewords agree
  have key : ∀ p q : F[X], p.degree < k → q.degree < k → p ≠ q →
      (Finset.univ.filter (fun i => p.eval (x i) = q.eval (x i))).card ≤ k - 1 := by
    intro p q hp hq hpq
    by_contra hcon
    rw [not_le] at hcon
    set A := Finset.univ.filter (fun i => p.eval (x i) = q.eval (x i)) with hA
    have hcard : (A.image x).card = A.card := Finset.card_image_of_injective A hx
    have hkA : (k : WithBot ℕ) ≤ ((A.image x).card : WithBot ℕ) := by
      rw [hcard]; exact_mod_cast (by omega : k ≤ A.card)
    apply hpq
    refine Polynomial.eq_of_degrees_lt_of_eval_finset_eq (A.image x)
      (lt_of_lt_of_le hp hkA) (lt_of_lt_of_le hq hkA) ?_
    intro y hy
    obtain ⟨i, hi, rfl⟩ := Finset.mem_image.mp hy
    exact (Finset.mem_filter.mp hi).2
  have split : ∀ p q : F[X],
      hammingDist (fun i => p.eval (x i)) (fun i => q.eval (x i)) +
        (Finset.univ.filter (fun i => p.eval (x i) = q.eval (x i))).card = n := by
    intro p q
    unfold hammingDist
    have := Finset.card_filter_add_card_filter_not
      (s := (Finset.univ : Finset (Fin n))) (fun i => p.eval (x i) ≠ q.eval (x i))
    simp only [ne_eq, not_not, Finset.card_univ, Fintype.card_fin] at this
    exact this
  refine ⟨?_, ?_⟩
  · intro p q hp hq hpq
    have h1 := key p q hp hq hpq
    have h2 := split p q
    omega
  · classical
    let S : Finset (Fin n) := Finset.univ.filter (fun i : Fin n => (i : ℕ) < k - 1)
    let q : F[X] := ∏ i ∈ S, (X - C (x i))
    have hqmonic : q.Monic := Polynomial.monic_prod_of_monic _ _ (fun i _ => monic_X_sub_C (x i))
    have hSc : S.card = k - 1 := by
      have := Fin.card_filter_val_lt (n := n) (m := k - 1)
      simp only [S]
      rw [this]; omega
    have hqdeg : q.natDegree = k - 1 := by
      simp only [q]
      rw [Polynomial.natDegree_prod_of_monic _ _ (fun i _ => monic_X_sub_C (x i))]
      simp [hSc]
    refine ⟨0, q, ?_, ?_, ?_, ?_⟩
    · simp only [degree_zero]; exact WithBot.bot_lt_coe k
    · rw [Polynomial.degree_eq_natDegree hqmonic.ne_zero, hqdeg]
      exact_mod_cast (by omega : k - 1 < k)
    · exact (hqmonic.ne_zero).symm
    · have hagree : (Finset.univ.filter
          (fun i => (0 : F[X]).eval (x i) = q.eval (x i))) = S := by
        ext j
        simp only [Finset.mem_filter, Finset.mem_univ, true_and, eval_zero, q, S,
          Polynomial.eval_prod, eval_sub, eval_X, eval_C]
        constructor
        · intro h
          have h' := h.symm
          rw [Finset.prod_eq_zero_iff] at h'
          obtain ⟨i, hi, hzero⟩ := h'
          rw [sub_eq_zero] at hzero
          rw [hx hzero]
          exact (Finset.mem_filter.mp hi).2
        · intro hj
          symm
          rw [Finset.prod_eq_zero_iff]
          exact ⟨j, Finset.mem_filter.mpr ⟨Finset.mem_univ _, hj⟩, sub_self _⟩
      have h2 := split 0 q
      rw [hagree, hSc] at h2
      omega

/-- No code of this size does better (the Singleton bound): if a code turns `k ≥ 1` message
symbols from a finite alphabet into `n` stored symbols, and any two different messages give
codewords that differ in at least `d` places, then `d ≤ n − k + 1`. -/
theorem singleton_bound {α : Type*} [Fintype α] [DecidableEq α] [Nontrivial α] {n k d : ℕ}
    (hk : 0 < k) (enc : (Fin k → α) → (Fin n → α))
    (hd : ∀ m m', m ≠ m' → d ≤ hammingDist (enc m) (enc m')) :
    d ≤ n - k + 1 := by
  classical
  set j := min (k - 1) n with hj
  have hjn : j ≤ n := min_le_right _ _
  let f : (Fin k → α) → (Fin j → α) := fun m i => enc m ⟨i, by omega⟩
  have hα : 1 < Fintype.card α := Fintype.one_lt_card
  have hlt : Fintype.card (Fin j → α) < Fintype.card (Fin k → α) := by
    simp only [Fintype.card_fun, Fintype.card_fin]
    exact Nat.pow_lt_pow_right hα (by omega)
  obtain ⟨m, m', hne, heq⟩ := Fintype.exists_ne_map_eq_of_card_lt f hlt
  have h1 := hd m m' hne
  have hle : hammingDist (enc m) (enc m') + j ≤ n := by
    unfold hammingDist
    have hdisj : Disjoint (Finset.univ.filter (fun i : Fin n => enc m i ≠ enc m' i))
        (Finset.univ.filter (fun i : Fin n => (i : ℕ) < j)) := by
      rw [Finset.disjoint_filter]
      intro i _ hne' hij
      apply hne'
      have := congrFun heq ⟨i, hij⟩
      simpa [f] using this
    have hc := Finset.card_union_of_disjoint hdisj
    have hsub := Finset.card_le_univ
      (Finset.univ.filter (fun i : Fin n => enc m i ≠ enc m' i) ∪
        Finset.univ.filter (fun i : Fin n => (i : ℕ) < j))
    have hcj := Fin.card_filter_val_lt (n := n) (m := j)
    simp only [Fintype.card_fin] at hsub
    rw [hc] at hsub
    rw [hcj] at hsub
    have : min n j = j := min_eq_right hjn
    omega
  omega

/-! Worked numbers from the card. Positions 1 to 7 are chk1, chk2, m1, chk4, m2, m3, m4. -/

/-- The card's generator matrix G, 7 rows by 4 columns, over bits. -/
def hammingG : Matrix (Fin 7) (Fin 4) (ZMod 2) :=
  !![1, 1, 0, 1;
     1, 0, 1, 1;
     1, 0, 0, 0;
     0, 1, 1, 1;
     0, 1, 0, 0;
     0, 0, 1, 0;
     0, 0, 0, 1]

/-- The card's check matrix H, 3 rows by 7 columns: column j is j in binary, low bit on top. -/
def hammingH : Matrix (Fin 3) (Fin 7) (ZMod 2) :=
  !![1, 0, 1, 0, 1, 0, 1;
     0, 1, 1, 0, 0, 1, 1;
     0, 0, 0, 1, 1, 1, 1]

-- The nibble 4 is message bits 0, 1, 0, 0 and encodes to 1001100.
example : hammingG *ᵥ ![0, 1, 0, 0] = ![1, 0, 0, 1, 1, 0, 0] := by decide
-- H times every one of the 16 codewords is 0.
example : ∀ m : Fin 4 → ZMod 2, hammingH *ᵥ (hammingG *ᵥ m) = 0 := by decide
-- A speck flips position 6: 1001110 has syndrome bits 0, 1, 1, that is 6.
example : hammingH *ᵥ ![1, 0, 0, 1, 1, 1, 0] = ![0, 1, 1] := by decide
-- The scratch turns block 2, 1000011, into 1000101: syndrome bits 1, 1, 0, that is 3.
example : hammingG *ᵥ ![0, 0, 1, 1] = ![1, 0, 0, 0, 0, 1, 1] := by decide
example : hammingH *ᵥ ![1, 0, 0, 0, 1, 0, 1] = ![1, 1, 0] := by decide
-- "Repairing" position 3 gives 1010101, the codeword of data 1101: nibble 13.
example : hammingG *ᵥ ![1, 1, 0, 1] = ![1, 0, 1, 0, 1, 0, 1] := by decide
-- Hamming (7,4) has distance 3: different messages give codewords at least 3 apart...
example : ∀ m m' : Fin 4 → ZMod 2, m ≠ m' →
    3 ≤ hammingDist (hammingG *ᵥ m) (hammingG *ᵥ m') := by decide
-- ...and flipping positions 1, 2 and 3 of codeword 0000000 gives the codeword 1110000.
example : hammingH *ᵥ ![1, 1, 1, 0, 0, 0, 0] = 0 := by decide
-- Repair budgets: distance 3 repairs 1, distance 5 repairs 2.
example : (3 - 1) / 2 = 1 ∧ (5 - 1) / 2 = 2 := by decide
-- Perfect code: 16 codewords times 8 words in each ball is every 7-bit word.
example : 16 * (1 + 7) = 2 ^ 7 := by norm_num
-- Reed-Solomon (8,4): distance 8 − 4 + 1 = 5.
example : 8 - 4 + 1 = 5 := by norm_num
-- Mod 16 is not a field: 8x² + 8x³ is zero at all 8 points 1, 2, 4, 8, 3, 6, 12, 11.
example : ∀ x ∈ ([1, 2, 4, 8, 3, 6, 12, 11] : List (ZMod 16)), 8 * x ^ 2 + 8 * x ^ 3 = 0 := by
  decide

#print axioms nearest_codeword_repairs_half_distance
#print axioms reed_solomon_min_distance
#print axioms singleton_bound
