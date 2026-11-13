-- Logistic regression: the log-likelihood of a logistic regression has at most one best fit when no predictor is an exact combination of the others, any point where all its slopes are zero is that best fit, and a loan book split by a straight line has no best fit at all.
import Mathlib.Analysis.SpecialFunctions.Sigmoid
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Real Finset

/-! Setup. There are `n` loans and `d` predictors. Loan `i` has predictor values `x i j` and
outcome `y i`, which is 1 if it defaulted and 0 if it was repaid. The coefficients are an
intercept `b₀` and one slope `b j` per predictor. The logistic curve `Λ` is Mathlib's
`Real.sigmoid`, `Λ z = 1 / (1 + e^(-z))`. -/

/-- The score of loan `i`: `z i = b₀ + ∑ j, b j * x i j`, the log-odds of default. -/
noncomputable def score {n d : ℕ} (x : Fin n → Fin d → ℝ) (b₀ : ℝ) (b : Fin d → ℝ)
    (i : Fin n) : ℝ :=
  b₀ + ∑ j, b j * x i j

/-- The log-likelihood `ℓ = ∑ i, (y i * z i - ln (1 + e^(z i)))`. -/
noncomputable def logLik {n d : ℕ} (x : Fin n → Fin d → ℝ) (y : Fin n → ℝ) (b₀ : ℝ)
    (b : Fin d → ℝ) : ℝ :=
  ∑ i, (y i * score x b₀ b i - Real.log (1 + Real.exp (score x b₀ b i)))

/-- Helper: the curve `ln (1 + e^z)` lies above its tangent line, whose slope is `Λ z`. -/
lemma logistic_aux_tangent (z w : ℝ) :
    Real.log (1 + Real.exp z) + sigmoid z * (w - z) ≤ Real.log (1 + Real.exp w) := by
  set p := sigmoid z with hpdef
  have hp : p * (1 + Real.exp z) = Real.exp z := by
    rw [hpdef, sigmoid_def, Real.exp_neg]
    have := Real.exp_pos z
    field_simp
    ring
  set t := w - z with htdef
  have h1 := Real.add_one_le_exp (-(p * t))
  have h2 := Real.add_one_le_exp ((1 - p) * t)
  have h2' := mul_le_mul_of_nonneg_left h2 (Real.exp_pos z).le
  have h3 : p * t * (1 + Real.exp z) = Real.exp z * t := by rw [mul_right_comm, hp]
  have hsum : 1 + Real.exp z ≤ Real.exp (-(p * t)) + Real.exp z * Real.exp ((1 - p) * t) := by
    nlinarith
  have hw : Real.exp w = Real.exp z * Real.exp t := by
    rw [← Real.exp_add]; congr 1; rw [htdef]; ring
  have hmul : (1 + Real.exp z) * Real.exp (p * t) ≤ 1 + Real.exp w := by
    calc (1 + Real.exp z) * Real.exp (p * t)
        ≤ (Real.exp (-(p * t)) + Real.exp z * Real.exp ((1 - p) * t)) * Real.exp (p * t) :=
          mul_le_mul_of_nonneg_right hsum (Real.exp_pos _).le
      _ = Real.exp (-(p * t) + p * t) + Real.exp z * Real.exp ((1 - p) * t + p * t) := by
          rw [Real.exp_add, Real.exp_add]; ring
      _ = 1 + Real.exp w := by
          rw [hw]; congr 1
          · simp
          · congr 2; ring
  have hpos : 0 < 1 + Real.exp z := by positivity
  calc Real.log (1 + Real.exp z) + p * t
      = Real.log ((1 + Real.exp z) * Real.exp (p * t)) := by
        rw [Real.log_mul hpos.ne' (Real.exp_pos _).ne', Real.log_exp]
    _ ≤ Real.log (1 + Real.exp w) := Real.log_le_log (by positivity) hmul

