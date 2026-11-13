-- Fokker-Planck: a smooth density whose payoff averages change at the rate of the generator obeys the forward equation p_t = -(mu p)' + (1/2)(sigma^2 p)'', the speck's bell obeys the heat equation p_t = (1/2) p_yy, and the mean-reverting rate's sliding bell obeys its forward equation.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Distribution.AEEqOfIntegralContDiff
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.Calculus.ParametricIntegral
import Mathlib.Analysis.Calculus.Deriv.Support
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith

open MeasureTheory Real
open scoped ContDiff

/-- Space derivative of a Gaussian bell with mean `a` and variance `v`. -/
theorem fp_bell_hasDerivAt_space (a v : ℝ) (hv : v ≠ 0) (z : ℝ) :
    HasDerivAt (fun z => Real.exp (-(z - a) ^ 2 / (2 * v)) / Real.sqrt (2 * π * v))
      (-(z - a) / v * (Real.exp (-(z - a) ^ 2 / (2 * v)) / Real.sqrt (2 * π * v))) z := by
  have h1 : HasDerivAt (fun z => -(z - a) ^ 2 / (2 * v)) (-(2 * (z - a) ^ 1 * 1) / (2 * v)) z :=
    (((hasDerivAt_id z).sub_const a).pow 2).neg.div_const (2 * v)
  have h2 := (h1.exp).div_const (Real.sqrt (2 * π * v))
  convert h2 using 1
  field_simp

#print axioms fp_bell_hasDerivAt_space

/-- Second space derivative of a Gaussian bell. -/
theorem fp_bell_hasDerivAt_space2 (a v : ℝ) (hv : v ≠ 0) (z : ℝ) :
    HasDerivAt (fun z => -(z - a) / v * (Real.exp (-(z - a) ^ 2 / (2 * v)) / Real.sqrt (2 * π * v)))
      (((z - a) ^ 2 / v ^ 2 - 1 / v) *
        (Real.exp (-(z - a) ^ 2 / (2 * v)) / Real.sqrt (2 * π * v))) z := by
  have h1 : HasDerivAt (fun z => -(z - a) / v) (-(1 : ℝ) / v) z :=
    ((hasDerivAt_id z).sub_const a).neg.div_const v
  have h2 := h1.mul (fp_bell_hasDerivAt_space a v hv z)
  convert h2 using 1
  field_simp
  ring

#print axioms fp_bell_hasDerivAt_space2

