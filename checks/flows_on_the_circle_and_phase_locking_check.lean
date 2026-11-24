-- Phase locking: Adler's equation phi' = omega - K sin phi has a rest exactly when |omega| <= K, at the lag arcsin(omega/K), and otherwise every solution gains or loses one full turn every 2 pi / sqrt(omega^2 - K^2).
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.ArctanDeriv
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Real

theorem adler_antideriv (ω K s : ℝ) (hK : 0 ≤ K) (hs : 0 < s) (hs2 : s ^ 2 = ω ^ 2 - K ^ 2)
    (hω : K < ω) (x : ℝ) :
    HasDerivAt (fun φ => (φ - 2 * arctan (K * cos φ / (ω + s - K * sin φ))) / s)
      (1 / (ω - K * sin x)) x := by
  have hsin : K * sin x ≤ K := by
    have := sin_le_one x; nlinarith
  have hD : ω + s - K * sin x ≠ 0 := by linarith
  have hE : ω - K * sin x ≠ 0 := by linarith
  have h := (((hasDerivAt_id x).sub ((((hasDerivAt_cos x).const_mul K).div
    ((hasDerivAt_const x (ω + s)).sub ((hasDerivAt_sin x).const_mul K)) hD).arctan.const_mul 2)).div_const s)
  convert h using 1
  · funext y; simp only [Pi.sub_apply, Pi.div_apply, id]
  simp only [Pi.sub_apply, Pi.div_apply]
  have hc : cos x ^ 2 = 1 - sin x ^ 2 := by rw [← sin_sq_add_cos_sq x]; ring
  have hP : (ω + s - K * sin x) ^ 2 + (K * cos x) ^ 2 ≠ 0 := by positivity
  field_simp
  linear_combination (s + ω - K * sin x) * (hs2 + K ^ 2 * sin_sq_add_cos_sq x)

#print axioms adler_antideriv

theorem adler_antideriv_periodic (ω K s : ℝ) (y : ℝ) :
    (fun φ => (φ - 2 * arctan (K * cos φ / (ω + s - K * sin φ))) / s) (y + 2 * π) =
      (fun φ => (φ - 2 * arctan (K * cos φ / (ω + s - K * sin φ))) / s) y + 2 * π / s := by
  simp only [sin_add_two_pi, cos_add_two_pi]
  ring

#print axioms adler_antideriv_periodic

