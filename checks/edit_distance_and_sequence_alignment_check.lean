-- Edit distance: the table's corner equals the least cost over all alignments, Hirschberg's split at any cut of x gives the same value, and with fair costs the distance is a true distance.
import Mathlib.Data.List.Basic
import Mathlib.Algebra.BigOperators.Group.List.Basic
import Mathlib.Algebra.Order.Group.Int
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

/-! Strings are lists of letters. A change of letter `a` into letter `b` costs `c a b`, and
each gap (an insert or a delete) costs `g`. Costs are whole numbers and may be negative, so the
DNA score (a match is a cost of -1) is covered too. -/

namespace EditDistance

variable {α : Type*} [DecidableEq α]

/-- The table, built from the card's rule. The arguments are the two strings read from the
last letter back, so each step peels the last letters `x_i` and `y_j`:
`D(i, 0) = i g`, `D(0, j) = j g`, and
`D(i, j) = min(D(i-1, j-1) + c(x_i, y_j), D(i-1, j) + g, D(i, j-1) + g)`. -/
def tableRev (c : α → α → ℤ) (g : ℤ) : List α → List α → ℤ
  | [], v => (v.length : ℤ) * g
  | a :: u, v => go a u (tableRev c g u) v
where
  /-- Row `i` of the table, for last letter `a = x_i`; `r` is row `i - 1`. -/
  go (a : α) (u : List α) (r : List α → ℤ) : List α → ℤ
    | [] => ((u.length : ℤ) + 1) * g
    | b :: v => min (min (r v + c a b) (r (b :: v) + g)) (go a u r v + g)

/-- The table's corner `D(n, m)` for the whole strings `x` (n letters) and `y` (m letters). -/
def editTable (c : α → α → ℤ) (g : ℤ) (x y : List α) : ℤ :=
  tableRev c g x.reverse y.reverse

/-- Levenshtein costs: a match costs 0, a change costs 1 (with gap cost `g = 1`). -/
def unitCost (a b : α) : ℤ := if a = b then 0 else 1

/-- The card's DNA score, +1 for a match and -1 for a mismatch, kept as a cost (minus the score). -/
def dnaCost (a b : α) : ℤ := if a = b then -1 else 1

/-- One column of an alignment: two letters paired, a letter of `x` over a dash (a delete),
or a dash over a letter of `y` (an insert). -/
inductive Column (α : Type*)
  | pair (a b : α)
  | del (a : α)
  | ins (b : α)

namespace Column

/-- The top row of a column with its dash removed. -/
def top {α : Type*} : Column α → List α
  | pair a _ => [a]
  | del a => [a]
  | ins _ => []

/-- The bottom row of a column with its dash removed. -/
def bot {α : Type*} : Column α → List α
  | pair _ b => [b]
  | del _ => []
  | ins b => [b]

/-- The cost of one column: `c a b` for a pair, `g` for a gap. -/
def cost {α : Type*} (c : α → α → ℤ) (g : ℤ) : Column α → ℤ
  | pair a b => c a b
  | del _ => g
  | ins _ => g

end Column

/-- A list of columns is an alignment of `x` with `y` when its top row, dashes removed,
spells `x` and its bottom row spells `y`. -/
def IsAlignment (A : List (Column α)) (x y : List α) : Prop :=
  A.flatMap Column.top = x ∧ A.flatMap Column.bot = y

instance (A : List (Column α)) (x y : List α) : Decidable (IsAlignment A x y) :=
  inferInstanceAs (Decidable (_ ∧ _))

/-- The cost of an alignment: the sum of its columns' costs. -/
def alignCost (c : α → α → ℤ) (g : ℤ) (A : List (Column α)) : ℤ :=
  (A.map (Column.cost c g)).sum

/-! Helper facts used by the proofs below. -/

lemma tableRev_nil_left (c : α → α → ℤ) (g : ℤ) (v : List α) :
    tableRev c g [] v = (v.length : ℤ) * g := by
  rw [tableRev]