/-- Time derivative of a Gaussian bell whose mean and variance move. -/
theorem fp_bell_hasDerivAt_time (m v : ℝ → ℝ) (m' v' y t : ℝ) (hm : HasDerivAt m m' t)
    (hv : HasDerivAt v v' t) (hpos : 0 < v t) :
    HasDerivAt (fun s => Real.exp (-(y - m s) ^ 2 / (2 * v s)) / Real.sqrt (2 * π * v s))
      (Real.exp (-(y - m t) ^ 2 / (2 * v t)) / Real.sqrt (2 * π * v t) *
        ((y - m t) * m' / v t + (y - m t) ^ 2 * v' / (2 * v t ^ 2) - v' / (2 * v t))) t := by
  have hv0 : v t ≠ 0 := hpos.ne'
  have hw : 0 < 2 * π * v t := by positivity
  have h1 := ((((hasDerivAt_const t y).sub hm).pow 2).neg.div (hv.const_mul 2)
    (by positivity)).exp
  have h2 := (hv.const_mul (2 * π)).sqrt hw.ne'
  have h3 := h1.div h2 (Real.sqrt_pos.2 hw).ne'
  convert h3 using 1
  have hS := Real.sq_sqrt hw.le
  have hSp := Real.sqrt_pos.2 hw
  set S := Real.sqrt (2 * π * v t)
  simp only [Pi.sub_apply, Pi.pow_apply, Pi.neg_apply, Pi.div_apply]
  field_simp
  rw [hS]
  push_cast
  ring

#print axioms fp_bell_hasDerivAt_time

/-- The forward equation (Steps 2 and 3 of the card). Let the drift mu and the noise size sigma be
smooth functions of position, and let p t y, the density of X t at y, be smooth in both variables
for t > 0. Step 1 (Ito's lemma, not in Mathlib, so given here as the hypothesis `hgen`) says that
for every smooth payoff f that is zero outside a bounded interval, the average
∫ f(y) p(t, y) dy changes in time at the rate ∫ (L f)(y) p(t, y) dy, where
L f = mu f' + (1/2) sigma^2 f'' is the generator. Then at every time t > 0 and every point y the
density obeys the Fokker-Planck equation
  p_t = -(mu p)_y + (1/2) (sigma^2 p)_yy,
that is, p_t = L* p, the generator's adjoint applied to the density. -/
theorem fokker_planck_forward_equation (μ σ : ℝ → ℝ) (p : ℝ → ℝ → ℝ)
    (hμ : ContDiff ℝ ∞ μ) (hσ : ContDiff ℝ ∞ σ)
    (hp : ContDiffOn ℝ ∞ (Function.uncurry p) (Set.Ioi (0 : ℝ) ×ˢ Set.univ))
    (hgen : ∀ t : ℝ, 0 < t → ∀ f : ℝ → ℝ, ContDiff ℝ ∞ f → HasCompactSupport f →
      HasDerivAt (fun s => ∫ y, f y * p s y)
        (∫ y, (μ y * deriv f y + 1 / 2 * σ y ^ 2 * deriv (deriv f) y) * p t y) t) :
    ∀ t : ℝ, 0 < t → ∀ y : ℝ,
      deriv (fun s => p s y) t =
        -deriv (fun z => μ z * p t z) y + 1 / 2 * deriv (deriv (fun z => σ z ^ 2 * p t z)) y := by
  intro t ht
  set U : Set (ℝ × ℝ) := Set.Ioi (0 : ℝ) ×ˢ Set.univ with hUdef
  have hUo : IsOpen U := isOpen_Ioi.prod isOpen_univ
  have hmemU : ∀ s y : ℝ, 0 < s → (s, y) ∈ U := fun s y hs => ⟨hs, Set.mem_univ _⟩
  -- the time derivative of p
  set D : ℝ × ℝ → ℝ := fun x => fderiv ℝ (Function.uncurry p) x (1, 0) with hDdef
  have hDc : ContinuousOn D U :=
    (hp.continuousOn_fderiv_of_isOpen hUo (by simp)).clm_apply continuousOn_const
  have hasD : ∀ s y : ℝ, 0 < s → HasDerivAt (fun s => p s y) (D (s, y)) s := by
    intro s y hs
    have h1 : HasFDerivAt (Function.uncurry p) (fderiv ℝ (Function.uncurry p) (s, y)) (s, y) :=
      ((hp.contDiffAt (hUo.mem_nhds (hmemU s y hs))).differentiableAt (by simp)).hasFDerivAt
    have h2 : HasDerivAt (fun s : ℝ => (s, y)) ((1 : ℝ), (0 : ℝ)) s :=
      (hasDerivAt_id s).prodMk (hasDerivAt_const s y)
    exact h1.comp_hasDerivAt s h2
  -- p s is smooth in space
  have hq : ∀ s : ℝ, 0 < s → ContDiff ℝ ∞ (p s) := by
    intro s hs
    refine contDiff_iff_contDiffAt.2 fun z => ?_
    have h1 := hp.contDiffAt (hUo.mem_nhds (hmemU s z hs))
    have h2 : ContDiffAt ℝ ∞ (fun z : ℝ => (s, z)) z := contDiffAt_const.prodMk contDiffAt_id
    exact h1.comp z h2
  set q := p t with hqdef
  have hqs : ContDiff ℝ ∞ q := hq t ht
  have hA : ContDiff ℝ ∞ (fun z => μ z * q z) := hμ.mul hqs
  have hB : ContDiff ℝ ∞ (fun z => σ z ^ 2 * q z) := (hσ.pow 2).mul hqs
  have hB' : ContDiff ℝ ∞ (deriv (fun z => σ z ^ 2 * q z)) := (contDiff_infty_iff_deriv.1 hB).2
  have hB'' : ContDiff ℝ ∞ (deriv (deriv (fun z => σ z ^ 2 * q z))) :=
    (contDiff_infty_iff_deriv.1 hB').2
  have hA' : ContDiff ℝ ∞ (deriv (fun z => μ z * q z)) := (contDiff_infty_iff_deriv.1 hA).2
  have hDt : Continuous (fun y => D (t, y)) :=
    hDc.comp_continuous (continuous_const.prodMk continuous_id) (fun y => hmemU t y ht)
  set g : ℝ → ℝ := fun y => D (t, y) -
    (-deriv (fun z => μ z * q z) y + 1 / 2 * deriv (deriv (fun z => σ z ^ 2 * q z)) y) with hgdef
  have hgc : Continuous g := hDt.sub (hA'.continuous.neg.add (continuous_const.mul hB''.continuous))
  -- the key identity: g integrates to zero against every test function
  have key : ∀ f : ℝ → ℝ, ContDiff ℝ ∞ f → HasCompactSupport f → ∫ y, f y • g y = 0 := by
    intro f hf hfs
    have hf' : ContDiff ℝ ∞ (deriv f) := (contDiff_infty_iff_deriv.1 hf).2
    have hf'' : ContDiff ℝ ∞ (deriv (deriv f)) := (contDiff_infty_iff_deriv.1 hf').2
    have hfs' : HasCompactSupport (deriv f) := hfs.deriv
    have hfs'' : HasCompactSupport (deriv (deriv f)) := hfs'.deriv
    have hint : ∀ (u h : ℝ → ℝ), Continuous u → HasCompactSupport u → Continuous h →
        Integrable (fun y => u y * h y) := fun u h hu hus hh =>
      (hu.mul hh).integrable_of_hasCompactSupport (hus.mul_right (f' := h))
    -- differentiate under the integral sign
    have hball : Metric.closedBall t (t / 2) ⊆ Set.Ioi 0 := by
      intro s hs
      rw [Metric.mem_closedBall, Real.dist_eq, abs_le] at hs
      show 0 < s
      linarith [hs.1]
    have hKc : IsCompact (Metric.closedBall t (t / 2) ×ˢ tsupport f) :=
      (isCompact_closedBall t (t / 2)).prod hfs
    obtain ⟨C, hC⟩ := hKc.exists_bound_of_continuousOn
      (f := fun x : ℝ × ℝ => f x.2 * D x)
      ((hf.continuous.comp continuous_snd).continuousOn.mul
        (hDc.mono (fun x hx => hmemU x.1 x.2 (hball hx.1))))
    have hderiv := hasDerivAt_integral_of_dominated_loc_of_deriv_le
      (μ := volume) (F := fun s y => f y * p s y) (F' := fun s y => f y * D (s, y))
      (x₀ := t) (bound := (tsupport f).indicator (fun _ => C))
      (Metric.closedBall_mem_nhds t (by linarith))
      (by
        filter_upwards [Ioi_mem_nhds ht] with s hs
        exact (hf.continuous.mul (hq s hs).continuous).aestronglyMeasurable)
      (hint f (p t) hf.continuous hfs (hq t ht).continuous)
      ((hf.continuous.mul hDt).aestronglyMeasurable)
      (by
        refine Filter.Eventually.of_forall fun y s hs => ?_
        by_cases hy : y ∈ tsupport f
        · rw [Set.indicator_of_mem hy]
          exact hC (s, y) ⟨hs, hy⟩
        · rw [Set.indicator_of_notMem hy, image_eq_zero_of_notMem_tsupport hy]
          simp)
      ((integrable_indicator_iff (isClosed_tsupport f).measurableSet).2
        (integrableOn_const hfs.measure_lt_top.ne))
      (Filter.Eventually.of_forall fun y s hs => (hasD s y (hball hs)).const_mul (f y))
    have hI1 : ∫ y, f y * D (t, y) =
        ∫ y, (μ y * deriv f y + 1 / 2 * σ y ^ 2 * deriv (deriv f) y) * p t y :=
      hderiv.2.unique (hgen t ht f hf hfs)
    -- split the generator side
    have hI2 : ∫ y, (μ y * deriv f y + 1 / 2 * σ y ^ 2 * deriv (deriv f) y) * p t y =
        (∫ y, deriv f y * (μ y * q y)) + 1 / 2 * ∫ y, deriv (deriv f) y * (σ y ^ 2 * q y) := by
      rw [← integral_const_mul, ← integral_add]
      · refine integral_congr_ae (Filter.Eventually.of_forall fun y => ?_)
        simp only [hqdef]
        ring
      · exact hint _ _ hf'.continuous hfs' hA.continuous
      · exact (hint _ _ hf''.continuous hfs'' hB.continuous).const_mul _
    -- integrate by parts
    have hP1 : ∫ y, f y * deriv (fun z => μ z * q z) y = -∫ y, deriv f y * (μ y * q y) :=
      integral_mul_deriv_eq_deriv_mul_of_integrable
        (fun x _ => (hf.differentiable (by simp) x).hasDerivAt)
        (fun x _ => (hA.differentiable (by simp) x).hasDerivAt)
        (hint _ _ hf.continuous hfs hA'.continuous)
        (hint _ _ hf'.continuous hfs' hA.continuous)
        (hint _ _ hf.continuous hfs hA.continuous)
    have hP2 : ∫ y, f y * deriv (deriv (fun z => σ z ^ 2 * q z)) y =
        -∫ y, deriv f y * deriv (fun z => σ z ^ 2 * q z) y :=
      integral_mul_deriv_eq_deriv_mul_of_integrable
        (fun x _ => (hf.differentiable (by simp) x).hasDerivAt)
        (fun x _ => (hB'.differentiable (by simp) x).hasDerivAt)
        (hint _ _ hf.continuous hfs hB''.continuous)
        (hint _ _ hf'.continuous hfs' hB'.continuous)
        (hint _ _ hf.continuous hfs hB'.continuous)
    have hP3 : ∫ y, deriv f y * deriv (fun z => σ z ^ 2 * q z) y =
        -∫ y, deriv (deriv f) y * (σ y ^ 2 * q y) :=
      integral_mul_deriv_eq_deriv_mul_of_integrable
        (fun x _ => (hf'.differentiable (by simp) x).hasDerivAt)
        (fun x _ => (hB.differentiable (by simp) x).hasDerivAt)
        (hint _ _ hf'.continuous hfs' hB'.continuous)
        (hint _ _ hf''.continuous hfs'' hB.continuous)
        (hint _ _ hf'.continuous hfs' hB.continuous)
    -- assemble
    have hsplit : ∫ y, f y • g y = (∫ y, f y * D (t, y)) + (∫ y, f y * deriv (fun z => μ z * q z) y)
        - 1 / 2 * ∫ y, f y * deriv (deriv (fun z => σ z ^ 2 * q z)) y := by
      rw [← integral_const_mul, ← integral_add, ← integral_sub]
      · refine integral_congr_ae (Filter.Eventually.of_forall fun y => ?_)
        simp only [hgdef, smul_eq_mul]
        ring
      · exact (hint _ _ hf.continuous hfs hDt).add (hint _ _ hf.continuous hfs hA'.continuous)
      · exact (hint _ _ hf.continuous hfs hB''.continuous).const_mul _
      · exact hint _ _ hf.continuous hfs hDt
      · exact hint _ _ hf.continuous hfs hA'.continuous
    rw [hsplit, hI1, hI2, hP1, hP2, hP3]
    ring
  have hae : ∀ᵐ y ∂(volume : Measure ℝ), g y = 0 :=
    ae_eq_zero_of_integral_contDiff_smul_eq_zero hgc.locallyIntegrable key
  have hg0 : g = 0 := (hgc.ae_eq_iff_eq volume continuous_const).1 hae
  intro y
  have hy := congrFun hg0 y
  simp only [hgdef, Pi.zero_apply] at hy
  rw [(hasD t y ht).deriv]
  linarith

/-- The speck (Step 4). With no drift and noise size 1, the bell grown from a point,
p(t, y) = exp(-y^2 / (2 t)) / sqrt(2 pi t), obeys the heat equation p_t = (1/2) p_yy at every
time t > 0 and every point y. -/
theorem speck_density_solves_heat_equation (t y : ℝ) (ht : 0 < t) :
    deriv (fun s => Real.exp (-y ^ 2 / (2 * s)) / Real.sqrt (2 * π * s)) t =
      1 / 2 * deriv (deriv (fun z => Real.exp (-z ^ 2 / (2 * t)) / Real.sqrt (2 * π * t))) y := by
  have hT := fp_bell_hasDerivAt_time (fun _ => 0) (fun s => s) 0 1 y t (hasDerivAt_const t 0)
    (hasDerivAt_id' t) ht
  simp only [sub_zero] at hT
  have hfun : (fun z => Real.exp (-z ^ 2 / (2 * t)) / Real.sqrt (2 * π * t)) =
      fun z => Real.exp (-(z - 0) ^ 2 / (2 * t)) / Real.sqrt (2 * π * t) := by
    simp
  have hD : deriv (fun z => Real.exp (-(z - 0) ^ 2 / (2 * t)) / Real.sqrt (2 * π * t)) =
      fun z => -(z - 0) / t * (Real.exp (-(z - 0) ^ 2 / (2 * t)) / Real.sqrt (2 * π * t)) :=
    funext fun z => (fp_bell_hasDerivAt_space 0 t ht.ne' z).deriv
  rw [hT.deriv, hfun, hD, (fp_bell_hasDerivAt_space2 0 t ht.ne' y).deriv]
  have := ht.ne'
  simp only [sub_zero]
  field_simp
  ring


/-- The rate (Step 5). For the mean-reverting rate with pull speed kappa > 0, long-run level theta,
constant noise size sigma ≠ 0 and start x, the bell with mean m(t) = theta + (x - theta) e^(-kappa t)
and variance v(t) = sigma^2 / (2 kappa) (1 - e^(-2 kappa t)) obeys the forward equation
p_t = -(kappa (theta - y) p)_y + (1/2) sigma^2 p_yy at every time t > 0 and every point y:
the bell slides toward theta while it widens. -/
theorem mean_reverting_bell_solves_forward_equation (κ θ σ x : ℝ) (hκ : 0 < κ) (hσ : σ ≠ 0)
    (t y : ℝ) (ht : 0 < t) :
    let m : ℝ → ℝ := fun s => θ + (x - θ) * Real.exp (-κ * s)
    let v : ℝ → ℝ := fun s => σ ^ 2 / (2 * κ) * (1 - Real.exp (-2 * κ * s))
    let p : ℝ → ℝ → ℝ := fun s z => Real.exp (-(z - m s) ^ 2 / (2 * v s)) / Real.sqrt (2 * π * v s)
    deriv (fun s => p s y) t =
      -deriv (fun z => κ * (θ - z) * p t z) y + 1 / 2 * deriv (deriv (fun z => σ ^ 2 * p t z)) y := by
  intro m v p
  have hvt : 0 < v t := by
    have h1 : Real.exp (-2 * κ * t) < 1 := Real.exp_lt_one_iff.2 (by nlinarith)
    have h2 : 0 < σ ^ 2 / (2 * κ) := by positivity
    exact mul_pos h2 (by linarith)
  have hv0 : v t ≠ 0 := hvt.ne'
  have hm' : HasDerivAt m (κ * (θ - m t)) t := by
    have h := ((((hasDerivAt_id t).const_mul (-κ)).exp).const_mul (x - θ)).const_add θ
    refine h.congr_deriv ?_
    have hmt : m t = θ + (x - θ) * Real.exp (-κ * t) := rfl
    rw [hmt]
    simp only [id]
    ring
  have hv' : HasDerivAt v (σ ^ 2 - 2 * κ * v t) t := by
    have h := ((((hasDerivAt_id t).const_mul (-2 * κ)).exp).const_sub 1).const_mul (σ ^ 2 / (2 * κ))
    refine h.congr_deriv ?_
    have hvt' : v t = σ ^ 2 / (2 * κ) * (1 - Real.exp (-2 * κ * t)) := rfl
    rw [hvt']
    simp only [id]
    field_simp
    ring
  have hT := fp_bell_hasDerivAt_time m v _ _ y t hm' hv' hvt
  have e1 : deriv (fun s => p s y) t = _ := hT.deriv
  have hS1 := fp_bell_hasDerivAt_space (m t) (v t) hv0
  have hS2 := fp_bell_hasDerivAt_space2 (m t) (v t) hv0
  have e2 : deriv (fun z => κ * (θ - z) * p t z) y =
      κ * (0 - 1) * p t y + κ * (θ - y) * (-(y - m t) / v t * p t y) :=
    (((hasDerivAt_const y θ).sub (hasDerivAt_id y)).const_mul κ).mul (hS1 y) |>.deriv
  have e3 : deriv (fun z => σ ^ 2 * p t z) =
      fun z => σ ^ 2 * (-(z - m t) / v t *
        (Real.exp (-(z - m t) ^ 2 / (2 * v t)) / Real.sqrt (2 * π * v t))) :=
    funext fun z => ((hS1 z).const_mul (σ ^ 2)).deriv
  have e4 := ((hS2 y).const_mul (σ ^ 2)).deriv
  rw [e1, e2, e3, e4]
  simp only [p]
  field_simp
  ring


/-! ### The card's worked numbers (exact parts only) -/

-- The worked table's adjoint identity with kappa = 1/2, theta = 4, sigma = 2 and f(y) = y^2:
-- for any mean m and variance v, the forward side v' + 2 m m', with m' = kappa (theta - m) and
-- v' = sigma^2 - 2 kappa v, equals the backward side 2 kappa theta m - 2 kappa (v + m^2) + sigma^2.
example (m v : ℝ) :
    (2 ^ 2 - 2 * (1 / 2) * v) + 2 * m * ((1 / 2) * (4 - m)) =
      2 * (1 / 2) * 4 * m - 2 * (1 / 2) * (v + m ^ 2) + 2 ^ 2 := by
  ring
-- The generator on f(y) = y^2 with these numbers: L f(y) = 2 kappa (theta - y) y + sigma^2.
example (y : ℝ) : (1 / 2) * (4 - y) * (2 * y) + 1 / 2 * 2 ^ 2 * 2 = 2 * (1 / 2) * (4 - y) * y + 2 ^ 2 := by
  ring
-- "Here 2 kappa = 1": with kappa = 1/2.
example : (2 : ℚ) * (1 / 2) = 1 := by norm_num
-- The long-run variance sigma^2 / (2 kappa) = 4, standard deviation 2 points (2^2 = 4).
example : (2 : ℚ) ^ 2 / (2 * (1 / 2)) = 4 ∧ (2 : ℚ) ^ 2 = 4 := by norm_num

#print axioms fokker_planck_forward_equation
#print axioms speck_density_solves_heat_equation
#print axioms mean_reverting_bell_solves_forward_equation
