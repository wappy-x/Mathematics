-- No gaps: every non-empty collection of real numbers with a ceiling has a lowest ceiling, the interval (0, 1) has lowest ceiling 1 and no largest member, and the fractions whose square is under 2 have no lowest fraction ceiling.
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Order.Bounds.Basic
import Mathlib.Order.Interval.Set.Basic
import Mathlib.Tactic.NormNum
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp

/-- Completeness of the real numbers: every collection `S` of real numbers that has a member
and a ceiling (an upper bound) has a lowest ceiling `s`, a real number. Lowest ceiling means
the card's two lines: no member of `S` passes `s`, and every number `t` below `s` is passed by
some member of `S`. -/
theorem reals_complete_sup_exists (S : Set ℝ) (h_member : S.Nonempty) (h_ceiling : BddAbove S) :
    ∃ s : ℝ, (∀ x ∈ S, x ≤ s) ∧ (∀ t < s, ∃ x ∈ S, t < x) := by
  refine ⟨sSup S, fun x hx => le_csSup h_ceiling hx, fun t ht => ?_⟩
  exact exists_lt_of_lt_csSup h_member ht

/-- The open interval (0, 1), every real number strictly between 0 and 1, has supremum 1:
no member passes 1, and every number below 1 is passed by some member. It has no maximum:
no member is at least as large as every member. -/
theorem sup_of_open_unit_interval_is_one_with_no_max :
    ((∀ x ∈ Set.Ioo (0 : ℝ) 1, x ≤ 1) ∧ (∀ t < (1 : ℝ), ∃ x ∈ Set.Ioo (0 : ℝ) 1, t < x)) ∧
      ¬ ∃ m ∈ Set.Ioo (0 : ℝ) 1, ∀ x ∈ Set.Ioo (0 : ℝ) 1, x ≤ m := by
  refine ⟨⟨fun x hx => hx.2.le, fun t ht => ?_⟩, ?_⟩
  · refine ⟨max (1 / 2) ((t + 1) / 2), ⟨?_, ?_⟩, ?_⟩
    · exact lt_max_of_lt_left (by norm_num)
    · exact max_lt (by norm_num) (by linarith)
    · exact lt_max_of_lt_right (by linarith)
  · rintro ⟨m, hm, hmax⟩
    have h := hmax ((m + 1) / 2) ⟨by linarith [hm.1], by linarith [hm.2]⟩
    linarith [hm.2]

