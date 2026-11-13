-- Vasicek: when the short rate is a Brownian motion pulled toward a level, the area under its path is normal and the zero-coupon bond price is exp(A(T) - B(T) r₀), that price solves the bond equation, and long yields settle at θ - σ²/(2a²).
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum

namespace VasicekModel

open MeasureTheory ProbabilityTheory Real Filter Topology
open scoped NNReal

/-! Setting. Mathlib's `IsBrownianReal W P` says that `W : ℝ≥0 → Ω → ℝ` is a Brownian motion
under `P` (here the pricing-world weighting of paths). `HasLaw X μ P` says the random variable
`X` has law `μ`, and `gaussianReal m v` is the normal law with mean `m` and variance `v`.

Mathlib has no Ito integral, so the Vasicek equation `dr = a(θ - r) dt + σ dW` is written path
by path: `r_t = r₀ + ∫₀ᵗ a(θ - r_u) du + σ W_t`, with continuous paths. -/

/-- `B(T) = (1 - e^(-aT))/a`: how much a change in today's rate moves the log bond price. -/
noncomputable def vasicekB (a T : ℝ) : ℝ := (1 - exp (-a * T)) / a

/-- `A(T) = (θ - σ²/(2a²))(B(T) - T) - σ² B(T)²/(4a)`: the part of the log bond price that does
not depend on today's rate. -/
noncomputable def vasicekA (a θ σ T : ℝ) : ℝ :=
  (θ - σ ^ 2 / (2 * a ^ 2)) * (vasicekB a T - T) - σ ^ 2 * vasicekB a T ^ 2 / (4 * a)

/-- The closed-form price `P(τ, r) = e^(A(τ) - B(τ) r)` of $1 paid after time `τ`, when the
short rate is `r` now. -/
noncomputable def vasicekPrice (a θ σ τ r : ℝ) : ℝ := exp (vasicekA a θ σ τ - vasicekB a τ * r)

/-- Helper: grid facts for the points `k T / n`. -/
lemma grid_facts {T : ℝ} (hT : 0 ≤ T) {n k : ℕ} (hk : k < n) :
    0 ≤ (k : ℝ) * T / n ∧ ((k + 1 : ℕ) : ℝ) * T / n ≤ T ∧
      ((k + 1 : ℕ) : ℝ) * T / n - (k : ℝ) * T / n = T / n ∧ 0 ≤ T / n := by
  have hn : (0 : ℝ) < n := by exact_mod_cast (lt_of_le_of_lt (Nat.zero_le k) hk)
  have hk1 : ((k + 1 : ℕ) : ℝ) ≤ n := by exact_mod_cast hk
  refine ⟨by positivity, ?_, ?_, by positivity⟩
  · rw [div_le_iff₀ hn]; nlinarith
  · push_cast; field_simp; ring

#print axioms grid_facts