theorem adler_slip_forward (ω K : ℝ) (hK : 0 ≤ K) (hω : K < ω) (φ : ℝ → ℝ)
    (hφ : ∀ t, HasDerivAt φ (ω - K * sin (φ t)) t) (t : ℝ) :
    φ (t + 2 * π / √(ω ^ 2 - K ^ 2)) = φ t + 2 * π := by
  have hs : 0 < √(ω ^ 2 - K ^ 2) := Real.sqrt_pos.2 (by nlinarith)
  have hs2 : √(ω ^ 2 - K ^ 2) ^ 2 = ω ^ 2 - K ^ 2 := Real.sq_sqrt (by nlinarith)
  set s := √(ω ^ 2 - K ^ 2)
  set F := fun φ => (φ - 2 * arctan (K * cos φ / (ω + s - K * sin φ))) / s with hFdef
  have hF : ∀ y, HasDerivAt F (1 / (ω - K * sin y)) y := adler_antideriv ω K s hK hs hs2 hω
  have hE : ∀ y, 0 < ω - K * sin y := by
    intro y
    have := sin_le_one y
    nlinarith
  have hmono : StrictMono F := strictMono_of_deriv_pos fun y => by
    rw [(hF y).deriv]
    exact one_div_pos.2 (hE y)
  have hg : ∀ u, HasDerivAt (fun u => F (φ u) - u) 0 u := by
    intro u
    have := ((hF (φ u)).comp u (hφ u)).sub (hasDerivAt_id u)
    convert this using 1
    · rfl
    · rw [one_div_mul_cancel (hE (φ u)).ne', sub_self]
  have hconst : ∀ u, F (φ u) - u = F (φ 0) - 0 := fun u =>
    is_const_of_deriv_eq_zero (fun u => (hg u).differentiableAt) (fun u => (hg u).deriv) u 0
  apply hmono.injective
  have h1 := hconst (t + 2 * π / s)
  have h2 := hconst t
  have h3 : F (φ t + 2 * π) = F (φ t) + 2 * π / s := adler_antideriv_periodic ω K s (φ t)
  rw [h3]
  linarith

#print axioms adler_slip_forward

/-- The card's main claim, for Adler's equation `φ' = ω - K sin φ` with frequency gap `ω`
and pull `K ≥ 0`. Locking: the gap has a rest (a value where its rate is zero) exactly
when `|ω| ≤ K`. Slipping: when the pull is smaller than the gap, every solution goes round
the circle forever, one full turn (`2π`) every `T = 2π / √(ω² - K²)` seconds: forward when
`ω > K`, backward when `ω < -K` (the mirror image). -/
theorem adler_locks_iff_else_slips (ω K : ℝ) (hK : 0 ≤ K) :
    ((∃ φ : ℝ, ω - K * sin φ = 0) ↔ |ω| ≤ K) ∧
      ∀ φ : ℝ → ℝ, (∀ t, HasDerivAt φ (ω - K * sin (φ t)) t) →
        (K < ω → ∀ t, φ (t + 2 * π / √(ω ^ 2 - K ^ 2)) = φ t + 2 * π) ∧
        (ω < -K → ∀ t, φ (t + 2 * π / √(ω ^ 2 - K ^ 2)) = φ t - 2 * π) := by
  refine ⟨⟨?_, ?_⟩, ?_⟩
  · rintro ⟨φ, hφ⟩
    rw [abs_le]
    have h1 := sin_le_one φ
    have h2 := neg_one_le_sin φ
    constructor <;> nlinarith
  · intro h
    rcases hK.lt_or_eq with hK' | hK'
    · refine ⟨arcsin (ω / K), ?_⟩
      rw [abs_le] at h
      rw [sin_arcsin (by rw [le_div_iff₀ hK']; linarith) (by rw [div_le_iff₀ hK']; linarith)]
      field_simp
      ring
    · refine ⟨0, ?_⟩
      subst hK'
      have : ω = 0 := abs_nonpos_iff.1 h
      simp [this]
  · intro φ hφ
    refine ⟨fun hω t => adler_slip_forward ω K hK hω φ hφ t, fun hω t => ?_⟩
    have hψ : ∀ t, HasDerivAt (fun u => -φ u) (-ω - K * sin ((fun u => -φ u) t)) t := by
      intro t
      convert (hφ t).neg using 1
      simp only [sin_neg]
      ring
    have := adler_slip_forward (-ω) K hK (by linarith) (fun u => -φ u) hψ t
    simp only [neg_sq] at this
    linarith

/-- The card's locked lag: when `|ω| ≤ K`, the gap rests at `φ* = arcsin (ω / K)` and at
`π - φ*`. The slope of the rate `ω - K sin φ` is `-√(K² - ω²)` at `φ*` (negative, so a
nudged gap returns: the stable lag) and `+√(K² - ω²)` at `π - φ*` (the unstable rest). -/
theorem adler_locked_lag (ω K : ℝ) (hK : 0 ≤ K) (hlock : |ω| ≤ K) :
    ω - K * sin (arcsin (ω / K)) = 0 ∧
      ω - K * sin (π - arcsin (ω / K)) = 0 ∧
      HasDerivAt (fun φ => ω - K * sin φ) (-√(K ^ 2 - ω ^ 2)) (arcsin (ω / K)) ∧
      HasDerivAt (fun φ => ω - K * sin φ) (√(K ^ 2 - ω ^ 2)) (π - arcsin (ω / K)) := by
  have hd : ∀ x, HasDerivAt (fun φ => ω - K * sin φ) (-(K * cos x)) x := fun x => by
    simpa using ((hasDerivAt_sin x).const_mul K).const_sub ω
  have key : ω - K * sin (arcsin (ω / K)) = 0 ∧ K * cos (arcsin (ω / K)) = √(K ^ 2 - ω ^ 2) := by
    rcases hK.lt_or_eq with hK' | hK'
    · rw [abs_le] at hlock
      rw [sin_arcsin (by rw [le_div_iff₀ hK']; linarith) (by rw [div_le_iff₀ hK']; linarith),
        cos_arcsin]
      refine ⟨by field_simp; ring, ?_⟩
      have h2 : K ^ 2 - ω ^ 2 = K ^ 2 * (1 - (ω / K) ^ 2) := by field_simp
      rw [h2, Real.sqrt_mul (sq_nonneg K), Real.sqrt_sq hK]
    · subst hK'
      have : ω = 0 := abs_nonpos_iff.1 hlock
      simp [this]
  refine ⟨key.1, ?_, ?_, ?_⟩
  · rw [sin_pi_sub]; exact key.1
  · convert hd (arcsin (ω / K)) using 1
    rw [key.2]
  · convert hd (π - arcsin (ω / K)) using 1
    rw [cos_pi_sub, mul_neg, neg_neg, key.2]

/-- The card's period integral: when the gap `ω` exceeds the pull `K ≥ 0`, the time for one
trip round the circle, `∫₀^{2π} dφ / (ω - K sin φ)`, equals `2π / √(ω² - K²)`. -/
theorem adler_slip_period_integral (ω K : ℝ) (hK : 0 ≤ K) (hslip : K < ω) :
    ∫ φ in (0 : ℝ)..2 * π, 1 / (ω - K * sin φ) = 2 * π / √(ω ^ 2 - K ^ 2) := by
  have hs : 0 < √(ω ^ 2 - K ^ 2) := Real.sqrt_pos.2 (by nlinarith)
  have hs2 : √(ω ^ 2 - K ^ 2) ^ 2 = ω ^ 2 - K ^ 2 := Real.sq_sqrt (by nlinarith)
  set s := √(ω ^ 2 - K ^ 2)
  have hE : ∀ y, ω - K * sin y ≠ 0 := by
    intro y
    have := sin_le_one y
    nlinarith
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (fun x _ => adler_antideriv ω K s hK hs hs2 hslip x)
    ((continuous_const.div (continuous_const.sub (continuous_const.mul continuous_sin))
      hE).intervalIntegrable _ _)]
  simp only [sin_two_pi, cos_two_pi, sin_zero, cos_zero]
  ring

