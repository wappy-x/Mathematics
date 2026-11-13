-- Independence: the product rule for two events matches "learning B leaves the chance of A unchanged", it carries over to complements, equal group mixes cannot reverse a pooled comparison, and the card's coin counts check out.
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.ConditionalProbability
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

open MeasureTheory ProbabilityTheory

/-- Two events A and B are independent (the chance that both happen equals the product of
their chances) exactly when learning that B happened leaves the chance of A where it was,
provided B has a chance above zero. -/
theorem indepSet_iff_cond_eq {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] {A B : Set Ω} (hA : MeasurableSet A) (hB : MeasurableSet B)
    (hB0 : μ B ≠ 0) :
    IndepSet A B μ ↔ μ[A | B] = μ A := by
  rw [indepSet_iff_measure_inter_eq_mul hA hB μ, cond_apply hB μ A, Set.inter_comm B A]
  have hBt : μ B ≠ ⊤ := measure_ne_top μ B
  constructor
  · intro h
    rw [h, mul_comm, mul_assoc, ENNReal.mul_inv_cancel hB0 hBt, mul_one]
  · intro h
    rw [← h, mul_comm _ (μ (A ∩ B)), mul_assoc, ENNReal.inv_mul_cancel hB0 hBt, mul_one]

/-- Complements come for free: if A and B are independent, so are A and "not B". -/
theorem indepSet_compl_right {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] {A B : Set Ω} (hA : MeasurableSet A) (hB : MeasurableSet B)
    (h : IndepSet A B μ) :
    IndepSet A Bᶜ μ := by
  rw [indepSet_iff_measure_inter_eq_mul hA hB μ] at h
  rw [indepSet_iff_measure_inter_eq_mul hA hB.compl μ, prob_compl_eq_one_sub hB]
  have hsum := measure_inter_add_sdiff A hB (μ := μ)
  rw [h] at hsum
  rw [← Set.sdiff_eq, ENNReal.mul_sub (fun _ _ => measure_ne_top μ A), mul_one]
  exact ENNReal.eq_sub_of_add_eq (ENNReal.mul_ne_top (measure_ne_top μ A) (measure_ne_top μ B))
    (by rw [add_comm]; exact hsum)

/-- No Simpson reversal under independence: if both mints have the same quarter share w
(coin type independent of mint) and X beats Y on quarters and on dimes, then X beats Y
on the pooled rate. -/
theorem pooled_rate_no_reversal_of_equal_mix (w xQ xD yQ yD : ℝ)
    (hw0 : 0 ≤ w) (hw1 : w ≤ 1) (hQ : yQ < xQ) (hD : yD < xD) :
    w * yQ + (1 - w) * yD < w * xQ + (1 - w) * xD := by
  have h1 : w * yQ ≤ w * xQ := mul_le_mul_of_nonneg_left hQ.le hw0
  have h2 : (1 - w) * yD ≤ (1 - w) * xD := mul_le_mul_of_nonneg_left hD.le (by linarith)
  rcases eq_or_lt_of_le hw0 with h | h
  · subst h; nlinarith
  · nlinarith [mul_lt_mul_of_pos_left hQ h]

/-! ### The card's worked examples, as exact counts over the four coin outcomes
An outcome is (quarter heads?, dime heads?); each of the 4 outcomes is equally likely,
so "P(E) = P(F) P(G)" becomes "4 · #(E) = #(F) · #(G)" after clearing denominators. -/

-- Quarter heads and dime heads: both heads is 1 outcome of 4, and 1/4 = 2/4 · 2/4.
example :
    let A := (Finset.univ : Finset (Bool × Bool)).filter (fun o => o.1 = true)
    let B := (Finset.univ : Finset (Bool × Bool)).filter (fun o => o.2 = true)
    A.card = 2 ∧ B.card = 2 ∧ (A ∩ B).card = 1 ∧ 4 * (A ∩ B).card = A.card * B.card := by
  decide

-- Quarter heads with dime tails: joint 1/4 equals 2/4 · 2/4.
example :
    let A := (Finset.univ : Finset (Bool × Bool)).filter (fun o => o.1 = true)
    let Bc := (Finset.univ : Finset (Bool × Bool)).filter (fun o => o.2 = false)
    4 * (A ∩ Bc).card = A.card * Bc.card := by
  decide

-- The quarter with itself: joint 2/4, product 1/4. With "quarter tails": joint 0, product 1/4.
example :
    let A := (Finset.univ : Finset (Bool × Bool)).filter (fun o => o.1 = true)
    let Ac := (Finset.univ : Finset (Bool × Bool)).filter (fun o => o.1 = false)
    4 * (A ∩ A).card ≠ A.card * A.card ∧ (A ∩ Ac).card = 0 ∧ 4 * (A ∩ Ac).card ≠ A.card * Ac.card := by
  decide

