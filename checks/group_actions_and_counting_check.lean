-- Group actions: for a finite group moving the members of a set, every member's orbit size times its stabiliser size equals the group's size, the orbits split the set into non-overlapping blocks, and the 16 two-coloured square tiles fall into 6 orbits.
import Mathlib.GroupTheory.GroupAction.Quotient
import Mathlib.GroupTheory.SpecificGroups.Dihedral
import Mathlib.Data.Setoid.Partition
import Mathlib.GroupTheory.GroupAction.Blocks

open MulAction

/-- Orbit-stabiliser: let a finite group `G` act on a set `X` (doing nothing leaves every member
put, and combining two moves before moving is the same as moving twice). Then at every member `x`
of `X`, the number of places `x` can be sent, times the number of moves that leave `x` put, is the
size of the group: `|Orb(x)| × |Stab(x)| = |G|`. The set `X` itself may be infinite. -/
theorem orbit_size_mul_stabiliser_size_eq_group_size {G X : Type*} [Group G] [MulAction G X]
    [Finite G] (x : X) :
    Nat.card (orbit G x) * Nat.card (stabilizer G x) = Nat.card G := by
  rw [← Nat.card_prod]
  exact Nat.card_congr (orbitProdStabilizerEquivGroup G x)

/-- The orbits cut the set into blocks that never overlap: for any group acting on a set, the
orbits are non-empty, and every member of the set lies in exactly one of them. -/
theorem orbits_partition_set {G X : Type*} [Group G] [MulAction G X] :
    Setoid.IsPartition (Set.range fun x : X => orbit G x) := by
  exact MulAction.IsPartition.of_orbits

/-- Burnside's lemma, the second road to the orbit count: for a finite group acting on a finite
set, adding up, move by move, how many members each move leaves untouched gives the number of
orbits times the size of the group. -/
theorem sum_fixed_points_eq_orbit_count_mul_group_size {G X : Type*} [Group G] [MulAction G X]
    [Fintype G] [Finite X] :
    ∑ g : G, Nat.card (fixedBy X g) = Nat.card (orbitRel.Quotient G X) * Nat.card G := by
  have := Fintype.ofFinite X
  classical
  have h := sum_card_fixedBy_eq_card_orbits_mul_card_group G X
  simp only [Nat.card_eq_fintype_card]
  convert h

/-! ### The card's square tile, checked exactly

The eight ways a square tile sits down are Mathlib's dihedral group `DihedralGroup 4`: `r k` turns
by `k` quarters, sending corner `i` to position `i + k`, and `sr k` flips, sending corner `i` to
`-i - k` (the card's `r(-k)f`). A pattern paints corners `0, 1, 2, 3` with a colour (`true` is
black); a move carries every corner's colour to the position that corner lands on. -/

/-- Pattern `p` after move `a`: position `j` receives the colour of the corner that `a` sends to
`j`. -/
def tileMove {C : Type} : DihedralGroup 4 → (ZMod 4 → C) → (ZMod 4 → C)
  | .r k, p => fun j => p (j - k)
  | .sr k, p => fun j => p (-j - k)

/-- BWWW: corner 0 black, the rest white. -/
def bwww : ZMod 4 → Bool := ![true, false, false, false]

/-- BWBW: two black corners across a diagonal. -/
def bwbw : ZMod 4 → Bool := ![true, false, true, false]

/-- BBBB: all four corners black. -/
def bbbb : ZMod 4 → Bool := fun _ => true

-- Eight moves, and 2 × 2 × 2 × 2 = 16 painted tiles.
example : Fintype.card (DihedralGroup 4) = 8 := by decide
example : Fintype.card (ZMod 4 → Bool) = 16 := by decide

-- BWWW: orbit 4 (BWWW, WBWW, WWBW, WWWB), stabiliser 2 (r0 and r0f), and 4 × 2 = 8.
example : (Finset.univ.image fun a : DihedralGroup 4 => tileMove a bwww).card = 4 := by decide
example : (Finset.univ.filter fun a : DihedralGroup 4 => tileMove a bwww = bwww).card = 2 := by
  decide

-- All-black: orbit 1, stabiliser 8, and 1 × 8 = 8.
example : (Finset.univ.image fun a : DihedralGroup 4 => tileMove a bbbb).card = 1 := by decide
example : (Finset.univ.filter fun a : DihedralGroup 4 => tileMove a bbbb = bbbb).card = 8 := by
  decide

-- Two black corners across a diagonal: orbit 2, stabiliser 4, and 2 × 4 = 8.
example : (Finset.univ.image fun a : DihedralGroup 4 => tileMove a bwbw).card = 2 := by decide
example : (Finset.univ.filter fun a : DihedralGroup 4 => tileMove a bwbw = bwbw).card = 4 := by
  decide

-- Road one, by listing: the 16 patterns fall into 6 orbits, of sizes 4 + 4 + 4 + 2 + 1 + 1 = 16.
example : (Finset.univ.image fun p : ZMod 4 → Bool =>
    Finset.univ.image fun a : DihedralGroup 4 => tileMove a p).card = 6 := by decide
example : 4 + 4 + 4 + 2 + 1 + 1 = 16 := by norm_num

-- What each move leaves untouched. In Mathlib's names r0, r1, r2, r3 leave 16, 2, 4, 2, and
-- sr0, sr1, sr2, sr3 (the card's r0f, r3f, r2f, r1f) leave 8, 4, 8, 4.
example : (List.map (fun a : DihedralGroup 4 =>
    (Finset.univ.filter fun p : ZMod 4 → Bool => tileMove a p = p).card)
    [.r 0, .r 1, .r 2, .r 3, .sr 0, .sr 1, .sr 2, .sr 3]) = [16, 2, 4, 2, 8, 4, 8, 4] := by
  decide

-- Road two, Burnside: 16 + 2 + 4 + 2 + 8 + 4 + 8 + 4 = 48, and 48 / 8 = 6.
example : ∑ a : DihedralGroup 4,
    (Finset.univ.filter fun p : ZMod 4 → Bool => tileMove a p = p).card = 48 := by decide
example : 48 / 8 = 6 := by norm_num

-- Three colours: 81 patterns, Burnside 168 / 8 = 21, and listing also gives 21 orbits.
example : ∑ a : DihedralGroup 4,
    (Finset.univ.filter fun p : ZMod 4 → Fin 3 => tileMove a p = p).card = 168 := by decide
set_option maxRecDepth 4000 in
example : (Finset.univ.image fun p : ZMod 4 → Fin 3 =>
    Finset.univ.image fun a : DihedralGroup 4 => tileMove a p).card = 21 := by decide

-- The mistake of forgetting the flips: averaging over the four turns alone at three colours
-- gives 24, not 21.
example : (∑ k : ZMod 4,
    (Finset.univ.filter fun p : ZMod 4 → Fin 3 => tileMove (.r k) p = p).card) / 4 = 24 := by
  decide

#print axioms orbit_size_mul_stabiliser_size_eq_group_size
#print axioms orbits_partition_set
#print axioms sum_fixed_points_eq_orbit_count_mul_group_size
