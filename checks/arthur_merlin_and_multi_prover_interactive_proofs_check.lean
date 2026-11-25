-- Arthur-Merlin and two provers: separated suspects win the CHSH game on at most 3 of the 4 question pairs, a network's labelled copies times its symmetries is the number of renamings, and Arthur's parity hash sends two different nonzero codes to a uniform pair of outputs.
import Mathlib.Combinatorics.SimpleGraph.Maps
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.GroupTheory.Perm.Fin
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.ZMod.Defs
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum

/-- The CHSH winning rule: with questions `x`, `y` and answers `a`, `b`, the suspects win
when `a ⊕ b = x ∧ y`. -/
def chshWin (x y a b : Bool) : Bool := (a ^^ b) == (x && y)

/-- The question pairs `(x, y)` that a fixed strategy wins: the first suspect answers
`a x`, the second answers `b y`. -/
def chshWins (a b : Bool → Bool) : Finset (Bool × Bool) :=
  Finset.univ.filter fun q => chshWin q.1 q.2 (a q.1) (b q.2) = true

/-- Separated suspects win at most 3 of the 4 question pairs: when the two suspects cannot
talk after hearing their questions and share no entanglement, each answers from a fixed
rule, the first's answer depending only on his own question `x` and the second's only on
`y`, and such a strategy wins `a ⊕ b = x ∧ y` on at most 3 of the 4 pairs `(x, y)`. -/
theorem chsh_separated_win_at_most_three (a b : Bool → Bool) :
    (chshWins a b).card ≤ 3 := by
  revert a b; decide

/-- The labelled copies of a network: every drawing obtained from it by renaming its
stations, each drawing recorded as its set of lines. -/
def labelledCopies {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V)
    [DecidableRel G.Adj] : Finset (Finset (Sym2 V)) :=
  Finset.univ.image fun σ : Equiv.Perm V => (G.map σ.toEmbedding).edgeFinset

/-- The symmetries of a network: the renamings of its stations that leave its drawing
unchanged. -/
def symmetries {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V)
    [DecidableRel G.Adj] : Finset (Equiv.Perm V) :=
  Finset.univ.filter fun σ => (G.map σ.toEmbedding).edgeFinset = G.edgeFinset

/-- Renaming by `τ * ρ` gives the same drawing as renaming by `τ` exactly when `ρ` is a
symmetry. -/
theorem map_perm_mul_eq_iff {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V)
    [DecidableRel G.Adj] (τ ρ : Equiv.Perm V) :
    (G.map (τ * ρ).toEmbedding).edgeFinset = (G.map τ.toEmbedding).edgeFinset ↔
      (G.map ρ.toEmbedding).edgeFinset = G.edgeFinset := by
  rw [SimpleGraph.edgeFinset_inj, SimpleGraph.edgeFinset_inj]
  have h : G.map (τ * ρ).toEmbedding = (G.map ρ.toEmbedding).map τ.toEmbedding := by
    rw [SimpleGraph.map_map]; rfl
  rw [h]
  exact (SimpleGraph.map_injective τ.toEmbedding).eq_iff

/-- Copies times symmetries is the number of renamings: each labelled copy of a network
arises from exactly as many renamings as the network has symmetries, so for a network on
`N` stations the number of copies times the number of symmetries is `N!` (24 for 4
stations). -/
theorem labelled_copies_mul_symmetries {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] :
    (labelledCopies G).card * (symmetries G).card = (Fintype.card V).factorial := by
  rw [← Fintype.card_perm, ← Finset.card_univ,
    Finset.card_eq_sum_card_image (fun σ : Equiv.Perm V => (G.map σ.toEmbedding).edgeFinset)
      Finset.univ]
  rw [labelledCopies, Finset.sum_const_nat]
  intro y hy
  obtain ⟨τ, -, rfl⟩ := Finset.mem_image.mp hy
  refine Finset.card_nbij' (fun σ => τ⁻¹ * σ) (fun ρ => τ * ρ) ?_ ?_ ?_ ?_
  · intro σ hσ
    simp only [symmetries, Finset.coe_filter, Finset.mem_univ, true_and] at hσ ⊢
    change _ = _ at hσ
    change _ = _
    rw [← map_perm_mul_eq_iff G τ, mul_inv_cancel_left]
    exact hσ
  · intro ρ hρ
    simp only [symmetries, Finset.coe_filter, Finset.mem_univ, true_and] at hρ ⊢
    change _ = _ at hρ
    change _ = _
    exact (map_perm_mul_eq_iff G τ ρ).mpr hρ
  · intro σ _
    simp
  · intro ρ _
    simp

