-- Prospect theory in outline: no expected-utility curve can produce the certainty reversal, the loss side of the value curve mirrors the gain side so all-loss choices flip, and ranked decision weights are non-negative and add up by telescoping.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

open Finset

/-- The prospect-theory value of a change of `x` dollars: `x ^ α` for a gain (or zero),
`-lam * (-x) ^ α` for a loss, where `lam` is the loss multiplier. -/
noncomputable def ptValue (α lam x : ℝ) : ℝ :=
  if 0 ≤ x then x ^ α else -lam * (-x) ^ α

/-- Expected utility cannot produce the certainty reversal. Take any utility curve `u`.
Prospect A pays `x` with chance `p`, else nothing; B pays `y` for sure. Now multiply every
chance by the same factor `k > 0` (Problem 4 is Problem 3 with every chance divided by four):
C pays `x` with chance `k * p`, D pays `y` with chance `k`. Scoring each prospect by its
average utility over the true chances, it is impossible to prefer B to A and also C to D. -/
theorem expected_utility_cannot_produce_certainty_reversal
    (u : ℝ → ℝ) (x y p k : ℝ) (hk : 0 < k) :
    ¬ (u y > p * u x + (1 - p) * u 0 ∧
        k * p * u x + (1 - k * p) * u 0 > k * u y + (1 - k) * u 0) := by
  rintro ⟨h1, h2⟩
  have h3 : k * (p * (u x - u 0)) > k * (u y - u 0) := by linarith
  have h4 : p * (u x - u 0) > u y - u 0 := lt_of_mul_lt_mul_left h3 hk.le
  linarith

/-- The reflection effect. For a loss of size `a > 0`, the value is the gain curve flipped and
stretched: `v(-a) = -lam * v(a)`. So with a positive loss multiplier, any comparison of two
all-loss prospects (each a decision weight times the value of a loss) runs the opposite way
to the same comparison of the mirror-image gains, and `lam` cancels. -/
theorem losses_mirror_gains_and_choices_flip
    (α lam a b p q : ℝ) (hlam : 0 < lam) (ha : 0 < a) (hb : 0 < b) :
    ptValue α lam (-a) = -lam * ptValue α lam a ∧
      (p * ptValue α lam (-a) < q * ptValue α lam (-b) ↔
        q * ptValue α lam b < p * ptValue α lam a) := by
  have hva : ptValue α lam (-a) = -lam * a ^ α := by
    unfold ptValue; rw [if_neg (by linarith), neg_neg]
  have hvb : ptValue α lam (-b) = -lam * b ^ α := by
    unfold ptValue; rw [if_neg (by linarith), neg_neg]
  have hpa : ptValue α lam a = a ^ α := by
    unfold ptValue; rw [if_pos ha.le]
  have hpb : ptValue α lam b = b ^ α := by
    unfold ptValue; rw [if_pos hb.le]
  rw [hva, hvb, hpa, hpb]
  refine ⟨rfl, ?_⟩
  constructor
  · intro h
    by_contra hc
    push_neg at hc
    have := mul_le_mul_of_nonneg_left hc hlam.le
    nlinarith
  · intro h
    have := mul_lt_mul_of_pos_left h hlam
    nlinarith

/-- Ranked (cumulative) decision weights. Rank the outcomes, let `p i` be the chance of the
`i`-th one and `G i = p 0 + ... + p (i-1)` the chance of doing at least that well. The weight of
outcome `i` is `w (G (i+1)) - w (G i)`. If the weighting curve `w` increases, every such weight is
non-negative, and the weights telescope: together they add up to `w` of the total chance,
minus `w 0`. -/
theorem ranked_weights_nonneg_and_telescope
    (w : ℝ → ℝ) (hw : Monotone w) (p : ℕ → ℝ) (hp : ∀ i, 0 ≤ p i) (n : ℕ) :
    (∀ i, 0 ≤ w (∑ j ∈ range (i + 1), p j) - w (∑ j ∈ range i, p j)) ∧
      ∑ i ∈ range n, (w (∑ j ∈ range (i + 1), p j) - w (∑ j ∈ range i, p j)) =
        w (∑ j ∈ range n, p j) - w 0 := by
  refine ⟨fun i => ?_, ?_⟩
  · rw [sub_nonneg]
    apply hw
    rw [sum_range_succ]
    linarith [hp i]
  · rw [sum_range_sub (fun i => w (∑ j ∈ range i, p j)) n]
    simp

-- Problem 3's gamble, 80% of $4,000, has expected payout $3,200.
example : (4 / 5 : ℚ) * 4000 = 3200 := by norm_num
-- Problem 4 is Problem 3 with every chance divided by four: 80% becomes 20%, 100% becomes 25%.
example : (4 / 5 : ℚ) / 4 = 1 / 5 ∧ (1 : ℚ) / 4 = 1 / 4 := by norm_num
-- Coin toss on straight lines with loss multiplier 9/4: heads must pay $225 to break even.
example : (1 / 2 : ℚ) * 225 - (9 / 4) * ((1 / 2) * 100) = 0 := by norm_num
example : (100 : ℚ) * (9 / 4) = 225 := by norm_num
-- Sixteen tickets of 5% make the 80% chance.
example : (16 : ℚ) * (1 / 20) = 4 / 5 := by norm_num
-- The saver: $10,000 at 4% is $400, at a mean of 8% is $800, with a spread of 15% = $1,500.
example : (10000 : ℚ) * (4 / 100) = 400 ∧ (10000 : ℚ) * (8 / 100) = 800 ∧
    (10000 : ℚ) * (15 / 100) = 1500 := by norm_num

#print axioms expected_utility_cannot_produce_certainty_reversal
#print axioms losses_mirror_gains_and_choices_flip
#print axioms ranked_weights_nonneg_and_telescope