/-- Helper: `ln (1 + e^z)` is strictly convex: at the midpoint of two different scores it is
below the average of its values. -/
lemma logistic_aux_mid_lt {z w : ℝ} (h : z ≠ w) :
    2 * Real.log (1 + Real.exp ((z + w) / 2)) <
      Real.log (1 + Real.exp z) + Real.log (1 + Real.exp w) := by
  have ha : Real.exp z = Real.exp (z / 2) ^ 2 := by rw [sq, ← Real.exp_add]; ring_nf
  have hb : Real.exp w = Real.exp (w / 2) ^ 2 := by rw [sq, ← Real.exp_add]; ring_nf
  have hm : Real.exp ((z + w) / 2) = Real.exp (z / 2) * Real.exp (w / 2) := by
    rw [← Real.exp_add]; ring_nf
  have hne : Real.exp (z / 2) - Real.exp (w / 2) ≠ 0 := by
    intro e
    apply h
    have := Real.exp_injective (sub_eq_zero.mp e)
    linarith
  have hsq : 0 < (Real.exp (z / 2) - Real.exp (w / 2)) ^ 2 := by positivity
  rw [← Real.log_mul (by positivity) (by positivity),
    show (2 : ℝ) * Real.log (1 + Real.exp ((z + w) / 2))
      = Real.log ((1 + Real.exp ((z + w) / 2)) ^ 2) by rw [Real.log_pow]; norm_num]
  apply Real.log_lt_log (by positivity)
  rw [ha, hb, hm]
  nlinarith

/-- Helper: the midpoint inequality, allowing equal scores. -/
lemma logistic_aux_mid_le (z w : ℝ) :
    2 * Real.log (1 + Real.exp ((z + w) / 2)) ≤
      Real.log (1 + Real.exp z) + Real.log (1 + Real.exp w) := by
  by_cases h : z = w
  · subst h; ring_nf; rfl
  · exact (logistic_aux_mid_lt h).le

