-- Adding a million numbers without losing the small ones: in the standard rounding model the plain left-to-right sum is off by at most γ_(n-1) times the sum of |x_i|, the pairwise sum by at most γ_L times it, and Welford's one-pass update gives the exact mean and variance in exact arithmetic.
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity

open Finset

/-! A machine addition is a function `fl : ℝ → ℝ → ℝ`. It obeys the standard model with unit
roundoff `u` (for doubles `u = 2^-53`, rounding to nearest) when every result is the exact sum
times `1 + δ` for some `|δ| ≤ u`:

  `∀ a b, ∃ δ, |δ| ≤ u ∧ fl a b = (a + b) * (1 + δ)`.

Each addition is free to choose its own `δ`; nothing else about `fl` is assumed.
`γ_k = k u / (1 - k u)` is the bound after `k` roundings in a row. -/

/-- `γ_k = k u / (1 - k u)`. -/
noncomputable def gamma (u : ℝ) (k : ℕ) : ℝ := k * u / (1 - k * u)

/-- The plain sum, left to right, in the order given: `T̂_1 = x_1`, `T̂_k = fl(T̂_(k-1), x_k)`.
The empty list sums to 0. -/
def plainSum (fl : ℝ → ℝ → ℝ) : List ℝ → ℝ
  | [] => 0
  | a :: l => l.foldl fl a

/-- The pairwise sum of the `2^L` numbers `x s, x (s+1), ..., x (s + 2^L - 1)`: one number is
itself; otherwise add the pairwise sum of the first half to that of the second half.
Each number passes through exactly `L` additions. A list of `n` numbers is padded with zeros to
`2^L` numbers, `L = ⌈log2 n⌉`; the padding changes neither the sum nor the sum of `|x_i|`. -/
def pairwiseSum (fl : ℝ → ℝ → ℝ) : ℕ → (ℕ → ℝ) → ℕ → ℝ
  | 0, x, s => x s
  | L + 1, x, s => fl (pairwiseSum fl L x s) (pairwiseSum fl L x (s + 2 ^ L))

/-- Welford's running mean: `μ_0 = 0`, `μ_k = μ_(k-1) + (x_k - μ_(k-1)) / k`
(readings indexed from 0, so the `k`-th reading is `x (k-1)`). -/
noncomputable def welfordMean (x : ℕ → ℝ) : ℕ → ℝ
  | 0 => 0
  | k + 1 => welfordMean x k + (x k - welfordMean x k) / (k + 1)

/-- Welford's running sum of squared distances:
`M_0 = 0`, `M_k = M_(k-1) + (x_k - μ_(k-1)) (x_k - μ_k)`. -/
noncomputable def welfordM (x : ℕ → ℝ) : ℕ → ℝ
  | 0 => 0
  | k + 1 => welfordM x k + (x k - welfordMean x k) * (x k - welfordMean x (k + 1))

/-- `(1 + u)^m (1 - m u) ≤ 1` whenever `u ≥ 0`. -/
theorem one_add_pow_mul_one_sub_le (u : ℝ) (hu : 0 ≤ u) (m : ℕ) :
    (1 + u) ^ m * (1 - m * u) ≤ 1 := by
  induction m with
  | zero => simp
  | succ m ih =>
    have h1 : (1 + u) * (1 - ((m + 1 : ℕ) : ℝ) * u) ≤ 1 - m * u := by
      push_cast; nlinarith [sq_nonneg u, mul_nonneg (Nat.cast_nonneg (α := ℝ) m) (sq_nonneg u)]
    have h2 : 0 ≤ (1 + u) ^ m := by positivity
    calc (1 + u) ^ (m + 1) * (1 - ((m + 1 : ℕ) : ℝ) * u)
        = (1 + u) ^ m * ((1 + u) * (1 - ((m + 1 : ℕ) : ℝ) * u)) := by ring
      _ ≤ (1 + u) ^ m * (1 - m * u) := mul_le_mul_of_nonneg_left h1 h2
      _ ≤ 1 := ih

