-- The real numbers have no gaps: every collection of real numbers with a member and a ceiling has a lowest ceiling that is a real number, for the numbers whose square is under 2 that lowest ceiling is root 2, and among the fractions the same collection has no lowest ceiling at all.
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic.NormNum
import Mathlib.NumberTheory.Real.Irrational

/-- Completeness: if a collection of real numbers has a member, and some one number sits above
everything in it, then there is a lowest such number (a least upper bound), and it is a real
number too. -/
theorem nonempty_bounded_above_has_lowest_ceiling (S : Set ℝ) (hne : S.Nonempty)
    (hbdd : BddAbove S) : ∃ x : ℝ, IsLUB S x := by
  exact ⟨sSup S, isLUB_csSup hne hbdd⟩

/-- The dart: among the real numbers, the collection of every number whose square is under 2
has root 2 as its lowest ceiling. -/
theorem sqrt_two_is_lowest_ceiling : IsLUB {x : ℝ | x * x < 2} (√2) := by
  have h2 : √2 * √2 = 2 := Real.mul_self_sqrt (by norm_num)
  have hpos : 0 < √2 := Real.sqrt_pos.mpr (by norm_num)
  constructor
  · intro x hx
    simp only [Set.mem_setOf_eq] at hx
    by_contra h
    push_neg at h
    nlinarith
  · intro b hb
    have h1 : (1 : ℝ) ≤ b := hb (by simp only [Set.mem_setOf_eq]; norm_num)
    by_contra h
    push_neg at h
    have hm : ((b + √2) / 2) ∈ {x : ℝ | x * x < 2} := by
      simp only [Set.mem_setOf_eq]
      nlinarith
    have := hb hm
    linarith

/-- The fractions have a gap: the fractions whose square is under 2 have a member (1) and a
ceiling (for example 3/2), but every fraction ceiling has a smaller fraction ceiling under it,
so no fraction is the lowest ceiling. -/
theorem fractions_have_no_lowest_ceiling :
    ({q : ℚ | q * q < 2}).Nonempty ∧ BddAbove {q : ℚ | q * q < 2} ∧
      (∀ r ∈ upperBounds {q : ℚ | q * q < 2}, ∃ r' ∈ upperBounds {q : ℚ | q * q < 2}, r' < r) ∧
      ¬ ∃ r : ℚ, IsLUB {q : ℚ | q * q < 2} r := by
  have key : ∀ r ∈ upperBounds {q : ℚ | q * q < 2}, ∃ r' ∈ upperBounds {q : ℚ | q * q < 2}, r' < r := by
    intro r hr
    have h1 : (1 : ℚ) ≤ r := hr (by simp only [Set.mem_setOf_eq]; norm_num)
    have hne : r * r ≠ 2 := by
      intro h
      apply irrational_sqrt_two
      refine ⟨r, ?_⟩
      have h2 : ((r : ℝ)) * (r : ℝ) = 2 := by exact_mod_cast h
      have h0 : (0 : ℝ) ≤ (r : ℝ) := by exact_mod_cast (by linarith : (0 : ℚ) ≤ r)
      rw [← h2]
      exact (Real.sqrt_mul_self h0).symm
    have hge : 2 < r * r := by
      by_contra hcon
      push_neg at hcon
      have hlt : r * r < 2 := lt_of_le_of_ne hcon hne
      have hr2 : r < 2 := by nlinarith
      set δ : ℚ := (2 - r * r) / 5 with hδ
      have hδpos : 0 < δ := by rw [hδ]; linarith
      have hδle : δ ≤ 1 := by rw [hδ]; nlinarith
      have hin : (r + δ) ∈ {q : ℚ | q * q < 2} := by
        simp only [Set.mem_setOf_eq]
        nlinarith
      have := hr hin
      linarith
    refine ⟨r / 2 + 1 / r, ?_, ?_⟩
    · intro q hq
      simp only [Set.mem_setOf_eq] at hq
      have hrpos : 0 < r := by linarith
      have hr' : 0 < r / 2 + 1 / r := by positivity
      have hsq : 2 ≤ (r / 2 + 1 / r) * (r / 2 + 1 / r) := by
        have : (r / 2 + 1 / r) * (r / 2 + 1 / r) - 2 = (r * r - 2) ^ 2 / (4 * (r * r)) := by
          field_simp
          ring
        have : 0 ≤ (r * r - 2) ^ 2 / (4 * (r * r)) := by positivity
        linarith
      by_contra h
      push_neg at h
      nlinarith
    · have hrpos : 0 < r := by linarith
      have : r / 2 + 1 / r < r ↔ 2 < r * r := by
        rw [show r / 2 + 1 / r = (r * r + 2) / (2 * r) by field_simp, div_lt_iff₀ (by positivity)]
        constructor <;> intro h <;> nlinarith
      exact this.mpr hge
  refine ⟨⟨1, by simp only [Set.mem_setOf_eq]; norm_num⟩, ⟨2, ?_⟩, key, ?_⟩
  · intro q hq
    simp only [Set.mem_setOf_eq] at hq
    by_contra h
    push_neg at h
    nlinarith
  · rintro ⟨r, hr⟩
    obtain ⟨r', hr', hlt⟩ := key r hr.1
    have := hr.2 hr'
    linarith

