-- Exact simulation: chaining exact lognormal steps gives geometric Brownian motion's joint law at any chosen dates, and two exact Ornstein-Uhlenbeck steps compose into one.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Measure.GiryMonad
import Mathlib.Analysis.SpecialFunctions.Sqrt

open MeasureTheory ProbabilityTheory Real
open scoped NNReal

lemma sum_fin_ite_lt_eq_sum_range (g : ℕ → ℝ) (m k : ℕ) (hk : k ≤ m) :
    ∑ j : Fin m, (if (j : ℕ) < k then (1 : ℝ) else 0) * g j = ∑ j ∈ Finset.range k, g j := by
  rw [Fin.sum_univ_eq_sum_range (fun j => (if j < k then (1 : ℝ) else 0) * g j) m]
  simp only [ite_mul, one_mul, zero_mul]
  rw [Finset.sum_ite, Finset.sum_const_zero, add_zero]
  congr 1
  ext j; simp; omega

#print axioms sum_fin_ite_lt_eq_sum_range

lemma gaussianReal_bind_affine (m : ℝ) (v₁ v₂ : ℝ≥0) (a b : ℝ) :
    (gaussianReal m v₁).bind (fun y => gaussianReal (a + b * y) v₂) =
      gaussianReal (b * m + (0 + a)) ((.mk (b ^ 2) (sq_nonneg _) : ℝ≥0) * v₁ + v₂) := by
  have hk : (fun y => gaussianReal (a + b * y) v₂) =
      fun y => ((gaussianReal 0 v₂).map (Prod.mk y)).map
        (fun p : ℝ × ℝ => b * p.1 + (a + p.2)) := by
    funext y
    rw [Measure.map_map (by fun_prop) (by fun_prop)]
    have : ((fun p : ℝ × ℝ => b * p.1 + (a + p.2)) ∘ Prod.mk y) = fun z => (b * y + a) + z := by
      funext z; simp; ring
    rw [this, gaussianReal_map_const_add]
    congr 1; ring
  rw [hk, ← Measure.map_bind Measurable.map_prodMk_left.aemeasurable (by fun_prop),
    ← Measure.prod_eq_of_sfinite]
  have hg : (fun p : ℝ × ℝ => b * p.1 + (a + p.2)) =
      (fun p : ℝ × ℝ => p.1 + p.2) ∘ Prod.map (fun x => b * x) (fun z => a + z) := by
    funext p; rfl
  rw [hg, ← Measure.map_map (by fun_prop) (by fun_prop),
    ← Measure.map_prod_map _ _ (by fun_prop) (by fun_prop),
    gaussianReal_map_const_mul, gaussianReal_map_const_add]
  exact gaussianReal_conv_gaussianReal

#print axioms gaussianReal_bind_affine

