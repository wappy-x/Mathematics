-- Picard iteration: for a rate rule that is continuous and has a Lipschitz constant L on the times 0 to T, the Picard guesses converge uniformly to a solution of y' = f(t, y), y(0) = y0, the gap between guesses n and n + 1 is at most M L^n t^(n+1)/(n+1)!, and for y' = y from 1 the guesses are the partial sums of the exponential series.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Topology.UniformSpace.UniformConvergence
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Normed.Group.FunctionSeries
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Topology.UniformSpace.UniformApproximation

open Set Filter Finset

/-- Helper: each Picard guess is continuous on the times `0` to `T`. -/
lemma picard_iterate_continuousOn (f : ℝ → ℝ → ℝ) (y₀ T : ℝ)
    (hcont : ContinuousOn (Function.uncurry f) (Icc 0 T ×ˢ univ))
    (φ : ℕ → ℝ → ℝ)
    (h0 : ∀ t ∈ Icc 0 T, φ 0 t = y₀)
    (hstep : ∀ n, ∀ t ∈ Icc 0 T, φ (n + 1) t = y₀ + ∫ s in (0)..t, f s (φ n s)) :
    ∀ n, ContinuousOn (φ n) (Icc 0 T) := by
  intro n
  induction n with
  | zero => exact (continuousOn_const (c := y₀)).congr (fun t ht => h0 t ht)
  | succ n ih =>
    rcases lt_or_ge T 0 with hT | hT
    · rw [Icc_eq_empty (not_le.mpr hT)]; exact continuousOn_empty _
    have hg : ContinuousOn (fun s => f s (φ n s)) (Icc 0 T) :=
      hcont.comp (continuousOn_id.prodMk ih) (fun s hs => ⟨hs, mem_univ _⟩)
    have hprim := intervalIntegral.continuousOn_primitive_interval' (μ := MeasureTheory.volume) (a := 0)
      (hg.intervalIntegrable_of_Icc hT) (by rw [uIcc_of_le hT]; exact ⟨le_rfl, hT⟩)
    rw [uIcc_of_le hT] at hprim
    exact (continuousOn_const.add hprim).congr (fun t ht => hstep n t ht)