-- The match event C: every pair passes, the triple fails (1/4 against 1/8).
example :
    let A := (Finset.univ : Finset (Bool × Bool)).filter (fun o => o.1 = true)
    let B := (Finset.univ : Finset (Bool × Bool)).filter (fun o => o.2 = true)
    let C := (Finset.univ : Finset (Bool × Bool)).filter (fun o => o.1 = o.2)
    C.card = 2 ∧
    4 * (A ∩ B).card = A.card * B.card ∧ 4 * (A ∩ C).card = A.card * C.card ∧
    4 * (B ∩ C).card = B.card * C.card ∧
    (A ∩ B ∩ C).card = 1 ∧ 4 * 4 * (A ∩ B ∩ C).card ≠ A.card * B.card * C.card := by
  decide

-- Three separate coins pass all 4 equations (8 equally likely outcomes).
example :
    let A := (Finset.univ : Finset (Bool × Bool × Bool)).filter (fun o => o.1 = true)
    let B := (Finset.univ : Finset (Bool × Bool × Bool)).filter (fun o => o.2.1 = true)
    let C := (Finset.univ : Finset (Bool × Bool × Bool)).filter (fun o => o.2.2 = true)
    8 * (A ∩ B).card = A.card * B.card ∧ 8 * (A ∩ C).card = A.card * C.card ∧
    8 * (B ∩ C).card = B.card * C.card ∧
    8 * 8 * (A ∩ B ∩ C).card = A.card * B.card * C.card := by
  decide

-- For k = 3 events, mutual independence is 2^3 - 3 - 1 = 4 equations.
example : 2 ^ 3 - 3 - 1 = 4 := by norm_num

-- Given M = "at least one head": P(A | M) = 2/3, P(B | M) = 2/3, P(A and B | M) = 1/3 ≠ 4/9.
example :
    let A := (Finset.univ : Finset (Bool × Bool)).filter (fun o => o.1 = true)
    let B := (Finset.univ : Finset (Bool × Bool)).filter (fun o => o.2 = true)
    let M := (Finset.univ : Finset (Bool × Bool)).filter (fun o => o.1 = true ∨ o.2 = true)
    M.card = 3 ∧ (A ∩ M).card = 2 ∧ (B ∩ M).card = 2 ∧ (A ∩ B ∩ M).card = 1 ∧
    M.card * (A ∩ B ∩ M).card ≠ (A ∩ M).card * (B ∩ M).card := by
  decide

-- The bag coin, in exact fractions: P(H1) = 7/10, P(H1 and H2) = 53/100, product 49/100.
example : (1/2 : ℚ) * (1/2) + (1/2) * (9/10) = 7/10 := by norm_num
example : (1/2 : ℚ) * (1/2 * 1/2) + (1/2) * (9/10 * 9/10) = 53/100 := by norm_num
example : (7/10 : ℚ) * (7/10) = 49/100 ∧ (49/100 : ℚ) ≠ 53/100 := by norm_num

-- The mints: X wins on quarters (90/100 > 340/400) and dimes (250/400 > 60/100),
-- yet loses overall (340/500 < 400/500); quarter shares 100/500 and 400/500.
example : (340/400 : ℚ) < 90/100 ∧ (60/100 : ℚ) < 250/400 ∧ (340/500 : ℚ) < 400/500 := by
  norm_num
example : (90 + 250 : ℕ) = 340 ∧ (340 + 60 : ℕ) = 400 ∧ (100 + 400 : ℕ) = 500 := by norm_num
-- Pooled gap -3/25 = within types 3/100 plus mix -3/20; equal half-and-half mix: X 61/80 > Y 29/40.
example : (1/5 : ℚ) * (9/10 - 17/20) + (4/5) * (5/8 - 3/5) = 3/100 ∧
    ((1/5 : ℚ) - 4/5) * (17/20 - 3/5) = -3/20 ∧ (17/25 : ℚ) - 4/5 = 3/100 + (-3/20) := by
  norm_num
example : ((9/10 : ℚ) + 5/8) / 2 = 61/80 ∧ ((17/20 : ℚ) + 3/5) / 2 = 29/40 ∧
    (29/40 : ℚ) < 61/80 := by
  norm_num

-- Squaring one in 8,543: one in 72,982,849.
example : 8543 ^ 2 = 72982849 := by norm_num

#print axioms indepSet_iff_cond_eq
#print axioms indepSet_compl_right
#print axioms pooled_rate_no_reversal_of_equal_mix
