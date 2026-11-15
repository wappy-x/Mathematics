-- Banach's fixed point theorem: a contraction on a complete metric space has exactly one fixed point, its iterates from any start reach it within the first-step and last-step bounds, and the continuous curves on [a, b] are complete under the worst-gap distance.
import Mathlib.Topology.MetricSpace.Contracting
import Mathlib.Topology.ContinuousMap.Compact

open Filter Topology

/-- Banach's fixed point theorem. Let `X` be a complete metric space and `T` a map of `X` into
itself that shrinks every distance by one factor `q` with `0 ≤ q < 1`:
`d(T x, T y) ≤ q · d(x, y)` for all `x, y`. Then, starting the passes from any point `x₀`,
there is a fixed point `x*` (`T x* = x*`), it is the only fixed point, the iterates
`x_n = Tⁿ x₀` converge to it, and after `n` passes the error is at most the first-step bound
`d(x_n, x*) ≤ qⁿ / (1 - q) · d(x₁, x₀)`. -/
theorem contraction_has_unique_fixed_point_reached_by_iteration
    {X : Type*} [MetricSpace X] [CompleteSpace X]
    (T : X → X) (q : ℝ) (hq0 : 0 ≤ q) (hq1 : q < 1)
    (hT : ∀ x y : X, dist (T x) (T y) ≤ q * dist x y) (x₀ : X) :
    ∃ xstar : X, T xstar = xstar ∧ (∀ y : X, T y = y → y = xstar) ∧
      Tendsto (fun n : ℕ => T^[n] x₀) atTop (𝓝 xstar) ∧
      ∀ n : ℕ, dist (T^[n] x₀) xstar ≤ q ^ n / (1 - q) * dist (T x₀) x₀ := by
  let K : NNReal := ⟨q, hq0⟩
  have hKq : (K : ℝ) = q := rfl
  have hK : ContractingWith K T :=
    ⟨by rw [← NNReal.coe_lt_coe, hKq, NNReal.coe_one]; exact hq1,
     LipschitzWith.of_dist_le_mul fun x y => by rw [hKq]; exact hT x y⟩
  have : Nonempty X := ⟨x₀⟩
  refine ⟨ContractingWith.fixedPoint T hK, hK.fixedPoint_isFixedPt,
    fun y hy => hK.fixedPoint_unique hy, hK.tendsto_iterate_fixedPoint x₀, fun n => ?_⟩
  have h := hK.apriori_dist_iterate_fixedPoint_le x₀ n
  rw [hKq] at h
  calc dist (T^[n] x₀) (ContractingWith.fixedPoint T hK) ≤ dist x₀ (T x₀) * q ^ n / (1 - q) := h
    _ = q ^ n / (1 - q) * dist (T x₀) x₀ := by rw [dist_comm]; ring