/-- Fractions alone are not enough: the fractions whose square is under 2 have a member and a
fraction ceiling, yet no fraction is their lowest ceiling. -/
theorem fractions_square_under_two_have_no_lowest_ceiling :
    {q : ℚ | q ^ 2 < 2}.Nonempty ∧ BddAbove {q : ℚ | q ^ 2 < 2} ∧
      ¬ ∃ s : ℚ, (∀ x ∈ {q : ℚ | q ^ 2 < 2}, x ≤ s) ∧
        (∀ t < s, ∃ x ∈ {q : ℚ | q ^ 2 < 2}, t < x) := by
  refine ⟨⟨0, by norm_num⟩, ⟨2, fun x hx => ?_⟩, ?_⟩
  · simp only [Set.mem_ofPred_eq] at hx
    by_contra h
    push Not at h
    nlinarith
  · rintro ⟨s, hub, hlow⟩
    have h1 : (1 : ℚ) ≤ s := hub 1 (by norm_num)
    have hpos : (0 : ℚ) < s + 2 := by linarith
    set s' : ℚ := (2 * s + 2) / (s + 2) with hs'
    have key : s' * (s + 2) = 2 * s + 2 := by
      rw [hs']; field_simp
    rcases lt_trichotomy (s ^ 2) 2 with hlt | heq | hgt
    · have hgt' : s < s' := by nlinarith
      have hmem : s' ^ 2 < 2 := by nlinarith
      have := hub s' hmem
      linarith
    · apply irrational_sqrt_two
      refine ⟨|s|, ?_⟩
      have : ((s : ℝ)) ^ 2 = 2 := by exact_mod_cast heq
      rw [← this, Real.sqrt_sq_eq_abs]
      push_cast
      rfl
    · have hlt' : s' < s := by nlinarith
      have hs'pos : 0 < s' := by nlinarith
      have hs'sq : 2 < s' ^ 2 := by nlinarith
      obtain ⟨x, hx, hx'⟩ := hlow s' hlt'
      simp only [Set.mem_ofPred_eq] at hx
      nlinarith

-- Worked numbers: each proposed maximum m is beaten by (m + 1)/2, still below 1.
example : ((9 : ℚ) / 10 + 1) / 2 = 19 / 20 ∧ (9 : ℚ) / 10 < 19 / 20 ∧ (19 : ℚ) / 20 < 1 := by
  norm_num
example : ((99 : ℚ) / 100 + 1) / 2 = 199 / 200 ∧ (99 : ℚ) / 100 < 199 / 200 ∧
    (199 : ℚ) / 200 < 1 := by norm_num
example : ((999 : ℚ) / 1000 + 1) / 2 = 1999 / 2000 ∧ (999 : ℚ) / 1000 < 1999 / 2000 ∧
    (1999 : ℚ) / 2000 < 1 := by norm_num
-- Challengers below 1: 0.5 is passed by 0.75; -3 is passed by 0.5.
example : ((1 : ℚ) / 2 + 1) / 2 = 3 / 4 ∧ (1 : ℚ) / 2 < 3 / 4 := by norm_num
example : (-3 : ℚ) < 1 / 2 := by norm_num
-- Grid of step 1/2^n: the largest member 1 - 1/2^n, n = 1 to 3, and the gap at n = 20.
example : (1 : ℚ) - 1 / 2 ^ 1 = 1 / 2 ∧ (1 : ℚ) - 1 / 2 ^ 2 = 3 / 4 ∧
    (1 : ℚ) - 1 / 2 ^ 3 = 7 / 8 := by norm_num
example : (2 : ℕ) ^ 20 = 1048576 := by norm_num
-- The fraction rule q -> (2q + 2)/(q + 2): 3/2, 10/7, 17/12, 58/41, 99/70.
example : (2 * ((3 : ℚ) / 2) + 2) / ((3 : ℚ) / 2 + 2) = 10 / 7 := by norm_num
example : (2 * ((10 : ℚ) / 7) + 2) / ((10 : ℚ) / 7 + 2) = 17 / 12 := by norm_num
example : (2 * ((17 : ℚ) / 12) + 2) / ((17 : ℚ) / 12 + 2) = 58 / 41 := by norm_num
example : (2 * ((58 : ℚ) / 41) + 2) / ((58 : ℚ) / 41 + 2) = 99 / 70 := by norm_num
-- Each is a ceiling (square over 2), lower than the one before.
example : 3 ^ 2 > 2 * 2 ^ 2 ∧ 10 ^ 2 > 2 * 7 ^ 2 ∧ 17 ^ 2 > 2 * 12 ^ 2 ∧
    58 ^ 2 > 2 * 41 ^ 2 ∧ 99 ^ 2 > 2 * 70 ^ 2 := by decide
example : 10 * 2 < 3 * 7 ∧ 17 * 7 < 10 * 12 ∧ 58 * 12 < 17 * 41 ∧ 99 * 41 < 58 * 70 := by
  decide
-- Halving 20 times: root 2 lies between 1482910/2^20 and 1482911/2^20, below every fraction ceiling.
example : 1482910 ^ 2 < 2 * 1048576 ^ 2 ∧ 2 * 1048576 ^ 2 < 1482911 ^ 2 := by norm_num
example : 99 * 1048576 > 1482911 * 70 := by norm_num
-- No ceiling over 1, 2, 3, ...: 1000.5 is passed by 1001.
example : (2001 : ℚ) / 2 < 1001 := by norm_num
-- The figure: x = 40 + 250 t for t = 0, 1/2, 1, 6/5.
example : 40 + 250 * (0 : ℚ) = 40 ∧ 40 + 250 * ((1 : ℚ) / 2) = 165 ∧ 40 + 250 * (1 : ℚ) = 290 ∧
    40 + 250 * ((6 : ℚ) / 5) = 340 := by norm_num

#print axioms reals_complete_sup_exists
#print axioms sup_of_open_unit_interval_is_one_with_no_max
#print axioms fractions_square_under_two_have_no_lowest_ceiling