lemma tableRev_nil_right (c : α → α → ℤ) (g : ℤ) (u : List α) :
    tableRev c g u [] = (u.length : ℤ) * g := by
  cases u with
  | nil => simp [tableRev]
  | cons a u => simp [tableRev, tableRev.go]

lemma tableRev_cons_cons (c : α → α → ℤ) (g : ℤ) (a b : α) (u v : List α) :
    tableRev c g (a :: u) (b :: v) =
      min (min (tableRev c g u v + c a b) (tableRev c g u (b :: v) + g))
        (tableRev c g (a :: u) v + g) := by
  simp only [tableRev, tableRev.go]

lemma alignCost_nil (c : α → α → ℤ) (g : ℤ) : alignCost c g ([] : List (Column α)) = 0 := by
  simp [alignCost]

lemma alignCost_cons (c : α → α → ℤ) (g : ℤ) (col : Column α) (A : List (Column α)) :
    alignCost c g (col :: A) = Column.cost c g col + alignCost c g A := by
  simp [alignCost]

lemma alignCost_append (c : α → α → ℤ) (g : ℤ) (A B : List (Column α)) :
    alignCost c g (A ++ B) = alignCost c g A + alignCost c g B := by
  simp [alignCost]

lemma alignCost_reverse (c : α → α → ℤ) (g : ℤ) (A : List (Column α)) :
    alignCost c g A.reverse = alignCost c g A := by
  simp [alignCost, List.sum_reverse]

lemma flatMap_top_reverse (A : List (Column α)) :
    A.reverse.flatMap Column.top = (A.flatMap Column.top).reverse := by
  induction A with
  | nil => rfl
  | cons col A ih => cases col <;> simp [ih, Column.top]

lemma flatMap_bot_reverse (A : List (Column α)) :
    A.reverse.flatMap Column.bot = (A.flatMap Column.bot).reverse := by
  induction A with
  | nil => rfl
  | cons col A ih => cases col <;> simp [ih, Column.bot]

lemma tableRev_le (c : α → α → ℤ) (g : ℤ) :
    ∀ (A : List (Column α)) (u v : List α), IsAlignment A u v → tableRev c g u v ≤ alignCost c g A
  | [], u, v, h => by
      obtain ⟨h1, h2⟩ := h
      subst h1; subst h2
      simp [tableRev, alignCost]
  | .pair a b :: A, u, v, h => by
      obtain ⟨h1, h2⟩ := h
      subst h1; subst h2
      have ih := tableRev_le c g A _ _ ⟨rfl, rfl⟩
      simp only [List.flatMap_cons, Column.top, Column.bot, List.singleton_append]
      rw [tableRev_cons_cons, alignCost_cons]
      simp only [Column.cost]
      have := min_le_left (min (tableRev c g (A.flatMap Column.top) (A.flatMap Column.bot) + c a b)
        (tableRev c g (A.flatMap Column.top) (b :: A.flatMap Column.bot) + g))
        (tableRev c g (a :: A.flatMap Column.top) (A.flatMap Column.bot) + g)
      have := min_le_left (tableRev c g (A.flatMap Column.top) (A.flatMap Column.bot) + c a b)
        (tableRev c g (A.flatMap Column.top) (b :: A.flatMap Column.bot) + g)
      linarith
  | .del a :: A, u, v, h => by
      obtain ⟨h1, h2⟩ := h
      subst h1; subst h2
      have ih := tableRev_le c g A _ _ ⟨rfl, rfl⟩
      simp only [List.flatMap_cons, Column.top, Column.bot, List.singleton_append, List.nil_append]
      rw [alignCost_cons]
      simp only [Column.cost]
      cases hv : A.flatMap Column.bot with
      | nil =>
          rw [hv] at ih
          simp only [tableRev_nil_right] at *
          simp only [List.length_cons, Nat.cast_add, Nat.cast_one] at *
          linarith
      | cons b v =>
          rw [hv] at ih
          rw [tableRev_cons_cons]
          have := min_le_left (min (tableRev c g (A.flatMap Column.top) v + c a b)
            (tableRev c g (A.flatMap Column.top) (b :: v) + g))
            (tableRev c g (a :: A.flatMap Column.top) v + g)
          have := min_le_right (tableRev c g (A.flatMap Column.top) v + c a b)
            (tableRev c g (A.flatMap Column.top) (b :: v) + g)
          linarith
  | .ins b :: A, u, v, h => by
      obtain ⟨h1, h2⟩ := h
      subst h1; subst h2
      have ih := tableRev_le c g A _ _ ⟨rfl, rfl⟩
      simp only [List.flatMap_cons, Column.top, Column.bot, List.singleton_append, List.nil_append]
      rw [alignCost_cons]
      simp only [Column.cost]
      cases hu : A.flatMap Column.top with
      | nil =>
          rw [hu] at ih
          simp only [tableRev_nil_left] at *
          simp only [List.length_cons, Nat.cast_add, Nat.cast_one] at *
          linarith
      | cons a u =>
          rw [hu] at ih
          rw [tableRev_cons_cons]
          have := min_le_right (min (tableRev c g u (A.flatMap Column.bot) + c a b)
            (tableRev c g u (b :: A.flatMap Column.bot) + g))
            (tableRev c g (a :: u) (A.flatMap Column.bot) + g)
          linarith

