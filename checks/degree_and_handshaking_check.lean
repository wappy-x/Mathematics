-- Degrees and the handshaking lemma: in any finite network of dots and lines, loops and parallel lines allowed, the degrees add to twice the number of lines, so the odd-degree dots are even in number.
import Mathlib.Data.Sym.Sym2
import Mathlib.Data.Fin.VecNotation
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Group.Nat.Even
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Fintype.Sigma
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.BigOperators.Group.Finset.Sigma
import Mathlib.Algebra.BigOperators.Ring.Nat

open Finset

/-! A network is a finite set of dots `V` and a finite set of lines `E`; each line has an
unordered pair of ends `ends e : Sym2 V`. A loop is a line whose two ends are the same dot,
and two different lines may share their ends (parallel lines). No arrows: the pair is
unordered. -/

/-- The degree of a dot `v`: how many line-ends meet it. A loop at `v` puts both of its
ends there, so it adds two; parallel lines each add their own ends. -/
def lineEnds {V E : Type*} [Fintype E] [DecidableEq V] (ends : E → Sym2 V) (v : V) : ℕ :=
  ∑ e, (ends e).toMultiset.count v

/-- The handshaking lemma: in a network with finitely many dots and lines, loops and
parallel lines allowed, the degrees of all the dots add up to twice the number of lines. -/
theorem sum_of_degrees_eq_twice_number_of_lines
    {V E : Type*} [Fintype V] [Fintype E] [DecidableEq V] (ends : E → Sym2 V) :
    ∑ v, lineEnds ends v = 2 * Fintype.card E := by
  unfold lineEnds
  rw [Finset.sum_comm]
  have h : ∀ e, ∑ v, (ends e).toMultiset.count v = 2 := by
    intro e
    rw [Multiset.sum_count_eq_card (s := (univ : Finset V)) (fun a _ => mem_univ a)]
    exact Sym2.card_toMultiset (ends e)
  simp [h, mul_comm]

/-- The odd-degree dots come in pairs: in any such network the number of dots whose
degree is odd is even (0, 2, 4, ..., never 1 or 3). -/
theorem odd_degree_dots_are_even_in_number
    {V E : Type*} [Fintype V] [Fintype E] [DecidableEq V] (ends : E → Sym2 V) :
    Even (univ.filter (fun v => Odd (lineEnds ends v))).card := by
  have h := sum_of_degrees_eq_twice_number_of_lines ends
  have h2 : Even (∑ v, lineEnds ends v) := by rw [h]; exact even_two_mul _
  exact (Finset.even_sum_iff_even_card_odd (s := univ) (fun v => lineEnds ends v)).1 h2

/-- The veto for regular networks: if every dot has the same degree d, then d times the
number of dots is even. So no network has nine dots each of degree 3, or five of degree 3. -/
theorem regular_degree_times_dots_is_even
    {V E : Type*} [Fintype V] [Fintype E] [DecidableEq V] (ends : E → Sym2 V)
    (d : ℕ) (hreg : ∀ v, lineEnds ends v = d) :
    Even (d * Fintype.card V) := by
  have h := sum_of_degrees_eq_twice_number_of_lines ends
  simp only [hreg, sum_const, card_univ, smul_eq_mul] at h
  rw [mul_comm, h]
  exact even_two_mul _

/-! The card's worked numbers. Stations A to F are 0 to 5. -/

/-- The metro: lines A-B, B-C, C-D, D-E, E-F, F-A and the crossings B-E, C-F. -/
def metro : Fin 8 → Sym2 (Fin 6) :=
  ![s(0, 1), s(1, 2), s(2, 3), s(3, 4), s(4, 5), s(5, 0), s(1, 4), s(2, 5)]

-- The degrees read off the map: 2, 3, 3, 2, 3, 3.
example : (List.ofFn fun v => lineEnds metro v) = [2, 3, 3, 2, 3, 3] := by decide
-- Road one, the degrees added: 16. Road two, two ends a line: 2 × 8 = 16.
example : ∑ v, lineEnds metro v = 16 := by decide
example : 2 * Fintype.card (Fin 8) = 16 := by decide
-- The odd-degree stations are B, C, E, F: four of them.
example : univ.filter (fun v => Odd (lineEnds metro v)) = {1, 2, 4, 5} := by decide
-- A loop at A adds two, not one: nine lines, degree total 18 (not 17).
example : ∑ v, lineEnds (Fin.cons s(0, 0) metro) v = 18 := by decide
-- A second B-C track counts separately: nine lines, degree total 18 (not 16).
example : ∑ v, lineEnds (Fin.cons s(1, 2) metro) v = 18 := by decide
-- Nine people each shaking three hands: 9 × 3 = 27, odd, so no such party.
example : ¬ Even (3 * 9) := by decide
-- Four hands each: 9 × 4 = 36 = 2 × 18 handshakes.
example : 4 * 9 = 2 * 18 := by norm_num
-- Five stations each meeting three lines: 3 × 5 = 15, odd.
example : ¬ Even (3 * 5) := by decide

#print axioms sum_of_degrees_eq_twice_number_of_lines
#print axioms odd_degree_dots_are_even_in_number
#print axioms regular_degree_times_dots_is_even
