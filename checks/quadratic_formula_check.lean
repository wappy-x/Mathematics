-- The quadratic formula: for real a, b, c with a not zero, the real solutions of a x^2 + b x + c = 0 are exactly (-b ± √(b^2 - 4ac)) / (2a), the discriminant b^2 - 4ac being above, at or below zero gives two, one or no solutions, and the two solutions add to -b/a and multiply to c/a.
import Mathlib.Algebra.QuadraticDiscriminant
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Data.Set.Card
import Mathlib.Tactic.NormNum.RealSqrt

/-- The quadratic formula. Take real numbers a, b and c with a not zero, and write the equation
with one side zero: a x^2 + b x + c = 0. When the discriminant D = b^2 - 4ac is not below zero,
a real number x solves the equation exactly when x = (-b + √D) / (2a) or x = (-b - √D) / (2a). -/
theorem quadratic_formula_solves_every_quadratic (a b c : ℝ) (ha : a ≠ 0)
    (hD : 0 ≤ discrim a b c) (x : ℝ) :
    a * x ^ 2 + b * x + c = 0 ↔
      x = (-b + Real.sqrt (discrim a b c)) / (2 * a) ∨
        x = (-b - Real.sqrt (discrim a b c)) / (2 * a) := by
  have hs : discrim a b c = Real.sqrt (discrim a b c) * Real.sqrt (discrim a b c) :=
    (Real.mul_self_sqrt hD).symm
  have h := quadratic_eq_zero_iff ha hs x
  rw [← h]
  constructor <;> intro h' <;> nlinarith [h', sq x]

/-- The discriminant counts the answers on the number line. With a not zero: if D = b^2 - 4ac is
above zero, a x^2 + b x + c = 0 has exactly two real solutions; if D is exactly zero, its one
real solution is -b / (2a); if D is below zero, it has no real solution at all. -/
theorem discriminant_says_how_many_answers (a b c : ℝ) (ha : a ≠ 0) :
    (0 < discrim a b c → {x : ℝ | a * x ^ 2 + b * x + c = 0}.ncard = 2) ∧
      (discrim a b c = 0 → {x : ℝ | a * x ^ 2 + b * x + c = 0} = {-b / (2 * a)}) ∧
      (discrim a b c < 0 → {x : ℝ | a * x ^ 2 + b * x + c = 0} = ∅) := by
  have hsq : ∀ D : ℝ, 0 ≤ D → Real.sqrt D * Real.sqrt D = D := fun D h => Real.mul_self_sqrt h
  have key : ∀ x : ℝ, a * x ^ 2 + b * x + c = 0 ↔ a * (x * x) + b * x + c = 0 := by
    intro x; constructor <;> intro h <;> nlinarith [h]
  refine ⟨?_, ?_, ?_⟩
  · intro hD
    have hs : discrim a b c = Real.sqrt (discrim a b c) * Real.sqrt (discrim a b c) :=
      (hsq _ hD.le).symm
    have hpos : 0 < Real.sqrt (discrim a b c) := Real.sqrt_pos.mpr hD
    have hset : {x : ℝ | a * x ^ 2 + b * x + c = 0} =
        {(-b + Real.sqrt (discrim a b c)) / (2 * a), (-b - Real.sqrt (discrim a b c)) / (2 * a)} := by
      ext x
      simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff]
      rw [key]
      exact quadratic_eq_zero_iff ha hs x
    rw [hset]
    apply Set.ncard_pair
    intro h
    have h2a : (2 * a) ≠ 0 := mul_ne_zero two_ne_zero ha
    rw [div_left_inj' h2a] at h
    linarith
  · intro hD
    have hs : discrim a b c = 0 * 0 := by rw [hD]; ring
    ext x
    simp only [Set.mem_ofPred_eq, Set.mem_singleton_iff]
    rw [key, quadratic_eq_zero_iff ha hs x]
    simp
  · intro hD
    ext x
    simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]
    intro h
    unfold discrim at hD
    have e : b ^ 2 - 4 * a * c = (2 * a * x + b) ^ 2 := by linear_combination (-4 * a) * h
    rw [e] at hD
    exact absurd hD (not_lt.mpr (sq_nonneg _))

