-- Power series in the plane: a complex power series converges absolutely on the open disc whose radius R is given by the Cauchy–Hadamard formula 1/R = limsup |a_n|^(1/n) and fails outside it, inside that disc it can be differentiated term by term with the same radius, and the bump 1/(1 + z^2) has series radius exactly 1, the distance from 0 to its poles i and −i.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Normed.Group.InfiniteSum
import Mathlib.Analysis.SpecialFunctions.Pow.NNReal
import Mathlib.Order.LiminfLimsup
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.IntervalCases
import Mathlib.Analysis.Analytic.RadiusLiminf
import Mathlib.Analysis.Analytic.OfScalars
import Mathlib.Analysis.Calculus.SmoothSeries
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.Normed.Module.Convex
import Mathlib.Analysis.Convex.PathConnected
import Mathlib.Analysis.Calculus.Deriv.Pow

open Filter Topology Finset Complex
open scoped ENNReal

open FormalMultilinearSeries in
lemma cps_norm_ofScalars (a : ℕ → ℂ) (n : ℕ) :
    ‖FormalMultilinearSeries.ofScalars ℂ a n‖ = ‖a n‖ :=
  FormalMultilinearSeries.ofScalars_norm ℂ a n

lemma cps_radius_ofScalars (a : ℕ → ℂ) :
    (FormalMultilinearSeries.ofScalars ℂ a).radius =
      (limsup (fun n : ℕ => (‖a n‖₊ : ℝ≥0∞) ^ ((n : ℝ)⁻¹)) atTop)⁻¹ := by
  rw [← inv_inv (FormalMultilinearSeries.ofScalars ℂ a).radius,
    FormalMultilinearSeries.radius_inv_eq_limsup]
  congr 2
  funext n
  rw [ENNReal.coe_rpow_of_nonneg _ (by positivity), one_div]
  congr 2
  ext
  simp only [coe_nnnorm]
  exact cps_norm_ofScalars a n

lemma cps_summable_inside (a : ℕ → ℂ) (c z : ℂ)
    (h : (‖z - c‖₊ : ℝ≥0∞) < (FormalMultilinearSeries.ofScalars ℂ a).radius) :
    Summable (fun n => ‖a n * (z - c) ^ n‖) := by
  have := (FormalMultilinearSeries.ofScalars ℂ a).summable_norm_mul_pow h
  simpa only [norm_mul, norm_pow, cps_norm_ofScalars, coe_nnnorm] using this

lemma cps_not_tendsto_outside (a : ℕ → ℂ) (c z : ℂ)
    (h : (FormalMultilinearSeries.ofScalars ℂ a).radius < (‖z - c‖₊ : ℝ≥0∞)) :
    ¬ Tendsto (fun n => a n * (z - c) ^ n) atTop (𝓝 0) := by
  intro ht
  have h2 : Tendsto (fun n => ‖FormalMultilinearSeries.ofScalars ℂ a n‖ * (‖z - c‖₊ : ℝ) ^ n)
      atTop (𝓝 0) := by
    have := ht.norm
    simpa only [norm_mul, norm_pow, cps_norm_ofScalars, coe_nnnorm, norm_zero] using this
  exact absurd ((FormalMultilinearSeries.ofScalars ℂ a).le_radius_of_tendsto h2) (not_le.mpr h)

lemma cps_terms_of_partial_sums (f : ℕ → ℂ) (S : ℂ)
    (h : Tendsto (fun N => ∑ n ∈ range N, f n) atTop (𝓝 S)) : Tendsto f atTop (𝓝 0) := by
  have h1 : Tendsto (fun N => ∑ n ∈ range (N + 1), f n) atTop (𝓝 S) :=
    h.comp (tendsto_add_atTop_nat 1)
  have := h1.sub h
  simpa only [sum_range_succ_sub_sum, sub_self] using this

