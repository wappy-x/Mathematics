-- NC and P-completeness: a fan-in-2 tree over n inputs needs and reaches depth ⌈log2 n⌉, S5 has two 5-cycles whose commutator is a 5-cycle, and no solvable group has such a pair.
import Mathlib.Data.Tree.Basic
import Mathlib.Data.Nat.Log
import Mathlib.GroupTheory.Perm.Cycle.Concrete
import Mathlib.GroupTheory.Perm.Cycle.Type
import Mathlib.GroupTheory.Solvable
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

open Equiv

/-- A binary tree has at most `2 ^ height` leaves. -/
theorem binaryTree_numLeaves_le_two_pow_height :
    ∀ t : BinaryTree Unit, t.numLeaves ≤ 2 ^ t.height
  | .nil => by simp [BinaryTree.numLeaves, BinaryTree.height]
  | .node _ a b => by
    have ha := binaryTree_numLeaves_le_two_pow_height a
    have hb := binaryTree_numLeaves_le_two_pow_height b
    simp only [BinaryTree.numLeaves, BinaryTree.height, pow_succ]
    have h1 : 2 ^ a.height ≤ 2 ^ max a.height b.height :=
      Nat.pow_le_pow_right (by norm_num) (le_max_left _ _)
    have h2 : 2 ^ b.height ≤ 2 ^ max a.height b.height :=
      Nat.pow_le_pow_right (by norm_num) (le_max_right _ _)
    omega

/-- Every `n` with `1 ≤ n ≤ 2 ^ k` is the leaf count of a tree of height at most `k`. -/
theorem binaryTree_exists_of_le_two_pow :
    ∀ k n : ℕ, 1 ≤ n → n ≤ 2 ^ k → ∃ t : BinaryTree Unit, t.numLeaves = n ∧ t.height ≤ k
  | 0, n, h1, h2 => ⟨.nil, by simp [BinaryTree.numLeaves] at *; omega, by simp [BinaryTree.height]⟩
  | k + 1, n, h1, h2 => by
    rcases Nat.eq_or_lt_of_le h1 with h | h
    · exact ⟨.nil, by simp [BinaryTree.numLeaves, ← h], by simp [BinaryTree.height]⟩
    · rw [pow_succ] at h2
      obtain ⟨a, ha, ha'⟩ := binaryTree_exists_of_le_two_pow k (n / 2) (by omega) (by omega)
      obtain ⟨b, hb, hb'⟩ := binaryTree_exists_of_le_two_pow k (n - n / 2) (by omega) (by omega)
      refine ⟨.node () a b, ?_, ?_⟩
      · simp only [BinaryTree.numLeaves, ha, hb]; omega
      · simp only [BinaryTree.height]; omega

