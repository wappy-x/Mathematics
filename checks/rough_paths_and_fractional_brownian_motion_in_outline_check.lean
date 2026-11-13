-- Rougher than Brownian: moves whose second moment is the gap to the power 2H force the fractional Brownian covariance, neighbouring unit moves are negatively correlated below H = 1/2 and positively above, and left- and right-point sums of a path against its own moves differ from half its final square by half the summed squared moves.
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Nat.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.Analysis.Convex.SpecificFunctions.Basic
import Mathlib.Analysis.Convex.SpecificFunctions.Pow

open MeasureTheory Finset

/-- The covariance is forced (Step 1). Let H lie strictly between 0 and 1. Let B be a process
on a probability space that starts at 0, has square-integrable values at every time t at least
0, and whose move over any gap has mean square equal to the gap to the power 2H. Then for all
times s, t at least 0 the mean of B at s times B at t is half of: s to the power 2H, plus t to the
power 2H, minus the gap between them to the power 2H. (The card assumes B is Gaussian; the
computation does not use it, so it is not assumed here.) -/
theorem fbm_covariance_forced_by_stationary_moves {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (H : ℝ) (hH0 : 0 < H) (hH1 : H < 1)
    (B : ℝ → Ω → ℝ) (hB0 : ∀ ω, B 0 ω = 0)
    (hL2 : ∀ t : ℝ, 0 ≤ t → MemLp (B t) 2 μ)
    (hmove : ∀ s t : ℝ, 0 ≤ s → 0 ≤ t →
      ∫ ω, (B t ω - B s ω) ^ 2 ∂μ = |t - s| ^ (2 * H)) :
    ∀ s t : ℝ, 0 ≤ s → 0 ≤ t →
      ∫ ω, B s ω * B t ω ∂μ = 1 / 2 * (s ^ (2 * H) + t ^ (2 * H) - |t - s| ^ (2 * H)) := by
  intro s t hs ht
  have hBs : MemLp (B s) 2 μ := hL2 s hs
  have hBt : MemLp (B t) 2 μ := hL2 t ht
  have hd : MemLp (fun ω => B t ω - B s ω) 2 μ := hBt.sub hBs
  have is := MemLp.integrable_sq hBs
  have it := MemLp.integrable_sq hBt
  have ist : Integrable (fun ω => B s ω ^ 2 + B t ω ^ 2) μ := is.add it
  have id := MemLp.integrable_sq hd
  have hs2 : ∫ ω, B s ω ^ 2 ∂μ = s ^ (2 * H) := by
    have := hmove 0 s le_rfl hs
    simpa [hB0, abs_of_nonneg hs] using this
  have ht2 : ∫ ω, B t ω ^ 2 ∂μ = t ^ (2 * H) := by
    have := hmove 0 t le_rfl ht
    simpa [hB0, abs_of_nonneg ht] using this
  have hst := hmove s t hs ht
  have key : (fun ω => B s ω * B t ω) =
      fun ω => 1 / 2 * ((B s ω ^ 2 + B t ω ^ 2) - (B t ω - B s ω) ^ 2) := by
    funext ω; ring
  rw [key, integral_const_mul, integral_sub ist id, integral_add is it, hs2, ht2, hst]

/-- The sign of the increment correlation follows H (Step 3). For H strictly between 0 and 1
and every whole number n at least 1, the correlation of two unit moves n steps apart,
rho(n) = 1/2 ((n+1)^(2H) - 2 n^(2H) + (n-1)^(2H)), is negative when H is below 1/2, zero when
H is 1/2, and positive when H is above 1/2. -/
theorem fbm_increment_correlation_sign (H : ℝ) (hH0 : 0 < H) (hH1 : H < 1)
    (n : ℕ) (hn : 1 ≤ n) :
    let ρ : ℝ := 1 / 2 * (((n : ℝ) + 1) ^ (2 * H) - 2 * (n : ℝ) ^ (2 * H)
      + ((n : ℝ) - 1) ^ (2 * H))
    (H < 1 / 2 → ρ < 0) ∧ (H = 1 / 2 → ρ = 0) ∧ (1 / 2 < H → 0 < ρ) := by
  intro ρ
  have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have hx : (0 : ℝ) ≤ (n : ℝ) - 1 := by linarith
  have hy : (0 : ℝ) ≤ (n : ℝ) + 1 := by linarith
  have hxy : (n : ℝ) - 1 ≠ (n : ℝ) + 1 := by intro h; linarith
  have hmid : (1 / 2 : ℝ) • ((n : ℝ) - 1) + (1 / 2 : ℝ) • ((n : ℝ) + 1) = n := by
    simp only [smul_eq_mul]; ring
  refine ⟨fun hH => ?_, fun hH => ?_, fun hH => ?_⟩
  · have hc := (Real.strictConcaveOn_rpow (p := 2 * H) (by linarith) (by linarith)).2
      (Set.mem_Ici.2 hx) (Set.mem_Ici.2 hy) hxy (by norm_num : (0 : ℝ) < 1 / 2)
      (by norm_num : (0 : ℝ) < 1 / 2) (by norm_num)
    simp only [smul_eq_mul] at hc hmid
    rw [hmid] at hc
    show 1 / 2 * (((n : ℝ) + 1) ^ (2 * H) - 2 * (n : ℝ) ^ (2 * H)
      + ((n : ℝ) - 1) ^ (2 * H)) < 0
    linarith
  · have h2 : 2 * H = 1 := by linarith
    show 1 / 2 * (((n : ℝ) + 1) ^ (2 * H) - 2 * (n : ℝ) ^ (2 * H)
      + ((n : ℝ) - 1) ^ (2 * H)) = 0
    rw [h2]; simp only [Real.rpow_one]; ring
  · have hc := (strictConvexOn_rpow (p := 2 * H) (by linarith)).2
      (Set.mem_Ici.2 hx) (Set.mem_Ici.2 hy) hxy (by norm_num : (0 : ℝ) < 1 / 2)
      (by norm_num : (0 : ℝ) < 1 / 2) (by norm_num)
    simp only [smul_eq_mul] at hc hmid
    rw [hmid] at hc
    show 0 < 1 / 2 * (((n : ℝ) + 1) ^ (2 * H) - 2 * (n : ℝ) ^ (2 * H)
      + ((n : ℝ) - 1) ^ (2 * H))
    linarith

/-- Left- and right-point sums part company (Step 5). For any path x on a grid of m steps
that starts at 0, path by path, the left-point sum of x against its own moves is half of: x at
the end squared, minus the sum of squared moves; the right-point sum is half of: x at the end
squared, plus the sum of squared moves. -/
theorem left_right_point_sums_differ_by_squared_moves (x : ℕ → ℝ) (hx0 : x 0 = 0) (m : ℕ) :
    (∑ i ∈ range m, x i * (x (i + 1) - x i)
        = 1 / 2 * (x m ^ 2 - ∑ i ∈ range m, (x (i + 1) - x i) ^ 2)) ∧
    (∑ i ∈ range m, x (i + 1) * (x (i + 1) - x i)
        = 1 / 2 * (x m ^ 2 + ∑ i ∈ range m, (x (i + 1) - x i) ^ 2)) := by
  have h1 : ∀ m : ℕ, ∑ i ∈ range m, x i * (x (i + 1) - x i)
      = 1 / 2 * (x m ^ 2 - ∑ i ∈ range m, (x (i + 1) - x i) ^ 2) := by
    intro m
    induction m with
    | zero => simp [hx0]
    | succ k ih => rw [sum_range_succ, sum_range_succ, ih]; ring
  have h2 : ∀ m : ℕ, ∑ i ∈ range m, x (i + 1) * (x (i + 1) - x i)
      = 1 / 2 * (x m ^ 2 + ∑ i ∈ range m, (x (i + 1) - x i) ^ 2) := by
    intro m
    induction m with
    | zero => simp [hx0]
    | succ k ih => rw [sum_range_succ, sum_range_succ, ih]; ring
  exact ⟨h1 m, h2 m⟩

-- Worked numbers. The square root of 1,024 trading days is 32.
example : Nat.sqrt 1024 = 32 := by rw [show (1024 : ℕ) = 32 ^ 2 by norm_num, Nat.sqrt_eq']
-- 1,024 to the power 1/10 is 2, because 2 to the power 10 is 1,024.
example : (2 : ℕ) ^ 10 = 1024 := by norm_num
-- Brownian spread over 1,024 days: 3/10 times 32 is 48/5, that is 9.6.
example : (3 / 10 : ℚ) * 32 = 48 / 5 := by norm_num
-- Rough spread over 1,024 days: 3/10 times 2 is 3/5, that is 0.6.
example : (3 / 10 : ℚ) * 2 = 3 / 5 := by norm_num
-- Sum of squared moves on the 1-day grid: (3/10)^2 times 64 is 144/25, that is 5.76.
example : (3 / 10 : ℚ) ^ 2 * 64 = 144 / 25 := by norm_num

#print axioms fbm_covariance_forced_by_stationary_moves
#print axioms fbm_increment_correlation_sign
#print axioms left_right_point_sums_differ_by_squared_moves