-- Worked numbers from the card: frequency gap 1/2 rad/s (6.5 - 6.0).
example : (13 / 2 : ℚ) - 6 = 1 / 2 := by norm_num
-- Pull 1 locks: |1/2| ≤ 1, and the lag 30 degrees (π/6) has sine 1/2 = ω/K.
example : |(1 / 2 : ℚ)| ≤ 1 := by norm_num
example : sin (π / 6) = 1 / 2 := by norm_num
-- The other rest is 180 - 30 = 150 degrees; 30 degrees is 1/12 of a cycle.
example : (180 : ℚ) - 30 = 150 := by norm_num
example : (30 : ℚ) / 360 = 1 / 12 := by norm_num
-- Once locked both run at 6 + 1/2 · 1/2 = 13/2 - 1/4 = 25/4 = 6.25 rad/s, the mean rhythm.
example : (6 : ℚ) + 1 / 2 * (1 / 2) = 25 / 4 ∧ (13 / 2 : ℚ) - 1 / 4 = 25 / 4 ∧
    ((6 : ℚ) + 13 / 2) / 2 = 25 / 4 := by norm_num
-- Pull 0.4 = 2/5 slips: 2/5 < 1/2, gap² - pull² = 0.09, square root 0.3.
example : (2 / 5 : ℚ) < 1 / 2 := by norm_num
example : (1 / 2 : ℚ) ^ 2 - (2 / 5) ^ 2 = 9 / 100 := by norm_num
example : √((1 / 2 : ℝ) ^ 2 - (2 / 5) ^ 2) = 3 / 10 := by norm_num
-- Pull 0.49: gap² - pull² = 0.0099.
example : (1 / 2 : ℚ) ^ 2 - (49 / 100) ^ 2 = 99 / 10000 := by norm_num
-- While slipping at pull 0.4 the mean drift is 2π/T = 0.3, so A averages
-- 6 + (0.5 - 0.3)/2 = 6.1 rad/s and B 6.5 - 0.1 = 6.4 rad/s.
example : (6 : ℚ) + (1 / 2 - 3 / 10) / 2 = 61 / 10 ∧
    (13 / 2 : ℚ) - (1 / 2 - 3 / 10) / 2 = 32 / 5 := by norm_num

#print axioms adler_locks_iff_else_slips
#print axioms adler_locked_lag
#print axioms adler_slip_period_integral