/-- A term of the derived series that contains `α` also contains `α`'s next term. -/
theorem mem_derivedSeries_succ_of_usable {G : Type*} [Group G] (α β : G)
    (hβ : IsConj α β) (hc : IsConj α (β⁻¹ * α⁻¹ * β * α)) (n : ℕ)
    (hα : α ∈ Subgroup.derivedSeries G n) : α ∈ Subgroup.derivedSeries G (n + 1) := by
  have hN := Subgroup.derivedSeries_normal G n
  have hβmem : β ∈ Subgroup.derivedSeries G n := by
    obtain ⟨c, hc'⟩ := isConj_iff.mp hβ
    rw [← hc']
    exact hN.conj_mem α hα c
  have hcomm : β⁻¹ * α⁻¹ * β * α ∈ Subgroup.derivedSeries G (n + 1) := by
    rw [Subgroup.derivedSeries_succ]
    have := Subgroup.commutator_mem_commutator (inv_mem hβmem) (inv_mem hα)
    simpa [commutatorElement_def] using this
  obtain ⟨c, hc'⟩ := isConj_iff.mp hc.symm
  rw [← hc']
  exact (Subgroup.derivedSeries_normal G (n + 1)).conj_mem _ hcomm c

/-- Step 0, depth is waiting time: a balanced tree of two-input additions
combines `n ≥ 1` numbers. A tree of two-input gates (a `BinaryTree Unit`, whose
leaves are the inputs and whose nodes are the gates) with `n` leaves always has
depth at least `⌈log2 n⌉`, and some such tree has depth exactly `⌈log2 n⌉`. -/
theorem binary_tree_min_depth_eq_clog (n : ℕ) (hn : 1 ≤ n) :
    (∀ t : BinaryTree Unit, t.numLeaves = n → Nat.clog 2 n ≤ t.height) ∧
      ∃ t : BinaryTree Unit, t.numLeaves = n ∧ t.height = Nat.clog 2 n := by
  refine ⟨fun t ht => ?_, ?_⟩
  · rw [Nat.clog_le_iff_le_pow (by norm_num), ← ht]
    exact binaryTree_numLeaves_le_two_pow_height t
  · obtain ⟨t, ht, ht'⟩ := binaryTree_exists_of_le_two_pow (Nat.clog 2 n) n hn
      ((Nat.clog_le_iff_le_pow (by norm_num)).mp le_rfl)
    refine ⟨t, ht, le_antisymm ht' ?_⟩
    rw [Nat.clog_le_iff_le_pow (by norm_num), ← ht]
    exact binaryTree_numLeaves_le_two_pow_height t

/-- Barrington's key fact (Step 5): in `S5`, the shuffles of five places, there
are two 5-cycles `α` and `β` whose commutator "do `α`, then `β`, then undo `α`,
then undo `β`" is again a 5-cycle. Mathlib multiplies permutations right to
left, so that commutator is `β⁻¹ * α⁻¹ * β * α`. -/
theorem exists_five_cycles_with_five_cycle_commutator :
    ∃ α β : Perm (Fin 5), α.cycleType = {5} ∧ β.cycleType = {5} ∧
      (β⁻¹ * α⁻¹ * β * α).cycleType = {5} := by
  refine ⟨c[0, 1, 2, 3, 4], c[0, 1, 3, 4, 2], ?_⟩
  decide

/-- Why five (the folded proof): in a solvable group there is no usable pair.
If `α`, `β` and the commutator "do `α`, then `β`, then undo `α`, then undo `β`"
all lie in one class of look-alike (conjugate) elements, that class is `{e}`. -/
theorem no_usable_pair_of_isSolvable {G : Type*} [Group G] [Group.IsSolvable G] (α β : G)
    (hβ : IsConj α β) (hc : IsConj α (β⁻¹ * α⁻¹ * β * α)) : α = 1 := by
  obtain ⟨k, hk⟩ := (Group.isSolvable_def (G := G)).mp ‹_›
  have key : ∀ n, α ∈ Subgroup.derivedSeries G n := by
    intro n
    induction n with
    | zero => rw [Subgroup.derivedSeries_zero]; exact Subgroup.mem_top α
    | succ n ih => exact mem_derivedSeries_succ_of_usable α β hβ hc n ih
  have := key k
  rw [hk] at this
  exact (Subgroup.mem_bot).mp this

-- The closing balance: 1,024 lines need ⌈log2 1024⌉ = 10 rounds.
example : Nat.clog 2 1024 = 10 := by decide

-- The OR of 1,024 bits with two-input gates: 1,023 gates.
example : 1024 - 1 = 1023 := by norm_num

-- The card's pair: α = (1 2 3 4 5), β = (1 2 4 5 3) (places 1..5 written 0..4);
-- do α, then β, then undo α, then undo β, gives (1 5 3 2 4).
example :
    let α : Perm (Fin 5) := c[0, 1, 2, 3, 4]
    let β : Perm (Fin 5) := c[0, 1, 3, 4, 2]
    β⁻¹ * α⁻¹ * β * α = c[0, 4, 2, 1, 3] := by decide

-- All three of them are 5-cycles.
example : (c[0, 1, 2, 3, 4] : Perm (Fin 5)).cycleType = {5} ∧
    (c[0, 1, 3, 4, 2] : Perm (Fin 5)).cycleType = {5} ∧
    (c[0, 4, 2, 1, 3] : Perm (Fin 5)).cycleType = {5} := by decide

-- Brent-Kung: 1,023 adds in 10 rounds up, 1,013 in 9 down: 19 rounds, 2,036 adds.
example : 1023 + 1013 = 2036 ∧ 10 + 9 = 19 := by norm_num

-- Kogge-Stone: round j adds at 1,024 - 2^j positions, 10 rounds, 9,217 adds.
example : ∑ j ∈ Finset.range 10, (1024 - 2 ^ j) = 9217 := by decide

-- Carry-save: three numbers become two, so n becomes n - n/3;
-- 16 layers take 1,024 numbers down to 2 (1,024 → 683 → 456 → 304 → …).
example : (fun n : ℕ => n - n / 3)^[16] 1024 = 2 := by decide

-- Gate depth of the total: 16 × 6 + 13 = 109.
example : 16 * 6 + 13 = 109 := by norm_num

-- Tableau for a 4-bit input: 240 × 5² + 1 = 6,001 gates, depth 2 × 5 + 1 = 11.
example : 240 * 5 ^ 2 + 1 = 6001 ∧ 2 * 5 + 1 = 11 := by norm_num

-- Carry program: 40 instructions, within 4³ = 64.
example : 40 ≤ 4 ^ 3 := by norm_num

#print axioms binaryTree_numLeaves_le_two_pow_height
#print axioms binaryTree_exists_of_le_two_pow
#print axioms mem_derivedSeries_succ_of_usable
#print axioms binary_tree_min_depth_eq_clog
#print axioms exists_five_cycles_with_five_cycle_commutator
#print axioms no_usable_pair_of_isSolvable
