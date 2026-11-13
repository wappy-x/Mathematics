-- When an SDE has one solution: once Step 1's mean-square estimate holds, the Picard gaps fall like C (Mt)^k / k! with a finite Borel–Cantelli total C e^(4MT) and two solutions' gap is zero, while the CIR noise 0.25 √r meets the growth and square-root conditions but has no Lipschitz constant at zero, and X = 1/(1 - W) solves dX = X³ dt + X² dW and runs off to infinity.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Integrability.Basic
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Topology.Algebra.Order.Floor

open Set Filter Topology MeasureTheory

/-! Mathlib has no Ito integral, so the card's theorem itself (an almost-sure integral equation
driven by Brownian motion) cannot be written here. This file states the exact parts of the card's
argument and its examples. The main theorem is the deterministic engine of the proof: Step 1
(Cauchy–Schwarz, Doob's inequality and the Ito isometry) gives each Picard gap
`D_k(t) ≤ M ∫₀ᵗ D_{k-1}(s) ds` with `M = 2K²(T + 4)`; from that alone, Steps 2 and 3 get the
factorial bound and a finite Borel–Cantelli total, and Step 4 gets uniqueness by Gronwall. -/

/-- Helper: integral of the factorial bound. -/
lemma sde_integral_bound (M C t : ℝ) (k : ℕ) :
    M * ∫ s in (0)..t, C * (M * s) ^ k / (k.factorial : ℝ) =
      C * (M * t) ^ (k + 1) / ((k + 1).factorial : ℝ) := by
  have h : (fun s : ℝ => C * (M * s) ^ k / (k.factorial : ℝ)) =
      fun s => (C * M ^ k / (k.factorial : ℝ)) * s ^ k := by
    funext s; rw [mul_pow]; ring
  rw [h, intervalIntegral.integral_const_mul, integral_pow, Nat.factorial_succ]
  push_cast
  have hk : (k.factorial : ℝ) ≠ 0 := by positivity
  field_simp
  ring

/-- Helper: the factorial bound from the Picard recursion, for any `M ≥ 0`. -/
lemma sde_picard_bound (M T C : ℝ) (hM : 0 ≤ M) (hT : 0 ≤ T) (D : ℕ → ℝ → ℝ)
    (hD0 : ∀ k, ∀ t ∈ Icc 0 T, 0 ≤ D k t) (hC : ∀ t ∈ Icc 0 T, D 0 t ≤ C)
    (hstep : ∀ k, ∀ t ∈ Icc 0 T, D (k + 1) t ≤ M * ∫ s in (0)..t, D k s) :
    ∀ k : ℕ, ∀ t ∈ Icc 0 T, D k t ≤ C * (M * t) ^ k / (k.factorial : ℝ) := by
  have hC0 : 0 ≤ C := (hD0 0 0 ⟨le_rfl, hT⟩).trans (hC 0 ⟨le_rfl, hT⟩)
  intro k
  induction k with
  | zero => intro t ht; simpa using hC t ht
  | succ k ih =>
    intro t ht
    refine (hstep k t ht).trans ?_
    rw [← sde_integral_bound]
    apply mul_le_mul_of_nonneg_left _ hM
    rw [intervalIntegral.integral_of_le ht.1, intervalIntegral.integral_of_le ht.1]
    apply integral_mono_of_nonneg
    · refine ae_restrict_of_forall_mem measurableSet_Ioc ?_
      intro s hs
      exact hD0 k s ⟨hs.1.le, hs.2.trans ht.2⟩
    · have : Continuous (fun s : ℝ => C * (M * s) ^ k / (k.factorial : ℝ)) := by fun_prop
      exact (this.integrableOn_Icc).mono_set Ioc_subset_Icc_self
    · refine ae_restrict_of_forall_mem measurableSet_Ioc ?_
      intro s hs
      exact ih s ⟨hs.1.le, hs.2.trans ht.2⟩

#print axioms sde_integral_bound
#print axioms sde_picard_bound

/-- Picard iteration in mean square converges, and two solutions agree. Fix a horizon `T ≥ 0` and
the constant `K`, and put `M = 2K²(T + 4)`.
(1) Existence, Steps 2 and 3. Let `D k t ≥ 0` be the mean square of the largest gap between Picard
guesses `k` and `k + 1` up to time `t`. If the first gap is at most `C` and each round obeys Step 1's
estimate `D_(k+1)(t) ≤ M ∫₀ᵗ D_k(s) ds`, then `D_k(t) ≤ C (Mt)^k / k!` for every round `k` and every
time `t` up to `T`.
(2) The Chebyshev bounds of the Detailed proof add to a finite total:
`∑ₖ 4^k · C (MT)^k / k! = C e^(4MT)`, so Borel–Cantelli applies.
(3) Uniqueness, Step 4. If `e(t) ≥ 0`, the mean square of the largest gap between two solutions,
obeys `e(t) ≤ M ∫₀ᵗ e(s) ds` up to `T`, then `e(t) = 0` at every time up to `T`. -/
theorem picard_gaps_fall_factorially_and_solutions_agree (K T C : ℝ) (hT : 0 ≤ T) :
    (∀ D : ℕ → ℝ → ℝ,
      (∀ k, ∀ t ∈ Icc 0 T, 0 ≤ D k t) →
      (∀ t ∈ Icc 0 T, D 0 t ≤ C) →
      (∀ k, ∀ t ∈ Icc 0 T, D (k + 1) t ≤ 2 * K ^ 2 * (T + 4) * ∫ s in (0)..t, D k s) →
      ∀ k : ℕ, ∀ t ∈ Icc 0 T,
        D k t ≤ C * (2 * K ^ 2 * (T + 4) * t) ^ k / (k.factorial : ℝ)) ∧
    HasSum (fun k : ℕ => (4 : ℝ) ^ k * (C * (2 * K ^ 2 * (T + 4) * T) ^ k / (k.factorial : ℝ)))
      (C * Real.exp (4 * (2 * K ^ 2 * (T + 4)) * T)) ∧
    (∀ e : ℝ → ℝ,
      (∀ t ∈ Icc 0 T, 0 ≤ e t) →
      (∀ t ∈ Icc 0 T, e t ≤ 2 * K ^ 2 * (T + 4) * ∫ s in (0)..t, e s) →
      ∀ t ∈ Icc 0 T, e t = 0) := by
  set M : ℝ := 2 * K ^ 2 * (T + 4) with hMdef
  have hM : 0 ≤ M := by positivity
  clear_value M
  refine ⟨?_, ?_, ?_⟩
  · intro D hD0 hC hstep
    exact sde_picard_bound M T C hM hT D hD0 hC hstep
  · have h := (NormedSpace.expSeries_div_hasSum_exp (4 * M * T : ℝ)).mul_left C
    rw [← Real.exp_eq_exp_ℝ] at h
    convert h using 1
    funext k
    simp only [mul_pow]
    ring
  · intro e he hstep t ht
    have hzero : e t ≤ 0 := by
      by_cases hint : IntervalIntegrable e volume 0 t
      · set B : ℝ := M * ∫ s in (0)..t, e s
        have hbd := sde_picard_bound M t B hM ht.1 (fun _ => e)
          (fun _ s hs => he s ⟨hs.1, hs.2.trans ht.2⟩)
          (by
            intro s hs
            refine (hstep s ⟨hs.1, hs.2.trans ht.2⟩).trans ?_
            apply mul_le_mul_of_nonneg_left _ hM
            apply intervalIntegral.integral_mono_interval le_rfl hs.1 hs.2
            · refine ae_restrict_of_forall_mem measurableSet_Ioc ?_
              intro u hu
              exact he u ⟨hu.1.le, hu.2.trans ht.2⟩
            · exact hint)
          (fun _ s hs => hstep s ⟨hs.1, hs.2.trans ht.2⟩)
        have hlim : Tendsto (fun k : ℕ => B * (M * t) ^ k / (k.factorial : ℝ)) atTop (𝓝 0) := by
          have := (FloorSemiring.tendsto_pow_div_factorial_atTop (M * t)).const_mul B
          simp only [mul_zero] at this
          convert this using 2 with k
          ring
        exact ge_of_tendsto' hlim (fun k => hbd k t ⟨ht.1, le_rfl⟩)
      · have := hstep t ht
        rwa [intervalIntegral.integral_undef hint, mul_zero] at this
    exact le_antisymm hzero (he t ht)

/-- Step 5, the CIR coefficients: drift `0.5 (0.04 - r)` and noise size `0.25 √r` on rates `r ≥ 0`.
The drift is Lipschitz with constant `0.5`. The noise has no Lipschitz constant: for no `K` is
`|0.25 √x - 0.25 √y| ≤ K |x - y|` for all rates. It still grows at most linearly, `√x ≤ (1 + x)/2`,
and it obeys the square-root bound `|√x - √y| ≤ √|x - y|`. For Yamada–Watanabe, `h(u) = 0.25 √u`
makes `∫ du / h(u)²` infinite near `0` (not integrable on `(0, 1]`), while `h(u) = u^0.4` keeps it
finite (integrable on `(0, 1]`). -/
theorem cir_noise_not_lipschitz_but_grows_linearly_and_is_sqrt_holder :
    (∀ x y : ℝ, |(1 / 2) * ((1 / 25) - x) - (1 / 2) * ((1 / 25) - y)| ≤ (1 / 2) * |x - y|) ∧
    (¬ ∃ K : ℝ, ∀ x y : ℝ, 0 ≤ x → 0 ≤ y →
        |(1 / 4) * Real.sqrt x - (1 / 4) * Real.sqrt y| ≤ K * |x - y|) ∧
    (∀ x : ℝ, 0 ≤ x → Real.sqrt x ≤ (1 + x) / 2) ∧
    (∀ x y : ℝ, 0 ≤ x → 0 ≤ y → |Real.sqrt x - Real.sqrt y| ≤ Real.sqrt |x - y|) ∧
    (¬ IntegrableOn (fun u : ℝ => 1 / ((1 / 4) * Real.sqrt u) ^ 2) (Ioc 0 1)) ∧
    IntegrableOn (fun u : ℝ => 1 / (u ^ (2 / 5 : ℝ)) ^ 2) (Ioc 0 1) := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro x y
    rw [show (1 / 2 : ℝ) * ((1 / 25) - x) - (1 / 2) * ((1 / 25) - y) = (1 / 2) * (y - x) by ring,
      abs_mul, abs_sub_comm]
    norm_num
  · rintro ⟨K, hK⟩
    set a : ℝ := |K| + 1 with ha
    have ha0 : 0 < a := by positivity
    set ε : ℝ := 1 / (8 * a) with hε
    have hε0 : 0 < ε := by positivity
    have h := hK (ε ^ 2) 0 (by positivity) le_rfl
    simp only [Real.sqrt_sq hε0.le, Real.sqrt_zero, mul_zero, sub_zero] at h
    rw [abs_of_nonneg (by positivity), abs_of_nonneg (by positivity)] at h
    have h1 : (1 / 4 : ℝ) ≤ K * ε := by nlinarith
    have h2 : K * ε ≤ |K| * ε := mul_le_mul_of_nonneg_right (le_abs_self K) hε0.le
    have h3 : |K| * ε < 1 / 8 := by
      rw [hε, mul_one_div, div_lt_div_iff₀ (by positivity) (by norm_num)]
      linarith [abs_nonneg K]
    linarith
  · intro x hx
    nlinarith [Real.sq_sqrt hx, sq_nonneg (Real.sqrt x - 1)]
  · intro x y hx hy
    rw [Real.le_sqrt (abs_nonneg _) (abs_nonneg _), sq_abs]
    have hsx := Real.sq_sqrt hx
    have hsy := Real.sq_sqrt hy
    have h0x := Real.sqrt_nonneg x
    have h0y := Real.sqrt_nonneg y
    rcases le_total x y with hxy | hxy
    · have hm := Real.sqrt_le_sqrt hxy
      rw [abs_of_nonpos (by linarith)]
      nlinarith
    · have hm := Real.sqrt_le_sqrt hxy
      rw [abs_of_nonneg (by linarith)]
      nlinarith
  · intro h
    have heq : EqOn (fun u : ℝ => 1 / ((1 / 4) * Real.sqrt u) ^ 2) (fun u => 16 * u ^ (-1 : ℝ))
        (Ioc 0 1) := by
      intro u hu
      simp only
      rw [mul_pow, Real.sq_sqrt hu.1.le, Real.rpow_neg_one]
      field_simp
      norm_num
    have h2 : IntegrableOn (fun u : ℝ => 1 / 16 * (16 * u ^ (-1 : ℝ))) (Ioc 0 1) :=
      (IntegrableOn.congr_fun h heq measurableSet_Ioc).const_mul (1 / 16)
    have h3 : IntegrableOn (fun u : ℝ => u ^ (-1 : ℝ)) (Ioc 0 1) := by
      refine IntegrableOn.congr_fun h2 ?_ measurableSet_Ioc
      intro u _
      simp only
      ring
    rw [integrableOn_Ioc_iff_integrableOn_Ioo, intervalIntegral.integrableOn_Ioo_rpow_iff one_pos] at h3
    linarith
  · have heq : EqOn (fun u : ℝ => u ^ (-(4 / 5) : ℝ)) (fun u : ℝ => 1 / (u ^ (2 / 5 : ℝ)) ^ 2)
        (Ioc 0 1) := by
      intro u hu
      simp only
      rw [← Real.rpow_natCast, ← Real.rpow_mul hu.1.le, one_div, ← Real.rpow_neg hu.1.le]
      norm_num
    refine IntegrableOn.congr_fun ?_ heq measurableSet_Ioc
    rw [integrableOn_Ioc_iff_integrableOn_Ioo, intervalIntegral.integrableOn_Ioo_rpow_iff one_pos]
    norm_num

/-- Step 6, the SDE that explodes. With `f(w) = 1/(1 - w)`, at every `w ≠ 1` the derivative of `f`
is `f²` (the noise `X²`) and the derivative of `f²` is `2 f³`, so half the second derivative is `f³`
(the drift `X³`): by Ito's lemma `X = f(W)` solves `dX = X³ dt + X² dW` from `X₀ = f(0) = 1`. Its
coefficients break the growth condition: no `K` gives `|x³| + |x²| ≤ K (1 + |x|)` for every `x`. And
`f(w)` grows without bound as `w` rises to `1`, so `X` reaches infinity when `W` first reaches 1. -/
theorem cubic_sde_solution_explodes :
    (fun w : ℝ => 1 / (1 - w)) 0 = 1 ∧
    (∀ w : ℝ, w ≠ 1 →
      HasDerivAt (fun v : ℝ => 1 / (1 - v)) ((1 / (1 - w)) ^ 2) w ∧
      HasDerivAt (fun v : ℝ => (1 / (1 - v)) ^ 2) (2 * (1 / (1 - w)) ^ 3) w) ∧
    (¬ ∃ K : ℝ, ∀ x : ℝ, |x ^ 3| + |x ^ 2| ≤ K * (1 + |x|)) ∧
    Tendsto (fun w : ℝ => 1 / (1 - w)) (𝓝[<] 1) atTop := by
  refine ⟨by norm_num, ?_, ?_, ?_⟩
  · intro w hw
    have hw' : (1 : ℝ) - w ≠ 0 := sub_ne_zero.mpr (Ne.symm hw)
    have h1 : HasDerivAt (fun v : ℝ => 1 / (1 - v)) ((1 / (1 - w)) ^ 2) w := by
      have h := ((hasDerivAt_id w).const_sub 1).inv hw'
      convert h using 1
      · funext v; simp [one_div]
      · simp [id]
    refine ⟨h1, ?_⟩
    convert h1.pow 2 using 1
    rw [show (2 : ℕ) - 1 = 1 from rfl, pow_one]
    push_cast
    ring
  · rintro ⟨K, hK⟩
    set x : ℝ := |K| + 1 with hx
    have hx1 : 1 ≤ x := by rw [hx]; linarith [abs_nonneg K]
    have h := hK x
    rw [abs_of_nonneg (by positivity), abs_of_nonneg (by positivity),
      abs_of_nonneg (by positivity)] at h
    have h2 : K * (1 + x) ≤ |K| * (1 + x) :=
      mul_le_mul_of_nonneg_right (le_abs_self K) (by positivity)
    have h3 : |K| = x - 1 := by rw [hx]; ring
    rw [h3] at h2
    nlinarith
  · have h1 : Tendsto (fun w : ℝ => 1 - w) (𝓝[<] 1) (𝓝[>] 0) := by
      apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
      · have : Tendsto (fun w : ℝ => 1 - w) (𝓝 1) (𝓝 (1 - 1)) :=
          (continuous_const.sub continuous_id).tendsto 1
        rw [sub_self] at this
        exact this.mono_left nhdsWithin_le_nhds
      · filter_upwards [self_mem_nhdsWithin] with w hw
        simp only [mem_Ioi, sub_pos]
        exact hw
    exact (tendsto_inv_nhdsGT_zero.comp h1).congr (fun w => by simp [one_div])

/-! The card's worked numbers, as exact fractions: r₀ = 1/100, κ = 1/2, θ = 1/25, σ = 1/4. -/

-- Noise per unit of rate, σ √r / r: 2.5 at 1 percent, 25 at 0.01 percent, 250 at 0.0001 percent.
example : (1 / 4 : ℝ) * Real.sqrt (1 / 100) / (1 / 100) = 5 / 2 := by norm_num
example : (1 / 4 : ℝ) * Real.sqrt (1 / 10000) / (1 / 10000) = 25 := by norm_num
example : (1 / 4 : ℝ) * Real.sqrt (1 / 1000000) / (1 / 1000000) = 250 := by norm_num
-- Feller test: 2κθ = 0.04 against σ² = 0.0625, ratio 0.64, so 2κθ < σ² and the rate touches zero.
example : 2 * (1 / 2 : ℚ) * (1 / 25) = 1 / 25 ∧ (1 / 4 : ℚ) ^ 2 = 1 / 16 ∧
    (1 / 25 : ℚ) < 1 / 16 ∧ (1 / 25 : ℚ) / (1 / 16) = 16 / 25 := by norm_num
-- One monthly Euler step from 1 percent: mean 0.01 + 0.5 × (0.04 − 0.01)/12 = 0.01125 = 9/800.
example : (1 / 100 : ℚ) + (1 / 2) * ((1 / 25) - (1 / 100)) / 12 = 9 / 800 := by norm_num
-- The Lipschitz cousin 1.25 r matches the CIR noise 0.25 √r at 4 percent: both are 0.05.
example : (5 / 4 : ℝ) * (1 / 25) = 1 / 20 ∧ (1 / 4 : ℝ) * Real.sqrt (1 / 25) = 1 / 20 := by norm_num
-- The growth test's largest ratio is exactly 1, at x = 1: √1 = (1 + 1)/2.
example : Real.sqrt 1 = (1 + 1) / 2 := by norm_num
-- The exploding SDE at w = 0.3: X = 1/(1 − 0.3) = 10/7, drift X³ = 1000/343, noise X² = 100/49.
example : (1 : ℚ) / (1 - 3 / 10) = 10 / 7 ∧ (10 / 7 : ℚ) ^ 3 = 1000 / 343 ∧
    (10 / 7 : ℚ) ^ 2 = 100 / 49 := by norm_num

#print axioms picard_gaps_fall_factorially_and_solutions_agree
#print axioms cir_noise_not_lipschitz_but_grows_linearly_and_is_sqrt_holder
#print axioms cubic_sde_solution_explodes
