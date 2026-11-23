-- P versus NP: a yes-or-no payability oracle asked once per invoice rebuilds a list paying exactly the target, meet in the middle counts the same matching selections as brute force, the amount table marks exactly the payable totals, and the card's whole-number examples are exact.
import Mathlib.Data.List.Sublists
import Mathlib.Data.List.ProdSigma
import Mathlib.Data.Finset.Image
import Mathlib.Tactic.NormNum

/-! The open question itself, P = NP, is not stated here: it is open as of 2026-11-23 and
no theorem settles it. This file states what the card proves around its invoice example,
SUBSET SUM: amounts `A` (in cents) and a payment `S`. -/

namespace PVersusNP

/-- SUBSET SUM, the yes-or-no question: some selection of the amounts, each used at most
once, adds up to exactly `t`. -/
def Payable (xs : List ℕ) (t : ℕ) : Prop := ∃ s ∈ xs.sublists, s.sum = t

instance (xs : List ℕ) (t : ℕ) : Decidable (Payable xs t) := by
  unfold Payable; infer_instance

/-- Search from decision (road 4 of the code). Walk the invoices in order, with `rest` left
to pay and `i` the current invoice number. Ask the yes-or-no oracle "can the invoices after
this one still pay `rest` without it?". On no, keep invoice `i` and take its amount off
`rest`. Returns the kept invoice numbers and what is left over. -/
def rebuild : List ℕ → ℕ → ℕ → List ℕ × ℕ
  | [], rest, _ => ([], rest)
  | a :: tl, rest, i =>
      if Payable tl rest then rebuild tl rest (i + 1)
      else
        let r := rebuild tl (rest - a) (i + 1)
        (i :: r.1, r.2)

theorem payable_nil_iff (t : ℕ) : Payable [] t ↔ t = 0 := by
  simp [Payable, eq_comm]

theorem payable_cons_iff (a : ℕ) (tl : List ℕ) (t : ℕ) :
    Payable (a :: tl) t ↔ Payable tl t ∨ (a ≤ t ∧ Payable tl (t - a)) := by
  simp only [Payable, List.mem_sublists, List.sublist_cons_iff]
  constructor
  · rintro ⟨s, hs | ⟨r, rfl, hr⟩, hsum⟩
    · exact Or.inl ⟨s, hs, hsum⟩
    · simp only [List.sum_cons] at hsum
      exact Or.inr ⟨by omega, r, hr, by omega⟩
  · rintro (⟨s, hs, hsum⟩ | ⟨ha, r, hr, hsum⟩)
    · exact ⟨s, Or.inl hs, hsum⟩
    · exact ⟨a :: r, Or.inr ⟨r, rfl, hr⟩, by simp only [List.sum_cons]; omega⟩

theorem rebuild_spec (xs : List ℕ) (rest i : ℕ) (f : ℕ → ℕ)
    (hf : ∀ k < xs.length, f (i + k) = xs.getD k 0) (h : Payable xs rest) :
    (rebuild xs rest i).2 = 0 ∧
    ((rebuild xs rest i).1.map f).sum = rest ∧
    (rebuild xs rest i).1.Pairwise (· < ·) ∧
    ∀ j ∈ (rebuild xs rest i).1, i ≤ j ∧ j < i + xs.length := by
  induction xs generalizing rest i with
  | nil =>
    rw [payable_nil_iff] at h
    subst h
    simp [rebuild]
  | cons a tl ih =>
    have hf' : ∀ k < tl.length, f (i + 1 + k) = tl.getD k 0 := by
      intro k hk
      have := hf (k + 1) (by simp; omega)
      rw [show i + 1 + k = i + (k + 1) by omega, this]
      simp
    by_cases hp : Payable tl rest
    · obtain ⟨h1, h2, h3, h4⟩ := ih rest (i + 1) hf' hp
      simp only [rebuild, hp, ↓reduceIte]
      refine ⟨h1, h2, h3, fun j hj => ?_⟩
      have := h4 j hj
      simp only [List.length_cons]
      omega
    · have hp' : a ≤ rest ∧ Payable tl (rest - a) := by
        rcases (payable_cons_iff a tl rest).1 h with h' | h'
        · exact absurd h' hp
        · exact h'
      obtain ⟨h1, h2, h3, h4⟩ := ih (rest - a) (i + 1) hf' hp'.2
      have hfi : f i = a := by
        have := hf 0 (by simp)
        simpa using this
      simp only [rebuild, hp, ↓reduceIte]
      refine ⟨h1, ?_, ?_, ?_⟩
      · simp only [List.map_cons, List.sum_cons, hfi, h2]
        omega
      · refine List.Pairwise.cons (fun j hj => ?_) h3
        have := h4 j hj
        omega
      · intro j hj
        simp only [List.mem_cons] at hj
        simp only [List.length_cons]
        rcases hj with rfl | hj
        · omega
        · have := h4 j hj
          omega

