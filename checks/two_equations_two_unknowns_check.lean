-- Two equations, two unknowns: when the crossing number a × d − b × c is not zero, the pair a x + b y = p, c x + d y = q has exactly one solution, given by x = (p d − b q) / (a d − b c) and y = (a q − c p) / (a d − b c); when it is zero, there is no solution or there are infinitely many.
import Mathlib.Data.Real.Basic
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.Algebra.CharZero.Infinite

/-- Two facts pin two unknowns. Take two equations a x + b y = p and c x + d y = q in two unknown
numbers x and y. If the crossing number a × d − b × c is not zero (one equation's counts are not
just the other's scaled up), then exactly one pair (x, y) fits both. -/
theorem exactly_one_pair_when_crossing_number_nonzero (a b c d p q : ℝ)
    (h : a * d - b * c ≠ 0) :
    ∃! xy : ℝ × ℝ, a * xy.1 + b * xy.2 = p ∧ c * xy.1 + d * xy.2 = q := by
  refine ⟨((p * d - b * q) / (a * d - b * c), (a * q - c * p) / (a * d - b * c)), ?_, ?_⟩
  · refine ⟨?_, ?_⟩
    · simp only
      rw [mul_div_assoc', mul_div_assoc', ← add_div, div_eq_iff h]
      ring
    · simp only
      rw [mul_div_assoc', mul_div_assoc', ← add_div, div_eq_iff h]
      ring
  · rintro ⟨x, y⟩ ⟨h1, h2⟩
    simp only at h1 h2
    have hx : x * (a * d - b * c) = p * d - b * q := by linear_combination d * h1 - b * h2
    have hy : y * (a * d - b * c) = a * q - c * p := by linear_combination a * h2 - c * h1
    rw [Prod.mk.injEq, eq_div_iff h, eq_div_iff h]
    exact ⟨hx, hy⟩

/-- Solve once with letters. When the crossing number a × d − b × c is not zero, a pair (x, y)
fits both a x + b y = p and c x + d y = q exactly when
x = (p d − b q) / (a d − b c) and y = (a q − c p) / (a d − b c). -/
theorem crossing_formula_solves_the_pair (a b c d p q : ℝ) (h : a * d - b * c ≠ 0) (x y : ℝ) :
    (a * x + b * y = p ∧ c * x + d * y = q) ↔
      (x = (p * d - b * q) / (a * d - b * c) ∧ y = (a * q - c * p) / (a * d - b * c)) := by
  constructor
  · rintro ⟨h1, h2⟩
    rw [eq_div_iff h, eq_div_iff h]
    exact ⟨by linear_combination d * h1 - b * h2, by linear_combination a * h2 - c * h1⟩
  · rintro ⟨rfl, rfl⟩
    constructor
    · rw [mul_div_assoc', mul_div_assoc', ← add_div, div_eq_iff h]
      ring
    · rw [mul_div_assoc', mul_div_assoc', ← add_div, div_eq_iff h]
      ring

/-- The two ways a crossing fails. If the crossing number a × d − b × c is zero, the two equations
a x + b y = p and c x + d y = q never have exactly one solution: either no pair fits both
(parallel lines), or infinitely many pairs do (one line drawn twice). -/
theorem zero_crossing_number_gives_none_or_infinitely_many (a b c d p q : ℝ)
    (h : a * d - b * c = 0) :
    {xy : ℝ × ℝ | a * xy.1 + b * xy.2 = p ∧ c * xy.1 + d * xy.2 = q} = ∅ ∨
      {xy : ℝ × ℝ | a * xy.1 + b * xy.2 = p ∧ c * xy.1 + d * xy.2 = q}.Infinite := by
  rcases Set.eq_empty_or_nonempty
      {xy : ℝ × ℝ | a * xy.1 + b * xy.2 = p ∧ c * xy.1 + d * xy.2 = q} with hs | ⟨⟨x0, y0⟩, h1, h2⟩
  · exact Or.inl hs
  · right
    obtain ⟨u, v, huv, hu, hv⟩ : ∃ u v : ℝ, (u, v) ≠ (0, 0) ∧ a * u + b * v = 0 ∧ c * u + d * v = 0 := by
      by_cases hab : a = 0 ∧ b = 0
      · by_cases hcd : c = 0 ∧ d = 0
        · obtain ⟨rfl, rfl⟩ := hab
          obtain ⟨rfl, rfl⟩ := hcd
          exact ⟨1, 0, by simp, by ring, by ring⟩
        · refine ⟨-d, c, ?_, by linear_combination -h, by ring⟩
          intro hh
          simp only [Prod.mk.injEq, neg_eq_zero] at hh
          exact hcd ⟨hh.2, hh.1⟩
      · refine ⟨-b, a, ?_, by ring, by linear_combination h⟩
        intro hh
        simp only [Prod.mk.injEq, neg_eq_zero] at hh
        exact hab ⟨hh.2, hh.1⟩
    refine Set.infinite_of_injective_forall_mem (α := ℝ) (f := fun t => (x0 + t * u, y0 + t * v))
      ?_ ?_
    · intro s t hst
      simp only [Prod.mk.injEq] at hst
      obtain ⟨e1, e2⟩ := hst
      by_contra hne
      have hs' : s - t ≠ 0 := sub_ne_zero.mpr hne
      apply huv
      rw [Prod.mk.injEq]
      constructor
      · have : (s - t) * u = 0 := by linear_combination e1
        exact (mul_eq_zero.mp this).resolve_left hs'
      · have : (s - t) * v = 0 := by linear_combination e2
        exact (mul_eq_zero.mp this).resolve_left hs'
    · intro t
      simp only at h1 h2
      exact ⟨by linear_combination h1 + t * hu, by linear_combination h2 + t * hv⟩

-- The museum in whole cents: Friday 2 adults and 3 children, 4100; Saturday 1 adult and
-- 2 children, 2400. Adult 1000 and child 700 fit both receipts.
example : (2 : ℤ) * 1000 + 3 * 700 = 4100 ∧ (1 : ℤ) * 1000 + 2 * 700 = 2400 := by decide
-- The crossing number for Friday against Saturday is 2 × 2 − 3 × 1 = 1.
example : (2 : ℤ) * 2 - 3 * 1 = 1 := by decide
-- Elimination: Saturday doubled is 2 adults, 4 children, 4800; minus Friday leaves one child, 700.
example : (2 : ℤ) * 2400 = 4800 ∧ (4800 : ℤ) - 4100 = 700 ∧ (2400 : ℤ) - 2 * 700 = 1000 := by
  decide
-- Substitution: 2 (24 − 2 × 7) + 3 × 7 = 41, in dollars.
example : (2 : ℤ) * (24 - 2 * 7) + 3 * 7 = 41 := by decide
-- The cross-multiplied formulas give adult 10 and child 7 dollars.
example : ((41 : ℝ) * 2 - 3 * 24) / (2 * 2 - 3 * 1) = 10 ∧
    ((2 : ℝ) * 24 - 1 * 41) / (2 * 2 - 3 * 1) = 7 := by norm_num
-- Friday alone: adult 13, child 5 fits Friday's 41 but makes Saturday 23, not 24.
example : (2 : ℤ) * 13 + 3 * 5 = 41 ∧ (1 : ℤ) * 13 + 2 * 5 = 23 := by decide
-- Sunday, 4 adults and 6 children: crossing number with Friday is 2 × 6 − 3 × 4 = 0,
-- and Friday doubled is 82, not Sunday's 70.
example : (2 : ℤ) * 6 - 3 * 4 = 0 ∧ (2 : ℤ) * 41 = 82 ∧ (82 : ℤ) ≠ 70 := by decide
-- Had Sunday read 82, both (10, 7) and (13, 5) fit it.
example : (4 : ℤ) * 10 + 6 * 7 = 82 ∧ (4 : ℤ) * 13 + 6 * 5 = 82 := by decide
-- Mistake: doubling only the tickets gives child 24 − 41 = −17 and adult 24 − 2 × (−17) = 58.
example : (24 : ℤ) - 41 = -17 ∧ (24 : ℤ) - 2 * (-17) = 58 := by decide

#print axioms exactly_one_pair_when_crossing_number_nonzero
#print axioms crossing_formula_solves_the_pair
#print axioms zero_crossing_number_gives_none_or_infinitely_many
