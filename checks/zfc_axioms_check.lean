-- The ZFC axioms: in Mathlib's model of ZFC sets, separation's Russell cut of any set stays outside it so no set holds every set, foundation keeps every set out of itself, and pairing and union build each counting number as the set of the numbers before it.
import Mathlib.SetTheory.ZFC.Basic
import Mathlib.SetTheory.ZFC.Cardinal
import Mathlib.Data.Fintype.Prod
import Mathlib.Tactic.NormNum

universe u

/-- The counting numbers built by the card's two rules: `0 = {}` and
`n + 1 = n ∪ {n}`, the union of the pair `{n, {n}}`. -/
def vnNat : ℕ → ZFSet.{u}
  | 0 => ∅
  | n + 1 => ZFSet.sUnion {vnNat n, {vnNat n}}

/-- Membership in the next number: `n + 1 = n ∪ {n}`. -/
theorem vnNat_succ_mem (n : ℕ) (x : ZFSet.{u}) :
    x ∈ vnNat (n + 1) ↔ x ∈ vnNat n ∨ x = vnNat n := by
  simp only [vnNat, ZFSet.mem_sUnion, ZFSet.mem_pair]
  constructor
  · rintro ⟨z, rfl | rfl, hz⟩
    · exact Or.inl hz
    · exact Or.inr (ZFSet.mem_singleton.mp hz)
  · rintro (h | rfl)
    · exact ⟨vnNat n, Or.inl rfl, h⟩
    · exact ⟨{vnNat n}, Or.inr rfl, ZFSet.mem_singleton.mpr rfl⟩

#print axioms vnNat_succ_mem

/-- Splitting off the top index of a bounded existential. -/
theorem exists_lt_succ_iff' (n : ℕ) (p : ℕ → Prop) :
    (∃ m < n + 1, p m) ↔ (∃ m < n, p m) ∨ p n := by
  constructor
  · rintro ⟨m, hm, h⟩
    rcases Nat.lt_succ_iff_lt_or_eq.mp hm with hm' | rfl
    · exact Or.inl ⟨m, hm', h⟩
    · exact Or.inr h
  · rintro (⟨m, hm, h⟩ | h)
    · exact ⟨m, Nat.lt_succ_of_lt hm, h⟩
    · exact ⟨n, Nat.lt_succ_self n, h⟩

#print axioms exists_lt_succ_iff'

/-- **Separation blocks Russell.** Separation with Russell's test
"x is not a member of x" on any set A in hand gives a set, the Russell cut of A,
and that cut is never a member of A. So no set holds every set: Russell's
collection of all sets not in themselves never forms. -/
theorem separation_blocks_russell (A : ZFSet.{u}) :
    ZFSet.sep (fun x => x ∉ x) A ∉ A ∧ ¬ ∃ U : ZFSet.{u}, ∀ x : ZFSet.{u}, x ∈ U := by
  have key : ∀ B : ZFSet.{u}, ZFSet.sep (fun x => x ∉ x) B ∉ B := by
    intro B hB
    have h := @ZFSet.mem_sep (fun x => x ∉ x) B (ZFSet.sep (fun x => x ∉ x) B)
    by_cases hS : ZFSet.sep (fun x => x ∉ x) B ∈ ZFSet.sep (fun x => x ∉ x) B
    · exact (h.mp hS).2 hS
    · exact hS (h.mpr ⟨hB, hS⟩)
  refine ⟨key A, ?_⟩
  rintro ⟨U, hU⟩
  exact key U (hU _)

/-- **Foundation: no set is a member of itself.** Every set x satisfies x ∉ x. -/
theorem no_set_mem_self (x : ZFSet.{u}) : x ∉ x := by
  exact ZFSet.mem_irrefl x