/-- The yes-or-no form loses nothing: when the payment `S` can be made from the invoices `A`
at all, asking the yes-or-no question once per invoice rebuilds an actual list. The kept
invoice numbers are distinct (strictly increasing), each names a real invoice, their amounts
add up to exactly `S`, and nothing is left over. -/
theorem search_from_decision_rebuilds_list (A : List ℕ) (S : ℕ) (h : Payable A S) :
    (rebuild A S 0).2 = 0 ∧
    ((rebuild A S 0).1.map fun i => A.getD i 0).sum = S ∧
    (rebuild A S 0).1.Pairwise (· < ·) ∧
    ∀ i ∈ (rebuild A S 0).1, i < A.length := by
  obtain ⟨h1, h2, h3, h4⟩ :=
    rebuild_spec A S 0 (fun i => A.getD i 0) (fun k _ => by simp) h
  refine ⟨h1, h2, h3, fun i hi => ?_⟩
  have := h4 i hi
  omega

/-- All totals of selections from a list: the half-sums of meet in the middle. -/
def halfSums (xs : List ℕ) : List ℕ := xs.sublists.map List.sum

theorem sum_map_add_nat {β : Type*} (Y : List β) (g h : β → ℕ) :
    (Y.map fun b => g b + h b).sum = (Y.map g).sum + (Y.map h).sum := by
  induction Y with
  | nil => simp
  | cons y Y ih =>
    simp only [List.map_cons, List.sum_cons, ih]
    omega

theorem sum_map_sum_map_comm {α β : Type*} (X : List α) (Y : List β) (f : α → β → ℕ) :
    (X.map fun a => (Y.map fun b => f a b).sum).sum =
      (Y.map fun b => (X.map fun a => f a b).sum).sum := by
  induction X with
  | nil => simp
  | cons x X ih =>
    simp only [List.map_cons, List.sum_cons, ih, sum_map_add_nat]

theorem countP_eq_sum_ite {α : Type*} (l : List α) (p : α → Bool) :
    l.countP p = (l.map fun x => if p x then 1 else 0).sum := by
  induction l with
  | nil => simp
  | cons x l ih =>
    rw [List.countP_cons, ih, List.map_cons, List.sum_cons]
    omega

theorem countP_product_eq {α β : Type*} (X : List α) (Y : List β) (q : α → β → Bool) :
    (X.product Y).countP (fun p => q p.1 p.2) =
      (X.map fun a => (Y.map fun b => if q a b then 1 else 0).sum).sum := by
  induction X with
  | nil => simp [List.product]
  | cons x X ih =>
    have : (x :: X).product Y = Y.map (Prod.mk x) ++ X.product Y := by
      simp [List.product]
    rw [this, List.countP_append, List.countP_map, ih, List.map_cons, List.sum_cons,
      countP_eq_sum_ite]
    rfl

/-- Meet in the middle (Horowitz and Sahni, 1974) agrees with brute force. Split the invoices
into a first part `L` and a second part `R`. The pairs (left half-sum, right half-sum) adding
to `S` are exactly as many as the selections of all the invoices adding to `S`. -/
theorem meet_in_the_middle_counts_matches (L R : List ℕ) (S : ℕ) :
    ((halfSums L).product (halfSums R)).countP (fun p => p.1 + p.2 = S) =
      (L ++ R).sublists.countP (fun s => s.sum = S) := by
  rw [countP_product_eq (halfSums L) (halfSums R) (fun a b => a + b = S)]
  rw [List.sublists_append, List.bind_eq_flatMap, List.countP_flatMap]
  simp only [halfSums, List.map_map, Function.comp_def, countP_eq_sum_ite,
    List.sum_append]
  exact sum_map_sum_map_comm _ _ _

/-- The amount table (road 3): start with the total 0 marked; for each invoice `a`, also
mark every marked total plus `a`, keeping only totals from 0 to `S`. -/
def amountTable (A : List ℕ) (S : ℕ) : Finset ℕ :=
  A.foldl (fun r a => r ∪ (r.image (· + a)).filter (· ≤ S)) {0}

theorem foldl_spec (A : List ℕ) (S : ℕ) (r : Finset ℕ) (t : ℕ) (ht : t ≤ S) :
    t ∈ A.foldl (fun r a => r ∪ (r.image (· + a)).filter (· ≤ S)) r ↔
      ∃ u ∈ r, ∃ s ∈ A.sublists, u + s.sum = t := by
  induction A generalizing r with
  | nil => simp
  | cons a tl ih =>
    rw [List.foldl_cons, ih]
    simp only [Finset.mem_union, Finset.mem_filter, Finset.mem_image, List.mem_sublists,
      List.sublist_cons_iff]
    constructor
    · rintro ⟨u, hu | ⟨⟨v, hv, rfl⟩, _⟩, s, hs, hsum⟩
      · exact ⟨u, hu, s, Or.inl hs, hsum⟩
      · exact ⟨v, hv, a :: s, Or.inr ⟨s, rfl, hs⟩, by simp only [List.sum_cons]; omega⟩
    · rintro ⟨u, hu, s, hs | ⟨s', rfl, hs'⟩, hsum⟩
      · exact ⟨u, Or.inl hu, s, hs, hsum⟩
      · simp only [List.sum_cons] at hsum
        exact ⟨u + a, Or.inr ⟨⟨u, hu, rfl⟩, by omega⟩, s', hs', by omega⟩