/-- Helper: Riemann sums `∑ (∫ over the k-th piece of g) · h(point in the piece)` converge to
`∫₀ᵀ g h` for continuous `g`, `h`. -/
lemma riemann_tendsto {g h : ℝ → ℝ} (hg : Continuous g) (hh : Continuous h) {T : ℝ}
    (hT : 0 ≤ T) (p : ℕ → ℕ → ℝ)
    (hp : ∀ n k : ℕ, k < n → (k : ℝ) * T / n ≤ p n k ∧ p n k ≤ ((k + 1 : ℕ) : ℝ) * T / n) :
    Tendsto (fun n : ℕ => ∑ k ∈ Finset.range n,
      (∫ u in (k : ℝ) * T / n..((k + 1 : ℕ) : ℝ) * T / n, g u) * h (p n k)) atTop
      (𝓝 (∫ u in (0 : ℝ)..T, g u * h u)) := by
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨C, hC⟩ :=
    (isCompact_Icc (a := (0 : ℝ)) (b := T)).exists_bound_of_continuousOn hg.continuousOn
  set M := |C| + 1 with hM
  have hMpos : 0 < M := by positivity
  have hgM : ∀ x ∈ Set.Icc 0 T, ‖g x‖ ≤ M := fun x hx =>
    (hC x hx).trans (by rw [hM]; linarith [le_abs_self C])
  set ε' := ε / (2 * M * (T + 1)) with hε'
  have hε'pos : 0 < ε' := by positivity
  obtain ⟨δ, hδ, hU⟩ := Metric.uniformContinuousOn_iff.1
    ((isCompact_Icc (a := (0 : ℝ)) (b := T)).uniformContinuousOn_of_continuous
      hh.continuousOn) ε' hε'pos
  obtain ⟨N, hN⟩ := exists_nat_gt (T / δ)
  refine ⟨N, fun n hn => ?_⟩
  have hNpos : (0 : ℝ) < N := lt_of_le_of_lt (div_nonneg hT hδ.le) hN
  have hnN : (N : ℝ) ≤ n := by exact_mod_cast hn
  have hnpos : (0 : ℝ) < n := lt_of_lt_of_le hNpos hnN
  have hn0 : n ≠ 0 := by rintro rfl; simp at hnpos
  have hstep : T / n < δ := by
    rw [div_lt_iff₀ hnpos]
    have := (div_lt_iff₀ hδ).1 hN
    nlinarith
  set t : ℕ → ℝ := fun k => (k : ℝ) * T / n with ht
  have hsplit : ∫ u in (0 : ℝ)..T, g u * h u =
      ∑ k ∈ Finset.range n, ∫ u in t k..t (k + 1), g u * h u := by
    rw [intervalIntegral.sum_integral_adjacent_intervals]
    · simp [t, hn0]
    · intro k _; exact (hg.mul hh).intervalIntegrable _ _
  rw [dist_eq_norm, hsplit, ← Finset.sum_sub_distrib]
  calc ‖∑ k ∈ Finset.range n, ((∫ u in t k..t (k + 1), g u) * h (p n k)
          - ∫ u in t k..t (k + 1), g u * h u)‖
      ≤ ∑ k ∈ Finset.range n, ‖(∫ u in t k..t (k + 1), g u) * h (p n k)
          - ∫ u in t k..t (k + 1), g u * h u‖ := norm_sum_le _ _
    _ ≤ ∑ k ∈ Finset.range n, M * ε' * (t (k + 1) - t k) := by
        apply Finset.sum_le_sum
        intro k hk
        rw [Finset.mem_range] at hk
        obtain ⟨h0, h1, h2, h3⟩ := grid_facts hT hk
        obtain ⟨hp1, hp2⟩ := hp n k hk
        have hle : t k ≤ t (k + 1) := by simp only [t]; linarith
        rw [← intervalIntegral.integral_mul_const]
        have hsub : (∫ u in t k..t (k + 1), g u * h (p n k)) - ∫ u in t k..t (k + 1), g u * h u
            = ∫ u in t k..t (k + 1), (g u * h (p n k) - g u * h u) :=
          (intervalIntegral.integral_sub
            ((hg.mul continuous_const).intervalIntegrable _ _)
            ((hg.mul hh).intervalIntegrable _ _)).symm
        rw [hsub]
        have := intervalIntegral.norm_integral_le_of_norm_le_const
          (a := t k) (b := t (k + 1)) (C := M * ε')
          (f := fun u => g u * h (p n k) - g u * h u) (fun x hx => ?_)
        · rwa [abs_of_nonneg (by linarith)] at this
        rw [Set.uIoc_of_le hle] at hx
        obtain ⟨hx1, hx2⟩ := hx
        have hxs : x ∈ Set.Icc 0 T := ⟨by simp only [t] at hx1; linarith, by
          simp only [t] at hx2; linarith⟩
        have hps : p n k ∈ Set.Icc 0 T := ⟨by linarith, by linarith⟩
        have hdist : dist (p n k) x < δ := by
          rw [Real.dist_eq, abs_lt]
          simp only [t] at hx1 hx2
          constructor <;> linarith
        have hd := hU (p n k) hps x hxs hdist
        rw [Real.dist_eq] at hd
        rw [← mul_sub, norm_mul, Real.norm_eq_abs (h (p n k) - h x)]
        exact mul_le_mul (hgM x hxs) hd.le (abs_nonneg _) hMpos.le
    _ = M * ε' * T := by
        rw [← Finset.mul_sum, Finset.sum_range_sub]; simp [t, hn0]
    _ < ε := by
        rw [hε']
        have hT1 : 0 < T + 1 := by linarith
        rw [show M * (ε / (2 * M * (T + 1))) * T = ε * (T / (2 * (T + 1))) by
          field_simp]
        have : T / (2 * (T + 1)) < 1 := by rw [div_lt_one (by positivity)]; linarith
        nlinarith

#print axioms riemann_tendsto

/-- Helper: summation by parts. -/
lemma sum_by_parts (F G : ℕ → ℝ) (n : ℕ) :
    ∑ k ∈ Finset.range n, F k * (G (k + 1) - G k) =
      F n * G n - F 0 * G 0 - ∑ k ∈ Finset.range n, (F (k + 1) - F k) * G (k + 1) := by
  induction n with
  | zero => simp
  | succ n ih => rw [Finset.sum_range_succ, Finset.sum_range_succ, ih]; ring

#print axioms sum_by_parts

/-- Helper: the integral of `e^(a u)` over `[x, y]`. -/
lemma integral_exp_mul_eq {a : ℝ} (ha : a ≠ 0) (x y : ℝ) :
    ∫ u in x..y, exp (a * u) = (exp (a * y) - exp (a * x)) / a := by
  have h : ∀ u ∈ Set.uIcc x y, HasDerivAt (fun u => exp (a * u) / a) (exp (a * u)) u := by
    intro u _
    have := (((hasDerivAt_id' u).const_mul a).exp).div_const a
    refine this.congr_deriv ?_
    field_simp
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt h
    ((by fun_prop : Continuous fun u => exp (a * u)).intervalIntegrable _ _)]
  ring

#print axioms integral_exp_mul_eq

/-- **The Vasicek bond formula** (the card's main claim). Let `W` be a Brownian motion, `a > 0`
the speed of the pull, `θ` the level, `σ` the size of the shocks and `r₀` today's rate. If the
short rate `r` solves `r_t = r₀ + ∫₀ᵗ a(θ - r_u) du + σ W_t` with continuous paths, then for
every maturity `T ≥ 0` the area `I_T = ∫₀ᵀ r_u du` under the path is normal, with mean
`m = θT + (r₀ - θ)B(T)` and variance `v = σ²/a² (T - B(T) - a B(T)²/2)`, and the zero-coupon
bond price, the average of `e^(-I_T)`, is `e^(A(T) - B(T) r₀)`: an exponential of a straight
line in today's rate. (The variance is never negative, so `toNNReal` only changes its type.) -/
theorem vasicek_zero_coupon_bond_price {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) {a θ σ r₀ : ℝ} (ha : 0 < a)
    {r : ℝ → Ω → ℝ}
    (hr : ∀ᵐ ω ∂P, ContinuousOn (fun s => r s ω) (Set.Ici 0) ∧
      ∀ t : ℝ≥0, r t ω = r₀ + (∫ u in (0 : ℝ)..t, a * (θ - r u ω)) + σ * W t ω)
    (T : ℝ≥0) :
    HasLaw (fun ω => ∫ u in (0 : ℝ)..T, r u ω)
        (gaussianReal (θ * T + (r₀ - θ) * vasicekB a T)
          (σ ^ 2 / a ^ 2 * (T - vasicekB a T - a * vasicekB a T ^ 2 / 2)).toNNReal) P ∧
      ∫ ω, exp (-∫ u in (0 : ℝ)..T, r u ω) ∂P = vasicekPrice a θ σ T r₀ := by
  classical
  have ha0 : a ≠ 0 := ha.ne'
  have hPr : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  set Tr : ℝ := (T : ℝ) with hTr
  have hT0 : 0 ≤ Tr := T.2
  set X : ℝ := exp (a * Tr) with hX
  have hXpos : 0 < X := exp_pos _
  let wp : Ω → ℝ → ℝ := fun ω u => W u.toNNReal ω
  let f : ℝ → ℝ := fun u => (X - exp (a * u)) / a
  have hfc : Continuous f := by fun_prop
  let tg : ℕ → ℕ → ℝ := fun n k => (k : ℝ) * Tr / n
  have htg_nonneg : ∀ n k, 0 ≤ tg n k := fun n k => by positivity
  have htg_step : ∀ n k, tg n (k + 1) - tg n k = Tr / n := fun n k => by
    simp only [tg]; push_cast; ring
  have htg_le : ∀ n k, tg n k ≤ tg n (k + 1) := fun n k => by
    have := htg_step n k; have : 0 ≤ Tr / n := by positivity
    linarith
  let Y : ℕ → Ω → ℝ := fun n ω =>
    ∑ k ∈ Finset.range n, f (tg n k) * (wp ω (tg n (k + 1)) - wp ω (tg n k))
  let S : Ω → ℝ := fun ω => ∫ u in (0 : ℝ)..Tr, exp (a * u) * wp ω u
  let Vn : ℕ → ℝ := fun n =>
    ∑ k ∈ Finset.range n, (∫ _ in tg n k..tg n (k + 1), (1 : ℝ)) * f (tg n k) ^ 2
  let V : ℝ := ∫ u in (0 : ℝ)..Tr, 1 * f u ^ 2
  -- Riemann sums of the variance converge.
  have hVn : Tendsto Vn atTop (𝓝 V) :=
    riemann_tendsto (g := fun _ => (1 : ℝ)) (h := fun u => f u ^ 2) continuous_const
      (hfc.pow 2) hT0 (fun n k => tg n k) (fun n k _ => ⟨le_rfl, htg_le n k⟩)
  -- Pathwise convergence of the discrete sums.
  have hconv : ∀ᵐ ω ∂P, Tendsto (fun n => Y n ω) atTop (𝓝 (S ω)) := by
    filter_upwards [hW.cont, hW.eval_zero_ae_eq_zero] with ω hc h0
    have hwc : Continuous (wp ω) := hc.comp continuous_real_toNNReal
    have hR := riemann_tendsto (g := fun u => exp (a * u)) (h := wp ω) (by fun_prop) hwc hT0
      (fun n k => tg n (k + 1)) (fun n k _ => ⟨htg_le n k, le_rfl⟩)
    refine hR.congr' ?_
    filter_upwards [eventually_ge_atTop 1] with n hn
    have hn' : (n : ℝ) ≠ 0 := by
      have : (1 : ℝ) ≤ n := by exact_mod_cast hn
      linarith
    simp only [Y]
    rw [sum_by_parts (fun k => f (tg n k)) (fun k => wp ω (tg n k)) n]
    have hfn : f (tg n n) = 0 := by
      have : tg n n = Tr := by simp only [tg]; field_simp
      simp only [this, f, X, sub_self, zero_div]
    have hw0 : wp ω (tg n 0) = 0 := by simp [wp, tg, h0]
    rw [hfn, hw0, zero_mul, mul_zero, sub_zero, zero_sub, ← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl (fun k _ => ?_)
    rw [integral_exp_mul_eq ha0]
    simp only [f, tg]
    ring
  -- Measurability.
  have hYmeas : ∀ n, AEMeasurable (Y n) P := fun n =>
    Finset.aemeasurable_fun_sum _ (fun k _ =>
      ((hW.aemeasurable _).sub (hW.aemeasurable _)).const_mul _)
  have hSmeas : AEMeasurable S P := aemeasurable_of_tendsto_metrizable_ae' hYmeas hconv
  -- Characteristic function of the discrete sums.
  have hchar : ∀ n (ξ : ℝ), ∫ ω, Complex.exp (ξ * Y n ω * Complex.I) ∂P = Complex.exp (((-(Vn n * ξ ^ 2 / 2) : ℝ) : ℂ)) := by
    intro n ξ
    let tt : Fin (n + 1) → ℝ≥0 := fun i => (tg n i).toNNReal
    have htt : Monotone tt := by
      intro i j hij
      apply Real.toNNReal_le_toNNReal
      simp only [tg]
      have : (i : ℝ) ≤ j := by exact_mod_cast hij
      gcongr
    have hind := (hW.hasIndepIncrements n tt htt).comp (fun i (x : ℝ) => f (tg n i) * x)
      (fun i => measurable_const.mul measurable_id)
    let Xf : Fin n → Ω → ℝ := fun i ω => f (tg n i) * (W (tt i.succ) ω - W (tt i.castSucc) ω)
    have hYeq : Y n = fun ω => ∑ i, Xf i ω := by
      funext ω
      simp only [Y, Xf]
      rw [← Fin.sum_univ_eq_sum_range]
      rfl
    have hmeasX : ∀ i, AEMeasurable (Xf i) P := fun i =>
      ((hW.aemeasurable _).sub (hW.aemeasurable _)).const_mul _
    have hc := iIndepFun.charFun_map_fun_sum_eq_prod (X := Xf) hmeasX hind
    have hlaw : ∀ i, P.map (Xf i) = gaussianReal (f (tg n i) * 0)
        (⟨f (tg n i) ^ 2, sq_nonneg _⟩ * nndist (tt i.succ : ℝ) (tt i.castSucc)) := fun i =>
      (gaussianReal_const_mul (hW.hasLaw_sub (tt i.succ) (tt i.castSucc)) _).map_eq
    have hfac : ∀ i : Fin n, charFun (P.map (Xf i)) ξ = Complex.exp
        (((-(f (tg n i) ^ 2 * (tg n (i + 1) - tg n i) * ξ ^ 2 / 2)) : ℝ) : ℂ) := by
      intro i
      have h1 : ((tt i.succ : ℝ)) = tg n (i + 1) := by
        simp only [tt]; rw [Real.coe_toNNReal _ (htg_nonneg _ _)]; simp
      have h2 : ((tt i.castSucc : ℝ)) = tg n i := by
        simp only [tt]; rw [Real.coe_toNNReal _ (htg_nonneg _ _)]; simp
      have h3 : ((⟨f (tg n i) ^ 2, sq_nonneg _⟩ * nndist (tt i.succ : ℝ) (tt i.castSucc) : ℝ≥0)
          : ℝ) = f (tg n i) ^ 2 * (tg n (i + 1) - tg n i) := by
        change f (tg n i) ^ 2 * ((nndist (tt i.succ : ℝ) (tt i.castSucc) : ℝ≥0) : ℝ) = _
        rw [coe_nndist, h1, h2, Real.dist_eq, abs_of_nonneg (by linarith [htg_le n i])]
      rw [hlaw i, charFun_gaussianReal]
      congr 1
      have h4 : (((⟨f (tg n i) ^ 2, sq_nonneg _⟩ * nndist (tt i.succ : ℝ) (tt i.castSucc) : ℝ≥0)
          : ℝ) : ℂ) = ((f (tg n i) ^ 2 * (tg n (i + 1) - tg n i) : ℝ) : ℂ) := by rw [h3]
      rw [h4]
      push_cast
      ring
    have hcξ := congrFun hc ξ
    rw [charFun_apply_real, integral_map (hYeq ▸ hYmeas n)
      (by fun_prop : Continuous fun x : ℝ => Complex.exp (ξ * x * Complex.I)).aestronglyMeasurable]
      at hcξ
    rw [hYeq, hcξ, Finset.prod_apply]
    simp_rw [hfac]
    rw [← Complex.exp_sum, ← Complex.ofReal_sum]
    congr 2
    simp only [Vn]
    rw [← Fin.sum_univ_eq_sum_range, Finset.sum_mul, Finset.sum_div, ← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl (fun i _ => ?_)
    rw [intervalIntegral.integral_const, smul_eq_mul, mul_one]
    ring
  -- The limit variance.
  have hV0 : 0 ≤ V := intervalIntegral.integral_nonneg hT0 (fun u _ => by positivity)
  have hVval : V = (X ^ 2 * Tr - 2 * X * X / a + X ^ 2 / (2 * a)) / a ^ 2
      - (0 - 2 * X * 1 / a + 1 / (2 * a)) / a ^ 2 := by
    let K : ℝ → ℝ := fun u =>
      (X ^ 2 * u - 2 * X * exp (a * u) / a + exp (a * u) ^ 2 / (2 * a)) / a ^ 2
    have hK : ∀ u ∈ Set.uIcc 0 Tr, HasDerivAt K (1 * f u ^ 2) u := by
      intro u _
      have e := ((hasDerivAt_id' u).const_mul a).exp
      have h := ((((hasDerivAt_id' u).const_mul (X ^ 2)).sub ((e.const_mul (2 * X)).div_const a)).add
        ((e.pow 2).div_const (2 * a))).div_const (a ^ 2)
      refine h.congr_deriv ?_
      simp only [f]
      field_simp
      ring
    have := intervalIntegral.integral_eq_sub_of_hasDerivAt hK
      ((continuous_const.mul (hfc.pow 2)).intervalIntegrable _ _)
    show (∫ u in (0 : ℝ)..Tr, 1 * f u ^ 2) = _
    rw [this]
    simp only [K, mul_zero, exp_zero, X]
    ring
  have hXinv : exp (-a * Tr) = X⁻¹ := by rw [neg_mul, Real.exp_neg]
  have hkey : (σ * X⁻¹) ^ 2 * V = σ ^ 2 / a ^ 2 * (Tr - vasicekB a Tr - a * vasicekB a Tr ^ 2 / 2) := by
    rw [hVval]
    simp only [vasicekB, hXinv]
    field_simp
    ring
  -- The law of `S`.
  have hS : HasLaw S (gaussianReal 0 V.toNNReal) P := by
    refine ⟨hSmeas, ?_⟩
    apply Measure.ext_of_charFun
    funext ξ
    have hcont : Continuous fun x : ℝ => Complex.exp (ξ * x * Complex.I) := by fun_prop
    rw [charFun_gaussianReal, charFun_apply_real, integral_map hSmeas hcont.aestronglyMeasurable]
    have lim1 : Tendsto (fun n => ∫ ω, Complex.exp (ξ * Y n ω * Complex.I) ∂P) atTop
        (𝓝 (∫ ω, Complex.exp (ξ * S ω * Complex.I) ∂P)) := by
      refine tendsto_integral_of_dominated_convergence (fun _ => 1)
        (fun n => (hcont.measurable.comp_aemeasurable (hYmeas n)).aestronglyMeasurable)
        (integrable_const 1) (fun n => ae_of_all _ (fun ω => ?_)) ?_
      · rw [← Complex.ofReal_mul, Complex.norm_exp_ofReal_mul_I]
      · filter_upwards [hconv] with ω hω
        exact (hcont.tendsto _).comp hω
    have lim2 : Tendsto (fun n => ∫ ω, Complex.exp (ξ * Y n ω * Complex.I) ∂P) atTop
        (𝓝 (Complex.exp (((-(V * ξ ^ 2 / 2)) : ℝ) : ℂ))) := by
      simp_rw [hchar]
      have hc2 : Continuous fun x : ℝ => Complex.exp (((-(x * ξ ^ 2 / 2)) : ℝ) : ℂ) := by fun_prop
      exact (hc2.tendsto _).comp hVn
    rw [tendsto_nhds_unique lim1 lim2, Real.coe_toNNReal _ hV0]
    congr 1
    push_cast
    ring
  -- Pathwise: the area under the rate path.
  have hident : ∀ᵐ ω ∂P, (∫ u in (0 : ℝ)..Tr, r u ω) =
      (θ * Tr + (r₀ - θ) * vasicekB a Tr) + σ * X⁻¹ * S ω := by
    filter_upwards [hr, hW.cont] with ω hrω hc
    obtain ⟨hcont, heq⟩ := hrω
    have hwc : Continuous (wp ω) := hc.comp continuous_real_toNNReal
    let rt : ℝ → ℝ := fun u => r (max u 0) ω
    have hrt : Continuous rt :=
      hcont.comp_continuous (continuous_id.max continuous_const) (fun u => le_max_right u 0)
    let R : ℝ → ℝ := fun u => ∫ v in (0 : ℝ)..u, rt v
    have hcongr : ∀ u, 0 ≤ u → ∀ v ∈ Set.uIcc 0 u, r v ω = rt v := by
      intro u hu v hv
      rw [Set.uIcc_of_le hu] at hv
      simp [rt, max_eq_left hv.1]
    have hRr : ∀ u, 0 ≤ u → (∫ v in (0 : ℝ)..u, r v ω) = R u := fun u hu =>
      intervalIntegral.integral_congr (hcongr u hu)
    have hrel : ∀ u, 0 ≤ u → rt u = r₀ + a * θ * u - a * R u + σ * wp ω u := by
      intro u hu
      have h1 := heq u.toNNReal
      rw [Real.coe_toNNReal _ hu] at h1
      have h2 : (∫ v in (0 : ℝ)..u, a * (θ - r v ω)) = a * θ * u - a * R u := by
        rw [intervalIntegral.integral_congr (g := fun v => a * (θ - rt v))
          (fun v hv => by simp only [hcongr u hu v hv])]
        rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_sub
          intervalIntegrable_const (hrt.intervalIntegrable _ _)]
        simp only [intervalIntegral.integral_const, smul_eq_mul, sub_zero, R]
        ring
      have h3 : rt u = r u ω := by simp [rt, max_eq_left hu]
      rw [h3, h1, h2]
      simp only [wp]
      ring
    let G : ℝ → ℝ := fun u => exp (a * u) * (R u - (r₀ / a + θ * u - θ / a))
    have hG : ∀ u ∈ Set.uIcc 0 Tr, HasDerivAt G (exp (a * u) * (σ * wp ω u)) u := by
      intro u hu
      rw [Set.uIcc_of_le hT0] at hu
      have hR : HasDerivAt R (rt u) u := (hrt.integral_hasStrictDerivAt 0 u).hasDerivAt
      have e := ((hasDerivAt_id' u).const_mul a).exp
      have h := e.mul (hR.sub ((((hasDerivAt_id' u).const_mul θ).const_add (r₀ / a)).sub_const
        (θ / a)))
      refine h.congr_deriv ?_
      rw [hrel u hu.1]
      simp only [Pi.sub_apply]
      field_simp
      ring
    have hFTC := intervalIntegral.integral_eq_sub_of_hasDerivAt hG
      ((by fun_prop : Continuous fun u => exp (a * u) * (σ * wp ω u)).intervalIntegrable _ _)
    have hint : (∫ u in (0 : ℝ)..Tr, exp (a * u) * (σ * wp ω u)) = σ * S ω := by
      simp only [S]
      rw [← intervalIntegral.integral_const_mul]
      congr 1
      funext u
      ring
    rw [hint] at hFTC
    have hR0 : R 0 = 0 := by simp [R]
    simp only [G, hR0, mul_zero, exp_zero] at hFTC
    rw [hRr Tr hT0]
    simp only [vasicekB, hXinv]
    have hXX : X⁻¹ * X = 1 := inv_mul_cancel₀ hXpos.ne'
    linear_combination (-X⁻¹) * hFTC - (R Tr - θ * Tr - (r₀ - θ) / a) * hXX
  -- Combine.
  have hlaw2 := gaussianReal_const_add (gaussianReal_const_mul hS (σ * X⁻¹))
    (θ * Tr + (r₀ - θ) * vasicekB a Tr)
  have hvnn : 0 ≤ σ ^ 2 / a ^ 2 * (Tr - vasicekB a Tr - a * vasicekB a Tr ^ 2 / 2) :=
    hkey ▸ mul_nonneg (sq_nonneg _) hV0
  have hI : HasLaw (fun ω => ∫ u in (0 : ℝ)..Tr, r u ω)
      (gaussianReal (θ * Tr + (r₀ - θ) * vasicekB a Tr)
        (σ ^ 2 / a ^ 2 * (Tr - vasicekB a Tr - a * vasicekB a Tr ^ 2 / 2)).toNNReal) P := by
    convert hlaw2.congr hident using 2
    · ring
    · ext
      rw [Real.coe_toNNReal _ hvnn, ← hkey, NNReal.coe_mul, Real.coe_toNNReal _ hV0]
      rfl
  refine ⟨hI, ?_⟩
  have hm := mgf_gaussianReal hI (-1)
  simp only [mgf, neg_one_mul] at hm
  rw [hm, Real.coe_toNNReal _ hvnn]
  simp only [vasicekPrice, vasicekA]
  congr 1
  field_simp
  ring

/-- **The same answer from the bond equation** (the card's Step 4). With `a > 0`, the price
`P(τ, r) = e^(A(τ) - B(τ) r)` equals 1 at `τ = 0` for every rate `r`, and at every time left `τ`
and every rate `r` it satisfies
`∂P/∂τ = a(θ - r) ∂P/∂r + ½σ² ∂²P/∂r² - rP`. -/
theorem vasicek_price_solves_bond_equation {a : ℝ} (ha : 0 < a) (θ σ : ℝ) :
    (∀ r : ℝ, vasicekPrice a θ σ 0 r = 1) ∧
      ∀ τ r : ℝ, HasDerivAt (fun τ' => vasicekPrice a θ σ τ' r)
        (a * (θ - r) * deriv (fun x => vasicekPrice a θ σ τ x) r
          + 1 / 2 * σ ^ 2 * deriv (deriv (fun x => vasicekPrice a θ σ τ x)) r
          - r * vasicekPrice a θ σ τ r) τ := by
  have ha0 : a ≠ 0 := ha.ne'
  refine ⟨fun r => by simp [vasicekPrice, vasicekA, vasicekB], fun τ r => ?_⟩
  have hx : ∀ x, HasDerivAt (fun x => vasicekPrice a θ σ τ x)
      (-vasicekB a τ * vasicekPrice a θ σ τ x) x := by
    intro x
    have h := (((hasDerivAt_id' x).const_mul (vasicekB a τ)).const_sub (vasicekA a θ σ τ)).exp
    refine h.congr_deriv ?_
    simp only [vasicekPrice]
    ring
  have hd : deriv (fun x => vasicekPrice a θ σ τ x) = fun x => -vasicekB a τ * vasicekPrice a θ σ τ x :=
    funext fun x => (hx x).deriv
  have hdd : deriv (deriv (fun x => vasicekPrice a θ σ τ x)) r =
      vasicekB a τ ^ 2 * vasicekPrice a θ σ τ r := by
    rw [hd]
    rw [((hx r).const_mul (-vasicekB a τ)).deriv]
    ring
  rw [hdd, hd]
  have hB : ∀ s, HasDerivAt (fun s => vasicekB a s) (exp (-a * s)) s := by
    intro s
    have h := ((((hasDerivAt_id' s).const_mul (-a)).exp).const_sub 1).div_const a
    refine h.congr_deriv ?_
    field_simp
  have hA : HasDerivAt (fun s => vasicekA a θ σ s)
      ((θ - σ ^ 2 / (2 * a ^ 2)) * (exp (-a * τ) - 1)
        - σ ^ 2 * (2 * vasicekB a τ * exp (-a * τ)) / (4 * a)) τ := by
    have h := (((hB τ).sub (hasDerivAt_id' τ)).const_mul (θ - σ ^ 2 / (2 * a ^ 2))).sub
      ((((hB τ).pow 2).const_mul (σ ^ 2)).div_const (4 * a))
    refine h.congr_deriv ?_
    norm_num
  have hP : HasDerivAt (fun s => exp (vasicekA a θ σ s - vasicekB a s * r))
      (exp (vasicekA a θ σ τ - vasicekB a τ * r) *
        ((θ - σ ^ 2 / (2 * a ^ 2)) * (exp (-a * τ) - 1)
        - σ ^ 2 * (2 * vasicekB a τ * exp (-a * τ)) / (4 * a) - exp (-a * τ) * r)) τ :=
    (hA.sub ((hB τ).mul_const r)).exp
  refine hP.congr_deriv ?_
  simp only [vasicekPrice]
  generalize exp (vasicekA a θ σ τ - vasicekB a τ * r) = P
  have hBv : vasicekB a τ = (1 - exp (-a * τ)) / a := rfl
  rw [hBv]
  field_simp
  ring

/-- **The long yield.** With `a > 0`, the yield `-ln P(0,T)/T` of a zero maturing at `T` tends,
as `T` grows, to `R∞ = θ - σ²/(2a²)`, below the level `θ` by the convexity term, whatever
today's rate `r₀`. -/
theorem vasicek_long_yield {a : ℝ} (ha : 0 < a) (θ σ r₀ : ℝ) :
    Tendsto (fun T : ℝ => -log (vasicekPrice a θ σ T r₀) / T) atTop
      (𝓝 (θ - σ ^ 2 / (2 * a ^ 2))) := by
  have ha0 : a ≠ 0 := ha.ne'
  have hE : Tendsto (fun T : ℝ => exp (-a * T)) atTop (𝓝 0) := by
    have : Tendsto (fun T : ℝ => -a * T) atTop atBot := by
      have h := tendsto_neg_atTop_atBot.comp (tendsto_id.const_mul_atTop ha)
      refine h.congr (fun T => ?_)
      simp [neg_mul]
    exact Real.tendsto_exp_atBot.comp this
  have hBlim : Tendsto (fun T : ℝ => vasicekB a T) atTop (𝓝 ((1 - 0) / a)) :=
    (tendsto_const_nhds.sub hE).div_const a
  have hg : Tendsto (fun T : ℝ => vasicekB a T * r₀ - (θ - σ ^ 2 / (2 * a ^ 2)) * vasicekB a T
      + σ ^ 2 * vasicekB a T ^ 2 / (4 * a)) atTop
      (𝓝 ((1 - 0) / a * r₀ - (θ - σ ^ 2 / (2 * a ^ 2)) * ((1 - 0) / a)
        + σ ^ 2 * ((1 - 0) / a) ^ 2 / (4 * a))) :=
    ((hBlim.mul_const r₀).sub (hBlim.const_mul _)).add (((hBlim.pow 2).const_mul _).div_const _)
  have h2 := (hg.div_atTop tendsto_id).const_add (θ - σ ^ 2 / (2 * a ^ 2))
  rw [add_zero] at h2
  refine h2.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with T hT
  simp only [vasicekPrice, Real.log_exp, vasicekA, id]
  field_simp
  ring

/-! The card's exact numbers, as fractions: `θ = 5/100`, `a = 3/10`, `σ = 1/100`, `r₀ = 4/100`. -/

-- Step 0: a path that stays at 4 percent for five years has area 0.2.
example : (4 / 100 : ℚ) * 5 = 1 / 5 := by norm_num

-- Worked numbers: σ²/(2a²) = 0.0001/0.18 = 1/1800, and the spread part divides by 4a = 1.2.
example : ((1 : ℚ) / 100) ^ 2 / (2 * (3 / 10) ^ 2) = 1 / 1800 ∧ 4 * (3 / 10 : ℚ) = 6 / 5 := by
  norm_num

-- The long yield θ - σ²/(2a²) = 0.05 - 1/1800 = 89/1800 = 4.9444 percent, under the 5% level.
example : (5 / 100 : ℚ) - ((1 : ℚ) / 100) ^ 2 / (2 * (3 / 10) ^ 2) = 89 / 1800 ∧
    (89 / 1800 : ℚ) < 5 / 100 := by
  norm_num

#print axioms vasicek_zero_coupon_bond_price
#print axioms vasicek_price_solves_bond_equation
#print axioms vasicek_long_yield

end VasicekModel
