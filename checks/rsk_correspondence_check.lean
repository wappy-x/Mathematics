-- The RSK correspondence: row insertion with a recording tableau matches the shuffles of 1 to n one for one with the pairs of same-shaped standard tableaux, so the squared tableau counts add up to n!, and the first row's length is the longest rising run.
import Mathlib.Combinatorics.Young.SemistandardTableau
import Mathlib.Combinatorics.Enumerative.Partition.YoungDiagram
import Mathlib.GroupTheory.Perm.Fin
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.List.Perm.Basic
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Data.Set.Card

/-! Mathlib has Young diagrams and semistandard tableaux but no RSK, so row insertion is
defined here on lists. A tableau is a list of rows, top row first. -/

/-- Insert `x` into one row: `x` takes the place of the first entry larger than it, and that
entry is bumped out (returned); if nothing is larger, `x` goes at the end and nothing is bumped. -/
def rowInsert : List ℕ → ℕ → List ℕ × Option ℕ
  | [], x => ([x], none)
  | y :: ys, x =>
      if x < y then (x :: ys, some y)
      else let r := rowInsert ys x; (y :: r.1, r.2)

/-- Insert `x` into the tableau `P`: a bumped entry is inserted into the next row by the same
rule, and a bumped entry that reaches an empty row starts it. Also returns the index of the row
that gained a box. -/
def insertP : List (List ℕ) → ℕ → List (List ℕ) × ℕ
  | [], x => ([[x]], 0)
  | row :: rows, x =>
      match rowInsert row x with
      | (row', none) => (row' :: rows, 0)
      | (row', some y) => let r := insertP rows y; (row' :: r.1, r.2 + 1)

/-- Write `k` in a new box at the end of row `i` of the recording tableau
(a new bottom row when `i` is the number of rows). -/
def addAt : List (List ℕ) → ℕ → ℕ → List (List ℕ)
  | [], _, k => [[k]]
  | row :: rows, 0, k => (row ++ [k]) :: rows
  | row :: rows, i + 1, k => row :: addAt rows i k

/-- RSK: insert the terms of `w` one at a time into `P`, and record in `Q` the step at which each
box appeared. Returns `(P, Q)`. -/
def rsk (w : List ℕ) : List (List ℕ) × List (List ℕ) :=
  let s := w.foldl
    (fun (s : List (List ℕ) × List (List ℕ) × ℕ) x =>
      let r := insertP s.1 x
      (r.1, addAt s.2.1 r.2 (s.2.2 + 1), s.2.2 + 1))
    ([], [], 0)
  (s.1, s.2.1)