lemma cps_radius_deriv (a : ℕ → ℂ) :
    (FormalMultilinearSeries.ofScalars ℂ (fun n => (n : ℂ) * a n)).radius =
      (FormalMultilinearSeries.ofScalars ℂ a).radius := by
  set P := FormalMultilinearSeries.ofScalars ℂ a
  set Q := FormalMultilinearSeries.ofScalars ℂ (fun n => (n : ℂ) * a n)
  apply le_antisymm
  · refine ENNReal.le_of_forall_nnreal_lt fun r hr => ?_
    have hs := Q.summable_norm_mul_pow hr
    apply P.le_radius_of_summable_norm
    rw [← summable_nat_add_iff 1]
    rw [← summable_nat_add_iff 1] at hs
    refine hs.of_nonneg_of_le (fun n => by positivity) fun n => ?_
    simp only [Q, P, cps_norm_ofScalars, norm_mul, Complex.norm_natCast]
    gcongr
    have : (1 : ℝ) ≤ ((n + 1 : ℕ) : ℝ) := by exact_mod_cast Nat.le_add_left 1 n
    nlinarith [norm_nonneg (a (n + 1))]
  · refine ENNReal.le_of_forall_nnreal_lt fun r hr => ?_
    obtain ⟨r', hr1, hr2⟩ := ENNReal.lt_iff_exists_nnreal_btwn.mp hr
    obtain ⟨C, hC, hb⟩ := P.norm_mul_pow_le_of_lt_radius hr2
    have hrr' : (r : ℝ) < r' := by exact_mod_cast hr1
    have hr'pos : (0 : ℝ) < r' := lt_of_le_of_lt r.2 hrr'
    set q : ℝ := r / r'
    have hq0 : 0 ≤ q := by positivity
    have hq1 : ‖q‖ < 1 := by
      rw [Real.norm_of_nonneg hq0, div_lt_one hr'pos]; exact hrr'
    have hsum := (summable_pow_mul_geometric_of_norm_lt_one 1 hq1).mul_left C
    apply Q.le_radius_of_summable_norm
    refine hsum.of_nonneg_of_le (fun n => by positivity) fun n => ?_
    simp only [Q, cps_norm_ofScalars, norm_mul, Complex.norm_natCast, pow_one]
    have hbn := hb n
    simp only [P, cps_norm_ofScalars] at hbn
    have hrq : (r : ℝ) = q * r' := by
      simp only [q]; field_simp
    rw [hrq, mul_pow]
    have hn : (0 : ℝ) ≤ n := by positivity
    calc (n : ℝ) * ‖a n‖ * (q ^ n * (r' : ℝ) ^ n)
        = (n * q ^ n) * (‖a n‖ * (r' : ℝ) ^ n) := by ring
      _ ≤ (n * q ^ n) * C := by gcongr
      _ = C * (n * q ^ n) := by ring

/-- A power series `∑ a n (z - c)^n` with complex coefficients converges on an open disc and
fails outside it. The radius `R` is given by the Cauchy–Hadamard formula
`1/R = limsup |a n|^(1/n)` (with `1/0 = ∞` and `1/∞ = 0`). Strictly inside the disc
(`|z - c| < R`) the series converges absolutely; strictly outside (`|z - c| > R`) its terms
do not shrink to 0 and its partial sums have no limit. The rim `|z - c| = R` is left open. -/
theorem power_series_converges_on_open_disc_fails_outside (a : ℕ → ℂ) (c : ℂ) (R : ℝ≥0∞)
    (hR : R = (limsup (fun n : ℕ => (‖a n‖₊ : ℝ≥0∞) ^ ((n : ℝ)⁻¹)) atTop)⁻¹) :
    (∀ z : ℂ, (‖z - c‖₊ : ℝ≥0∞) < R → Summable (fun n => ‖a n * (z - c) ^ n‖)) ∧
    (∀ z : ℂ, R < (‖z - c‖₊ : ℝ≥0∞) →
      ¬ Tendsto (fun n => a n * (z - c) ^ n) atTop (𝓝 0) ∧
      ¬ ∃ S : ℂ, Tendsto (fun N => ∑ n ∈ range N, a n * (z - c) ^ n) atTop (𝓝 S)) := by
  have hrad : (FormalMultilinearSeries.ofScalars ℂ a).radius = R := by
    rw [hR, cps_radius_ofScalars]
  refine ⟨fun z hz => cps_summable_inside a c z (hrad ▸ hz), fun z hz => ?_⟩
  have h1 := cps_not_tendsto_outside a c z (hrad ▸ hz)
  exact ⟨h1, fun ⟨S, hS⟩ => h1 (cps_terms_of_partial_sums _ S hS)⟩

/-- Termwise differentiation: the derivative series `∑ n a n (z - c)^(n-1)` has the same
Cauchy–Hadamard radius `R` as `∑ a n (z - c)^n`, and at every point strictly inside the disc
the sum `f(w) = ∑ a n (w - c)^n` has a complex derivative equal to the derivative series. -/
theorem power_series_termwise_derivative (a : ℕ → ℂ) (c : ℂ) (R : ℝ≥0∞)
    (hR : R = (limsup (fun n : ℕ => (‖a n‖₊ : ℝ≥0∞) ^ ((n : ℝ)⁻¹)) atTop)⁻¹) :
    (limsup (fun n : ℕ => (‖(n : ℂ) * a n‖₊ : ℝ≥0∞) ^ ((n : ℝ)⁻¹)) atTop)⁻¹ = R ∧
    ∀ z : ℂ, (‖z - c‖₊ : ℝ≥0∞) < R →
      HasDerivAt (fun w => ∑' n, a n * (w - c) ^ n)
        (∑' n : ℕ, (n : ℂ) * a n * (z - c) ^ (n - 1)) z := by
  have hrad : (FormalMultilinearSeries.ofScalars ℂ a).radius = R := by
    rw [hR, cps_radius_ofScalars]
  have hradQ : (FormalMultilinearSeries.ofScalars ℂ (fun n => (n : ℂ) * a n)).radius = R := by
    rw [cps_radius_deriv, hrad]
  refine ⟨by rw [← cps_radius_ofScalars]; exact hradQ, fun z hz => ?_⟩
  obtain ⟨r, hr1, hr2⟩ := ENNReal.lt_iff_exists_nnreal_btwn.mp hz
  have hzr : ‖z - c‖ < r := by exact_mod_cast hr1
  have hrpos : (0 : ℝ) < r := lt_of_le_of_lt (norm_nonneg _) hzr
  have hsQ := (FormalMultilinearSeries.ofScalars ℂ (fun n => (n : ℂ) * a n)).summable_norm_mul_pow
    (hradQ ▸ hr2)
  set u : ℕ → ℝ := fun n => (n : ℝ) * ‖a n‖ * (r : ℝ) ^ (n - 1) with hu_def
  have hu : Summable u := by
    have := hsQ.mul_left ((r : ℝ)⁻¹)
    refine this.congr fun n => ?_
    simp only [u, cps_norm_ofScalars, norm_mul, Complex.norm_natCast]
    rcases n with _ | n
    · simp
    · simp only [Nat.add_sub_cancel, pow_succ]
      field_simp
  have hP : (FormalMultilinearSeries.ofScalars ℂ a).radius = R := hrad
  refine hasDerivAt_tsum_of_isPreconnected (t := Metric.ball c r) (y₀ := c)
    (g := fun n w => a n * (w - c) ^ n)
    (g' := fun n w => (n : ℂ) * a n * (w - c) ^ (n - 1)) hu Metric.isOpen_ball
    (convex_ball c r).isPreconnected ?_ ?_ (Metric.mem_ball_self hrpos) ?_
    (Metric.mem_ball.mpr (by rw [dist_eq_norm]; exact hzr))
  · intro n y _
    have h0 : HasDerivAt (fun w : ℂ => (w - c) ^ n) ((n : ℂ) * (y - c) ^ (n - 1)) y := by
      have h1 := HasDerivAt.pow (HasDerivAt.sub_const c (hasDerivAt_id' y)) n
      rw [mul_one] at h1
      exact h1
    have := h0.const_mul (a n)
    convert this using 1
    ring
  · intro n y hy
    rw [Metric.mem_ball, dist_eq_norm] at hy
    simp only [u, norm_mul, Complex.norm_natCast, norm_pow]
    gcongr
  · apply Summable.of_norm
    have : (‖c - c‖₊ : ℝ≥0∞) < (FormalMultilinearSeries.ofScalars ℂ a).radius := by
      rw [sub_self, nnnorm_zero, ENNReal.coe_zero, hP]
      exact pos_of_gt hz
    exact cps_summable_inside a c c this

/-- The speed bump's series about 0, `1 - z^2 + z^4 - ...`, with coefficients
`a n = (-1)^(n/2)` for even `n` and `0` for odd `n`: its Cauchy–Hadamard radius is exactly 1,
inside the unit disc it sums to the bump `1/(1 + z^2)`, and the bump's poles (the zeros of
`1 + z^2`) are exactly `i` and `-i`, both at distance 1 from the centre 0. -/
theorem bump_series_radius_equals_distance_to_poles :
    let a : ℕ → ℂ := fun n => if Even n then (-1) ^ (n / 2) else 0
    (limsup (fun n : ℕ => (‖a n‖₊ : ℝ≥0∞) ^ ((n : ℝ)⁻¹)) atTop)⁻¹ = 1 ∧
    (∀ z : ℂ, ‖z‖ < 1 → HasSum (fun n => a n * z ^ n) (1 + z ^ 2)⁻¹) ∧
    {p : ℂ | 1 + p ^ 2 = 0} = {I, -I} ∧
    (∀ p : ℂ, 1 + p ^ 2 = 0 → ‖p - 0‖ = 1) := by
  intro a
  have hnorm : ∀ n, (‖a n‖₊ : ℝ≥0∞) ^ ((n : ℝ)⁻¹) ≤ 1 := by
    intro n
    by_cases hn : Even n
    · simp [a, hn]
    · have hpos : (0 : ℝ) < (n : ℝ)⁻¹ := by
        have : n ≠ 0 := by rintro rfl; exact hn ⟨0, rfl⟩
        positivity
      simp [a, hn, ENNReal.zero_rpow_of_pos hpos]
  have hlim : limsup (fun n : ℕ => (‖a n‖₊ : ℝ≥0∞) ^ ((n : ℝ)⁻¹)) atTop = 1 := by
    apply le_antisymm
    · exact limsup_le_of_le (by isBoundedDefault) (Eventually.of_forall hnorm)
    · apply le_limsup_of_frequently_le
      · rw [Nat.frequently_atTop_iff_infinite]
        apply Set.infinite_of_not_bddAbove
        rintro ⟨M, hM⟩
        have : 2 * (M + 1) ∈ {n : ℕ | 1 ≤ (‖a n‖₊ : ℝ≥0∞) ^ ((n : ℝ)⁻¹)} := by
          simp [a]
        have := hM this
        omega
      · isBoundedDefault
  refine ⟨by rw [hlim, inv_one], ?_, ?_, ?_⟩
  · intro z hz
    have hz2 : ‖-z ^ 2‖ < 1 := by
      rw [norm_neg, norm_pow]
      nlinarith [norm_nonneg z]
    have hg := hasSum_geometric_of_norm_lt_one hz2
    rw [sub_neg_eq_add] at hg
    have hinj : Function.Injective (fun k : ℕ => 2 * k) := fun x y h => by simpa using h
    rw [← hinj.hasSum_iff]
    · convert hg using 1
      funext k
      show (if Even (2 * k) then (-1 : ℂ) ^ (2 * k / 2) else 0) * z ^ (2 * k) = (-z ^ 2) ^ k
      simp only [even_two_mul k, ↓reduceIte]
      rw [ Nat.mul_div_cancel_left k two_pos, pow_mul, ← mul_pow, neg_one_mul]
    · intro n hn
      have : ¬ Even n := by
        rintro ⟨k, rfl⟩
        exact hn ⟨k, by ring⟩
      simp [a, this]
  · ext p
    simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff]
    constructor
    · intro h
      have : (p - I) * (p + I) = 0 := by
        ring_nf
        rw [I_sq]
        linear_combination h
      rcases mul_eq_zero.mp this with h1 | h1
      · left; linear_combination h1
      · right; linear_combination h1
    · rintro (rfl | rfl) <;> simp
  · intro p hp
    have : (p - I) * (p + I) = 0 := by
      ring_nf
      rw [I_sq]
      linear_combination hp
    rcases mul_eq_zero.mp this with h1 | h1
    · rw [sub_zero, sub_eq_zero.mp h1, norm_I]
    · rw [sub_zero, eq_neg_of_add_eq_zero_left h1, norm_neg, norm_I]

-- On the rim, x = 1: the partial sums of 1 - 1 + 1 - ... run 1, 0, 1, 0, 1, 0.
example : (List.range 6).map (fun N => ∑ k ∈ range (N + 1), (-1 : ℤ) ^ k) = [1, 0, 1, 0, 1, 0] := by
  decide

-- Half a metre out: the bump is 1/(1 + 1/4) = 4/5 and its slope -2x/(1 + x^2)^2 is -16/25.
example : (1 + (1 / 2 : ℚ) ^ 2)⁻¹ = 4 / 5 ∧ -2 * (1 / 2 : ℚ) / (1 + (1 / 2) ^ 2) ^ 2 = -16 / 25 := by
  norm_num

-- Partial sums at x = 1/2, k = 0..3: 1, 3/4, 13/16, 51/64 (settling on 4/5).
example : (List.range 4).map (fun K => ∑ k ∈ range (K + 1), (-1 : ℚ) ^ k * (1 / 2) ^ (2 * k))
    = [1, 3 / 4, 13 / 16, 51 / 64] := by
  norm_num [List.range_succ, Finset.sum_range_succ]

-- At z = 1/2 + i/2: z^2 = i/2, the bump is 4/5 - (2/5)i, and its slope -2z/(1 + z^2)^2 is -28/25 + (4/25)i.
example : ((1 / 2 : ℂ) + (1 / 2) * I) ^ 2 = (1 / 2) * I := by
  apply Complex.ext <;> norm_num [pow_two]
example : (1 + ((1 / 2 : ℂ) + (1 / 2) * I) ^ 2)⁻¹ = 4 / 5 - (2 / 5) * I := by
  apply Complex.ext <;> norm_num [pow_two, Complex.inv_re, Complex.inv_im, Complex.normSq]
example : -2 * ((1 / 2 : ℂ) + (1 / 2) * I) / (1 + ((1 / 2 : ℂ) + (1 / 2) * I) ^ 2) ^ 2
    = -28 / 25 + (4 / 25) * I := by
  apply Complex.ext <;> norm_num [pow_two, Complex.div_re, Complex.div_im, Complex.normSq]

-- The poles: 1 + i^2 = 0 and 1 + (-i)^2 = 0.
example : (1 : ℂ) + I ^ 2 = 0 ∧ (1 : ℂ) + (-I) ^ 2 = 0 := by
  norm_num

-- About the centre 1, with w = z - 1: the bump is 1/(2 + 2w + w^2), and the coefficients
-- 1/2, -1/2, 1/4, 0, -1/8, 1/8 make (2 + 2w + w^2) times the series equal 1 up to w^5.
example :
    let b : ℕ → ℚ := fun n => [1 / 2, -1 / 2, 1 / 4, 0, -1 / 8, 1 / 8].getD n 0
    2 * b 0 = 1 ∧ 2 * b 1 + 2 * b 0 = 0 ∧
    ∀ n ∈ Finset.Icc 2 5, 2 * b n + 2 * b (n - 1) + b (n - 2) = 0 := by
  intro b
  refine ⟨by norm_num [b], by norm_num [b], ?_⟩
  intro n hn
  rcases Finset.mem_Icc.mp hn with ⟨h2, h5⟩
  interval_cases n <;> norm_num [b]

-- The poles are |1 - i| = √2 from the centre 1: (1 - i) times its conjugate is 2.
example : ((1 : ℂ) - I) * (starRingEnd ℂ ((1 : ℂ) - I)) = 2 := by
  apply Complex.ext <;> norm_num

#print axioms cps_norm_ofScalars
#print axioms cps_radius_ofScalars
#print axioms cps_summable_inside
#print axioms cps_not_tendsto_outside
#print axioms cps_terms_of_partial_sums
#print axioms cps_radius_deriv
#print axioms power_series_converges_on_open_disc_fails_outside
#print axioms power_series_termwise_derivative
#print axioms bump_series_radius_equals_distance_to_poles