/-- Vieta's formulas, read off the quadratic formula. With a not zero and D = b^2 - 4ac not below
zero, the two answers (-b + √D) / (2a) and (-b - √D) / (2a) add to -b/a and multiply to c/a. -/
theorem quadratic_answers_add_to_neg_b_over_a_and_multiply_to_c_over_a (a b c : ℝ) (ha : a ≠ 0)
    (hD : 0 ≤ discrim a b c) :
    (-b + Real.sqrt (discrim a b c)) / (2 * a) + (-b - Real.sqrt (discrim a b c)) / (2 * a)
        = -b / a ∧
      (-b + Real.sqrt (discrim a b c)) / (2 * a) * ((-b - Real.sqrt (discrim a b c)) / (2 * a))
        = c / a := by
  have h2 := Real.mul_self_sqrt hD
  have h2a : (2 * a) ≠ 0 := mul_ne_zero two_ne_zero ha
  constructor
  · field_simp
    ring
  · unfold discrim at h2 ⊢
    field_simp
    nlinarith [h2]

-- The ball: height 20t - 5t^2 is 20 metres at t = 2, and 15 metres at t = 1 and t = 3.
example : (20 : ℝ) * 2 - 5 * 2 ^ 2 = 20 ∧ (20 : ℝ) * 1 - 5 * 1 ^ 2 = 15 ∧
    (20 : ℝ) * 3 - 5 * 3 ^ 2 = 15 := by norm_num
-- Landing: 20t - 5t^2 = 0 at 0 and 4 seconds.
example : (20 : ℝ) * 0 - 5 * 0 ^ 2 = 0 ∧ (20 : ℝ) * 4 - 5 * 4 ^ 2 = 0 := by norm_num
-- The 15 metre question: 5t^2 - 20t + 15 = 0 is solved by t = 1 and t = 3.
example : (5 : ℝ) * 1 ^ 2 + (-20) * 1 + 15 = 0 ∧ (5 : ℝ) * 3 ^ 2 + (-20) * 3 + 15 = 0 := by
  norm_num
-- Completing the square on the numbers: (t - 2)^2 = 1 at t = 1 and t = 3.
example : ((1 : ℝ) - 2) ^ 2 = 1 ∧ ((3 : ℝ) - 2) ^ 2 = 1 := by norm_num
-- Worked numbers by hand: b^2 = 400, 4ac = 300, D = 100, its root 10, -b = 20, 2a = 10.
example : (-20 : ℝ) ^ 2 = 400 ∧ (4 : ℝ) * 5 * 15 = 300 ∧ discrim (5 : ℝ) (-20) 15 = 100 ∧
    Real.sqrt 100 = 10 ∧ -(-20 : ℝ) = 20 ∧ (2 : ℝ) * 5 = 10 := by
  norm_num [discrim]
-- The formula itself hands back 1 and 3.
example : (-(-20 : ℝ) - Real.sqrt (discrim 5 (-20) 15)) / (2 * 5) = 1 ∧
    (-(-20 : ℝ) + Real.sqrt (discrim 5 (-20) 15)) / (2 * 5) = 3 := by
  norm_num [discrim]
-- Sum and product: 1 + 3 = 20/5 = -b/a and 1 × 3 = 15/5 = c/a.
example : (1 : ℝ) + 3 = -(-20) / 5 ∧ (1 : ℝ) * 3 = 15 / 5 := by norm_num
-- 20 metres: D = 400 - 400 = 0, and the one answer is 20 / 10 = 2.
example : discrim (5 : ℝ) (-20) 20 = 0 ∧ -(-20 : ℝ) / (2 * 5) = 2 := by norm_num [discrim]
-- 25 metres: D = 400 - 500 = -100, below zero, so never.
example : discrim (5 : ℝ) (-20) 25 = -100 := by norm_num [discrim]
-- A lower height, 10 metres: D = 200.
example : discrim (5 : ℝ) (-20) 10 = 200 := by norm_num [discrim]
-- The first two mistakes: using b for -b gives -3 and -1; dividing only the root gives 19 and 21.
example : ((-20 : ℝ) - 10) / 10 = -3 ∧ ((-20 : ℝ) + 10) / 10 = -1 ∧
    (20 : ℝ) - 10 / 10 = 19 ∧ (20 : ℝ) + 10 / 10 = 21 := by norm_num

#print axioms quadratic_formula_solves_every_quadratic
#print axioms discriminant_says_how_many_answers
#print axioms quadratic_answers_add_to_neg_b_over_a_and_multiply_to_c_over_a
