-- Mean reversion: an Ornstein-Uhlenbeck rate driven by a Brownian motion is normal with mean θ + (r₀ - θ)e^(-κt) and variance σ²/(2κ)(1 - e^(-2κt)), its expected gap halves every ln 2/κ while its variance settles at σ²/(2κ), and the Cox-Ingersoll-Ross scale function blows up at zero exactly under Feller's condition 2κθ ≥ σ².
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic.NormNum
import Mathlib

namespace OrnsteinUhlenbeckCIR

open MeasureTheory ProbabilityTheory Real Filter Topology
open scoped NNReal

lemma ou_hasLaw_gaussian_of_tendsto {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {X : ℕ → Ω → ℝ} {Y : Ω → ℝ} {v : ℕ → ℝ≥0} {v₀ : ℝ≥0}
    (hX : ∀ n, HasLaw (X n) (gaussianReal 0 (v n)) P)
    (hlim : ∀ᵐ ω ∂P, Tendsto (fun n => X n ω) atTop (𝓝 (Y ω)))
    (hv : Tendsto v atTop (𝓝 v₀)) :
    HasLaw Y (gaussianReal 0 v₀) P := by
  have hY : AEMeasurable Y P :=
    aemeasurable_of_tendsto_metrizable_ae' (fun n => (hX n).aemeasurable) hlim
  refine ⟨hY, ?_⟩
  apply Measure.ext_of_charFun
  funext s
  have h1 : Tendsto (fun n => charFun (P.map (X n)) s) atTop (𝓝 (charFun (P.map Y) s)) := by
    simp_rw [charFun_apply_real]
    rw [integral_map hY (by fun_prop)]
    have e : ∀ n, ∫ x, Complex.exp (↑s * ↑x * Complex.I) ∂(P.map (X n))
        = ∫ ω, Complex.exp (↑s * ↑(X n ω) * Complex.I) ∂P := fun n =>
      integral_map (hX n).aemeasurable (by fun_prop)
    simp_rw [e]
    refine tendsto_integral_of_dominated_convergence (fun _ => (1:ℝ)) (fun n => ?_)
      (integrable_const _) (fun n => ?_) ?_
    · exact (by fun_prop : Continuous fun x : ℝ => Complex.exp (↑s * ↑x * Complex.I)).comp_aestronglyMeasurable
        (hX n).aemeasurable.aestronglyMeasurable
    · refine ae_of_all _ (fun ω => ?_)
      rw [← Complex.ofReal_mul, Complex.norm_exp_ofReal_mul_I]
    · filter_upwards [hlim] with ω hω
      exact ((by fun_prop : Continuous fun x : ℝ => Complex.exp (↑s * ↑x * Complex.I)).tendsto _).comp hω
  have h2 : ∀ n, charFun (P.map (X n)) s
      = Complex.exp (↑s * ↑(0:ℝ) * Complex.I - ↑(v n : ℝ) * ↑s ^ 2 / 2) := fun n => by
    rw [(hX n).map_eq, charFun_gaussianReal]
  simp_rw [h2] at h1
  have h3 : Tendsto (fun n => Complex.exp (↑s * ↑(0:ℝ) * Complex.I - ↑(v n : ℝ) * ↑s ^ 2 / 2))
      atTop (𝓝 (Complex.exp (↑s * ↑(0:ℝ) * Complex.I - ↑(v₀ : ℝ) * ↑s ^ 2 / 2))) := by
    have hc : Continuous fun x : ℝ≥0 =>
        Complex.exp (↑s * ↑(0:ℝ) * Complex.I - ↑(x : ℝ) * ↑s ^ 2 / 2) := by fun_prop
    exact (hc.tendsto _).comp hv
  rw [tendsto_nhds_unique h1 h3, charFun_gaussianReal]

lemma ou_variance_limit {κ T : ℝ} (hκ : 0 < κ) (hT : 0 ≤ T) :
    Tendsto (fun n : ℕ => ∑ j ∈ Finset.range n, exp (κ * (j * T / n)) ^ 2 * (T / n)) atTop
      (𝓝 ((exp (2 * κ * T) - 1) / (2 * κ))) := by
  rcases hT.eq_or_lt with rfl | hT
  · simp
  have hslope : Tendsto (fun h : ℝ => h / (exp (2 * κ * h) - 1)) (𝓝[≠] 0) (𝓝 (1 / (2 * κ))) := by
    have hd : HasDerivAt (fun h : ℝ => exp (2 * κ * h)) (2 * κ) 0 := by
      have := ((hasDerivAt_id (0:ℝ)).const_mul (2 * κ)).exp
      simpa using this
    have := (hasDerivAt_iff_tendsto_slope_zero.mp hd).inv₀ (by positivity)
    rw [one_div]
    refine this.congr' ?_
    filter_upwards with h
    simp [div_eq_mul_inv, mul_comm]
  have hn : Tendsto (fun n : ℕ => T / n) atTop (𝓝[≠] 0) := by
    rw [tendsto_nhdsWithin_iff]
    refine ⟨tendsto_const_div_atTop_nhds_zero_nat T, ?_⟩
    filter_upwards [eventually_ge_atTop 1] with n hn
    have : (0:ℝ) < n := by exact_mod_cast hn
    exact (div_pos hT this).ne'
  have hlim := (hslope.comp hn).const_mul (exp (2 * κ * T) - 1)
  rw [show (exp (2 * κ * T) - 1) * (1 / (2 * κ)) = (exp (2 * κ * T) - 1) / (2 * κ) by ring] at hlim
  refine hlim.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  have hn0 : (0:ℝ) < n := by exact_mod_cast hn
  set q := exp (2 * κ * (T / n)) with hq
  have hq1 : q ≠ 1 := by
    rw [hq]; intro h
    have := exp_eq_one_iff _ |>.mp h
    have : 0 < 2 * κ * (T / n) := by positivity
    linarith
  have hterm : ∀ j : ℕ, exp (κ * (j * T / n)) ^ 2 * (T / n) = q ^ j * (T / n) := by
    intro j
    rw [hq, ← exp_nat_mul, ← exp_nat_mul]
    congr 2; ring
  simp_rw [hterm, ← Finset.sum_mul, geom_sum_eq hq1]
  have hqn : q ^ n = exp (2 * κ * T) := by
    rw [hq, ← exp_nat_mul]; congr 1; field_simp
  rw [hqn]
  simp only [Function.comp, ← hq]
  have : q - 1 ≠ 0 := sub_ne_zero.mpr hq1
  field_simp

lemma ou_pathwise_solution {κ θ σ r₀ T : ℝ} {y w : ℝ → ℝ} (hy : ContinuousOn y (Set.Ici 0))
    (hw : Continuous w) (heq : ∀ s, 0 ≤ s → y s = r₀ + (∫ u in (0:ℝ)..s, κ * (θ - y u)) + σ * w s)
    (hT : 0 ≤ T) :
    y T = θ + (r₀ - θ) * exp (-κ * T) +
      σ * exp (-κ * T) * (exp (κ * T) * w T - ∫ u in (0:ℝ)..T, κ * exp (κ * u) * w u) := by
  set yt : ℝ → ℝ := fun s => y (max s 0) with hyt
  have hytc : Continuous yt :=
    hy.comp_continuous (continuous_id.max continuous_const) (fun s => le_max_right s 0)
  have hint : ∀ s, 0 ≤ s → (∫ u in (0:ℝ)..s, κ * (θ - y u)) = ∫ u in (0:ℝ)..s, κ * (θ - yt u) := by
    intro s hs
    apply intervalIntegral.integral_congr
    intro u hu
    rw [Set.uIcc_of_le hs] at hu
    simp [hyt, max_eq_left hu.1]
  set z : ℝ → ℝ := fun s => r₀ + ∫ u in (0:ℝ)..s, κ * (θ - yt u) with hz
  set J : ℝ → ℝ := fun s => ∫ u in (0:ℝ)..s, exp (κ * u) * w u with hJ
  have hzd : ∀ s, HasDerivAt z (κ * (θ - yt s)) s := fun s => by
    have := (Continuous.integral_hasStrictDerivAt (f := fun u => κ * (θ - yt u))
      (by fun_prop) 0 s).hasDerivAt
    simpa [hz] using this.const_add r₀
  have hJd : ∀ s, HasDerivAt J (exp (κ * s) * w s) s := fun s =>
    (Continuous.integral_hasStrictDerivAt (f := fun u => exp (κ * u) * w u)
      (by fun_prop) 0 s).hasDerivAt
  set φ : ℝ → ℝ := fun s => exp (κ * s) * (z s - θ) + κ * σ * J s with hφ
  have hed : ∀ s, HasDerivAt (fun s => exp (κ * s)) (exp (κ * s) * κ) s := fun s => by
    simpa using ((hasDerivAt_id s).const_mul κ).exp
  have hφd : ∀ s, HasDerivAt φ (exp (κ * s) * κ * (z s - θ) + exp (κ * s) * (κ * (θ - yt s))
      + κ * σ * (exp (κ * s) * w s)) s := fun s =>
    (((hed s).mul ((hzd s).sub_const θ))).add ((hJd s).const_mul (κ * σ))
  have hzy : ∀ s, 0 ≤ s → yt s = z s + σ * w s := by
    intro s hs
    simp only [hyt, hz, max_eq_left hs]
    rw [← hint s hs]
    exact heq s hs
  have hconst := constant_of_has_deriv_right_zero (f := φ) (a := 0) (b := T)
    (fun s _ => (hφd s).continuousAt.continuousWithinAt) (fun s hs => by
      have h0 := hφd s
      have : exp (κ * s) * κ * (z s - θ) + exp (κ * s) * (κ * (θ - yt s))
          + κ * σ * (exp (κ * s) * w s) = 0 := by
        rw [hzy s hs.1]; ring
      rw [this] at h0
      exact h0.hasDerivWithinAt) T ⟨hT, le_rfl⟩
  have hφ0 : φ 0 = r₀ - θ := by simp [hφ, hz, hJ]
  rw [hφ0] at hconst
  simp only [hφ] at hconst
  have hyT : y T = z T + σ * w T := by
    have := hzy T hT
    simpa [hyt, max_eq_left hT] using this
  have hJT : (∫ u in (0:ℝ)..T, κ * exp (κ * u) * w u) = κ * J T := by
    simp only [hJ, ← intervalIntegral.integral_const_mul, mul_assoc]
  rw [hyT, hJT]
  have he : exp (-κ * T) * exp (κ * T) = 1 := by rw [← exp_add]; simp
  have hz' : z T - θ = exp (-κ * T) * (r₀ - θ - κ * σ * J T) := by
    rw [← hconst]
    linear_combination (-(z T - θ)) * he
  linear_combination hz' - σ * w T * he

lemma ou_stieltjes_sum_tendsto {κ T : ℝ} (hκ : 0 < κ) (hT : 0 ≤ T) {w : ℝ → ℝ}
    (hw : Continuous w) :
    Tendsto (fun n : ℕ => ∑ j ∈ Finset.range n,
        exp (κ * (j * T / n)) * (w (((j + 1 : ℕ) : ℝ) * T / n) - w (j * T / n))) atTop
      (𝓝 (exp (κ * T) * w T - w 0 - ∫ u in (0:ℝ)..T, κ * exp (κ * u) * w u)) := by
  set C := κ * exp (κ * T) with hC
  have hC0 : 0 ≤ C := by positivity
  have hed : ∀ x, HasDerivAt (fun x => exp (κ * x)) (κ * exp (κ * x)) x := fun x => by
    simpa [mul_comm] using ((hasDerivAt_id x).const_mul κ).exp
  rw [Metric.tendsto_nhds]
  intro ε hε
  set ε' := ε / (C * T + 1) with hε'
  have hε'0 : 0 < ε' := by positivity
  have huc := (isCompact_Icc (a := (0:ℝ)) (b := T)).uniformContinuousOn_of_continuous hw.continuousOn
  obtain ⟨δ, hδ, hδw⟩ := Metric.uniformContinuousOn_iff.mp huc ε' hε'0
  have hmesh : ∀ᶠ n : ℕ in atTop, T / n < δ :=
    (tendsto_const_div_atTop_nhds_zero_nat T).eventually (gt_mem_nhds hδ)
  filter_upwards [hmesh, eventually_ge_atTop 1] with n hn hn1
  have hn0 : (0:ℝ) < n := by exact_mod_cast hn1
  set u : ℕ → ℝ := fun j => (j : ℝ) * T / n with hu
  have hu0 : u 0 = 0 := by simp [hu]
  have hun : u n = T := by simp only [hu]; field_simp
  have hustep : ∀ j, u (j + 1) - u j = T / n := fun j => by simp only [hu]; push_cast; ring
  have humono : ∀ j, u j ≤ u (j + 1) := fun j => by
    have := hustep j; have : 0 ≤ T / n := by positivity
    linarith
  have hu_nonneg : ∀ j, 0 ≤ u j := fun j => by simp only [hu]; positivity
  have hu_le : ∀ j, j ≤ n → u j ≤ T := fun j hj => by
    simp only [hu]
    rw [div_le_iff₀ hn0]
    have : (j : ℝ) ≤ n := by exact_mod_cast hj
    nlinarith
  set E : ℕ → ℝ := fun j => ∫ x in u j..u (j + 1), κ * exp (κ * x) * (w x - w (u (j + 1)))
    with hE
  have hint : ∀ a b : ℝ, IntervalIntegrable (fun x => κ * exp (κ * x) * w x) volume a b :=
    fun a b => (by fun_prop : Continuous fun x => κ * exp (κ * x) * w x).intervalIntegrable a b
  have hkey : ∀ j, exp (κ * u j) * (w (u (j + 1)) - w (u j)) =
      (exp (κ * u (j + 1)) * w (u (j + 1)) - exp (κ * u j) * w (u j))
        - (∫ x in u j..u (j + 1), κ * exp (κ * x) * w x) + E j := by
    intro j
    have h1 : (∫ x in u j..u (j + 1), κ * exp (κ * x)) = exp (κ * u (j + 1)) - exp (κ * u j) :=
      intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hed x)
        ((by fun_prop : Continuous fun x => κ * exp (κ * x)).intervalIntegrable _ _)
    have h2 : E j = (∫ x in u j..u (j + 1), κ * exp (κ * x) * w x)
        - (∫ x in u j..u (j + 1), κ * exp (κ * x)) * w (u (j + 1)) := by
      simp only [hE, mul_sub]
      rw [intervalIntegral.integral_sub (hint _ _), intervalIntegral.integral_mul_const]
      exact ((by fun_prop : Continuous fun x => κ * exp (κ * x)).intervalIntegrable _ _).mul_const _
    rw [h2, h1]; ring
  have hsum1 : ∑ j ∈ Finset.range n, (exp (κ * u (j + 1)) * w (u (j + 1)) - exp (κ * u j) * w (u j))
      = exp (κ * T) * w T - w 0 := by
    rw [Finset.sum_range_sub (fun j => exp (κ * u j) * w (u j)), hun, hu0]; simp
  have hsum2 : ∑ j ∈ Finset.range n, (∫ x in u j..u (j + 1), κ * exp (κ * x) * w x)
      = ∫ x in (0:ℝ)..T, κ * exp (κ * x) * w x := by
    rw [intervalIntegral.sum_integral_adjacent_intervals (fun k _ => hint _ _), hu0, hun]
  have hS : (∑ j ∈ Finset.range n,
        exp (κ * (j * T / n)) * (w (((j + 1 : ℕ) : ℝ) * T / n) - w (j * T / n)))
      = (exp (κ * T) * w T - w 0 - ∫ u in (0:ℝ)..T, κ * exp (κ * u) * w u)
        + ∑ j ∈ Finset.range n, E j := by
    have : ∀ j : ℕ, exp (κ * (j * T / n)) * (w (((j + 1 : ℕ) : ℝ) * T / n) - w (j * T / n))
        = exp (κ * u j) * (w (u (j + 1)) - w (u j)) := fun j => rfl
    rw [Finset.sum_congr rfl (fun j _ => (this j).trans (hkey j)), Finset.sum_add_distrib,
      Finset.sum_sub_distrib, hsum1, hsum2]
  rw [hS, dist_eq_norm, add_sub_cancel_left]
  have hEb : ∀ j ∈ Finset.range n, ‖E j‖ ≤ C * ε' * (T / n) := by
    intro j hj
    have hjn : j + 1 ≤ n := Finset.mem_range.mp hj
    have := intervalIntegral.norm_integral_le_of_norm_le_const
      (a := u j) (b := u (j + 1)) (C := C * ε')
      (f := fun x => κ * exp (κ * x) * (w x - w (u (j + 1)))) (fun x hx => by
        rw [Set.uIoc_of_le (humono j)] at hx
        have hx0 : 0 ≤ x := le_trans (hu_nonneg j) hx.1.le
        have hxT : x ≤ T := le_trans hx.2 (hu_le _ hjn)
        have hdist : dist x (u (j + 1)) < δ := by
          rw [Real.dist_eq, abs_of_nonpos (by linarith [hx.2])]
          linarith [hustep j, hx.1]
        have hw' := hδw x ⟨hx0, hxT⟩ (u (j + 1)) ⟨hu_nonneg _, hu_le _ hjn⟩ hdist
        rw [Real.dist_eq] at hw'
        rw [norm_mul, Real.norm_eq_abs, Real.norm_eq_abs, abs_of_pos (by positivity)]
        have : κ * exp (κ * x) ≤ C := by
          rw [hC]; gcongr
        calc κ * exp (κ * x) * |w x - w (u (j + 1))| ≤ C * ε' := by
              apply mul_le_mul this hw'.le (abs_nonneg _) hC0)
    rw [abs_of_nonneg (by linarith [humono j]), hustep j] at this
    exact this
  calc ‖∑ j ∈ Finset.range n, E j‖ ≤ ∑ j ∈ Finset.range n, ‖E j‖ := norm_sum_le _ _
    _ ≤ ∑ j ∈ Finset.range n, C * ε' * (T / n) := Finset.sum_le_sum hEb
    _ = C * ε' * T := by simp; field_simp
    _ < ε := by
      rw [hε']
      have : 0 < C * T + 1 := by positivity
      rw [mul_comm C, mul_assoc, div_mul_eq_mul_div, div_lt_iff₀ this]
      nlinarith [mul_nonneg hC0 hT]

lemma ou_hasLaw_weighted_increments {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) {τ : ℕ → ℝ≥0} (hτ : Monotone τ) (c : ℕ → ℝ)
    (n : ℕ) :
    HasLaw (fun ω => ∑ j ∈ Finset.range n, c j * (W (τ (j + 1)) ω - W (τ j) ω))
      (gaussianReal 0 (∑ j ∈ Finset.range n, c j ^ 2 * ((τ (j + 1) : ℝ) - τ j)).toNNReal) P := by
  have hGP := hW.isGaussianProcess
  have hP : IsProbabilityMeasure P := hGP.isProbabilityMeasure
  set X : ℕ → Ω → ℝ := fun j ω => c j * (W (τ (j + 1)) ω - W (τ j) ω) with hX
  have hS : (fun ω => ∑ j ∈ Finset.range n, c j * (W (τ (j + 1)) ω - W (τ j) ω))
      = ∑ j ∈ Finset.range n, X j := by
    funext ω; simp [hX, Finset.sum_apply]
  have hG : HasGaussianLaw (fun ω => ∑ j ∈ Finset.range n, c j * (W (τ (j + 1)) ω - W (τ j) ω))
      P := by
    have h := hGP.hasGaussianLaw_increments (t := fun i : Fin (n + 1) => τ i)
    let L : (Fin n → ℝ) →L[ℝ] ℝ := ∑ i : Fin n, c i • ContinuousLinearMap.proj i
    have h2 := h.map_fun L
    convert h2 using 1
    funext ω
    simp only [L, FunLike.coe_sum, FunLike.coe_smul, Finset.sum_apply,
      Pi.smul_apply, smul_eq_mul, Fin.val_succ,
      Fin.val_castSucc]
    exact (Fin.sum_univ_eq_sum_range (fun j => c j * (W (τ (j + 1)) ω - W (τ j) ω)) n).symm
  have hmem : ∀ j, MemLp (X j) 2 P := fun j =>
    (hGP.hasGaussianLaw_fun_sub (s := τ (j + 1)) (t := τ j)).memLp_two.const_mul (c j)
  have hmean : P[fun ω => ∑ j ∈ Finset.range n, c j * (W (τ (j + 1)) ω - W (τ j) ω)] = 0 := by
    rw [integral_finsetSum _ (fun j _ => (hmem j).integrable one_le_two)]
    apply Finset.sum_eq_zero
    intro j _
    rw [integral_const_mul, integral_sub (hW.integrable_eval _) (hW.integrable_eval _),
      hW.integral_eval, hW.integral_eval]
    simp
  have hvar : Var[fun ω => ∑ j ∈ Finset.range n, c j * (W (τ (j + 1)) ω - W (τ j) ω); P]
      = ∑ j ∈ Finset.range n, c j ^ 2 * ((τ (j + 1) : ℝ) - τ j) := by
    rw [hS, IndepFun.variance_sum (fun j _ => hmem j)]
    · apply Finset.sum_congr rfl
      intro j _
      simp only [hX]
      rw [variance_const_mul]
      have hl := hW.hasLaw_sub (τ (j + 1)) (τ j)
      have hv : Var[fun ω => W (τ (j + 1)) ω - W (τ j) ω; P] = nndist (τ (j + 1) : ℝ) (τ j) := by
        rw [show (fun ω => W (τ (j + 1)) ω - W (τ j) ω) = W (τ (j + 1)) - W (τ j) from rfl,
          hl.variance_eq, variance_id_gaussianReal]
        rfl
      rw [hv, coe_nndist, Real.dist_eq, abs_of_nonneg]
      have := hτ (Nat.le_succ j)
      simpa using this
    · intro i _ j _ hij
      have hinc := hW.hasIndepIncrements.nat hτ
      exact (hinc.comp (fun i x => c i * x) (fun i => measurable_const_mul (c i))).indepFun hij
  exact ⟨hG.aemeasurable, by rw [hG.map_eq_gaussianReal, hmean, hvar]⟩

/-! Setting. Mathlib's `IsBrownianReal W P` says that `W : ℝ≥0 → Ω → ℝ` is a Brownian motion
under `P`: it starts at 0, its steps over separate stretches are independent and normal with
variance equal to the length of the stretch, and its paths are continuous almost surely.
`HasLaw X μ P` says the random variable `X` is measurable (up to a null set) and has law `μ`;
`gaussianReal m v` is the normal law with mean `m` and variance `v`.

Mathlib has no Ito integral, so the Ornstein-Uhlenbeck equation `dr = κ(θ - r) dt + σ dW` is
written the way the card's Detailed proof writes it, path by path:
`r_t = r₀ + ∫₀ᵗ κ(θ - r_u) du + σ W_t`. A solution has continuous paths, as usual for a
solution of a stochastic differential equation. The Cox-Ingersoll-Ross noise `σ √r dW` needs an
Ito integral, so for CIR only the analytic heart of Feller's test is stated: the third theorem. -/

/-- **The Ornstein-Uhlenbeck rate is normal** (the card's main claim). Let `W` be a Brownian
motion, `κ > 0` the pull speed, `θ` the long-run level, `σ` the noise size and `r₀` today's
rate. If the rate `r` solves `r_t = r₀ + ∫₀ᵗ κ(θ - r_u) du + σ W_t` with continuous paths
(almost surely), then at every time `t ≥ 0` the rate is normal with mean
`θ + (r₀ - θ) e^(-κt)` and variance `σ²/(2κ) (1 - e^(-2κt))`. (The variance is never negative,
so `toNNReal` only changes its type.) -/
theorem ou_rate_is_normal {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) {κ θ σ r₀ : ℝ} (hκ : 0 < κ)
    {r : ℝ → Ω → ℝ}
    (hr : ∀ᵐ ω ∂P, ContinuousOn (fun s => r s ω) (Set.Ici 0) ∧
      ∀ t : ℝ≥0, r t ω = r₀ + (∫ u in (0 : ℝ)..t, κ * (θ - r u ω)) + σ * W t ω)
    (t : ℝ≥0) :
    HasLaw (r t)
      (gaussianReal (θ + (r₀ - θ) * exp (-κ * t))
        (σ ^ 2 / (2 * κ) * (1 - exp (-2 * κ * t))).toNNReal) P := by
  have hP : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  have hT : (0 : ℝ) ≤ t := t.2
  set T : ℝ := (t : ℝ) with hTdef
  set τ : ℕ → ℕ → ℝ≥0 := fun n j => ((j : ℝ) * T / n).toNNReal with hτ
  have hτm : ∀ n, Monotone (τ n) := fun n j k hjk => by
    simp only [hτ]
    apply Real.toNNReal_le_toNNReal
    have : (j : ℝ) ≤ k := by exact_mod_cast hjk
    gcongr
  set c : ℕ → ℕ → ℝ := fun n j => exp (κ * (j * T / n)) with hc
  set S : ℕ → Ω → ℝ := fun n ω =>
    ∑ j ∈ Finset.range n, c n j * (W (τ n (j + 1)) ω - W (τ n j) ω) with hS
  set v : ℕ → ℝ≥0 := fun n =>
    (∑ j ∈ Finset.range n, c n j ^ 2 * ((τ n (j + 1) : ℝ) - τ n j)).toNNReal with hv
  have hXn : ∀ n, HasLaw (S n) (gaussianReal 0 (v n)) P := fun n =>
    ou_hasLaw_weighted_increments hW (hτm n) (c n) n
  set Y : Ω → ℝ := fun ω => exp (κ * T) * W T.toNNReal ω - W (0 : ℝ).toNNReal ω -
    ∫ u in (0:ℝ)..T, κ * exp (κ * u) * W u.toNNReal ω with hY
  have hlim : ∀ᵐ ω ∂P, Tendsto (fun n => S n ω) atTop (𝓝 (Y ω)) := by
    filter_upwards [hW.cont] with ω hω
    exact ou_stieltjes_sum_tendsto hκ hT (w := fun s => W s.toNNReal ω)
      (hω.comp continuous_real_toNNReal)
  have hvlim : Tendsto v atTop (𝓝 ((exp (2 * κ * T) - 1) / (2 * κ)).toNNReal) := by
    refine (continuous_real_toNNReal.tendsto _).comp ((ou_variance_limit hκ hT).congr fun n => ?_)
    apply Finset.sum_congr rfl
    intro j _
    simp only [hτ, hc]
    rw [Real.coe_toNNReal _ (by positivity), Real.coe_toNNReal _ (by positivity)]
    push_cast; ring
  have hYlaw := ou_hasLaw_gaussian_of_tendsto hXn hlim hvlim
  have hZ := gaussianReal_const_add (gaussianReal_const_mul hYlaw (σ * exp (-κ * T)))
    (θ + (r₀ - θ) * exp (-κ * T))
  have hae : r t =ᵐ[P] fun ω => θ + (r₀ - θ) * exp (-κ * T) + σ * exp (-κ * T) * Y ω := by
    filter_upwards [hr, hW.eval_zero_ae_eq_zero, hW.cont] with ω hω hW0 hWc
    obtain ⟨hcont, heq⟩ := hω
    have hA := ou_pathwise_solution (κ := κ) (θ := θ) (σ := σ) (r₀ := r₀) (T := T)
      (y := fun s => r s ω) (w := fun s => W s.toNNReal ω) hcont
      (hWc.comp continuous_real_toNNReal) (fun s hs => by
        have := heq s.toNNReal
        rwa [Real.coe_toNNReal s hs] at this) hT
    rw [hA]
    simp only [hY, Real.toNNReal_zero, hW0, hTdef, Real.toNNReal_coe]
    ring
  have key := hZ.congr hae
  convert key using 2
  · ring
  · have h1 : 0 ≤ (exp (2 * κ * T) - 1) / (2 * κ) := by
      apply div_nonneg _ (by positivity)
      have : 1 ≤ exp (2 * κ * T) := one_le_exp (by positivity)
      linarith
    have h2 : 0 ≤ σ ^ 2 / (2 * κ) * (1 - exp (-2 * κ * T)) := by
      apply mul_nonneg (by positivity)
      have : exp (-2 * κ * T) ≤ 1 := exp_le_one_iff.mpr (by nlinarith)
      linarith
    ext
    rw [NNReal.coe_mul, Real.coe_toNNReal _ h1, Real.coe_toNNReal _ h2, NNReal.coe_mk]
    have e1 : exp (-κ * T) ^ 2 = exp (-2 * κ * T) := by
      rw [← exp_nat_mul]; congr 1; push_cast; ring
    have e2 : exp (-2 * κ * T) * exp (2 * κ * T) = 1 := by
      rw [← exp_add]; simp
    rw [mul_pow, e1]
    linear_combination -(σ ^ 2 / (2 * κ)) * e2

/-- **Half-life and stationary variance.** With pull speed `κ > 0`, the expected gap
`(r₀ - θ) e^(-κt)` halves over every stretch of length `ln 2/κ`, whatever the start time; when
there is a gap (`r₀ ≠ θ`) it reaches half its starting size exactly at `t = ln 2/κ`, whatever the
noise. As `t` grows, the mean `θ + (r₀ - θ) e^(-κt)` settles at `θ` and the variance
`σ²/(2κ) (1 - e^(-2κt))` settles at the stationary variance `σ²/(2κ)`. -/
theorem ou_gap_halves_every_log_two_div_kappa {κ θ σ r₀ : ℝ} (hκ : 0 < κ) :
    (∀ t : ℝ, (r₀ - θ) * exp (-κ * (t + log 2 / κ)) = (r₀ - θ) * exp (-κ * t) / 2) ∧
    (r₀ ≠ θ → ∀ t : ℝ, (r₀ - θ) * exp (-κ * t) = (r₀ - θ) / 2 ↔ t = log 2 / κ) ∧
    Tendsto (fun t : ℝ => θ + (r₀ - θ) * exp (-κ * t)) atTop (𝓝 θ) ∧
    Tendsto (fun t : ℝ => σ ^ 2 / (2 * κ) * (1 - exp (-2 * κ * t))) atTop
      (𝓝 (σ ^ 2 / (2 * κ))) := by
  have hκ0 : κ ≠ 0 := hκ.ne'
  refine ⟨fun t => ?_, fun hne t => ?_, ?_, ?_⟩
  · have : -κ * (t + log 2 / κ) = -κ * t - log 2 := by field_simp; ring
    rw [this, exp_sub, exp_log (by norm_num : (0:ℝ) < 2)]
    ring
  · have hne' : r₀ - θ ≠ 0 := sub_ne_zero.mpr hne
    have h1 : (r₀ - θ) * exp (-κ * t) = (r₀ - θ) / 2 ↔ exp (-κ * t) = exp (-log 2) := by
      rw [exp_neg, exp_log (by norm_num : (0:ℝ) < 2), div_eq_mul_inv]
      exact mul_right_inj' hne'
    rw [h1, exp_eq_exp]
    constructor
    · intro h; field_simp; linarith
    · intro h; rw [h]; field_simp
  · have h : Tendsto (fun t : ℝ => exp (-κ * t)) atTop (𝓝 0) :=
      tendsto_exp_atBot.comp (tendsto_id.const_mul_atTop_of_neg (by linarith))
    simpa using (h.const_mul (r₀ - θ)).const_add θ
  · have h : Tendsto (fun t : ℝ => exp (-2 * κ * t)) atTop (𝓝 0) :=
      tendsto_exp_atBot.comp (tendsto_id.const_mul_atTop_of_neg (by linarith))
    simpa using ((h.const_sub 1).const_mul (σ ^ 2 / (2 * κ)))

/-- **Feller's condition, the heart of Feller's test for CIR** (the card's Step 7). For the
Cox-Ingersoll-Ross equation `dr = κ(θ - r) dt + σ √r dW` with `κ > 0` and `σ > 0`, the scale
function `S` has slope `S'(x) = x^(-ν) e^(2κx/σ²)` with `ν = 2κθ/σ²`. Taking `S(1) = 0`, so that
`S(ε) = -∫_ε^1 S'`, the scale function falls to `-∞` as `ε` drops to `0` exactly when
`2κθ ≥ σ²`. That is what makes zero unreachable. -/
theorem cir_scale_function_diverges_iff_feller {κ θ σ : ℝ} (hκ : 0 < κ) (hσ : 0 < σ) :
    Tendsto (fun ε : ℝ => -∫ x in ε..1, x ^ (-(2 * κ * θ / σ ^ 2)) * exp (2 * κ * x / σ ^ 2))
        (𝓝[>] 0) atBot ↔
      σ ^ 2 ≤ 2 * κ * θ := by
  set ν := 2 * κ * θ / σ ^ 2 with hν
  have hσ2 : 0 < σ ^ 2 := by positivity
  have key : σ ^ 2 ≤ 2 * κ * θ ↔ 1 ≤ ν := by rw [hν, le_div_iff₀ hσ2, one_mul]
  rw [key]
  set f : ℝ → ℝ := fun x => x ^ (-ν) * exp (2 * κ * x / σ ^ 2) with hf
  have fnn : ∀ x, 0 ≤ x → 0 ≤ f x := fun x hx => by
    simp only [hf]; exact mul_nonneg (rpow_nonneg hx _) (exp_pos _).le
  have fint : ∀ a b : ℝ, 0 < a → 0 < b → IntervalIntegrable f volume a b := by
    intro a b ha hb
    apply ContinuousOn.intervalIntegrable
    apply ContinuousOn.mul
    · apply ContinuousOn.rpow_const continuousOn_id
      intro x hx; left
      have : 0 < min a b := lt_min ha hb
      have := (Set.mem_uIcc.mp hx)
      simp only [id]
      rcases this with h | h <;> [linarith [min_le_left a b, h.1]; linarith [min_le_right a b, h.1]]
    · fun_prop
  constructor
  · intro h
    by_contra hlt
    have hlt : ν < 1 := not_le.mp hlt
    have hint : IntervalIntegrable f volume 0 1 := by
      apply IntervalIntegrable.mul_continuousOn
      · exact intervalIntegral.intervalIntegrable_rpow' (by linarith)
      · fun_prop
    set M := ∫ x in (0:ℝ)..1, f x
    have hb : ∀ ε, 0 < ε → ε < 1 → -M ≤ -∫ x in ε..1, f x := by
      intro ε hε hε1
      have h1 : IntervalIntegrable f volume 0 ε :=
        hint.mono_set (by rw [Set.uIcc_of_le hε.le, Set.uIcc_of_le zero_le_one]; exact Set.Icc_subset_Icc le_rfl hε1.le)
      have h2 : IntervalIntegrable f volume ε 1 := fint ε 1 hε one_pos
      have hsum := intervalIntegral.integral_add_adjacent_intervals h1 h2
      have hnn : 0 ≤ ∫ x in (0:ℝ)..ε, f x :=
        intervalIntegral.integral_nonneg hε.le (fun x hx => fnn x hx.1)
      linarith
    have ev1 : ∀ᶠ ε in 𝓝[>] (0:ℝ), -∫ x in ε..1, f x < -M := h.eventually (eventually_lt_atBot (-M))
    have ev2 : ∀ᶠ ε in 𝓝[>] (0:ℝ), 0 < ε ∧ ε < 1 := by
      have : Set.Ioo (0:ℝ) 1 ∈ 𝓝[>] (0:ℝ) := Ioo_mem_nhdsGT one_pos
      filter_upwards [this] with ε hε using hε
    obtain ⟨ε, hε1, hε2⟩ := (ev1.and ev2).exists
    linarith [hb ε hε2.1 hε2.2]
  · intro hν1
    have bound : ∀ ε, 0 < ε → ε < 1 → -∫ x in ε..1, f x ≤ log ε := by
      intro ε hε hε1
      have hle : ∫ x in ε..1, x⁻¹ ≤ ∫ x in ε..1, f x := by
        apply intervalIntegral.integral_mono_on hε1.le
        · apply ContinuousOn.intervalIntegrable
          apply ContinuousOn.inv₀ continuousOn_id
          intro x hx
          rw [Set.uIcc_of_le hε1.le] at hx
          simp only [id]; linarith [hx.1]
        · exact fint ε 1 hε one_pos
        · intro x hx
          have hx0 : 0 < x := by linarith [hx.1]
          simp only [hf]
          have e1 : x⁻¹ = x ^ (-1 : ℝ) := by rw [rpow_neg_one]
          have e2 : x ^ (-1 : ℝ) ≤ x ^ (-ν) :=
            rpow_le_rpow_of_exponent_ge hx0 hx.2 (by linarith)
          have e3 : 1 ≤ exp (2 * κ * x / σ ^ 2) := one_le_exp (by positivity)
          rw [e1]
          calc x ^ (-1 : ℝ) = x ^ (-1:ℝ) * 1 := by ring
            _ ≤ x ^ (-ν) * exp (2 * κ * x / σ ^ 2) :=
              mul_le_mul e2 e3 zero_le_one (rpow_nonneg hx0.le _)
      rw [integral_inv_of_pos hε one_pos, log_div one_ne_zero hε.ne', log_one] at hle
      linarith
    apply tendsto_atBot_mono' _ _ tendsto_log_nhdsGT_zero
    have : Set.Ioo (0:ℝ) 1 ∈ 𝓝[>] (0:ℝ) := Ioo_mem_nhdsGT one_pos
    filter_upwards [this] with ε hε using bound ε hε.1 hε.2

/-! The card's exact worked numbers, as fractions: `κ = 1/2`, `θ = 4/100`, OU `σ = 2/100`,
CIR `σ = 1/10` and `3/10`. -/

-- Stationary variance σ²/(2κ) = 0.02 × 0.02/(2 × 0.5) = 0.000400, standard deviation 2 points.
example : ((2 : ℚ) / 100) ^ 2 / (2 * (1 / 2)) = 4 / 10000 ∧ ((2 : ℚ) / 100) ^ 2 = 4 / 10000 := by
  norm_num

-- Feller check at sigma 0.10: 2 × 0.5 × 0.04 = 0.04 against 0.01, ratio ν = 4, so it holds.
example : 2 * (1 / 2 : ℚ) * (4 / 100) = 4 / 100 ∧ ((1 : ℚ) / 10) ^ 2 = 1 / 100 ∧
    (2 * (1 / 2 : ℚ) * (4 / 100)) / ((1 : ℚ) / 10) ^ 2 = 4 ∧
    ((1 : ℚ) / 10) ^ 2 ≤ 2 * (1 / 2) * (4 / 100) := by norm_num

-- Feller fails at sigma 0.30: 0.09 against 0.04, ratio ν = 4/9 = 0.4444, below 1.
example : ((3 : ℚ) / 10) ^ 2 = 9 / 100 ∧
    (2 * (1 / 2 : ℚ) * (4 / 100)) / ((3 : ℚ) / 10) ^ 2 = 4 / 9 ∧
    ¬ (((3 : ℚ) / 10) ^ 2 ≤ 2 * (1 / 2) * (4 / 100)) := by norm_num

-- CIR at sigma 0.10 has stationary variance θσ²/(2κ) = 0.000400, the same as OU.
example : (4 / 100 : ℚ) * ((1 : ℚ) / 10) ^ 2 / (2 * (1 / 2)) = 4 / 10000 := by norm_num

-- Mistakes: no pull, σ²t at ten years = 0.004000; dropping the 2, σ²/κ = 0.000800.
example : ((2 : ℚ) / 100) ^ 2 * 10 = 4 / 1000 ∧ ((2 : ℚ) / 100) ^ 2 / (1 / 2) = 8 / 10000 := by
  norm_num

-- Euler factor 1 - κh: 0.99 at h = 0.02, -1.25 at h = 4.5.
example : 1 - (1 / 2 : ℚ) * (2 / 100) = 99 / 100 ∧ 1 - (1 / 2 : ℚ) * (9 / 2) = -5 / 4 := by
  norm_num

-- Euler long-run variance σ²h/(1 - a²): 0.000533 at h = 1, 0.001067 at h = 2.5, and
-- 0.003200 (eight times the true 0.000400) at h = 3.5.
example : ((2 : ℚ) / 100) ^ 2 * 1 / (1 - (1 - 1 / 2 * 1) ^ 2) = 1 / 1875 ∧
    ((2 : ℚ) / 100) ^ 2 * (5 / 2) / (1 - (1 - 1 / 2 * (5 / 2)) ^ 2) = 2 / 1875 ∧
    ((2 : ℚ) / 100) ^ 2 * (7 / 2) / (1 - (1 - 1 / 2 * (7 / 2)) ^ 2) = 8 * (4 / 10000) := by
  norm_num

#print axioms ou_hasLaw_gaussian_of_tendsto
#print axioms ou_variance_limit
#print axioms ou_pathwise_solution
#print axioms ou_stieltjes_sum_tendsto
#print axioms ou_hasLaw_weighted_increments
#print axioms ou_rate_is_normal
#print axioms ou_gap_halves_every_log_two_div_kappa
#print axioms cir_scale_function_diverges_iff_feller

end OrnsteinUhlenbeckCIR