/-- `(1 + u)^m - 1 ≤ γ_m` whenever `u ≥ 0` and `m u < 1`. -/
theorem one_add_pow_sub_one_le_gamma (u : ℝ) (hu : 0 ≤ u) (m : ℕ) (hmu : (m : ℝ) * u < 1) :
    (1 + u) ^ m - 1 ≤ gamma u m := by
  unfold gamma
  have hpos : 0 < 1 - (m : ℝ) * u := by linarith
  rw [le_div_iff₀ hpos]
  have := one_add_pow_mul_one_sub_le u hu m
  linarith

/-- One step of a rounded addition: the error grows by at most the factor `1 + u`, plus `u`
times the new exact value. -/
theorem fl_step_err (fl : ℝ → ℝ → ℝ) (u : ℝ)
    (hfl : ∀ a b : ℝ, ∃ δ : ℝ, |δ| ≤ u ∧ fl a b = (a + b) * (1 + δ))
    (a b s t : ℝ) :
    |fl a b - (s + t)| ≤ (|a - s| + |b - t|) * (1 + u) + u * (|s| + |t|) := by
  obtain ⟨δ, hδ, h⟩ := hfl a b
  have hu : 0 ≤ u := le_trans (abs_nonneg δ) hδ
  rw [h]
  have e : (a + b) * (1 + δ) - (s + t) = ((a - s) + (b - t)) * (1 + δ) + δ * (s + t) := by ring
  rw [e]
  have h1 : |1 + δ| ≤ 1 + u := by
    calc |1 + δ| ≤ |(1 : ℝ)| + |δ| := abs_add_le _ _
      _ ≤ 1 + u := by rw [abs_one]; linarith
  calc |((a - s) + (b - t)) * (1 + δ) + δ * (s + t)|
      ≤ |((a - s) + (b - t)) * (1 + δ)| + |δ * (s + t)| := abs_add_le _ _
    _ = |(a - s) + (b - t)| * |1 + δ| + |δ| * |s + t| := by rw [abs_mul, abs_mul]
    _ ≤ (|a - s| + |b - t|) * (1 + u) + u * (|s| + |t|) := by
        apply add_le_add
        · exact mul_le_mul (abs_add_le _ _) h1 (abs_nonneg _) (by positivity)
        · exact mul_le_mul hδ (abs_add_le _ _) (abs_nonneg _) hu

/-- The left-to-right fold keeps its error below `((1 + u)^j - 1)` times the running sum of
absolute values. -/
theorem foldl_err (fl : ℝ → ℝ → ℝ) (u : ℝ)
    (hfl : ∀ a b : ℝ, ∃ δ : ℝ, |δ| ≤ u ∧ fl a b = (a + b) * (1 + δ)) (hu : 0 ≤ u)
    (l : List ℝ) : ∀ (a s A : ℝ) (j : ℕ), |s| ≤ A → |a - s| ≤ ((1 + u) ^ j - 1) * A →
      |l.foldl fl a - (s + l.sum)| ≤ ((1 + u) ^ (j + l.length) - 1) * (A + (l.map (fun x => |x|)).sum) := by
  induction l with
  | nil => intro a s A j _ h; simpa using h
  | cons y l ih =>
    intro a s A j hs h
    simp only [List.foldl_cons, List.sum_cons, List.map_cons, List.length_cons]
    have hA : 0 ≤ A := le_trans (abs_nonneg s) hs
    have hpow : 1 + u ≤ (1 + u) ^ (j + 1) := by
      rw [pow_succ]
      have : 1 ≤ (1 + u) ^ j := one_le_pow₀ (by linarith)
      nlinarith
    have hstep := fl_step_err fl u hfl a y s y
    simp only [sub_self, abs_zero, add_zero] at hstep
    have key : |fl a y - (s + y)| ≤ ((1 + u) ^ (j + 1) - 1) * (A + |y|) := by
      calc |fl a y - (s + y)| ≤ |a - s| * (1 + u) + u * (|s| + |y|) := hstep
        _ ≤ ((1 + u) ^ j - 1) * A * (1 + u) + u * (A + |y|) := by
            apply add_le_add
            · exact mul_le_mul_of_nonneg_right h (by linarith)
            · exact mul_le_mul_of_nonneg_left (by linarith) hu
        _ = ((1 + u) ^ (j + 1) - 1 - u) * A + u * (A + |y|) := by ring
        _ ≤ ((1 + u) ^ (j + 1) - 1 - u) * (A + |y|) + u * (A + |y|) := by
            exact add_le_add (mul_le_mul_of_nonneg_left (by linarith [abs_nonneg y]) (by linarith)) le_rfl
        _ = ((1 + u) ^ (j + 1) - 1) * (A + |y|) := by ring
    have hs' : |s + y| ≤ A + |y| := le_trans (abs_add_le _ _) (by linarith)
    have := ih (fl a y) (s + y) (A + |y|) (j + 1) hs' key
    rw [show j + (l.length + 1) = j + 1 + l.length by ring]
    rw [show s + (y + l.sum) = s + y + l.sum by ring,
      show A + (|y| + (l.map (fun x => |x|)).sum) = A + |y| + (l.map (fun x => |x|)).sum by ring]
    exact this

