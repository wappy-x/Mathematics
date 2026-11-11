-- Taylor series: the Taylor series of exp, sin and cos add up to the function at every x, the one for ln(1 + x) does so for x above −1 and at most 1 and settles on nothing outside that range, and the smooth function e^(−1/x²) has Taylor series 0 at 0 yet is not 0 anywhere else.
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.SmoothTransition
import Mathlib.Analysis.Calculus.ContDiff.Bounds
import Mathlib.Analysis.PSeries
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Topology.Algebra.Order.Floor

open Finset Filter Topology Nat
open scoped ContDiff

theorem taylorHelper_log_iteratedDeriv_succ (k : ℕ) (t : ℝ) :
    iteratedDeriv (k + 1) (fun t => Real.log (1 + t)) t = (-1) ^ k * k ! * (1 + t) ^ (-1 - k : ℤ) := by
  rw [iteratedDeriv_succ']
  have h : deriv (fun t => Real.log (1 + t)) = fun t => (1 + t)⁻¹ := by
    funext t
    rw [deriv_comp_const_add (f := Real.log), Real.deriv_log]
  rw [h, iteratedDeriv_comp_const_add k (fun y : ℝ => y⁻¹) 1, iteratedDeriv_eq_iterate]
  exact iter_deriv_inv k (1 + t)

#print axioms taylorHelper_log_iteratedDeriv_succ

theorem taylorHelper_log_coeff (k : ℕ) (x : ℝ) :
    iteratedDeriv (k + 1) (fun t => Real.log (1 + t)) 0 / (k + 1)! * x ^ (k + 1) =
      (-1) ^ k * x ^ (k + 1) / (k + 1) := by
  rw [taylorHelper_log_iteratedDeriv_succ, Nat.factorial_succ]
  push_cast
  simp
  field_simp

#print axioms taylorHelper_log_coeff

theorem taylorHelper_lagrange {f : ℝ → ℝ} {U : Set ℝ} (hU : IsOpen U) (hf : ContDiffOn ℝ ∞ f U)
    {x : ℝ} (hx : x ≠ 0) (hsub : Set.uIcc 0 x ⊆ U) (n : ℕ) :
    ∃ c ∈ Set.uIoo 0 x, f x - ∑ k ∈ range (n + 1), iteratedDeriv k f 0 / k ! * x ^ k =
      iteratedDeriv (n + 1) f c * x ^ (n + 1) / (n + 1)! := by
  obtain ⟨c, hc, h⟩ := taylor_mean_remainder_lagrange_iteratedDeriv (n := n) (f := f) (x₀ := 0)
    (x := x) hx.symm ((hf.mono hsub).of_le (by exact_mod_cast le_top))
  refine ⟨c, hc, ?_⟩
  rw [sub_zero] at h
  rw [← h, taylor_within_apply]
  congr 1
  refine Finset.sum_congr rfl fun k _ => ?_
  rw [iteratedDerivWithin_eq_iteratedDeriv (uniqueDiffOn_uIcc hx.symm) ?_ Set.left_mem_uIcc]
  · simp only [sub_zero, smul_eq_mul]
    ring
  · exact (hf.contDiffAt (hU.mem_nhds (hsub Set.left_mem_uIcc))).of_le (by exact_mod_cast le_top)

#print axioms taylorHelper_lagrange

theorem taylorHelper_tendsto_of_bound {f : ℝ → ℝ} {U : Set ℝ} (hU : IsOpen U)
    (hf : ContDiffOn ℝ ∞ f U) {x : ℝ} (hsub : Set.uIcc 0 x ⊆ U) {M : ℝ}
    (hM : ∀ n : ℕ, ∀ c ∈ Set.uIoo 0 x, |iteratedDeriv (n + 1) f c| ≤ M) :
    Tendsto (fun n => ∑ k ∈ range (n + 1), iteratedDeriv k f 0 / k ! * x ^ k) atTop
      (𝓝 (f x)) := by
  rcases eq_or_ne x 0 with rfl | hx
  · simp [Finset.sum_range_succ']
  · have key : Tendsto (fun n : ℕ => M * (|x| ^ (n + 1) / ((n + 1)! : ℝ))) atTop (𝓝 0) := by
      simpa using ((FloorSemiring.tendsto_pow_div_factorial_atTop |x|).comp
        (tendsto_add_atTop_nat 1)).const_mul M
    rw [tendsto_iff_norm_sub_tendsto_zero]
    refine squeeze_zero (fun _ => norm_nonneg _) (fun n => ?_) key
    obtain ⟨c, hc, h⟩ := taylorHelper_lagrange hU hf hx hsub n
    rw [norm_sub_rev, Real.norm_eq_abs, h, abs_div, abs_mul, abs_pow, Nat.abs_cast, mul_div_assoc]
    exact mul_le_mul_of_nonneg_right (hM n c hc) (by positivity)

#print axioms taylorHelper_tendsto_of_bound

theorem taylorHelper_glue_iteratedDeriv_zero (k : ℕ) : iteratedDeriv k expNegInvGlue 0 = 0 := by
  have hc : Continuous (iteratedDeriv k expNegInvGlue) :=
    (expNegInvGlue.contDiff (n := ⊤)).continuous_iteratedDeriv k (by exact_mod_cast le_top)
  have hS : Set.Iio (0 : ℝ) ⊆ {y | iteratedDeriv k expNegInvGlue y = 0} := by
    intro y hy
    have : expNegInvGlue =ᶠ[𝓝 y] fun _ => 0 := by
      filter_upwards [Iio_mem_nhds hy] with z hz using expNegInvGlue.zero_of_nonpos hz.le
    simp [this.iteratedDeriv_eq k]
  have hcl := (isClosed_eq hc continuous_const).closure_subset_iff.2 hS
  rw [closure_Iio] at hcl
  exact hcl (Set.mem_Iic.2 le_rfl)

#print axioms taylorHelper_glue_iteratedDeriv_zero

theorem taylorHelper_mem_bound {x c : ℝ} (hc : c ∈ Set.uIoo 0 x) : c ≤ |x| := by
  simp only [Set.uIoo, Set.mem_Ioo] at hc
  exact hc.2.le.trans (max_le (abs_nonneg x) (le_abs_self x))

#print axioms taylorHelper_mem_bound

/-- Exp, sin, cos and ln(1 + x) equal their Taylor series at the centre 0. The Taylor
polynomial T_n(x) = ∑_{k=0}^{n} f^(k)(0) / k! · x^k, built from the k-th derivatives of f at 0,
heads for f(x) as n grows: for e^x, sin x and cos x at every real x, and for ln(1 + x) at every
x with −1 < x ≤ 1 (at x = 1 this is ln 2 = 1 − 1/2 + 1/3 − ⋯). -/
theorem exp_sin_cos_log_equal_their_taylor_series :
    (∀ x : ℝ, Tendsto (fun n => ∑ k ∈ range (n + 1),
        iteratedDeriv k Real.exp 0 / k ! * x ^ k) atTop (𝓝 (Real.exp x))) ∧
    (∀ x : ℝ, Tendsto (fun n => ∑ k ∈ range (n + 1),
        iteratedDeriv k Real.sin 0 / k ! * x ^ k) atTop (𝓝 (Real.sin x))) ∧
    (∀ x : ℝ, Tendsto (fun n => ∑ k ∈ range (n + 1),
        iteratedDeriv k Real.cos 0 / k ! * x ^ k) atTop (𝓝 (Real.cos x))) ∧
    (∀ x : ℝ, -1 < x → x ≤ 1 → Tendsto (fun n => ∑ k ∈ range (n + 1),
        iteratedDeriv k (fun t => Real.log (1 + t)) 0 / k ! * x ^ k) atTop
          (𝓝 (Real.log (1 + x)))) := by
  refine ⟨fun x => ?_, fun x => ?_, fun x => ?_, fun x hx1 hx2 => ?_⟩
  · refine taylorHelper_tendsto_of_bound isOpen_univ Real.contDiff_exp.contDiffOn
      (Set.subset_univ _) (M := Real.exp |x|) fun n c hc => ?_
    rw [iteratedDeriv_eq_iterate, Real.iter_deriv_exp, abs_of_pos (Real.exp_pos c)]
    exact Real.exp_le_exp.2 (taylorHelper_mem_bound hc)
  · exact taylorHelper_tendsto_of_bound isOpen_univ Real.contDiff_sin.contDiffOn
      (Set.subset_univ _) (M := 1) fun n c _ => Real.abs_iteratedDeriv_sin_le_one _ _
  · exact taylorHelper_tendsto_of_bound isOpen_univ Real.contDiff_cos.contDiffOn
      (Set.subset_univ _) (M := 1) fun n c _ => Real.abs_iteratedDeriv_cos_le_one _ _
  · rcases eq_or_lt_of_le hx2 with rfl | hx2
    · -- x = 1: Lagrange remainder
      have hU : IsOpen (Set.Ioi (-1 : ℝ)) := isOpen_Ioi
      have hf : ContDiffOn ℝ ∞ (fun t => Real.log (1 + t)) (Set.Ioi (-1)) := by
        intro t ht
        have ht' : (1 + t) ≠ 0 := by simp only [Set.mem_Ioi] at ht; linarith
        exact ((Real.contDiffAt_log.2 ht').comp t (contDiffAt_const.add contDiffAt_id)).contDiffWithinAt
      have hsub : Set.uIcc (0 : ℝ) 1 ⊆ Set.Ioi (-1) := by
        intro t ht
        rw [Set.uIcc_of_le zero_le_one] at ht
        simp only [Set.mem_Ioi]; linarith [ht.1]
      rw [tendsto_iff_norm_sub_tendsto_zero]
      refine squeeze_zero (fun _ => norm_nonneg _) (fun n => ?_)
        tendsto_one_div_add_atTop_nhds_zero_nat
      obtain ⟨c, hc, h⟩ := taylorHelper_lagrange hU hf one_ne_zero hsub n
      rw [Set.uIoo_of_le zero_le_one, Set.mem_Ioo] at hc
      rw [norm_sub_rev, Real.norm_eq_abs, h, taylorHelper_log_iteratedDeriv_succ]
      have h1 : (1 + c) ^ (-1 - (n : ℤ)) = ((1 + c) ^ (n + 1))⁻¹ := by
        rw [show (-1 - (n : ℤ)) = -((n + 1 : ℕ) : ℤ) by push_cast; ring, zpow_neg, zpow_natCast]
      have h2 : ((1 + c) ^ (n + 1))⁻¹ ≤ 1 := inv_le_one_of_one_le₀ (one_le_pow₀ (by linarith))
      have h3 : 0 < ((1 + c) ^ (n + 1))⁻¹ := inv_pos.2 (pow_pos (by linarith) _)
      rw [h1, one_pow, mul_one, abs_div, abs_mul, abs_mul, abs_pow, abs_neg, abs_one, one_pow,
        one_mul, Nat.abs_cast, abs_of_pos h3, Nat.abs_cast, Nat.factorial_succ]
      push_cast
      rw [div_le_div_iff₀ (by positivity) (by positivity)]
      have h5 : (n ! : ℝ) * (n + 1) * ((1 + c) ^ (n + 1))⁻¹ ≤ n ! * (n + 1) * 1 :=
        mul_le_mul_of_nonneg_left h2 (by positivity)
      linarith
    · -- |x| < 1: the logarithm series
      have hx : |-x| < 1 := by rw [abs_neg, abs_lt]; exact ⟨hx1, hx2⟩
      have hs := (Real.hasSum_pow_div_log_of_abs_lt_one hx).neg.tendsto_sum_nat
      rw [sub_neg_eq_add, neg_neg] at hs
      refine hs.congr fun n => ?_
      rw [Finset.sum_range_succ']
      simp only [taylorHelper_log_coeff, iteratedDeriv_zero, add_zero, Real.log_one, zero_div,
        zero_mul, add_zero]
      refine Finset.sum_congr rfl fun k _ => ?_
      rw [neg_pow, pow_succ (-1 : ℝ)]
      ring

/-- The wall at radius 1. For x = −1, and for every x beyond 1 in size, the Taylor polynomials
of ln(1 + x) at 0 do not settle on any number at all: past the radius of convergence the
series cannot add up. -/
theorem log_one_add_taylor_series_diverges_outside :
    ∀ x : ℝ, (x ≤ -1 ∨ 1 < x) → ¬ ∃ L : ℝ, Tendsto (fun n => ∑ k ∈ range (n + 1),
        iteratedDeriv k (fun t => Real.log (1 + t)) 0 / k ! * x ^ k) atTop (𝓝 L) := by
  rintro x hx ⟨L, hL⟩
  have hS : ∀ n : ℕ, (∑ k ∈ range (n + 1),
      iteratedDeriv k (fun t => Real.log (1 + t)) 0 / k ! * x ^ k) =
        ∑ k ∈ range n, (-1) ^ k * x ^ (k + 1) / (k + 1) := by
    intro n
    rw [Finset.sum_range_succ']
    simp [taylorHelper_log_coeff]
  simp only [hS] at hL
  rcases eq_or_ne x (-1) with rfl | hne
  · have hlim : Tendsto (fun n : ℕ => ∑ k ∈ range n, (-1 : ℝ) ^ k * (-1) ^ (k + 1) / (k + 1))
        atTop atBot := by
      refine (tendsto_neg_atTop_atBot.comp Real.tendsto_sum_range_one_div_nat_succ_atTop).congr
        fun n => ?_
      simp only [Function.comp, ← Finset.sum_neg_distrib]
      refine Finset.sum_congr rfl fun k _ => ?_
      rw [← pow_add, Odd.neg_one_pow ⟨k, by ring⟩]
      ring
    exact not_tendsto_nhds_of_tendsto_atBot hlim L hL
  · have hax : 1 < |x| := by
      rcases hx with h | h
      · rw [abs_of_neg (by linarith)]; exact lt_of_le_of_ne (by linarith) (fun h' => hne (by linarith))
      · rw [abs_of_pos (by linarith)]; exact h
    have hd : Tendsto (fun n : ℕ => (-1 : ℝ) ^ n * x ^ (n + 1) / (n + 1)) atTop (𝓝 0) := by
      have := (hL.comp (tendsto_add_atTop_nat 1)).sub hL
      rw [sub_self] at this
      refine this.congr fun n => ?_
      simp [Finset.sum_range_succ]
    have ha : Tendsto (fun n : ℕ => |x| ^ (n + 1) / (n + 1)) atTop (𝓝 0) := by
      have := hd.abs
      rw [abs_zero] at this
      refine this.congr fun n => ?_
      rw [abs_div, abs_mul, abs_pow, abs_neg, abs_one, one_pow, one_mul, abs_pow]
      congr 1
      exact abs_of_pos (by positivity)
    have hb : Tendsto (fun n : ℕ => ((n + 1 : ℕ) : ℝ) ^ 1 / |x| ^ (n + 1)) atTop (𝓝 0) :=
      (tendsto_pow_const_div_const_pow_of_one_lt 1 hax).comp (tendsto_add_atTop_nat 1)
    have hprod := ha.mul hb
    rw [mul_zero] at hprod
    have hone : Tendsto (fun n : ℕ => |x| ^ (n + 1) / (n + 1) * (((n + 1 : ℕ) : ℝ) ^ 1 /
        |x| ^ (n + 1))) atTop (𝓝 1) := by
      refine tendsto_const_nhds.congr fun n => ?_
      have h1 : (0 : ℝ) < |x| ^ (n + 1) := by positivity
      push_cast
      field_simp
    exact one_ne_zero (tendsto_nhds_unique hone hprod)

/-- The smooth impostor g(x) = e^(−1/x²), with g(0) = 0. -/
noncomputable def impostor (x : ℝ) : ℝ := if x = 0 then 0 else Real.exp (-1 / x ^ 2)

theorem taylorHelper_impostor_eq : impostor = expNegInvGlue ∘ fun x => x ^ 2 := by
  funext x
  simp only [impostor, Function.comp, expNegInvGlue]
  by_cases h : x = 0
  · simp [h]
  · have : ¬ x ^ 2 ≤ 0 := not_le.2 (by positivity)
    simp only [h, this, ↓reduceIte, neg_div, one_div]

#print axioms taylorHelper_impostor_eq

/-- Every derivative is not enough. The impostor g has every derivative at every point, and
every derivative of g at 0 is 0, so each Taylor polynomial at 0 is 0; yet g(x) is not 0 for
any x ≠ 0, so the Taylor series at 0 equals g nowhere but the centre. -/
theorem smooth_impostor_not_equal_to_its_taylor_series :
    ContDiff ℝ ∞ impostor ∧
    (∀ k : ℕ, iteratedDeriv k impostor 0 = 0) ∧
    ∀ x : ℝ, x ≠ 0 → ¬ Tendsto (fun n => ∑ k ∈ range (n + 1),
        iteratedDeriv k impostor 0 / k ! * x ^ k) atTop (𝓝 (impostor x)) := by
  have hzero : ∀ k : ℕ, iteratedDeriv k impostor 0 = 0 := by
    intro k
    set D : ℝ := 1 + ∑ i ∈ range (k + 1), ‖iteratedFDeriv ℝ i (fun x : ℝ => x ^ 2) 0‖ with hD
    have hD1 : 1 ≤ D := by
      have : 0 ≤ ∑ i ∈ range (k + 1), ‖iteratedFDeriv ℝ i (fun x : ℝ => x ^ 2) 0‖ :=
        Finset.sum_nonneg fun _ _ => norm_nonneg _
      linarith
    have key := norm_iteratedFDeriv_comp_le (g := expNegInvGlue) (f := fun x : ℝ => x ^ 2)
      (N := ∞) (n := k) (expNegInvGlue.contDiff (n := ⊤)) (contDiff_id.pow 2)
      (by exact_mod_cast le_top) 0 (C := 0) (D := D) ?_ ?_
    · rw [mul_zero, zero_mul, ← taylorHelper_impostor_eq,
        norm_iteratedFDeriv_eq_norm_iteratedDeriv] at key
      exact norm_le_zero_iff.1 key
    · intro i _
      rw [norm_iteratedFDeriv_eq_norm_iteratedDeriv]
      simp [taylorHelper_glue_iteratedDeriv_zero]
    · intro i hi1 hik
      have h1 : ‖iteratedFDeriv ℝ i (fun x : ℝ => x ^ 2) 0‖ ≤
          ∑ j ∈ range (k + 1), ‖iteratedFDeriv ℝ j (fun x : ℝ => x ^ 2) 0‖ :=
        Finset.single_le_sum (f := fun j => ‖iteratedFDeriv ℝ j (fun x : ℝ => x ^ 2) 0‖)
          (fun _ _ => norm_nonneg _) (Finset.mem_range.2 (by omega))
      calc ‖iteratedFDeriv ℝ i (fun x : ℝ => x ^ 2) 0‖ ≤ D := by linarith
        _ ≤ D ^ i := le_self_pow₀ hD1 (by omega)
  refine ⟨?_, hzero, fun x hx h => ?_⟩
  · rw [taylorHelper_impostor_eq]
    exact (expNegInvGlue.contDiff (n := ⊤)).comp (contDiff_id.pow 2)
  · simp only [hzero, zero_div, zero_mul, Finset.sum_const_zero] at h
    have := tendsto_nhds_unique tendsto_const_nhds h
    simp only [impostor, hx, ↓reduceIte] at this
    exact (Real.exp_pos _).ne' this.symm

/-! The card's exact worked numbers for e² at x = 2: each term is 2^k / k!. -/

-- Terms k = 0 to 2: 1 + 2 + 4/2 = 5.
example : ∑ k ∈ range 3, (2 : ℚ) ^ k / k ! = 5 := by
  norm_num [Finset.sum_range_succ, Nat.factorial]

-- Terms k = 0 to 5: T_5(2) = 5 + 8/6 + 16/24 + 32/120 = 109/15 = 7.2666…
example : ∑ k ∈ range 6, (2 : ℚ) ^ k / k ! = 109 / 15 := by
  norm_num [Finset.sum_range_succ, Nat.factorial]

-- Leftover bound at n = 5: 9 · 2^6 / 6! = 576/720 = 0.8.
example : (9 * 2 ^ 6 / 6 ! : ℚ) = 576 / 720 ∧ (576 / 720 : ℚ) = 4 / 5 := by
  norm_num [Nat.factorial]

-- The first n with 9 · 2^(n+1) / (n+1)! under 0.001 is n = 10.
example : (9 * 2 ^ 11 / 11 ! : ℚ) < 1 / 1000 ∧
    ∀ n < 10, ¬ ((9 * 2 ^ (n + 1) / (n + 1) ! : ℚ) < 1 / 1000) := by
  refine ⟨by norm_num [Nat.factorial], fun n hn => ?_⟩
  interval_cases n <;> norm_num [Nat.factorial]

-- Dropping the factorials: 1 + 2 + 4 + ⋯ + 2^20 = 2097151.
example : ∑ k ∈ range 21, 2 ^ k = 2097151 := by
  decide

#print axioms exp_sin_cos_log_equal_their_taylor_series
#print axioms log_one_add_taylor_series_diverges_outside
#print axioms smooth_impostor_not_equal_to_its_taylor_series
