-- Pell's equation: the positive whole-number solutions of x^2 - 2y^2 = 1 are exactly the powers of 3 + 2 root 2, there are infinitely many of them, and each x/y sits just above root 2, closer with every step.
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Tactic.LinearCombination

lemma pell_aux_coeff_eq (a b c d : ℤ) (h : (a : ℝ) + b * √2 = c + d * √2) : a = c ∧ b = d := by
  by_cases hbd : b = d
  · subst hbd
    refine ⟨?_, rfl⟩
    exact_mod_cast (by linarith : (a : ℝ) = c)
  · exfalso
    have hne : ((b - d : ℤ) : ℝ) ≠ 0 := by exact_mod_cast sub_ne_zero.mpr hbd
    have key : √2 = ((c - a : ℤ) : ℝ) / ((b - d : ℤ) : ℝ) := by
      rw [eq_div_iff hne]; push_cast; linarith
    exact (irrational_iff_ne_rational _).mp irrational_sqrt_two (c - a) (b - d)
      (sub_ne_zero.mpr hbd) key

lemma pell_aux_sqrt_mul_self : √2 * √2 = 2 := Real.mul_self_sqrt (by norm_num)

lemma pell_aux_pow (n : ℕ) :
    ∃ a b : ℕ, (3 + 2 * √2) ^ n = a + b * √2 ∧ (a : ℤ) ^ 2 - 2 * (b : ℤ) ^ 2 = 1 := by
  induction n with
  | zero => exact ⟨1, 0, by simp, by norm_num⟩
  | succ n ih =>
    obtain ⟨a, b, h1, h2⟩ := ih
    refine ⟨3 * a + 4 * b, 2 * a + 3 * b, ?_, ?_⟩
    · rw [pow_succ, h1]; push_cast
      linear_combination (2 * (b : ℝ)) * pell_aux_sqrt_mul_self
    · push_cast; linear_combination h2

