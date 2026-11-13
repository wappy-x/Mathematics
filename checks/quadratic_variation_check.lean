-- Quadratic variation: for a Brownian motion, the sum of squared increments over n equal steps of [0, t] averages t with mean squared error 2t^2/n, so it converges to t in mean square, almost surely along halving grids, and the path has infinite total variation on [0, t].
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Topology.EMetricSpace.BoundedVariation
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Constructions.Polish.Basic

open MeasureTheory ProbabilityTheory Filter Topology
open scoped NNReal ENNReal

/-! Mathlib's `IsBrownianReal W P` says that `W : ℝ≥0 → Ω → ℝ` is a Brownian motion under `P`:
its finite-dimensional laws are those of Brownian motion (start at 0, independent increments,
an increment over a stretch of length `h` is normal with mean 0 and variance `h`) and its paths
are continuous almost surely. -/

/-- The card's `Q_n`: cut the stretch from `0` to `t` into `n` equal steps at the times
`t_k = k t / n`, square each move `W(t_{k+1}) - W(t_k)` and add the squares. -/
noncomputable def sumSqIncrements {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (t : ℝ≥0) (n : ℕ) (ω : Ω) : ℝ :=
  ∑ k ∈ Finset.range n, (W ((k + 1 : ℕ) * t / n) ω - W ((k : ℕ) * t / n) ω) ^ 2

lemma qv_gauss_moment_four (v : ℝ≥0) : ∫ x, x ^ 4 ∂gaussianReal 0 v = 3 * (v : ℝ) ^ 2 := by
  have h1 : ∫ x, x ^ 4 ∂gaussianReal 0 v = iteratedDeriv 4 (mgf (fun x ↦ x) (gaussianReal 0 v)) 0 := by
    rw [iteratedDeriv_mgf_zero] <;> simp
  rw [h1, mgf_fun_id_gaussianReal]
  set c : ℝ := (v : ℝ)
  have d1 : ∀ t : ℝ, HasDerivAt (fun t ↦ Real.exp (0 * t + c * t ^ 2 / 2))
      (c * t * Real.exp (0 * t + c * t ^ 2 / 2)) t := by
    intro t
    have := ((((hasDerivAt_id t).const_mul 0).add (((hasDerivAt_pow 2 t).const_mul c).div_const 2))).exp
    exact this.congr_deriv (by simp only [id_eq, Pi.add_apply]; ring)
  have e1 : deriv (fun t ↦ Real.exp (0 * t + c * t ^ 2 / 2)) =
      fun t ↦ c * t * Real.exp (0 * t + c * t ^ 2 / 2) := funext fun t ↦ (d1 t).deriv
  have d2 : ∀ t : ℝ, HasDerivAt (fun t ↦ c * t * Real.exp (0 * t + c * t ^ 2 / 2))
      ((c + c ^ 2 * t ^ 2) * Real.exp (0 * t + c * t ^ 2 / 2)) t := by
    intro t
    have := (((hasDerivAt_id t).const_mul c).mul (d1 t))
    exact this.congr_deriv (by simp only [id_eq]; ring)
  have e2 : deriv (fun t ↦ c * t * Real.exp (0 * t + c * t ^ 2 / 2)) =
      fun t ↦ (c + c ^ 2 * t ^ 2) * Real.exp (0 * t + c * t ^ 2 / 2) :=
    funext fun t ↦ (d2 t).deriv
  have d3 : ∀ t : ℝ, HasDerivAt (fun t ↦ (c + c ^ 2 * t ^ 2) * Real.exp (0 * t + c * t ^ 2 / 2))
      ((3 * c ^ 2 * t + c ^ 3 * t ^ 3) * Real.exp (0 * t + c * t ^ 2 / 2)) t := by
    intro t
    have := ((((hasDerivAt_pow 2 t).const_mul (c ^ 2)).const_add c).mul (d1 t))
    exact this.congr_deriv (by ring)
  have e3 : deriv (fun t ↦ (c + c ^ 2 * t ^ 2) * Real.exp (0 * t + c * t ^ 2 / 2)) =
      fun t ↦ (3 * c ^ 2 * t + c ^ 3 * t ^ 3) * Real.exp (0 * t + c * t ^ 2 / 2) :=
    funext fun t ↦ (d3 t).deriv
  have d4 : HasDerivAt (fun t ↦ (3 * c ^ 2 * t + c ^ 3 * t ^ 3) * Real.exp (0 * t + c * t ^ 2 / 2))
      (3 * c ^ 2) 0 := by
    have := ((((hasDerivAt_id (0:ℝ)).const_mul (3 * c ^ 2)).add
      ((hasDerivAt_pow 3 (0:ℝ)).const_mul (c ^ 3))).mul (d1 0))
    exact this.congr_deriv (by norm_num)
  simp only [iteratedDeriv_succ, iteratedDeriv_zero]
  rw [e1, e2, e3, d4.deriv]

lemma qv_gauss_moment_two (v : ℝ≥0) : ∫ x, x ^ 2 ∂gaussianReal 0 v = v := by
  have := variance_fun_id_gaussianReal (μ := 0) (v := v)
  rw [variance_eq_integral measurable_id'.aemeasurable] at this
  simpa using this

lemma qv_memLp_sq_gauss (v : ℝ≥0) : MemLp (fun x : ℝ ↦ x ^ 2) 2 (gaussianReal 0 v) := by
  rw [memLp_two_iff_integrable_sq (by fun_prop)]
  have := integrable_pow_of_mem_interior_integrableExpSet (X := fun x : ℝ ↦ x)
    (μ := gaussianReal 0 v) (by simp) 4
  refine this.congr (ae_of_all _ fun x ↦ ?_)
  dsimp only
  ring

lemma qv_step_sub (t : ℝ≥0) (n k : ℕ) :
    ((((k + 1 : ℕ) : ℝ≥0) * t / n : ℝ≥0) : ℝ) - ((((k : ℕ) : ℝ≥0) * t / n : ℝ≥0) : ℝ)
      = (t : ℝ) / n := by
  push_cast; ring

lemma qv_incr_law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsPreBrownianReal W P) (t : ℝ≥0) (n k : ℕ) :
    HasLaw (fun ω ↦ W ((k + 1 : ℕ) * t / n) ω - W ((k : ℕ) * t / n) ω)
      (gaussianReal 0 (t / n)) P := by
  have e : nndist ((((k + 1 : ℕ) : ℝ≥0) * t / n : ℝ≥0) : ℝ) ((((k : ℕ) : ℝ≥0) * t / n : ℝ≥0) : ℝ)
      = t / n := by
    apply NNReal.eq
    rw [coe_nndist, Real.dist_eq, qv_step_sub, abs_of_nonneg (by positivity)]
    push_cast
    rfl
  convert hW.hasLaw_sub ((k + 1 : ℕ) * t / n) ((k : ℕ) * t / n) using 2
  exact e.symm

lemma qv_memLp {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsPreBrownianReal W P) (t : ℝ≥0) (n : ℕ) :
    MemLp (sumSqIncrements W t n) 2 P := by
  have h : ∀ k, MemLp (fun ω ↦ (W ((k + 1 : ℕ) * t / n) ω - W ((k : ℕ) * t / n) ω) ^ 2) 2 P :=
    fun k ↦ (qv_incr_law hW t n k).memLp_comp (qv_memLp_sq_gauss _)
  have := memLp_finsetSum' (Finset.range n) (fun k _ ↦ h k)
  convert this using 1
  funext ω
  simp [sumSqIncrements, Finset.sum_apply]

/-- Deterministic part of Theorem 3: if every step moves by less than `ε`, the sum of squared
moves is at most `ε` times the total variation. -/
lemma qv_det_bound (f : ℝ≥0 → ℝ) (t : ℝ≥0) (n : ℕ) (hn : n ≠ 0) (ε δ : ℝ) (hε : 0 ≤ ε)
    (hV : eVariationOn f (Set.Icc 0 t) ≠ ∞)
    (hδf : ∀ x ∈ Set.Icc 0 t, ∀ y ∈ Set.Icc 0 t, dist x y < δ → dist (f x) (f y) < ε)
    (hmesh : (t : ℝ) / n < δ) :
    ∑ k ∈ Finset.range n, (f ((k + 1 : ℕ) * t / n) - f ((k : ℕ) * t / n)) ^ 2 ≤
      ε * (eVariationOn f (Set.Icc 0 t)).toReal := by
  let u : ℕ → ℝ≥0 := fun i ↦ (i : ℝ≥0) * t / n
  have hn' : (0 : ℝ≥0) < n := by exact_mod_cast Nat.pos_of_ne_zero hn
  have hu_mem : ∀ i ≤ n, u i ∈ Set.Icc 0 t := by
    intro i hi
    refine ⟨by positivity, ?_⟩
    simp only [u]
    rw [div_le_iff₀ hn', mul_comm]
    gcongr
  have hu_mono : MonotoneOn u (Set.Iic n) := fun a _ b _ hab ↦ by
    simp only [u]
    gcongr
  have hsum := eVariationOn.sum_le_of_monotoneOn_Iic (f := f) hu_mono hu_mem
  have hstep : ∀ k ∈ Finset.range n, |f (u (k + 1)) - f (u k)| < ε := by
    intro k hk
    have hk' := Finset.mem_range.1 hk
    have := hδf _ (hu_mem (k + 1) hk') _ (hu_mem k hk'.le) (by
      rw [NNReal.dist_eq]
      simp only [u]
      rw [qv_step_sub, abs_of_nonneg (by positivity)]
      exact hmesh)
    rwa [Real.dist_eq] at this
  have hreal : ∑ k ∈ Finset.range n, |f (u (k + 1)) - f (u k)| ≤
      (eVariationOn f (Set.Icc 0 t)).toReal := by
    rw [← ENNReal.ofReal_le_iff_le_toReal hV,
      ENNReal.ofReal_sum_of_nonneg (fun _ _ ↦ abs_nonneg _)]
    refine le_trans (le_of_eq ?_) hsum
    refine Finset.sum_congr rfl fun k _ ↦ ?_
    rw [edist_dist, Real.dist_eq]
  calc ∑ k ∈ Finset.range n, (f ((k + 1 : ℕ) * t / n) - f ((k : ℕ) * t / n)) ^ 2
      = ∑ k ∈ Finset.range n, |f (u (k + 1)) - f (u k)| * |f (u (k + 1)) - f (u k)| := by
        refine Finset.sum_congr rfl fun k _ ↦ ?_
        rw [← sq, sq_abs]
    _ ≤ ∑ k ∈ Finset.range n, ε * |f (u (k + 1)) - f (u k)| :=
        Finset.sum_le_sum fun k hk ↦ mul_le_mul_of_nonneg_right (hstep k hk).le (abs_nonneg _)
    _ = ε * ∑ k ∈ Finset.range n, |f (u (k + 1)) - f (u k)| := (Finset.mul_sum _ _ _).symm
    _ ≤ ε * (eVariationOn f (Set.Icc 0 t)).toReal := mul_le_mul_of_nonneg_left hreal hε

/-- The card's main claim, with its exact rate. For a Brownian motion and `n ≥ 1` equal steps of
the stretch from `0` to `t`, the sum of squared moves averages exactly `t`, its mean squared error
is `2t^2/n`, and so the mean squared error goes to `0` as the grid gets finer: the sum of squares
converges to `t` in mean square. -/
theorem sum_sq_increments_tendsto_t_in_mean_square {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (t : ℝ≥0) :
    (∀ n : ℕ, 1 ≤ n →
        ∫ ω, sumSqIncrements W t n ω ∂P = t ∧
        ∫ ω, (sumSqIncrements W t n ω - t) ^ 2 ∂P = 2 * (t : ℝ) ^ 2 / n) ∧
      Tendsto (fun n : ℕ => ∫ ω, (sumSqIncrements W t n ω - t) ^ 2 ∂P) atTop (𝓝 0) := by
  have hP : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  have key : ∀ n : ℕ, 1 ≤ n →
      ∫ ω, sumSqIncrements W t n ω ∂P = t ∧
      ∫ ω, (sumSqIncrements W t n ω - t) ^ 2 ∂P = 2 * (t : ℝ) ^ 2 / n := by
    intro n hn
    have hn0 : (n : ℝ) ≠ 0 := by exact_mod_cast (Nat.one_le_iff_ne_zero.1 hn)
    let D : ℕ → Ω → ℝ := fun k ω ↦ W ((k + 1 : ℕ) * t / n) ω - W ((k : ℕ) * t / n) ω
    let Y : ℕ → Ω → ℝ := fun k ω ↦ D k ω ^ 2
    have hlaw : ∀ k, HasLaw (D k) (gaussianReal 0 (t / n)) P :=
      fun k ↦ qv_incr_law hW.toIsPreBrownianReal t n k
    have hmem : ∀ k, MemLp (Y k) 2 P := fun k ↦ (hlaw k).memLp_comp (qv_memLp_sq_gauss _)
    have hint : ∀ k, Integrable (Y k) P := fun k ↦ (hmem k).integrable one_le_two
    have hEY : ∀ k, P[Y k] = (t : ℝ) / n := fun k ↦ by
      have := (hlaw k).integral_comp (f := fun x : ℝ ↦ x ^ 2) (by fun_prop)
      rw [qv_gauss_moment_two] at this
      rw [show Y k = (fun x : ℝ ↦ x ^ 2) ∘ D k from rfl, this]
      push_cast; rfl
    have hEY2 : ∀ k, P[Y k ^ 2] = 3 * ((t : ℝ) / n) ^ 2 := fun k ↦ by
      have := (hlaw k).integral_comp (f := fun x : ℝ ↦ x ^ 4) (by fun_prop)
      rw [qv_gauss_moment_four] at this
      have e : Y k ^ 2 = (fun x : ℝ ↦ x ^ 4) ∘ D k := by
        funext ω
        simp only [Pi.pow_apply, Function.comp_apply, Y]
        ring
      rw [e, this]
      push_cast; rfl
    have hQ : sumSqIncrements W t n = ∑ k ∈ Finset.range n, Y k := by
      funext ω
      simp [sumSqIncrements, Y, D, Finset.sum_apply]
    have hEQ : ∫ ω, sumSqIncrements W t n ω ∂P = t := by
      rw [hQ]
      simp only [Finset.sum_apply]
      rw [integral_finsetSum _ (fun k _ ↦ hint k)]
      simp only [hEY, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
      field_simp
    have hindep : iIndepFun D P :=
      hW.hasIndepIncrements.nat (t := fun i : ℕ ↦ (i : ℝ≥0) * t / n) (fun a b hab ↦ by
        dsimp only
        gcongr)
    have hvar : Var[sumSqIncrements W t n; P] = 2 * (t : ℝ) ^ 2 / n := by
      rw [hQ, IndepFun.variance_sum (fun k _ ↦ hmem k)]
      · have hv : ∀ k, Var[Y k; P] = 2 * ((t : ℝ) / n) ^ 2 := fun k ↦ by
          rw [variance_eq_sub (hmem k), hEY2, hEY]
          ring
        simp only [hv, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
        field_simp
      · intro i _ j _ hij
        exact (hindep.indepFun hij).comp (measurable_id.pow_const 2) (measurable_id.pow_const 2)
    refine ⟨hEQ, ?_⟩
    rw [← hvar, variance_eq_integral
      (qv_memLp hW.toIsPreBrownianReal t n).aestronglyMeasurable.aemeasurable, hEQ]
  refine ⟨key, ?_⟩
  refine (tendsto_const_div_atTop_nhds_zero_nat (2 * (t : ℝ) ^ 2)).congr' ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  exact (key n hn).2.symm

/-- Almost sure convergence along good grids (the card's Theorem 2, for the halving grids with
`2^j` equal steps, whose step lengths `t / 2^j` add to a finite total): with probability one,
the sum of squared moves on the `j`-th halving grid converges to `t`. -/
theorem sum_sq_increments_tendsto_t_ae_on_halving_grids {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (t : ℝ≥0) :
    ∀ᵐ ω ∂P, Tendsto (fun j : ℕ => sumSqIncrements W t (2 ^ j) ω) atTop (𝓝 (t : ℝ)) := by
  have hP : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  have key := (sum_sq_increments_tendsto_t_in_mean_square hW t).1
  let F : ℕ → Ω → ℝ := fun j ω ↦ (sumSqIncrements W t (2 ^ j) ω - t) ^ 2
  have hFm : ∀ j, AEMeasurable (F j) P := fun j ↦
    (((qv_memLp hW.toIsPreBrownianReal t _).aestronglyMeasurable.aemeasurable).sub_const
      _).pow_const 2
  have hFint : ∀ j, ∫⁻ ω, ENNReal.ofReal (F j ω) ∂P
      = ENNReal.ofReal (2 * (t : ℝ) ^ 2 * (1 / 2) ^ j) := by
    intro j
    rw [← ofReal_integral_eq_lintegral_ofReal]
    · simp only [F]
      rw [(key (2 ^ j) Nat.one_le_two_pow).2]
      congr 1
      push_cast
      field_simp
      rw [mul_assoc, ← mul_pow]
      norm_num
    · exact ((qv_memLp hW.toIsPreBrownianReal t _).sub (memLp_const _)).integrable_sq
    · exact ae_of_all _ (fun ω ↦ sq_nonneg _)
  have hsum : ∫⁻ ω, ∑' j, ENNReal.ofReal (F j ω) ∂P ≠ ∞ := by
    rw [lintegral_tsum (fun j ↦ (hFm j).ennreal_ofReal)]
    simp only [hFint]
    rw [← ENNReal.ofReal_tsum_of_nonneg (fun j ↦ by positivity)
      (summable_geometric_two.mul_left _)]
    exact ENNReal.ofReal_ne_top
  have hae := ae_lt_top' (AEMeasurable.tsum fun j ↦ (hFm j).ennreal_ofReal) hsum
  filter_upwards [hae] with ω hω
  have h0 := ENNReal.tendsto_atTop_zero_of_tsum_ne_top hω.ne
  have h1 : Tendsto (fun j ↦ F j ω) atTop (𝓝 0) := by
    have := (ENNReal.tendsto_toReal ENNReal.zero_ne_top).comp h0
    simpa [Function.comp_def, ENNReal.toReal_ofReal (sq_nonneg _), F] using this
  have h2 : Tendsto (fun j ↦ |sumSqIncrements W t (2 ^ j) ω - t|) atTop (𝓝 0) := by
    have := (Real.continuous_sqrt.tendsto 0).comp h1
    simpa [Function.comp_def, F, Real.sqrt_sq_eq_abs] using this
  rw [tendsto_iff_norm_sub_tendsto_zero]
  simpa [Real.norm_eq_abs] using h2

/-- Finite quadratic variation forces infinite length (the card's Theorem 3): with probability
one, a Brownian path has infinite total variation on the stretch from `0` to `t`, for `t > 0`. -/
theorem brownian_path_infinite_variation {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (t : ℝ≥0) (ht : 0 < t) :
    ∀ᵐ ω ∂P, eVariationOn (fun s => W s ω) (Set.Icc 0 t) = ∞ := by
  filter_upwards [sum_sq_increments_tendsto_t_ae_on_halving_grids hW t, hW.cont]
    with ω hlim hcont
  by_contra hV
  set V : ℝ := (eVariationOn (fun s ↦ W s ω) (Set.Icc 0 t)).toReal with hVdef
  have hV0 : 0 ≤ V := ENNReal.toReal_nonneg
  have htpos : (0 : ℝ) < t := by exact_mod_cast ht
  set ε : ℝ := (t : ℝ) / (V + 1) with hε
  have hεpos : 0 < ε := by positivity
  have huc : UniformContinuousOn (fun s ↦ W s ω) (Set.Icc 0 t) :=
    isCompact_Icc.uniformContinuousOn_of_continuous hcont.continuousOn
  obtain ⟨δ, hδ, hδf⟩ := Metric.uniformContinuousOn_iff.1 huc ε hεpos
  have hmesh : Tendsto (fun j : ℕ ↦ (t : ℝ) / ((2 ^ j : ℕ) : ℝ)) atTop (𝓝 0) := by
    have := (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num : (0 : ℝ) ≤ 1 / 2)
      (by norm_num)).const_mul (t : ℝ)
    rw [mul_zero] at this
    refine this.congr fun j ↦ ?_
    push_cast
    field_simp
    rw [← mul_pow]
    norm_num
  have hev : ∀ᶠ j in atTop, sumSqIncrements W t (2 ^ j) ω ≤ ε * V := by
    filter_upwards [hmesh.eventually (gt_mem_nhds hδ)] with j hj
    exact qv_det_bound (fun s ↦ W s ω) t (2 ^ j) (by positivity) ε δ hεpos.le hV hδf hj
  have hle := le_of_tendsto hlim hev
  have hlt : ε * V < t := by
    rw [hε, div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]
    nlinarith
  linarith

/-! The card's exact worked arithmetic: one second, 1,000 steps of 1/1000 s. -/

-- Each step's variance is t/n = 1/1000, and 1000 of them average 1000 × 1/1000 = 1 = t.
example : (1000 : ℚ) * (1 / 1000) = 1 := by norm_num

-- The variance of the sum is 2t^2/n = 2/1000 at t = 1, n = 1000.
example : (2 : ℚ) * 1 ^ 2 / 1000 = 2 / 1000 := by norm_num

-- One squared move has variance Δt^2 (E[Z^4] - E[Z^2]^2) = Δt^2 (3 - 1) = 2 Δt^2.
example : ∀ Δt : ℚ, Δt ^ 2 * (3 - 1 ^ 2) = 2 * Δt ^ 2 := by intro Δt; ring

-- n squared moves with variance 2 Δt^2 each, Δt = t/n, give 2t^2/n.
example : ∀ t n : ℚ, n ≠ 0 → n * (2 * (t / n) ^ 2) = 2 * t ^ 2 / n := by
  intro t n hn; field_simp

-- The drift of 3 micrometres a second at 1,000 steps: t + μ^2 t^2 / n = 1 + 9/1000 = 1009/1000.
example : (1 : ℚ) + 3 ^ 2 * 1 ^ 2 / 1000 = 1009 / 1000 := by norm_num

-- The pure algebra behind the square of W: each step's change in the square is
-- 2 × (left value) × (move) + (move)^2, and the right-point version adds twice the square.
example : ∀ a b : ℚ, b ^ 2 - a ^ 2 = 2 * a * (b - a) + (b - a) ^ 2 := by intro a b; ring
example : ∀ a b : ℚ, 2 * b * (b - a) = 2 * a * (b - a) + 2 * (b - a) ^ 2 := by intro a b; ring

#print axioms sum_sq_increments_tendsto_t_in_mean_square
#print axioms sum_sq_increments_tendsto_t_ae_on_halving_grids
#print axioms brownian_path_infinite_variation
#print axioms qv_gauss_moment_four
#print axioms qv_gauss_moment_two
#print axioms qv_memLp_sq_gauss
#print axioms qv_step_sub
#print axioms qv_incr_law
#print axioms qv_memLp
#print axioms qv_det_bound