/-- The pairwise tree of depth `L` starting at `s` is off by at most `((1 + u)^L - 1)` times
the sum of absolute values of its `2^L` leaves. -/
theorem pairwise_err (fl : ℝ → ℝ → ℝ) (u : ℝ)
    (hfl : ∀ a b : ℝ, ∃ δ : ℝ, |δ| ≤ u ∧ fl a b = (a + b) * (1 + δ)) (hu : 0 ≤ u)
    (x : ℕ → ℝ) (L : ℕ) : ∀ s : ℕ,
    |pairwiseSum fl L x s - ∑ i ∈ range (2 ^ L), x (s + i)| ≤
      ((1 + u) ^ L - 1) * ∑ i ∈ range (2 ^ L), |x (s + i)| := by
  induction L with
  | zero => intro s; simp [pairwiseSum]
  | succ L ih =>
    intro s
    have hsplit : ∀ f : ℕ → ℝ, ∑ i ∈ range (2 ^ (L + 1)), f (s + i) =
        ∑ i ∈ range (2 ^ L), f (s + i) + ∑ i ∈ range (2 ^ L), f (s + 2 ^ L + i) := by
      intro f
      rw [pow_succ, mul_two, sum_range_add]
      simp only [add_assoc]
    rw [hsplit x, hsplit (fun i => |x i|)]
    simp only [pairwiseSum]
    have h1 := ih s
    have h2 := ih (s + 2 ^ L)
    have hstep := fl_step_err fl u hfl (pairwiseSum fl L x s) (pairwiseSum fl L x (s + 2 ^ L))
      (∑ i ∈ range (2 ^ L), x (s + i)) (∑ i ∈ range (2 ^ L), x (s + 2 ^ L + i))
    set A1 := ∑ i ∈ range (2 ^ L), |x (s + i)|
    set A2 := ∑ i ∈ range (2 ^ L), |x (s + 2 ^ L + i)|
    have hA1 : |∑ i ∈ range (2 ^ L), x (s + i)| ≤ A1 := abs_sum_le_sum_abs _ _
    have hA2 : |∑ i ∈ range (2 ^ L), x (s + 2 ^ L + i)| ≤ A2 := abs_sum_le_sum_abs _ _
    calc _ ≤ _ := hstep
      _ ≤ (((1 + u) ^ L - 1) * A1 + ((1 + u) ^ L - 1) * A2) * (1 + u) + u * (A1 + A2) := by
          apply add_le_add
          · exact mul_le_mul_of_nonneg_right (add_le_add h1 h2) (by linarith)
          · exact mul_le_mul_of_nonneg_left (add_le_add hA1 hA2) hu
      _ = ((1 + u) ^ (L + 1) - 1) * (A1 + A2) := by ring

