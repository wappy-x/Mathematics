-- The Hopf bifurcation: in the normal form r' = d mu r + a r^3 the sign of a decides between a stable cycle of radius sqrt(-d mu / a) and runaway growth, the model r' = mu r + r^3 - r^5 has a stable big cycle from mu = -1/4 on (hysteresis), and the Brusselator's Hopf point is B = 2 with the exact cubic form used for a.
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation

open Real

/-- The quadratic `μ + t - t^2` factors through its two roots `(1 ± √(1 + 4μ))/2`. -/
theorem quintic_factor (μ t : ℝ) (hμ : -1 / 4 ≤ μ) :
    μ + t - t ^ 2 = -((t - (1 + √(1 + 4 * μ)) / 2) * (t - (1 - √(1 + 4 * μ)) / 2)) := by
  have hq2 := Real.sq_sqrt (show (0 : ℝ) ≤ 1 + 4 * μ by linarith)
  linear_combination (-1 / 4 : ℝ) * hq2

#print axioms quintic_factor

/-- The cubic coefficient decides. Take the normal form `r' = d μ r + a r^3` with dial speed
`d ≠ 0` and cubic coefficient `a ≠ 0`. A cycle is a radius `s > 0` where the rate is zero.
1. A cycle exists exactly when `-d μ / a > 0`, and then it is the single radius `√(-d μ / a)`.
2. There the rate's slope is `-2 d μ`.
3. If `a < 0` (supercritical) and `d μ > 0`, smaller swings grow and larger swings shrink, so
   every swing settles onto the cycle: a stable cycle of radius `√(-d μ / a)`, growing like `√μ`.
   If `a < 0` and `d μ ≤ 0`, every swing dies away.
4. If `a > 0` (subcritical) and `d μ > 0`, there is no cycle and every swing grows: nothing small
   holds the state. If `a > 0` and `d μ < 0`, the cycle repels on both sides (unstable). -/