/-- Exact simulation of geometric Brownian motion. The share price is
`S_t = S₀ exp((μ - σ²/2) t + σ W_t)` for a Brownian motion `W` (the solution of
`dS = μ S dt + σ S dW`). Pick dates `0 = t₀ < t₁ < t₂ < …`, independent standard normal
draws `Z₀, Z₁, …`, and build the chain `Y₀ = S₀`,
`Y_{k+1} = Y_k exp((μ - σ²/2) h_k + σ √h_k Z_k)` with `h_k = t_{k+1} - t_k`.
Then for every number of dates `m`, the simulated values `(Y₀, …, Y_m)` have exactly the
same joint law as the true prices `(S_{t₀}, …, S_{t_m})`, whatever the spacing of the dates. -/
theorem gbm_exact_chain_same_joint_law
    {Ω Ω' : Type*} [MeasurableSpace Ω] [MeasurableSpace Ω']
    {P : Measure Ω} [IsProbabilityMeasure P] {Q : Measure Ω'} [IsProbabilityMeasure Q]
    (W : ℝ≥0 → Ω → ℝ) (hW : IsBrownianReal W P)
    (S₀ μ σ : ℝ) (t : ℕ → ℝ≥0) (ht0 : t 0 = 0) (ht : StrictMono t)
    (Z : ℕ → Ω' → ℝ) (hZind : iIndepFun Z Q) (hZlaw : ∀ k, HasLaw (Z k) (gaussianReal 0 1) Q)
    (Y : ℕ → Ω' → ℝ) (hY0 : ∀ ω, Y 0 ω = S₀)
    (hY : ∀ k ω, Y (k + 1) ω = Y k ω *
      exp ((μ - σ ^ 2 / 2) * ((t (k + 1) : ℝ) - t k) + σ * √((t (k + 1) : ℝ) - t k) * Z k ω))
    (m : ℕ) :
    P.map (fun ω (k : Fin (m + 1)) => S₀ * exp ((μ - σ ^ 2 / 2) * (t k : ℝ) + σ * W (t k) ω)) =
      Q.map (fun ω (k : Fin (m + 1)) => Y k ω) := by
  set a := μ - σ ^ 2 / 2 with ha
  let F : (Fin m → ℝ) → Fin (m + 1) → ℝ := fun d k =>
    S₀ * exp (a * (t k : ℝ) + σ * ∑ j : Fin m, (if (j : ℕ) < k then (1 : ℝ) else 0) * d j)
  have hF : Measurable F := by
    unfold F
    fun_prop
  let D : ℕ → Ω → ℝ := fun j ω => W (t (j + 1)) ω - W (t j) ω
  let G : ℕ → Ω' → ℝ := fun j ω => √((t (j + 1) : ℝ) - t j) * Z j ω
  have hDm : ∀ j, AEMeasurable (D j) P := fun j =>
    (hW.toIsPreBrownianReal.aemeasurable _).sub (hW.toIsPreBrownianReal.aemeasurable _)
  have hGm : ∀ j, AEMeasurable (G j) Q := fun j => (hZlaw j).aemeasurable.const_mul _
  have hDlaw : ∀ j, P.map (D j) = gaussianReal 0 ⟨(t (j + 1) : ℝ) - t j, by
      have := (ht (Nat.lt_succ_self j)).le
      have : (t j : ℝ) ≤ t (j + 1) := by exact_mod_cast this
      linarith⟩ := by
    intro j
    refine (hW.toIsPreBrownianReal.hasLaw_sub (t (j + 1)) (t j)).map_eq.trans ?_
    congr 1
    ext
    have := (ht (Nat.lt_succ_self j)).le
    have : (t j : ℝ) ≤ t (j + 1) := by exact_mod_cast this
    simp [Real.dist_eq, abs_of_nonneg (sub_nonneg.mpr this)]
    rfl
  have hGlaw : ∀ j, Q.map (G j) = gaussianReal 0 ⟨(t (j + 1) : ℝ) - t j, by
      have := (ht (Nat.lt_succ_self j)).le
      have : (t j : ℝ) ≤ t (j + 1) := by exact_mod_cast this
      linarith⟩ := by
    intro j
    refine (gaussianReal_const_mul (hZlaw j) (√((t (j + 1) : ℝ) - t j))).map_eq.trans ?_
    have := (ht (Nat.lt_succ_self j)).le
    have : (t j : ℝ) ≤ t (j + 1) := by exact_mod_cast this
    congr 1
    · simp
    · ext
      simp [Real.sq_sqrt (sub_nonneg.mpr this)]
      rfl
  have hDind : iIndepFun (fun (j : Fin m) => D j) P :=
    (hW.toIsPreBrownianReal.hasIndepIncrements.nat ht.monotone).precomp Fin.val_injective
  have hGind : iIndepFun (fun (j : Fin m) => G j) Q :=
    (hZind.comp (fun j x => √((t (j + 1) : ℝ) - t j) * x) (fun j => by fun_prop)).precomp
      Fin.val_injective
  have hlaw : P.map (fun ω (j : Fin m) => D j ω) = Q.map (fun ω (j : Fin m) => G j ω) := by
    rw [(iIndepFun_iff_map_fun_eq_pi_map (fun (j : Fin m) => hDm j)).mp hDind,
      (iIndepFun_iff_map_fun_eq_pi_map (fun (j : Fin m) => hGm j)).mp hGind]
    congr 1
    funext j
    rw [hDlaw, hGlaw]
  have hL : (fun ω (k : Fin (m + 1)) => S₀ * exp (a * (t k : ℝ) + σ * W (t k) ω)) =ᵐ[P]
      F ∘ (fun ω (j : Fin m) => D j ω) := by
    filter_upwards [hW.toIsPreBrownianReal.eval_zero_ae_eq_zero] with ω hω
    funext k
    simp only [Function.comp, F]
    rw [sum_fin_ite_lt_eq_sum_range (fun j => D j ω) m k (by omega)]
    simp only [D]
    rw [Finset.sum_range_sub (fun j => W (t j) ω), ht0, hω, sub_zero]
  have key : ∀ k ω, Y k ω = S₀ * exp (a * (t k : ℝ) + σ * ∑ j ∈ Finset.range k, G j ω) := by
    intro k ω
    induction k with
    | zero => simp [hY0, ht0]
    | succ k ih =>
      rw [hY, ih, mul_assoc, ← exp_add, Finset.sum_range_succ]
      congr 2
      simp only [G]
      ring
  have hR : (fun ω (k : Fin (m + 1)) => Y k ω) = F ∘ (fun ω (j : Fin m) => G j ω) := by
    funext ω k
    simp only [Function.comp, F]
    rw [key, sum_fin_ite_lt_eq_sum_range (fun j => G j ω) m k (by omega)]
  have hDv : AEMeasurable (fun ω (j : Fin m) => D j ω) P := AEMeasurable.of_eval fun j => hDm j
  have hGv : AEMeasurable (fun ω (j : Fin m) => G j ω) Q := AEMeasurable.of_eval fun j => hGm j
  rw [Measure.map_congr hL, hR, ← AEMeasurable.map_map_of_aemeasurable hF.aemeasurable hDv,
    ← AEMeasurable.map_map_of_aemeasurable hF.aemeasurable hGv, hlaw]

/-- Path by path for geometric Brownian motion. If the normal draws are taken from the Brownian
path itself, `Z_k = (W_{t_{k+1}} - W_{t_k}) / √h_k`, then the exact chain equals the true price
`S_{t_k} = S₀ exp((μ - σ²/2) t_k + σ W_{t_k})` at every date, for almost every path. -/
theorem gbm_exact_chain_eq_path_of_increments
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    (W : ℝ≥0 → Ω → ℝ) (hW : IsBrownianReal W P)
    (S₀ μ σ : ℝ) (t : ℕ → ℝ≥0) (ht0 : t 0 = 0) (ht : StrictMono t)
    (Y : ℕ → Ω → ℝ) (hY0 : ∀ ω, Y 0 ω = S₀)
    (hY : ∀ k ω, Y (k + 1) ω = Y k ω *
      exp ((μ - σ ^ 2 / 2) * ((t (k + 1) : ℝ) - t k) + σ * √((t (k + 1) : ℝ) - t k) *
        ((W (t (k + 1)) ω - W (t k) ω) / √((t (k + 1) : ℝ) - t k)))) :
    ∀ᵐ ω ∂P, ∀ k, Y k ω = S₀ * exp ((μ - σ ^ 2 / 2) * (t k : ℝ) + σ * W (t k) ω) := by
  filter_upwards [hW.eval_zero_ae_eq_zero] with ω hω k
  induction k with
  | zero => simp [hY0, ht0, hω]
  | succ k ih =>
    have hpos : 0 < (t (k + 1) : ℝ) - t k := by
      have := ht (Nat.lt_succ_self k)
      have : (t k : ℝ) < t (k + 1) := by exact_mod_cast this
      linarith
    have hs : √((t (k + 1) : ℝ) - t k) ≠ 0 := (Real.sqrt_pos.mpr hpos).ne'
    rw [hY, ih, mul_assoc, ← exp_add]
    congr 2
    field_simp
    ring

/-- The exact Ornstein-Uhlenbeck steps compose (Chapman-Kolmogorov). The exact step over a gap
`h` sends a rate `x` to the normal law with mean `θ + (x - θ) e^{-κh}` and variance
`σ_r² (1 - e^{-2κh}) / (2κ)`. Taking an exact step over `h₁` and then one over `h₂` gives
exactly the law of one exact step over `h₁ + h₂`, so the grid of dates does not matter. -/
theorem ou_exact_step_chapman_kolmogorov
    (θ κ σr : ℝ) (hκ : 0 < κ) (h₁ h₂ : ℝ) (hh₁ : 0 ≤ h₁) (hh₂ : 0 ≤ h₂) (x : ℝ) :
    (gaussianReal (θ + (x - θ) * exp (-κ * h₁))
        (Real.toNNReal (σr ^ 2 * (1 - exp (-2 * κ * h₁)) / (2 * κ)))).bind
      (fun y => gaussianReal (θ + (y - θ) * exp (-κ * h₂))
        (Real.toNNReal (σr ^ 2 * (1 - exp (-2 * κ * h₂)) / (2 * κ)))) =
      gaussianReal (θ + (x - θ) * exp (-κ * (h₁ + h₂)))
        (Real.toNNReal (σr ^ 2 * (1 - exp (-2 * κ * (h₁ + h₂))) / (2 * κ))) := by
  have hf : (fun y => gaussianReal (θ + (y - θ) * exp (-κ * h₂))
        (Real.toNNReal (σr ^ 2 * (1 - exp (-2 * κ * h₂)) / (2 * κ)))) =
      fun y => gaussianReal ((θ - θ * exp (-κ * h₂)) + exp (-κ * h₂) * y)
        (Real.toNNReal (σr ^ 2 * (1 - exp (-2 * κ * h₂)) / (2 * κ))) := by
    funext y; congr 1; ring
  rw [hf, gaussianReal_bind_affine]
  have hnn : ∀ h : ℝ, 0 ≤ h → 0 ≤ σr ^ 2 * (1 - exp (-2 * κ * h)) / (2 * κ) := by
    intro h hh
    apply div_nonneg _ (by linarith)
    apply mul_nonneg (sq_nonneg _)
    have : exp (-2 * κ * h) ≤ 1 := exp_le_one_iff.mpr (by nlinarith)
    linarith
  have e1 : exp (-κ * (h₁ + h₂)) = exp (-κ * h₁) * exp (-κ * h₂) := by
    rw [← exp_add]; ring_nf
  have e2 : exp (-2 * κ * (h₁ + h₂)) = exp (-κ * h₂) ^ 2 * exp (-2 * κ * h₁) * 1
      + (exp (-2 * κ * h₂) - exp (-κ * h₂) ^ 2) := by
    rw [← exp_nat_mul, ← exp_add]; ring_nf
  congr 1
  · rw [e1]; ring
  · ext
    rw [NNReal.coe_add, NNReal.coe_mul, NNReal.coe_mk, Real.coe_toNNReal _ (hnn h₁ hh₁),
      Real.coe_toNNReal _ (hnn h₂ hh₂), Real.coe_toNNReal _ (hnn _ (by linarith))]
    have e3 : exp (-κ * h₂) ^ 2 = exp (-2 * κ * h₂) := by
      rw [← exp_nat_mul]; ring_nf
    rw [e2, e3]
    field_simp
    ring

-- One Euler step for the whole year (card's "What breaks" table), share from $100,
-- drift 8/100, volatility 20/100: mean 108 dollars and variance 400.
example : (100 : ℚ) * (1 + 8 / 100 * 1) = 108 := by norm_num
example : (100 : ℚ) ^ 2 * ((1 + 8 / 100 * 1) ^ 2 + (20 / 100) ^ 2 * 1) - (100 * (1 + 8 / 100 * 1)) ^ 2 = 400 := by
  norm_num
-- One Euler step for the whole year for the rate, in percent: 6 + 0.5 × (4 - 6) × 1 = 5.
example : (6 : ℚ) + 1 / 2 * (4 - 6) * 1 = 5 := by norm_num

#print axioms gbm_exact_chain_same_joint_law
#print axioms gbm_exact_chain_eq_path_of_increments
#print axioms ou_exact_step_chapman_kolmogorov