/-- The amount table is right: a total `t` from 0 to `S` is marked exactly when some selection
of the invoices adds up to `t`. -/
theorem amount_table_marks_payable (A : List ℕ) (S t : ℕ) (ht : t ≤ S) :
    t ∈ amountTable A S ↔ Payable A t := by
  rw [amountTable, foldl_spec A S {0} t ht]
  simp [Payable]

/-! ### The card's worked numbers -/

/-- The twenty open invoices, in cents, numbered from 0. -/
def invoices : List ℕ :=
  [48215, 112040, 23999, 375010, 89950, 154281, 61830, 298000, 17465, 205590,
   73320, 131085, 44700, 260415, 98760, 186230, 35580, 142900, 67125, 228860]

-- 20 invoices, $26,553.55 open in total.
example : invoices.length = 20 ∧ invoices.sum = 2655355 := by decide
-- The clerk's list 1, 4, 6, 9, 13, 16, 18: 7 amounts adding to $8,325.30.
example : ([1, 4, 6, 9, 13, 16, 18].map fun i => invoices.getD i 0).sum = 832530 := by decide
-- The clerk's list is a selection of the invoices, so the payment is payable.
example : List.Sublist [112040, 89950, 61830, 205590, 260415, 35580, 67125] invoices ∧
    [112040, 89950, 61830, 205590, 260415, 35580, 67125].sum = 832530 := by decide
-- One cent more: invoices 1, 4, 5, 6, 10, 11, 17, 18 pay $8,325.31.
example : ([1, 4, 5, 6, 10, 11, 17, 18].map fun i => invoices.getD i 0).sum = 832531 := by decide
-- Brute force: 1,048,576 selections; meet in the middle: 1,024 + 1,024 half-sums.
example : 2 ^ 20 = 1048576 ∧ 2 ^ 10 = 1024 := by norm_num
-- The amount table: 20 rows × 832,531 columns = 16,650,620 cells.
example : 20 * (832530 + 1) = 16650620 := by norm_num
-- Every invoice 1,000 times larger: 16,650,600,020 cells.
example : 20 * (1000 * 832530 + 1) = 16650600020 := by norm_num
-- Every amount 10 times larger: 166,506,020 cells.
example : 20 * (10 * 832530 + 1) = 166506020 := by norm_num
-- A 21st invoice: 2,097,152 selections, 1,024 + 2,048 half-sums.
example : 2 ^ 21 = 2097152 ∧ 2 ^ 11 = 2048 := by norm_num
-- 60 invoices at a billion selections a second: 36.5 years of 31,557,600 s.
example : 2 ^ 60 = 1152921504606846976 ∧ 2 ^ 30 = 1073741824 := by norm_num
example : 2 ^ 60 / 10 ^ 6 = 1152921504606 := by norm_num
example : 2 ^ 60 / (10 ^ 9 * 31557600) = 36 ∧ 10 * 2 ^ 60 / (10 ^ 9 * 31557600) = 365 := by
  norm_num
-- 100 invoices: 2^100 subsets against 2^50 half-sums, and 40,169,423,537,538.6 years.
example : 2 ^ 100 = 1267650600228229401496703205376 ∧ 2 ^ 50 = 1125899906842624 := by norm_num
example : 10 * 2 ^ 100 / (10 ^ 9 * 31557600) = 401694235375386 := by norm_num
-- The bars: 2^60 has 19 digits, 2^30 has 10, and 60 has 2.
example : 10 ^ 18 ≤ 2 ^ 60 ∧ 2 ^ 60 < 10 ^ 19 ∧ 10 ^ 9 ≤ 2 ^ 30 ∧ 2 ^ 30 < 10 ^ 10 := by norm_num
-- The polls, in tenths of a percent, rounded: 61.0%, 82.9%, 87.9%, and 12.1% for P = NP.
example : (1000 * 61 + 50) / 100 = 610 ∧ (1000 * 126 + 76) / 152 = 829 ∧
    (1000 * 109 + 62) / 124 = 879 ∧ (1000 * 15 + 62) / 124 = 121 := by norm_num
-- The poll counts: 109 + 15 = 124 answers in 2019.
example : 109 + 15 = 124 := by norm_num
-- Clay's fund: 7 problems × $1,000,000.
example : 7 * 1000000 = 7000000 := by norm_num

#print axioms search_from_decision_rebuilds_list
#print axioms meet_in_the_middle_counts_matches
#print axioms amount_table_marks_payable
#print axioms payable_nil_iff
#print axioms payable_cons_iff
#print axioms rebuild_spec
#print axioms sum_map_add_nat
#print axioms sum_map_sum_map_comm
#print axioms countP_eq_sum_ite
#print axioms countP_product_eq
#print axioms foldl_spec

end PVersusNP
