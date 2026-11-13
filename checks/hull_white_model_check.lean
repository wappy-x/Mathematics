-- Hull-White: for a pull speed a > 0 and a noise size σ, the drift θ(t) = f'(0,t) + a f(0,t) + σ²/(2a)(1 - e^(-2at)) makes every zero-coupon price equal today's curve, it is the only continuous drift that does, and the closed-form bond price returns the curve at time 0.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.HasLaw
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Tactic.NormNum
import Mathlib

namespace HullWhiteModel

open MeasureTheory ProbabilityTheory Real
open scoped NNReal

/-! Setting. Mathlib's `IsBrownianReal W P` says that `W : ℝ≥0 → Ω → ℝ` is a Brownian motion
under `P` (here the pricing-world weighting of paths): its finite-dimensional laws are those of
a Brownian motion and its paths are continuous almost surely.

Today's forward curve is a function `f : ℝ → ℝ`, `f t` being the forward rate `f(0,t)` for the
instant at `t`; today's price of a dollar due at `T` is `D(T) = e^(-∫₀ᵀ f)`.

Mathlib has no Ito integral. The Hull-White noise is added, not multiplied, so the equation
`dr = (θ(t) - a r) dt + σ dW` is written path by path:
`r_t = r₀ + ∫₀ᵗ (θ(u) - a r_u) du + σ W_t`, with continuous paths. -/

/-- Today's discount factor `D(T) = e^(-∫₀ᵀ f(0,s) ds)` built from the forward curve `f`. -/
noncomputable def discount (f : ℝ → ℝ) (T : ℝ) : ℝ := exp (-∫ s in (0 : ℝ)..T, f s)

/-- The Hull-White drift `θ(t) = f'(0,t) + a f(0,t) + σ²/(2a) (1 - e^(-2at))`: the card's boxed
formula. -/
noncomputable def hwTheta (a σ : ℝ) (f : ℝ → ℝ) (t : ℝ) : ℝ :=
  deriv f t + a * f t + σ ^ 2 / (2 * a) * (1 - exp (-2 * a * t))

/-- `B(t,T) = (1 - e^(-a(T-t)))/a`: the bond's exposure to the rate. -/
noncomputable def hwB (a t T : ℝ) : ℝ := (1 - exp (-a * (T - t))) / a

/-- `V(T) = σ²/a² (T - 2B(0,T) + (1 - e^(-2aT))/(2a))`: the variance of the total rate paid
from today to `T`. -/
noncomputable def hwV (a σ T : ℝ) : ℝ :=
  σ ^ 2 / a ^ 2 * (T - 2 * hwB a 0 T + (1 - exp (-2 * a * T)) / (2 * a))

/-- `lift(t) = σ²/(2a²) (1 - e^(-at))²`: how far the expected rate sits above the forward curve. -/
noncomputable def hwLift (a σ t : ℝ) : ℝ := σ ^ 2 / (2 * a ^ 2) * (1 - exp (-a * t)) ^ 2

/-- The closed-form bond price at a later date `t`, with the short rate at `r`:
`P(t,T) = D(T)/D(t) · exp(B f(0,t) - σ²/(4a) (1 - e^(-2at)) B² - B r)`, `B = B(t,T)`. -/
noncomputable def hwPrice (a σ : ℝ) (f : ℝ → ℝ) (t T r : ℝ) : ℝ :=
  discount f T / discount f t *
    exp (hwB a t T * f t - σ ^ 2 / (4 * a) * (1 - exp (-2 * a * t)) * hwB a t T ^ 2
      - hwB a t T * r)

section HullWhiteHelpers

open Filter Topology

/-- A continuous function whose integrals from `0` vanish on `[0, ∞)` vanishes there. -/
theorem hw_eq_zero_of_integral_eq_zero {h : ℝ → ℝ} (hh : Continuous h)
    (H : ∀ T : ℝ, 0 ≤ T → ∫ u in (0 : ℝ)..T, h u = 0) : ∀ t : ℝ, 0 ≤ t → h t = 0 := by
  intro t ht
  have h1 : HasDerivWithinAt (fun T => ∫ u in (0 : ℝ)..T, h u) (h t) (Set.Ici t) t :=
    intervalIntegral.integral_hasDerivWithinAt_right (hh.intervalIntegrable _ _)
      (hh.stronglyMeasurableAtFilter _ _) hh.continuousWithinAt
  have h2 : HasDerivWithinAt (fun T => ∫ u in (0 : ℝ)..T, h u) 0 (Set.Ici t) t := by
    apply (hasDerivWithinAt_const t (Set.Ici t) (0 : ℝ)).congr
    · intro y hy; exact H y (le_trans ht hy)
    · exact H t ht
  exact (uniqueDiffOn_Ici t t (by simp)).eq_deriv _ h1 h2