/-- Welford's running mean is the plain mean, for every `n` (with `0 / 0 = 0` at `n = 0`). -/
theorem welfordMean_eq (x : ℕ → ℝ) (n : ℕ) :
    welfordMean x n = (∑ i ∈ range n, x i) / n := by
  induction n with
  | zero => simp [welfordMean]
  | succ k ih =>
    rw [welfordMean, ih, sum_range_succ]
    rcases Nat.eq_zero_or_pos k with rfl | hk
    · simp
    · have hk' : (k : ℝ) ≠ 0 := by positivity
      push_cast
      field_simp
      ring

/-- Welford's running sum `M_n` equals `∑ x_i² - (∑ x_i)² / n`. -/
theorem welfordM_eq (x : ℕ → ℝ) (n : ℕ) :
    welfordM x n = ∑ i ∈ range n, x i ^ 2 - (∑ i ∈ range n, x i) ^ 2 / n := by
  induction n with
  | zero => simp [welfordM]
  | succ k ih =>
    rw [welfordM, ih, welfordMean_eq, welfordMean_eq, sum_range_succ, sum_range_succ]
    rcases Nat.eq_zero_or_pos k with rfl | hk
    · simp
    · have hk' : (k : ℝ) ≠ 0 := by positivity
      push_cast
      field_simp
      ring

#print axioms one_add_pow_mul_one_sub_le
#print axioms one_add_pow_sub_one_le_gamma
#print axioms fl_step_err
#print axioms foldl_err
#print axioms pairwise_err
#print axioms welfordMean_eq
#print axioms welfordM_eq

/-- The plain sum's error bound. If every machine addition obeys the standard model
`fl(a + b) = (a + b)(1 + δ)`, `|δ| ≤ u`, the additions are done left to right in the order given,
and `(n - 1) u < 1`, then the computed total `Ŝ` of `n` numbers `x_1, ..., x_n` with exact
total `S` obeys `|Ŝ - S| ≤ γ_(n-1) (|x_1| + ... + |x_n|)`. -/
theorem plain_sum_error_le_gamma_mul_sum_abs (fl : ℝ → ℝ → ℝ) (u : ℝ)
    (hfl : ∀ a b : ℝ, ∃ δ : ℝ, |δ| ≤ u ∧ fl a b = (a + b) * (1 + δ))
    (xs : List ℝ) (hnu : ((xs.length : ℝ) - 1) * u < 1) :
    |plainSum fl xs - xs.sum| ≤ gamma u (xs.length - 1) * (xs.map (fun x => |x|)).sum := by
  obtain ⟨δ, hδ, _⟩ := hfl 0 0
  have hu : 0 ≤ u := le_trans (abs_nonneg δ) hδ
  cases xs with
  | nil => simp [plainSum, gamma]
  | cons a l =>
    have h := foldl_err fl u hfl hu l a a |a| 0 le_rfl (by simp)
    simp only [zero_add] at h
    simp only [plainSum, List.sum_cons, List.map_cons, List.length_cons, Nat.add_sub_cancel]
    simp only [List.length_cons, Nat.cast_add, Nat.cast_one, add_sub_cancel_right] at hnu
    have hg := one_add_pow_sub_one_le_gamma u hu l.length hnu
    have hS : 0 ≤ |a| + (l.map (fun x => |x|)).sum := by
      apply add_nonneg (abs_nonneg a)
      apply List.sum_nonneg
      intro z hz
      simp only [List.mem_map] at hz
      obtain ⟨w, _, rfl⟩ := hz
      exact abs_nonneg w
    exact le_trans h (mul_le_mul_of_nonneg_right hg hS)