theorem hopf_cubic_coefficient_decides (d μ a : ℝ) (hd : d ≠ 0) (ha : a ≠ 0) :
    (∀ s : ℝ, 0 < s →
      (d * μ * s + a * s ^ 3 = 0 ↔ 0 < -(d * μ) / a ∧ s = √(-(d * μ) / a))) ∧
    (0 < -(d * μ) / a →
      HasDerivAt (fun r : ℝ => d * μ * r + a * r ^ 3) (-2 * (d * μ)) (√(-(d * μ) / a))) ∧
    (a < 0 → 0 < d * μ →
      (∀ s : ℝ, 0 < s → s < √(-(d * μ) / a) → 0 < d * μ * s + a * s ^ 3) ∧
      (∀ s : ℝ, √(-(d * μ) / a) < s → d * μ * s + a * s ^ 3 < 0)) ∧
    (a < 0 → d * μ ≤ 0 → ∀ s : ℝ, 0 < s → d * μ * s + a * s ^ 3 < 0) ∧
    (0 < a → 0 < d * μ → ∀ s : ℝ, 0 < s → 0 < d * μ * s + a * s ^ 3) ∧
    (0 < a → d * μ < 0 →
      (∀ s : ℝ, 0 < s → s < √(-(d * μ) / a) → d * μ * s + a * s ^ 3 < 0) ∧
      (∀ s : ℝ, √(-(d * μ) / a) < s → 0 < d * μ * s + a * s ^ 3)) := by
  have hac : a * (-(d * μ) / a) = -(d * μ) := by field_simp
  have key : ∀ s : ℝ, d * μ * s + a * s ^ 3 = a * s * (s ^ 2 - (-(d * μ) / a)) := by
    intro s; linear_combination s * hac
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro s hs
    rw [key]
    constructor
    · intro h
      have h1 : s ^ 2 - (-(d * μ) / a) = 0 := by
        rcases mul_eq_zero.mp h with h2 | h2
        · exact absurd h2 (mul_ne_zero ha hs.ne')
        · exact h2
      have hc0 : 0 < -(d * μ) / a := by nlinarith [pow_pos hs 2]
      refine ⟨hc0, ?_⟩
      rw [← Real.sqrt_sq hs.le]; congr 1; linarith
    · rintro ⟨hc0, rfl⟩
      rw [Real.sq_sqrt hc0.le]; ring
  · intro hc0
    have hs2 := Real.sq_sqrt hc0.le
    obtain ⟨r, hr⟩ : ∃ r, r = √(-(d * μ) / a) := ⟨_, rfl⟩
    rw [← hr] at hs2 ⊢
    refine HasDerivAt.congr_deriv (HasDerivAt.add (HasDerivAt.const_mul (d * μ) (hasDerivAt_id' r))
      (HasDerivAt.const_mul a (hasDerivAt_pow 3 r))) ?_
    norm_num
    rw [hs2]
    linear_combination 3 * hac
  · intro ha' hdm
    have hc0 : 0 < -(d * μ) / a := div_pos_of_neg_of_neg (by linarith) ha'
    constructor
    · intro s hs hlt
      have ht : s ^ 2 < -(d * μ) / a := (Real.lt_sqrt hs.le).mp hlt
      rw [key]
      exact mul_pos_of_neg_of_neg (mul_neg_of_neg_of_pos ha' hs) (by linarith)
    · intro s hlt
      have hs : 0 < s := lt_of_le_of_lt (Real.sqrt_nonneg _) hlt
      have ht : -(d * μ) / a < s ^ 2 := (Real.sqrt_lt' hs).mp hlt
      rw [key]
      exact mul_neg_of_neg_of_pos (mul_neg_of_neg_of_pos ha' hs) (by linarith)
  · intro ha' hdm s hs
    have h1 : d * μ * s ≤ 0 := mul_nonpos_of_nonpos_of_nonneg hdm hs.le
    have h2 : a * s ^ 3 < 0 := mul_neg_of_neg_of_pos ha' (pow_pos hs 3)
    linarith
  · intro ha' hdm s hs
    have h1 : 0 < d * μ * s := mul_pos hdm hs
    have h2 : 0 < a * s ^ 3 := mul_pos ha' (pow_pos hs 3)
    linarith
  · intro ha' hdm
    have hc0 : 0 < -(d * μ) / a := div_pos (by linarith) ha'
    constructor
    · intro s hs hlt
      have ht : s ^ 2 < -(d * μ) / a := (Real.lt_sqrt hs.le).mp hlt
      rw [key]
      exact mul_neg_of_pos_of_neg (mul_pos ha' hs) (by linarith)
    · intro s hlt
      have hs : 0 < s := lt_of_le_of_lt (Real.sqrt_nonneg _) hlt
      have ht : -(d * μ) / a < s ^ 2 := (Real.sqrt_lt' hs).mp hlt
      rw [key]
      exact mul_pos (mul_pos ha' hs) (by linarith)

/-- The sudden case and its hysteresis. For `r' = μ r + r^3 - r^5` put
`R₊ = (1 + √(1 + 4μ))/2` and `R₋ = (1 - √(1 + 4μ))/2` (the two roots of `μ + R - R^2 = 0`).
1. Below `μ = -1/4` there is no cycle: every swing dies away.
2. From `μ = -1/4` on, the big cycle of radius `√R₊` exists and every larger swing shrinks onto it;
   for `μ > -1/4` the slope there is `2 R₊ (1 - 2 R₊) < 0`, so it is stable.
3. For `-1/4 < μ < 0` the rest is fenced by the small cycle `√R₋`, which lies inside the big one:
   swings below it die, swings between the two grow to the big cycle. So the rest and the big
   swing are both stable there, and which one the state shows depends on its history.
4. For `μ > 0` every swing below the big cycle grows to it: the state jumps to the big swing. -/
theorem subcritical_quintic_hysteresis (μ : ℝ) :
    (μ < -1 / 4 → ∀ s : ℝ, 0 < s → μ * s + s ^ 3 - s ^ 5 < 0) ∧
    (-1 / 4 ≤ μ →
      0 < √((1 + √(1 + 4 * μ)) / 2) ∧
      μ * √((1 + √(1 + 4 * μ)) / 2) + √((1 + √(1 + 4 * μ)) / 2) ^ 3
        - √((1 + √(1 + 4 * μ)) / 2) ^ 5 = 0 ∧
      ∀ s : ℝ, √((1 + √(1 + 4 * μ)) / 2) < s → μ * s + s ^ 3 - s ^ 5 < 0) ∧
    (-1 / 4 < μ →
      HasDerivAt (fun r : ℝ => μ * r + r ^ 3 - r ^ 5)
        (2 * ((1 + √(1 + 4 * μ)) / 2) * (1 - 2 * ((1 + √(1 + 4 * μ)) / 2)))
        (√((1 + √(1 + 4 * μ)) / 2)) ∧
      2 * ((1 + √(1 + 4 * μ)) / 2) * (1 - 2 * ((1 + √(1 + 4 * μ)) / 2)) < 0) ∧
    (-1 / 4 < μ → μ < 0 →
      0 < √((1 - √(1 + 4 * μ)) / 2) ∧
      √((1 - √(1 + 4 * μ)) / 2) < √((1 + √(1 + 4 * μ)) / 2) ∧
      μ * √((1 - √(1 + 4 * μ)) / 2) + √((1 - √(1 + 4 * μ)) / 2) ^ 3
        - √((1 - √(1 + 4 * μ)) / 2) ^ 5 = 0 ∧
      (∀ s : ℝ, 0 < s → s < √((1 - √(1 + 4 * μ)) / 2) → μ * s + s ^ 3 - s ^ 5 < 0) ∧
      (∀ s : ℝ, √((1 - √(1 + 4 * μ)) / 2) < s → s < √((1 + √(1 + 4 * μ)) / 2) →
        0 < μ * s + s ^ 3 - s ^ 5)) ∧
    (0 < μ → ∀ s : ℝ, 0 < s → s < √((1 + √(1 + 4 * μ)) / 2) → 0 < μ * s + s ^ 3 - s ^ 5) := by
  have hf : ∀ s : ℝ, μ * s + s ^ 3 - s ^ 5 = s * (μ + s ^ 2 - (s ^ 2) ^ 2) := fun s => by ring
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · intro hμ s hs
    rw [hf]
    apply mul_neg_of_pos_of_neg hs
    nlinarith [sq_nonneg (s ^ 2 - 1 / 2)]
  · intro hμ
    have hq0 : 0 ≤ √(1 + 4 * μ) := Real.sqrt_nonneg _
    have hRp : 0 < (1 + √(1 + 4 * μ)) / 2 := by linarith
    have hs2 := Real.sq_sqrt hRp.le
    refine ⟨Real.sqrt_pos.mpr hRp, ?_, ?_⟩
    · rw [hf, hs2, quintic_factor μ _ hμ]; ring
    · intro s hlt
      have hs : 0 < s := lt_of_le_of_lt (Real.sqrt_nonneg _) hlt
      have ht : (1 + √(1 + 4 * μ)) / 2 < s ^ 2 := (Real.sqrt_lt' hs).mp hlt
      rw [hf, quintic_factor μ _ hμ]
      apply mul_neg_of_pos_of_neg hs
      have : 0 < (s ^ 2 - (1 + √(1 + 4 * μ)) / 2) * (s ^ 2 - (1 - √(1 + 4 * μ)) / 2) :=
        mul_pos (by linarith) (by linarith)
      linarith
  · intro hμ
    have hq0 : 0 < √(1 + 4 * μ) := Real.sqrt_pos.mpr (by linarith)
    have hRp : 0 < (1 + √(1 + 4 * μ)) / 2 := by linarith
    have hs2 := Real.sq_sqrt hRp.le
    have hz := quintic_factor μ ((1 + √(1 + 4 * μ)) / 2) hμ.le
    have hz' : μ + (1 + √(1 + 4 * μ)) / 2 - ((1 + √(1 + 4 * μ)) / 2) ^ 2 = 0 := by
      rw [hz]; ring
    refine ⟨?_, ?_⟩
    · obtain ⟨r, hr⟩ : ∃ r, r = √((1 + √(1 + 4 * μ)) / 2) := ⟨_, rfl⟩
      rw [← hr] at hs2 ⊢
      obtain ⟨R, hR⟩ : ∃ R, R = (1 + √(1 + 4 * μ)) / 2 := ⟨_, rfl⟩
      rw [← hR] at hs2 hz' ⊢
      refine HasDerivAt.congr_deriv
        (HasDerivAt.sub (HasDerivAt.add (HasDerivAt.const_mul μ (hasDerivAt_id' r)) (hasDerivAt_pow 3 r))
          (hasDerivAt_pow 5 r)) ?_
      norm_num
      have e4 : r ^ 4 = (r ^ 2) ^ 2 := by ring
      rw [e4, hs2]
      linear_combination hz'
    · apply mul_neg_of_pos_of_neg (by linarith)
      linarith
  · intro hμ hμ0
    have hq0 : 0 < √(1 + 4 * μ) := Real.sqrt_pos.mpr (by linarith)
    have hq1 : √(1 + 4 * μ) < 1 := (Real.sqrt_lt' one_pos).mpr (by linarith)
    have hRm : 0 < (1 - √(1 + 4 * μ)) / 2 := by linarith
    have hs2 := Real.sq_sqrt hRm.le
    refine ⟨Real.sqrt_pos.mpr hRm, Real.sqrt_lt_sqrt hRm.le (by linarith), ?_, ?_, ?_⟩
    · rw [hf, hs2, quintic_factor μ _ hμ.le]; ring
    · intro s hs hlt
      have ht : s ^ 2 < (1 - √(1 + 4 * μ)) / 2 := (Real.lt_sqrt hs.le).mp hlt
      rw [hf, quintic_factor μ _ hμ.le]
      apply mul_neg_of_pos_of_neg hs
      have : 0 < (s ^ 2 - (1 + √(1 + 4 * μ)) / 2) * (s ^ 2 - (1 - √(1 + 4 * μ)) / 2) :=
        mul_pos_of_neg_of_neg (by linarith) (by linarith)
      linarith
    · intro s hlt1 hlt2
      have hs : 0 < s := lt_of_le_of_lt (Real.sqrt_nonneg _) hlt1
      have ht1 : (1 - √(1 + 4 * μ)) / 2 < s ^ 2 := (Real.sqrt_lt' hs).mp hlt1
      have ht2 : s ^ 2 < (1 + √(1 + 4 * μ)) / 2 := (Real.lt_sqrt hs.le).mp hlt2
      rw [hf, quintic_factor μ _ hμ.le]
      apply mul_pos hs
      have : (s ^ 2 - (1 + √(1 + 4 * μ)) / 2) * (s ^ 2 - (1 - √(1 + 4 * μ)) / 2) < 0 :=
        mul_neg_of_neg_of_pos (by linarith) (by linarith)
      linarith
  · intro hμ s hs hlt
    have hq1 : 1 < √(1 + 4 * μ) := (Real.lt_sqrt zero_le_one).mpr (by linarith)
    have ht : s ^ 2 < (1 + √(1 + 4 * μ)) / 2 := (Real.lt_sqrt hs.le).mp hlt
    have ht0 : 0 < s ^ 2 := pow_pos hs 2
    rw [hf, quintic_factor μ _ (by linarith)]
    apply mul_pos hs
    have : (s ^ 2 - (1 + √(1 + 4 * μ)) / 2) * (s ^ 2 - (1 - √(1 + 4 * μ)) / 2) < 0 :=
      mul_neg_of_neg_of_pos (by linarith) (by linarith)
    linarith

/-- The Brusselator `x' = 1 - (B + 1) x + x^2 y`, `y' = B x - x^2 y`. For every feed rate `B`,
the mix rests at `(1, B)`; the rates' slopes there are `B - 1`, `1`, `-B`, `-1`, so the Jacobian
has trace `B - 2` and determinant `1` (the Hopf point is `B = 2`, turning rate 1). At `B = 2`, in
the shifted coordinates `u = x - 1`, `w = 3 - x - y`, the law is exactly
`u' = -w + (-2uw - u^2 w - u^3)` and `w' = u`: the pure turn plus `f = -2uw - u^2 w - u^3`, `g = 0`. -/
theorem brusselator_hopf_point (B : ℝ) :
    (1 - (B + 1) * 1 + 1 ^ 2 * B = 0 ∧ B * 1 - 1 ^ 2 * B = 0) ∧
    HasDerivAt (fun x : ℝ => 1 - (B + 1) * x + x ^ 2 * B) (B - 1) 1 ∧
    HasDerivAt (fun y : ℝ => 1 - (B + 1) * 1 + 1 ^ 2 * y) 1 B ∧
    HasDerivAt (fun x : ℝ => B * x - x ^ 2 * B) (-B) 1 ∧
    HasDerivAt (fun y : ℝ => B * 1 - 1 ^ 2 * y) (-1) B ∧
    Matrix.trace !![B - 1, 1; -B, -1] = B - 2 ∧
    Matrix.det !![B - 1, 1; -B, -1] = 1 ∧
    (B = 2 → ∀ u w : ℝ,
      1 - (B + 1) * (1 + u) + (1 + u) ^ 2 * (2 - u - w) = -w + (-2 * u * w - u ^ 2 * w - u ^ 3) ∧
      -(1 - (B + 1) * (1 + u) + (1 + u) ^ 2 * (2 - u - w))
        - (B * (1 + u) - (1 + u) ^ 2 * (2 - u - w)) = u) := by
  refine ⟨⟨by ring, by ring⟩, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · refine HasDerivAt.congr_deriv (HasDerivAt.add
      (HasDerivAt.const_sub 1 (HasDerivAt.const_mul (B + 1) (hasDerivAt_id' (1 : ℝ))))
      (HasDerivAt.mul_const (hasDerivAt_pow 2 (1 : ℝ)) B)) ?_
    norm_num; ring
  · refine HasDerivAt.congr_deriv (HasDerivAt.const_add (1 - (B + 1) * 1)
      (HasDerivAt.const_mul ((1 : ℝ) ^ 2) (hasDerivAt_id' B))) ?_
    norm_num
  · refine HasDerivAt.congr_deriv (HasDerivAt.sub (HasDerivAt.const_mul B (hasDerivAt_id' (1 : ℝ)))
      (HasDerivAt.mul_const (hasDerivAt_pow 2 (1 : ℝ)) B)) ?_
    norm_num; ring
  · refine HasDerivAt.congr_deriv (HasDerivAt.const_sub (B * 1)
      (HasDerivAt.const_mul ((1 : ℝ) ^ 2) (hasDerivAt_id' B))) ?_
    norm_num
  · rw [Matrix.trace_fin_two_of]; ring
  · rw [Matrix.det_fin_two_of]; ring
  · intro hB u w
    subst hB
    constructor <;> ring

-- Supercritical normal form r' = mu r - r^3 at mu = 1/25: the cycle radius is 1/5.
example : √((1 : ℝ) / 25) = 1 / 5 := by
  rw [show (1 : ℝ) / 25 = (1 / 5) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
example : (1 / 25 : ℚ) * (1 / 5) - (1 / 5) ^ 3 = 0 ∧ (1 / 25 - 3 * (1 / 5) ^ 2 : ℚ) = -2 * (1 / 25) := by
  norm_num
-- At mu = 0 the swing from 1/5 follows 1/sqrt(25 + 2t); at t = 1000 that is 1/45.
example : √((25 : ℝ) + 2 * 1000) = 45 := by
  rw [show (25 : ℝ) + 2 * 1000 = 45 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- Subcritical model: at mu = 0 the big cycle has radius 1; at mu = -1/4 it has r^2 = 1/2.
example : √((1 + √(1 + 4 * (0 : ℝ))) / 2) = 1 := by norm_num
example : (1 + √(1 + 4 * (-1 / 4 : ℝ))) / 2 = 1 / 2 := by norm_num
example : (-1 / 4 : ℚ) + 1 / 2 - (1 / 2) ^ 2 = 0 := by norm_num
-- Brusselator: f = -2uw - u^2 w - u^3 has f_uuu = -6, f_uw = -2, the rest 0, so 16a = -6 and a = -3/8.
example : ((-6 : ℚ) + 0 + 0 + 0 + (1 / 1) * ((-2) * (0 + 0) - 0 * (0 + 0) - 0 * 0 + 0 * 0)) / 16 = -3 / 8 := by
  norm_num
-- Brusselator at B = 2.04: dial mu = 1/25 at speed d = 1/2, so radius^2 = (1/50)/(3/8) = 4/75.
example : ((1 / 2 : ℚ) * (1 / 25)) / (3 / 8) = 4 / 75 := by norm_num

#print axioms hopf_cubic_coefficient_decides
#print axioms subcritical_quintic_hysteresis
#print axioms brusselator_hopf_point
