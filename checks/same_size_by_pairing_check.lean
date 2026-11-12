-- Same size means pairable: doubling pairs the counting numbers with the even counting numbers, moving up one pairs them with every room from 2 on, and a set is infinite exactly when it pairs with a part of itself that leaves something out.
import Mathlib.Data.Set.Function
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Algebra.Group.Nat.Even
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Data.Set.Card
import Mathlib.Tactic

/-- The even numbers are the same size as the counting numbers: the rule "room n goes to
room 2n" pairs the counting numbers 1, 2, 3, ... with the even counting numbers 2, 4, 6, ...,
one-to-one and onto, with nothing left over on either side. -/
theorem doubling_pairs_counting_numbers_with_evens :
    Set.BijOn (fun n : ℕ => 2 * n) {n : ℕ | 1 ≤ n} {m : ℕ | 1 ≤ m ∧ Even m} := by
  refine ⟨?_, ?_, ?_⟩
  · rintro n (hn : 1 ≤ n)
    show 1 ≤ 2 * n ∧ Even (2 * n)
    exact ⟨by omega, even_two_mul n⟩
  · intro a _ b _ h
    simp only at h
    omega
  · rintro m ⟨hm, k, hk⟩
    exact ⟨k, by simp only [Set.mem_ofPred_eq]; omega, by simp only; omega⟩

/-- The full hotel takes one more guest: the rule "room n goes to room n + 1" pairs the
counting numbers with the counting numbers from 2 on, so room 1 is freed and nobody is lost. -/
theorem move_up_one_frees_room_one :
    Set.BijOn (fun n : ℕ => n + 1) {n : ℕ | 1 ≤ n} {m : ℕ | 2 ≤ m} := by
  refine ⟨?_, ?_, ?_⟩
  · rintro n (hn : 1 ≤ n)
    show 2 ≤ n + 1
    omega
  · intro a _ b _ h
    simp only at h
    omega
  · rintro m (hm : 2 ≤ m)
    exact ⟨m - 1, by simp only [Set.mem_ofPred_eq]; omega, by simp only; omega⟩

/-- Dedekind's test: a set is infinite exactly when some rule pairs it, one-to-one and onto,
with a part of itself that leaves something out. -/
theorem infinite_iff_pairs_with_proper_part {α : Type*} (s : Set α) :
    s.Infinite ↔ ∃ t ⊂ s, ∃ f : α → α, Set.BijOn f s t := by
  classical
  constructor
  · intro hs
    let e := hs.natEmbedding s
    let g : α → α := fun x => if h : ∃ n, (e n : α) = x then (e (h.choose + 1) : α) else x
    have hg1 : ∀ n, g (e n) = e (n + 1) := by
      intro n
      have h : ∃ k, (e k : α) = e n := ⟨n, rfl⟩
      have hc : h.choose = n := by
        apply e.injective
        exact Subtype.ext h.choose_spec
      simp only [g, dif_pos h, hc]
    have hg2 : ∀ x, (¬ ∃ n, (e n : α) = x) → g x = x := by
      intro x hx
      simp only [g, dif_neg hx]
    refine ⟨s \ {(e 0 : α)}, ?_, g, ?_, ?_, ?_⟩
    · refine ⟨Set.sdiff_subset, fun h => ?_⟩
      have := h (e 0).2
      exact this.2 rfl
    · intro x hx
      by_cases h : ∃ n, (e n : α) = x
      · obtain ⟨n, rfl⟩ := h
        rw [hg1]
        refine ⟨(e (n + 1)).2, ?_⟩
        intro h0
        have : e (n + 1) = e 0 := Subtype.ext h0
        have := e.injective this
        omega
      · rw [hg2 x h]
        refine ⟨hx, ?_⟩
        intro h0
        exact h ⟨0, h0.symm⟩
    · intro x hx y hy hxy
      by_cases h : ∃ n, (e n : α) = x
      · obtain ⟨n, rfl⟩ := h
        by_cases h' : ∃ m, (e m : α) = y
        · obtain ⟨m, rfl⟩ := h'
          simp only [hg1] at hxy
          have := e.injective (Subtype.ext hxy)
          have : n = m := by omega
          rw [this]
        · simp only [hg1, hg2 y h'] at hxy
          exact absurd ⟨n + 1, hxy⟩ h'
      · by_cases h' : ∃ m, (e m : α) = y
        · obtain ⟨m, rfl⟩ := h'
          simp only [hg1, hg2 x h] at hxy
          exact absurd ⟨m + 1, hxy.symm⟩ h
        · simpa only [hg2 x h, hg2 y h'] using hxy
    · intro y hy
      by_cases h : ∃ m, (e m : α) = y
      · obtain ⟨m, rfl⟩ := h
        have hm : m ≠ 0 := by
          rintro rfl
          exact hy.2 rfl
        obtain ⟨k, rfl⟩ := Nat.exists_eq_succ_of_ne_zero hm
        exact ⟨e k, (e k).2, hg1 k⟩
      · exact ⟨y, hy.1, hg2 y h⟩
  · rintro ⟨t, hts, f, hf⟩ hfin
    have h1 : s.ncard = t.ncard := hf.ncard_eq
    have h2 : t = s := Set.eq_of_subset_of_ncard_le hts.subset h1.le hfin
    exact hts.ne h2

-- Worked numbers: everyone up one, rooms 1 to 8 land in rooms 2 to 9.
example : (Finset.Icc 1 8).image (fun n : ℕ => n + 1) = Finset.Icc 2 9 := by decide
-- Every guest doubled lands in exactly the even rooms up to 16.
example : (Finset.Icc 1 8).image (fun n : ℕ => 2 * n) = (Finset.Icc 1 16).filter Even := by decide
-- Those even rooms, counted: 8.
example : ((Finset.Icc 1 16).filter Even).card = 8 := by decide
-- The finite hotel of 8 rooms: moving up one houses 7 of 8.
example : ((Finset.Icc 1 8).filter (fun n : ℕ => n + 1 ∈ Finset.Icc 1 8)).card = 7 := by decide
-- The finite hotel of 8 rooms: the even rooms are 2, 4, 6, 8, so 4 rooms for 8 guests.
example : (Finset.Icc 1 8).filter Even = {2, 4, 6, 8} := by decide
example : ((Finset.Icc 1 8).filter Even).card = 4 := by decide

#print axioms doubling_pairs_counting_numbers_with_evens
#print axioms move_up_one_frees_room_one
#print axioms infinite_iff_pairs_with_proper_part
