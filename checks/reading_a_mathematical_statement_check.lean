-- Reading a statement: a "for every case in the domain, if the hypotheses hold then the conclusion holds" statement is false exactly when some case passes the hypotheses and misses the conclusion, moving an "exists" to the front makes a strictly stronger claim, and an odd sum of two primes must use 2; the card's small colouring and Goldbach counts are checked exactly.
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Finset.Card
import Mathlib.Algebra.Group.Nat.Even
import Mathlib.Tactic.NormNum

/-! A statement in the standard shape is `∀ s ∈ D, Hyp s → Concl s`: a domain `D` of cases,
a hypothesis `Hyp` each case must pass, and a conclusion `Concl` promised for each case that
passes. -/

/-- A statement can only fail inside its fence (Step 0 and Step 3). "For every case `s` in the
domain `D`, if `s` passes the hypotheses then the conclusion holds for `s`" is false exactly
when some case in `D` passes the hypotheses and still misses the conclusion: a counterexample. -/
theorem statement_false_iff_counterexample_inside_fence {α : Type*} (D : Set α)
    (Hyp Concl : α → Prop) :
    ¬ (∀ s ∈ D, Hyp s → Concl s) ↔ ∃ s ∈ D, Hyp s ∧ ¬ Concl s := by
  constructor
  · intro h
    by_contra h'
    exact h (fun s hs hh => by_contra fun hc => h' ⟨s, hs, hh, hc⟩)
  · rintro ⟨s, hs, hh, hc⟩ h
    exact hc (h s hs hh)

/-- The order of quantifiers is kept (When it holds). "There is one bound `C` that works for
every case" implies "every case has a bound `C` of its own", but not the other way round:
every whole number `s` has a number `C` above it, yet no single `C` is above every `s`. So
moving the "exists" to the front makes a different and stronger statement. -/
theorem exists_first_is_stronger {α β : Type*} (D : Set α) (P : α → β → Prop) :
    ((∃ C, ∀ s ∈ D, P s C) → ∀ s ∈ D, ∃ C, P s C) ∧
    ((∀ s : ℕ, ∃ C : ℕ, s < C) ∧ ¬ ∃ C : ℕ, ∀ s : ℕ, s < C) := by
  refine ⟨fun ⟨C, hC⟩ s hs => ⟨C, hC s hs⟩, fun s => ⟨s + 1, Nat.lt_succ_self s⟩, ?_⟩
  rintro ⟨C, hC⟩
  exact lt_irrefl C (hC C)

/-- Why "even" is a hypothesis of Goldbach's conjecture (Step 5). If an odd number is a sum of
two primes, one of the two primes is 2: two odd primes would add to an even number. -/
theorem odd_sum_of_two_primes_uses_two {n p q : ℕ} (hn : Odd n) (hp : p.Prime) (hq : q.Prime)
    (hsum : p + q = n) : p = 2 ∨ q = 2 := by
  rcases hp.eq_two_or_odd with h1 | h1
  · exact Or.inl h1
  rcases hq.eq_two_or_odd with h2 | h2
  · exact Or.inr h2
  obtain ⟨k, hk⟩ := hn
  omega

/-! ### The card's exact small cases -/

/-- The card's `ways(m)`: the splits `m = p + (m - p)` into two primes with `p ≤ m / 2`,
equal primes allowed. -/
def goldbachWays (m : ℕ) : ℕ :=
  ((Finset.range (m / 2 + 1)).filter (fun p => p.Prime ∧ (m - p).Prime)).card

/-- The same count with the two primes required to be different. -/
def goldbachWaysDistinct (m : ℕ) : ℕ :=
  ((Finset.range (m / 2 + 1)).filter (fun p => p.Prime ∧ (m - p).Prime ∧ 2 * p ≠ m)).card

/-- The number of ways to colour `n` regions with `k` colours so that the two regions of every
neighbour pair in `E` get different colours. -/
def properColourings (n k : ℕ) (E : List (Fin n × Fin n)) : ℕ :=
  (Finset.univ.filter (fun c : Fin n → Fin k => ∀ e ∈ E, c e.1 ≠ c e.2)).card

/-- Benelux, France, Germany: Belgium 0, Netherlands 1, Luxembourg 2, France 3, Germany 4. -/
def benelux : List (Fin 5 × Fin 5) :=
  [(0, 1), (0, 2), (0, 3), (0, 4), (1, 4), (2, 3), (2, 4), (3, 4)]

/-- Four regions in a ring, each touching the next along a border (Four Corners). -/
def ring4 : List (Fin 4 × Fin 4) := [(0, 1), (1, 2), (2, 3), (3, 0)]

/-- Six cake slices in a ring, each touching the next along a border. -/
def ring6 : List (Fin 6 × Fin 6) := [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]

/-- Every pair of regions touching. -/
def completeEdges (m : ℕ) : List (Fin m × Fin m) :=
  ((List.finRange m).product (List.finRange m)).filter fun e => e.1 < e.2

-- Four colours are needed for Benelux, France, Germany: 0 three-colourings, 48 four-colourings.
example : properColourings 5 3 benelux = 0 := by decide
example : properColourings 5 4 benelux = 48 := by decide
-- Four Corners, borders only: 2 colours suffice (2 ways), 1 does not.
example : properColourings 4 1 ring4 = 0 := by decide
example : properColourings 4 2 ring4 = 2 := by decide
-- Four Corners, points counted: 0 three-colourings, 24 four-colourings.
example : properColourings 4 3 (completeEdges 4) = 0 := by decide
example : properColourings 4 4 (completeEdges 4) = 24 := by decide
-- Six-slice cake, borders only: 2 two-colourings.
example : properColourings 6 2 ring6 = 2 := by decide
-- Six-slice cake, points counted: 15 neighbour pairs; with six colours, 6 × 5 × 4 × 3 × 2 × 1 = 720.
example : (completeEdges 6).length = 15 := by decide
example : 6 * 5 * 4 * 3 * 2 * 1 = 720 := by norm_num
-- Five regions all touching: 0 four-colourings; 10 pairs against the plane limit 3 × 5 − 6 = 9.
set_option maxRecDepth 100000 in
example : properColourings 5 4 (completeEdges 5) = 0 := by decide
example : (completeEdges 5).length = 10 ∧ 3 * 5 - 6 = 9 ∧ 9 < 10 := by decide

-- Goldbach: ways as a sum of two primes, 2: 0, 4: 1, 6: 1, 8: 1, 100: 6.
example : goldbachWays 2 = 0 ∧ goldbachWays 4 = 1 ∧ goldbachWays 6 = 1 ∧ goldbachWays 8 = 1 := by
  decide
example : goldbachWays 100 = 6 := by decide
-- Two different primes: 4: 0, 6: 0, 8: 1.
example : goldbachWaysDistinct 4 = 0 ∧ goldbachWaysDistinct 6 = 0 ∧ goldbachWaysDistinct 8 = 1 := by
  decide
-- Odd numbers 3 to 29 with no split: 3, 11, 17, 23, 27, 29.
example : (List.range' 3 14 2).filter (fun m => goldbachWays m = 0) = [3, 11, 17, 23, 27, 29] := by
  decide

-- Start B's energy in a cube of side 1, 2, 3: 3 × 1, 3 × 8, 3 × 27.
example : 3 * 1 ^ 3 = 3 ∧ 3 * 2 ^ 3 = 24 ∧ 3 * 3 ^ 3 = 81 := by norm_num

#print axioms statement_false_iff_counterexample_inside_fence
#print axioms exists_first_is_stronger
#print axioms odd_sum_of_two_primes_uses_two