/-- Helper: moving a score in the direction of its outcome strictly raises its term. -/
lemma logistic_aux_term_lt (y z s : ℝ) (hy : y = 0 ∨ y = 1) (hs1 : y = 1 → 0 ≤ s)
    (hs0 : y = 0 → s ≤ 0) (hs : s ≠ 0) :
    y * z - Real.log (1 + Real.exp z) < y * (z + s) - Real.log (1 + Real.exp (z + s)) := by
  rcases hy with h | h
  · have hs' : s < 0 := lt_of_le_of_ne (hs0 h) hs
    subst h
    have : Real.exp (z + s) < Real.exp z := Real.exp_lt_exp.mpr (by linarith)
    have := Real.log_lt_log (by positivity) (show 1 + Real.exp (z + s) < 1 + Real.exp z by linarith)
    linarith
  · have hs' : 0 < s := lt_of_le_of_ne (hs1 h) (Ne.symm hs)
    subst h
    have he : 1 < Real.exp s := by
      have := Real.exp_lt_exp.mpr hs'
      rwa [Real.exp_zero] at this
    have hez := Real.exp_pos z
    have key : 1 + Real.exp (z + s) < Real.exp s * (1 + Real.exp z) := by
      rw [Real.exp_add]; nlinarith
    have := Real.log_lt_log (by positivity) key
    rw [Real.log_mul (Real.exp_pos s).ne' (by positivity), Real.log_exp] at this
    linarith

/-- Helper: the same move never lowers the term. -/
lemma logistic_aux_term_le (y z s : ℝ) (hy : y = 0 ∨ y = 1) (hs1 : y = 1 → 0 ≤ s)
    (hs0 : y = 0 → s ≤ 0) :
    y * z - Real.log (1 + Real.exp z) ≤ y * (z + s) - Real.log (1 + Real.exp (z + s)) := by
  by_cases hs : s = 0
  · subst hs; simp
  · exact (logistic_aux_term_lt y z s hy hs1 hs0 hs).le

/-- Helper: the score is linear in the coefficients. -/
lemma logistic_aux_score_add {n d : ℕ} (x : Fin n → Fin d → ℝ) (b₀ v₀ : ℝ) (b v : Fin d → ℝ)
    (i : Fin n) :
    score x (b₀ + v₀) (b + v) i = score x b₀ b i + (v₀ + ∑ j, v j * x i j) := by
  simp only [score, Pi.add_apply, add_mul, Finset.sum_add_distrib]
  ring

#print axioms logistic_aux_tangent
#print axioms logistic_aux_mid_lt
#print axioms logistic_aux_mid_le
#print axioms logistic_aux_term_lt
#print axioms logistic_aux_term_le
#print axioms logistic_aux_score_add

/-- One peak at most. If every outcome is 0 or 1 and no predictor is an exact combination of
the others and the constant (the only direction that leaves every loan's score unchanged is
zero), then two coefficient sets that both maximise the log-likelihood are the same. -/
theorem logistic_best_fit_unique {n d : ℕ} (x : Fin n → Fin d → ℝ) (y : Fin n → ℝ)
    (hy : ∀ i, y i = 0 ∨ y i = 1)
    (hx : ∀ (v₀ : ℝ) (v : Fin d → ℝ), (∀ i, v₀ + ∑ j, v j * x i j = 0) → v₀ = 0 ∧ v = 0)
    (b₀ c₀ : ℝ) (b c : Fin d → ℝ)
    (hb : ∀ (a₀ : ℝ) (a : Fin d → ℝ), logLik x y a₀ a ≤ logLik x y b₀ b)
    (hc : ∀ (a₀ : ℝ) (a : Fin d → ℝ), logLik x y a₀ a ≤ logLik x y c₀ c) :
    b₀ = c₀ ∧ b = c := by
  have hmid : ∀ i, score x ((b₀ + c₀) / 2) (fun j => (b j + c j) / 2) i
      = (score x b₀ b i + score x c₀ c i) / 2 := by
    intro i
    simp only [score, add_div, add_mul, Finset.sum_add_distrib, div_mul_eq_mul_div,
      ← Finset.sum_div]
    ring
  have heq : ∀ i, score x b₀ b i = score x c₀ c i := by
    by_contra hne
    push Not at hne
    have hlt : logLik x y b₀ b + logLik x y c₀ c
        < 2 * logLik x y ((b₀ + c₀) / 2) (fun j => (b j + c j) / 2) := by
      unfold logLik
      rw [← Finset.sum_add_distrib, Finset.mul_sum]
      apply Finset.sum_lt_sum
      · intro i _
        rw [hmid i]
        have := logistic_aux_mid_le (score x b₀ b i) (score x c₀ c i)
        linarith
      · obtain ⟨i, hi⟩ := hne
        refine ⟨i, Finset.mem_univ _, ?_⟩
        rw [hmid i]
        have := logistic_aux_mid_lt hi
        linarith
    have h1 := hb ((b₀ + c₀) / 2) (fun j => (b j + c j) / 2)
    have h2 := hc ((b₀ + c₀) / 2) (fun j => (b j + c j) / 2)
    linarith
  have hzero : ∀ i, (b₀ - c₀) + ∑ j, (b - c) j * x i j = 0 := by
    intro i
    have := heq i
    simp only [score] at this
    simp only [Pi.sub_apply, sub_mul, Finset.sum_sub_distrib]
    linarith
  obtain ⟨h0, hv⟩ := hx (b₀ - c₀) (b - c) hzero
  exact ⟨sub_eq_zero.mp h0, sub_eq_zero.mp hv⟩

/-- Zero slopes mean the top. If coefficients solve the likelihood equations (observed minus
predicted, `y i - Λ (z i)`, adds to zero overall and again when weighted by each predictor),
then no other coefficients give a larger log-likelihood. -/
theorem logistic_likelihood_equations_give_max {n d : ℕ} (x : Fin n → Fin d → ℝ)
    (y : Fin n → ℝ) (hy : ∀ i, y i = 0 ∨ y i = 1) (b₀ : ℝ) (b : Fin d → ℝ)
    (h0 : ∑ i, (y i - sigmoid (score x b₀ b i)) = 0)
    (hj : ∀ j, ∑ i, x i j * (y i - sigmoid (score x b₀ b i)) = 0) :
    ∀ (a₀ : ℝ) (a : Fin d → ℝ), logLik x y a₀ a ≤ logLik x y b₀ b := by
  intro a₀ a
  have hdiff : ∀ i, score x a₀ a i - score x b₀ b i = (a₀ - b₀) + ∑ j, (a j - b j) * x i j := by
    intro i
    simp only [score, sub_mul, Finset.sum_sub_distrib]
    ring
  have hkey : ∑ i, (y i - sigmoid (score x b₀ b i)) * (score x a₀ a i - score x b₀ b i) = 0 := by
    simp_rw [hdiff, mul_add, Finset.mul_sum]
    rw [Finset.sum_add_distrib, Finset.sum_comm]
    have e1 : ∑ i, (y i - sigmoid (score x b₀ b i)) * (a₀ - b₀) = 0 := by
      rw [← Finset.sum_mul, h0, zero_mul]
    have e2 : ∀ j, ∑ i, (y i - sigmoid (score x b₀ b i)) * ((a j - b j) * x i j) = 0 := by
      intro j
      have : ∑ i, (y i - sigmoid (score x b₀ b i)) * ((a j - b j) * x i j)
          = (a j - b j) * ∑ i, x i j * (y i - sigmoid (score x b₀ b i)) := by
        rw [Finset.mul_sum]
        refine Finset.sum_congr rfl fun i _ => ?_
        ring
      rw [this, hj j, mul_zero]
    rw [e1, Finset.sum_congr rfl fun j _ => e2 j]
    simp
  have hle : logLik x y a₀ a ≤ logLik x y b₀ b
      + ∑ i, (y i - sigmoid (score x b₀ b i)) * (score x a₀ a i - score x b₀ b i) := by
    unfold logLik
    rw [← Finset.sum_add_distrib]
    apply Finset.sum_le_sum
    intro i _
    have := logistic_aux_tangent (score x b₀ b i) (score x a₀ a i)
    nlinarith
  linarith

/-- Separation leaves no best fit. If some straight line in the predictors splits the defaults
from the repayments (a direction `v₀, v` whose score change `s i = v₀ + ∑ j, v j * x i j` is at
least 0 on every defaulted loan and at most 0 on every repaid one, with some loans allowed to lie
on the line but not all), then no coefficients maximise the log-likelihood. -/
theorem logistic_no_best_fit_under_separation {n d : ℕ} (x : Fin n → Fin d → ℝ)
    (y : Fin n → ℝ) (hy : ∀ i, y i = 0 ∨ y i = 1) (v₀ : ℝ) (v : Fin d → ℝ)
    (hpos : ∀ i, y i = 1 → 0 ≤ v₀ + ∑ j, v j * x i j)
    (hneg : ∀ i, y i = 0 → v₀ + ∑ j, v j * x i j ≤ 0)
    (hoff : ∃ i, v₀ + ∑ j, v j * x i j ≠ 0) :
    ¬ ∃ (b₀ : ℝ) (b : Fin d → ℝ), ∀ (a₀ : ℝ) (a : Fin d → ℝ), logLik x y a₀ a ≤ logLik x y b₀ b := by
  rintro ⟨b₀, b, h⟩
  have hge := h (b₀ + v₀) (b + v)
  have hlt : logLik x y b₀ b < logLik x y (b₀ + v₀) (b + v) := by
    unfold logLik
    simp_rw [logistic_aux_score_add]
    apply Finset.sum_lt_sum
    · intro i _
      exact logistic_aux_term_le _ _ _ (hy i) (hpos i) (hneg i)
    · obtain ⟨i, hi⟩ := hoff
      exact ⟨i, Finset.mem_univ _, logistic_aux_term_lt _ _ _ (hy i) (hpos i) (hneg i) hi⟩
  linarith

/-! The card's whole-number worked examples. -/

-- 103 of the 500 loans defaulted: a share of 0.2060.
example : (103 : ℚ) / 500 = 2060 / 10000 := by norm_num

-- Of the 297 loans with debt ratio under 40%, 27 defaulted: odds 27 / 270 = 1/10, i.e. 0.1000.
example : 297 - 27 = 270 ∧ (27 : ℚ) / (297 - 27) = 1 / 10 := by norm_num

-- The separated book of eight loans: debt ratios 20, 25, 30, 35 repaid, 45, 50, 55, 60 defaulted.
-- The score change `debt ratio - 40` is negative on every repaid loan and positive on every
-- defaulted one, so the book meets the hypotheses of `logistic_no_best_fit_under_separation`.
example :
    let debt : Fin 8 → ℝ := ![20, 25, 30, 35, 45, 50, 55, 60]
    let y : Fin 8 → ℝ := ![0, 0, 0, 0, 1, 1, 1, 1]
    (∀ i, y i = 0 ∨ y i = 1) ∧
      (∀ i, y i = 1 → 0 < -40 + debt i) ∧ (∀ i, y i = 0 → -40 + debt i < 0) := by
  intro debt y
  refine ⟨?_, ?_, ?_⟩ <;> intro i <;> fin_cases i <;> norm_num [debt, y]

#print axioms logistic_best_fit_unique
#print axioms logistic_likelihood_equations_give_max
#print axioms logistic_no_best_fit_under_separation
