-- KL divergence: for finite tables of chances, the divergence is the cross-entropy minus the entropy, it is never negative and is zero only when the two tables agree (Gibbs' inequality), a model has higher likelihood on a log of readings exactly when it has smaller divergence from the log's own table, and the card's London and Lisbon numbers are exact.
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Fintype.Card
import Mathlib.Tactic.NormNum

namespace KLDivergenceCard

open Real

/-- The entropy in bits of a table `p` of chances: H(p) = Σ p(x) log2(1/p(x)). A reading of
chance 0 adds nothing, since Lean's 1/0 is 0 and log2 0 is 0. -/
noncomputable def entropy {α : Type*} [Fintype α] (p : α → ℝ) : ℝ :=
  ∑ x, p x * logb 2 (1 / p x)

/-- The cross-entropy in bits: the average codeword length H(p, q) = Σ p(x) log2(1/q(x)) of a
code built for the table `q` when the readings follow the table `p`. -/
noncomputable def crossEntropy {α : Type*} [Fintype α] (p q : α → ℝ) : ℝ :=
  ∑ x, p x * logb 2 (1 / q x)

/-- The Kullback-Leibler divergence in bits: D(p‖q) = Σ p(x) log2(p(x)/q(x)). -/
noncomputable def klDiv {α : Type*} [Fintype α] (p q : α → ℝ) : ℝ :=
  ∑ x, p x * logb 2 (p x / q x)

/-- The year's own table p̂ from a log of `n` readings: p̂(x) is the number of days that read
`x`, divided by `n`. -/
noncomputable def empirical {α : Type*} [Fintype α] [DecidableEq α] {n : ℕ} (days : Fin n → α)
    (x : α) : ℝ :=
  ((Finset.univ.filter (fun i => days i = x)).card : ℝ) / n

/-- Each term of the divergence is at least `p x - q x` (natural log). -/
theorem term_ge {a b : ℝ} (ha : 0 ≤ a) (hb : 0 ≤ b) (hab : 0 < a → 0 < b) :
    a - b ≤ a * Real.log (a / b) := by
  rcases ha.eq_or_lt with h | h
  · subst h; simp [hb]
  · have hb' := hab h
    have h1 := Real.log_le_sub_one_of_pos (div_pos hb' h)
    have h2 : Real.log (a / b) = - Real.log (b / a) := by
      rw [← Real.log_inv, inv_div]
    rw [h2]
    have h3 : a * (b / a - 1) = b - a := by field_simp
    nlinarith [mul_le_mul_of_nonneg_left h1 ha]

/-- Equality in `term_ge` forces `a = b`. -/
theorem term_eq {a b : ℝ} (ha : 0 ≤ a) (hb : 0 ≤ b) (hab : 0 < a → 0 < b)
    (heq : a * Real.log (a / b) = a - b) : a = b := by
  rcases ha.eq_or_lt with h | h
  · subst h; simp at heq; linarith
  · have hb' := hab h
    by_contra hne
    have hne' : b / a ≠ 1 := by
      intro h1; rw [div_eq_one_iff_eq h.ne'] at h1; exact hne h1.symm
    have h1 := Real.log_lt_sub_one_of_pos (div_pos hb' h) hne'
    have h2 : Real.log (a / b) = - Real.log (b / a) := by
      rw [← Real.log_inv, inv_div]
    rw [h2] at heq
    have h3 : a * (b / a - 1) = b - a := by field_simp
    nlinarith [mul_lt_mul_of_pos_left h1 h]

/-- The divergence in natural-log units, times `log 2`. -/
theorem klDiv_eq_div {α : Type*} [Fintype α] (p q : α → ℝ) :
    klDiv p q = (∑ x, p x * Real.log (p x / q x)) / Real.log 2 := by
  unfold klDiv
  rw [Finset.sum_div]
  refine Finset.sum_congr rfl fun x _ => ?_
  rw [Real.logb, mul_div_assoc]

/-- Per-term split of the divergence. -/
theorem term_split {a b : ℝ} (ha : 0 ≤ a) (hab : 0 < a → 0 < b) :
    a * logb 2 (a / b) = a * logb 2 (1 / b) - a * logb 2 (1 / a) := by
  rcases ha.eq_or_lt with h | h
  · subst h; simp
  · have hb := hab h
    rw [Real.logb_div h.ne' hb.ne', one_div, one_div, Real.logb_inv, Real.logb_inv]
    ring

/-- log2 8 = 3. -/
theorem logb_two_eight : logb 2 (8 : ℝ) = 3 := by
  rw [show (8 : ℝ) = 2 ^ 3 by norm_num, Real.logb_pow]; simp

/-- log2 4 = 2. -/
theorem logb_two_four : logb 2 (4 : ℝ) = 2 := by
  rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.logb_pow]; simp

/-- log2 (1/4) = -2. -/
theorem logb_two_quarter : logb 2 (1 / 4 : ℝ) = -2 := by
  rw [one_div, Real.logb_inv, logb_two_four]

/-- log2 (1/2) = -1. -/
theorem logb_two_half : logb 2 (1 / 2 : ℝ) = -1 := by
  rw [one_div, Real.logb_inv, Real.logb_self_eq_one (by norm_num : (1 : ℝ) < 2)]

/-- The likelihood identity for one model. -/
theorem likelihood_eq {α : Type*} [Fintype α] [DecidableEq α] {n : ℕ}
    (days : Fin n → α) (q : α → ℝ) (hqpos : ∀ i, 0 < q (days i)) :
    -(1 / (n : ℝ)) * logb 2 (∏ i, q (days i)) =
        entropy (empirical days) + klDiv (empirical days) q := by
  have hsplit : klDiv (empirical days) q =
      crossEntropy (empirical days) q - entropy (empirical days) := by
    unfold klDiv crossEntropy entropy
    rw [← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun x _ => ?_
    apply term_split
    · unfold empirical; positivity
    · intro hx
      unfold empirical at hx
      have hc : 0 < (Finset.univ.filter (fun i => days i = x)).card := by
        by_contra h0
        have : (Finset.univ.filter (fun i => days i = x)).card = 0 := by omega
        rw [this] at hx; simp at hx
      obtain ⟨i, hi⟩ := Finset.card_pos.mp hc
      rw [Finset.mem_filter] at hi
      rw [← hi.2]; exact hqpos i
  rw [hsplit, add_sub_cancel]
  unfold crossEntropy empirical
  rw [Real.logb_prod _ _ (fun i _ => (hqpos i).ne'),
    ← Finset.sum_fiberwise' Finset.univ days (fun x => logb 2 (q x))]
  rw [Finset.mul_sum]
  refine Finset.sum_congr rfl fun x _ => ?_
  rw [Finset.sum_const, nsmul_eq_mul]
  simp only [one_div, Real.logb_inv]
  ring

/-- **Gibbs' inequality: the waste is never negative, and zero only when the tables agree.**
Let `p` and `q` be tables of chances on the same finite set of readings: every chance at least
0, each table adding to 1, and `q` giving a chance above zero to every reading that `p` can
send. Then D(p‖q) ≥ 0, and D(p‖q) = 0 exactly when `q = p`. -/
theorem kl_divergence_nonneg_and_eq_zero_iff {α : Type*} [Fintype α] (p q : α → ℝ)
    (hp : ∀ x, 0 ≤ p x) (hp1 : ∑ x, p x = 1)
    (hq : ∀ x, 0 ≤ q x) (hq1 : ∑ x, q x = 1)
    (hpos : ∀ x, 0 < p x → 0 < q x) :
    0 ≤ klDiv p q ∧ (klDiv p q = 0 ↔ p = q) := by
  have hterm : ∀ x, 0 ≤ p x * Real.log (p x / q x) - (p x - q x) := fun x =>
    sub_nonneg.mpr (term_ge (hp x) (hq x) (hpos x))
  have hsum : ∑ x, p x * Real.log (p x / q x) =
      ∑ x, (p x * Real.log (p x / q x) - (p x - q x)) := by
    rw [Finset.sum_sub_distrib, Finset.sum_sub_distrib, hp1, hq1]; ring
  have hlog2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have hnn : 0 ≤ ∑ x, (p x * Real.log (p x / q x) - (p x - q x)) :=
    Finset.sum_nonneg fun x _ => hterm x
  refine ⟨?_, ?_⟩
  · rw [klDiv_eq_div, hsum]; exact div_nonneg hnn hlog2.le
  · constructor
    · intro h
      rw [klDiv_eq_div, hsum, div_eq_zero_iff] at h
      rcases h with h | h
      · funext x
        have := (Finset.sum_eq_zero_iff_of_nonneg (fun x _ => hterm x)).mp h x (Finset.mem_univ x)
        exact term_eq (hp x) (hq x) (hpos x) (by linarith)
      · linarith
    · intro h
      subst h
      unfold klDiv
      refine Finset.sum_eq_zero fun x _ => ?_
      by_cases hx : p x = 0
      · simp [hx]
      · simp [div_self hx]

/-- **The divergence is the extra bill.** For tables `p` and `q` as above, the bits per reading
of `q`'s code on `p`'s readings, H(p, q), is the best bill H(p) plus the waste:
D(p‖q) = H(p, q) - H(p). So no code beats the entropy: H(p) ≤ H(p, q). -/
theorem kl_divergence_eq_cross_entropy_sub_entropy {α : Type*} [Fintype α] (p q : α → ℝ)
    (hp : ∀ x, 0 ≤ p x) (hp1 : ∑ x, p x = 1)
    (hq : ∀ x, 0 ≤ q x) (hq1 : ∑ x, q x = 1)
    (hpos : ∀ x, 0 < p x → 0 < q x) :
    klDiv p q = crossEntropy p q - entropy p ∧ entropy p ≤ crossEntropy p q := by
  have hsplit : klDiv p q = crossEntropy p q - entropy p := by
    unfold klDiv crossEntropy entropy
    rw [← Finset.sum_sub_distrib]
    exact Finset.sum_congr rfl fun x _ => term_split (hp x) (hpos x)
  refine ⟨hsplit, ?_⟩
  have := (kl_divergence_nonneg_and_eq_zero_iff p q hp hp1 hq hq1 hpos).1
  linarith

/-- **Maximum likelihood is divergence minimisation.** Take a log of `n` readings and its own
table p̂. Minus log2 of a model's likelihood (the product of the model's chances over the days),
divided by `n`, is H(p̂, q) = H(p̂) + D(p̂‖q). So for any two model tables `q₁` and `q₂` that give
every reading in the log a chance above zero, `q₁` has at least the likelihood of `q₂` exactly
when D(p̂‖q₁) ≤ D(p̂‖q₂): the likeliest model is the one with the smallest divergence. -/
theorem max_likelihood_iff_min_kl_divergence {α : Type*} [Fintype α] [DecidableEq α] {n : ℕ}
    (days : Fin n → α) (q q₁ q₂ : α → ℝ)
    (hq : ∀ x, 0 ≤ q x) (hq1 : ∑ x, q x = 1) (hqpos : ∀ i, 0 < q (days i))
    (hq₁ : ∀ x, 0 ≤ q₁ x) (hq₁1 : ∑ x, q₁ x = 1) (hq₁pos : ∀ i, 0 < q₁ (days i))
    (hq₂ : ∀ x, 0 ≤ q₂ x) (hq₂1 : ∑ x, q₂ x = 1) (hq₂pos : ∀ i, 0 < q₂ (days i)) :
    -(1 / (n : ℝ)) * logb 2 (∏ i, q (days i)) =
        entropy (empirical days) + klDiv (empirical days) q ∧
      (∏ i, q₂ (days i) ≤ ∏ i, q₁ (days i) ↔
        klDiv (empirical days) q₁ ≤ klDiv (empirical days) q₂) := by
  refine ⟨likelihood_eq days q hqpos, ?_⟩
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn
    have h0 : ∀ r : α → ℝ, klDiv (empirical days) r = 0 := by
      intro r; unfold klDiv empirical; simp
    simp [h0]
  · have e1 := likelihood_eq days q₁ hq₁pos
    have e2 := likelihood_eq days q₂ hq₂pos
    have p1 : 0 < ∏ i, q₁ (days i) := Finset.prod_pos fun i _ => hq₁pos i
    have p2 : 0 < ∏ i, q₂ (days i) := Finset.prod_pos fun i _ => hq₂pos i
    have hn' : (0:ℝ) < 1 / (n:ℝ) := by positivity
    rw [← Real.logb_le_logb (by norm_num : (1:ℝ) < 2) p2 p1]
    constructor
    · intro h; nlinarith [mul_le_mul_of_nonneg_left h hn'.le]
    · intro h
      have : (1 / (n:ℝ)) * logb 2 (∏ i, q₂ (days i)) ≤
          (1 / (n:ℝ)) * logb 2 (∏ i, q₁ (days i)) := by linarith
      exact le_of_mul_le_mul_left this hn'

-- London's sky (sunny, cloudy, drizzle, rain) and Lisbon's.
-- London's own code: H(p) = 7/4 bits a day.
example : entropy ![(1 / 8 : ℝ), 1 / 2, 1 / 4, 1 / 8] = 7 / 4 := by
  simp only [entropy, crossEntropy, klDiv, Fin.sum_univ_four, Matrix.cons_val_zero,
    Matrix.cons_val_one, Matrix.cons_val_two, Matrix.cons_val_three, Matrix.head_cons]
  norm_num [logb_two_eight, logb_two_four, logb_two_quarter, logb_two_half]
-- Lisbon's code on London's sky: H(p, q) = 9/4 bits a day.
example : crossEntropy ![(1 / 8 : ℝ), 1 / 2, 1 / 4, 1 / 8] ![1 / 2, 1 / 4, 1 / 8, 1 / 8] = 9 / 4 := by
  simp only [entropy, crossEntropy, klDiv, Fin.sum_univ_four, Matrix.cons_val_zero,
    Matrix.cons_val_one, Matrix.cons_val_two, Matrix.cons_val_three, Matrix.head_cons]
  norm_num [logb_two_eight, logb_two_four, logb_two_quarter, logb_two_half]
-- The waste: D(p‖q) = 1/2 bit a day.
example : klDiv ![(1 / 8 : ℝ), 1 / 2, 1 / 4, 1 / 8] ![1 / 2, 1 / 4, 1 / 8, 1 / 8] = 1 / 2 := by
  simp only [entropy, crossEntropy, klDiv, Fin.sum_univ_four, Matrix.cons_val_zero,
    Matrix.cons_val_one, Matrix.cons_val_two, Matrix.cons_val_three, Matrix.head_cons]
  norm_num [logb_two_eight, logb_two_four, logb_two_quarter, logb_two_half]
-- Swap the arguments: D(q‖p) = 5/8 bit, not 1/2.
example : klDiv ![(1 / 2 : ℝ), 1 / 4, 1 / 8, 1 / 8] ![1 / 8, 1 / 2, 1 / 4, 1 / 8] = 5 / 8 := by
  simp only [entropy, crossEntropy, klDiv, Fin.sum_univ_four, Matrix.cons_val_zero,
    Matrix.cons_val_one, Matrix.cons_val_two, Matrix.cons_val_three, Matrix.head_cons]
  norm_num [logb_two_eight, logb_two_four, logb_two_quarter, logb_two_half]
-- Drop the weights: log2(1/4) + log2 2 + log2 2 + log2 1 = 0.
example : ∑ x, logb 2 (![(1 / 8 : ℝ), 1 / 2, 1 / 4, 1 / 8] x / ![1 / 2, 1 / 4, 1 / 8, 1 / 8] x) = 0 := by
  simp only [entropy, crossEntropy, klDiv, Fin.sum_univ_four, Matrix.cons_val_zero,
    Matrix.cons_val_one, Matrix.cons_val_two, Matrix.cons_val_three, Matrix.head_cons]
  norm_num [logb_two_eight, logb_two_four, logb_two_quarter, logb_two_half]
-- Lisbon lengths 1, 2, 3, 3 and London lengths 3, 1, 2, 3: both Kraft sums are exactly 1.
example : (1 / 2 : ℚ) + 1 / 4 + 1 / 8 + 1 / 8 = 1 ∧ (1 / 8 : ℚ) + 1 / 2 + 1 / 4 + 1 / 8 = 1 := by
  norm_num
-- The bills by hand: 1/8 × 3 + 1/2 × 1 + 1/4 × 2 + 1/8 × 3 = 7/4 and
-- 1/8 × 1 + 1/2 × 2 + 1/4 × 3 + 1/8 × 3 = 9/4, and 9/4 - 7/4 = 1/2.
example : (1 / 8 : ℚ) * 3 + 1 / 2 * 1 + 1 / 4 * 2 + 1 / 8 * 3 = 7 / 4 ∧
    (1 / 8 : ℚ) * 1 + 1 / 2 * 2 + 1 / 4 * 3 + 1 / 8 * 3 = 9 / 4 ∧ (9 / 4 : ℚ) - 7 / 4 = 1 / 2 := by
  norm_num
-- A year of waste: 365 × 1/2 = 365/2 bits (182.5).
example : (365 : ℚ) * (1 / 2) = 365 / 2 := by norm_num
-- Pinsker's example: the largest difference in chance, half the sum of |p - q|, is 3/8.
example : (1 / 2 : ℚ) * (|1 / 8 - 1 / 2| + |1 / 2 - 1 / 4| + |1 / 4 - 1 / 8| + |1 / 8 - 1 / 8|)
    = 3 / 8 := by norm_num [abs_of_nonneg, abs_of_nonpos]
-- The year's counts 49, 184, 86, 46 add to 365 days, with total wetness
-- 0 × 49 + 1 × 184 + 2 × 86 + 3 × 46 = 494.
example : 49 + 184 + 86 + 46 = 365 ∧ 0 * 49 + 1 * 184 + 2 * 86 + 3 * 46 = 494 := by decide

#print axioms term_ge
#print axioms term_eq
#print axioms klDiv_eq_div
#print axioms term_split
#print axioms logb_two_eight
#print axioms logb_two_four
#print axioms logb_two_quarter
#print axioms logb_two_half
#print axioms likelihood_eq
#print axioms kl_divergence_nonneg_and_eq_zero_iff
#print axioms kl_divergence_eq_cross_entropy_sub_entropy
#print axioms max_likelihood_iff_min_kl_divergence

end KLDivergenceCard
