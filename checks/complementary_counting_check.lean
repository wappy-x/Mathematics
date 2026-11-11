-- Counting the complement: the objects a rule allows number the whole collection minus the objects it refuses, which gives 36^6 - 26^6 = 1,867,866,560 six-character passwords with a digit and C(20, 11) - C(18, 11) = 136,136 elevens with a goalkeeper.
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Data.Fintype.BigOperators

/-- The card's method, `|A| = |S| − |Ā|`: in any finite collection `S`, every object either
passes a rule `p` or fails it, never both, so the objects the rule allows number the whole
collection minus the objects the rule refuses. -/
theorem card_allowed_eq_card_sub_card_refused {α : Type*} (S : Finset α) (p : α → Prop)
    [DecidablePred p] :
    (S.filter p).card = S.card - (S.filter (fun x => ¬ p x)).card := by
  have h := Finset.card_filter_add_card_filter_not (s := S) (p := p)
  omega

/-- Strings with a required symbol: over an alphabet of `n` symbols, of which those in `D`
are the required kind (the digits), the strings of length `k` holding at least one symbol
from `D` number `n^k − (n − |D|)^k`: all strings minus those using no symbol from `D`. -/
theorem card_strings_with_at_least_one {α : Type*} [Fintype α] [DecidableEq α]
    (D : Finset α) (k : ℕ) :
    (Finset.univ.filter (fun w : Fin k → α => ∃ i, w i ∈ D)).card =
      Fintype.card α ^ k - (Fintype.card α - D.card) ^ k := by
  have hbad : (Finset.univ.filter (fun w : Fin k → α => ¬ ∃ i, w i ∈ D)) =
      Fintype.piFinset (fun _ : Fin k => Dᶜ) := by
    ext w
    simp
  have hbadc : (Finset.univ.filter (fun w : Fin k → α => ¬ ∃ i, w i ∈ D)).card =
      (Fintype.card α - D.card) ^ k := by
    rw [hbad, Fintype.card_piFinset, Finset.prod_const, Finset.card_compl, Finset.card_univ,
      Fintype.card_fin]
  have hall : (Finset.univ : Finset (Fin k → α)).card = Fintype.card α ^ k := by
    rw [Finset.card_univ, Fintype.card_fun, Fintype.card_fin]
  have h := Finset.card_filter_add_card_filter_not (s := (Finset.univ : Finset (Fin k → α)))
    (p := fun w : Fin k → α => ∃ i, w i ∈ D)
  rw [hbadc, hall] at h
  omega

/-- Picks with a required member: from a squad `S` containing a group `G` (the goalkeepers),
the picks of `m` players that include at least one member of `G` number
`C(|S|, m) − C(|S| − |G|, m)`: all picks minus those taken only from outside `G`. -/
theorem card_picks_with_at_least_one {α : Type*} [DecidableEq α] (S G : Finset α)
    (hG : G ⊆ S) (m : ℕ) :
    ((S.powersetCard m).filter (fun T => (T ∩ G).Nonempty)).card =
      S.card.choose m - (S.card - G.card).choose m := by
  have hbad : ((S.powersetCard m).filter (fun T => ¬ (T ∩ G).Nonempty)) =
      (S \ G).powersetCard m := by
    ext T
    simp only [Finset.mem_filter, Finset.mem_powersetCard, Finset.not_nonempty_iff_eq_empty,
      Finset.subset_sdiff]
    constructor
    · rintro ⟨⟨h1, h2⟩, h3⟩
      exact ⟨⟨h1, Finset.disjoint_iff_inter_eq_empty.mpr h3⟩, h2⟩
    · rintro ⟨⟨h1, h2⟩, h3⟩
      exact ⟨⟨h1, h3⟩, Finset.disjoint_iff_inter_eq_empty.mp h2⟩
  have hbadc : ((S.powersetCard m).filter (fun T => ¬ (T ∩ G).Nonempty)).card =
      (S.card - G.card).choose m := by
    rw [hbad, Finset.card_powersetCard, Finset.card_sdiff_of_subset hG]
  have h := Finset.card_filter_add_card_filter_not (s := S.powersetCard m)
    (p := fun T => (T ∩ G).Nonempty)
  rw [hbadc, Finset.card_powersetCard] at h
  omega

-- The password: 36 symbols in each of 6 slots, 26 of them letters.
example : (26 + 10) ^ 6 = 2176782336 := by norm_num
example : 26 ^ 6 = 308915776 := by norm_num
example : 36 ^ 6 - 26 ^ 6 = 1867866560 := by norm_num
-- The hard road: exactly k digits for k = 1 to 6, then all six added.
example : Nat.choose 6 1 * 10 * 26 ^ 5 = 712882560 := by norm_num [Nat.choose]
example : Nat.choose 6 2 * 10 ^ 2 * 26 ^ 4 = 685464000 := by norm_num [Nat.choose]
example : Nat.choose 6 3 * 10 ^ 3 * 26 ^ 3 = 351520000 := by norm_num [Nat.choose]
example : Nat.choose 6 4 * 10 ^ 4 * 26 ^ 2 = 101400000 := by norm_num [Nat.choose]
example : Nat.choose 6 5 * 10 ^ 5 * 26 = 15600000 := by norm_num [Nat.choose]
example : Nat.choose 6 6 * 10 ^ 6 = 1000000 := by norm_num [Nat.choose]
example : ∑ k ∈ Finset.Icc 1 6, Nat.choose 6 k * 10 ^ k * 26 ^ (6 - k) = 1867866560 := by
  decide +kernel
-- The toy version, every string listed: 3 letters and 2 digits, strings of 4.
example : (Finset.univ.filter (fun w : Fin 4 → Fin 5 => ∃ i, 3 ≤ (w i).val)).card = 544 := by
  decide +kernel
example : (3 + 2) ^ 4 = 625 ∧ 3 ^ 4 = 81 ∧ 625 - 81 = 544 := by norm_num
-- The squad: 20 players, 2 goalkeepers, elevens with at least one goalkeeper.
example : Nat.choose 20 11 = 167960 := by decide +kernel
example : Nat.choose 18 11 = 31824 := by decide +kernel
example : Nat.choose 20 11 - Nat.choose 18 11 = 136136 := by decide +kernel
-- The three mistakes.
example : 6 * 10 * 36 ^ 5 = 3627970560 := by norm_num
example : 36 ^ 6 - 712882560 = 1463899776 := by norm_num
example : 2 * Nat.choose 19 10 = 184756 := by decide +kernel

#print axioms card_allowed_eq_card_sub_card_refused
#print axioms card_strings_with_at_least_one
#print axioms card_picks_with_at_least_one