/-- Helper: the gap bound `|φ (n + 1) t - φ n t| ≤ M L^n t^(n+1) / (n+1)!`. -/
lemma picard_gap_bound_aux (f : ℝ → ℝ → ℝ) (y₀ L M T : ℝ)
    (hcont : ContinuousOn (Function.uncurry f) (Icc 0 T ×ˢ univ))
    (hlip : ∀ t ∈ Icc 0 T, ∀ a b : ℝ, |f t a - f t b| ≤ L * |a - b|)
    (hM : ∀ t ∈ Icc 0 T, |f t y₀| ≤ M)
    (φ : ℕ → ℝ → ℝ)
    (h0 : ∀ t ∈ Icc 0 T, φ 0 t = y₀)
    (hstep : ∀ n, ∀ t ∈ Icc 0 T, φ (n + 1) t = y₀ + ∫ s in (0)..t, f s (φ n s)) :
    ∀ n : ℕ, ∀ t ∈ Icc 0 T,
      |φ (n + 1) t - φ n t| ≤ M * L ^ n * t ^ (n + 1) / ((n + 1).factorial : ℝ) := by
  have hφc := picard_iterate_continuousOn f y₀ T hcont φ h0 hstep
  have hcomp : ∀ h : ℝ → ℝ, ContinuousOn h (Icc 0 T) →
      ContinuousOn (fun s => f s (h s)) (Icc 0 T) := fun h hh =>
    hcont.comp (continuousOn_id.prodMk hh) (fun s hs => ⟨hs, mem_univ _⟩)
  intro n
  induction n with
  | zero =>
    intro t ht
    have hsub : uIoc (0 : ℝ) t ⊆ Icc 0 T := by
      rw [uIoc_of_le ht.1]; exact fun s hs => ⟨hs.1.le, hs.2.trans ht.2⟩
    rw [hstep 0 t ht, h0 t ht, add_sub_cancel_left]
    have hcongr : ∫ s in (0)..t, f s (φ 0 s) = ∫ s in (0)..t, f s y₀ := by
      refine intervalIntegral.integral_congr (fun s hs => ?_)
      rw [uIcc_of_le ht.1] at hs
      simp only [h0 s ⟨hs.1, hs.2.trans ht.2⟩]
    rw [hcongr]
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := 0) (b := t) (C := M)
      (f := fun s => f s y₀) (fun s hs => by rw [Real.norm_eq_abs]; exact hM s (hsub hs))
    rw [Real.norm_eq_abs, sub_zero, abs_of_nonneg ht.1] at this
    simpa using this
  | succ n ih =>
    intro t ht
    have hL : 0 ≤ L := by
      have := hlip t ht 1 0
      norm_num at this
      exact (abs_nonneg _).trans this
    have hsub : uIcc (0 : ℝ) t ⊆ Icc 0 T := by
      rw [uIcc_of_le ht.1]; exact Icc_subset_Icc le_rfl ht.2
    have int1 : IntervalIntegrable (fun s => f s (φ (n + 1) s)) MeasureTheory.volume 0 t :=
      ((hcomp _ (hφc (n + 1))).mono hsub).intervalIntegrable
    have int2 : IntervalIntegrable (fun s => f s (φ n s)) MeasureTheory.volume 0 t :=
      ((hcomp _ (hφc n)).mono hsub).intervalIntegrable
    have int3 : IntervalIntegrable (fun s => |f s (φ (n + 1) s) - f s (φ n s)|)
        MeasureTheory.volume 0 t :=
      ((((hcomp _ (hφc (n + 1))).sub (hcomp _ (hφc n))).abs).mono hsub).intervalIntegrable
    have int4 : IntervalIntegrable
        (fun s : ℝ => L * (M * L ^ n * s ^ (n + 1) / ((n + 1).factorial : ℝ)))
        MeasureTheory.volume 0 t := by
      apply Continuous.intervalIntegrable; fun_prop
    rw [hstep (n + 1) t ht, hstep n t ht, add_sub_add_left_eq_sub,
      ← intervalIntegral.integral_sub int1 int2]
    calc |∫ s in (0)..t, (f s (φ (n + 1) s) - f s (φ n s))|
        ≤ ∫ s in (0)..t, |f s (φ (n + 1) s) - f s (φ n s)| :=
          intervalIntegral.abs_integral_le_integral_abs ht.1
      _ ≤ ∫ s in (0)..t, L * (M * L ^ n * s ^ (n + 1) / ((n + 1).factorial : ℝ)) := by
          refine intervalIntegral.integral_mono_on ht.1 int3 int4 (fun s hs => ?_)
          have hs' : s ∈ Icc 0 T := ⟨hs.1, hs.2.trans ht.2⟩
          exact (hlip s hs' _ _).trans (mul_le_mul_of_nonneg_left (ih s hs') hL)
      _ = M * L ^ (n + 1) * t ^ (n + 1 + 1) / ((n + 1 + 1).factorial : ℝ) := by
          have hfun : (fun s : ℝ => L * (M * L ^ n * s ^ (n + 1) / ((n + 1).factorial : ℝ))) =
              fun s => (L * M * L ^ n / ((n + 1).factorial : ℝ)) * s ^ (n + 1) := by
            ext s; ring
          rw [hfun, intervalIntegral.integral_const_mul, integral_pow, Nat.factorial_succ (n + 1)]
          push_cast
          field_simp
          ring

