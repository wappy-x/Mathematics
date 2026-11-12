-- Russell's paradox: no set contains exactly the sets that are not members of themselves, no barber can shave exactly those who do not shave themselves, and the Russell cut of any set is never a member of that set.
import Mathlib.SetTheory.ZFC.Basic
import Mathlib.Data.Fintype.Powerset

/-- Russell's paradox: there is no set R whose members are exactly the sets that are not
members of themselves. The rule sweeps over every set x, with no set to cut from, and says
"x is in R exactly when x is not in x". -/
theorem no_set_of_all_sets_not_containing_themselves :
    ¬ ∃ R : ZFSet, ∀ x : ZFSet, x ∈ R ↔ x ∉ x := by
  rintro ⟨R, hR⟩
  exact iff_not_self (hR R)

/-- The barber: in any village, with any meaning of "shaves", no villager b can shave
exactly those villagers who do not shave themselves, when the rule covers every villager,
b included. -/
theorem no_barber_shaves_exactly_non_self_shavers {V : Type*} (shaves : V → V → Prop) :
    ¬ ∃ b : V, ∀ x : V, shaves b x ↔ ¬ shaves x x := by
  rintro ⟨b, hb⟩
  exact iff_not_self (hb b)

/-- Cut, do not sweep: for every set A, the Russell cut {x in A : x is not a member of x}
is never a member of A. So every set is missing its own Russell cut. -/
theorem russell_cut_not_mem (A : ZFSet) : ZFSet.sep (fun x => x ∉ x) A ∉ A := by
  intro hA
  have h := @ZFSet.mem_sep (fun x => x ∉ x) A (ZFSet.sep (fun x => x ∉ x) A)
  by_cases hs : ZFSet.sep (fun x => x ∉ x) A ∈ ZFSet.sep (fun x => x ∉ x) A
  · exact (h.mp hs).2 hs
  · exact hs (h.mpr ⟨hA, hs⟩)

-- The village: villagers 0 = Ada, 1 = Ben, 2 = Cyd. A list is a set of villagers.
-- Ada shaves herself; Cyd shaves himself exactly when he is on his own list.
-- The promise at villager v and list l: v is on l exactly when v does not shave v.

-- Three villagers, and 2 × 2 × 2 = 8 lists Cyd could hold.
example : Fintype.card (Fin 3) = 3 := by decide
example : (Finset.univ : Finset (Finset (Fin 3))).card = 8 := by decide

-- Lists that get Ada and Ben right: 2.
example : (Finset.univ.filter (fun l : Finset (Fin 3) =>
    ((0 : Fin 3) ∈ l ↔ ¬ ((0 : Fin 3) = 0 ∨ ((0 : Fin 3) = 2 ∧ (2 : Fin 3) ∈ l))) ∧
    ((1 : Fin 3) ∈ l ↔ ¬ ((1 : Fin 3) = 0 ∨ ((1 : Fin 3) = 2 ∧ (2 : Fin 3) ∈ l))))).card = 2 := by
  decide

-- Lists that keep the whole promise: 0.
example : (Finset.univ.filter (fun l : Finset (Fin 3) =>
    ∀ v : Fin 3, (v ∈ l ↔ ¬ (v = 0 ∨ (v = 2 ∧ (2 : Fin 3) ∈ l))))).card = 0 := by
  decide

-- Lists that break the promise at Cyd himself: all 8.
example : (Finset.univ.filter (fun l : Finset (Fin 3) =>
    ¬ ((2 : Fin 3) ∈ l ↔ ¬ ((2 : Fin 3) = 0 ∨ ((2 : Fin 3) = 2 ∧ (2 : Fin 3) ∈ l))))).card = 8 := by
  decide

-- The fullest of the eight lists holds 3 villagers, so none of the eight holds 8.
example : ∀ l : Finset (Fin 3), l.card ≤ 3 := by decide
example : (Finset.univ : Finset (Fin 3)).card = 3 := by decide
example : (Finset.univ.filter (fun l : Finset (Fin 3) => l.card = 8)).card = 0 := by decide

#print axioms no_set_of_all_sets_not_containing_themselves
#print axioms no_barber_shaves_exactly_non_self_shavers
#print axioms russell_cut_not_mem