lemma pell_aux_descent (y : ℕ) : ∀ x : ℕ, 0 < y → (x : ℤ) ^ 2 - 2 * (y : ℤ) ^ 2 = 1 →
    ∃ n : ℕ, 0 < n ∧ (x : ℝ) + y * √2 = (3 + 2 * √2) ^ n := by
  induction y using Nat.strong_induction_on with
  | _ y ih =>
  intro x hy h
  have hy2 : 2 ≤ y := by
    by_contra hc
    have hy1 : y = 1 := by omega
    subst hy1
    push_cast at h
    have hx0 : (0 : ℤ) ≤ x := by positivity
    rcases (show x ≤ 1 ∨ 2 ≤ x by omega) with hx | hx
    · have : (x : ℤ) ≤ 1 := by exact_mod_cast hx
      nlinarith
    · have : (2 : ℤ) ≤ x := by exact_mod_cast hx
      nlinarith
  have hyz : (2 : ℤ) ≤ y := by exact_mod_cast hy2
  have hx0 : (0 : ℤ) ≤ x := by positivity
  have h1 : 4 * y ≤ 3 * x := by
    have : (4 * y : ℤ) ≤ 3 * x := by nlinarith
    exact_mod_cast this
  have h2 : 2 * x ≤ 3 * y := by
    have : (2 * x : ℤ) ≤ 3 * y := by nlinarith
    exact_mod_cast this
  have h3 : y < x := by
    have : (y : ℤ) < x := by nlinarith
    exact_mod_cast this
  obtain ⟨x', y', rfl, rfl⟩ : ∃ x' y' : ℕ, x = 3 * x' + 4 * y' ∧ y = 2 * x' + 3 * y' :=
    ⟨3 * x - 4 * y, 3 * y - 2 * x, by omega, by omega⟩
  have h' : (x' : ℤ) ^ 2 - 2 * (y' : ℤ) ^ 2 = 1 := by
    push_cast at h; linear_combination h
  have hstep : ((3 * x' + 4 * y' : ℕ) : ℝ) + ((2 * x' + 3 * y' : ℕ) : ℝ) * √2 =
      ((x' : ℝ) + y' * √2) * (3 + 2 * √2) := by
    push_cast; linear_combination (-2 * (y' : ℝ)) * pell_aux_sqrt_mul_self
  rcases Nat.eq_zero_or_pos y' with hy0 | hy0
  · subst hy0
    have hx1 : x' = 1 := by
      push_cast at h'
      have hx0' : (0 : ℤ) ≤ x' := by positivity
      have : (x' : ℤ) = 1 := by nlinarith
      exact_mod_cast this
    subst hx1
    exact ⟨1, by norm_num, by rw [hstep]; push_cast; ring⟩
  · obtain ⟨n, -, hn⟩ := ih y' (by omega) x' hy0 h'
    exact ⟨n + 1, by omega, by rw [hstep, hn, pow_succ]⟩

lemma pell_aux_gap (x y : ℕ) (hy : 0 < y) (h : (x : ℤ) ^ 2 - 2 * (y : ℤ) ^ 2 = 1) :
    (x : ℝ) / y - √2 = 1 / (y * (x + y * √2)) := by
  have hr : (x : ℝ) ^ 2 - 2 * (y : ℝ) ^ 2 = 1 := by exact_mod_cast h
  have hyr : (0 : ℝ) < y := by exact_mod_cast hy
  have hpos : (0 : ℝ) < x + y * √2 := by positivity
  rw [div_sub' (ne_of_gt hyr), div_eq_div_iff (ne_of_gt hyr) (by positivity)]
  have hsq : √2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  linear_combination (y : ℝ) * hr - (y : ℝ) ^ 3 * hsq

lemma pell_aux_above (x y : ℕ) (h : (x : ℤ) ^ 2 - 2 * (y : ℤ) ^ 2 = 1) : (y : ℝ) * √2 < x := by
  have hr : (x : ℝ) ^ 2 - 2 * (y : ℝ) ^ 2 = 1 := by exact_mod_cast h
  have hs : ((y : ℝ) * √2) ^ 2 = 2 * (y : ℝ) ^ 2 := by
    rw [mul_pow, Real.sq_sqrt (by norm_num)]; ring
  nlinarith [Real.sqrt_nonneg 2, (Nat.cast_nonneg x : (0 : ℝ) ≤ x),
    (Nat.cast_nonneg y : (0 : ℝ) ≤ y), mul_nonneg (Nat.cast_nonneg y : (0 : ℝ) ≤ y) (Real.sqrt_nonneg 2)]

lemma pell_aux_step (x y : ℕ) (h : (x : ℤ) ^ 2 - 2 * (y : ℤ) ^ 2 = 1) :
    ((3 * x + 4 * y : ℕ) : ℤ) ^ 2 - 2 * ((2 * x + 3 * y : ℕ) : ℤ) ^ 2 = 1 := by
  push_cast; linear_combination h

/-- The whole list, by one multiplication. For whole numbers x and y above zero,
x^2 - 2y^2 = 1 holds exactly when x + y root 2 is a power of 3 + 2 root 2, the power
n counting the solutions from 1: every power solves the equation, and nothing else does. -/
theorem pell_two_solutions_are_powers_of_three_plus_two_root_two (x y : ℕ) (hx : 0 < x)
    (hy : 0 < y) :
    (x : ℤ) ^ 2 - 2 * (y : ℤ) ^ 2 = 1 ↔
      ∃ n : ℕ, 0 < n ∧ (x : ℝ) + y * √2 = (3 + 2 * √2) ^ n := by
  constructor
  · intro h
    exact pell_aux_descent y x hy h
  · rintro ⟨n, -, hn⟩
    obtain ⟨a, b, hab, hab2⟩ := pell_aux_pow n
    have := pell_aux_coeff_eq x y a b (by push_cast; rw [hn, hab])
    obtain ⟨h1, h2⟩ := this
    rw [h1, h2]; exact hab2

/-- The solutions never run out: there are infinitely many pairs (x, y) of whole numbers
above zero with x^2 - 2y^2 = 1, and the step (x, y) ↦ (3x + 4y, 2x + 3y) turns every
solution into another one. -/
theorem pell_two_solutions_never_run_out :
    {p : ℕ × ℕ | 0 < p.1 ∧ 0 < p.2 ∧ (p.1 : ℤ) ^ 2 - 2 * (p.2 : ℤ) ^ 2 = 1}.Infinite ∧
      ∀ x y : ℕ, (x : ℤ) ^ 2 - 2 * (y : ℤ) ^ 2 = 1 →
        ((3 * x + 4 * y : ℕ) : ℤ) ^ 2 - 2 * ((2 * x + 3 * y : ℕ) : ℤ) ^ 2 = 1 := by
  refine ⟨?_, pell_aux_step⟩
  obtain ⟨g, hg⟩ : ∃ g : ℕ × ℕ → ℕ × ℕ, ∀ p, g p = (3 * p.1 + 4 * p.2, 2 * p.1 + 3 * p.2) :=
    ⟨_, fun _ => rfl⟩
  have hmem : ∀ n, g^[n] (3, 2) ∈
      {p : ℕ × ℕ | 0 < p.1 ∧ 0 < p.2 ∧ (p.1 : ℤ) ^ 2 - 2 * (p.2 : ℤ) ^ 2 = 1} := by
    intro n
    induction n with
    | zero => simp only [Function.iterate_zero, id, Set.mem_ofPred_eq]; norm_num
    | succ n ih =>
      rw [Function.iterate_succ_apply']
      obtain ⟨h1, h2, h3⟩ := ih
      rw [hg]
      exact ⟨by omega, by omega, pell_aux_step _ _ h3⟩
  have hmono : StrictMono (fun n => (g^[n] (3, 2)).2) := by
    refine strictMono_nat_of_lt_succ fun n => ?_
    show (g^[n] (3, 2)).2 < (g^[n + 1] (3, 2)).2
    rw [Function.iterate_succ_apply', hg]
    have := (hmem n).2.1
    dsimp only; omega
  refine Set.infinite_of_injective_forall_mem (f := fun n => g^[n] (3, 2)) ?_ hmem
  intro a b hab
  exact hmono.injective (congrArg Prod.snd hab)

/-- Each solution is a fine fraction for root 2, and the next one is finer. If x and y are
above zero and x^2 - 2y^2 = 1, then x/y sits above root 2 by less than 1 / (2 root 2 y^2),
and the next solution's fraction (3x + 4y)/(2x + 3y) is still above root 2 but closer. -/
theorem pell_two_fraction_overshoots_root_two_less_each_step (x y : ℕ) (hx : 0 < x)
    (hy : 0 < y) (h : (x : ℤ) ^ 2 - 2 * (y : ℤ) ^ 2 = 1) :
    (0 < (x : ℝ) / y - √2 ∧ (x : ℝ) / y - √2 < 1 / (2 * √2 * (y : ℝ) ^ 2)) ∧
      (0 < ((3 * x + 4 * y : ℕ) : ℝ) / (2 * x + 3 * y : ℕ) - √2 ∧
        ((3 * x + 4 * y : ℕ) : ℝ) / (2 * x + 3 * y : ℕ) - √2 < (x : ℝ) / y - √2) := by
  have hY : 0 < 2 * x + 3 * y := by omega
  have h' := pell_aux_step x y h
  have hyr : (0 : ℝ) < y := by exact_mod_cast hy
  have hxr : (0 : ℝ) < x := by exact_mod_cast hx
  have hab := pell_aux_above x y h
  have hab' := pell_aux_above _ _ h'
  rw [pell_aux_gap x y hy h, pell_aux_gap _ _ hY h']
  have hs := Real.sqrt_nonneg 2
  have hs2 := pell_aux_sqrt_mul_self
  refine ⟨⟨by positivity, ?_⟩, ⟨by positivity, ?_⟩⟩
  · apply one_div_lt_one_div_of_lt (by positivity)
    nlinarith
  · apply one_div_lt_one_div_of_lt (by positivity)
    push_cast
    have hA : (y : ℝ) ≤ 2 * x + 3 * y := by linarith
    have hB : (x : ℝ) + y * √2 < 3 * x + 4 * y + (2 * x + 3 * y) * √2 := by
      nlinarith [mul_nonneg hxr.le hs, mul_nonneg hyr.le hs]
    exact mul_lt_mul' hA hB (by positivity) (by linarith)

-- The counters: 9 - 8, 289 - 288, 9801 - 9800, 332929 - 332928 and 11309769 - 11309768 each leave 1.
example : (3 : ℤ) ^ 2 - 2 * 2 ^ 2 = 1 ∧ (17 : ℤ) ^ 2 - 2 * 12 ^ 2 = 1 ∧
    (99 : ℤ) ^ 2 - 2 * 70 ^ 2 = 1 ∧ (577 : ℤ) ^ 2 - 2 * 408 ^ 2 = 1 ∧
    (3363 : ℤ) ^ 2 - 2 * 2378 ^ 2 = 1 := by decide
example : (17 : ℤ) ^ 2 = 289 ∧ 2 * (12 : ℤ) ^ 2 = 288 ∧ (99 : ℤ) ^ 2 = 9801 ∧ 2 * (70 : ℤ) ^ 2 = 9800 ∧
    (577 : ℤ) ^ 2 = 332929 ∧ 2 * (408 : ℤ) ^ 2 = 332928 := by decide
-- The step rule (3x + 4y, 2x + 3y) walks (1, 0), (3, 2), (17, 12), (99, 70), (577, 408), (3363, 2378).
example : (3 * 1 + 4 * 0, 2 * 1 + 3 * 0) = (3, 2) ∧ (3 * 3 + 4 * 2, 2 * 3 + 3 * 2) = (17, 12) ∧
    (3 * 17 + 4 * 12, 2 * 17 + 3 * 12) = (99, 70) ∧ (3 * 99 + 4 * 70, 2 * 99 + 3 * 70) = (577, 408) ∧
    (3 * 577 + 4 * 408, 2 * 577 + 3 * 408) = (3363, 2378) := by decide
-- One multiplication: (3 + 2 root 2)^2 = 17 + 12 root 2.
example : (3 + 2 * √2) ^ 2 = 17 + 12 * √2 := by
  norm_num [add_sq, mul_pow]; ring
-- The backward step (3x - 4y, 3y - 2x): from (17, 12) to (3, 2), from (3, 2) to (1, 0).
example : ((3 * 17 - 4 * 12 : ℤ), (3 * 12 - 2 * 17 : ℤ)) = (3, 2) ∧
    ((3 * 3 - 4 * 2 : ℤ), (3 * 2 - 2 * 3 : ℤ)) = (1, 0) := by decide
-- The three mistakes: 17^2 - 2 × 40^2 = -2911, 141^2 - 2 × 100^2 = -119, 7^2 - 2 × 5^2 = -1.
example : 2 * 17 + 3 * 2 = 40 ∧ (17 : ℤ) ^ 2 - 2 * 40 ^ 2 = -2911 ∧
    (141 : ℤ) ^ 2 - 2 * 100 ^ 2 = -119 ∧ (7 : ℤ) ^ 2 - 2 * 5 ^ 2 = -1 := by decide
-- The other equation with root 3: (2, 1) solves x^2 - 3y^2 = 1.
example : (2 : ℤ) ^ 2 - 3 * 1 ^ 2 = 1 := by decide
-- A4 paper: 297 over 210 is exactly 99/70, step three of the list.
example : (297 : ℚ) / 210 = 99 / 70 := by norm_num

#print axioms pell_two_solutions_are_powers_of_three_plus_two_root_two
#print axioms pell_two_solutions_never_run_out
#print axioms pell_two_fraction_overshoots_root_two_less_each_step
#print axioms pell_aux_coeff_eq
#print axioms pell_aux_sqrt_mul_self
#print axioms pell_aux_pow
#print axioms pell_aux_descent
#print axioms pell_aux_gap
#print axioms pell_aux_above
#print axioms pell_aux_step