theorem hw_lift_hasDerivAt (a σ : ℝ) (ha : a ≠ 0) (x : ℝ) :
    HasDerivAt (fun t => σ ^ 2 / (2 * a ^ 2) * (t + 2 / a * exp (-a * t)
      - 1 / (2 * a) * exp (-2 * a * t))) (hwLift a σ x) x := by
  have e1 := ((hasDerivAt_id' x).const_mul (-a)).exp
  have e2 := ((hasDerivAt_id' x).const_mul (-2 * a)).exp
  have := (((hasDerivAt_id' x).fun_add (e1.const_mul (2 / a))).fun_sub
    (e2.const_mul (1 / (2 * a)))).const_mul (σ ^ 2 / (2 * a ^ 2))
  convert this using 1
  simp only [hwLift]
  have : exp (-2 * a * x) = exp (-a * x) ^ 2 := by
    rw [← Real.exp_nat_mul]; congr 1; push_cast; ring
  rw [this]
  field_simp
  ring

theorem hw_lift_deriv (a σ : ℝ) (ha : a ≠ 0) (x : ℝ) :
    HasDerivAt (hwLift a σ) (σ ^ 2 / a * (1 - exp (-a * x)) * exp (-a * x)) x := by
  have e1 := ((hasDerivAt_id' x).const_mul (-a)).exp
  have := ((e1.const_sub 1).fun_pow 2).const_mul (σ ^ 2 / (2 * a ^ 2))
  convert this using 1
  · rfl
  · push_cast
    field_simp

theorem hw_ode {a : ℝ} {ρ h : ℝ → ℝ} (hρ : Continuous ρ) (hh : Continuous h)
    (H : ∀ t : ℝ, 0 ≤ t → ρ t = h t - a * ∫ u in (0 : ℝ)..t, ρ u) (T : ℝ) (hT : 0 ≤ T) :
    ∫ u in (0 : ℝ)..T, ρ u = ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * h u := by
  set D : ℝ → ℝ := fun t => exp (a * t) * (∫ u in (0 : ℝ)..t, ρ u)
    - ∫ u in (0 : ℝ)..t, exp (a * u) * h u with hDdef
  have hcE : Continuous fun u => exp (a * u) * h u := by fun_prop
  have hderiv : ∀ x, HasDerivAt D (exp (a * x) * (a * (∫ u in (0 : ℝ)..x, ρ u) + ρ x - h x)) x := by
    intro x
    have e := ((hasDerivAt_id' x).const_mul a).exp
    have i1 := (hρ.integral_hasStrictDerivAt 0 x).hasDerivAt
    have i2 := (hcE.integral_hasStrictDerivAt 0 x).hasDerivAt
    convert (e.fun_mul i1).fun_sub i2 using 1
    ring
  have hDc : Continuous D := continuous_iff_continuousAt.2 fun x => (hderiv x).continuousAt
  have hconst := constant_of_has_deriv_right_zero (a := 0) (b := T) hDc.continuousOn
    (fun x hx => by
      have := (hderiv x).hasDerivWithinAt (s := Set.Ici x)
      rw [H x hx.1] at this
      convert this using 1
      ring)
  have h1 := hconst T ⟨hT, le_rfl⟩
  simp only [hDdef, intervalIntegral.integral_same, mul_zero, sub_zero] at h1
  have h2 : ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * h u
      = exp (-a * T) * ∫ u in (0 : ℝ)..T, exp (a * u) * h u := by
    rw [← intervalIntegral.integral_const_mul]
    congr 1
    funext u
    rw [← mul_assoc, ← Real.exp_add]
    ring_nf
  rw [h2, ← sub_eq_zero.1 h1, ← mul_assoc, ← Real.exp_add]
  simp

/-- The grid point `k T / n`. -/
noncomputable def hwGrid (T : ℝ) (n k : ℕ) : ℝ := k * T / n

theorem hw_riemann {F ψ : ℝ → ℝ} (hF : Continuous F) (hψ : Continuous ψ) {T : ℝ} (hT : 0 ≤ T)
    (p : ℕ → ℕ → ℝ) (hp : ∀ n k, k < n → p n k ∈ Set.Icc (hwGrid T n k) (hwGrid T n (k + 1))) :
    Tendsto (fun n : ℕ => ∑ k ∈ Finset.range n,
        (∫ u in (hwGrid T n k)..(hwGrid T n (k + 1)), ψ u) * F (p n k))
      atTop (𝓝 (∫ u in (0 : ℝ)..T, ψ u * F u)) := by
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨C, hC⟩ := isCompact_Icc.exists_bound_of_continuousOn (hψ.continuousOn (s := Set.Icc 0 T))
  set M := max C 0 + 1 with hM
  have hMpos : 0 < M := by positivity
  have huc := isCompact_Icc.uniformContinuousOn_of_continuous (hF.continuousOn (s := Set.Icc 0 T))
  rw [Metric.uniformContinuousOn_iff] at huc
  obtain ⟨δ, hδ, hδ'⟩ := huc (ε / (2 * M * (T + 1))) (by positivity)
  obtain ⟨N, hN⟩ := exists_nat_gt (T / δ)
  refine ⟨N + 1, fun n hn => ?_⟩
  have hn0 : (0 : ℝ) < n := by
    have : (1 : ℕ) ≤ n := by omega
    exact_mod_cast this
  have hNn : (N : ℝ) < n := by exact_mod_cast (show N < n by omega)
  have hmesh : T / n < δ := by
    rw [div_lt_iff₀ hn0]
    rw [div_lt_iff₀ hδ] at hN
    nlinarith
  set a := hwGrid T n with ha
  have hstep : ∀ k, a (k + 1) - a k = T / n := by
    intro k; simp only [ha, hwGrid]; push_cast; ring
  have hmono : ∀ k, a k ≤ a (k + 1) := by
    intro k; have := hstep k; have : 0 ≤ T / n := by positivity
    linarith
  have hlo : ∀ k, 0 ≤ a k := by intro k; simp only [ha, hwGrid]; positivity
  have hhi : ∀ k, k ≤ n → a k ≤ T := by
    intro k hk; simp only [ha, hwGrid]
    rw [div_le_iff₀ hn0]
    have : (k : ℝ) ≤ n := by exact_mod_cast hk
    nlinarith
  have hsplit : ∑ k ∈ Finset.range n, ∫ u in (a k)..(a (k + 1)), ψ u * F u
      = ∫ u in (0 : ℝ)..T, ψ u * F u := by
    rw [intervalIntegral.sum_integral_adjacent_intervals]
    · congr 1
      · simp [ha, hwGrid]
      · simp only [ha, hwGrid]; field_simp
    · intro k _; exact (hψ.mul hF).intervalIntegrable _ _
  have hterm : ∀ k, (∫ u in (a k)..(a (k + 1)), ψ u) * F (p n k) - ∫ u in (a k)..(a (k + 1)), ψ u * F u
      = ∫ u in (a k)..(a (k + 1)), ψ u * (F (p n k) - F u) := by
    intro k
    simp_rw [mul_sub]
    rw [intervalIntegral.integral_sub, intervalIntegral.integral_mul_const]
    · exact (hψ.mul continuous_const).intervalIntegrable _ _
    · exact (hψ.mul hF).intervalIntegrable _ _
  have hbound : ∀ k ∈ Finset.range n,
      ‖∫ u in (a k)..(a (k + 1)), ψ u * (F (p n k) - F u)‖ ≤ M * (ε / (2 * M * (T + 1))) * (T / n) := by
    intro k hk
    rw [Finset.mem_range] at hk
    rw [← hstep k, ← abs_of_nonneg (sub_nonneg.2 (hmono k))]
    apply intervalIntegral.norm_integral_le_of_norm_le_const
    intro u hu
    rw [Set.uIoc_of_le (hmono k)] at hu
    have hu0 : u ∈ Set.Icc 0 T := ⟨le_trans (hlo k) hu.1.le, le_trans hu.2 (hhi (k + 1) hk)⟩
    have hpk := hp n k hk
    have hp0 : p n k ∈ Set.Icc 0 T := ⟨le_trans (hlo k) hpk.1, le_trans hpk.2 (hhi (k + 1) hk)⟩
    have hd : dist (p n k) u < δ := by
      rw [Real.dist_eq, abs_lt]
      have := hstep k
      constructor <;> linarith [hu.1, hu.2, hpk.1, hpk.2]
    have h1 := hδ' _ hp0 _ hu0 hd
    rw [Real.dist_eq] at h1
    rw [norm_mul, Real.norm_eq_abs (F (p n k) - F u)]
    have h2 : ‖ψ u‖ ≤ M := le_trans (hC u hu0) (by rw [hM]; linarith [le_max_left C 0])
    exact mul_le_mul h2 h1.le (abs_nonneg _) hMpos.le
  rw [dist_eq_norm, ← hsplit, ← Finset.sum_sub_distrib]
  simp_rw [hterm]
  refine lt_of_le_of_lt (le_trans (norm_sum_le _ _) (Finset.sum_le_sum hbound)) ?_
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
  have : (n : ℝ) * (M * (ε / (2 * M * (T + 1))) * (T / n)) = ε * (T / (2 * (T + 1))) := by
    field_simp
  rw [this]
  have : T / (2 * (T + 1)) < 1 := by rw [div_lt_one (by positivity)]; linarith
  nlinarith

theorem hw_abel (G V : ℕ → ℝ) (n : ℕ) :
    ∑ k ∈ Finset.range n, G (k + 1) * (V (k + 1) - V k)
      = G n * V n - G 0 * V 0 + ∑ k ∈ Finset.range n, (G k - G (k + 1)) * V k := by
  induction n with
  | zero => simp
  | succ n ih => rw [Finset.sum_range_succ, ih, Finset.sum_range_succ]; ring

theorem hw_gauss {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsBrownianReal W P) {g G : ℝ → ℝ} (hg : Continuous g) (hG : Continuous G)
    {T : ℝ} (hT : 0 ≤ T) (hGint : ∀ s, G s = ∫ u in s..T, g u) :
    HasLaw (fun ω => ∫ u in (0 : ℝ)..T, g u * W u.toNNReal ω)
      (gaussianReal 0 (NNReal.mk (∫ s in (0 : ℝ)..T, G s ^ 2)
        (intervalIntegral.integral_nonneg hT (fun _ _ => sq_nonneg _)))) P := by
  have hP : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  set v : ℝ≥0 := NNReal.mk (∫ s in (0 : ℝ)..T, G s ^ 2)
    (intervalIntegral.integral_nonneg hT (fun _ _ => sq_nonneg _)) with hvdef
  set X : Ω → ℝ := fun ω => ∫ u in (0 : ℝ)..T, g u * W u.toNNReal ω with hXdef
  -- the grid and the discrete sums
  set t : ℕ → ℕ → ℝ≥0 := fun n k => (hwGrid T n k).toNNReal with htdef
  have hgrid0 : ∀ n k, 0 ≤ hwGrid T n k := fun n k => by unfold hwGrid; positivity
  have htcoe : ∀ n k, ((t n k : ℝ≥0) : ℝ) = hwGrid T n k := fun n k =>
    Real.coe_toNNReal _ (hgrid0 n k)
  have hgridmono : ∀ n, Monotone (hwGrid T n) := by
    intro n i j hij
    unfold hwGrid
    have : (i : ℝ) ≤ j := by exact_mod_cast hij
    have : (0 : ℝ) ≤ n := by positivity
    gcongr
  have hstep : ∀ n k, hwGrid T n k ≤ hwGrid T n (k + 1) := fun n k => hgridmono n (by omega)
  set Z : ℕ → ℕ → Ω → ℝ := fun n k ω =>
    G (hwGrid T n (k + 1)) * (W (t n (k + 1)) ω - W (t n k) ω) with hZdef
  set S : ℕ → Ω → ℝ := fun n => ∑ k ∈ Finset.range n, Z n k with hSdef
  set w : ℕ → ℕ → ℝ≥0 := fun n k =>
    NNReal.mk (G (hwGrid T n (k + 1)) ^ 2) (sq_nonneg _) * nndist (t n (k + 1)).1 (t n k).1 with hwdef
  set vn : ℕ → ℝ≥0 := fun n => ∑ k ∈ Finset.range n, w n k with hvndef
  have hmeasW : ∀ s, AEMeasurable (W s) P := fun s => hW.aemeasurable s
  have hZmeas : ∀ n k, AEMeasurable (Z n k) P := by
    intro n k
    exact ((hmeasW _).sub (hmeasW _)).const_mul _
  have hSmeas : ∀ n, AEMeasurable (S n) P := by
    intro n
    exact Finset.aemeasurable_sum _ (fun k _ => hZmeas n k)
  -- the law of each discrete sum
  have hZlaw : ∀ n k, HasLaw (Z n k) (gaussianReal 0 (w n k)) P := by
    intro n k
    have := gaussianReal_const_mul (hW.hasLaw_sub (t n (k + 1)) (t n k)) (G (hwGrid T n (k + 1)))
    rw [mul_zero] at this
    exact this
  have hindep : ∀ n, iIndepFun (Z n) P := by
    intro n
    have hm : Monotone (t n) := fun i j hij => Real.toNNReal_le_toNNReal (hgridmono n hij)
    exact (hW.hasIndepIncrements.nat hm).comp (fun k x => G (hwGrid T n (k + 1)) * x)
      (fun k => measurable_const.mul measurable_id)
  have hSlaw : ∀ n, HasLaw (S n) (gaussianReal 0 (vn n)) P := by
    intro n
    have : ∀ m, HasLaw (∑ k ∈ Finset.range m, Z n k)
        (gaussianReal 0 (∑ k ∈ Finset.range m, w n k)) P := by
      intro m
      induction m with
      | zero =>
        refine ⟨by simp; fun_prop, ?_⟩
        simp only [Finset.range_zero, Finset.sum_empty, gaussianReal_zero_var]
        show P.map (fun _ => (0 : ℝ)) = _
        rw [Measure.map_const, measure_univ, one_smul]
      | succ m ih =>
        rw [Finset.sum_range_succ, Finset.sum_range_succ]
        refine ⟨ih.aemeasurable.add (hZmeas n m), ?_⟩
        rw [gaussianReal_add_gaussianReal_of_indepFun
          ((hindep n).indepFun_sum_range_succ₀ (hZmeas n) m) ih (hZlaw n m), add_zero]
    exact this n
  -- convergence of the variances
  have hvn : ∀ n, ((vn n : ℝ≥0) : ℝ) = ∑ k ∈ Finset.range n,
      (∫ _ in (hwGrid T n k)..(hwGrid T n (k + 1)), (1 : ℝ)) * (fun s => G s ^ 2)
        (hwGrid T n (k + 1)) := by
    intro n
    simp only [hvndef, hwdef, NNReal.coe_sum, NNReal.coe_mul, NNReal.coe_mk, coe_nndist,
      intervalIntegral.integral_const, smul_eq_mul, mul_one, Real.dist_eq]
    refine Finset.sum_congr rfl fun k _ => ?_
    have e1 : ((t n (k + 1)).1 : ℝ) = hwGrid T n (k + 1) := htcoe _ _
    have e2 : ((t n k).1 : ℝ) = hwGrid T n k := htcoe _ _
    simp only [e1, e2]
    rw [abs_of_nonneg (sub_nonneg.2 (hstep n k))]
    ring
  have hvlim : Tendsto (fun n => vn n) atTop (𝓝 v) := by
    have := hw_riemann (F := fun s => G s ^ 2) (ψ := fun _ => (1 : ℝ)) (hG.pow 2)
      continuous_const hT (fun n k => hwGrid T n (k + 1))
      (fun n k _ => ⟨hstep n k, le_rfl⟩)
    have hv' : ((v : ℝ≥0) : ℝ)
        = ∫ u in (0 : ℝ)..T, (fun _ => (1 : ℝ)) u * (fun s => G s ^ 2) u := by
      simp [hvdef]
    rw [← NNReal.tendsto_coe]
    refine Tendsto.congr (fun n => (hvn n).symm) ?_
    rw [hv']
    exact this
  -- almost sure convergence of the discrete sums
  have hSlim : ∀ᵐ ω ∂P, Tendsto (fun n => S n ω) atTop (𝓝 (X ω)) := by
    filter_upwards [hW.cont, hW.eval_zero_ae_eq_zero] with ω hc h0
    have hwc : Continuous fun u : ℝ => W u.toNNReal ω := hc.comp continuous_real_toNNReal
    have hR := hw_riemann (F := fun u : ℝ => W u.toNNReal ω) (ψ := g) hwc hg hT
      (fun n k => hwGrid T n k) (fun n k _ => ⟨le_rfl, hstep n k⟩)
    refine hR.congr' ?_
    rw [EventuallyEq, eventually_atTop]
    refine ⟨1, fun n hn => ?_⟩
    have hab := hw_abel (fun k => G (hwGrid T n k)) (fun k => W (t n k) ω) n
    simp only [hSdef, hZdef, Finset.sum_apply]
    rw [hab]
    have hn : (n : ℝ) ≠ 0 := by have : (1 : ℝ) ≤ n := by exact_mod_cast hn
                                linarith
    have hGn : G (hwGrid T n n) = 0 := by
      rw [hGint]
      have : hwGrid T n n = T := by unfold hwGrid; field_simp
      rw [this, intervalIntegral.integral_same]
    have ht0 : t n 0 = 0 := by simp [htdef, hwGrid]
    rw [hGn, ht0, h0, zero_mul, mul_zero, sub_zero, zero_add]
    refine Finset.sum_congr rfl fun k _ => ?_
    have hadd := intervalIntegral.integral_add_adjacent_intervals
      (hg.intervalIntegrable (μ := volume) (hwGrid T n k) (hwGrid T n (k + 1)))
      (hg.intervalIntegrable (μ := volume) (hwGrid T n (k + 1)) T)
    rw [hGint, hGint, ← hadd]
    simp [htdef]
  have hXmeas : AEMeasurable X P := aemeasurable_of_tendsto_metrizable_ae' hSmeas hSlim
  -- characteristic functions
  refine ⟨hXmeas, ?_⟩
  apply Measure.ext_of_charFun
  funext τ
  have hcf : ∀ (Y : Ω → ℝ), AEMeasurable Y P →
      charFun (P.map Y) τ = ∫ ω, Complex.exp (τ * Y ω * Complex.I) ∂P := by
    intro Y hY
    rw [charFun_apply_real, integral_map hY]
    exact (by fun_prop : Continuous fun x : ℝ => Complex.exp (τ * x * Complex.I)).aestronglyMeasurable
  have hlim1 : Tendsto (fun n => charFun (P.map (S n)) τ) atTop (𝓝 (charFun (P.map X) τ)) := by
    simp_rw [hcf _ (hSmeas _), hcf _ hXmeas]
    refine tendsto_integral_of_dominated_convergence (fun _ => 1) (fun n => ?_)
      (integrable_const _) (fun n => Eventually.of_forall fun ω => ?_) ?_
    · exact ((by fun_prop : Continuous fun x : ℝ => Complex.exp (τ * x * Complex.I)).measurable.comp_aemeasurable
        (hSmeas n)).aestronglyMeasurable
    · rw [← Complex.ofReal_mul, Complex.norm_exp_ofReal_mul_I]
    · filter_upwards [hSlim] with ω hω
      exact ((by fun_prop : Continuous fun x : ℝ => Complex.exp (τ * x * Complex.I)).tendsto _).comp hω
  have hlim2 : Tendsto (fun n => charFun (P.map (S n)) τ) atTop
      (𝓝 (charFun (gaussianReal 0 v) τ)) := by
    simp_rw [fun n => (hSlaw n).map_eq, charFun_gaussianReal]
    exact ((by fun_prop : Continuous fun x : ℝ≥0 =>
      Complex.exp (τ * ((0 : ℝ) : ℂ) * Complex.I - ((x : ℝ) : ℂ) * τ ^ 2 / 2)).tendsto v).comp hvlim
  exact tendsto_nhds_unique hlim1 hlim2

theorem hw_B_eq_integral {a : ℝ} (ha : a ≠ 0) (T s : ℝ) :
    hwB a s T = ∫ u in s..T, exp (-a * (T - u)) := by
  have hd : ∀ x, HasDerivAt (fun u => exp (-a * (T - u)) / a) (exp (-a * (T - x))) x := by
    intro x
    have e := ((((hasDerivAt_id' x).const_sub T).const_mul (-a)).exp).div_const a
    convert e using 1
    field_simp
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hd x)
    ((by fun_prop : Continuous fun u => exp (-a * (T - u))).intervalIntegrable _ _)]
  simp only [hwB, sub_self, mul_zero, exp_zero]
  ring

theorem hw_V_eq_integral {a : ℝ} (ha : a ≠ 0) (σ T : ℝ) :
    hwV a σ T = σ ^ 2 * ∫ s in (0 : ℝ)..T, hwB a s T ^ 2 := by
  have hd : ∀ x, HasDerivAt (fun s => (s - 2 / a * exp (-a * (T - s))
      + 1 / (2 * a) * exp (-2 * a * (T - s))) / a ^ 2) (hwB a x T ^ 2) x := by
    intro x
    have e1 := (((hasDerivAt_id' x).const_sub T).const_mul (-a)).exp
    have e2 := (((hasDerivAt_id' x).const_sub T).const_mul (-2 * a)).exp
    have := (((hasDerivAt_id' x).fun_sub (e1.const_mul (2 / a))).fun_add
      (e2.const_mul (1 / (2 * a)))).div_const (a ^ 2)
    convert this using 1
    simp only [hwB]
    have h2 : exp (-2 * a * (T - x)) = exp (-a * (T - x)) ^ 2 := by
      rw [← Real.exp_nat_mul]; congr 1; push_cast; ring
    rw [h2]
    field_simp
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hd x)
    ((by unfold hwB; fun_prop : Continuous fun s => hwB a s T ^ 2).intervalIntegrable _ _)]
  simp only [hwV, hwB, sub_self, sub_zero, mul_zero, exp_zero]
  field_simp
  ring

theorem hw_exp_factor (a T : ℝ) (k : ℝ → ℝ) :
    ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * k u
      = exp (-a * T) * ∫ u in (0 : ℝ)..T, exp (a * u) * k u := by
  rw [← intervalIntegral.integral_const_mul]
  congr 1
  funext u
  rw [← mul_assoc, ← Real.exp_add]
  ring_nf

theorem hw_primitive_continuous {θ : ℝ → ℝ} (hθ : Continuous θ) :
    Continuous fun u => ∫ x in (0 : ℝ)..u, θ x :=
  continuous_iff_continuousAt.2 fun u => (hθ.integral_hasStrictDerivAt 0 u).hasDerivAt.continuousAt

theorem hw_conv_eq {a f0 : ℝ} {θ₁ θ₂ : ℝ → ℝ} (h₁ : Continuous θ₁) (h₂ : Continuous θ₂)
    (H : ∀ T : ℝ, 0 ≤ T →
      ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * (f0 + ∫ x in (0 : ℝ)..u, θ₁ x)
        = ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * (f0 + ∫ x in (0 : ℝ)..u, θ₂ x)) :
    ∀ t : ℝ, 0 ≤ t → θ₁ t = θ₂ t := by
  intro t ht
  have hI1 := hw_primitive_continuous h₁
  have hI2 := hw_primitive_continuous h₂
  have step1 : ∀ T : ℝ, 0 ≤ T → ∫ u in (0 : ℝ)..T,
      exp (a * u) * ((∫ x in (0 : ℝ)..u, θ₁ x) - ∫ x in (0 : ℝ)..u, θ₂ x) = 0 := by
    intro T hT
    have h := H T hT
    rw [hw_exp_factor, hw_exp_factor] at h
    have h' := mul_left_cancel₀ (exp_ne_zero _) h
    rw [← sub_eq_zero, ← intervalIntegral.integral_sub] at h'
    · refine Eq.trans ?_ h'
      congr 1
      funext u
      ring
    · exact ((by fun_prop : Continuous fun u : ℝ => exp (a * u)).mul
        (continuous_const.add hI1)).intervalIntegrable _ _
    · exact ((by fun_prop : Continuous fun u : ℝ => exp (a * u)).mul
        (continuous_const.add hI2)).intervalIntegrable _ _
  have step2 := hw_eq_zero_of_integral_eq_zero
    ((by fun_prop : Continuous fun u : ℝ => exp (a * u)).mul (hI1.sub hI2)) step1
  have step3 : ∀ T : ℝ, 0 ≤ T → ∫ x in (0 : ℝ)..T, (θ₁ x - θ₂ x) = 0 := by
    intro T hT
    rw [intervalIntegral.integral_sub (h₁.intervalIntegrable _ _) (h₂.intervalIntegrable _ _)]
    rcases mul_eq_zero.1 (step2 T hT) with h | h
    · exact absurd h (exp_ne_zero _)
    · exact h
  have := hw_eq_zero_of_integral_eq_zero (h := fun x => θ₁ x - θ₂ x) (h₁.sub h₂) step3 t ht
  linarith

theorem hw_mean_path_and_drift {a σ : ℝ} (ha : 0 < a) {f : ℝ → ℝ}
    (hf : Differentiable ℝ f) :
    (∀ T : ℝ, ∫ t in (0 : ℝ)..T, hwLift a σ t = hwV a σ T / 2) ∧
    (∀ φ : ℝ → ℝ, Continuous φ →
      (∀ T : ℝ, 0 ≤ T → ∫ t in (0 : ℝ)..T, φ t = (∫ t in (0 : ℝ)..T, f t) + hwV a σ T / 2) →
      ∀ t : ℝ, 0 ≤ t → φ t = f t + hwLift a σ t) ∧
    (∀ t : ℝ, deriv (fun s => f s + hwLift a σ s) t + a * (f t + hwLift a σ t)
      = hwTheta a σ f t) := by
  have ha' : a ≠ 0 := ha.ne'
  have hint : ∀ T : ℝ, ∫ t in (0 : ℝ)..T, hwLift a σ t = hwV a σ T / 2 := by
    intro T
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hw_lift_hasDerivAt a σ ha' x)]
    · simp only [hwV, hwB]
      have h0 : exp (-a * 0) = 1 := by simp
      have h0' : exp (-2 * a * 0) = 1 := by simp
      rw [h0, h0', sub_zero]
      field_simp
      ring
    · exact (by unfold hwLift; fun_prop : Continuous (hwLift a σ)).intervalIntegrable _ _
  have hcont : Continuous (hwLift a σ) := by unfold hwLift; fun_prop
  refine ⟨hint, ?_, ?_⟩
  · intro φ hφ H t ht
    have key := hw_eq_zero_of_integral_eq_zero (h := fun u => φ u - (f u + hwLift a σ u))
      (hφ.sub (hf.continuous.add hcont)) ?_ t ht
    · linarith
    intro T hT
    rw [intervalIntegral.integral_sub (f := φ) (g := fun u => f u + hwLift a σ u)
      (hφ.intervalIntegrable _ _)
      ((hf.continuous.add hcont : Continuous fun u => f u + hwLift a σ u).intervalIntegrable _ _),
      intervalIntegral.integral_add (hf.continuous.intervalIntegrable _ _)
      (hcont.intervalIntegrable _ _), H T hT, hint]
    ring
  · intro t
    rw [((hf t).hasDerivAt.fun_add (hw_lift_deriv a σ ha' t)).deriv]
    simp only [hwTheta, hwLift]
    have : exp (-2 * a * t) = exp (-a * t) ^ 2 := by
      rw [← Real.exp_nat_mul]; congr 1; push_cast; ring
    rw [this]
    field_simp
    ring

theorem hw_price {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {W : ℝ≥0 → Ω → ℝ}
    (hW : IsBrownianReal W P) {a σ : ℝ} (ha : 0 < a) {f0 : ℝ} {θ : ℝ → ℝ} (hθ : Continuous θ)
    (r : ℝ → Ω → ℝ)
    (hr : ∀ᵐ ω ∂P, ContinuousOn (fun s => r s ω) (Set.Ici 0) ∧
      ∀ t : ℝ≥0, r t ω = f0 + (∫ u in (0 : ℝ)..t, (θ u - a * r u ω)) + σ * W t ω)
    (T : ℝ) (hT : 0 ≤ T) :
    ∫ ω, exp (-∫ u in (0 : ℝ)..T, r u ω) ∂P
      = exp (-(∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * (f0 + ∫ x in (0 : ℝ)..u, θ x))
        + hwV a σ T / 2) := by
  have ha' : a ≠ 0 := ha.ne'
  have hP : IsProbabilityMeasure P := hW.isGaussianProcess.isProbabilityMeasure
  have hΘ := hw_primitive_continuous hθ
  have hgauss := hw_gauss hW (g := fun u => exp (-a * (T - u))) (G := fun s => hwB a s T)
    (by fun_prop) (by unfold hwB; fun_prop) hT (fun s => hw_B_eq_integral ha' T s)
  set X : Ω → ℝ := fun ω => ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * W u.toNNReal ω with hXdef
  set m : ℝ := ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * (f0 + ∫ x in (0 : ℝ)..u, θ x) with hmdef
  have hpath : ∀ᵐ ω ∂P, ∫ u in (0 : ℝ)..T, r u ω = m + σ * X ω := by
    filter_upwards [hr, hW.cont] with ω hω hc
    obtain ⟨hrc, hreq⟩ := hω
    set ρ : ℝ → ℝ := fun t => r (max t 0) ω with hρdef
    have hρc : Continuous ρ :=
      hrc.comp_continuous (continuous_id.max continuous_const) (fun t => le_max_right t 0)
    have hρeq : ∀ t : ℝ, 0 ≤ t → ∫ u in (0 : ℝ)..t, r u ω = ∫ u in (0 : ℝ)..t, ρ u := by
      intro t ht
      refine intervalIntegral.integral_congr (fun u hu => ?_)
      rw [Set.uIcc_of_le ht] at hu
      simp only [hρdef, max_eq_left hu.1]
    have hwc : Continuous fun u : ℝ => W u.toNNReal ω := hc.comp continuous_real_toNNReal
    set h : ℝ → ℝ := fun t => (f0 + ∫ x in (0 : ℝ)..t, θ x) + σ * W t.toNNReal ω with hhdef
    have hh : Continuous h := (continuous_const.add hΘ).add (continuous_const.mul hwc)
    have H : ∀ t : ℝ, 0 ≤ t → ρ t = h t - a * ∫ u in (0 : ℝ)..t, ρ u := by
      intro t ht
      have e := hreq t.toNNReal
      rw [Real.coe_toNNReal t ht] at e
      have hri : IntervalIntegrable (fun u => r u ω) volume 0 t := by
        apply ContinuousOn.intervalIntegrable
        rw [Set.uIcc_of_le ht]
        exact hrc.mono Set.Icc_subset_Ici_self
      rw [intervalIntegral.integral_sub (hθ.intervalIntegrable _ _) (hri.const_mul a),
        intervalIntegral.integral_const_mul, hρeq t ht] at e
      simp only [hρdef, hhdef, max_eq_left ht]
      rw [e]
      ring
    have hode := hw_ode hρc hh H T hT
    rw [hρeq T hT, hode, hmdef, hXdef]
    simp only [hhdef]
    rw [← intervalIntegral.integral_const_mul, ← intervalIntegral.integral_add]
    · congr 1
      funext u
      ring
    · exact ((by fun_prop : Continuous fun u : ℝ => exp (-a * (T - u))).mul
        (continuous_const.add hΘ)).intervalIntegrable _ _
    · exact (continuous_const.mul ((by fun_prop : Continuous fun u : ℝ => exp (-a * (T - u))).mul
        hwc)).intervalIntegrable _ _
  calc ∫ ω, exp (-∫ u in (0 : ℝ)..T, r u ω) ∂P
      = ∫ ω, exp (-m) * exp ((-σ) * X ω) ∂P := by
        refine integral_congr_ae (hpath.mono fun ω hω => ?_)
        simp only
        rw [hω, ← Real.exp_add]
        congr 1
        ring
    _ = exp (-m) * mgf X P (-σ) := by
        rw [integral_const_mul]
        rfl
    _ = exp (-m + hwV a σ T / 2) := by
        rw [mgf_gaussianReal hgauss, ← Real.exp_add, hw_V_eq_integral ha' σ T]
        congr 1
        simp only [NNReal.coe_mk]
        ring

#print axioms hw_eq_zero_of_integral_eq_zero
#print axioms hw_lift_hasDerivAt
#print axioms hw_lift_deriv
#print axioms hw_ode
#print axioms hw_riemann
#print axioms hw_abel
#print axioms hw_gauss
#print axioms hw_B_eq_integral
#print axioms hw_V_eq_integral
#print axioms hw_exp_factor
#print axioms hw_primitive_continuous
#print axioms hw_conv_eq
#print axioms hw_mean_path_and_drift
#print axioms hw_price

end HullWhiteHelpers

/-- **Hull-White fits today's curve, and only one drift does** (the card's main claim). Let `W`
be a Brownian motion, `a > 0` the pull speed, `σ` the noise size, and `f` today's forward curve,
with a continuous slope at every date. Start the rate at the curve's front end, `r₀ = f(0,0)`.

1. With the drift `θ(t) = f'(0,t) + a f(0,t) + σ²/(2a)(1 - e^(-2at))`, if the short rate `r`
   solves `r_t = f(0,0) + ∫₀ᵗ (θ(u) - a r_u) du + σ W_t` with continuous paths, then every
   zero-coupon price, the average of `e^(-∫₀ᵀ r)`, equals today's `D(T)`, for every `T ≥ 0`.
2. If any other continuous drift `θ'` gives a short rate `r'` (same equation, same start, same
   noise) whose zero-coupon prices all equal `D(T)`, then `θ'` is that same drift at every date
   `t ≥ 0`. -/
theorem hull_white_drift_fits_curve_uniquely {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) {a σ : ℝ} (ha : 0 < a)
    {f : ℝ → ℝ} (hf : ContDiff ℝ 1 f) :
    (∀ r : ℝ → Ω → ℝ,
      (∀ᵐ ω ∂P, ContinuousOn (fun s => r s ω) (Set.Ici 0) ∧
        ∀ t : ℝ≥0, r t ω = f 0 + (∫ u in (0 : ℝ)..t, (hwTheta a σ f u - a * r u ω))
          + σ * W t ω) →
      ∀ T : ℝ≥0, ∫ ω, exp (-∫ u in (0 : ℝ)..T, r u ω) ∂P = discount f T) ∧
    (∀ (θ' : ℝ → ℝ) (r' : ℝ → Ω → ℝ), Continuous θ' →
      (∀ᵐ ω ∂P, ContinuousOn (fun s => r' s ω) (Set.Ici 0) ∧
        ∀ t : ℝ≥0, r' t ω = f 0 + (∫ u in (0 : ℝ)..t, (θ' u - a * r' u ω)) + σ * W t ω) →
      (∀ T : ℝ≥0, ∫ ω, exp (-∫ u in (0 : ℝ)..T, r' u ω) ∂P = discount f T) →
      ∀ t : ℝ, 0 ≤ t → θ' t = hwTheta a σ f t) := by
  have hfd : Differentiable ℝ f := hf.differentiable one_ne_zero
  have hdc : Continuous (deriv f) := hf.continuous_deriv le_rfl
  have hfc : Continuous f := hfd.continuous
  have hθc : Continuous (hwTheta a σ f) := by unfold hwTheta; fun_prop
  have hlc : Continuous (hwLift a σ) := by unfold hwLift; fun_prop
  obtain ⟨hint, -, hderiv⟩ := hw_mean_path_and_drift (σ := σ) ha hfd
  set φ : ℝ → ℝ := fun s => f s + hwLift a σ s with hφdef
  have hφc : Continuous φ := hfc.add hlc
  have hφeq : ∀ t : ℝ, 0 ≤ t →
      φ t = (f 0 + ∫ x in (0 : ℝ)..t, hwTheta a σ f x) - a * ∫ u in (0 : ℝ)..t, φ u := by
    intro t _
    have hφd : ∀ x, HasDerivAt φ (hwTheta a σ f x - a * φ x) x := by
      intro x
      have hdiff : DifferentiableAt ℝ φ x :=
        (hfd x).add ((hw_lift_deriv a σ ha.ne' x).differentiableAt)
      have e := hdiff.hasDerivAt
      have hx := hderiv x
      rw [show deriv φ x = hwTheta a σ f x - a * φ x by simp only [hφdef] at hx ⊢; linarith] at e
      exact e
    have hftc := intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hφd x)
      ((hθc.sub (continuous_const.mul hφc)).intervalIntegrable 0 t)
    rw [intervalIntegral.integral_sub (f := hwTheta a σ f) (g := fun x => a * φ x)
      (hθc.intervalIntegrable _ _) ((continuous_const.mul hφc).intervalIntegrable _ _),
      intervalIntegral.integral_const_mul] at hftc
    have h0 : φ 0 = f 0 := by simp [hφdef, hwLift]
    linarith
  have hmθ : ∀ T : ℝ, 0 ≤ T →
      ∫ u in (0 : ℝ)..T, exp (-a * (T - u)) * (f 0 + ∫ x in (0 : ℝ)..u, hwTheta a σ f x)
        = (∫ u in (0 : ℝ)..T, f u) + hwV a σ T / 2 := by
    intro T hT
    rw [← hw_ode (h := fun t => f 0 + ∫ x in (0 : ℝ)..t, hwTheta a σ f x) hφc
      (continuous_const.add (hw_primitive_continuous hθc)) hφeq T hT, hφdef,
      intervalIntegral.integral_add (hfc.intervalIntegrable _ _) (hlc.intervalIntegrable _ _),
      hint]
  refine ⟨fun r hr T => ?_, fun θ' r' hθ' hr' hprice t ht => ?_⟩
  · rw [hw_price hW ha hθc r hr T T.2, hmθ T T.2, discount]
    congr 1
    ring
  · refine hw_conv_eq (a := a) (f0 := f 0) hθ' hθc (fun T hT => ?_) t ht
    have e := hprice T.toNNReal
    rw [Real.coe_toNNReal T hT] at e
    rw [hw_price hW ha hθ' r' hr' T hT, discount] at e
    have e' := Real.exp_injective e
    rw [hmθ T hT]
    linarith

/-- **The mean path and the drift read off it** (the card's Steps 3 and 4). Let `a > 0`, `σ` be
any noise size and `f` a forward curve with a slope at every date.

1. The lift adds up to half the variance: `∫₀ᵀ lift = V(T)/2` for every `T`.
2. A continuous expected path `φ` whose integral is the forward's plus half the variance,
   `∫₀ᵀ φ = ∫₀ᵀ f + V(T)/2` for every `T ≥ 0`, must be `φ(t) = f(0,t) + lift(t)` for `t ≥ 0`.
3. That path's drift, `φ' + aφ`, is the boxed formula `θ(t)` at every date. -/
theorem hull_white_mean_path_and_drift {a σ : ℝ} (ha : 0 < a) {f : ℝ → ℝ}
    (hf : Differentiable ℝ f) :
    (∀ T : ℝ, ∫ t in (0 : ℝ)..T, hwLift a σ t = hwV a σ T / 2) ∧
    (∀ φ : ℝ → ℝ, Continuous φ →
      (∀ T : ℝ, 0 ≤ T → ∫ t in (0 : ℝ)..T, φ t = (∫ t in (0 : ℝ)..T, f t) + hwV a σ T / 2) →
      ∀ t : ℝ, 0 ≤ t → φ t = f t + hwLift a σ t) ∧
    (∀ t : ℝ, deriv (fun s => f s + hwLift a σ s) t + a * (f t + hwLift a σ t)
      = hwTheta a σ f t) := by
  exact hw_mean_path_and_drift ha hf

/-- **The closed-form price returns the curve** (the card's Step 5 and its Detailed proof). With
`a > 0` and any forward curve `f`:

1. At `t = 0`, with the rate at the curve's front end `r = f(0,0)`, the closed-form price
   `P(0,T)` is today's `D(T)`, for every `T`.
2. The variance pieces behind the later-date formula combine as the card says:
   `½[V(T) - V(t) - V(T-t)] = B(t,T) lift(t) + σ²/(4a)(1 - e^(-2at)) B(t,T)²`, for every
   `t` and `T`. -/
theorem hull_white_closed_form_matches_curve {a σ : ℝ} (ha : 0 < a) (f : ℝ → ℝ) :
    (∀ T : ℝ, hwPrice a σ f 0 T (f 0) = discount f T) ∧
    (∀ t T : ℝ, (hwV a σ T - hwV a σ t - hwV a σ (T - t)) / 2
      = hwB a t T * hwLift a σ t + σ ^ 2 / (4 * a) * (1 - exp (-2 * a * t)) * hwB a t T ^ 2) := by
  have ha' : a ≠ 0 := ha.ne'
  refine ⟨fun T => ?_, fun t T => ?_⟩
  · simp [hwPrice, discount]
  · set u := exp (a * t) with hu
    set v := exp (a * T) with hv
    have upos : 0 < u := exp_pos _
    have vpos : 0 < v := exp_pos _
    have h1 : exp (-a * (T - t)) = u / v := by rw [hu, hv, ← Real.exp_sub]; congr 1; ring
    have h2 : exp (-a * T) = 1 / v := by rw [hv, one_div, ← Real.exp_neg]; congr 1; ring
    have h3 : exp (-2 * a * T) = 1 / v ^ 2 := by
      rw [hv, one_div, ← Real.exp_nat_mul, ← Real.exp_neg]; congr 1; push_cast; ring
    have h5 : exp (-2 * a * (T - t)) = u ^ 2 / v ^ 2 := by
      rw [hu, hv, ← Real.exp_nat_mul, ← Real.exp_nat_mul, ← Real.exp_sub]; congr 1; push_cast; ring
    have h6 : exp (-a * t) = 1 / u := by rw [hu, one_div, ← Real.exp_neg]; congr 1; ring
    have h7 : exp (-2 * a * t) = 1 / u ^ 2 := by
      rw [hu, one_div, ← Real.exp_nat_mul, ← Real.exp_neg]; congr 1; push_cast; ring
    simp only [hwV, hwB, hwLift, sub_zero]
    rw [h1, h2, h3, h5, h6, h7]
    field_simp
    ring

/-! The card's exact numbers, as fractions: `a = 3/10`, `σ = 1/100`, Vasicek's level `5/100`. -/

-- The first two rungs of the bootstrap ladder: D(0.5) = 1/(1 + 0.5 × 0.04) = 50/51 and
-- D(1) = 1/(1 + 1 × 0.042) = 500/521.
example : 1 / (1 + (1 / 2 : ℚ) * (4 / 100)) = 50 / 51 ∧
    1 / (1 + (1 : ℚ) * (42 / 1000)) = 500 / 521 := by
  norm_num

-- The noise term at 2.5 years: σ²/(2a) = 0.01²/0.6 = 1/6000, and the exponent 2at = 1.5.
example : ((1 : ℚ) / 100) ^ 2 / (2 * (3 / 10)) = 1 / 6000 ∧ 2 * (3 / 10 : ℚ) * (5 / 2) = 3 / 2 := by
  norm_num

-- Road 5: plain Vasicek's fixed push, a × level = 0.3 × 0.05 = 0.015.
example : (3 / 10 : ℚ) * (5 / 100) = 15 / 1000 := by
  norm_num

-- Step 4's bracket: with E = e^(-at), 2E + 1 - E = 1 + E and (1 - E)(1 + E) = 1 - E².
example (E : ℝ) : 2 * E + 1 - E = 1 + E ∧ (1 - E) * (1 + E) = 1 - E ^ 2 := by
  constructor <;> ring

#print axioms hull_white_drift_fits_curve_uniquely
#print axioms hull_white_mean_path_and_drift
#print axioms hull_white_closed_form_matches_curve

end HullWhiteModel