-- 1 is in the collection: 1 × 1 = 1, under 2.
example : (1 * 1 : ℕ) = 1 ∧ (1 : ℕ) < 2 := by decide
-- No places: 1 × 1 = 1 is under 2, and 2 × 2 = 4 is over it.
example : (1 * 1 : ℕ) < 2 ∧ (2 : ℕ) < 2 * 2 := by decide
-- One place, in tenths: 14 × 14 = 196 is under 200, and 15 × 15 = 225 is over it (1.96 and 2.25).
example : (14 * 14 : ℕ) = 196 ∧ (15 * 15 : ℕ) = 225 ∧ (196 : ℕ) < 2 * 10 ^ 2 ∧
    2 * 10 ^ 2 < (225 : ℕ) := by norm_num
-- Two places, in hundredths: 141 × 141 = 19881 and 142 × 142 = 20164 sit either side of 20000.
example : (141 * 141 : ℕ) = 19881 ∧ (142 * 142 : ℕ) = 20164 ∧ (19881 : ℕ) < 2 * 10 ^ 4 ∧
    2 * 10 ^ 4 < (20164 : ℕ) := by norm_num
-- Three places: 1414 × 1414 = 1999396 and 1415 × 1415 = 2002225 sit either side of 2000000.
example : (1414 * 1414 : ℕ) = 1999396 ∧ (1415 * 1415 : ℕ) = 2002225 ∧
    (1999396 : ℕ) < 2 * 10 ^ 6 ∧ 2 * 10 ^ 6 < (2002225 : ℕ) := by norm_num
-- Four places: 14142 × 14142 = 199996164 and 14143 × 14143 = 200024449 sit either side of 200000000.
example : (14142 * 14142 : ℕ) = 199996164 ∧ (14143 * 14143 : ℕ) = 200024449 ∧
    (199996164 : ℕ) < 2 * 10 ^ 8 ∧ 2 * 10 ^ 8 < (200024449 : ℕ) := by norm_num
-- 1.415 is a ceiling, but 1.4143 is a smaller one: 14143 < 14150, and 14143 × 14143 is still over 2 × 10^8.
example : (14143 : ℕ) < 1415 * 10 ∧ 2 * 10 ^ 8 < (14143 * 14143 : ℕ) := by norm_num
-- Stopping at 1.4142 is wrong: its square is under 2, so it is in the collection, not a ceiling.
example : (14142 * 14142 : ℕ) < 2 * 10 ^ 8 := by norm_num

#print axioms nonempty_bounded_above_has_lowest_ceiling
#print axioms sqrt_two_is_lowest_ceiling
#print axioms fractions_have_no_lowest_ceiling