/-- Picard iteration converges to a solution. Let the rule `f` be continuous for times
`0 ≤ t ≤ T` and every value `y`, and let it have a Lipschitz constant `L` there:
`|f t a - f t b| ≤ L * |a - b|`. Start from the constant guess `φ 0 t = y₀` and make each next
guess by `φ (n + 1) t = y₀ + ∫₀ᵗ f(s, φ n s) ds`. Then the guesses converge, at the same rate
at every time from `0` to `T`, to a continuous curve `y` that satisfies the integral equation
`y t = y₀ + ∫₀ᵗ f(s, y s) ds` and solves the problem `y' = f(t, y)`, `y(0) = y₀`. -/
theorem picard_iterates_converge_to_solution (f : ℝ → ℝ → ℝ) (y₀ L T : ℝ)
    (hcont : ContinuousOn (Function.uncurry f) (Icc 0 T ×ˢ univ))
    (hlip : ∀ t ∈ Icc 0 T, ∀ a b : ℝ, |f t a - f t b| ≤ L * |a - b|)
    (φ : ℕ → ℝ → ℝ)
    (h0 : ∀ t ∈ Icc 0 T, φ 0 t = y₀)
    (hstep : ∀ n, ∀ t ∈ Icc 0 T, φ (n + 1) t = y₀ + ∫ s in (0)..t, f s (φ n s)) :
    ∃ y : ℝ → ℝ, TendstoUniformlyOn φ y atTop (Icc 0 T) ∧ ContinuousOn y (Icc 0 T) ∧
      (∀ t ∈ Icc 0 T, y t = y₀ + ∫ s in (0)..t, f s (y s)) ∧
      y 0 = y₀ ∧ ∀ t ∈ Icc 0 T, HasDerivWithinAt y (f t (y t)) (Icc 0 T) t := by
  rcases lt_or_ge T 0 with hT | hT
  · have hE : Icc 0 T = ∅ := Icc_eq_empty (not_le.mpr hT)
    refine ⟨fun _ => y₀, ?_, ?_, ?_, rfl, ?_⟩
    · rw [hE]; exact tendstoUniformlyOn_empty
    · rw [hE]; exact continuousOn_empty _
    · intro t ht; rw [hE] at ht; simp at ht
    · intro t ht; rw [hE] at ht; simp at ht
  -- a nonnegative Lipschitz constant
  obtain ⟨L', hL', hlip'⟩ : ∃ L' : ℝ, 0 < L' ∧
      ∀ t ∈ Icc 0 T, ∀ a b : ℝ, |f t a - f t b| ≤ L' * |a - b| :=
    ⟨max L 0 + 1, by positivity, fun t ht a b =>
      (hlip t ht a b).trans (mul_le_mul_of_nonneg_right
        (by linarith [le_max_left L 0]) (abs_nonneg _))⟩
  have hcomp : ∀ h : ℝ → ℝ, ContinuousOn h (Icc 0 T) →
      ContinuousOn (fun s => f s (h s)) (Icc 0 T) := fun h hh =>
    hcont.comp (continuousOn_id.prodMk hh) (fun s hs => ⟨hs, mem_univ _⟩)
  obtain ⟨M, hM⟩ := isCompact_Icc.exists_bound_of_continuousOn
    (hcomp (fun _ => y₀) continuousOn_const)
  have hM' : ∀ t ∈ Icc 0 T, |f t y₀| ≤ M := fun t ht => by
    simpa [Real.norm_eq_abs] using hM t ht
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM' 0 ⟨le_rfl, hT⟩)
  have hgap := picard_gap_bound_aux f y₀ L' M T hcont hlip' hM' φ h0 hstep
  have hφc := picard_iterate_continuousOn f y₀ T hcont φ h0 hstep
  -- the series of gaps
  obtain ⟨d, hd⟩ : ∃ d : ℕ → ℝ → ℝ, d = fun n t => φ (n + 1) t - φ n t := ⟨_, rfl⟩
  obtain ⟨u, hu⟩ : ∃ u : ℕ → ℝ, u = fun n => M * L' ^ n * T ^ (n + 1) / ((n + 1).factorial : ℝ) :=
    ⟨_, rfl⟩
  have hus : Summable u := by
    have h1 : Summable (fun n : ℕ => (L' * T) ^ (n + 1) / ((n + 1).factorial : ℝ)) :=
      (summable_nat_add_iff 1).mpr (Real.summable_pow_div_factorial (L' * T))
    have h2 := h1.mul_left (M / L')
    convert h2 using 1
    ext n
    rw [hu, mul_pow, pow_succ L']
    field_simp
  have hbound : ∀ n t, t ∈ Icc 0 T → ‖d n t‖ ≤ u n := by
    intro n t ht
    rw [hd, hu, Real.norm_eq_abs]
    dsimp only
    refine (hgap n t ht).trans ?_
    have : t ^ (n + 1) ≤ T ^ (n + 1) := pow_le_pow_left₀ ht.1 ht.2 _
    gcongr
  have hTU := tendstoUniformlyOn_tsum_nat hus hbound
  obtain ⟨y, hy⟩ : ∃ y : ℝ → ℝ, y = fun t => y₀ + ∑' n, d n t := ⟨_, rfl⟩
  have hφsum : ∀ N, ∀ t ∈ Icc 0 T, φ N t = y₀ + ∑ n ∈ range N, d n t := by
    intro N t ht
    rw [hd]
    simp only
    rw [Finset.sum_range_sub (fun n => φ n t), h0 t ht]
    ring
  have hconv : TendstoUniformlyOn φ y atTop (Icc 0 T) := by
    rw [Metric.tendstoUniformlyOn_iff] at hTU ⊢
    intro ε hε
    filter_upwards [hTU ε hε] with N hN t ht
    rw [hφsum N t ht, hy]
    simp only
    rw [dist_add_left]
    exact hN t ht
  have hyc : ContinuousOn y (Icc 0 T) :=
    hconv.continuousOn (Eventually.of_forall hφc).frequently
  have hgc := hcomp y hyc
  have hint : ∀ t ∈ Icc 0 T, y t = y₀ + ∫ s in (0)..t, f s (y s) := by
    intro t ht
    have hsub : uIcc (0 : ℝ) t ⊆ Icc 0 T := by
      rw [uIcc_of_le ht.1]; exact Icc_subset_Icc le_rfl ht.2
    have h1 : Tendsto (fun n => φ (n + 1) t) atTop (nhds (y t)) :=
      (hconv.tendsto_at ht).comp (tendsto_add_atTop_nat 1)
    have h2 : Tendsto (fun n => φ (n + 1) t) atTop
        (nhds (y₀ + ∫ s in (0)..t, f s (y s))) := by
      rw [Metric.tendsto_atTop]
      intro ε hε
      have hpos : 0 < L' * T + 1 := by positivity
      obtain ⟨N, hN⟩ := eventually_atTop.mp
        (Metric.tendstoUniformlyOn_iff.mp hconv (ε / (L' * T + 1)) (by positivity))
      refine ⟨N, fun n hn => ?_⟩
      have int1 : IntervalIntegrable (fun s => f s (φ n s)) MeasureTheory.volume 0 t :=
        ((hcomp _ (hφc n)).mono hsub).intervalIntegrable
      have int2 : IntervalIntegrable (fun s => f s (y s)) MeasureTheory.volume 0 t :=
        (hgc.mono hsub).intervalIntegrable
      rw [hstep n t ht, dist_add_left, dist_eq_norm,
        ← intervalIntegral.integral_sub int1 int2]
      calc ‖∫ s in (0)..t, (f s (φ n s) - f s (y s))‖
          ≤ (L' * (ε / (L' * T + 1))) * |t - 0| := by
            refine intervalIntegral.norm_integral_le_of_norm_le_const (fun s hs => ?_)
            have hs' : s ∈ Icc 0 T := hsub (uIoc_subset_uIcc hs)
            rw [Real.norm_eq_abs]
            refine (hlip' s hs' _ _).trans (mul_le_mul_of_nonneg_left ?_ hL'.le)
            have := hN n hn s hs'
            rw [Real.dist_eq, abs_sub_comm] at this
            exact this.le
        _ ≤ (L' * (ε / (L' * T + 1))) * T := by
            rw [sub_zero, abs_of_nonneg ht.1]
            gcongr
            exact ht.2
        _ = ε * (L' * T) / (L' * T + 1) := by field_simp
        _ < ε := by
            rw [div_lt_iff₀ hpos]
            nlinarith
    exact tendsto_nhds_unique h1 h2
  refine ⟨y, hconv, hyc, hint, ?_, ?_⟩
  · rw [hint 0 ⟨le_rfl, hT⟩, intervalIntegral.integral_same, add_zero]
  · intro t ht
    obtain ⟨g, hg⟩ : ∃ g : ℝ → ℝ, g = fun s => f (projIcc 0 T hT s) (y (projIcc 0 T hT s)) :=
      ⟨_, rfl⟩
    have hgcont : Continuous g := by
      rw [hg]
      exact hgc.comp_continuous (continuous_subtype_val.comp continuous_projIcc)
        (fun s => (projIcc 0 T hT s).2)
    have hgeq : ∀ s ∈ Icc 0 T, g s = f s (y s) := by
      intro s hs
      rw [hg]
      simp only [projIcc_of_mem hT hs]
    have hderiv : HasDerivAt (fun u => y₀ + ∫ s in (0)..u, g s) (g t) t :=
      ((hgcont.integral_hasStrictDerivAt 0 t).hasDerivAt).const_add y₀
    rw [← hgeq t ht]
    refine hderiv.hasDerivWithinAt.congr_of_mem (fun u hu => ?_) ht
    rw [hint u hu]
    congr 1
    refine intervalIntegral.integral_congr (fun s hs => ?_)
    rw [uIcc_of_le hu.1] at hs
    exact (hgeq s ⟨hs.1, hs.2.trans hu.2⟩).symm

/-- The gaps between guesses shrink like a factorial. With the same rule, Lipschitz constant
`L` and guesses as above, let `M` bound the rate the starting guess produces:
`|f t y₀| ≤ M` for `0 ≤ t ≤ T`. Then at every time `t` from `0` to `T` and for every pass `n`,
`|φ (n + 1) t - φ n t| ≤ M * L ^ n * t ^ (n + 1) / (n + 1)!`. -/
theorem picard_gap_le_factorial_bound (f : ℝ → ℝ → ℝ) (y₀ L M T : ℝ)
    (hcont : ContinuousOn (Function.uncurry f) (Icc 0 T ×ˢ univ))
    (hlip : ∀ t ∈ Icc 0 T, ∀ a b : ℝ, |f t a - f t b| ≤ L * |a - b|)
    (hM : ∀ t ∈ Icc 0 T, |f t y₀| ≤ M)
    (φ : ℕ → ℝ → ℝ)
    (h0 : ∀ t ∈ Icc 0 T, φ 0 t = y₀)
    (hstep : ∀ n, ∀ t ∈ Icc 0 T, φ (n + 1) t = y₀ + ∫ s in (0)..t, f s (φ n s)) :
    ∀ n : ℕ, ∀ t ∈ Icc 0 T,
      |φ (n + 1) t - φ n t| ≤ M * L ^ n * t ^ (n + 1) / ((n + 1).factorial : ℝ) := by
  exact picard_gap_bound_aux f y₀ L M T hcont hlip hM φ h0 hstep

/-- The yeast: for `y' = y` from `y(0) = 1`, the Picard guesses are the partial sums of the
exponential series, `φ n t = 1 + t + t²/2! + ... + tⁿ/n!`, at every time `t`. -/
theorem yeast_picard_iterates_are_exp_partial_sums (φ : ℕ → ℝ → ℝ)
    (h0 : ∀ t, φ 0 t = 1)
    (hstep : ∀ n t, φ (n + 1) t = 1 + ∫ s in (0)..t, φ n s) :
    ∀ n : ℕ, ∀ t : ℝ, φ n t = ∑ k ∈ range (n + 1), t ^ k / (k.factorial : ℝ) := by
  intro n
  induction n with
  | zero => intro t; simp [h0]
  | succ n ih =>
    intro t
    have hfun : φ n = fun s => ∑ k ∈ range (n + 1), s ^ k / (k.factorial : ℝ) := funext ih
    rw [hstep, hfun, intervalIntegral.integral_finsetSum
      (fun k _ => by apply Continuous.intervalIntegrable; fun_prop)]
    rw [Finset.sum_range_succ' _ (n + 1)]
    simp only [intervalIntegral.integral_div, integral_pow, pow_zero, Nat.factorial_zero,
      Nat.cast_one, div_one]
    rw [add_comm]
    congr 1
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [Nat.factorial_succ]
    push_cast
    field_simp
    ring

-- The yeast at 1 pm, guesses 0 to 5: 1, 2, 5/2, 8/3, 65/24 and 163/60 grams (163/60 = 2.716667).
example : ∑ k ∈ range 1, (1 : ℚ) / k.factorial = 1 := by norm_num [Finset.sum_range_succ, Nat.factorial]
example : ∑ k ∈ range 2, (1 : ℚ) / k.factorial = 2 := by norm_num [Finset.sum_range_succ, Nat.factorial]
example : ∑ k ∈ range 3, (1 : ℚ) / k.factorial = 5 / 2 := by norm_num [Finset.sum_range_succ, Nat.factorial]
example : ∑ k ∈ range 4, (1 : ℚ) / k.factorial = 8 / 3 := by norm_num [Finset.sum_range_succ, Nat.factorial]
example : ∑ k ∈ range 5, (1 : ℚ) / k.factorial = 65 / 24 := by norm_num [Finset.sum_range_succ, Nat.factorial]
example : ∑ k ∈ range 6, (1 : ℚ) / k.factorial = 163 / 60 := by norm_num [Finset.sum_range_succ, Nat.factorial]
-- The guaranteed gap after guess 5: 2/6! = 2/720 = 1/360 g.
example : (2 : ℚ) / (Nat.factorial 6) = 1 / 360 := by norm_num [Nat.factorial]
-- Forgetting to add y₀: guess 5 keeps only t^5/5!, which at t = 1 is 1/120 g.
example : (1 : ℚ) / (Nat.factorial 5) = 1 / 120 := by norm_num [Nat.factorial]
-- y' = √y from 0: the other solution t²/4 reads 1 at t = 2.
example : (2 : ℚ) ^ 2 / 4 = 1 := by norm_num

#print axioms picard_iterate_continuousOn
#print axioms picard_gap_bound_aux
#print axioms picard_iterates_converge_to_solution
#print axioms picard_gap_le_factorial_bound
#print axioms yeast_picard_iterates_are_exp_partial_sums