/-- The shuffle `σ` of `1, …, n` written out as the list `σ(1), …, σ(n)`
(Mathlib's `Fin n` counts from 0, so each value is shifted up by one). -/
def word {n : ℕ} (σ : Equiv.Perm (Fin n)) : List ℕ :=
  List.ofFn fun i => (σ i : ℕ) + 1

/-- The shape of a list tableau: its row lengths, top row first. -/
def shape (T : List (List ℕ)) : List ℕ :=
  T.map List.length

/-- A standard tableau with `n` boxes, as a list of rows: no empty rows, each row rising, each
row no longer than the one above it, each column rising, and the entries exactly `1, …, n`. -/
def IsStandard (n : ℕ) (T : List (List ℕ)) : Prop :=
  (∀ row ∈ T, row ≠ []) ∧
  (∀ row ∈ T, row.Pairwise (· < ·)) ∧
  (∀ i, (T.getD (i + 1) []).length ≤ (T.getD i []).length ∧
    ∀ j < (T.getD (i + 1) []).length, (T.getD i []).getD j 0 < (T.getD (i + 1) []).getD j 0) ∧
  T.flatten.Perm (List.range' 1 n)

/-- A standard Young tableau of shape `μ`, in Mathlib's terms: a semistandard tableau whose
entries on the cells of `μ` are exactly `1, …, |μ|`, each used once. -/
def StandardYoungTableau (μ : YoungDiagram) : Type :=
  {T : SemistandardYoungTableau μ //
    Set.BijOn (fun c : ℕ × ℕ => T c.1 c.2) (μ.cells : Set (ℕ × ℕ)) (Set.Icc 1 μ.card)}

/-! ## Helper definitions and lemmas for the proofs -/

/-- Column condition between two consecutive rows. -/
def RowsOK : List ℕ → List ℕ → Prop
  | _, [] => True
  | [], _ :: _ => False
  | a :: as, b :: bs => a < b ∧ RowsOK as bs

/-- Tableau shape conditions, row by row. -/
def Tab : List (List ℕ) → Prop
  | [] => True
  | r :: rs => r ≠ [] ∧ r.Pairwise (· < ·) ∧ RowsOK r (rs.headD []) ∧ Tab rs

def incAt : List ℕ → ℕ → List ℕ
  | [], _ => [1]
  | a :: as, 0 => (a + 1) :: as
  | a :: as, i + 1 => a :: incAt as i

def rowUnins : List ℕ → ℕ → List ℕ × ℕ
  | [], y => ([], y)
  | u :: us, y => if us.headD y < y then (u :: (rowUnins us y).1, (rowUnins us y).2) else (y :: us, u)

def dropBox : List (List ℕ) → ℕ → List (List ℕ)
  | [], _ => []
  | r :: rs, 0 => if r.length = 1 then rs else r.dropLast :: rs
  | r :: rs, i + 1 => r :: dropBox rs i

def deleteP : List (List ℕ) → ℕ → List (List ℕ) × ℕ
  | [], _ => ([], 0)
  | r :: rs, 0 => (if r.length = 1 then rs else r.dropLast :: rs, r.getLastD 0)
  | r :: rs, i + 1 =>
      ((rowUnins r (deleteP rs i).2).1 :: (deleteP rs i).1, (rowUnins r (deleteP rs i).2).2)

def findRow : List (List ℕ) → ℕ → ℕ
  | [], _ => 0
  | r :: rs, k => if k ∈ r then 0 else findRow rs k + 1

@[simp] theorem rowsOK_nil_right (a : List ℕ) : RowsOK a [] := by cases a <;> trivial
@[simp] theorem rowsOK_nil_cons (b : ℕ) (bs : List ℕ) : RowsOK [] (b :: bs) ↔ False := Iff.rfl
@[simp] theorem rowsOK_cons_cons (a b : ℕ) (as bs : List ℕ) :
    RowsOK (a :: as) (b :: bs) ↔ a < b ∧ RowsOK as bs := Iff.rfl
@[simp] theorem tab_nil : Tab [] ↔ True := Iff.rfl
theorem tab_cons (r : List ℕ) (rs : List (List ℕ)) :
    Tab (r :: rs) ↔ r ≠ [] ∧ r.Pairwise (· < ·) ∧ RowsOK r (rs.headD []) ∧ Tab rs := Iff.rfl

theorem getD_zero_eq_headD (l : List (List ℕ)) : l.getD 0 [] = l.headD [] := by
  cases l <;> rfl

theorem mem_flatten_of_mem_head {l : List (List ℕ)} {z : ℕ} (h : z ∈ l.headD []) : z ∈ l.flatten := by
  cases l with
  | nil => simp at h
  | cons b bs => simp only [List.headD_cons] at h; simp [h]

theorem tab_head_sorted {P : List (List ℕ)} (h : Tab P) : (P.headD []).Pairwise (· < ·) := by
  cases P with
  | nil => simp
  | cons r rs => exact ((tab_cons _ _).1 h).2.1

theorem rowsOK_length {a b : List ℕ} (h : RowsOK a b) : b.length ≤ a.length := by
  induction a generalizing b with
  | nil => cases b with
    | nil => simp
    | cons _ _ => simp at h
  | cons x xs ih => cases b with
    | nil => simp
    | cons y ys => simp only [rowsOK_cons_cons] at h; simpa using ih h.2

theorem rowsOK_append_right {a b : List ℕ} (l : List ℕ) (h : RowsOK a b) : RowsOK (a ++ l) b := by
  induction a generalizing b with
  | nil => cases b with
    | nil => simp
    | cons _ _ => simp at h
  | cons x xs ih => cases b with
    | nil => simp
    | cons y ys => simp only [rowsOK_cons_cons] at h; simp only [List.cons_append, rowsOK_cons_cons]; exact ⟨h.1, ih h.2⟩

theorem rowsOK_prefix {a c : List ℕ} {y : ℕ} (h : RowsOK a (c ++ [y])) : RowsOK a c := by
  induction c generalizing a with
  | nil => simp
  | cons v cs ih => cases a with
    | nil => simp at h
    | cons u us => simp only [List.cons_append, rowsOK_cons_cons] at h ⊢; exact ⟨h.1, ih h.2⟩

theorem rowsOK_shrink {c b : List ℕ} {y : ℕ} (h : RowsOK (c ++ [y]) b) (hl : b.length ≤ c.length) :
    RowsOK c b := by
  induction c generalizing b with
  | nil => cases b with
    | nil => simp
    | cons _ _ => simp at hl
  | cons v cs ih => cases b with
    | nil => simp
    | cons q qs =>
      simp only [List.cons_append, rowsOK_cons_cons] at h ⊢
      simp only [List.length_cons] at hl
      exact ⟨h.1, ih h.2 (by omega)⟩

theorem rowsOK_snoc {r b : List ℕ} {k : ℕ} (h : RowsOK r b) (hl : b.length < r.length)
    (hk : ∀ e ∈ r, e < k) : RowsOK r (b ++ [k]) := by
  induction b generalizing r with
  | nil => cases r with
    | nil => simp at hl
    | cons u us => simp only [List.nil_append, rowsOK_cons_cons, rowsOK_nil_right, and_true]; exact hk u (by simp)
  | cons q qs ih => cases r with
    | nil => simp at h
    | cons u us =>
      simp only [rowsOK_cons_cons] at h
      simp only [List.length_cons] at hl
      simp only [List.cons_append, rowsOK_cons_cons]
      exact ⟨h.1, ih h.2 (by omega) (fun e he => hk e (by simp [he]))⟩

theorem rowsOK_full {c b : List ℕ} {y : ℕ} (h : RowsOK (c ++ [y]) b) (hl : b.length = c.length + 1) :
    ∃ e ∈ b, y < e := by
  induction c generalizing b with
  | nil => cases b with
    | nil => simp at hl
    | cons q qs => simp only [List.nil_append, rowsOK_cons_cons] at h; exact ⟨q, by simp, h.1⟩
  | cons v cs ih => cases b with
    | nil => simp at hl
    | cons q qs =>
      simp only [List.cons_append, rowsOK_cons_cons] at h
      simp only [List.length_cons] at hl
      obtain ⟨e, he, hye⟩ := ih h.2 (by omega)
      exact ⟨e, by simp [he], hye⟩

theorem head_lt_of_mem {r b : List ℕ} {z : ℕ} (h : RowsOK r b) (hr : r ≠ []) (hb : b.Pairwise (· < ·))
    (hz : z ∈ b) : r.headD z < z := by
  cases b with
  | nil => simp at hz
  | cons q qs => cases r with
    | nil => exact absurd rfl hr
    | cons p ps =>
      simp only [rowsOK_cons_cons] at h
      simp only [List.headD_cons]
      rcases List.mem_cons.1 hz with h' | h'
      · omega
      · have := (List.pairwise_cons.1 hb).1 z h'; omega

/-! ### Row insertion -/

theorem rowInsert_nil (x : ℕ) : rowInsert [] x = ([x], none) := rfl

theorem rowInsert_cons_lt {y x : ℕ} (ys : List ℕ) (h : x < y) :
    rowInsert (y :: ys) x = (x :: ys, some y) := by
  simp [rowInsert, h]

theorem rowInsert_cons_not_lt {y x : ℕ} (ys : List ℕ) (h : ¬ x < y) :
    rowInsert (y :: ys) x = (y :: (rowInsert ys x).1, (rowInsert ys x).2) := by
  simp [rowInsert, h]

theorem rowInsert_fst_ne_nil (r : List ℕ) (x : ℕ) : (rowInsert r x).1 ≠ [] := by
  cases r with
  | nil => simp [rowInsert_nil]
  | cons y ys =>
    by_cases h : x < y
    · rw [rowInsert_cons_lt ys h]; simp
    · rw [rowInsert_cons_not_lt ys h]; simp

theorem rowInsert_of_forall {r : List ℕ} {x : ℕ} (h : ∀ e ∈ r, ¬ x < e) :
    rowInsert r x = (r ++ [x], none) := by
  induction r with
  | nil => rfl
  | cons y ys ih =>
    simp only [List.mem_cons, forall_eq_or_imp] at h
    rw [rowInsert_cons_not_lt ys h.1, ih h.2]; rfl

theorem rowInsert_snd_none {r : List ℕ} {x : ℕ} (h : (rowInsert r x).2 = none) :
    rowInsert r x = (r ++ [x], none) := by
  induction r with
  | nil => rfl
  | cons y ys ih =>
    by_cases hxy : x < y
    · rw [rowInsert_cons_lt ys hxy] at h; simp at h
    · rw [rowInsert_cons_not_lt ys hxy] at h ⊢
      simp only at h
      rw [ih h]; rfl

theorem rowInsert_snd_mem {r : List ℕ} {x y : ℕ} (h : (rowInsert r x).2 = some y) : y ∈ r := by
  induction r with
  | nil => simp [rowInsert_nil] at h
  | cons w ws ih =>
    by_cases hxw : x < w
    · rw [rowInsert_cons_lt ws hxw] at h; simp only [Option.some.injEq] at h; simp [h]
    · rw [rowInsert_cons_not_lt ws hxw] at h; simp only at h; exact List.mem_cons_of_mem _ (ih h)

theorem rowInsert_perm (r : List ℕ) (x : ℕ) :
    ((rowInsert r x).1 ++ (rowInsert r x).2.toList).Perm (x :: r) := by
  induction r with
  | nil => simp [rowInsert_nil]
  | cons y ys ih =>
    by_cases hxy : x < y
    · rw [rowInsert_cons_lt ys hxy]
      simp only [Option.toList_some, List.cons_append]
      exact (List.perm_append_singleton y ys).cons x
    · rw [rowInsert_cons_not_lt ys hxy]
      simp only [List.cons_append]
      exact (ih.cons y).trans (List.Perm.swap x y ys)

theorem rowInsert_mem_fst {r : List ℕ} {x e : ℕ} (he : e ∈ (rowInsert r x).1) : e = x ∨ e ∈ r :=
  List.mem_cons.1 ((rowInsert_perm r x).subset (List.mem_append_left _ he))

theorem rowInsert_length_some {r : List ℕ} {x y : ℕ} (h : (rowInsert r x).2 = some y) :
    (rowInsert r x).1.length = r.length := by
  have := (rowInsert_perm r x).length_eq
  rw [h] at this
  simpa using this

theorem rowInsert_sorted {r : List ℕ} {x : ℕ} (hr : r.Pairwise (· < ·)) (hx : x ∉ r) :
    (rowInsert r x).1.Pairwise (· < ·) := by
  induction r with
  | nil => simp [rowInsert_nil]
  | cons y ys ih =>
    rw [List.pairwise_cons] at hr
    simp only [List.mem_cons, not_or] at hx
    by_cases hxy : x < y
    · rw [rowInsert_cons_lt ys hxy]
      exact List.pairwise_cons.2 ⟨fun e he => lt_trans hxy (hr.1 e he), hr.2⟩
    · rw [rowInsert_cons_not_lt ys hxy]
      refine List.pairwise_cons.2 ⟨fun e he => ?_, ih hr.2 hx.2⟩
      rcases rowInsert_mem_fst he with h | h
      · rw [h]; omega
      · exact hr.1 e h

theorem rowsOK_rowInsert_left {r b : List ℕ} (x : ℕ) (h : RowsOK r b) : RowsOK (rowInsert r x).1 b := by
  induction r generalizing b with
  | nil => cases b with
    | nil => simp
    | cons _ _ => simp at h
  | cons y ys ih =>
    cases b with
    | nil => simp
    | cons v vs =>
      rw [rowsOK_cons_cons] at h
      by_cases hxy : x < y
      · rw [rowInsert_cons_lt ys hxy]; simp only [rowsOK_cons_cons]; exact ⟨by omega, h.2⟩
      · rw [rowInsert_cons_not_lt ys hxy]; simp only [rowsOK_cons_cons]; exact ⟨h.1, ih h.2⟩

theorem rowsOK_insert_step {a b : List ℕ} {x y : ℕ} (ha : a.Pairwise (· < ·))
    (hab : RowsOK a b) (hx : x ∉ a) (hy : (rowInsert a x).2 = some y) :
    RowsOK (rowInsert a x).1 (rowInsert b y).1 := by
  induction a generalizing b with
  | nil => simp [rowInsert_nil] at hy
  | cons u us ih =>
    rw [List.pairwise_cons] at ha
    simp only [List.mem_cons, not_or] at hx
    by_cases hxu : x < u
    · rw [rowInsert_cons_lt us hxu] at hy ⊢
      simp only [Option.some.injEq] at hy
      subst hy
      cases b with
      | nil => rw [rowInsert_nil]; simp [hxu]
      | cons v vs =>
        rw [rowsOK_cons_cons] at hab
        rw [rowInsert_cons_lt vs hab.1]
        simp [hxu, hab.2]
    · rw [rowInsert_cons_not_lt us hxu] at hy ⊢
      simp only at hy
      have hyu : u < y := ha.1 y (rowInsert_snd_mem hy)
      cases b with
      | nil => rw [rowInsert_nil]; simp [hyu]
      | cons v vs =>
        rw [rowsOK_cons_cons] at hab
        by_cases hyv : y < v
        · rw [rowInsert_cons_lt vs hyv]
          simp only [rowsOK_cons_cons]
          exact ⟨hyu, rowsOK_rowInsert_left x hab.2⟩
        · rw [rowInsert_cons_not_lt vs hyv]
          simp only [rowsOK_cons_cons]
          exact ⟨hab.1, ih ha.2 hab.2 hx.2 hy⟩

theorem rowInsert_head_lt {r : List ℕ} {x y : ℕ} (hr : r.Pairwise (· < ·))
    (hy : (rowInsert r x).2 = some y) : (rowInsert r x).1.headD y < y := by
  cases r with
  | nil => simp [rowInsert_nil] at hy
  | cons w ws =>
    rw [List.pairwise_cons] at hr
    by_cases hxw : x < w
    · rw [rowInsert_cons_lt ws hxw] at hy ⊢
      simp only [Option.some.injEq] at hy; subst hy; simpa using hxw
    · rw [rowInsert_cons_not_lt ws hxw] at hy ⊢
      simp only [List.headD_cons] at hy ⊢
      exact hr.1 y (rowInsert_snd_mem hy)

/-! ### Reverse bumping -/

theorem rowUnins_cons_lt {u y : ℕ} {us : List ℕ} (h : us.headD y < y) :
    rowUnins (u :: us) y = (u :: (rowUnins us y).1, (rowUnins us y).2) := by
  rw [rowUnins, if_pos h]

theorem rowUnins_cons_not_lt {u y : ℕ} {us : List ℕ} (h : ¬ us.headD y < y) :
    rowUnins (u :: us) y = (y :: us, u) := by
  rw [rowUnins, if_neg h]

theorem rowUnins_ne_nil {r : List ℕ} (y : ℕ) (hr : r ≠ []) : (rowUnins r y).1 ≠ [] := by
  cases r with
  | nil => exact absurd rfl hr
  | cons u us =>
    by_cases h : us.headD y < y
    · rw [rowUnins_cons_lt h]; simp
    · rw [rowUnins_cons_not_lt h]; simp

theorem rowUnins_mem {r : List ℕ} {z : ℕ} (h : r.headD z < z) : (rowUnins r z).2 ∈ r := by
  induction r with
  | nil => simp at h
  | cons u us ih =>
    by_cases hu : us.headD z < z
    · rw [rowUnins_cons_lt hu]; exact List.mem_cons_of_mem _ (ih hu)
    · rw [rowUnins_cons_not_lt hu]; simp

theorem rowUnins_rowInsert {r : List ℕ} {x y : ℕ} (hr : r.Pairwise (· < ·)) (hx : x ∉ r)
    (hy : (rowInsert r x).2 = some y) : rowUnins (rowInsert r x).1 y = (r, x) := by
  induction r with
  | nil => simp [rowInsert_nil] at hy
  | cons u us ih =>
    rw [List.pairwise_cons] at hr
    simp only [List.mem_cons, not_or] at hx
    by_cases hxu : x < u
    · rw [rowInsert_cons_lt us hxu] at hy ⊢
      simp only [Option.some.injEq] at hy; subst hy
      have h : ¬ us.headD u < u := by
        cases us with
        | nil => simp
        | cons v vs => simp only [List.headD_cons, not_lt]; exact (hr.1 v (by simp)).le
      rw [rowUnins_cons_not_lt h]
    · rw [rowInsert_cons_not_lt us hxu] at hy ⊢
      simp only at hy ⊢
      rw [rowUnins_cons_lt (rowInsert_head_lt hr.2 hy), ih hr.2 hx.2 hy]

theorem rowInsert_rowUnins {r : List ℕ} {y : ℕ} (hr : r.Pairwise (· < ·)) (hy : y ∉ r)
    (hh : r.headD y < y) :
    rowInsert (rowUnins r y).1 (rowUnins r y).2 = (r, some y) ∧ (rowUnins r y).1.Pairwise (· < ·) ∧
    (rowUnins r y).2 ∈ r ∧ (y :: r).Perm ((rowUnins r y).2 :: (rowUnins r y).1) := by
  induction r with
  | nil => simp at hh
  | cons u us ih =>
    rw [List.pairwise_cons] at hr
    simp only [List.mem_cons, not_or] at hy
    simp only [List.headD_cons] at hh
    by_cases h : us.headD y < y
    · rw [rowUnins_cons_lt h]
      obtain ⟨h1, h2, h3, h4⟩ := ih hr.2 hy.2 h
      simp only
      refine ⟨?_, ?_, ?_, ?_⟩
      · rw [rowInsert_cons_not_lt _ (by have := hr.1 _ h3; omega), h1]
      · refine List.pairwise_cons.2 ⟨fun e he => ?_, h2⟩
        have : e ∈ y :: us := h4.symm.subset (List.mem_cons_of_mem _ he)
        rcases List.mem_cons.1 this with h' | h'
        · rw [h']; exact hh
        · exact hr.1 e h'
      · exact List.mem_cons_of_mem _ h3
      · exact (List.Perm.swap u y us).trans ((h4.cons u).trans (List.Perm.swap _ _ _))
    · rw [rowUnins_cons_not_lt h]
      simp only
      refine ⟨?_, ?_, by simp, List.Perm.swap _ _ _⟩
      · rw [rowInsert_cons_lt _ hh]
      · refine List.pairwise_cons.2 ⟨fun e he => ?_, hr.2⟩
        cases us with
        | nil => simp at he
        | cons v vs =>
          simp only [List.headD_cons, not_lt] at h
          have hv : y ≠ v := fun h' => hy.2 (by simp [h'])
          rcases List.mem_cons.1 he with h' | h'
          · rw [h']; omega
          · have := (List.pairwise_cons.1 hr.2).1 e h'; omega

theorem rowsOK_unins_last {a c : List ℕ} {y : ℕ} (hc : (c ++ [y]).Pairwise (· < ·))
    (hab : RowsOK a (c ++ [y])) : RowsOK (rowUnins a y).1 c := by
  induction c generalizing a with
  | nil => simp
  | cons v cs ih =>
    cases a with
    | nil => simp at hab
    | cons u us =>
      simp only [List.cons_append, rowsOK_cons_cons] at hab
      rw [List.cons_append, List.pairwise_cons] at hc
      have hus : us.headD y < y := by
        cases us with
        | nil => cases cs <;> simp at hab
        | cons p ps =>
          simp only [List.headD_cons]
          cases cs with
          | nil => simpa using hab.2
          | cons q qs =>
            have h1 := hab.2
            simp only [List.cons_append, rowsOK_cons_cons] at h1
            have h2 := hc.2
            simp only [List.cons_append, List.pairwise_cons] at h2
            have := h2.1 y (by simp)
            omega
      rw [rowUnins_cons_lt hus]
      simp only [rowsOK_cons_cons]
      exact ⟨hab.1, ih hc.2 hab.2⟩

theorem rowsOK_unins_ins {us vs : List ℕ} {v : ℕ} (h : RowsOK us vs) (hv : ∀ e ∈ vs, v < e) :
    RowsOK (rowUnins us v).1 vs := by
  induction us generalizing vs with
  | nil => simpa [rowUnins] using h
  | cons p ps ih =>
    cases vs with
    | nil => simp
    | cons q qs =>
      simp only [rowsOK_cons_cons] at h
      simp only [List.mem_cons, forall_eq_or_imp] at hv
      by_cases hp : ps.headD v < v
      · rw [rowUnins_cons_lt hp]; simp only [rowsOK_cons_cons]; exact ⟨h.1, ih h.2 hv.2⟩
      · rw [rowUnins_cons_not_lt hp]; simp only [rowsOK_cons_cons]; exact ⟨hv.1, h.2⟩

theorem rowsOK_unins_step {a b : List ℕ} {z : ℕ} (hb : b.Pairwise (· < ·))
    (hab : RowsOK a b) (hz : b.headD z < z) :
    RowsOK (rowUnins a (rowUnins b z).2).1 (rowUnins b z).1 := by
  induction b generalizing a with
  | nil => simp at hz
  | cons v vs ih =>
    cases a with
    | nil => simp at hab
    | cons u us =>
      simp only [rowsOK_cons_cons] at hab
      rw [List.pairwise_cons] at hb
      simp only [List.headD_cons] at hz
      by_cases hv : vs.headD z < z
      · rw [rowUnins_cons_lt hv]
        simp only
        have hyv : (rowUnins vs z).2 ∈ vs := rowUnins_mem hv
        have hus : us.headD (rowUnins vs z).2 < (rowUnins vs z).2 := by
          cases vs with
          | nil => simp at hyv
          | cons q qs =>
            cases us with
            | nil => simp at hab
            | cons p ps =>
              have h1 := hab.2
              simp only [rowsOK_cons_cons] at h1
              simp only [List.headD_cons]
              have : q ≤ (rowUnins (q :: qs) z).2 := by
                rcases List.mem_cons.1 hyv with h | h
                · omega
                · exact ((List.pairwise_cons.1 hb.2).1 _ h).le
              omega
        rw [rowUnins_cons_lt hus]
        simp only [rowsOK_cons_cons]
        exact ⟨hab.1, ih hb.2 hab.2 hv⟩
      · rw [rowUnins_cons_not_lt hv]
        simp only
        by_cases hu : us.headD v < v
        · rw [rowUnins_cons_lt hu]; simp only [rowsOK_cons_cons]
          exact ⟨by omega, rowsOK_unins_ins hab.2 hb.1⟩
        · rw [rowUnins_cons_not_lt hu]; simp only [rowsOK_cons_cons]; exact ⟨hz, hab.2⟩

/-! ### Tableau insertion -/

theorem insertP_cons_none {row : List ℕ} {rows : List (List ℕ)} {x : ℕ}
    (h : (rowInsert row x).2 = none) : insertP (row :: rows) x = ((rowInsert row x).1 :: rows, 0) := by
  have e : rowInsert row x = ((rowInsert row x).1, none) := Prod.ext rfl h
  rw [insertP, e]

theorem insertP_cons_some {row : List ℕ} {rows : List (List ℕ)} {x y : ℕ}
    (h : (rowInsert row x).2 = some y) :
    insertP (row :: rows) x = ((rowInsert row x).1 :: (insertP rows y).1, (insertP rows y).2 + 1) := by
  have e : rowInsert row x = ((rowInsert row x).1, some y) := Prod.ext rfl h
  rw [insertP, e]

theorem insertP_head (P : List (List ℕ)) (x : ℕ) :
    (insertP P x).1.headD [] = (rowInsert (P.headD []) x).1 := by
  cases P with
  | nil => rfl
  | cons row rows =>
    rcases h : (rowInsert row x).2 with _ | y
    · rw [insertP_cons_none h]; rfl
    · rw [insertP_cons_some h]; rfl

theorem shape_cons (r : List ℕ) (rs : List (List ℕ)) : shape (r :: rs) = r.length :: shape rs := rfl

theorem tab_insertP (P : List (List ℕ)) (x : ℕ) (hP : Tab P) (hnd : P.flatten.Nodup)
    (hx : x ∉ P.flatten) :
    Tab (insertP P x).1 ∧ (insertP P x).1.flatten.Perm (x :: P.flatten) ∧
    shape (insertP P x).1 = incAt (shape P) (insertP P x).2 ∧ (insertP P x).2 ≤ P.length := by
  induction P generalizing x with
  | nil => simp [insertP, Tab, shape, incAt]
  | cons row rows ih =>
    rw [tab_cons] at hP
    obtain ⟨hne, hsort, hok, hrows⟩ := hP
    rw [List.flatten_cons] at hnd hx
    rw [List.mem_append, not_or] at hx
    rcases h : (rowInsert row x).2 with _ | y
    · rw [insertP_cons_none h]
      have e := rowInsert_snd_none h
      refine ⟨?_, ?_, ?_, by simp⟩
      · rw [tab_cons]
        exact ⟨rowInsert_fst_ne_nil _ _, rowInsert_sorted hsort hx.1, rowsOK_rowInsert_left x hok, hrows⟩
      · rw [e]; simp only [List.flatten_cons, List.append_assoc, List.singleton_append]
        exact List.perm_middle
      · rw [e]; simp [shape, incAt]
    · rw [insertP_cons_some h]
      have hy : y ∈ row := rowInsert_snd_mem h
      have hyr : y ∉ rows.flatten := fun h' => List.disjoint_of_nodup_append hnd hy h'
      obtain ⟨t1, t2, t3, t4⟩ := ih y hrows hnd.of_append_right hyr
      refine ⟨?_, ?_, ?_, by simp; omega⟩
      · rw [tab_cons]
        refine ⟨rowInsert_fst_ne_nil _ _, rowInsert_sorted hsort hx.1, ?_, t1⟩
        rw [insertP_head]
        exact rowsOK_insert_step hsort hok hx.1 h
      · have hp := rowInsert_perm row x
        rw [h] at hp
        simp only [Option.toList_some] at hp
        rw [List.flatten_cons]
        have h1 : List.Perm ((rowInsert row x).1 ++ (y :: rows.flatten)) (x :: (row ++ rows.flatten)) := by
          have := hp.append_right rows.flatten
          simpa using this
        exact (t2.append_left _).trans h1
      · rw [shape_cons, shape_cons, t3, rowInsert_length_some h]; rfl

/-! ### Tableau deletion -/

theorem tab_shrink {c : List ℕ} {y : ℕ} {rs : List (List ℕ)} (h : Tab ((c ++ [y]) :: rs))
    (hl : (rs.headD []).length ≤ c.length) (hc : c ≠ []) : Tab (c :: rs) := by
  rw [tab_cons] at h ⊢
  exact ⟨hc, h.2.1.sublist (List.sublist_append_left _ _), rowsOK_shrink h.2.2.1 hl, h.2.2.2⟩

theorem tab_rest_nil {r : List ℕ} {rs : List (List ℕ)} (h : Tab (r :: rs))
    (hl : (rs.headD []).length < 1) : rs = [] := by
  cases rs with
  | nil => rfl
  | cons b bs =>
    simp only [List.headD_cons, Nat.lt_one_iff, List.length_eq_zero_iff] at hl
    exact absurd hl ((tab_cons _ _).1 ((tab_cons _ _).1 h).2.2.2).1

theorem exists_concat {r : List ℕ} (hne : r ≠ []) : ∃ c y, r = c ++ [y] :=
  ⟨r.dropLast, r.getLast hne, (List.dropLast_append_getLast hne).symm⟩

theorem deleteP_spec (P : List (List ℕ)) (i : ℕ) (hP : Tab P) (hnd : P.flatten.Nodup)
    (hi : i < P.length) (hc : (P.getD (i + 1) []).length < (P.getD i []).length) :
    insertP (deleteP P i).1 (deleteP P i).2 = (P, i) ∧ Tab (deleteP P i).1 ∧
    P.flatten.Perm ((deleteP P i).2 :: (deleteP P i).1.flatten) ∧ (deleteP P i).2 ∈ P.headD [] ∧
    (∀ a : List ℕ, RowsOK a (P.headD []) →
      RowsOK (rowUnins a (deleteP P i).2).1 ((deleteP P i).1.headD [])) ∧
    shape (deleteP P i).1 = shape (dropBox P i) := by
  induction P generalizing i with
  | nil => simp at hi
  | cons r rs ih =>
    have hT := hP
    rw [tab_cons] at hP
    obtain ⟨hne, hsort, hok, hrs⟩ := hP
    cases i with
    | zero =>
      simp only [List.getD_cons_succ, List.getD_cons_zero, getD_zero_eq_headD] at hc
      obtain ⟨c, y, rfl⟩ := exists_concat hne
      by_cases hc0 : c = []
      · subst hc0
        have := tab_rest_nil hT (by simpa using hc)
        subst this
        simp [deleteP, dropBox, insertP, shape, rowInsert_nil]
      · have hd : deleteP ((c ++ [y]) :: rs) 0 = (c :: rs, y) := by simp [deleteP, hc0]
        have hdb : dropBox ((c ++ [y]) :: rs) 0 = c :: rs := by simp [dropBox, hc0]
        rw [hd, hdb]
        have hcy := List.pairwise_append.1 hsort
        refine ⟨?_, tab_shrink hT (by simp only [List.length_append, List.length_singleton] at hc; omega) hc0, ?_, by simp, ?_, rfl⟩
        · have hr : rowInsert c y = (c ++ [y], none) :=
            rowInsert_of_forall (fun e he => by have := hcy.2.2 e he y (by simp); omega)
          rw [insertP_cons_none (by rw [hr]), hr]
        · simp only [List.flatten_cons, List.append_assoc, List.singleton_append]
          exact List.perm_middle
        · intro a ha
          exact rowsOK_unins_last hsort ha
    | succ i' =>
      simp only [List.length_cons, Nat.add_lt_add_iff_right] at hi
      simp only [List.getD_cons_succ] at hc
      rw [List.flatten_cons] at hnd
      obtain ⟨s1, s2, s3, s4, s5, s6⟩ := ih i' hrs hnd.of_append_right hi hc
      have hzh : r.headD (deleteP rs i').2 < (deleteP rs i').2 :=
        head_lt_of_mem hok hne (tab_head_sorted hrs) s4
      have hzr : (deleteP rs i').2 ∉ r := fun h' =>
        List.disjoint_of_nodup_append hnd h' (mem_flatten_of_mem_head s4)
      obtain ⟨u1, u2, u3, u4⟩ := rowInsert_rowUnins hsort hzr hzh
      have hd : deleteP (r :: rs) (i' + 1) = ((rowUnins r (deleteP rs i').2).1 :: (deleteP rs i').1,
          (rowUnins r (deleteP rs i').2).2) := rfl
      rw [hd]
      refine ⟨?_, ?_, ?_, u3, ?_, ?_⟩
      · rw [insertP_cons_some (by rw [u1]), s1, u1]
      · rw [tab_cons]
        exact ⟨rowUnins_ne_nil _ hne, u2, s5 r hok, s2⟩
      · rw [List.flatten_cons, List.flatten_cons]
        exact (s3.append_left r).trans (List.perm_middle.trans (u4.append_right _))
      · intro a ha
        exact rowsOK_unins_step hsort ha hzh
      · have hl := u4.length_eq
        simp only [List.length_cons, Nat.add_right_cancel_iff] at hl
        simp only [dropBox, shape_cons, s6, hl]

/-! ### The recording tableau -/

theorem shape_addAt (Q : List (List ℕ)) (i k : ℕ) : shape (addAt Q i k) = incAt (shape Q) i := by
  induction Q generalizing i with
  | nil => simp [addAt, shape, incAt]
  | cons r rs ih => cases i with
    | zero => simp [addAt, shape_cons, incAt]
    | succ j => simp only [addAt, shape_cons, incAt, ih]

theorem flatten_addAt (Q : List (List ℕ)) (i k : ℕ) : (addAt Q i k).flatten.Perm (k :: Q.flatten) := by
  induction Q generalizing i with
  | nil => simp [addAt]
  | cons r rs ih => cases i with
    | zero =>
      simp only [addAt, List.flatten_cons, List.append_assoc, List.singleton_append]
      exact List.perm_middle
    | succ j =>
      simp only [addAt, List.flatten_cons]
      exact ((ih j).append_left r).trans List.perm_middle

theorem findRow_addAt {Q : List (List ℕ)} {i k : ℕ} (hk : k ∉ Q.flatten) (hi : i ≤ Q.length) :
    findRow (addAt Q i k) k = i := by
  induction Q generalizing i with
  | nil => simp at hi; subst hi; simp [addAt, findRow]
  | cons r rs ih =>
    simp only [List.flatten_cons, List.mem_append, not_or] at hk
    cases i with
    | zero => simp [addAt, findRow]
    | succ j =>
      simp only [List.length_cons, Nat.add_le_add_iff_right] at hi
      simp [addAt, findRow, hk.1, ih hk.2 hi]

theorem dropBox_addAt {Q : List (List ℕ)} {i : ℕ} (k : ℕ) (hQ : ∀ r ∈ Q, r ≠ [])
    (hi : i ≤ Q.length) : dropBox (addAt Q i k) i = Q := by
  induction Q generalizing i with
  | nil => simp at hi; subst hi; simp [addAt, dropBox]
  | cons r rs ih =>
    simp only [List.forall_mem_cons] at hQ
    cases i with
    | zero => simp [addAt, dropBox, hQ.1]
    | succ j =>
      simp only [List.length_cons, Nat.add_le_add_iff_right] at hi
      simp only [addAt, dropBox, ih hQ.2 hi]

theorem headD_length_of_shape {A B : List (List ℕ)} (h : shape A = shape B) :
    (A.headD []).length = (B.headD []).length := by
  cases A with
  | nil => cases B with
    | nil => rfl
    | cons _ _ => simp [shape] at h
  | cons a as => cases B with
    | nil => simp [shape] at h
    | cons b bs => simp only [shape_cons, List.cons.injEq] at h; simpa using h.1

theorem getD_length_of_shape {A B : List (List ℕ)} (h : shape A = shape B) (j : ℕ) :
    (A.getD j []).length = (B.getD j []).length := by
  induction A generalizing B j with
  | nil => cases B with
    | nil => rfl
    | cons _ _ => simp [shape] at h
  | cons a as ih => cases B with
    | nil => simp [shape] at h
    | cons b bs =>
      simp only [shape_cons, List.cons.injEq] at h
      cases j with
      | zero => simpa using h.1
      | succ j => simpa using ih h.2 j

theorem length_eq_of_shape {A B : List (List ℕ)} (h : shape A = shape B) : A.length = B.length := by
  simpa [shape] using congrArg List.length h

theorem shape_dropBox {P Q : List (List ℕ)} (h : shape P = shape Q) (i : ℕ) :
    shape (dropBox P i) = shape (dropBox Q i) := by
  induction P generalizing Q i with
  | nil => cases Q with
    | nil => rfl
    | cons _ _ => simp [shape] at h
  | cons r rs ih => cases Q with
    | nil => simp [shape] at h
    | cons q qs =>
      rw [shape_cons, shape_cons, List.cons.injEq] at h
      cases i with
      | zero => simp only [dropBox]; rw [h.1]; split_ifs <;> simp [shape_cons, h.1, h.2]
      | succ j => simp only [dropBox, shape_cons, h.1, ih h.2]

theorem tab_addAt (Q : List (List ℕ)) (i k : ℕ) (T : List (List ℕ)) (hQ : Tab Q)
    (hk : ∀ e ∈ Q.flatten, e < k) (hT : Tab T) (hs : shape T = shape (addAt Q i k)) :
    Tab (addAt Q i k) := by
  induction Q generalizing i T with
  | nil => simp [addAt, tab_cons]
  | cons r rs ih =>
    rw [tab_cons] at hQ
    obtain ⟨hne, hsort, hok, hrs⟩ := hQ
    simp only [List.flatten_cons, List.mem_append] at hk
    cases i with
    | zero =>
      simp only [addAt, tab_cons]
      refine ⟨by simp, ?_, rowsOK_append_right _ hok, hrs⟩
      exact List.pairwise_append.2 ⟨hsort, by simp, fun a ha b hb => by
        simp at hb; rw [hb]; exact hk a (Or.inl ha)⟩
    | succ j =>
      simp only [addAt] at hs ⊢
      cases T with
      | nil => simp [shape] at hs
      | cons t ts =>
        rw [shape_cons, shape_cons, List.cons.injEq] at hs
        rw [tab_cons] at hT
        have hA := ih j ts hrs (fun e he => hk e (Or.inr he)) hT.2.2.2 hs.2
        rw [tab_cons]
        refine ⟨hne, hsort, ?_, hA⟩
        have hlen : ((addAt rs j k).headD []).length ≤ r.length := by
          rw [← headD_length_of_shape hs.2, ← hs.1]; exact rowsOK_length hT.2.2.1
        cases rs with
        | nil =>
          obtain ⟨p, ps, rfl⟩ := List.exists_cons_of_ne_nil hne
          simp [addAt, hk p (Or.inl (by simp))]
        | cons b bs =>
          cases j with
          | zero =>
            simp only [addAt, List.headD_cons] at hlen ⊢
            simp only [List.headD_cons] at hok
            exact rowsOK_snoc hok (by simp at hlen; omega) (fun e he => hk e (Or.inl he))
          | succ j' => simpa [addAt] using hok

theorem rowsOK_dropBox_head {r : List ℕ} {rs : List (List ℕ)} {j : ℕ} (hrs : Tab rs)
    (hc : (rs.getD (j + 1) []).length < (rs.getD j []).length) (h : RowsOK r (rs.headD [])) :
    RowsOK r ((dropBox rs j).headD []) := by
  cases rs with
  | nil => simp [dropBox]
  | cons b bs =>
    cases j with
    | zero =>
      simp only [List.getD_cons_succ, List.getD_cons_zero, getD_zero_eq_headD] at hc
      simp only [dropBox]
      split_ifs with hb
      · rw [tab_rest_nil hrs (by omega)]; simp
      · have hne := ((tab_cons _ _).1 hrs).1
        obtain ⟨c, y, rfl⟩ := exists_concat hne
        simp only [List.headD_cons, List.dropLast_concat] at h ⊢
        exact rowsOK_prefix h
    | succ j' => simpa [dropBox] using h

theorem qmax_spec (Q : List (List ℕ)) (k : ℕ) (hQ : Tab Q) (hnd : Q.flatten.Nodup)
    (hk : k ∈ Q.flatten) (hle : ∀ e ∈ Q.flatten, e ≤ k) :
    findRow Q k < Q.length ∧
    (Q.getD (findRow Q k + 1) []).length < (Q.getD (findRow Q k) []).length ∧
    addAt (dropBox Q (findRow Q k)) (findRow Q k) k = Q ∧ Tab (dropBox Q (findRow Q k)) ∧
    Q.flatten.Perm (k :: (dropBox Q (findRow Q k)).flatten) := by
  induction Q with
  | nil => simp at hk
  | cons r rs ih =>
    have hT := hQ
    rw [tab_cons] at hQ
    obtain ⟨hne, hsort, hok, hrs⟩ := hQ
    rw [List.flatten_cons] at hnd
    simp only [List.flatten_cons, List.mem_append] at hk hle
    by_cases hkr : k ∈ r
    · have hf : findRow (r :: rs) k = 0 := by simp [findRow, hkr]
      rw [hf]
      obtain ⟨c, y, rfl⟩ := exists_concat hne
      have hyk : y = k := by
        rcases List.mem_append.1 hkr with h | h
        · have h1 := (List.pairwise_append.1 hsort).2.2 k h y (by simp)
          have h2 := hle y (Or.inl (by simp))
          omega
        · exact (List.mem_singleton.1 h).symm
      subst hyk
      have hcorner : (rs.headD []).length < c.length + 1 := by
        by_contra hcon
        have hl := rowsOK_length hok
        simp only [List.length_append, List.length_singleton] at hl
        obtain ⟨e, he, hye⟩ := rowsOK_full hok (by omega)
        have := hle e (Or.inr (mem_flatten_of_mem_head he))
        omega
      refine ⟨by simp, by simp only [List.getD_cons_succ, List.getD_cons_zero, getD_zero_eq_headD, List.length_append, List.length_singleton]; exact hcorner, ?_⟩
      by_cases hc0 : c = []
      · subst hc0
        have := tab_rest_nil hT (by simpa using hcorner)
        subst this
        simp [dropBox, addAt]
      · have hdb : dropBox ((c ++ [y]) :: rs) 0 = c :: rs := by simp [dropBox, hc0]
        rw [hdb]
        refine ⟨rfl, tab_shrink hT (by omega) hc0, ?_⟩
        simp only [List.flatten_cons, List.append_assoc, List.singleton_append]
        exact List.perm_middle
    · have hf : findRow (r :: rs) k = findRow rs k + 1 := by simp [findRow, hkr]
      have hk' : k ∈ rs.flatten := by simpa [hkr] using hk
      obtain ⟨a1, a2, a3, a4, a5⟩ :=
        ih hrs hnd.of_append_right hk' (fun e he => hle e (Or.inr he))
      rw [hf]
      refine ⟨by simp; omega, by simpa using a2, ?_, ?_, ?_⟩
      · simp only [dropBox, addAt, a3]
      · simp only [dropBox]
        rw [tab_cons]
        exact ⟨hne, hsort, rowsOK_dropBox_head hrs a2 hok, a4⟩
      · simp only [dropBox, List.flatten_cons]
        exact (a5.append_left r).trans List.perm_middle

/-! ### Standard tableaux as `Tab` -/

theorem rowsOK_iff (a b : List ℕ) :
    RowsOK a b ↔ b.length ≤ a.length ∧ ∀ j < b.length, a.getD j 0 < b.getD j 0 := by
  induction a generalizing b with
  | nil => cases b with
    | nil => simp
    | cons _ _ => simp
  | cons x xs ih => cases b with
    | nil => simp
    | cons y ys =>
      simp only [rowsOK_cons_cons, ih, List.length_cons]
      constructor
      · rintro ⟨h1, h2, h3⟩
        refine ⟨by omega, fun j hj => ?_⟩
        cases j with
        | zero => simpa using h1
        | succ j => simpa using h3 j (by omega)
      · rintro ⟨hl, hj⟩
        refine ⟨by simpa using hj 0 (by omega), by omega, fun j hj' => by simpa using hj (j + 1) (by omega)⟩

theorem tab_iff (T : List (List ℕ)) : Tab T ↔ (∀ row ∈ T, row ≠ []) ∧
    (∀ row ∈ T, row.Pairwise (· < ·)) ∧
    (∀ i, (T.getD (i + 1) []).length ≤ (T.getD i []).length ∧
      ∀ j < (T.getD (i + 1) []).length, (T.getD i []).getD j 0 < (T.getD (i + 1) []).getD j 0) := by
  induction T with
  | nil => simp
  | cons r rs ih =>
    rw [tab_cons, ih]
    simp only [List.forall_mem_cons]
    constructor
    · rintro ⟨hne, hs, hok, h1, h2, h3⟩
      refine ⟨⟨hne, h1⟩, ⟨hs, h2⟩, fun i => ?_⟩
      cases i with
      | zero =>
        simp only [List.getD_cons_succ, List.getD_cons_zero, getD_zero_eq_headD]
        exact (rowsOK_iff _ _).1 hok
      | succ i => simp only [List.getD_cons_succ]; exact h3 i
    · rintro ⟨⟨h1, h1'⟩, ⟨h2, h2'⟩, h3⟩
      refine ⟨h1, h2, ?_, h1', h2', fun i => by simpa only [List.getD_cons_succ] using h3 (i + 1)⟩
      have := h3 0
      simp only [List.getD_cons_succ, List.getD_cons_zero, getD_zero_eq_headD] at this
      exact (rowsOK_iff _ _).2 this

theorem isStandard_iff (n : ℕ) (T : List (List ℕ)) :
    IsStandard n T ↔ Tab T ∧ T.flatten.Perm (List.range' 1 n) := by
  simp only [IsStandard, tab_iff, and_assoc]

theorem tab_rows_ne {Q : List (List ℕ)} (h : Tab Q) : ∀ r ∈ Q, r ≠ [] := ((tab_iff Q).1 h).1

/-! ### RSK and its inverse -/

def rskStep (s : List (List ℕ) × List (List ℕ) × ℕ) (x : ℕ) : List (List ℕ) × List (List ℕ) × ℕ :=
  let r := insertP s.1 x
  (r.1, addAt s.2.1 r.2 (s.2.2 + 1), s.2.2 + 1)

theorem rsk_eq (w : List ℕ) :
    rsk w = ((w.foldl rskStep ([], [], 0)).1, (w.foldl rskStep ([], [], 0)).2.1) := rfl

theorem rsk_fold_count (w : List ℕ) (s : List (List ℕ) × List (List ℕ) × ℕ) :
    (w.foldl rskStep s).2.2 = s.2.2 + w.length := by
  induction w generalizing s with
  | nil => simp
  | cons x xs ih => simp only [List.foldl_cons, ih, rskStep, List.length_cons]; omega

theorem rsk_append (w : List ℕ) (x : ℕ) :
    rsk (w ++ [x]) = ((insertP (rsk w).1 x).1, addAt (rsk w).2 (insertP (rsk w).1 x).2 (w.length + 1)) := by
  rw [rsk_eq, rsk_eq, List.foldl_append, List.foldl_cons, List.foldl_nil]
  simp only [rskStep, rsk_fold_count]
  simp

theorem rsk_inv (w : List ℕ) (hw : w.Nodup) :
    Tab (rsk w).1 ∧ (rsk w).1.flatten.Perm w ∧ Tab (rsk w).2 ∧
    (rsk w).2.flatten.Perm (List.range' 1 w.length) ∧ shape (rsk w).1 = shape (rsk w).2 := by
  induction w using List.reverseRecOn with
  | nil => simp [rsk_eq, Tab, shape]
  | append_singleton w x ih =>
    have hw' : w.Nodup := hw.sublist (List.sublist_append_left _ _)
    have hxw : x ∉ w := fun h => List.disjoint_of_nodup_append hw h (List.mem_singleton_self x)
    obtain ⟨p1, p2, q1, q2, s⟩ := ih hw'
    have hnd : (rsk w).1.flatten.Nodup := p2.nodup_iff.2 hw'
    have hx : x ∉ (rsk w).1.flatten := fun h => hxw (p2.subset h)
    obtain ⟨i1, i2, i3, i4⟩ := tab_insertP _ x p1 hnd hx
    rw [rsk_append]
    refine ⟨i1, i2.trans ((p2.cons x).trans (List.perm_append_singleton x w).symm), ?_, ?_, ?_⟩
    · exact tab_addAt _ _ _ _ q1
        (fun e he => by have := List.mem_range'_1.1 (q2.subset he); omega) i1
        (by rw [i3, shape_addAt, s])
    · refine (flatten_addAt _ _ _).trans ?_
      rw [List.length_append, List.length_singleton, List.range'_1_concat]
      refine ((q2.cons _).trans ?_)
      rw [show 1 + w.length = w.length + 1 by omega]
      exact (List.perm_append_singleton _ _).symm
    · rw [i3, shape_addAt, s]

theorem deleteP_insertP (P : List (List ℕ)) (x : ℕ) (hP : Tab P) (hnd : P.flatten.Nodup)
    (hx : x ∉ P.flatten) : deleteP (insertP P x).1 (insertP P x).2 = (P, x) := by
  induction P generalizing x with
  | nil => simp [insertP, deleteP]
  | cons row rows ih =>
    rw [tab_cons] at hP
    obtain ⟨hne, hsort, hok, hrows⟩ := hP
    rw [List.flatten_cons] at hnd hx
    rw [List.mem_append, not_or] at hx
    rcases h : (rowInsert row x).2 with _ | y
    · rw [insertP_cons_none h, rowInsert_snd_none h]
      simp [deleteP, hne]
    · rw [insertP_cons_some h, deleteP]
      have hy : y ∈ row := rowInsert_snd_mem h
      have hyr : y ∉ rows.flatten := fun h' => List.disjoint_of_nodup_append hnd hy h'
      rw [ih y hrows hnd.of_append_right hyr]
      simp only
      rw [rowUnins_rowInsert hsort hx.1 h]

def rskInv : ℕ → List (List ℕ) → List (List ℕ) → List ℕ
  | 0, _, _ => []
  | m + 1, P, Q => rskInv m (deleteP P (findRow Q (m + 1))).1 (dropBox Q (findRow Q (m + 1))) ++
      [(deleteP P (findRow Q (m + 1))).2]

theorem rskInv_rsk (w : List ℕ) (hw : w.Nodup) : rskInv w.length (rsk w).1 (rsk w).2 = w := by
  induction w using List.reverseRecOn with
  | nil => rfl
  | append_singleton w x ih =>
    have hw' : w.Nodup := hw.sublist (List.sublist_append_left _ _)
    have hxw : x ∉ w := fun h => List.disjoint_of_nodup_append hw h (List.mem_singleton_self x)
    obtain ⟨p1, p2, q1, q2, s⟩ := rsk_inv w hw'
    have hnd : (rsk w).1.flatten.Nodup := p2.nodup_iff.2 hw'
    have hx : x ∉ (rsk w).1.flatten := fun h => hxw (p2.subset h)
    obtain ⟨i1, i2, i3, i4⟩ := tab_insertP _ x p1 hnd hx
    have hlen := length_eq_of_shape s
    have hf : findRow (addAt (rsk w).2 (insertP (rsk w).1 x).2 (w.length + 1)) (w.length + 1) =
        (insertP (rsk w).1 x).2 :=
      findRow_addAt (fun h => by have := List.mem_range'_1.1 (q2.subset h); omega) (by omega)
    rw [rsk_append, List.length_append, List.length_singleton]
    simp only [rskInv]
    rw [hf, dropBox_addAt _ (tab_rows_ne q1) (by omega), deleteP_insertP _ _ p1 hnd hx]
    simp only
    rw [ih hw']

theorem rsk_rskInv (m : ℕ) : ∀ P Q : List (List ℕ), Tab P → P.flatten.Nodup → Tab Q →
    Q.flatten.Perm (List.range' 1 m) → shape P = shape Q →
    rsk (rskInv m P Q) = (P, Q) ∧ (rskInv m P Q).length = m ∧ (rskInv m P Q).Perm P.flatten := by
  induction m with
  | zero =>
    intro P Q hP hnd hQ hQf hs
    have h1 : Q.flatten = [] := List.perm_nil.1 (by simpa using hQf)
    have hQ0 : Q = [] := by
      cases Q with
      | nil => rfl
      | cons q qs =>
        simp only [List.flatten_cons, List.append_eq_nil_iff] at h1
        exact absurd h1.1 ((tab_cons _ _).1 hQ).1
    subst hQ0
    have hP0 : P = [] := by simpa [shape] using hs
    subst hP0
    simp [rskInv, rsk_eq]
  | succ m ih =>
    intro P Q hP hnd hQ hQf hs
    have hQnd : Q.flatten.Nodup := hQf.nodup_iff.2 List.nodup_range'
    have hk : m + 1 ∈ Q.flatten := hQf.symm.subset (by simp)
    have hle : ∀ e ∈ Q.flatten, e ≤ m + 1 := fun e he => by
      have := List.mem_range'_1.1 (hQf.subset he); omega
    obtain ⟨a1, a2, a3, a4, a5⟩ := qmax_spec Q (m + 1) hQ hQnd hk hle
    have hPi : findRow Q (m + 1) < P.length := by rw [length_eq_of_shape hs]; exact a1
    have hPc : (P.getD (findRow Q (m + 1) + 1) []).length < (P.getD (findRow Q (m + 1)) []).length := by
      rw [getD_length_of_shape hs, getD_length_of_shape hs]; exact a2
    obtain ⟨d1, d2, d3, d4, d5, d6⟩ := deleteP_spec P _ hP hnd hPi hPc
    have hQ'f : (dropBox Q (findRow Q (m + 1))).flatten.Perm (List.range' 1 m) := by
      have := a5.symm.trans hQf
      rw [List.range'_1_concat, show 1 + m = m + 1 by omega] at this
      exact (this.trans (List.perm_append_singleton _ _)).cons_inv
    have hnd' := (d3.nodup_iff.1 hnd).of_cons
    obtain ⟨r1, r2, r3⟩ := ih _ _ d2 hnd' a4 hQ'f (by rw [d6]; exact shape_dropBox hs _)
    have e : rskInv (m + 1) P Q = rskInv m (deleteP P (findRow Q (m + 1))).1
        (dropBox Q (findRow Q (m + 1))) ++ [(deleteP P (findRow Q (m + 1))).2] := rfl
    rw [e]
    refine ⟨?_, by simp [r2], (r3.append_right _).trans ((List.perm_append_singleton _ _).trans d3.symm)⟩
    rw [rsk_append, r1, r2]
    simp only
    rw [d1]
    simp only
    rw [a3]

/-! ### Shuffles as words -/

theorem word_perm {n : ℕ} (σ : Equiv.Perm (Fin n)) : (word σ).Perm (List.range' 1 n) := by
  have hnd : (word σ).Nodup := by
    unfold word
    rw [List.nodup_ofFn]
    intro i j h
    exact σ.injective (Fin.ext (by simpa using h))
  refine (List.perm_ext_iff_of_nodup hnd List.nodup_range').2 (fun a => ?_)
  unfold word
  rw [List.mem_ofFn, List.mem_range'_1]
  constructor
  · rintro ⟨i, rfl⟩; have := (σ i).isLt; omega
  · rintro ⟨h1, h2⟩
    exact ⟨σ.symm ⟨a - 1, by omega⟩, by simp; omega⟩

theorem word_inj {n : ℕ} {σ τ : Equiv.Perm (Fin n)} (h : word σ = word τ) : σ = τ := by
  unfold word at h
  rw [List.ofFn_inj] at h
  ext i
  have := congrFun h i
  omega

theorem exists_word {n : ℕ} {w : List ℕ} (h : w.Perm (List.range' 1 n)) :
    ∃ σ : Equiv.Perm (Fin n), word σ = w := by
  have hlen : w.length = n := by simpa using h.length_eq
  have hmem : ∀ i (hi : i < w.length), 1 ≤ w[i] ∧ w[i] < 1 + n := fun i hi =>
    List.mem_range'_1.1 (h.subset (List.getElem_mem hi))
  have hnd : w.Nodup := h.nodup_iff.2 List.nodup_range'
  let f : Fin n → Fin n := fun i =>
    ⟨w[i.1]'(by omega) - 1, by have := hmem i.1 (by omega); omega⟩
  have hf : Function.Injective f := by
    intro i j hij
    simp only [f, Fin.mk.injEq] at hij
    have h1 := hmem i.1 (by omega)
    have h2 := hmem j.1 (by omega)
    have h3 : w[i.1]'(by omega) = w[j.1]'(by omega) := by omega
    exact Fin.ext ((List.Nodup.getElem_inj_iff hnd).1 h3)
  refine ⟨Equiv.ofBijective f (Finite.injective_iff_bijective.1 hf), ?_⟩
  unfold word
  apply List.ext_getElem (by simp [hlen])
  intro k h1 h2
  simp only [List.getElem_ofFn, Equiv.ofBijective_apply, f]
  have := hmem k h2
  omega

theorem rsk_bijOn_aux (n : ℕ) :
    Set.BijOn (fun σ : Equiv.Perm (Fin n) => rsk (word σ)) Set.univ
      {PQ : List (List ℕ) × List (List ℕ) |
        IsStandard n PQ.1 ∧ IsStandard n PQ.2 ∧ shape PQ.1 = shape PQ.2} := by
  refine ⟨?_, ?_, ?_⟩
  · intro σ _
    have hp := word_perm σ
    obtain ⟨p1, p2, q1, q2, s⟩ := rsk_inv (word σ) (hp.nodup_iff.2 List.nodup_range')
    have hl : (word σ).length = n := by simpa using hp.length_eq
    rw [hl] at q2
    exact ⟨(isStandard_iff _ _).2 ⟨p1, p2.trans hp⟩, (isStandard_iff _ _).2 ⟨q1, q2⟩, s⟩
  · intro σ _ τ _ h
    simp only at h
    apply word_inj
    have hσ := rskInv_rsk (word σ) ((word_perm σ).nodup_iff.2 List.nodup_range')
    have hτ := rskInv_rsk (word τ) ((word_perm τ).nodup_iff.2 List.nodup_range')
    have lσ : (word σ).length = n := by simpa using (word_perm σ).length_eq
    have lτ : (word τ).length = n := by simpa using (word_perm τ).length_eq
    rw [lσ] at hσ
    rw [lτ] at hτ
    rw [← hσ, ← hτ, h]
  · rintro ⟨P, Q⟩ ⟨hP, hQ, hs⟩
    rw [isStandard_iff] at hP hQ
    obtain ⟨r1, r2, r3⟩ := rsk_rskInv n P Q hP.1 (hP.2.nodup_iff.2 List.nodup_range') hQ.1 hQ.2 hs
    obtain ⟨σ, hσ⟩ := exists_word (r3.trans hP.2)
    exact ⟨σ, trivial, by simp only; rw [hσ, r1]⟩

/-! ### Schensted: the first row -/

theorem rowInsert_filter_le {R : List ℕ} {x : ℕ} (v : ℕ) :
    (R.filter (· ≤ v)).length ≤ ((rowInsert R x).1.filter (· ≤ v)).length := by
  induction R with
  | nil => simp
  | cons y ys ih =>
    by_cases hxy : x < y
    · rw [rowInsert_cons_lt ys hxy]
      simp only [List.filter_cons]
      by_cases h1 : x ≤ v <;> by_cases h2 : y ≤ v <;> simp [h1, h2] <;> omega
    · rw [rowInsert_cons_not_lt ys hxy]
      simp only [List.filter_cons]
      by_cases h2 : y ≤ v <;> simp [h2] <;> omega

theorem rowInsert_filter_self {R : List ℕ} {x : ℕ} (hR : R.Pairwise (· < ·)) (hx : x ∉ R) :
    ((rowInsert R x).1.filter (· ≤ x)).length = (R.filter (· < x)).length + 1 := by
  induction R with
  | nil => simp [rowInsert_nil]
  | cons y ys ih =>
    rw [List.pairwise_cons] at hR
    simp only [List.mem_cons, not_or] at hx
    by_cases hxy : x < y
    · rw [rowInsert_cons_lt ys hxy]
      have h1 : ys.filter (· ≤ x) = [] :=
        List.filter_eq_nil_iff.2 (fun e he => by have := hR.1 e he; simp; omega)
      have h2 : ys.filter (· < x) = [] :=
        List.filter_eq_nil_iff.2 (fun e he => by have := hR.1 e he; simp; omega)
      rw [List.filter_cons_of_pos (by simp), h1, List.filter_cons_of_neg (by simp; omega), h2]
      simp
    · have hyx : y < x := by omega
      rw [rowInsert_cons_not_lt ys hxy]
      rw [List.filter_cons_of_pos (by simp; omega), List.filter_cons_of_pos (by simp; omega)]
      simp [ih hR.2 hx.2]

theorem rowInsert_filter_other {R : List ℕ} {x r : ℕ} (hR : R.Pairwise (· < ·)) (hx : x ∉ R)
    (hr : r ∈ (rowInsert R x).1) (hrx : r ≠ x) :
    r ∈ R ∧ ((rowInsert R x).1.filter (· ≤ r)).length = (R.filter (· ≤ r)).length := by
  induction R with
  | nil => simp [rowInsert_nil] at hr; exact absurd hr hrx
  | cons y ys ih =>
    rw [List.pairwise_cons] at hR
    simp only [List.mem_cons, not_or] at hx
    by_cases hxy : x < y
    · rw [rowInsert_cons_lt ys hxy] at hr ⊢
      have hr' : r ∈ ys := by simpa [hrx] using hr
      have := hR.1 r hr'
      refine ⟨List.mem_cons_of_mem _ hr', ?_⟩
      rw [List.filter_cons_of_pos (by simp; omega), List.filter_cons_of_pos (by simp; omega)]
      simp
    · have hyx : y < x := by omega
      rw [rowInsert_cons_not_lt ys hxy] at hr ⊢
      rcases List.mem_cons.1 hr with h | h
      · rw [h]
        have e1 : (rowInsert ys x).1.filter (· ≤ y) = [] := List.filter_eq_nil_iff.2 (fun e he => by
          rcases rowInsert_mem_fst he with h' | h'
          · simp; omega
          · have := hR.1 e h'; simp; omega)
        have e2 : ys.filter (· ≤ y) = [] :=
          List.filter_eq_nil_iff.2 (fun e he => by have := hR.1 e he; simp; omega)
        refine ⟨by simp, ?_⟩
        rw [List.filter_cons_of_pos (by simp), List.filter_cons_of_pos (by simp), e1, e2]
      · obtain ⟨h1, h2⟩ := ih hR.2 hx.2 h
        have := hR.1 r h1
        refine ⟨List.mem_cons_of_mem _ h1, ?_⟩
        rw [List.filter_cons_of_pos (by simp; omega), List.filter_cons_of_pos (by simp; omega)]
        simp [h2]

theorem nil_or_snoc (l : List ℕ) : l = [] ∨ ∃ L b, l = L ++ [b] := by
  rcases List.eq_nil_or_concat l with h | ⟨L, b, h⟩
  · exact Or.inl h
  · exact Or.inr ⟨L, b, by simp [h]⟩

theorem schensted_inv (w : List ℕ) (hw : w.Nodup) :
    (∀ s y, (s ++ [y]).Sublist w → (s ++ [y]).Pairwise (· < ·) →
      s.length + 1 ≤ (((rsk w).1.headD []).filter (· ≤ y)).length) ∧
    (∀ r ∈ (rsk w).1.headD [], ∃ s, (s ++ [r]).Sublist w ∧ (s ++ [r]).Pairwise (· < ·) ∧
      s.length + 1 = (((rsk w).1.headD []).filter (· ≤ r)).length) := by
  induction w using List.reverseRecOn with
  | nil =>
    refine ⟨fun s y h _ => ?_, fun r hr => by simp [rsk_eq] at hr⟩
    have := h.length_le
    simp at this
  | append_singleton w x ih =>
    have hw' : w.Nodup := hw.sublist (List.sublist_append_left _ _)
    have hxw : x ∉ w := fun h => List.disjoint_of_nodup_append hw h (List.mem_singleton_self x)
    obtain ⟨p1, p2, -, -, -⟩ := rsk_inv w hw'
    obtain ⟨U, L⟩ := ih hw'
    have hR : ((rsk w).1.headD []).Pairwise (· < ·) := tab_head_sorted p1
    have hxR : x ∉ (rsk w).1.headD [] := fun h => hxw (p2.subset (mem_flatten_of_mem_head h))
    have hR' : (rsk (w ++ [x])).1.headD [] = (rowInsert ((rsk w).1.headD []) x).1 := by
      rw [rsk_append, insertP_head]
    rw [hR']
    generalize (rsk w).1.headD [] = R at U L hR hxR
    constructor
    · intro s y hsub hpw
      obtain ⟨l1, l2, heq, h1, h2⟩ := List.sublist_append_iff.1 hsub
      rcases List.sublist_singleton.1 h2 with rfl | rfl
      · simp only [List.append_nil] at heq
        rw [← heq] at h1
        exact (U s y h1 hpw).trans (rowInsert_filter_le y)
      · obtain ⟨rfl, hyx⟩ := List.append_inj' heq rfl
        simp only [List.cons.injEq, and_true] at hyx
        subst hyx
        rw [rowInsert_filter_self hR hxR]
        rcases nil_or_snoc s with rfl | ⟨s0, y0, rfl⟩
        · simp
        · have hu := U s0 y0 h1 (hpw.sublist (List.sublist_append_left _ _))
          have hyx : y0 < y := (List.pairwise_append.1 hpw).2.2 y0 (by simp) y (by simp)
          have hmono := (List.monotone_filter_right R (p := fun e => decide (e ≤ y0))
            (q := fun e => decide (e < y)) (fun a ha => by simp at ha ⊢; omega)).length_le
          simp only [List.length_append, List.length_singleton]
          omega
    · intro r hr
      by_cases hrx : r = x
      · rw [hrx, rowInsert_filter_self hR hxR]
        rcases nil_or_snoc (R.filter (· < x)) with hF | ⟨F0, r0, hF⟩
        · exact ⟨[], by simp, by simp, by simp [hF]⟩
        · have hr0 : r0 ∈ R.filter (· < x) := by rw [hF]; simp
          rw [List.mem_filter] at hr0
          have hr0x : r0 < x := by simpa using hr0.2
          obtain ⟨s0, hs1, hs2, hs3⟩ := L r0 hr0.1
          have hFs : (F0 ++ [r0]).Pairwise (· < ·) := hF ▸ hR.filter _
          have hcongr : R.filter (· ≤ r0) = R.filter (· < x) := by
            apply List.filter_congr
            intro e he
            simp only [decide_eq_decide]
            constructor
            · intro h; omega
            · intro h
              have hm : e ∈ F0 ++ [r0] := hF ▸ List.mem_filter.2 ⟨he, by simpa using h⟩
              rcases List.mem_append.1 hm with h' | h'
              · exact ((List.pairwise_append.1 hFs).2.2 e h' r0 (by simp)).le
              · simp at h'; omega
          refine ⟨s0 ++ [r0], hs1.append (List.Sublist.refl _), ?_, ?_⟩
          · refine List.pairwise_append.2 ⟨hs2, by simp, fun a ha b hb => ?_⟩
            simp only [List.mem_singleton] at hb
            rw [hb]
            rcases List.mem_append.1 ha with h' | h'
            · have := (List.pairwise_append.1 hs2).2.2 a h' r0 (by simp); omega
            · simp at h'; omega
          · rw [← hcongr, ← hs3]; simp
      · obtain ⟨hrR, hcnt⟩ := rowInsert_filter_other hR hxR hr hrx
        obtain ⟨s, hs1, hs2, hs3⟩ := L r hrR
        exact ⟨s, hs1.trans (List.sublist_append_left _ _), hs2, hs3.trans hcnt.symm⟩

theorem first_row_aux {n : ℕ} (σ : Equiv.Perm (Fin n)) :
    IsGreatest {k | ∃ s : List ℕ, s.Sublist (word σ) ∧ s.Pairwise (· < ·) ∧ s.length = k}
      ((rsk (word σ)).1.headD []).length := by
  have hw : (word σ).Nodup := (word_perm σ).nodup_iff.2 List.nodup_range'
  obtain ⟨U, L⟩ := schensted_inv _ hw
  have hR : ((rsk (word σ)).1.headD []).Pairwise (· < ·) := tab_head_sorted (rsk_inv _ hw).1
  generalize (rsk (word σ)).1.headD [] = R at U L hR
  constructor
  · rcases nil_or_snoc R with hR0 | ⟨R0, r, hR0⟩
    · exact ⟨[], List.nil_sublist _, List.Pairwise.nil, by simp [hR0]⟩
    · obtain ⟨s, h1, h2, h3⟩ := L r (by rw [hR0]; simp)
      refine ⟨s ++ [r], h1, h2, ?_⟩
      rw [List.length_append, List.length_singleton, h3]
      congr 1
      apply List.filter_eq_self.2
      intro e he
      rw [hR0] at hR he
      rcases List.mem_append.1 he with h' | h'
      · have := (List.pairwise_append.1 hR).2.2 e h' r (by simp); simp; omega
      · simp at h'; simp [h']
  · rintro k ⟨s, h1, h2, rfl⟩
    rcases nil_or_snoc s with rfl | ⟨s0, y, rfl⟩
    · simp
    · have := U s0 y h1 h2
      simp only [List.length_append, List.length_singleton]
      exact this.trans (List.length_filter_le _ _)

/-! ### Mathlib's standard tableaux as lists of rows -/

theorem getD_of_lt {α : Type} (l : List α) (d : α) {i : ℕ} (h : i < l.length) : l.getD i d = l[i] := by
  simp [List.getD_eq_getElem?_getD, h]

theorem getD_of_ge {α : Type} (l : List α) (d : α) {i : ℕ} (h : l.length ≤ i) : l.getD i d = d := by
  simp [List.getD_eq_getElem?_getD, h]

def ent (T : List (List ℕ)) (i j : ℕ) : ℕ := (T.getD i []).getD j 0

theorem shape_getD (T : List (List ℕ)) (i : ℕ) : (shape T).getD i 0 = (T.getD i []).length := by
  induction T generalizing i with
  | nil => simp [shape]
  | cons r rs ih => cases i with
    | zero => simp [shape_cons]
    | succ i => simp only [shape_cons, List.getD_cons_succ]; exact ih i

theorem rowLens_getD (μ : YoungDiagram) (i : ℕ) : μ.rowLens.getD i 0 = μ.rowLen i := by
  by_cases hi : i < μ.colLen 0
  · rw [getD_of_lt _ _ (by simpa using hi)]; simp
  · rw [getD_of_ge _ _ (by simpa using hi)]
    have : (i, 0) ∉ μ := by rw [YoungDiagram.mem_iff_lt_colLen]; exact hi
    rw [YoungDiagram.mem_iff_lt_rowLen] at this; omega

theorem len_getD_of_shape {μ : YoungDiagram} {T : List (List ℕ)} (hs : shape T = μ.rowLens) (i : ℕ) :
    (T.getD i []).length = μ.rowLen i := by
  rw [← shape_getD, hs, rowLens_getD]

theorem mem_iff_of_shape {μ : YoungDiagram} {T : List (List ℕ)} (hs : shape T = μ.rowLens) {i j : ℕ} :
    (i, j) ∈ μ ↔ j < (T.getD i []).length := by
  rw [YoungDiagram.mem_iff_lt_rowLen, len_getD_of_shape hs]

theorem getD_mem_of_lt {T : List (List ℕ)} {i j : ℕ} (h : j < (T.getD i []).length) :
    T.getD i [] ∈ T ∧ i < T.length := by
  by_cases hi : i < T.length
  · rw [getD_of_lt _ _ hi]; exact ⟨List.getElem_mem hi, hi⟩
  · rw [getD_of_ge _ _ (by omega)] at h; simp at h

theorem ent_mem {T : List (List ℕ)} {i j : ℕ} (h : j < (T.getD i []).length) : ent T i j ∈ T.flatten := by
  refine List.mem_flatten.2 ⟨_, (getD_mem_of_lt h).1, ?_⟩
  unfold ent; rw [getD_of_lt _ _ h]; exact List.getElem_mem h

theorem col_lt {T : List (List ℕ)} (hT3 : ∀ i, (T.getD (i + 1) []).length ≤ (T.getD i []).length ∧
      ∀ j < (T.getD (i + 1) []).length, (T.getD i []).getD j 0 < (T.getD (i + 1) []).getD j 0)
    {i j : ℕ} : ∀ i2, i + 1 ≤ i2 → j < (T.getD i2 []).length → ent T i j < ent T i2 j := by
  intro i2 h
  induction i2, h using Nat.le_induction with
  | base => intro hj; exact (hT3 i).2 j hj
  | succ m hm ih =>
    intro hj
    have hl := (hT3 m).1
    exact lt_trans (ih (by omega)) ((hT3 m).2 j hj)

def fromList {n : ℕ} (μ : YoungDiagram) (T : List (List ℕ)) (hT : IsStandard n T)
    (hs : shape T = μ.rowLens) : SemistandardYoungTableau μ where
  entry := ent T
  row_weak' := by
    intro i j1 j2 hj hc
    have h2 : j2 < (T.getD i []).length := (mem_iff_of_shape hs).1 hc
    have hrow := hT.2.1 _ (getD_mem_of_lt h2).1
    unfold ent
    rw [getD_of_lt _ _ (by omega), getD_of_lt _ _ h2]
    exact (List.pairwise_iff_getElem.1 hrow _ _ _ _ hj).le
  col_strict' := by
    intro i1 i2 j hi hc
    exact col_lt hT.2.2.1 i2 hi ((mem_iff_of_shape hs).1 hc)
  zeros' := by
    intro i j hc
    rw [mem_iff_of_shape hs] at hc
    unfold ent
    exact getD_of_ge _ _ (by omega)

theorem fromList_apply {n : ℕ} (μ : YoungDiagram) (T : List (List ℕ)) (hT : IsStandard n T)
    (hs : shape T = μ.rowLens) (i j : ℕ) : fromList μ T hT hs i j = ent T i j := rfl

theorem ent_inj {T : List (List ℕ)} (hnd : T.flatten.Nodup) {i1 j1 i2 j2 : ℕ}
    (h1 : j1 < (T.getD i1 []).length) (h2 : j2 < (T.getD i2 []).length)
    (heq : ent T i1 j1 = ent T i2 j2) : i1 = i2 ∧ j1 = j2 := by
  rw [List.nodup_flatten] at hnd
  have hi1 := (getD_mem_of_lt h1).2
  have hi2 := (getD_mem_of_lt h2).2
  unfold ent at heq
  rw [getD_of_lt _ _ hi1] at h1 heq
  rw [getD_of_lt _ _ hi2] at h2 heq
  rw [getD_of_lt _ _ h1, getD_of_lt _ _ h2] at heq
  by_cases hi : i1 = i2
  · subst hi
    exact ⟨rfl, (List.Nodup.getElem_inj_iff (hnd.1 _ (List.getElem_mem hi1))).1 heq⟩
  · exfalso
    rcases lt_or_gt_of_ne hi with h | h
    · exact (List.pairwise_iff_getElem.1 hnd.2 i1 i2 hi1 hi2 h) (List.getElem_mem h1)
        (heq ▸ List.getElem_mem h2)
    · exact (List.pairwise_iff_getElem.1 hnd.2 i2 i1 hi2 hi1 h) (List.getElem_mem h2)
        (heq.symm ▸ List.getElem_mem h1)

theorem fromList_bijOn {n : ℕ} (μ : YoungDiagram) (hμ : μ.card = n) (T : List (List ℕ))
    (hT : IsStandard n T) (hs : shape T = μ.rowLens) :
    Set.BijOn (fun c : ℕ × ℕ => fromList μ T hT hs c.1 c.2) (μ.cells : Set (ℕ × ℕ))
      (Set.Icc 1 μ.card) := by
  have hnd : T.flatten.Nodup := hT.2.2.2.nodup_iff.2 List.nodup_range'
  refine ⟨?_, ?_, ?_⟩
  · rintro ⟨i, j⟩ hc
    rw [Finset.mem_coe, YoungDiagram.mem_cells, mem_iff_of_shape hs] at hc
    have := List.mem_range'_1.1 (hT.2.2.2.subset (ent_mem hc))
    simp only [fromList_apply, Set.mem_Icc]
    omega
  · rintro ⟨i1, j1⟩ hc1 ⟨i2, j2⟩ hc2 heq
    rw [Finset.mem_coe, YoungDiagram.mem_cells, mem_iff_of_shape hs] at hc1 hc2
    simp only [fromList_apply] at heq
    obtain ⟨rfl, rfl⟩ := ent_inj hnd hc1 hc2 heq
    rfl
  · intro v hv
    rw [Set.mem_Icc] at hv
    have hvf : v ∈ T.flatten := hT.2.2.2.symm.subset (List.mem_range'_1.2 (by omega))
    obtain ⟨l, hl, hvl⟩ := List.mem_flatten.1 hvf
    obtain ⟨i, hi, rfl⟩ := List.mem_iff_getElem.1 hl
    obtain ⟨j, hj, rfl⟩ := List.mem_iff_getElem.1 hvl
    have hj' : j < (T.getD i []).length := by rw [getD_of_lt _ _ hi]; exact hj
    refine ⟨(i, j), ?_, ?_⟩
    · rw [Finset.mem_coe, YoungDiagram.mem_cells, mem_iff_of_shape hs]; exact hj'
    · simp only [fromList_apply, ent]
      rw [getD_of_lt _ _ hi, getD_of_lt _ _ hj]

def toList {μ : YoungDiagram} (T : SemistandardYoungTableau μ) : List (List ℕ) :=
  (List.range (μ.colLen 0)).map (fun i => (List.range (μ.rowLen i)).map (fun j => T i j))

theorem rowLen_eq_zero {μ : YoungDiagram} {i : ℕ} (hi : ¬ i < μ.colLen 0) : μ.rowLen i = 0 := by
  have : (i, 0) ∉ μ := by rw [YoungDiagram.mem_iff_lt_colLen]; exact hi
  rw [YoungDiagram.mem_iff_lt_rowLen] at this; omega

theorem toList_getD {μ : YoungDiagram} (T : SemistandardYoungTableau μ) (i : ℕ) :
    (toList T).getD i [] = (List.range (μ.rowLen i)).map (fun j => T i j) := by
  by_cases hi : i < μ.colLen 0
  · rw [getD_of_lt _ _ (by simpa [toList] using hi)]; simp [toList]
  · rw [getD_of_ge _ _ (by simp [toList]; omega), rowLen_eq_zero hi]; simp

theorem ent_toList {μ : YoungDiagram} (T : SemistandardYoungTableau μ) (i j : ℕ) :
    ent (toList T) i j = T i j := by
  unfold ent
  rw [toList_getD]
  by_cases hj : j < μ.rowLen i
  · rw [getD_of_lt _ _ (by simpa using hj)]; simp
  · rw [getD_of_ge _ _ (by simp; omega)]
    exact (T.zeros (by rw [YoungDiagram.mem_iff_lt_rowLen]; exact hj)).symm

theorem shape_toList {μ : YoungDiagram} (T : SemistandardYoungTableau μ) : shape (toList T) = μ.rowLens := by
  simp [shape, toList, YoungDiagram.rowLens, Function.comp_def]

theorem toList_standard {n : ℕ} {μ : YoungDiagram} (hμ : μ.card = n) (T : StandardYoungTableau μ) :
    IsStandard n (toList T.1) := by
  have hinj : ∀ {i1 j1 i2 j2 : ℕ}, (i1, j1) ∈ μ → (i2, j2) ∈ μ → T.1 i1 j1 = T.1 i2 j2 →
      i1 = i2 ∧ j1 = j2 := by
    intro i1 j1 i2 j2 h1 h2 h
    have := T.2.injOn (by simpa using h1) (by simpa using h2) h
    simpa using this
  have hrow : ∀ i, ((List.range (μ.rowLen i)).map (fun j => T.1 i j)).Pairwise (· < ·) := by
    intro i
    refine List.pairwise_map.2 (List.pairwise_lt_range.imp_of_mem (fun {a b} ha hb hab => ?_))
    rw [List.mem_range] at ha hb
    have hb' : (i, b) ∈ μ := YoungDiagram.mem_iff_lt_rowLen.2 hb
    have ha' : (i, a) ∈ μ := YoungDiagram.mem_iff_lt_rowLen.2 ha
    refine lt_of_le_of_ne (T.1.row_weak hab hb') (fun h => ?_)
    have := (hinj ha' hb' h).2; omega
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro row hr
    simp only [toList, List.mem_map, List.mem_range] at hr
    obtain ⟨i, hi, rfl⟩ := hr
    have : (i, 0) ∈ μ := YoungDiagram.mem_iff_lt_colLen.2 hi
    rw [YoungDiagram.mem_iff_lt_rowLen] at this
    simp; omega
  · intro row hr
    simp only [toList, List.mem_map, List.mem_range] at hr
    obtain ⟨i, hi, rfl⟩ := hr
    exact hrow i
  · intro i
    refine ⟨by simp only [toList_getD, List.length_map, List.length_range]; exact μ.rowLen_anti _ _ (by omega),
      fun j hj => ?_⟩
    have hj' : j < μ.rowLen (i + 1) := by
      simp only [toList_getD, List.length_map, List.length_range] at hj; exact hj
    show ent (toList T.1) i j < ent (toList T.1) (i + 1) j
    rw [ent_toList, ent_toList]
    exact T.1.col_strict (by omega) (YoungDiagram.mem_iff_lt_rowLen.2 hj')
  · have hnd : (toList T.1).flatten.Nodup := by
      rw [List.nodup_flatten]
      refine ⟨?_, ?_⟩
      · intro row hr
        simp only [toList, List.mem_map, List.mem_range] at hr
        obtain ⟨i, hi, rfl⟩ := hr
        exact (hrow i).imp (fun h => Nat.ne_of_lt h)
      · refine List.pairwise_map.2 (List.pairwise_lt_range.imp_of_mem (fun {a b} ha hb hab => ?_))
        intro v hv1 hv2
        simp only [List.mem_map, List.mem_range] at hv1 hv2
        obtain ⟨j1, hj1, rfl⟩ := hv1
        obtain ⟨j2, hj2, h⟩ := hv2
        have := (hinj (YoungDiagram.mem_iff_lt_rowLen.2 hj2) (YoungDiagram.mem_iff_lt_rowLen.2 hj1) h).1
        omega
    refine (List.perm_ext_iff_of_nodup hnd List.nodup_range').2 (fun v => ?_)
    rw [List.mem_range'_1]
    simp only [toList, List.mem_flatten, List.mem_map, List.mem_range]
    constructor
    · rintro ⟨l, ⟨i, hi, rfl⟩, hv⟩
      simp only [List.mem_map, List.mem_range] at hv
      obtain ⟨j, hj, rfl⟩ := hv
      have := T.2.mapsTo (show ((i, j) : ℕ × ℕ) ∈ (μ.cells : Set (ℕ × ℕ)) by
        simpa using YoungDiagram.mem_iff_lt_rowLen.2 hj)
      simp only [Set.mem_Icc] at this
      omega
    · intro hv
      obtain ⟨⟨i, j⟩, hc, hcv⟩ := T.2.surjOn (show v ∈ Set.Icc 1 μ.card by simp; omega)
      have hc' : (i, j) ∈ μ := by simpa using hc
      refine ⟨_, ⟨i, ?_, rfl⟩, ?_⟩
      swap
      · simp only [List.mem_map, List.mem_range]; exact ⟨j, YoungDiagram.mem_iff_lt_rowLen.1 hc', hcv⟩
      have := YoungDiagram.mem_iff_lt_colLen.1 hc'
      have := μ.colLen_anti 0 j (Nat.zero_le _)
      omega

theorem toList_fromList {n : ℕ} (μ : YoungDiagram) (T : List (List ℕ)) (hT : IsStandard n T)
    (hs : shape T = μ.rowLens) : toList (fromList μ T hT hs) = T := by
  have hlen : T.length = μ.colLen 0 := by
    rw [← YoungDiagram.length_rowLens, ← hs]; simp [shape]
  apply List.ext_getElem (by simp [toList, hlen])
  intro i h1 h2
  simp only [toList, List.getElem_map, List.getElem_range]
  have hl := len_getD_of_shape hs i
  rw [getD_of_lt _ _ h2] at hl
  apply List.ext_getElem (by simp [hl])
  intro j h3 h4
  simp only [List.getElem_map, List.getElem_range, fromList_apply, ent]
  rw [getD_of_lt _ _ h2, getD_of_lt _ _ h4]

def sytEquiv (μ : YoungDiagram) (n : ℕ) (hμ : μ.card = n) :
    StandardYoungTableau μ ≃ {T : List (List ℕ) // IsStandard n T ∧ shape T = μ.rowLens} where
  toFun T := ⟨toList T.1, toList_standard hμ T, shape_toList T.1⟩
  invFun T := ⟨fromList μ T.1 T.2.1 T.2.2, fromList_bijOn μ hμ T.1 T.2.1 T.2.2⟩
  left_inv T := Subtype.ext (SemistandardYoungTableau.ext fun i j => ent_toList T.1 i j)
  right_inv T := Subtype.ext (toList_fromList μ T.1 T.2.1 T.2.2)

theorem syt_finite (μ : YoungDiagram) : Finite (StandardYoungTableau μ) := by
  let g : StandardYoungTableau μ → (μ.cells → Fin (μ.card + 1)) := fun T c =>
    ⟨T.1 c.1.1 c.1.2, by
      have := T.2.mapsTo (show (c.1 : ℕ × ℕ) ∈ (μ.cells : Set (ℕ × ℕ)) from Finset.mem_coe.2 c.2)
      simp only [Set.mem_Icc] at this
      omega⟩
  refine Finite.of_injective g ?_
  intro T T' h
  apply Subtype.ext
  apply SemistandardYoungTableau.ext
  intro i j
  by_cases hc : (i, j) ∈ μ
  · have := congrFun h ⟨(i, j), (YoungDiagram.mem_cells _).2 hc⟩
    simpa [g, Fin.ext_iff] using this
  · rw [T.1.zeros hc, T'.1.zeros hc]

/-! ### Counting -/

theorem shape_chain (P : List (List ℕ)) (h : Tab P) : List.IsChain (· ≥ ·) (shape P) := by
  induction P with
  | nil => simp [shape]
  | cons r rs ih =>
    rw [tab_cons] at h
    cases rs with
    | nil => simp [shape]
    | cons b bs =>
      rw [shape_cons, shape_cons, List.isChain_cons_cons]
      exact ⟨rowsOK_length h.2.2.1, by rw [← shape_cons]; exact ih h.2.2.2⟩

theorem std_shape_sorted {n : ℕ} {P : List (List ℕ)} (hP : IsStandard n P) : (shape P).SortedGE :=
  List.sortedGE_iff_isChain.2 (shape_chain P ((isStandard_iff _ _).1 hP).1)

theorem std_shape_pos {n : ℕ} {P : List (List ℕ)} (hP : IsStandard n P) : ∀ x ∈ shape P, 0 < x := by
  intro x hx
  simp only [shape, List.mem_map] at hx
  obtain ⟨r, hr, rfl⟩ := hx
  exact List.length_pos_iff.2 (hP.1 r hr)

theorem std_card {n : ℕ} {P : List (List ℕ)} (hP : IsStandard n P) :
    (YoungDiagram.ofRowLens (shape P) (std_shape_sorted hP)).card = n := by
  rw [← YoungDiagram.sum_rowLens_eq_card, YoungDiagram.rowLens_ofRowLens_eq_self (std_shape_pos hP)]
  have := hP.2.2.2.length_eq
  rw [List.length_flatten] at this
  simpa [shape] using this

abbrev SPairs (n : ℕ) := {PQ : List (List ℕ) × List (List ℕ) //
  IsStandard n PQ.1 ∧ IsStandard n PQ.2 ∧ shape PQ.1 = shape PQ.2}

noncomputable def shapeOf {n : ℕ} (x : SPairs n) : Nat.Partition n :=
  (YoungDiagram.ofRowLens (shape x.1.1) (std_shape_sorted x.2.1)).toPartition (std_card x.2.1)

theorem shapeOf_eq_iff {n : ℕ} (x : SPairs n) (p : Nat.Partition n) :
    shapeOf x = p ↔ shape x.1.1 = (YoungDiagram.ofPartition p).rowLens := by
  constructor
  · intro h
    subst h
    rw [shapeOf, YoungDiagram.ofPartition_toPartition,
      YoungDiagram.rowLens_ofRowLens_eq_self (std_shape_pos x.2.1)]
  · intro h
    have key : ∀ (w : List ℕ) (hw : w.SortedGE), w = (YoungDiagram.ofPartition p).rowLens →
        YoungDiagram.ofRowLens w hw = YoungDiagram.ofPartition p := by
      rintro w hw rfl; exact YoungDiagram.ofRowLens_to_rowLens_eq_self
    have key2 : ∀ (μ : YoungDiagram) (hμ : μ.card = n), μ = YoungDiagram.ofPartition p →
        μ.toPartition hμ = p := by
      rintro μ hμ rfl; exact YoungDiagram.toPartition_ofPartition
    exact key2 _ _ (key _ _ h)

def fiberEquiv {n : ℕ} (p : Nat.Partition n) :
    {x : SPairs n // shapeOf x = p} ≃
      {T : List (List ℕ) // IsStandard n T ∧ shape T = (YoungDiagram.ofPartition p).rowLens} ×
      {T : List (List ℕ) // IsStandard n T ∧ shape T = (YoungDiagram.ofPartition p).rowLens} where
  toFun y := (⟨y.1.1.1, y.1.2.1, (shapeOf_eq_iff _ _).1 y.2⟩,
    ⟨y.1.1.2, y.1.2.2.1, y.1.2.2.2.symm.trans ((shapeOf_eq_iff _ _).1 y.2)⟩)
  invFun z := ⟨⟨(z.1.1, z.2.1), z.1.2.1, z.2.2.1, z.1.2.2.trans z.2.2.2.symm⟩,
    (shapeOf_eq_iff _ _).2 z.1.2.2⟩
  left_inv y := rfl
  right_inv z := rfl

theorem sum_sq_aux (n : ℕ) :
    ∑ p : Nat.Partition n,
      Nat.card (StandardYoungTableau (YoungDiagram.ofPartition p)) ^ 2 = n.factorial := by
  have hL : ∀ p : Nat.Partition n,
      Nat.card (StandardYoungTableau (YoungDiagram.ofPartition p)) =
      Nat.card {T : List (List ℕ) // IsStandard n T ∧ shape T = (YoungDiagram.ofPartition p).rowLens} :=
    fun p => Nat.card_congr (sytEquiv _ n (YoungDiagram.card_ofPartition p))
  have hfin : ∀ p : Nat.Partition n, Finite {x : SPairs n // shapeOf x = p} := by
    intro p
    have := syt_finite (YoungDiagram.ofPartition p)
    have : Finite {T : List (List ℕ) // IsStandard n T ∧ shape T = (YoungDiagram.ofPartition p).rowLens} :=
      Finite.of_equiv _ (sytEquiv _ n (YoungDiagram.card_ofPartition p))
    exact Finite.of_equiv _ (fiberEquiv p).symm
  have h1 : Nat.card (SPairs n) = ∑ p : Nat.Partition n,
      Nat.card (StandardYoungTableau (YoungDiagram.ofPartition p)) ^ 2 := by
    rw [← Nat.card_congr (Equiv.sigmaFiberEquiv (shapeOf (n := n))), Nat.card_sigma]
    refine Finset.sum_congr rfl (fun p _ => ?_)
    rw [Nat.card_congr (fiberEquiv p), Nat.card_prod, hL p, sq]
  have h2 : Nat.card (SPairs n) = n.factorial := by
    have hb := rsk_bijOn_aux n
    have e : Nat.card (SPairs n) = Nat.card ↥{PQ : List (List ℕ) × List (List ℕ) |
        IsStandard n PQ.1 ∧ IsStandard n PQ.2 ∧ shape PQ.1 = shape PQ.2} := rfl
    rw [e, ← Nat.card_congr (hb.equiv _), Nat.card_univ, Nat.card_eq_fintype_card,
      Fintype.card_perm, Fintype.card_fin]
  rw [← h1, h2]

/-- RSK is a bijection: row insertion with a recording tableau sends each shuffle of `1, …, n`
to a pair `(P, Q)` of standard tableaux with `n` boxes and the same shape, different shuffles go
to different pairs, and every such pair comes from some shuffle. -/
theorem rsk_bijOn_same_shape_standard_pairs (n : ℕ) :
    Set.BijOn (fun σ : Equiv.Perm (Fin n) => rsk (word σ)) Set.univ
      {PQ : List (List ℕ) × List (List ℕ) |
        IsStandard n PQ.1 ∧ IsStandard n PQ.2 ∧ shape PQ.1 = shape PQ.2} := by
  exact rsk_bijOn_aux n

/-- Counting both sides of RSK: over every shape with `n` boxes, the squares of the numbers of
standard tableaux of that shape add up to `n!`. -/
theorem sum_sq_card_standard_tableaux_eq_factorial (n : ℕ) :
    ∑ p : Nat.Partition n,
      Nat.card (StandardYoungTableau (YoungDiagram.ofPartition p)) ^ 2 = n.factorial := by
  exact sum_sq_aux n

/-- Schensted's theorem, first row: the length of the first row of the insertion tableau `P` of a
shuffle is the length of its longest rising run (terms taken in their original order, gaps
allowed, that climb). -/
theorem first_row_length_eq_longest_rising_run {n : ℕ} (σ : Equiv.Perm (Fin n)) :
    IsGreatest {k | ∃ s : List ℕ, s.Sublist (word σ) ∧ s.Pairwise (· < ·) ∧ s.length = k}
      ((rsk (word σ)).1.headD []).length := by
  exact first_row_aux σ

-- Inserting 2, 4, 1, 3, one step at a time: 2 | 2 4 | 1 4 / 2 | 1 3 / 2 4.
example : (rsk [2]).1 = [[2]] := by decide
example : (rsk [2, 4]).1 = [[2, 4]] := by decide
example : (rsk [2, 4, 1]).1 = [[1, 4], [2]] := by decide
-- P = 1 3 / 2 4 and Q = 1 2 / 3 4, of shape (2, 2).
example : rsk [2, 4, 1, 3] = ([[1, 3], [2, 4]], [[1, 2], [3, 4]]) := by decide
example : shape (rsk [2, 4, 1, 3]).1 = [2, 2] := by decide
-- First row length 2, the longest rising run; 4 - 2 = 2 volumes move.
example : ((rsk [2, 4, 1, 3]).1.headD []).length = 2 := by decide
example : 4 - ((rsk [2, 4, 1, 3]).1.headD []).length = 2 := by decide
-- n = 4: the shapes (4), (3, 1), (2, 2), (2, 1, 1), (1, 1, 1, 1) have 1, 3, 2, 3, 1 tableaux.
example : 1 ^ 2 + 3 ^ 2 + 2 ^ 2 + 3 ^ 2 + 1 ^ 2 = Nat.factorial 4 := by decide
example : 1 + 3 + 2 + 3 + 1 = 10 := by decide
-- All 24 shuffles of four give 24 distinct pairs (P, Q) but only 10 insertion tableaux P,
-- split by shape as 1, 3, 2, 3, 1.
example : ((List.range' 1 4).permutations'.map rsk).dedup.length = 24 := by decide
example : ((List.range' 1 4).permutations'.map fun w => (rsk w).1).dedup.length = 10 := by decide
example :
    [[4], [3, 1], [2, 2], [2, 1, 1], [1, 1, 1, 1]].map
      (fun l => (((List.range' 1 4).permutations'.map fun w => (rsk w).1).dedup.map shape).count l)
      = [1, 3, 2, 3, 1] := by decide
-- Keeping only P: 2, 1, 4, 3 also gives 1 3 / 2 4.
example : (rsk [2, 1, 4, 3]).1 = [[1, 3], [2, 4]] := by decide
-- Lengths, not entries: 3, 4, 2, 1 gives P = 1 4 / 2 / 3.
example : (rsk [3, 4, 2, 1]).1 = [[1, 4], [2], [3]] := by decide

#print axioms rowsOK_nil_right
#print axioms rowsOK_nil_cons
#print axioms rowsOK_cons_cons
#print axioms tab_nil
#print axioms tab_cons
#print axioms getD_zero_eq_headD
#print axioms mem_flatten_of_mem_head
#print axioms tab_head_sorted
#print axioms rowsOK_length
#print axioms rowsOK_append_right
#print axioms rowsOK_prefix
#print axioms rowsOK_shrink
#print axioms rowsOK_snoc
#print axioms rowsOK_full
#print axioms head_lt_of_mem
#print axioms rowInsert_nil
#print axioms rowInsert_cons_lt
#print axioms rowInsert_cons_not_lt
#print axioms rowInsert_fst_ne_nil
#print axioms rowInsert_of_forall
#print axioms rowInsert_snd_none
#print axioms rowInsert_snd_mem
#print axioms rowInsert_perm
#print axioms rowInsert_mem_fst
#print axioms rowInsert_length_some
#print axioms rowInsert_sorted
#print axioms rowsOK_rowInsert_left
#print axioms rowsOK_insert_step
#print axioms rowInsert_head_lt
#print axioms rowUnins_cons_lt
#print axioms rowUnins_cons_not_lt
#print axioms rowUnins_ne_nil
#print axioms rowUnins_mem
#print axioms rowUnins_rowInsert
#print axioms rowInsert_rowUnins
#print axioms rowsOK_unins_last
#print axioms rowsOK_unins_ins
#print axioms rowsOK_unins_step
#print axioms insertP_cons_none
#print axioms insertP_cons_some
#print axioms insertP_head
#print axioms shape_cons
#print axioms tab_insertP
#print axioms tab_shrink
#print axioms tab_rest_nil
#print axioms exists_concat
#print axioms deleteP_spec
#print axioms shape_addAt
#print axioms flatten_addAt
#print axioms findRow_addAt
#print axioms dropBox_addAt
#print axioms headD_length_of_shape
#print axioms getD_length_of_shape
#print axioms length_eq_of_shape
#print axioms shape_dropBox
#print axioms tab_addAt
#print axioms rowsOK_dropBox_head
#print axioms qmax_spec
#print axioms rowsOK_iff
#print axioms tab_iff
#print axioms isStandard_iff
#print axioms tab_rows_ne
#print axioms rsk_eq
#print axioms rsk_fold_count
#print axioms rsk_append
#print axioms rsk_inv
#print axioms deleteP_insertP
#print axioms rskInv_rsk
#print axioms rsk_rskInv
#print axioms word_perm
#print axioms word_inj
#print axioms exists_word
#print axioms rsk_bijOn_aux
#print axioms rowInsert_filter_le
#print axioms rowInsert_filter_self
#print axioms rowInsert_filter_other
#print axioms nil_or_snoc
#print axioms schensted_inv
#print axioms first_row_aux
#print axioms getD_of_lt
#print axioms getD_of_ge
#print axioms shape_getD
#print axioms rowLens_getD
#print axioms len_getD_of_shape
#print axioms mem_iff_of_shape
#print axioms getD_mem_of_lt
#print axioms ent_mem
#print axioms col_lt
#print axioms fromList_apply
#print axioms ent_inj
#print axioms fromList_bijOn
#print axioms rowLen_eq_zero
#print axioms toList_getD
#print axioms ent_toList
#print axioms shape_toList
#print axioms toList_standard
#print axioms toList_fromList
#print axioms syt_finite
#print axioms shape_chain
#print axioms std_shape_sorted
#print axioms std_shape_pos
#print axioms std_card
#print axioms shapeOf_eq_iff
#print axioms sum_sq_aux
#print axioms rsk_bijOn_same_shape_standard_pairs
#print axioms sum_sq_card_standard_tableaux_eq_factorial
#print axioms first_row_length_eq_longest_rising_run