/-- The last-step bound, the card's stopping rule. Under the same hypotheses, if `x*` is the
fixed point of `T`, then after any pass `n ≥ 1` the distance to `x*` is at most `q / (1 - q)`
times the length of the last step: `d(x_n, x*) ≤ q / (1 - q) · d(x_n, x_{n-1})`. -/
theorem contraction_last_step_bound
    {X : Type*} [MetricSpace X] [CompleteSpace X]
    (T : X → X) (q : ℝ) (hq0 : 0 ≤ q) (hq1 : q < 1)
    (hT : ∀ x y : X, dist (T x) (T y) ≤ q * dist x y) (x₀ xstar : X) (hfix : T xstar = xstar)
    (n : ℕ) (hn : 1 ≤ n) :
    dist (T^[n] x₀) xstar ≤ q / (1 - q) * dist (T^[n] x₀) (T^[n - 1] x₀) := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  simp only [Nat.add_sub_cancel]
  have h1q : 0 < 1 - q := by linarith
  set z := T^[m] x₀ with hz
  have hsucc : T^[m + 1] x₀ = T z := by rw [Function.iterate_succ_apply']
  rw [hsucc]
  -- d(z, x*) ≤ d(z, T z) + d(T z, x*) ≤ d(z, T z) + q d(z, x*)
  have h1 : dist (T z) xstar ≤ q * dist z xstar := by
    simpa [hfix] using hT z xstar
  have h2 : dist z xstar ≤ dist z (T z) + dist (T z) xstar := dist_triangle _ _ _
  have h3 : (1 - q) * dist z xstar ≤ dist (T z) z := by
    rw [dist_comm z (T z)] at h2; nlinarith
  rw [div_mul_eq_mul_div, le_div_iff₀ h1q]
  calc dist (T z) xstar * (1 - q) ≤ q * dist z xstar * (1 - q) :=
        mul_le_mul_of_nonneg_right h1 h1q.le
    _ = q * ((1 - q) * dist z xstar) := by ring
    _ ≤ q * dist (T z) z := mul_le_mul_of_nonneg_left h3 hq0

/-- The continuous curves on the time window `[a, b]` are complete under the worst-gap distance:
if a sequence of continuous curves `y n` is Cauchy in the largest gap (for every tolerance
`ε > 0`, from some pass on any two curves differ by less than `ε` at every time), then there is
a continuous curve `y∞` that the sequence approaches in the largest gap (for every `ε > 0`,
from some pass on each curve is within `ε` of `y∞` at every time). -/
theorem continuous_curves_complete_under_worst_gap (a b : ℝ)
    (y : ℕ → C(Set.Icc a b, ℝ))
    (hy : ∀ ε > 0, ∃ N : ℕ, ∀ m ≥ N, ∀ n ≥ N, ∀ t, |y m t - y n t| < ε) :
    ∃ ylim : C(Set.Icc a b, ℝ), ∀ ε > 0, ∃ N : ℕ, ∀ n ≥ N, ∀ t, |y n t - ylim t| ≤ ε := by
  have hc : CauchySeq y := by
    rw [Metric.cauchySeq_iff]
    intro ε hε
    obtain ⟨N, hN⟩ := hy (ε / 2) (by positivity)
    refine ⟨N, fun m hm n hn => ?_⟩
    calc dist (y m) (y n) ≤ ε / 2 :=
          (ContinuousMap.dist_le (by positivity)).2 fun t => by
            rw [Real.dist_eq]; exact (hN m hm n hn t).le
      _ < ε := by linarith
  obtain ⟨ylim, hlim⟩ := cauchySeq_tendsto_of_complete hc
  refine ⟨ylim, fun ε hε => ?_⟩
  obtain ⟨N, hN⟩ := (Metric.tendsto_atTop.1 hlim) ε hε
  refine ⟨N, fun n hn t => ?_⟩
  have := ContinuousMap.dist_apply_le_dist (f := y n) (g := ylim) t
  rw [Real.dist_eq] at this
  exact this.trans (hN n hn).le

-- The four cafés: targets 280, 315, 350, 420 cents sum to 1365.
example : (280 : ℤ) + 315 + 350 + 420 = 1365 := by norm_num
-- The settled prices are (3 c + 1365) / 7: 315, 330, 345, 375 cents.
example : ((3 * 280 + 1365) / 7 : ℚ) = 315 ∧ ((3 * 315 + 1365) / 7 : ℚ) = 330 ∧
    ((3 * 350 + 1365) / 7 : ℚ) = 345 ∧ ((3 * 420 + 1365) / 7 : ℚ) = 375 := by norm_num
-- The morning rule (half the target plus half the rivals' average) leaves each settled price alone.
example : (280 : ℚ) / 2 + (330 + 345 + 375) / 6 = 315 ∧ (315 : ℚ) / 2 + (315 + 345 + 375) / 6 = 330 ∧
    (350 : ℚ) / 2 + (315 + 330 + 375) / 6 = 345 ∧ (420 : ℚ) / 2 + (315 + 330 + 345) / 6 = 375 := by
  norm_num
-- Morning 1 from 300 cents each: 290, 615/2, 325, 360; the first step is 360 - 300 = 60 cents.
example : (280 : ℚ) / 2 + 300 / 2 = 290 ∧ (315 : ℚ) / 2 + 300 / 2 = 615 / 2 ∧
    (350 : ℚ) / 2 + 300 / 2 = 325 ∧ (420 : ℚ) / 2 + 300 / 2 = 360 := by norm_num
-- First-step bound 60 / (1 - 1/2) / 2^n = 120 / 2^n cents: within 1 cent first at morning 7.
example : (1 / 2 : ℚ) ^ 7 / (1 - 1 / 2) * 60 ≤ 1 ∧ ¬ ((1 / 2 : ℚ) ^ 6 / (1 - 1 / 2) * 60 ≤ 1) := by
  norm_num
-- An even 10-cent shift: every new price moves by exactly 5 cents, ratio 1/2.
example : (1 / 2 : ℚ) * ((10 + 10 + 10) / 3) = 5 := by norm_num
-- Fractions only: x/2 + 1/x from 1 gives 3/2, 17/12, 577/408, 665857/470832.
example : (1 : ℚ) / 2 + 1 / 1 = 3 / 2 ∧ (3 / 2 : ℚ) / 2 + 1 / (3 / 2) = 17 / 12 ∧
    (17 / 12 : ℚ) / 2 + 1 / (17 / 12) = 577 / 408 ∧
    (577 / 408 : ℚ) / 2 + 1 / (577 / 408) = 665857 / 470832 := by norm_num
-- Its square misses 2 by 1/221682772224.
example : (665857 / 470832 : ℚ) ^ 2 - 2 = 1 / 221682772224 := by norm_num

#print axioms contraction_has_unique_fixed_point_reached_by_iteration
#print axioms contraction_last_step_bound
#print axioms continuous_curves_complete_under_worst_gap
