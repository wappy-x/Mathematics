-- k-d trees: a point across a cut is at least as far from the query as the cut, so a cut no nearer than the best point found lets the search skip everything beyond it, and the card's six-depot search and level counts are exact.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Data.Nat.Log

/-- `p` lies across the cut "coordinate `a` equals `s`" from the query `q`: the cut sits
between them in coordinate `a` (either side may touch the cut). -/
def AcrossCut {k : ℕ} (q p : Fin k → ℝ) (a : Fin k) (s : ℝ) : Prop :=
  (q a ≤ s ∧ s ≤ p a) ∨ (p a ≤ s ∧ s ≤ q a)

/-- The skip rule. Take any distance `D` that is never shorter than the gap in one
coordinate (the card's "When it holds" condition: `|q a - p a| ≤ D q p` for every
coordinate `a`). If a depot `p` lies across the cut "coordinate `a` equals `s`" from the
query `q`, and the cut is at least `r` away from the query (`r ≤ |q a - s|`, where `r` is
the distance to the best depot found so far), then `p` is at least `r` away too, so nothing
beyond the cut can beat the best depot and the whole far side may be skipped. -/
theorem skip_far_side_of_cut {k : ℕ} (D : (Fin k → ℝ) → (Fin k → ℝ) → ℝ)
    (hD : ∀ q p : Fin k → ℝ, ∀ a : Fin k, |q a - p a| ≤ D q p)
    (q p : Fin k → ℝ) (a : Fin k) (s r : ℝ)
    (hp : AcrossCut q p a s) (hr : r ≤ |q a - s|) :
    r ≤ D q p := by
  have h1 : |q a - s| ≤ |q a - p a| := by
    rcases hp with ⟨h1, h2⟩ | ⟨h1, h2⟩
    · rw [abs_of_nonpos (by linarith), abs_of_nonpos (by linarith)]; linarith
    · rw [abs_of_nonneg (by linarith), abs_of_nonneg (by linarith)]; linarith
  exact hr.trans (h1.trans (hD q p a))

/-- The card's formula: for straight-line distance in `k` dimensions, a depot `p` across
the cut "coordinate `a` equals `s`" from the query `q` is at least as far from `q` as the
cut is, `d(q, p) ≥ |q a - s|` (Pythagoras with the other legs thrown away). -/
theorem euclidean_dist_ge_gap_to_cut {k : ℕ} (q p : EuclideanSpace ℝ (Fin k)) (a : Fin k)
    (s : ℝ) (hp : (q a ≤ s ∧ s ≤ p a) ∨ (p a ≤ s ∧ s ≤ q a)) :
    |q a - s| ≤ dist q p := by
  have h1 : |q a - s| ≤ |q a - p a| := by
    rcases hp with ⟨h1, h2⟩ | ⟨h1, h2⟩
    · rw [abs_of_nonpos (by linarith), abs_of_nonpos (by linarith)]; linarith
    · rw [abs_of_nonneg (by linarith), abs_of_nonneg (by linarith)]; linarith
  have h2 : dist (q a) (p a) ≤ dist q p := PiLp.dist_apply_le q p a
  rw [Real.dist_eq] at h2
  exact h1.trans h2

/-- The search is exact: if every stored point was either measured and found no nearer
than the best point `b`, or ruled out because it lies across some cut that is no nearer
to the query than `b`, then `b` is a nearest point to the query among all stored points. -/
theorem nearest_of_measured_or_skipped {k : ℕ} (S : Finset (EuclideanSpace ℝ (Fin k)))
    (q b : EuclideanSpace ℝ (Fin k)) (hb : b ∈ S)
    (hS : ∀ p ∈ S, dist q b ≤ dist q p ∨
      ∃ (a : Fin k) (s : ℝ), ((q a ≤ s ∧ s ≤ p a) ∨ (p a ≤ s ∧ s ≤ q a)) ∧
        dist q b ≤ |q a - s|) :
    ∀ p ∈ S, dist q b ≤ dist q p := by
  intro p hpS
  rcases hS p hpS with h | ⟨a, s, hp, h⟩
  · exact h
  · exact h.trans (euclidean_dist_ge_gap_to_cut q p a s hp)

/-! Worked examples from the card, in whole numbers (squared distances, so no square roots). -/

/-- The six depots. -/
def depots : List (ℤ × ℤ) := [(2, 3), (5, 4), (9, 6), (4, 7), (8, 1), (7, 2)]

/-- Squared straight-line distance from the breakdown at (9, 2). -/
def sqDistFromQuery (p : ℤ × ℤ) : ℤ := (9 - p.1) ^ 2 + (2 - p.2) ^ 2

-- Squared distances from (9, 2): 50, 20, 16, 50, 2, 4 (so 7.07, 4.47, 4.00, 7.07, 1.41, 2.00 km).
example : depots.map sqDistFromQuery = [50, 20, 16, 50, 2, 4] := by decide

-- (8, 1) is nearest to (9, 2) among all six depots (brute force).
example : ∀ p ∈ depots, sqDistFromQuery (8, 1) ≤ sqDistFromQuery p := by decide

-- Sorted by x the depots read 2, 4, 5, 7, 8, 9; the 4th, (7, 2), is the root: three depots
-- lie west of x = 7 and two east of it.
example : (depots.filter (fun p => p.1 < 7)).length = 3 ∧
    (depots.filter (fun p => 7 < p.1)).length = 2 := by decide

-- The cut x = 7 is 2 km from the query; 2 squared = 4 is at least 1.41 squared = 2, so skip.
example : (9 - 7 : ℤ) ^ 2 ≥ sqDistFromQuery (8, 1) := by decide

-- The three skipped depots are exactly those west of x = 7.
example : depots.filter (fun p => p.1 < 7) = [(2, 3), (5, 4), (4, 7)] := by decide

-- Levels = ⌊log₂ n⌋ + 1: 3 for 6 depots, 10 for 1000, 14 for 10,000.
example : Nat.log 2 6 + 1 = 3 := by decide
example : Nat.log 2 1000 + 1 = 10 := by decide
example : Nat.log 2 10000 + 1 = 14 := by decide

#print axioms skip_far_side_of_cut
#print axioms euclidean_dist_ge_gap_to_cut
#print axioms nearest_of_measured_or_skipped
