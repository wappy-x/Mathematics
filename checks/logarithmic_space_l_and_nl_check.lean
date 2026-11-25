-- Logarithmic space: a route in a finite maze of one-way doors can be cut to at most N − 1 doors, Savitch's midpoint split is exact, a log-space configuration count is polynomial, and the card's bit counts are right.
import Mathlib.Combinatorics.Digraph.Basic
import Mathlib.Data.List.Chain
import Mathlib.Data.Nat.Log
import Mathlib.Data.Fintype.Card

open List

/-- A route from room `u` to room `v` of at most `n` doors in the maze `G`: a list of rooms
starting at `u`, each step through a one-way door of `G`, ending at `v`, with at most `n` steps. -/
def RouteWithin {V : Type*} (G : Digraph V) (n : ℕ) (u v : V) : Prop :=
  ∃ l : List V, IsChain G.Adj (u :: l) ∧ (u :: l).getLast (cons_ne_nil _ _) = v ∧ l.length ≤ n

theorem route_nodup_aux {V : Type*} (G : Digraph V) (a b : V)
    (h : Relation.ReflTransGen G.Adj a b) :
    ∃ l : List V, IsChain G.Adj (a :: l) ∧ (a :: l).getLast (cons_ne_nil _ _) = b ∧
      (a :: l).Nodup := by
  induction h using Relation.ReflTransGen.head_induction_on with
  | refl => exact ⟨[], .singleton _, rfl, nodup_singleton _⟩
  | @head a c hac _ ih =>
    obtain ⟨l, hch, hl, hnd⟩ := ih
    by_cases ha : a ∈ c :: l
    · obtain ⟨s, t, hst⟩ := List.append_of_mem ha
      refine ⟨t, ?_, ?_, ?_⟩
      · exact hch.suffix (hst ▸ suffix_append s (a :: t))
      · rw [← hl]
        simp only [hst, getLast_append_of_ne_nil _ (cons_ne_nil a t)]
      · rw [hst] at hnd
        exact hnd.sublist (sublist_append_right s (a :: t))
    · exact ⟨c :: l, hch.cons_cons hac, by rw [getLast_cons_cons]; exact hl, nodup_cons.2 ⟨ha, hnd⟩⟩

theorem getLast_cons_getLast_append {V : Type*} (A B : List V) (hA : A ≠ []) :
    (A.getLast hA :: B).getLast (cons_ne_nil _ _) = (A ++ B).getLast (by simp [hA]) := by
  cases B with
  | nil => simp
  | cons b B => simp [getLast_append_of_ne_nil]

theorem isChain_cons_getLast_of_append {V : Type*} (R : V → V → Prop) (A B : List V)
    (hA : A ≠ []) (h : IsChain R (A ++ B)) : IsChain R (A.getLast hA :: B) := by
  rw [isChain_append] at h
  obtain ⟨_, h2, h3⟩ := h
  rw [isChain_cons]
  exact ⟨fun y hy => h3 _ (by simp [getLast?_eq_some_getLast hA]) y hy, h2⟩

theorem routeWithin_add {V : Type*} (G : Digraph V) (m n : ℕ) (u v : V) :
    RouteWithin G (m + n) u v ↔ ∃ x, RouteWithin G m u x ∧ RouteWithin G n x v := by
  constructor
  · rintro ⟨l, hch, hl, hlen⟩
    refine ⟨(u :: l.take m).getLast (cons_ne_nil _ _), ⟨l.take m, ?_, rfl, ?_⟩, ⟨l.drop m, ?_, ?_, ?_⟩⟩
    · exact hch.take (m + 1)
    · simp
    · have e : u :: l = (u :: l.take m) ++ l.drop m := by simp
      rw [e] at hch
      exact isChain_cons_getLast_of_append _ _ _ (cons_ne_nil _ _) hch
    · rw [getLast_cons_getLast_append, ← hl]
      simp
    · simp; omega
  · rintro ⟨x, ⟨l₁, h₁, e₁, n₁⟩, ⟨l₂, h₂, e₂, n₂⟩⟩
    refine ⟨l₁ ++ l₂, ?_, ?_, ?_⟩
    · have h := h₁.append h₂.tail (by
        intro a ha y hy
        rw [getLast?_eq_some_getLast (cons_ne_nil _ _), Option.mem_some_iff] at ha
        rw [← ha, e₁]
        exact h₂.rel_head? (by simpa using hy))
      simpa using h
    · have h := getLast_cons_getLast_append (u :: l₁) l₂ (cons_ne_nil _ _)
      rw [e₁] at h
      rw [← e₂, h]
      simp
    · simp; omega

/-- In a maze of one-way doors with N rooms, if some route leads from room `a` to room `b`,
then a route with no repeated room leads from `a` to `b`, and it has at most N − 1 doors.
This is the cap that the guessing walker's step counter enforces. -/
theorem route_cut_to_at_most_card_sub_one {V : Type*} [Fintype V] (G : Digraph V) (a b : V)
    (h : Relation.ReflTransGen G.Adj a b) :
    ∃ l : List V, IsChain G.Adj (a :: l) ∧ (a :: l).getLast (cons_ne_nil _ _) = b ∧
      (a :: l).Nodup ∧ l.length ≤ Fintype.card V - 1 := by
  obtain ⟨l, hch, hl, hnd⟩ := route_nodup_aux G a b h
  refine ⟨l, hch, hl, hnd, ?_⟩
  have := hnd.length_le_card
  simp only [length_cons] at this
  omega

