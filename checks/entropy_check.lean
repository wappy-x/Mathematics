-- Entropy: the entropy of any finite list of chances is at most log2 of the number of outcomes, with equality exactly when all chances are equal, one yes-or-no answer carries at most 1 bit, surprises add when chances multiply, and the card's weather numbers are exact.
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.SpecialFunctions.BinaryEntropy
import Mathlib.Analysis.SpecialFunctions.Log.NegMulLog
import Mathlib.Analysis.Convex.Jensen
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum

namespace EntropyCard

open Real

/-- The entropy in bits of a list of chances `p₁, …, pₙ`: H = Σ pᵢ log2(1/pᵢ). An outcome of
chance 0 adds nothing, since Lean's 1/0 is 0 and log2 0 is 0, so its term is 0. -/
noncomputable def entropy {n : ℕ} (p : Fin n → ℝ) : ℝ :=
  ∑ i, p i * logb 2 (1 / p i)

/-- The binary entropy in bits of one yes-or-no answer with chance `p` of yes:
h(p) = p log2(1/p) + (1 - p) log2(1/(1 - p)). -/
noncomputable def binEntropyBits (p : ℝ) : ℝ :=
  p * logb 2 (1 / p) + (1 - p) * logb 2 (1 / (1 - p))

/-- Helper: entropy in bits is the sum of `negMulLog` (natural-log entropy terms) over log 2. -/
lemma entropy_eq_sum_negMulLog {n : ℕ} (p : Fin n → ℝ) :
    entropy p = (∑ i, negMulLog (p i)) / log 2 := by
  unfold entropy
  rw [Finset.sum_div]
  refine Finset.sum_congr rfl fun i _ => ?_
  simp only [negMulLog, logb, one_div, Real.log_inv]
  ring

/-- Helper: binary entropy in bits is Mathlib's `binEntropy` (in nats) over log 2. -/
lemma binEntropyBits_eq (p : ℝ) : binEntropyBits p = binEntropy p / log 2 := by
  unfold binEntropyBits binEntropy
  simp only [logb, one_div]
  ring

/-- Helper: log2 4 = 2. -/
lemma logb_two_four : logb 2 (4 : ℝ) = 2 := by
  rw [show (4:ℝ) = 2 ^ (2:ℕ) by norm_num, logb_pow, logb_self_eq_one (by norm_num)]; norm_num

/-- Helper: log2 8 = 3. -/
lemma logb_two_eight : logb 2 (8 : ℝ) = 3 := by
  rw [show (8:ℝ) = 2 ^ (3:ℕ) by norm_num, logb_pow, logb_self_eq_one (by norm_num)]; norm_num

#print axioms entropy_eq_sum_negMulLog
#print axioms binEntropyBits_eq
#print axioms logb_two_four
#print axioms logb_two_eight

/-- **Equal chances give the most entropy.** Take any finite list of n outcomes with chances
p₁, …, pₙ, each at least 0 and adding to 1. Then the entropy is at most log2 n, and it equals
log2 n exactly when every chance is 1/n. -/
theorem entropy_le_log_two_card_eq_iff_uniform {n : ℕ} (p : Fin n → ℝ)
    (hp : ∀ i, 0 ≤ p i) (hsum : ∑ i, p i = 1) :
    entropy p ≤ logb 2 n ∧ (entropy p = logb 2 n ↔ ∀ i, p i = 1 / n) := by
  rcases Nat.eq_zero_or_pos n with rfl | hn0
  · simp at hsum
  have hn : (0 : ℝ) < n := by exact_mod_cast hn0
  have hl2 : 0 < log 2 := log_pos (by norm_num)
  set S := ∑ i, negMulLog (p i) with hS
  have hw0 : ∀ i ∈ (Finset.univ : Finset (Fin n)), (0 : ℝ) < (fun _ => 1 / (n : ℝ)) i :=
    fun _ _ => by positivity
  have hw1 : ∑ i ∈ (Finset.univ : Finset (Fin n)), (fun _ => 1 / (n : ℝ)) i = 1 := by
    simp [Finset.card_univ, Fintype.card_fin]
    field_simp
  have hmem : ∀ i ∈ (Finset.univ : Finset (Fin n)), p i ∈ Set.Ici (0 : ℝ) := fun i _ => hp i
  have hcm : ∑ i, (1 / (n : ℝ)) • p i = 1 / n := by
    simp only [smul_eq_mul, ← Finset.mul_sum, hsum, mul_one]
  have hfcm : negMulLog (1 / (n : ℝ)) = (1 / n) * log n := by
    simp only [negMulLog, one_div, Real.log_inv]; ring
  have hLHS : ∑ i, (1 / (n : ℝ)) • negMulLog (p i) = (1 / n) * S := by
    simp only [smul_eq_mul, ← Finset.mul_sum, hS]
  have hJ := strictConcaveOn_negMulLog.concaveOn.le_map_sum (fun i hi => (hw0 i hi).le) hw1 hmem
  have hE := strictConcaveOn_negMulLog.map_sum_eq_iff hw0 hw1 hmem
  simp only [hcm, hfcm, hLHS] at hJ hE
  have hSle : S ≤ log n := by
    have := mul_le_mul_of_nonneg_left hJ hn.le
    field_simp at this
    linarith
  rw [entropy_eq_sum_negMulLog, ← hS]
  refine ⟨div_le_div_of_nonneg_right hSle hl2.le, ?_⟩
  rw [logb, div_left_inj' hl2.ne']
  have : S = log n ↔ 1 / (n : ℝ) * log n = 1 / n * S := by
    constructor
    · intro h; rw [h]
    · intro h
      have := congrArg (fun x => (n : ℝ) * x) h
      field_simp at this
      linarith
  rw [this, hE]
  simp

