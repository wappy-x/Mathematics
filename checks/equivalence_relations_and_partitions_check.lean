-- Equivalence relations and partitions: a reflexive, symmetric and transitive rule cuts any set into non-empty blocks that cover it and never overlap, "in the same block" gives the rule back, a partition gives a sameness rule whose blocks are the piles, and the card's clock and sock counts come out as it says.
import Mathlib.Order.Setoid.Partition
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Prod
import Mathlib.Data.Finset.Image

/-- The block of `a` under a rule `r`: everything the rule links `a` to. -/
def block {α : Type*} (r : α → α → Prop) (a : α) : Set α := {b | r a b}

/-- All the blocks of a rule `r`, one for each member (two members may share one block). -/
def blocks {α : Type*} (r : α → α → Prop) : Set (Set α) := Set.range (block r)

/-- "In the same pile": the rule a collection of piles `c` hands back. -/
def samePile {α : Type*} (c : Set (Set α)) (a b : α) : Prop := ∃ B ∈ c, a ∈ B ∧ b ∈ B

/-- A rule that is reflexive, symmetric and transitive cuts the set into blocks that form a
partition: no block is empty, and every member sits in exactly one block. And "in the same
block" is that rule handed back: `a` is linked to `b` exactly when some block holds both. -/
theorem equivalence_relation_cuts_set_into_partition {α : Type*} (r : α → α → Prop)
    (hrefl : ∀ a, r a a) (hsymm : ∀ a b, r a b → r b a)
    (htrans : ∀ a b c, r a b → r b c → r a c) :
    Setoid.IsPartition (blocks r) ∧ ∀ a b, r a b ↔ samePile (blocks r) a b := by
  have key : ∀ a b, r a b ↔ samePile (blocks r) a b := by
    intro a b
    constructor
    · intro h
      exact ⟨block r a, ⟨a, rfl⟩, hrefl a, h⟩
    · rintro ⟨B, ⟨c, rfl⟩, ha, hb⟩
      exact htrans _ _ _ (hsymm _ _ ha) hb
  refine ⟨⟨?_, ?_⟩, key⟩
  · rintro ⟨a, ha⟩
    have h1 : a ∈ block r a := hrefl a
    rw [ha] at h1
    exact h1
  · intro a
    refine ⟨block r a, ⟨⟨a, rfl⟩, hrefl a⟩, ?_⟩
    rintro B ⟨⟨c, rfl⟩, hB⟩
    have hB' : r c a := hB
    ext x
    constructor
    · intro hx
      exact htrans _ _ _ (hsymm _ _ hB') hx
    · intro hx
      exact htrans _ _ _ hB' hx

/-- Symmetric and transitive stop blocks overlapping: if the block of `a` and the block of `b`
share a member `h`, they are the same block. -/
theorem blocks_that_share_a_member_are_equal {α : Type*} (r : α → α → Prop)
    (hsymm : ∀ a b, r a b → r b a) (htrans : ∀ a b c, r a b → r b c → r a c) {a b h : α}
    (ha : h ∈ block r a) (hb : h ∈ block r b) : block r a = block r b := by
  ext x
  simp only [block, Set.mem_setOf_eq] at *
  constructor
  · intro hax
    exact htrans _ _ _ (htrans _ _ _ hb (hsymm _ _ ha)) hax
  · intro hbx
    exact htrans _ _ _ (htrans _ _ _ ha (hsymm _ _ hb)) hbx

/-- Piles first, rule second: for piles that form a partition (none empty, every member in
exactly one pile), "in the same pile" is reflexive, symmetric and transitive, and its blocks
are exactly the piles again. -/
theorem partition_gives_equivalence_relation_with_piles_as_blocks {α : Type*}
    (c : Set (Set α)) (hc : Setoid.IsPartition c) :
    (∀ a, samePile c a a) ∧ (∀ a b, samePile c a b → samePile c b a) ∧
      (∀ a b d, samePile c a b → samePile c b d → samePile c a d) ∧
      blocks (samePile c) = c := by
  obtain ⟨hne, hu⟩ := hc
  have hblock : ∀ a B, B ∈ c → a ∈ B → block (samePile c) a = B := by
    intro a B hB ha
    ext x
    constructor
    · rintro ⟨B', hB', ha', hx⟩
      have : B' = B := (hu a).unique ⟨hB', ha'⟩ ⟨hB, ha⟩
      subst this
      exact hx
    · intro hx
      exact ⟨B, hB, ha, hx⟩
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro a
    obtain ⟨B, ⟨hB, ha⟩, _⟩ := hu a
    exact ⟨B, hB, ha, ha⟩
  · rintro a b ⟨B, hB, ha, hb⟩
    exact ⟨B, hB, hb, ha⟩
  · rintro a b d ⟨B, hB, ha, hb⟩ ⟨B', hB', hb', hd⟩
    have : B' = B := (hu b).unique ⟨hB', hb'⟩ ⟨hB, hb⟩
    subst this
    exact ⟨B', hB', ha, hd⟩
  · ext S
    constructor
    · rintro ⟨a, rfl⟩
      obtain ⟨B, ⟨hB, ha⟩, _⟩ := hu a
      rw [hblock a B hB ha]
      exact hB
    · intro hS
      have hn : S.Nonempty := Set.nonempty_iff_ne_empty.2 fun h => hne (h ▸ hS)
      obtain ⟨a, ha⟩ := hn
      exact ⟨a, hblock a S hS ha⟩

/-- What a 12-hour face shows at hour `h` of the day. -/
def dial (h : ℕ) : ℕ := if 12 ≤ h then h - 12 else h

/-- Which pile sock `s` is in: socks 0 to 3 black, 4 to 6 white, 7 and 8 grey. -/
def pile (s : ℕ) : ℕ := if s < 4 then 0 else if s < 7 then 1 else 2

/-- The 24 hours of the day, and all 576 ordered pairs of them. -/
def hours : Finset ℕ := Finset.range 24
def hourPairs : Finset (ℕ × ℕ) := hours ×ˢ hours
/-- The 9 socks, and all 81 ordered pairs of them. -/
def socks : Finset ℕ := Finset.range 9
def sockPairs : Finset (ℕ × ℕ) := socks ×ˢ socks

-- The dial readings the card quotes.
example : dial 3 = 3 ∧ dial 15 = 3 ∧ dial 23 = 11 := by decide
-- 24 hours give 24 × 24 = 576 ordered pairs to ask about.
set_option maxRecDepth 4000 in
example : hourPairs.card = 576 := by decide
-- "Same reading on a 12-hour dial" links 48 of them: 12 blocks × 2 × 2.
set_option maxRecDepth 4000 in
example : (hourPairs.filter fun p => dial p.1 = dial p.2).card = 48 := by decide
example : 12 * 2 * 2 = 48 := by decide
-- The rule cuts the 24 hours into 12 blocks; hour 0's block is {0, 12}, hour 11's is {11, 23}.
example : (hours.image fun a => hours.filter fun b => dial a = dial b).card = 12 := by decide
example : hours.filter (fun b => dial 0 = dial b) = {0, 12} := by decide
example : hours.filter (fun b => dial 11 = dial b) = {11, 23} := by decide
-- The sock drawer: "same pile" links 4 × 4 + 3 × 3 + 2 × 2 = 29 ordered pairs.
example : (sockPairs.filter fun p => pile p.1 = pile p.2).card = 29 := by decide
example : 4 * 4 + 3 * 3 + 2 * 2 = 29 := by decide
-- That rule's blocks are the three piles back again.
example : (socks.image fun a => socks.filter fun b => pile a = pile b) =
    {{0, 1, 2, 3}, {4, 5, 6}, {7, 8}} := by decide
-- Broken rule 1, "same reading, and not the same hour": 24 pairs, and hour 0 is not in its own
-- block, though 0 links to 12 and 12 back to 0.
set_option maxRecDepth 4000 in
example : (hourPairs.filter fun p => dial p.1 = dial p.2 ∧ p.1 ≠ p.2).card = 24 := by decide
example : ¬ (dial 0 = dial 0 ∧ (0 : ℕ) ≠ 0) ∧ (dial 0 = dial 12 ∧ (0 : ℕ) ≠ 12) ∧
    (dial 12 = dial 0 ∧ (12 : ℕ) ≠ 0) := by decide
-- Broken rule 2, "readings at most 1 apart, no wrap": 136 pairs; 2 with 3 and 3 with 4, not 2 with 4.
set_option maxRecDepth 4000 in
example : (hourPairs.filter fun p => dial p.1 ≤ dial p.2 + 1 ∧ dial p.2 ≤ dial p.1 + 1).card = 136 := by
  decide
example : (dial 2 ≤ dial 3 + 1 ∧ dial 3 ≤ dial 2 + 1) ∧ (dial 3 ≤ dial 4 + 1 ∧ dial 4 ≤ dial 3 + 1) ∧
    ¬ (dial 2 ≤ dial 4 + 1 ∧ dial 4 ≤ dial 2 + 1) := by decide
-- Broken rule 3, one grey sock (sock 8) left on the floor: 26 pairs, and sock 8 is in no pile.
example : (sockPairs.filter fun p => pile p.1 = pile p.2 ∧ p.1 ≠ 8 ∧ p.2 ≠ 8).card = 26 := by decide
example : ¬ (pile 8 = pile 8 ∧ (8 : ℕ) ≠ 8 ∧ (8 : ℕ) ≠ 8) := by decide

#print axioms equivalence_relation_cuts_set_into_partition
#print axioms blocks_that_share_a_member_are_equal
#print axioms partition_gives_equivalence_relation_with_piles_as_blocks
