-- The derivative: Mathlib's derivative of a real function at a point is exactly the limit of the average rates (f(a + h) - f(a)) / h as the window h heads for 0, a function with such a limit is continuous there, and the car's odometer 2t^2 has speed 4a at every instant a.
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul

open Filter Topology

/-- The derivative is the limit of average rates over shrinking windows. A real function f has
derivative L at the point a exactly when the average rate (f(a + h) - f(a)) / h heads for L as the
window h heads for 0 from either side, never equal to 0. The limit must be a single finite number,
the same from both sides. -/
theorem derivative_is_limit_of_average_rates (f : ℝ → ℝ) (a L : ℝ) :
    HasDerivAt f L a ↔ Tendsto (fun h : ℝ => (f (a + h) - f a) / h) (𝓝[≠] 0) (𝓝 L) := by
  rw [hasDerivAt_iff_tendsto_slope_zero]
  simp only [smul_eq_mul, inv_mul_eq_div]

/-- A derivative forces continuity. If the average rates of f at a head for a finite number L as
the window shrinks, then f(x) heads for f(a) as x heads for a: f is continuous at a. -/
theorem average_rates_converge_implies_continuous (f : ℝ → ℝ) (a L : ℝ)
    (hf : Tendsto (fun h : ℝ => (f (a + h) - f a) / h) (𝓝[≠] 0) (𝓝 L)) :
    ContinuousAt f a := by
  exact ((derivative_is_limit_of_average_rates f a L).2 hf).continuousAt

/-- The car. Its odometer reads s(t) = 2t^2 metres at t seconds. At every instant a, the average
speed over a window of h seconds is 4a + 2h, so the averages head for 4a: the speed at a is 4a
metres per second (20 m/s at 5 s, 8 m/s at 2 s). -/
theorem car_speed_is_four_a (a : ℝ) :
    Tendsto (fun h : ℝ => (2 * (a + h) ^ 2 - 2 * a ^ 2) / h) (𝓝[≠] 0) (𝓝 (4 * a)) := by
  have hd : HasDerivAt (fun t : ℝ => 2 * t ^ 2) (4 * a) a := by
    have h2 : HasDerivAt (fun x : ℝ => x ^ 2) ((2 : ℕ) * a ^ (2 - 1)) a := hasDerivAt_pow 2 a
    have := HasDerivAt.const_mul (2 : ℝ) h2
    convert this using 1
    push_cast
    ring
  exact (derivative_is_limit_of_average_rates (fun t : ℝ => 2 * t ^ 2) a (4 * a)).1 hd

-- The odometer readings: 50 m at 5 s, 72 m at 6 s.
example : (2 * 5 * 5 : ℤ) = 50 ∧ (2 * 6 * 6 : ℤ) = 72 := by decide
-- Readings at 0 to 6 s, and the metres covered in each second.
example : (List.range 7).map (fun t : ℕ => 2 * t * t) = [0, 2, 8, 18, 32, 50, 72] := by decide
example : (List.range 6).map (fun k : ℕ => 2 * (k + 1) * (k + 1) - 2 * k * k)
    = [2, 6, 10, 14, 18, 22] := by decide
-- One-second windows: 22 m/s after 5 s (h = 1) and 18 m/s before it (h = -1), each 20 + 2h.
example : ((2 * 6 * 6 - 2 * 5 * 5 : ℚ) / 1) = 20 + 2 * 1 := by norm_num
example : ((2 * 4 * 4 - 2 * 5 * 5 : ℚ) / (-1)) = 20 + 2 * (-1) := by norm_num
-- Whole-second readings: the mean of the fifth and sixth seconds is 20 m/s.
example : ((18 + 22) / 2 : ℚ) = 20 := by norm_num
-- 20 m/s is 72 km/h; the speed at 2 s is 4 × 2 = 8 m/s.
example : (20 * 3600 / 1000 : ℚ) = 72 ∧ (4 * 2 : ℤ) = 8 := by norm_num
-- The usual mistakes: the whole-trip average is 50 m over 5 s = 10 m/s, half the true 20.
example : (50 / 5 : ℚ) = 10 ∧ (10 : ℚ) * 2 = 20 := by norm_num

#print axioms derivative_is_limit_of_average_rates
#print axioms average_rates_converge_implies_continuous
#print axioms car_speed_is_four_a