/-- Savitch's midpoint split: a route of at most 2^(k+1) doors from `u` to `v` exists exactly
when some midpoint room `x` has routes of at most 2^k doors from `u` to `x` and from `x` to `v`. -/
theorem savitch_midpoint_split {V : Type*} (G : Digraph V) (k : ℕ) (u v : V) :
    RouteWithin G (2 ^ (k + 1)) u v ↔ ∃ x, RouteWithin G (2 ^ k) u x ∧ RouteWithin G (2 ^ k) x v := by
  rw [pow_succ, Nat.mul_two]
  exact routeWithin_add G _ _ u v

/-- With s = c · log₂ n work bits, the number of work-tape contents 2^s is at most n^c, so the
configuration count |Q| · (n + 2) · s · 2^s is a polynomial in the input length n. -/
theorem work_tape_contents_le_pow (n c : ℕ) (hn : 0 < n) :
    2 ^ (c * Nat.log 2 n) ≤ n ^ c := by
  rw [mul_comm, pow_mul]
  exact Nat.pow_le_pow_left (Nat.pow_log_le_self 2 hn.ne') c

/-! Worked numbers from the card. A counter for k values takes ⌈log₂ k⌉ = `Nat.clog 2 k` bits. -/

-- The card's filled 9 by 9 grid, row by row.
def cardGrid : List (List ℕ) :=
  [[1,2,3,4,5,6,7,8,9], [4,5,6,7,8,9,1,2,3], [7,8,9,1,2,3,4,5,6],
   [2,3,4,5,6,7,8,9,1], [5,6,7,8,9,1,2,3,4], [8,9,1,2,3,4,5,6,7],
   [3,4,5,6,7,8,9,1,2], [6,7,8,9,1,2,3,4,5], [9,1,2,3,4,5,6,7,8]]

-- Every row, column and 3 by 3 box of the grid holds each digit 1 to 9 exactly once.
example : ∀ i : Fin 9,
    ((cardGrid.getD i []).Perm (List.range' 1 9)) ∧
    ((cardGrid.map (fun row => row.getD i 0)).Perm (List.range' 1 9)) ∧
    (((List.range 9).map (fun p =>
        (cardGrid.getD (3 * (i / 3) + p / 3) []).getD (3 * (i % 3) + p % 3) 0)).Perm
      (List.range' 1 9)) := by
  decide

-- Input length: 81 cells of 4 bits (digits 0 to 9 need ⌈log₂ 10⌉ = 4 bits); a copy on the
-- work tape would cost these 324 bits, against the checker's 22.
example : 81 * Nat.clog 2 10 = 324 := by decide
-- One counter up to 9 takes 4 bits.
example : Nat.clog 2 9 = 4 := by decide
-- Checker's memory: kind 2 + unit 4 + digit 4 + place 4 + flag 1 + address 7 = 22 bits.
example : Nat.clog 2 3 + 3 * Nat.clog 2 9 + Nat.clog 2 2 + Nat.clog 2 81 = 22 := by decide
-- Checker's reads: 3 kinds × 9 units × 9 digits × 9 places.
example : 3 * 9 * 9 * 9 = 2187 := by decide
-- Maze room name 10 bits; walker's memory room + step count = 20 bits.
example : Nat.clog 2 1000 = 10 ∧ 2 * Nat.clog 2 1000 = 20 := by decide
-- Guess sequences of 11 doors, two doors per room.
example : 2 ^ 11 = 2048 := by decide
-- Savitch: k = ⌈log₂ 999⌉ = 10 levels, memory 2m + k(m + 1) = 130 bits.
example : Nat.clog 2 999 = 10 ∧
    2 * Nat.clog 2 1000 + Nat.clog 2 999 * (Nat.clog 2 1000 + 1) = 130 := by decide
-- The table of memory at growing maze sizes: walker 2m and Savitch 2m + k(m + 1).
example : [10, 100, 1000, 10000, 100000, 1000000].map (fun N => 2 * Nat.clog 2 N) =
    [8, 14, 20, 28, 34, 40] := by decide
example : [10, 100, 1000, 10000, 100000, 1000000].map
    (fun N => 2 * Nat.clog 2 N + Nat.clog 2 (N - 1) * (Nat.clog 2 N + 1)) =
    [28, 70, 130, 238, 340, 460] := by decide
-- Road D: 4 states × 16 head positions × 4 × 4 × 4 register values × 5 digit values
-- = 20,480 configurations, each named in 15 bits.
example : 4 * 16 * 4 * 4 * 4 * 5 = 20480 ∧ Nat.clog 2 20480 = 15 := by decide

#print axioms route_cut_to_at_most_card_sub_one
#print axioms savitch_midpoint_split
#print axioms work_tape_contents_le_pow
#print axioms route_nodup_aux
#print axioms getLast_cons_getLast_append
#print axioms isChain_cons_getLast_of_append
#print axioms routeWithin_add