/-- **Each number n holds the n numbers before it.** Built from the empty set by
pairing and union, the members of n are exactly 0, 1, ..., n - 1. -/
theorem mem_vnNat_iff (n : ℕ) (x : ZFSet.{u}) : x ∈ vnNat n ↔ ∃ m < n, x = vnNat m := by
  induction n generalizing x with
  | zero =>
    simp only [vnNat, Nat.not_lt_zero, false_and, exists_false, iff_false]
    exact ZFSet.notMem_empty x
  | succ n ih =>
    rw [vnNat_succ_mem, ih, exists_lt_succ_iff']

-- Extensionality: pairing 0 with itself gives {0, 0}, which is {0}.
example : ({vnNat 0, vnNat 0} : ZFSet.{0}) = {vnNat 0} := by
  ext z; rw [ZFSet.mem_pair, ZFSet.mem_singleton, or_self]
-- 1 = {0}, 2 = {0, 1}, 3 = {0, 1, 2}.
example : (vnNat 1 : ZFSet.{0}) = {vnNat 0} := by
  ext z
  rw [vnNat_succ_mem, ZFSet.mem_singleton]
  simp [vnNat, ZFSet.notMem_empty]
example : (vnNat 2 : ZFSet.{0}) = {vnNat 0, vnNat 1} := by
  ext z
  rw [mem_vnNat_iff, ZFSet.mem_pair, exists_lt_succ_iff', exists_lt_succ_iff']
  simp only [Nat.not_lt_zero, false_and, exists_false, false_or]
example : (vnNat 3 : ZFSet.{0}) = {vnNat 0, vnNat 1, vnNat 2} := by
  ext z
  rw [mem_vnNat_iff, ZFSet.mem_insert_iff, ZFSet.mem_pair, exists_lt_succ_iff',
    exists_lt_succ_iff', exists_lt_succ_iff']
  simp only [Nat.not_lt_zero, false_and, exists_false, false_or]
  tauto
-- The power set of 2 is {{}, {0}, {1}, {0, 1}}, 4 parts.
example : ZFSet.powerset (vnNat 2 : ZFSet.{0}) = {∅, {vnNat 0}, {vnNat 1}, vnNat 2} := by
  have h2 : ∀ z : ZFSet.{0}, z ∈ vnNat 2 ↔ z = vnNat 0 ∨ z = vnNat 1 := by
    intro z
    rw [mem_vnNat_iff, exists_lt_succ_iff', exists_lt_succ_iff']
    simp only [Nat.not_lt_zero, false_and, exists_false, false_or]
  ext y
  rw [ZFSet.mem_powerset, ZFSet.mem_insert_iff, ZFSet.mem_insert_iff, ZFSet.mem_pair,
    ZFSet.subset_def]
  constructor
  · intro hy
    by_cases h0 : vnNat 0 ∈ y <;> by_cases h1 : vnNat 1 ∈ y
    · right; right; right
      ext z
      rw [h2]
      constructor
      · intro hz; exact (h2 z).mp (hy hz)
      · rintro (rfl | rfl) <;> assumption
    · right; left
      ext z
      rw [ZFSet.mem_singleton]
      constructor
      · intro hz
        rcases (h2 z).mp (hy hz) with rfl | rfl
        · rfl
        · exact absurd hz h1
      · rintro rfl; exact h0
    · right; right; left
      ext z
      rw [ZFSet.mem_singleton]
      constructor
      · intro hz
        rcases (h2 z).mp (hy hz) with rfl | rfl
        · exact absurd hz h0
        · rfl
      · rintro rfl; exact h1
    · left
      rw [ZFSet.eq_empty]
      intro z hz
      rcases (h2 z).mp (hy hz) with rfl | rfl
      · exact h0 hz
      · exact h1 hz
  · rintro (rfl | rfl | rfl | rfl)
    · intro z hz; exact absurd hz (ZFSet.notMem_empty z)
    · intro z hz
      rw [ZFSet.mem_singleton] at hz
      exact (h2 z).mpr (Or.inl hz)
    · intro z hz
      rw [ZFSet.mem_singleton] at hz
      exact (h2 z).mpr (Or.inr hz)
    · intro z hz; exact hz
example : ZFSet.card (ZFSet.powerset (vnNat 2 : ZFSet.{0})) = 4 := by
  have hne : (vnNat 0 : ZFSet.{0}) ≠ vnNat 1 := by
    intro h
    have : (vnNat 0 : ZFSet.{0}) ∈ vnNat 1 := (vnNat_succ_mem 0 _).mpr (Or.inr rfl)
    rw [← h] at this
    exact ZFSet.mem_irrefl _ this
  have h2 : (vnNat 2 : ZFSet.{0}) = {vnNat 0, vnNat 1} := by
    ext z
    rw [mem_vnNat_iff, ZFSet.mem_pair, exists_lt_succ_iff', exists_lt_succ_iff']
    simp only [Nat.not_lt_zero, false_and, exists_false, false_or]
  rw [ZFSet.card_powerset, h2, ZFSet.card_pair_of_ne hne]
  rw [show (2 : Cardinal.{0}) = ((2 : ℕ) : Cardinal.{0}) from rfl, Cardinal.power_natCast]
  norm_num
-- The Russell cut of 3 keeps all 3 members, so it equals 3, and it is not in 3.
example : ZFSet.sep (fun x => x ∉ x) (vnNat 3 : ZFSet.{0}) = vnNat 3 ∧
    ZFSet.sep (fun x => x ∉ x) (vnNat 3 : ZFSet.{0}) ∉ (vnNat 3 : ZFSet.{0}) := by
  refine ⟨?_, (separation_blocks_russell _).1⟩
  ext z
  rw [ZFSet.mem_sep]
  exact ⟨fun h => h.1, fun h => ⟨h, ZFSet.mem_irrefl z⟩⟩
-- Mistake: building 2 as {1} gives 1 member, not 2.
example : ZFSet.card ({vnNat 1} : ZFSet.{0}) = 1 := by
  exact ZFSet.card_singleton
-- The deck: 4 suits times 13 ranks is 52 cards; separation keeps 13 hearts (suit 2).
example : Fintype.card (Fin 4 × Fin 13) = 52 := by decide
example : ((Finset.univ : Finset (Fin 4 × Fin 13)).filter (fun c => c.1 = 2)).card = 13 := by decide

#print axioms separation_blocks_russell
#print axioms no_set_mem_self
#print axioms mem_vnNat_iff