/-- The pairwise sum's error bound. If every machine addition obeys the standard model with
unit roundoff `u` and `L u < 1`, the pairwise sum of `2^L` numbers is off by at most
`γ_L (|x_1| + ... + |x_(2^L)|)`: one `u` per level of the tree, not one per number. -/
theorem pairwise_sum_error_le_gamma_mul_sum_abs (fl : ℝ → ℝ → ℝ) (u : ℝ)
    (hfl : ∀ a b : ℝ, ∃ δ : ℝ, |δ| ≤ u ∧ fl a b = (a + b) * (1 + δ))
    (L : ℕ) (hLu : (L : ℝ) * u < 1) (x : ℕ → ℝ) :
    |pairwiseSum fl L x 0 - ∑ i ∈ range (2 ^ L), x i| ≤
      gamma u L * ∑ i ∈ range (2 ^ L), |x i| := by
  obtain ⟨δ, hδ, _⟩ := hfl 0 0
  have hu : 0 ≤ u := le_trans (abs_nonneg δ) hδ
  have h := pairwise_err fl u hfl hu x L 0
  simp only [zero_add] at h
  have hg := one_add_pow_sub_one_le_gamma u hu L hLu
  have hS : 0 ≤ ∑ i ∈ range (2 ^ L), |x i| := sum_nonneg (fun i _ => abs_nonneg (x i))
  exact le_trans h (mul_le_mul_of_nonneg_right hg hS)

/-- Welford's update is exact in exact arithmetic: after `n ≥ 1` readings its running mean is
the mean of the readings, and its running sum `M_n` is the sum of squared distances from that
mean, so `σ² = M_n / n` is the variance, found in one pass. -/
theorem welford_mean_and_variance (x : ℕ → ℝ) (n : ℕ) (hn : 1 ≤ n) :
    welfordMean x n = (∑ i ∈ range n, x i) / n ∧
    welfordM x n = ∑ i ∈ range n, (x i - (∑ j ∈ range n, x j) / n) ^ 2 := by
  refine ⟨welfordMean_eq x n, ?_⟩
  rw [welfordM_eq]
  have hn' : (n : ℝ) ≠ 0 := by positivity
  set S := ∑ j ∈ range n, x j
  have e : ∀ i, (x i - S / n) ^ 2 = x i ^ 2 - 2 * (S / n) * x i + (S / n) ^ 2 := by
    intro i; ring
  simp_rw [e, sum_add_distrib, sum_sub_distrib, ← mul_sum, sum_const, card_range, nsmul_eq_mul]
  field_simp
  ring

-- The card's exact worked numbers.

-- The barometer cycle 101325 + (k - 12)/4 Pa, k = 0, ..., 24: its mean is exactly 101325 Pa.
example : (∑ k ∈ range 25, ((101325 : ℚ) + ((k : ℚ) - 12) / 4)) / 25 = 101325 := by
  simp only [sum_range_succ, sum_range_zero]; norm_num

-- Its variance is exactly 13/4 = 3.25 Pa², and the closed form (1/16) × 2(1² + ... + 12²)/25 agrees.
example : (∑ k ∈ range 25, (((k : ℚ) - 12) / 4) ^ 2) / 25 = 13 / 4 := by
  simp only [sum_range_succ, sum_range_zero]; norm_num
example : (2 * ∑ j ∈ range 13, (j : ℚ) ^ 2) / (25 * 16) = 13 / 4 := by
  simp only [sum_range_succ, sum_range_zero]; norm_num

-- Ten million ticks need L = ⌈log2 10^7⌉ = 24 levels: 2^23 < 10^7 ≤ 2^24.
example : 2 ^ 23 < 10 ^ 7 ∧ 10 ^ 7 ≤ 2 ^ 24 := by norm_num

-- In singles above 524288 = 2^19 the gap is 2^(19-23) = 1/16, and 0.1 rounds to 2 gaps,
-- 1/8 = 0.125, which is 25% too much: 2/16 is nearer 1/10 than 1/16 or 3/16.
example : |(2 : ℚ) / 16 - 1 / 10| < |(1 : ℚ) / 16 - 1 / 10| ∧
    |(2 : ℚ) / 16 - 1 / 10| < |(3 : ℚ) / 16 - 1 / 10| ∧ ((1 : ℚ) / 8 - 1 / 10) / (1 / 10) = 1 / 4 := by
  norm_num [abs_of_pos, abs_of_neg]

#print axioms plain_sum_error_le_gamma_mul_sum_abs
#print axioms pairwise_sum_error_le_gamma_mul_sum_abs
#print axioms welford_mean_and_variance