theorem parity_row_exists_aux {n : ℕ} (c c' : Fin n → ZMod 2) (i j : Fin n)
    (hi : c i = 1) (hi' : c' i = 0) (hj : c' j = 1) (a b : ZMod 2) :
    ∃ r : Fin n → ZMod 2, r ⬝ᵥ c = a ∧ r ⬝ᵥ c' = b := by
  refine ⟨Pi.single i (a - b * c j) + Pi.single j b, ?_, ?_⟩
  · rw [add_dotProduct, single_dotProduct, single_dotProduct, hi]; ring
  · rw [add_dotProduct, single_dotProduct, single_dotProduct, hi', hj]; ring

theorem zmod_two_eq_one_of_ne_zero {x : ZMod 2} (h : x ≠ 0) : x = 1 := by
  revert x; decide

theorem parity_row_exists {n : ℕ} (c c' : Fin n → ZMod 2)
    (hc : c ≠ 0) (hc' : c' ≠ 0) (hne : c ≠ c') (a b : ZMod 2) :
    ∃ r : Fin n → ZMod 2, r ⬝ᵥ c = a ∧ r ⬝ᵥ c' = b := by
  obtain ⟨l, hl⟩ : ∃ l, c l ≠ c' l := by
    by_contra h; push Not at h; exact hne (funext h)
  have key : (c l = 1 ∧ c' l = 0) ∨ (c l = 0 ∧ c' l = 1) := by
    revert hl; generalize c l = x; generalize c' l = y; revert x y; decide
  rcases key with ⟨h1, h2⟩ | ⟨h1, h2⟩
  · obtain ⟨j, hj⟩ : ∃ j, c' j ≠ 0 := by
      by_contra h; push Not at h; exact hc' (funext h)
    exact parity_row_exists_aux c c' l j h1 h2 (zmod_two_eq_one_of_ne_zero hj) a b
  · obtain ⟨j, hj⟩ : ∃ j, c j ≠ 0 := by
      by_contra h; push Not at h; exact hc (funext h)
    obtain ⟨r, hr, hr'⟩ :=
      parity_row_exists_aux c' c l j h2 h1 (zmod_two_eq_one_of_ne_zero hj) b a
    exact ⟨r, hr', hr⟩

theorem parity_hash_exists {k n : ℕ} (c c' : Fin n → ZMod 2)
    (hc : c ≠ 0) (hc' : c' ≠ 0) (hne : c ≠ c') (u u' : Fin k → ZMod 2) :
    ∃ h : Matrix (Fin k) (Fin n) (ZMod 2), h.mulVec c = u ∧ h.mulVec c' = u' := by
  choose r hr hr' using fun i => parity_row_exists c c' hc hc' hne (u i) (u' i)
  exact ⟨Matrix.of r, funext hr, funext hr'⟩

theorem parity_hash_fiber_card {k n : ℕ} (c c' : Fin n → ZMod 2)
    (hc : c ≠ 0) (hc' : c' ≠ 0) (hne : c ≠ c') (u u' v v' : Fin k → ZMod 2) :
    (Finset.univ.filter fun h : Matrix (Fin k) (Fin n) (ZMod 2) =>
        h.mulVec c = u ∧ h.mulVec c' = u').card =
    (Finset.univ.filter fun h : Matrix (Fin k) (Fin n) (ZMod 2) =>
        h.mulVec c = v ∧ h.mulVec c' = v').card := by
  obtain ⟨h0, h0c, h0c'⟩ := parity_hash_exists c c' hc hc' hne (v - u) (v' - u')
  refine Finset.card_nbij' (fun h => h + h0) (fun h => h - h0) ?_ ?_ ?_ ?_
  · intro h hh
    simp only [Finset.coe_filter, Finset.mem_univ, true_and] at hh ⊢
    obtain ⟨h1, h2⟩ := hh
    refine ⟨?_, ?_⟩
    · rw [Matrix.add_mulVec, h1, h0c]; abel
    · rw [Matrix.add_mulVec, h2, h0c']; abel
  · intro h hh
    simp only [Finset.coe_filter, Finset.mem_univ, true_and] at hh ⊢
    obtain ⟨h1, h2⟩ := hh
    refine ⟨?_, ?_⟩
    · rw [Matrix.sub_mulVec, h1, h0c]; abel
    · rw [Matrix.sub_mulVec, h2, h0c']; abel
  · intro h _; simp
  · intro h _; simp

/-- Arthur's parity hash is pairwise independent: a hash with `k` rows of `n` random bits
sends each `n`-bit code `c` to the `k` parities `h *ᵥ c` (arithmetic mod 2). For two
different nonzero codes `c ≠ c'`, the pair of outputs `(h c, h c')` takes every value
`(u, u')` for the same number of hashes, one in `4 ^ k` of the `2 ^ (k n)` hashes, so the
pair is uniform over all `2 ^ k × 2 ^ k` combinations. -/
theorem parity_hash_pairwise_independent (k n : ℕ) (c c' : Fin n → ZMod 2)
    (hc : c ≠ 0) (hc' : c' ≠ 0) (hne : c ≠ c') (u u' : Fin k → ZMod 2) :
    4 ^ k * (Finset.univ.filter fun h : Matrix (Fin k) (Fin n) (ZMod 2) =>
        h.mulVec c = u ∧ h.mulVec c' = u').card = 2 ^ (k * n) := by
  have hsum := Finset.card_eq_sum_card_fiberwise
    (f := fun h : Matrix (Fin k) (Fin n) (ZMod 2) => (h.mulVec c, h.mulVec c'))
    (s := Finset.univ) (t := (Finset.univ : Finset ((Fin k → ZMod 2) × (Fin k → ZMod 2))))
    (fun _ _ => Finset.mem_coe.mpr (Finset.mem_univ _))
  have hconst : ∀ p ∈ (Finset.univ : Finset ((Fin k → ZMod 2) × (Fin k → ZMod 2))),
      (Finset.univ.filter fun h : Matrix (Fin k) (Fin n) (ZMod 2) =>
        (h.mulVec c, h.mulVec c') = p).card =
      (Finset.univ.filter fun h : Matrix (Fin k) (Fin n) (ZMod 2) =>
        h.mulVec c = u ∧ h.mulVec c' = u').card := by
    rintro ⟨v, v'⟩ -
    simp only [Prod.mk.injEq]
    exact parity_hash_fiber_card c c' hc hc' hne v v' u u'
  rw [Finset.sum_const_nat hconst, Finset.card_univ, Finset.card_univ] at hsum
  have hM : Fintype.card (Matrix (Fin k) (Fin n) (ZMod 2)) = 2 ^ (k * n) := by
    change Fintype.card (Fin k → Fin n → ZMod 2) = _
    rw [Fintype.card_fun, Fintype.card_fun, Fintype.card_fin, Fintype.card_fin,
      ZMod.card, ← pow_mul, mul_comm]
  have hP : Fintype.card ((Fin k → ZMod 2) × (Fin k → ZMod 2)) = 4 ^ k := by
    rw [Fintype.card_prod, Fintype.card_fun, Fintype.card_fin, ZMod.card, ← mul_pow]
    norm_num
  rw [hM, hP] at hsum
  exact hsum.symm

/-! ### The card's worked numbers -/

/-- The path 0-1, 1-2, 2-3. -/
def pathNet : SimpleGraph (Fin 4) := SimpleGraph.fromRel fun a b => b.val = a.val + 1
instance : DecidableRel pathNet.Adj := by unfold pathNet; infer_instance

/-- The star: hub 0 joined to 1, 2 and 3. -/
def starNet : SimpleGraph (Fin 4) := SimpleGraph.fromRel fun a b => a = 0 ∧ b ≠ 0
instance : DecidableRel starNet.Adj := by unfold starNet; infer_instance

-- 24 renamings of 4 stations
example : Fintype.card (Equiv.Perm (Fin 4)) = 24 := by decide
example : Nat.factorial 4 = 4 * 3 * 2 * 1 := by decide
-- path: 2 symmetries and 12 = 24 / 2 copies; star: 6 symmetries and 4 = 24 / 6 copies
example : (symmetries pathNet).card = 2 := by decide
example : (labelledCopies pathNet).card = 12 := by decide
example : (symmetries starNet).card = 6 := by decide
example : (labelledCopies starNet).card = 4 := by decide
example : 24 / 2 = 12 ∧ 24 / 6 = 4 := by decide
-- no copy of the path is a copy of the star; copies alone: 16 when the claim is true
example : Disjoint (labelledCopies pathNet) (labelledCopies starNet) := by decide
example : (labelledCopies pathNet ∪ labelledCopies starNet).card = 16 := by decide
-- (copy, symmetry) pairs: 48 when the claim is true, 24 when it is false
example : 12 * 2 + 4 * 6 = 48 ∧ 12 * 2 = 24 := by decide
-- hash bounds with 128 targets: 1,128 pairs among 48 items; 48/128 - 1128/16384 and 24/128
example : Nat.choose 48 2 = 1128 ∧ 128 * 128 = 16384 ∧ 2 ^ 7 = 128 := by decide
example : (48 : ℚ) / 128 - 1128 / 16384 = 627 / 2048 := by norm_num
example : (24 : ℚ) / 128 = 3 / 16 := by norm_num
-- CHSH: of the 16 fixed strategies, 8 win 3 of 4 and 8 win 1 of 4
example : (Finset.univ.filter fun s : (Bool → Bool) × (Bool → Bool) =>
    (chshWins s.1 s.2).card = 3).card = 8 := by decide
example : (Finset.univ.filter fun s : (Bool → Bool) × (Bool → Bool) =>
    (chshWins s.1 s.2).card = 1).card = 8 := by decide
-- suspects who hear both questions win all 4: a = 0 and b = x ∧ y
example : (Finset.univ.filter fun q : Bool × Bool =>
    chshWin q.1 q.2 false (q.1 && q.2) = true).card = 4 := by decide
-- pairs of 1-bit answer tables for q-bit questions: 2^(2^(q+1)), 16 at q = 1, 4,294,967,296 at q = 4
example : 2 ^ (2 ^ (1 + 1)) = 16 ∧ 2 ^ (2 ^ (4 + 1)) = 4294967296 := by norm_num

#print axioms chsh_separated_win_at_most_three
#print axioms labelled_copies_mul_symmetries
#print axioms parity_hash_pairwise_independent
#print axioms map_perm_mul_eq_iff
#print axioms parity_row_exists_aux
#print axioms zmod_two_eq_one_of_ne_zero
#print axioms parity_row_exists
#print axioms parity_hash_exists
#print axioms parity_hash_fiber_card