lemma tableRev_exists (c : α → α → ℤ) (g : ℤ) :
    ∀ (u v : List α), ∃ A : List (Column α), IsAlignment A u v ∧ alignCost c g A = tableRev c g u v
  | [], v => by
      induction v with
      | nil => exact ⟨[], ⟨rfl, rfl⟩, by simp [alignCost, tableRev]⟩
      | cons b v ih =>
          obtain ⟨A, ⟨h1, h2⟩, h3⟩ := ih
          refine ⟨.ins b :: A, ⟨by simp [Column.top, h1], by simp [Column.bot, h2]⟩, ?_⟩
          rw [alignCost_cons, h3, tableRev_nil_left, tableRev_nil_left]
          simp [Column.cost]; ring
  | a :: u, v => by
      have ihu := tableRev_exists c g u
      induction v with
      | nil =>
          obtain ⟨A, ⟨h1, h2⟩, h3⟩ := ihu []
          refine ⟨.del a :: A, ⟨by simp [Column.top, h1], by simp [Column.bot, h2]⟩, ?_⟩
          rw [alignCost_cons, h3, tableRev_nil_right, tableRev_nil_right]
          simp [Column.cost]; ring
      | cons b v ihv =>
          rw [tableRev_cons_cons]
          rcases min_choice (min (tableRev c g u v + c a b) (tableRev c g u (b :: v) + g))
              (tableRev c g (a :: u) v + g) with h | h <;> rw [h]
          · rcases min_choice (tableRev c g u v + c a b) (tableRev c g u (b :: v) + g)
              with h' | h' <;> rw [h']
            · obtain ⟨A, ⟨h1, h2⟩, h3⟩ := ihu v
              refine ⟨.pair a b :: A, ⟨by simp [Column.top, h1], by simp [Column.bot, h2]⟩, ?_⟩
              rw [alignCost_cons, h3]; simp [Column.cost]; ring
            · obtain ⟨A, ⟨h1, h2⟩, h3⟩ := ihu (b :: v)
              refine ⟨.del a :: A, ⟨by simp [Column.top, h1], by simp [Column.bot, h2]⟩, ?_⟩
              rw [alignCost_cons, h3]; simp [Column.cost]; ring
          · obtain ⟨A, ⟨h1, h2⟩, h3⟩ := ihv
            refine ⟨.ins b :: A, ⟨by simp [Column.top, h1], by simp [Column.bot, h2]⟩, ?_⟩
            rw [alignCost_cons, h3]; simp [Column.cost]; ring

/-- The table's corner is reached by some alignment and is below every alignment. -/
lemma editTable_spec (c : α → α → ℤ) (g : ℤ) (x y : List α) :
    (∃ A, IsAlignment A x y ∧ alignCost c g A = editTable c g x y) ∧
      ∀ A, IsAlignment A x y → editTable c g x y ≤ alignCost c g A := by
  constructor
  · obtain ⟨A, ⟨h1, h2⟩, h3⟩ := tableRev_exists c g x.reverse y.reverse
    refine ⟨A.reverse, ⟨?_, ?_⟩, ?_⟩
    · rw [flatMap_top_reverse, h1, List.reverse_reverse]
    · rw [flatMap_bot_reverse, h2, List.reverse_reverse]
    · rw [alignCost_reverse, h3]; rfl
  · intro A ⟨h1, h2⟩
    have := tableRev_le c g A.reverse x.reverse y.reverse
      ⟨by rw [flatMap_top_reverse, h1], by rw [flatMap_bot_reverse, h2]⟩
    rw [alignCost_reverse] at this
    exact this

lemma split_alignment :
    ∀ (A : List (Column α)) (h : ℕ), ∃ A1 A2 : List (Column α),
      A = A1 ++ A2 ∧ A1.flatMap Column.top = (A.flatMap Column.top).take h
  | [], h => ⟨[], [], rfl, by simp⟩
  | col :: A, 0 => ⟨[], col :: A, rfl, by simp⟩
  | .pair a b :: A, k + 1 => by
      obtain ⟨A1, A2, h1, h2⟩ := split_alignment A k
      exact ⟨.pair a b :: A1, A2, by simp [h1], by simp [Column.top, h2]⟩
  | .del a :: A, k + 1 => by
      obtain ⟨A1, A2, h1, h2⟩ := split_alignment A k
      exact ⟨.del a :: A1, A2, by simp [h1], by simp [Column.top, h2]⟩
  | .ins b :: A, k + 1 => by
      obtain ⟨A1, A2, h1, h2⟩ := split_alignment A (k + 1)
      exact ⟨.ins b :: A1, A2, by simp [h1], by simp [Column.top, h2]⟩

lemma merge_alignment (c : α → α → ℤ) (g : ℤ) (hc0 : ∀ a b, 0 ≤ c a b) (hg : 0 ≤ g)
    (htri : ∀ a b d, c a d ≤ c a b + c b d) :
    ∀ (A B : List (Column α)), A.flatMap Column.bot = B.flatMap Column.top →
      ∃ C : List (Column α), C.flatMap Column.top = A.flatMap Column.top ∧
        C.flatMap Column.bot = B.flatMap Column.bot ∧
        alignCost c g C ≤ alignCost c g A + alignCost c g B
  | [], [], _ => ⟨[], rfl, rfl, by simp [alignCost]⟩
  | .del a :: A, B, h => by
      obtain ⟨C, h1, h2, h3⟩ := merge_alignment c g hc0 hg htri A B (by simpa [Column.bot] using h)
      refine ⟨.del a :: C, by simp [Column.top, h1], by simpa [Column.bot] using h2, ?_⟩
      simp only [alignCost_cons, Column.cost]; linarith
  | A, .ins d :: B, h => by
      obtain ⟨C, h1, h2, h3⟩ := merge_alignment c g hc0 hg htri A B (by simpa [Column.top] using h)
      refine ⟨.ins d :: C, by simpa [Column.top] using h1, by simp [Column.bot, h2], ?_⟩
      simp only [alignCost_cons, Column.cost]; linarith
  | .ins b :: A, .pair b' d :: B, h => by
      simp only [List.flatMap_cons, Column.bot, Column.top, List.singleton_append,
        List.cons.injEq] at h
      obtain ⟨C, h1, h2, h3⟩ := merge_alignment c g hc0 hg htri A B h.2
      refine ⟨.ins d :: C, by simpa [Column.top] using h1, by simp [Column.bot, h2], ?_⟩
      simp only [alignCost_cons, Column.cost]; linarith [hc0 b' d]
  | .ins b :: A, .del b' :: B, h => by
      simp only [List.flatMap_cons, Column.bot, Column.top, List.singleton_append,
        List.cons.injEq] at h
      obtain ⟨C, h1, h2, h3⟩ := merge_alignment c g hc0 hg htri A B h.2
      refine ⟨C, by simpa [Column.top] using h1, by simpa [Column.bot] using h2, ?_⟩
      simp only [alignCost_cons, Column.cost]; linarith
  | .pair a b :: A, .pair b' d :: B, h => by
      simp only [List.flatMap_cons, Column.bot, Column.top, List.singleton_append,
        List.cons.injEq] at h
      obtain ⟨hb, h'⟩ := h
      subst hb
      obtain ⟨C, h1, h2, h3⟩ := merge_alignment c g hc0 hg htri A B h'
      refine ⟨.pair a d :: C, by simp [Column.top, h1], by simp [Column.bot, h2], ?_⟩
      simp only [alignCost_cons, Column.cost]; linarith [htri a b d]
  | .pair a b :: A, .del b' :: B, h => by
      simp only [List.flatMap_cons, Column.bot, Column.top, List.singleton_append,
        List.cons.injEq] at h
      obtain ⟨C, h1, h2, h3⟩ := merge_alignment c g hc0 hg htri A B h.2
      refine ⟨.del a :: C, by simp [Column.top, h1], by simpa [Column.bot] using h2, ?_⟩
      simp only [alignCost_cons, Column.cost]; linarith [hc0 a b]
  | [], .pair b d :: B, h => by simp [Column.top] at h
  | [], .del b :: B, h => by simp [Column.top] at h
  | .ins b :: A, [], h => by simp [Column.bot] at h
  | .pair a b :: A, [], h => by simp [Column.bot] at h
termination_by A B => A.length + B.length

/-- Swap the two rows of a column. -/
def Column.swap : Column α → Column α
  | .pair a b => .pair b a
  | .del a => .ins a
  | .ins b => .del b

lemma flatMap_top_swap (A : List (Column α)) :
    (A.map Column.swap).flatMap Column.top = A.flatMap Column.bot := by
  induction A with
  | nil => rfl
  | cons col A ih => cases col <;> simp_all [Column.swap, Column.top, Column.bot]

lemma flatMap_bot_swap (A : List (Column α)) :
    (A.map Column.swap).flatMap Column.bot = A.flatMap Column.top := by
  induction A with
  | nil => rfl
  | cons col A ih => cases col <;> simp_all [Column.swap, Column.top, Column.bot]

lemma alignCost_swap (c : α → α → ℤ) (g : ℤ) (hsymm : ∀ a b, c a b = c b a)
    (A : List (Column α)) : alignCost c g (A.map Column.swap) = alignCost c g A := by
  induction A with
  | nil => rfl
  | cons col A ih =>
      cases col <;> simp only [List.map_cons, alignCost_cons, ih, Column.swap, Column.cost, hsymm]

lemma alignCost_nonneg (c : α → α → ℤ) (g : ℤ) (hc0 : ∀ a b, 0 ≤ c a b) (hg : 0 ≤ g)
    (A : List (Column α)) : 0 ≤ alignCost c g A := by
  induction A with
  | nil => simp [alignCost]
  | cons col A ih =>
      rw [alignCost_cons]
      cases col with
      | pair a b => simp only [Column.cost]; linarith [hc0 a b]
      | del a => simp only [Column.cost]; linarith
      | ins b => simp only [Column.cost]; linarith

lemma alignCost_zero (c : α → α → ℤ) (g : ℤ) (hc0 : ∀ a b, 0 ≤ c a b)
    (hchange : ∀ a b, a ≠ b → 0 < c a b) (hg : 0 < g) (A : List (Column α))
    (h : alignCost c g A = 0) : A.flatMap Column.top = A.flatMap Column.bot := by
  induction A with
  | nil => rfl
  | cons col A ih =>
      rw [alignCost_cons] at h
      have hA := alignCost_nonneg c g hc0 hg.le A
      cases col with
      | pair a b =>
          simp only [Column.cost] at h
          have hab : c a b = 0 := by linarith [hc0 a b]
          have hab' : a = b := by
            by_contra hne; have := hchange a b hne; omega
          subst hab'
          simp [Column.top, Column.bot, ih (by linarith [hc0 a a])]
      | del a => simp only [Column.cost] at h; linarith
      | ins b => simp only [Column.cost] at h; linarith

lemma diag_alignment (c : α → α → ℤ) (g : ℤ) (hmatch : ∀ a, c a a = 0) (x : List α) :
    IsAlignment (x.map fun a => Column.pair a a) x x ∧
      alignCost c g (x.map fun a => Column.pair a a) = 0 := by
  induction x with
  | nil => exact ⟨⟨rfl, rfl⟩, rfl⟩
  | cons a x ih =>
      obtain ⟨⟨h1, h2⟩, h3⟩ := ih
      refine ⟨⟨by simp [Column.top, h1], by simp [Column.bot, h2]⟩, ?_⟩
      rw [List.map_cons, alignCost_cons, h3]
      simp [Column.cost, hmatch]

/-- The table gives the cheapest alignment: for any letter costs `c` and gap cost `g`, the
table's corner `D(n, m)` is the cost of some alignment of `x` with `y`, and no alignment of
`x` with `y` costs less. -/
theorem editTable_eq_min_alignment_cost (c : α → α → ℤ) (g : ℤ) (x y : List α) :
    (∃ A, IsAlignment A x y ∧ alignCost c g A = editTable c g x y) ∧
      ∀ A, IsAlignment A x y → editTable c g x y ≤ alignCost c g A := by
  exact editTable_spec c g x y

/-- Hirschberg's split: cut `x` after `h` letters (the card cuts at `h = ⌊n/2⌋`; any cut
works). Then `D(n, m)` is the least, over the places `j` from 0 to `m` where `y` is cut, of
the cost of the top part of `x` against `y_1 … y_j` plus the cost of the rest of `x`
against `y_{j+1} … y_m`. -/
theorem editTable_split (c : α → α → ℤ) (g : ℤ) (x y : List α) (h : ℕ) :
    (∃ j ≤ y.length, editTable c g x y =
        editTable c g (x.take h) (y.take j) + editTable c g (x.drop h) (y.drop j)) ∧
      ∀ j ≤ y.length, editTable c g x y ≤
        editTable c g (x.take h) (y.take j) + editTable c g (x.drop h) (y.drop j) := by
  obtain ⟨⟨A, hA, hAc⟩, hle⟩ := editTable_spec c g x y
  have upper : ∀ j, editTable c g x y ≤
      editTable c g (x.take h) (y.take j) + editTable c g (x.drop h) (y.drop j) := by
    intro j
    obtain ⟨⟨A1, ⟨a1, b1⟩, c1⟩, -⟩ := editTable_spec c g (x.take h) (y.take j)
    obtain ⟨⟨A2, ⟨a2, b2⟩, c2⟩, -⟩ := editTable_spec c g (x.drop h) (y.drop j)
    have := hle (A1 ++ A2)
      ⟨by rw [List.flatMap_append, a1, a2, List.take_append_drop],
        by rw [List.flatMap_append, b1, b2, List.take_append_drop]⟩
    rw [alignCost_append, c1, c2] at this
    exact this
  refine ⟨?_, fun j _ => upper j⟩
  obtain ⟨A1, A2, hsplit, htop⟩ := split_alignment A h
  obtain ⟨ht, hb⟩ := hA
  subst hsplit
  rw [List.flatMap_append] at ht hb htop
  rw [ht] at htop
  have hy1 : y.take (A1.flatMap Column.bot).length = A1.flatMap Column.bot := by
    rw [← hb]; exact List.take_left
  have hy2 : y.drop (A1.flatMap Column.bot).length = A2.flatMap Column.bot := by
    rw [← hb]; exact List.drop_left
  have hx2 : x.drop h = A2.flatMap Column.top := by
    have e : A1.flatMap Column.top ++ x.drop h = A1.flatMap Column.top ++ A2.flatMap Column.top := by
      rw [htop, List.take_append_drop, ← htop]
      exact ht.symm
    exact List.append_cancel_left e
  refine ⟨(A1.flatMap Column.bot).length, by rw [← hb]; simp, le_antisymm (upper _) ?_⟩
  have l1 := (editTable_spec c g (x.take h) (y.take (A1.flatMap Column.bot).length)).2 A1
    ⟨htop.symm ▸ rfl, hy1.symm⟩
  have l2 := (editTable_spec c g (x.drop h) (y.drop (A1.flatMap Column.bot).length)).2 A2
    ⟨hx2.symm, hy2.symm⟩
  rw [← hAc, alignCost_append]
  linarith

/-- A true distance: if a match costs 0, every change and every gap costs more than 0, letter
costs are the same both ways and obey the triangle rule, then the table's corner is zero only
for equal strings, is symmetric, and is never more than a detour through a third string. -/
theorem editTable_is_distance (c : α → α → ℤ) (g : ℤ)
    (hmatch : ∀ a, c a a = 0) (hchange : ∀ a b, a ≠ b → 0 < c a b) (hgap : 0 < g)
    (hsymm : ∀ a b, c a b = c b a) (htri : ∀ a b d, c a d ≤ c a b + c b d) :
    (∀ x y : List α, editTable c g x y = 0 ↔ x = y) ∧
      (∀ x y : List α, editTable c g x y = editTable c g y x) ∧
      (∀ x y z : List α, editTable c g x z ≤ editTable c g x y + editTable c g y z) := by
  have hc0 : ∀ a b, 0 ≤ c a b := by
    intro a b
    by_cases hab : a = b
    · subst hab; rw [hmatch]
    · exact (hchange a b hab).le
  refine ⟨?_, ?_, ?_⟩
  · intro x y
    constructor
    · intro h0
      obtain ⟨⟨A, ⟨h1, h2⟩, h3⟩, -⟩ := editTable_spec c g x y
      rw [h0] at h3
      rw [← h1, ← h2]
      exact alignCost_zero c g hc0 hchange hgap A h3
    · rintro rfl
      obtain ⟨⟨A, -, h3⟩, hle⟩ := editTable_spec c g x x
      have hA := alignCost_nonneg c g hc0 hgap.le A
      obtain ⟨hD, hD0⟩ := diag_alignment c g hmatch x
      have := hle _ hD
      rw [hD0] at this
      linarith
  · have hsw : ∀ x y : List α, editTable c g y x ≤ editTable c g x y := by
      intro x y
      obtain ⟨⟨A, ⟨h1, h2⟩, h3⟩, -⟩ := editTable_spec c g x y
      have := (editTable_spec c g y x).2 (A.map Column.swap)
        ⟨by rw [flatMap_top_swap, h2], by rw [flatMap_bot_swap, h1]⟩
      rw [alignCost_swap c g hsymm, h3] at this
      exact this
    exact fun x y => le_antisymm (hsw y x) (hsw x y)
  · intro x y z
    obtain ⟨⟨A, ⟨a1, a2⟩, a3⟩, -⟩ := editTable_spec c g x y
    obtain ⟨⟨B, ⟨b1, b2⟩, b3⟩, -⟩ := editTable_spec c g y z
    obtain ⟨C, c1, c2, c3⟩ := merge_alignment c g hc0 hgap.le htri A B (by rw [a2, b1])
    have := (editTable_spec c g x z).2 C ⟨by rw [c1, a1], by rw [c2, b2]⟩
    linarith

/-! The card's whole-number examples. -/

-- kitten to sitting costs 3 edits.
example : editTable unitCost 1 "kitten".toList "sitting".toList = 3 := by decide
-- Cells on the traceback path: D(5, 5) = 2 and D(6, 6) = 2.
example : editTable unitCost 1 "kitte".toList "sitti".toList = 2 := by decide
example : editTable unitCost 1 "kitten".toList "sittin".toList = 2 := by decide
-- The table's border and last row for kitten: row 6 is 6 6 5 4 3 3 2 3.
example : (List.range 8).map (fun j => editTable unitCost 1 "kitten".toList ("sitting".toList.take j)) =
    [6, 6, 5, 4, 3, 3, 2, 3] := by decide
-- The traceback alignment kitten- over sitting costs 3.
example : IsAlignment [.pair 'k' 's', .pair 'i' 'i', .pair 't' 't', .pair 't' 't', .pair 'e' 'i',
    .pair 'n' 'n', .ins 'g'] "kitten".toList "sitting".toList ∧
    alignCost unitCost 1 [.pair 'k' 's', .pair 'i' 'i', .pair 't' 't', .pair 't' 't', .pair 'e' 'i',
    .pair 'n' 'n', .ins 'g'] = 3 := by decide
-- GATTACA to GCATGCA costs 3.
example : editTable unitCost 1 "GATTACA".toList "GCATGCA".toList = 3 := by decide
-- DNA score, match +1, mismatch -1: best score 2 with gap -1, best score 1 with gap -2.
example : editTable dnaCost 1 "GATTACA".toList "GCATGCA".toList = -2 := by decide
example : editTable dnaCost 2 "GATTACA".toList "GCATGCA".toList = -1 := by decide
-- Hirschberg's first split of kitten (h = 3): forward row for kit, backward row for ten.
example : (List.range 8).map (fun j => editTable unitCost 1 "kit".toList ("sitting".toList.take j)) =
    [3, 3, 2, 1, 2, 3, 4, 5] := by decide
example : (List.range 8).map (fun j => editTable unitCost 1 "ten".toList ("sitting".toList.drop j)) =
    [5, 4, 3, 2, 3, 3, 3, 3] := by decide
-- The best cut is j = 3: kit to sit costs 1, ten to ting costs 2, total 3.
example : editTable unitCost 1 "kit".toList "sit".toList = 1 ∧
    editTable unitCost 1 "ten".toList "ting".toList = 2 := by decide
-- What breaks: the true distance from Beatles to The Beatles is 4.
example : editTable unitCost 1 "Beatles".toList "The Beatles".toList = 4 := by decide +kernel
-- Only insert and delete (a change costs 2): kitten to sitting is 5.
example : editTable (fun a b : Char => if a = b then 0 else 2) 1 "kitten".toList "sitting".toList = 5 := by
  decide
-- A swap is two edits: teh to the is 2.
example : editTable unitCost 1 "teh".toList "the".toList = 2 := by decide
-- Alignment counts: 19,825 for 6 and 7 letters, 48,639 for 7 and 7.
example : ((List.range 7).map fun k =>
    Nat.factorial (13 - k) / (Nat.factorial k * Nat.factorial (6 - k) * Nat.factorial (7 - k))).sum
    = 19825 := by norm_num [List.range_succ, Nat.factorial]
example : ((List.range 8).map fun k =>
    Nat.factorial (14 - k) / (Nat.factorial k * Nat.factorial (7 - k) * Nat.factorial (7 - k))).sum
    = 48639 := by norm_num [List.range_succ, Nat.factorial]
-- Table sizes: 7 × 8 = 56 questions, 6 × 7 = 42 cells filled; 100,001² cells at 4 bytes;
-- three rows of 100,001 cells at 4 bytes; two genomes of 4,600,000 letters.
example : 7 * 8 = 56 ∧ 6 * 7 = 42 := by norm_num
example : 100001 ^ 2 = 10000200001 ∧ 4 * 100001 ^ 2 = 40000800004 := by norm_num
example : 3 * 100001 = 300003 ∧ 12 * 100001 = 1200012 := by norm_num
example : 4600000 ^ 2 = 21160000000000 := by norm_num

#print axioms tableRev_nil_left
#print axioms tableRev_nil_right
#print axioms tableRev_cons_cons
#print axioms alignCost_nil
#print axioms alignCost_cons
#print axioms alignCost_append
#print axioms alignCost_reverse
#print axioms flatMap_top_reverse
#print axioms flatMap_bot_reverse
#print axioms tableRev_le
#print axioms tableRev_exists
#print axioms editTable_spec
#print axioms split_alignment
#print axioms merge_alignment
#print axioms flatMap_top_swap
#print axioms flatMap_bot_swap
#print axioms alignCost_swap
#print axioms alignCost_nonneg
#print axioms alignCost_zero
#print axioms diag_alignment
#print axioms editTable_eq_min_alignment_cost
#print axioms editTable_split
#print axioms editTable_is_distance

end EditDistance
