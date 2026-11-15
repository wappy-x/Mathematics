-- Topological space: the unions of a family's members form a topology exactly when the family covers the set and passes the overlap test, and bases decide which topology is finer.
import Mathlib.Topology.Bases
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Data.Nat.Fib.Basic
import Mathlib.Tactic.NormNum.NatFib

open Set TopologicalSpace Topology

/-- The unions of a family's members form a topology exactly when the family passes the two
basis tests: B1, its members cover the set, and B2, every point of an overlap of two members
sits in a third member inside that overlap. -/
theorem unions_form_topology_iff_basis_tests {X : Type*} (B : Set (Set X)) :
    (∃ t : TopologicalSpace X, ∀ U : Set X, IsOpen[t] U ↔ ∃ S ⊆ B, ⋃₀ S = U) ↔
      (⋃₀ B = univ ∧
        ∀ B₁ ∈ B, ∀ B₂ ∈ B, ∀ x ∈ B₁ ∩ B₂, ∃ B₃ ∈ B, x ∈ B₃ ∧ B₃ ⊆ B₁ ∩ B₂) := by
  constructor
  · rintro ⟨t, ht⟩
    have hopen : ∀ b ∈ B, IsOpen[t] b := fun b hb =>
      (ht b).2 ⟨{b}, singleton_subset_iff.2 hb, sUnion_singleton b⟩
    constructor
    · obtain ⟨S, hSB, hS⟩ := (ht univ).1 (@isOpen_univ X t)
      exact eq_univ_of_univ_subset (hS ▸ sUnion_mono hSB)
    · intro B₁ h1 B₂ h2 x hx
      obtain ⟨S, hSB, hS⟩ := (ht _).1 (@IsOpen.inter X t _ _ (hopen _ h1) (hopen _ h2))
      rw [← hS] at hx
      obtain ⟨B₃, h3, hx3⟩ := hx
      exact ⟨B₃, hSB h3, hx3, hS ▸ subset_sUnion_of_mem h3⟩
  · rintro ⟨h1, h2⟩
    let t : TopologicalSpace X := generateFrom B
    refine ⟨t, fun U => ?_⟩
    have hb : IsTopologicalBasis B := ⟨h2, h1, rfl⟩
    rw [hb.open_iff_eq_sUnion]
    exact exists_congr fun S => and_congr_right' eq_comm

/-- "Unions of basis members" and "room round every point" are the same family: a set is a
union of members exactly when each of its points has a member round it that stays inside the set. -/
theorem unions_of_members_iff_room_round_every_point {X : Type*} (B : Set (Set X)) (U : Set X) :
    (∃ S ⊆ B, ⋃₀ S = U) ↔ ∀ x ∈ U, ∃ b ∈ B, x ∈ b ∧ b ⊆ U := by
  constructor
  · rintro ⟨S, hSB, rfl⟩ x ⟨b, hbS, hxb⟩
    exact ⟨b, hSB hbS, hxb, subset_sUnion_of_mem hbS⟩
  · intro h
    refine ⟨{b | b ∈ B ∧ b ⊆ U}, fun b hb => hb.1, ?_⟩
    apply Subset.antisymm
    · rintro x ⟨b, ⟨_, hbU⟩, hxb⟩
      exact hbU hxb
    · intro x hx
      obtain ⟨b, hb, hxb, hbU⟩ := h x hx
      exact ⟨b, ⟨hb, hbU⟩, hxb⟩

/-- The basis test for fineness: when `B` is a basis of `t` and `B'` a basis of `t'`, the topology
`t'` is finer than `t` (every set open in `t` is open in `t'`) exactly when every point of every
member of `B` has a member of `B'` round it that lies inside that member. -/
theorem finer_iff_basis_test {X : Type*} {t t' : TopologicalSpace X} {B B' : Set (Set X)}
    (hB : @IsTopologicalBasis X t B) (hB' : @IsTopologicalBasis X t' B') :
    (∀ U : Set X, IsOpen[t] U → IsOpen[t'] U) ↔
      ∀ b ∈ B, ∀ x ∈ b, ∃ b' ∈ B', x ∈ b' ∧ b' ⊆ b := by
  constructor
  · intro h b hb x hx
    exact @IsTopologicalBasis.exists_subset_of_mem_open X t' B' hB' x b hx
      (h b (@IsTopologicalBasis.isOpen X t _ _ hB hb))
  · intro h U hU
    rw [@IsTopologicalBasis.isOpen_iff X t' U B' hB']
    intro x hx
    obtain ⟨b, hb, hxb, hbU⟩ := @IsTopologicalBasis.exists_subset_of_mem_open X t B hB x U hx hU
    obtain ⟨b', hb', hxb', hb'b⟩ := h b hb x hxb
    exact ⟨b', hb', hxb', hb'b.trans hbU⟩

-- The 90° dial by hand: 1 + 4 + 8 + 2 + 16 + 16 open sets.
example : 1 + 4 + 8 + 2 + 16 + 16 = 47 := by norm_num

-- The counting table M = [[1, 1], [1, 2]]: M^4 = [[13, 21], [21, 34]], trace 13 + 34 = 47.
example : (!![1, 1; 1, 2] : Matrix (Fin 2) (Fin 2) ℕ) ^ 4 = !![13, 21; 21, 34] := by decide

-- Open sets on the dials with N = 4, 6, 8, 12 and 24 marks: the trace of M^N.
example : Matrix.trace ((!![1, 1; 1, 2] : Matrix (Fin 2) (Fin 2) ℕ) ^ 4) = 47 := by decide
example : Matrix.trace ((!![1, 1; 1, 2] : Matrix (Fin 2) (Fin 2) ℕ) ^ 6) = 322 := by decide
example : Matrix.trace ((!![1, 1; 1, 2] : Matrix (Fin 2) (Fin 2) ℕ) ^ 8) = 2207 := by decide
example : Matrix.trace ((!![1, 1; 1, 2] : Matrix (Fin 2) (Fin 2) ℕ) ^ 12) = 103682 := by decide
example : Matrix.trace ((!![1, 1; 1, 2] : Matrix (Fin 2) (Fin 2) ℕ) ^ 24) = 10749957122 := by decide

-- The same counts as Lucas term 2N, where Lucas term n is fib (n - 1) + fib (n + 1).
example : Nat.fib 7 + Nat.fib 9 = 47 := by norm_num
example : Nat.fib 11 + Nat.fib 13 = 322 := by norm_num
example : Nat.fib 15 + Nat.fib 17 = 2207 := by norm_num
example : Nat.fib 23 + Nat.fib 25 = 103682 := by norm_num
example : Nat.fib 47 + Nat.fib 49 = 10749957122 := by norm_num

-- Basis arcs: N × (N - 1) per dial; ordered pairs of arcs on the 30° dial.
example : 4 * 3 = 12 ∧ 6 * 5 = 30 ∧ 8 * 7 = 56 ∧ 12 * 11 = 132 ∧ 24 * 23 = 552 := by norm_num
example : 132 * 132 = 17424 := by norm_num

#print axioms unions_form_topology_iff_basis_tests
#print axioms unions_of_members_iff_room_round_every_point
#print axioms finer_iff_basis_test
