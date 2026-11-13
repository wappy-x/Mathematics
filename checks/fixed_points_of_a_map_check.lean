-- Fixed points of a map: near a fixed point of a map with a continuous slope, a slope smaller than 1 in size pulls every nearby start in, and a slope larger than 1 in size pushes every nearby start other than the point itself out of a window; the moth rule r x (1 - x) has fixed points 0 and 1 - 1/r with slopes r and 2 - r.
import Mathlib.Analysis.Calculus.ContDiff.RCLike
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum

/-! Setting, in the card's notation.
* A map is a function `g : ℝ → ℝ`; summer `n` of the orbit from `x₀` is `g^[n] x₀`
  (`g` applied `n` times).
* A fixed point `xs` (the card's `x*`) has `g xs = xs`.
* "The slope exists and changes smoothly near `x*`" is `ContDiffAt ℝ 1 g xs`: `g` has a
  derivative on some interval round `xs`, and that derivative is continuous at `xs`.
* The slope at the fixed point is `deriv g xs`.
* "The state is one number" is built in: the map acts on `ℝ`.
* The moth rule is `g x = r * x * (1 - x)`. -/

open Filter Topology

namespace FixedPointsOfAMap

/-- Near a fixed point with derivative `d`, the map is `d`-linear up to an error `ε` times the gap. -/
theorem local_linear_bound_at_fixed_point
    (g : ℝ → ℝ) (xs d : ℝ) (hfix : g xs = xs) (hd : HasDerivAt g d xs) (ε : ℝ) (hε : 0 < ε) :
    ∃ δ > 0, ∀ x : ℝ, |x - xs| ≤ δ → |g x - xs - d * (x - xs)| ≤ ε * |x - xs| := by
  have h := (hasDerivAt_iff_isLittleO.mp hd).def hε
  obtain ⟨η, hη, hball⟩ := Metric.eventually_nhds_iff.mp h
  refine ⟨η / 2, by positivity, fun x hx => ?_⟩
  have hdist : dist x xs < η := by
    rw [Real.dist_eq]; linarith
  have := hball hdist
  simp only [Real.norm_eq_abs, smul_eq_mul, hfix] at this
  rwa [mul_comm (x - xs) d] at this

#print axioms local_linear_bound_at_fixed_point

/-- **A slope smaller than 1 in size pulls nearby points in.** Let `xs` be a fixed point of a
map `g` whose slope exists and is continuous near `xs`, with `|g'(xs)| < 1`. Then there is a
window of half-width `δ > 0` round `xs` and a factor `L` with `0 ≤ L < 1` such that every start
`x₀` in the window has its gap after `n` summers at most `Lⁿ` times the first gap, so the orbit
converges to `xs`. -/
theorem fixed_point_attracts_when_slope_smaller_than_one
    (g : ℝ → ℝ) (xs : ℝ) (hfix : g xs = xs) (hsmooth : ContDiffAt ℝ 1 g xs)
    (hslope : |deriv g xs| < 1) :
    ∃ δ > 0, ∃ L : ℝ, 0 ≤ L ∧ L < 1 ∧ ∀ x₀ : ℝ, |x₀ - xs| ≤ δ →
      (∀ n : ℕ, |g^[n] x₀ - xs| ≤ L ^ n * |x₀ - xs|) ∧
      Tendsto (fun n : ℕ => g^[n] x₀) atTop (𝓝 xs) := by
  have hd : HasDerivAt g (deriv g xs) xs := (hsmooth.differentiableAt (by norm_num)).hasDerivAt
  set d := deriv g xs
  obtain ⟨δ, hδ, hb⟩ := local_linear_bound_at_fixed_point g xs d hfix hd ((1 - |d|) / 2)
    (by linarith)
  set L := |d| + (1 - |d|) / 2 with hL
  have hL0 : 0 ≤ L := by have := abs_nonneg d; linarith
  have hL1 : L < 1 := by linarith
  have step : ∀ x, |x - xs| ≤ δ → |g x - xs| ≤ L * |x - xs| := by
    intro x hx
    have h1 := hb x hx
    have h2 : |g x - xs| ≤ |g x - xs - d * (x - xs)| + |d * (x - xs)| := by
      have := abs_add_le (g x - xs - d * (x - xs)) (d * (x - xs))
      simpa using this
    rw [abs_mul] at h2
    rw [hL]; nlinarith [abs_nonneg (x - xs)]
  refine ⟨δ, hδ, L, hL0, hL1, fun x₀ hx₀ => ?_⟩
  have key : ∀ n : ℕ, |g^[n] x₀ - xs| ≤ L ^ n * |x₀ - xs| := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      have hin : |g^[n] x₀ - xs| ≤ δ := by
        have : L ^ n ≤ 1 := pow_le_one₀ hL0 hL1.le
        have := mul_le_mul_of_nonneg_right this (abs_nonneg (x₀ - xs))
        linarith
      rw [Function.iterate_succ_apply']
      calc |g (g^[n] x₀) - xs| ≤ L * |g^[n] x₀ - xs| := step _ hin
        _ ≤ L * (L ^ n * |x₀ - xs|) := mul_le_mul_of_nonneg_left ih hL0
        _ = L ^ (n + 1) * |x₀ - xs| := by ring
  refine ⟨key, ?_⟩
  rw [tendsto_iff_norm_sub_tendsto_zero]
  refine squeeze_zero (fun n => norm_nonneg _) (fun n => by simpa [Real.norm_eq_abs] using key n) ?_
  simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hL0 hL1).mul_const |x₀ - xs|

/-- **A slope larger than 1 in size pushes nearby points away.** Let `xs` be a fixed point of a
map `g` whose slope exists and is continuous near `xs`, with `|g'(xs)| > 1`. Then there is a
window of half-width `δ > 0` round `xs` that every orbit starting anywhere other than `xs`
itself eventually leaves: some summer `n` has the gap `|g^[n] x₀ - xs|` larger than `δ`. -/
theorem fixed_point_repels_when_slope_larger_than_one
    (g : ℝ → ℝ) (xs : ℝ) (hfix : g xs = xs) (hsmooth : ContDiffAt ℝ 1 g xs)
    (hslope : 1 < |deriv g xs|) :
    ∃ δ > 0, ∀ x₀ : ℝ, x₀ ≠ xs → ∃ n : ℕ, δ < |g^[n] x₀ - xs| := by
  have hd : HasDerivAt g (deriv g xs) xs := (hsmooth.differentiableAt (by norm_num)).hasDerivAt
  set d := deriv g xs
  obtain ⟨δ, hδ, hb⟩ := local_linear_bound_at_fixed_point g xs d hfix hd ((|d| - 1) / 2)
    (by linarith)
  set K := |d| - (|d| - 1) / 2 with hK
  have hK1 : 1 < K := by linarith
  have hK0 : 0 ≤ K := by linarith
  have step : ∀ x, |x - xs| ≤ δ → K * |x - xs| ≤ |g x - xs| := by
    intro x hx
    have h1 := hb x hx
    have h2 : |d * (x - xs)| ≤ |g x - xs| + |g x - xs - d * (x - xs)| := by
      have := abs_sub_le (d * (x - xs)) (g x - xs) 0
      have e1 : |d * (x - xs) - (g x - xs)| = |g x - xs - d * (x - xs)| := abs_sub_comm _ _
      simp only [sub_zero] at this
      rw [e1] at this
      linarith [abs_neg (g x - xs)]
    rw [abs_mul] at h2
    rw [hK]; nlinarith [abs_nonneg (x - xs)]
  refine ⟨δ, hδ, fun x₀ hx₀ => ?_⟩
  by_contra hcon
  push Not at hcon
  have key : ∀ n : ℕ, K ^ n * |x₀ - xs| ≤ |g^[n] x₀ - xs| := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [Function.iterate_succ_apply']
      calc K ^ (n + 1) * |x₀ - xs| = K * (K ^ n * |x₀ - xs|) := by ring
        _ ≤ K * |g^[n] x₀ - xs| := mul_le_mul_of_nonneg_left ih hK0
        _ ≤ |g (g^[n] x₀) - xs| := step _ (hcon n)
  have hpos : 0 < |x₀ - xs| := abs_pos.mpr (sub_ne_zero.mpr hx₀)
  obtain ⟨n, hn⟩ := pow_unbounded_of_one_lt (δ / |x₀ - xs|) hK1
  have : δ < K ^ n * |x₀ - xs| := by
    rwa [div_lt_iff₀ hpos] at hn
  linarith [key n, hcon n]

/-- **The moth rule's fixed points and their slopes.** For a breeding factor `r ≠ 0`, the
logistic map `g(x) = r x (1 - x)` sends `x` to itself exactly when `x = 0` or `x = 1 - 1/r`; its
slope is `r` at 0 and `2 - r` at `1 - 1/r`; and that slope is smaller than 1 in size exactly
when `r` lies between 1 and 3, so the living fixed point attracts for those `r`. -/
theorem logistic_fixed_points_and_slopes (r : ℝ) (hr : r ≠ 0) :
    (∀ x : ℝ, r * x * (1 - x) = x ↔ x = 0 ∨ x = 1 - 1 / r) ∧
    deriv (fun x : ℝ => r * x * (1 - x)) 0 = r ∧
    deriv (fun x : ℝ => r * x * (1 - x)) (1 - 1 / r) = 2 - r ∧
    (|2 - r| < 1 ↔ 1 < r ∧ r < 3) := by
  have hderiv : ∀ x : ℝ, deriv (fun x : ℝ => r * x * (1 - x)) x = r * (1 - 2 * x) := by
    intro x
    have h' : HasDerivAt (fun y : ℝ => r * y * (1 - y)) (r * 1 * (1 - x) + r * x * (0 - 1)) x :=
      ((hasDerivAt_id' x).const_mul r).mul ((hasDerivAt_const x (1 : ℝ)).sub (hasDerivAt_id' x))
    rw [h'.deriv]; ring
  refine ⟨fun x => ?_, ?_, ?_, ?_⟩
  · constructor
    · intro h
      have : x * (r * (1 - x) - 1) = 0 := by linear_combination h
      rcases mul_eq_zero.mp this with h0 | h1
      · exact Or.inl h0
      · right
        field_simp
        linear_combination -h1
    · rintro (h | h)
      · subst h; ring
      · subst h; field_simp; ring
  · rw [hderiv]; ring
  · rw [hderiv]; field_simp; ring
  · rw [abs_lt]; constructor <;> rintro ⟨h1, h2⟩ <;> constructor <;> linarith

/-! The card's worked numbers, as exact fractions (2.8 = 14/5, 3.2 = 16/5, 0.2 = 1/5). -/

-- One summer from 0.2 at breeding factor 2.8: 2.8 × 0.2 × 0.8 = 0.448.
example : (14 / 5 : ℚ) * (1 / 5) * (1 - 1 / 5) = 56 / 125 := by norm_num

-- At 2.8 the living fixed point is 1 - 1/2.8 = 9/14 (0.642857), and the map sends it to itself.
example : (1 : ℚ) - 1 / (14 / 5) = 9 / 14 ∧ (14 / 5 : ℚ) * (9 / 14) * (1 - 9 / 14) = 9 / 14 := by
  norm_num

-- Its slope r(1 - 2x*) is 2 - 2.8 = -0.8.
example : (14 / 5 : ℚ) * (1 - 2 * (9 / 14)) = -4 / 5 ∧ (2 : ℚ) - 14 / 5 = -4 / 5 := by norm_num

-- At 3.2 the fixed point is 1 - 1/3.2 = 0.6875, a fixed point, with slope 2 - 3.2 = -1.2.
example : (1 : ℚ) - 1 / (16 / 5) = 11 / 16 ∧ (16 / 5 : ℚ) * (11 / 16) * (1 - 11 / 16) = 11 / 16 ∧
    (16 / 5 : ℚ) * (1 - 2 * (11 / 16)) = -6 / 5 := by
  norm_num

-- The slope bound on the window ±0.02 at 2.8: 0.8 + 2 × 2.8 × 0.02 = 0.912.
example : (4 / 5 : ℚ) + 2 * (14 / 5) * (1 / 50) = 114 / 125 := by norm_num

-- The exact one-summer gap g(x* + e) - x* = (2 - r)e - re², for every r ≠ 0 and every gap e.
example (r e : ℚ) (hr : r ≠ 0) :
    r * (1 - 1 / r + e) * (1 - (1 - 1 / r + e)) - (1 - 1 / r) = (2 - r) * e - r * e ^ 2 := by
  field_simp
  ring

-- At 2.8 a gap of 0.02 becomes -0.8 × 0.02 - 2.8 × 0.0004 = -0.01712.
example : (14 / 5 : ℚ) * (9 / 14 + 1 / 50) * (1 - (9 / 14 + 1 / 50)) - 9 / 14 = -107 / 6250 ∧
    (-4 / 5 : ℚ) * (1 / 50) - (14 / 5) * (1 / 50) ^ 2 = -107 / 6250 := by
  norm_num

-- The usual mistake: the slope read at the start 0.2 instead of x*: 2.8 × (1 - 0.4) = 1.68.
example : (14 / 5 : ℚ) * (1 - 2 * (1 / 5)) = 42 / 25 := by norm_num

-- Euler's map x + hF(x) for F(x) = x(1 - x) has slope 1 - h at 1: -0.8 for h = 1.8, -1.2 for 2.2.
example : (1 : ℚ) - 9 / 5 = -4 / 5 ∧ (1 : ℚ) - 11 / 5 = -6 / 5 := by norm_num

-- Newton's map x/2 + 1/x for x² = 2 has slope 1/2 - 1/x² = 0 at √2, and √2 is its fixed point.
example : (1 : ℝ) / 2 - 1 / Real.sqrt 2 ^ 2 = 0 ∧
    Real.sqrt 2 / 2 + 1 / Real.sqrt 2 = Real.sqrt 2 := by
  have h : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have h0 : Real.sqrt 2 ≠ 0 := by positivity
  refine ⟨by norm_num [h], ?_⟩
  field_simp
  norm_num [h]

#print axioms fixed_point_attracts_when_slope_smaller_than_one
#print axioms fixed_point_repels_when_slope_larger_than_one
#print axioms logistic_fixed_points_and_slopes

end FixedPointsOfAMap
