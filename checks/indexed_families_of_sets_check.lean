-- Indexed families: for any index set, a "not" moved inside a union becomes an intersection of the outsides and vice versa (De Morgan), the sets [0, 1/n) share only 0 while the sets [1/n, 1] fill (0, 1], a product with one empty set has no pick, and the card's deck counts come out as it says.
import Mathlib.Data.Set.Lattice.Indexed
import Mathlib.Data.Set.Prod
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Tactic.NormNum

/-- De Morgan's law for any number of sets. The universe `U` is named first: here it is the
type `α`, and the outside of a set `X` is `Xᶜ`, read "U − X". For any index set `ι` and any
family `A i` of sets in `U`: outside the union is inside every outside,
`U − ⋃ A i = ⋂ (U − A i)`, and outside the intersection is inside some outside,
`U − ⋂ A i = ⋃ (U − A i)`. -/
theorem de_morgan_for_indexed_families {α ι : Type*} (A : ι → Set α) :
    (⋃ i, A i)ᶜ = ⋂ i, (A i)ᶜ ∧ (⋂ i, A i)ᶜ = ⋃ i, (A i)ᶜ := by
  exact ⟨Set.compl_iUnion A, Set.compl_iInter A⟩

/-- Infinitely many sets can share one number: over n = 1, 2, 3, ... the sets `[0, 1/n)`,
0 in and 1/n out, have only 0 in common, and the sets `[1/n, 1]` together make `(0, 1]`. -/
theorem shrinking_intervals_share_only_zero :
    (⋂ n : ℕ+, Set.Ico (0 : ℝ) (1 / (n : ℝ))) = {0} ∧
      (⋃ n : ℕ+, Set.Icc (1 / (n : ℝ)) 1) = Set.Ioc (0 : ℝ) 1 := by
  have key : ∀ x : ℝ, 0 < x → ∃ n : ℕ+, 1 / (n : ℝ) < x := by
    intro x hx
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt hx
    refine ⟨n.succPNat, ?_⟩
    have hc : ((n.succPNat : ℕ) : ℝ) = (n : ℝ) + 1 := by
      rw [Nat.succPNat_coe, Nat.cast_succ]
    simpa [hc] using hn
  constructor
  · ext x
    simp only [Set.mem_iInter, Set.mem_Ico, Set.mem_singleton_iff]
    constructor
    · intro h
      have h0 : 0 ≤ x := (h 1).1
      rcases h0.lt_or_eq with hpos | hzero
      · obtain ⟨n, hn⟩ := key x hpos
        exact absurd (h n).2 (not_lt.mpr hn.le)
      · exact hzero.symm
    · rintro rfl n
      refine ⟨le_rfl, ?_⟩
      have : (0 : ℝ) < (n : ℝ) := by exact_mod_cast n.pos
      positivity
  · ext x
    simp only [Set.mem_iUnion, Set.mem_Icc, Set.mem_Ioc]
    constructor
    · rintro ⟨n, h1, h2⟩
      have : (0 : ℝ) < (n : ℝ) := by exact_mod_cast n.pos
      exact ⟨lt_of_lt_of_le (by positivity) h1, h2⟩
    · rintro ⟨hpos, hle⟩
      obtain ⟨n, hn⟩ := key x hpos
      exact ⟨n, hn.le, hle⟩

/-- A product needs every set to have a member: if one set `B s` in the family is empty,
there is no pick `f` with `f s ∈ B s` for every label `s`, so the product is empty. -/
theorem product_with_an_empty_set_is_empty {ι : Type*} {β : ι → Type*} (B : ∀ s, Set (β s))
    (h : ∃ s, B s = ∅) : Set.pi Set.univ B = ∅ := by
  exact Set.univ_pi_eq_empty_iff.2 h

/-- The deck: a card is a suit (4) and a rank (13). -/
abbrev Card := Fin 4 × Fin 13

/-- The family indexed by rank: rank `r` labels its 4 cards. -/
def rankPile (r : Fin 13) : Finset Card := Finset.univ.filter (fun c => c.2 = r)

/-- The family indexed by suit: suit `s` labels its 13 cards. -/
def suitPile (s : Fin 4) : Finset Card := Finset.univ.filter (fun c => c.1 = s)

-- The rank family: 13 sets of 4 cards each.
example : ∀ r : Fin 13, (rankPile r).card = 4 := by decide
-- The union over all 13 ranks is the whole 52-card deck.
example : (Finset.univ.biUnion rankPile).card = 52 := by decide
-- The intersection over the ranks is empty: no card has every rank.
example : ∀ c : Card, ¬ ∀ r : Fin 13, c ∈ rankPile r := by decide
-- Distributive law (suits in the order clubs, diamonds, hearts, spades, so hearts is suit 2): the hearts in the union are the union of each pile's hearts, 13 cards.
example : suitPile 2 ∩ Finset.univ.biUnion rankPile =
    Finset.univ.biUnion (fun r => suitPile 2 ∩ rankPile r) := by decide
example : (suitPile 2 ∩ Finset.univ.biUnion rankPile).card = 13 := by decide
-- One card from each suit: 13 × 13 × 13 × 13 = 28,561 picks.
example : (Fintype.piFinset suitPile).card = 28561 := by
  rw [Fintype.card_piFinset]; decide
-- The mistake "four choices, thirteen times": 4^13 = 67,108,864.
example : (4 : ℕ) ^ 13 = 67108864 := by norm_num
-- 1/1000 is still in [0, 1/999) but drops out of [0, 1/n) at n = 1000.
example : (1 / 1000 : ℝ) ∈ Set.Ico (0 : ℝ) (1 / 999) ∧ (1 / 1000 : ℝ) ∉ Set.Ico (0 : ℝ) (1 / 1000) := by
  norm_num

#print axioms de_morgan_for_indexed_families
#print axioms shrinking_intervals_share_only_zero
#print axioms product_with_an_empty_set_is_empty
