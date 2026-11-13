-- Ito's product rule: on any grid the change in a product is exactly the two "factor times the other's change" sums plus the sum of corner terms, that corner sum shrinks to zero when one factor has no noise part, and the two-squares route turns the noise parts b and h into the covariation b h.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Topology.EMetricSpace.BoundedVariation
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Topology.UniformSpace.HeineCantor
import Mathlib.Tactic.LinearCombination

open Finset Filter Topology

/-! Mathlib has no Ito integral and no Ito processes, so the card's limit statement
`d(X_t Y_t) = X_t dY_t + Y_t dX_t + d[X,Y]_t` cannot be written here. This file states the exact
parts of the card's argument: the grid identity of Step 1 (true for every path and every grid),
the fact that the corner sum vanishes when one factor has no noise part (the "When it holds"
case of the discount factor), and the algebra of the Step 4 proof from Ito's lemma for a square.
`X k`, `Y k` are the two quantities at the start of step `k`. -/

lemma grid_point_mem_Icc (T : ℝ) (hT : 0 ≤ T) (n k : ℕ) (hn : 0 < n) (hk : k ≤ n) :
    (k : ℝ) * T / n ∈ Set.Icc 0 T := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hk' : (k : ℝ) ≤ n := by exact_mod_cast hk
  refine ⟨by positivity, ?_⟩
  rw [div_le_iff₀ hn']
  nlinarith

lemma grid_sum_abs_le_variation (Y : ℝ → ℝ) (T : ℝ) (hT : 0 ≤ T)
    (hY : BoundedVariationOn Y (Set.Icc 0 T)) (n : ℕ) (hn : 0 < n) :
    ∑ k ∈ range n, |Y ((k + 1) * T / n) - Y (k * T / n)| ≤
      (eVariationOn Y (Set.Icc 0 T)).toReal := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hmono : MonotoneOn (fun i : ℕ => (i : ℝ) * T / n) (Set.Icc 0 n) := by
    intro a _ b _ hab
    have : (a : ℝ) ≤ b := by exact_mod_cast hab
    simp only
    apply div_le_div_of_nonneg_right _ hn'.le
    nlinarith
  have hmem : ∀ i ∈ Set.Icc 0 n, (fun i : ℕ => (i : ℝ) * T / n) i ∈ Set.Icc 0 T :=
    fun i hi => grid_point_mem_Icc T hT n i hn hi.2
  have h := eVariationOn.sum_le_of_monotoneOn_Icc (f := Y) hmono hmem
  rw [← Finset.range_eq_Ico] at h
  simp only [edist_dist, Real.dist_eq, Nat.cast_add, Nat.cast_one] at h
  rw [← ENNReal.ofReal_sum_of_nonneg (fun _ _ => abs_nonneg _)] at h
  exact (ENNReal.ofReal_le_iff_le_toReal hY).1 h

#print axioms grid_point_mem_Icc
#print axioms grid_sum_abs_le_variation

/-- Step 1 of the card: cut time into `n` steps. For every path and every grid, the product's
total change equals the sum of `X_k ΔY_k`, plus the sum of `Y_k ΔX_k`, plus the sum of the corner
terms `ΔX_k ΔY_k`, with no approximation. The corner sum is what becomes the covariation. -/
theorem product_change_eq_two_sums_plus_corner_sum (X Y : ℕ → ℝ) (n : ℕ) :
    X n * Y n - X 0 * Y 0 =
      ∑ k ∈ range n, X k * (Y (k + 1) - Y k) + ∑ k ∈ range n, Y k * (X (k + 1) - X k) +
        ∑ k ∈ range n, (X (k + 1) - X k) * (Y (k + 1) - Y k) := by
  induction n with
  | zero => simp
  | succ m ih =>
    simp only [sum_range_succ]
    linear_combination ih

/-- If one factor has no noise part, the covariation is zero. Path by path: let `X` be any
continuous path on `[0, T]` (such as a share price) and `Y` a factor with no noise part, that is,
of bounded variation on `[0, T]` (such as the discount factor `e^{-rt}`, or any
`Y_0 + ∫ g dt`). Then the corner sum `∑ ΔX_k ΔY_k` over the grid of `n` equal steps tends to `0`
as `n` grows, so the school product rule is exact for the product. -/
theorem corner_sum_tendsto_zero_of_no_noise (X Y : ℝ → ℝ) (T : ℝ) (hT : 0 ≤ T)
    (hX : ContinuousOn X (Set.Icc 0 T)) (hY : BoundedVariationOn Y (Set.Icc 0 T)) :
    Tendsto (fun n : ℕ => ∑ k ∈ range n,
        (X ((k + 1) * T / n) - X (k * T / n)) * (Y ((k + 1) * T / n) - Y (k * T / n)))
      atTop (𝓝 0) := by
  have hU := Metric.uniformContinuousOn_iff.1
    ((isCompact_Icc).uniformContinuousOn_of_continuous hX)
  set V := (eVariationOn Y (Set.Icc 0 T)).toReal with hVdef
  have hV : 0 ≤ V := ENNReal.toReal_nonneg
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨δ, hδ, hXδ⟩ := hU (ε / (V + 1)) (by positivity)
  obtain ⟨N, hN⟩ := exists_nat_gt (T / δ)
  refine ⟨N + 1, fun n hn => ?_⟩
  have hn0 : 0 < n := by omega
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn0
  have hNn : (N : ℝ) + 1 ≤ n := by exact_mod_cast hn
  have hstep : T / n < δ := by
    rw [div_lt_iff₀ hn']
    rw [div_lt_iff₀ hδ] at hN
    nlinarith
  have hterm : ∀ k ∈ range n, |X ((k + 1) * T / n) - X (k * T / n)| ≤ ε / (V + 1) := by
    intro k hk
    have hk : k < n := mem_range.1 hk
    have h1 := grid_point_mem_Icc T hT n (k + 1) hn0 hk
    have h0 := grid_point_mem_Icc T hT n k hn0 hk.le
    push_cast at h1
    have hd : dist ((k + 1 : ℝ) * T / n) (k * T / n) < δ := by
      rw [Real.dist_eq]
      have : (k + 1 : ℝ) * T / n - k * T / n = T / n := by ring
      rw [this, abs_of_nonneg (by positivity)]
      exact hstep
    have := hXδ _ h1 _ h0 hd
    rw [Real.dist_eq] at this
    exact this.le
  have hsum := grid_sum_abs_le_variation Y T hT hY n hn0
  rw [Real.dist_eq, sub_zero]
  calc |∑ k ∈ range n, (X ((k + 1) * T / n) - X (k * T / n)) *
          (Y ((k + 1) * T / n) - Y (k * T / n))|
      ≤ ∑ k ∈ range n, |(X ((k + 1) * T / n) - X (k * T / n)) *
          (Y ((k + 1) * T / n) - Y (k * T / n))| := Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ k ∈ range n, ε / (V + 1) * |Y ((k + 1) * T / n) - Y (k * T / n)| := by
        apply Finset.sum_le_sum
        intro k hk
        rw [abs_mul]
        exact mul_le_mul_of_nonneg_right (hterm k hk) (abs_nonneg _)
    _ = ε / (V + 1) * ∑ k ∈ range n, |Y ((k + 1) * T / n) - Y (k * T / n)| := by
        rw [Finset.mul_sum]
    _ ≤ ε / (V + 1) * V := mul_le_mul_of_nonneg_left hsum (by positivity)
    _ < ε := by
        rw [div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]
        nlinarith

/-- Step 4 of the card, the short proof from Ito's lemma, as exact algebra. Write `U = X + Y`
and `V = X - Y`, so `dU = dX + dY` and `dV = dX - dY`, with noise parts `b + h` and `b - h`.
The product is a difference of two squares divided by four. If Ito's lemma for the square gives
`d(U²) = 2U dU + (b+h)² dt` and `d(V²) = 2V dV + (b-h)² dt`, then subtracting and dividing by
four leaves `d(XY) = X dY + Y dX + b h dt`: the extra term is the noise parts multiplied. -/
theorem two_squares_give_product_rule (X Y dX dY b h dt dU2 dV2 : ℝ)
    (hU : dU2 = 2 * (X + Y) * (dX + dY) + (b + h) ^ 2 * dt)
    (hV : dV2 = 2 * (X - Y) * (dX - dY) + (b - h) ^ 2 * dt) :
    X * Y = ((X + Y) ^ 2 - (X - Y) ^ 2) / 4 ∧
      (dU2 - dV2) / 4 = X * dY + Y * dX + b * h * dt := by
  constructor
  · ring
  · rw [hU, hV]; ring

/-! The card's exact worked arithmetic: drift 8% = 8/100, bank rate 5% = 5/100, volatility
20% = 20/100. -/

-- The noise-part bracket in the detailed proof: (b + h)^2 - (b - h)^2 = 4 b h.
example : ∀ b h : ℚ, (b + h) ^ 2 - (b - h) ^ 2 = 4 * b * h := by intro b h; ring

-- Share times discount factor: the covariation is sigma S_t times 0, which is 0.
example : ∀ σ S : ℚ, σ * S * 0 = 0 := by intro σ S; ring

-- Step 5: e^{-rt} dS - r S e^{-rt} dt equals D((mu - r) dt + sigma dW) with D = S e^{-rt}.
example : ∀ e S μ σ r dt dW : ℚ,
    e * (μ * S * dt + σ * S * dW) - r * S * e * dt = (S * e) * ((μ - r) * dt + σ * dW) := by
  intro e S μ σ r dt dW; ring

-- Drift of the discounted share at the real 8%: 0.08 - 0.05 = 0.03.
example : (8 / 100 : ℚ) - 5 / 100 = 3 / 100 := by norm_num

-- Drift at the right 5%: 0.05 - 0.05 = 0.
example : (5 / 100 : ℚ) - 5 / 100 = 0 := by norm_num

-- Average discounted share after one year at the right drift: 100 e^0 = 100.
example : (100 : ℝ) * Real.exp 0 = 100 := by rw [Real.exp_zero, mul_one]

-- Growth rate of the average squared share at drift 0.05: 2 mu + sigma^2 = 0.10 + 0.04 = 0.14.
example : 2 * (5 / 100 : ℚ) + (20 / 100) ^ 2 = 14 / 100 := by norm_num

#print axioms product_change_eq_two_sums_plus_corner_sum
#print axioms corner_sum_tendsto_zero_of_no_noise
#print axioms two_squares_give_product_rule