/-- **One answer carries at most 1 bit.** For a yes-or-no question with chance p of yes,
0 ≤ p ≤ 1, the binary entropy h(p) is at most 1 bit, and it is exactly 1 only when p = 1/2. -/
theorem binEntropyBits_le_one_eq_iff_half (p : ℝ) (h0 : 0 ≤ p) (h1 : p ≤ 1) :
    binEntropyBits p ≤ 1 ∧ (binEntropyBits p = 1 ↔ p = 1 / 2) := by
  have hl2 : 0 < log 2 := log_pos (by norm_num)
  rw [binEntropyBits_eq]
  refine ⟨?_, ?_⟩
  · rw [div_le_one hl2]; exact binEntropy_le_log_two
  · rw [div_eq_one_iff_eq hl2.ne', binEntropy_eq_log_two, one_div]

/-- **Surprise adds when chances multiply.** Two independent events of chances p and q, both
positive, happen together with chance p q, and the surprise of both is the sum of the two
surprises: log2(1/(p q)) = log2(1/p) + log2(1/q). -/
theorem surprise_mul_eq_add (p q : ℝ) (hp : 0 < p) (hq : 0 < q) :
    logb 2 (1 / (p * q)) = logb 2 (1 / p) + logb 2 (1 / q) := by
  rw [one_div, mul_inv, logb_mul (by positivity) (by positivity), one_div, one_div]

-- The station's forecast: sunny 1/2, cloudy 1/4, rain 1/8, snow 1/8 has entropy 7/4 bits.
example : entropy ![1 / 2, 1 / 4, 1 / 8, 1 / 8] = 7 / 4 := by
  simp [entropy, Fin.sum_univ_four, logb_two_four, logb_two_eight]
  norm_num
-- All four equal gives the ceiling, log2 4 = 2 bits.
example : entropy ![1 / 4, 1 / 4, 1 / 4, 1 / 4] = 2 := by
  simp [entropy, Fin.sum_univ_four, logb_two_four]
  norm_num
-- Surprises 1, 2, 3, 3: log2 2 = 1, log2 4 = 2, log2 8 = 3.
example : (2 : ℕ) ^ 1 = 2 ∧ (2 : ℕ) ^ 2 = 4 ∧ (2 : ℕ) ^ 3 = 8 := by norm_num
-- The question tree: 1/2 × 1 + 1/4 × 2 + 1/8 × 3 + 1/8 × 3 = 7/4 questions a day.
example : (1 / 2 : ℚ) * 1 + 1 / 4 * 2 + 1 / 8 * 3 + 1 / 8 * 3 = 7 / 4 := by norm_num
-- One question at a time: h(1/2) + 1/2 × (h(1/2) + 1/2 × h(1/2)) with h(1/2) = 1.
example : (1 : ℚ) + 1 / 2 * (1 + 1 / 2 * 1) = 7 / 4 := by norm_num
-- A year: 365 × 7/4 = 2555/4 bits by questions against 365 × 2 = 730 by two fixed bits.
example : (365 : ℚ) * (7 / 4) = 2555 / 4 ∧ 365 * 2 = 730 := by norm_num
-- The gap to the ceiling: 2 - 7/4 = 1/4 bit.
example : (2 : ℚ) - 7 / 4 = 1 / 4 := by norm_num
-- Sunny then snow: chance 1/2 × 1/8 = 1/16, surprise 1 + 3 = 4, and 2^4 = 16.
example : (1 / 2 : ℚ) * (1 / 8) = 1 / 16 ∧ 1 + 3 = 4 ∧ (2 : ℕ) ^ 4 = 16 := by norm_num
-- The usual tree in a snowy month (sunny 1/8, cloudy 1/8, rain 1/4, snow 1/2) costs 21/8 bits a
-- day, and 21/8 - 7/4 = 7/8 bits a day are wasted.
example : (1 / 8 : ℚ) * 1 + 1 / 8 * 2 + 1 / 4 * 3 + 1 / 2 * 3 = 21 / 8 ∧
    (21 / 8 : ℚ) - 7 / 4 = 7 / 8 := by norm_num
-- Averaging 1, 2, 3, 3 questions without the chances gives 9/4.
example : ((1 + 2 + 3 + 3 : ℚ)) / 4 = 9 / 4 := by norm_num
-- The grid search: four-way forecasts in steps of 1/20 are the ways to split 20 steps into
-- four parts, C(23, 3) = 1771 of them.
example : Nat.choose 23 3 = 1771 := by decide

#print axioms entropy_le_log_two_card_eq_iff_uniform
#print axioms binEntropyBits_le_one_eq_iff_half
#print axioms surprise_mul_eq_add

end EntropyCard
