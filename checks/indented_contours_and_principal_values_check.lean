-- Poles on the path: a shrinking arc round a simple pole picks up i times the angle it sweeps times the residue (so a half-circle dent keeps −iπ times it), the area under sin x/x is π, and the principal value of 1/(x(1 + x²)) is 0 although each side of the pole is infinite.
import Mathlib.Analysis.Analytic.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Sinc
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.ExpDecay

namespace IndentedContoursAndPrincipalValues

open Complex Filter Topology

open MeasureTheory in
lemma odd_f (x : ℝ) : 1 / ((-x) * (1 + (-x) ^ 2)) = -(1 / (x * (1 + x ^ 2))) := by
  rw [neg_sq, neg_mul, div_neg]

#print axioms odd_f

open MeasureTheory in
lemma left_eq (a b : ℝ) :
    (∫ x in -b..-a, 1 / (x * (1 + x ^ 2))) = -∫ x in a..b, 1 / (x * (1 + x ^ 2)) := by
  rw [← intervalIntegral.integral_comp_neg (fun x : ℝ => 1 / (x * (1 + x ^ 2)))]
  simp only [odd_f, intervalIntegral.integral_neg]

#print axioms left_eq

open MeasureTheory in
lemma G_eq (a : ℝ) (ha : 0 < a) :
    (∫ x in a..1, 1 / (x * (1 + x ^ 2))) =
      -(Real.log 2 / 2) - Real.log a + Real.log (1 + a ^ 2) / 2 := by
  have hpos : ∀ x ∈ Set.uIcc a 1, 0 < x := by
    intro x hx
    rcases Set.mem_uIcc.mp hx with h | h
    · linarith [h.1]
    · linarith [h.1]
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun x : ℝ => Real.log x - Real.log (1 + x ^ 2) / 2)]
  · norm_num
    ring
  · intro x hx
    have hx0 := hpos x hx
    have h1 : (1 + x ^ 2) ≠ 0 := by positivity
    have hd := ((Real.hasDerivAt_log hx0.ne').sub
      ((((hasDerivAt_pow 2 x).const_add 1).log h1).div_const 2))
    convert hd using 1
    field_simp
    ring
  · apply ContinuousOn.intervalIntegrable
    apply ContinuousOn.div continuousOn_const (by fun_prop)
    intro x hx
    have := hpos x hx
    positivity

#print axioms G_eq

open MeasureTheory in
lemma dir_inner_exp (x : ℝ) (hx : 0 < x) :
    (∫ t in Set.Ioi (0 : ℝ), Real.exp (-x * t)) = 1 / x := by
  rw [integral_exp_mul_Ioi (by linarith) 0]
  simp

#print axioms dir_inner_exp

open MeasureTheory in
lemma dir_inner_sin (R t : ℝ) :
    (∫ x in (0 : ℝ)..R, Real.sin x * Real.exp (-x * t)) =
      (1 - Real.exp (-R * t) * (t * Real.sin R + Real.cos R)) / (1 + t ^ 2) := by
  have ht : (1 + t ^ 2) ≠ 0 := by positivity
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun x : ℝ => -(Real.exp (-x * t) * (t * Real.sin x + Real.cos x)) / (1 + t ^ 2))]
  · simp only [neg_zero, zero_mul, Real.exp_zero, Real.sin_zero, Real.cos_zero, mul_zero,
      zero_add, one_mul]
    field_simp
    ring
  · intro x _
    have h1 := (((hasDerivAt_id' x).neg.mul_const t).exp)
    have h2 := ((Real.hasDerivAt_sin x).const_mul t).add (Real.hasDerivAt_cos x)
    have hd := ((h1.mul h2).neg).div_const (1 + t ^ 2)
    convert hd using 1
    simp only [Pi.neg_apply, Pi.add_apply]
    field_simp
    ring
  · exact (by fun_prop : Continuous fun x : ℝ => Real.sin x * Real.exp (-x * t)).intervalIntegrable _ _

#print axioms dir_inner_sin

open MeasureTheory in
lemma dir_integrable (R : ℝ) :
    Integrable (Function.uncurry fun x t : ℝ => Real.sin x * Real.exp (-x * t))
      ((volume.restrict (Set.Ioc (0 : ℝ) R)).prod (volume.restrict (Set.Ioi (0 : ℝ)))) := by
  have hc : Continuous (Function.uncurry fun x t : ℝ => Real.sin x * Real.exp (-x * t)) := by
    show Continuous (fun p : ℝ × ℝ => Real.sin p.1 * Real.exp (-p.1 * p.2))
    fun_prop
  refine (integrable_prod_iff hc.aestronglyMeasurable).mpr ⟨?_, ?_⟩
  · filter_upwards [ae_restrict_mem measurableSet_Ioc] with x hx
    exact (exp_neg_integrableOn_Ioi 0 hx.1).const_mul (Real.sin x)
  · have hint : Integrable (fun x : ℝ => |Real.sinc x|) (volume.restrict (Set.Ioc (0 : ℝ) R)) :=
      Continuous.integrableOn_Ioc (by fun_prop)
    refine hint.congr ?_
    filter_upwards [ae_restrict_mem measurableSet_Ioc] with x hx
    have hx0 : 0 < x := hx.1
    show |Real.sinc x| = ∫ t in Set.Ioi (0 : ℝ), ‖Real.sin x * Real.exp (-x * t)‖
    simp_rw [norm_mul, Real.norm_eq_abs, Real.abs_exp]
    rw [integral_const_mul, dir_inner_exp x hx0, Real.sinc_of_ne_zero hx0.ne', abs_div,
      abs_of_pos hx0]
    ring

#print axioms dir_integrable

open MeasureTheory in
lemma dir_bound (R t : ℝ) :
    ‖Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)‖ ≤ 2 * Real.exp (-R * t) := by
  have ht : 0 < 1 + t ^ 2 := by positivity
  have he := Real.exp_pos (-R * t)
  rw [Real.norm_eq_abs, abs_div, abs_mul, Real.abs_exp, abs_of_pos ht, div_le_iff₀ ht]
  have h1 : |t * Real.sin R + Real.cos R| ≤ |t| + 1 := by
    calc |t * Real.sin R + Real.cos R| ≤ |t * Real.sin R| + |Real.cos R| := abs_add_le _ _
      _ ≤ |t| * 1 + 1 := by
        rw [abs_mul]
        gcongr
        · exact Real.abs_sin_le_one R
        · exact Real.abs_cos_le_one R
      _ = |t| + 1 := by ring
  have h2 : |t| ≤ 1 + t ^ 2 := by nlinarith [abs_nonneg t, sq_abs t]
  calc Real.exp (-R * t) * |t * Real.sin R + Real.cos R|
      ≤ Real.exp (-R * t) * (2 * (1 + t ^ 2)) := by
        apply mul_le_mul_of_nonneg_left _ he.le
        nlinarith [sq_nonneg t]
    _ = 2 * Real.exp (-R * t) * (1 + t ^ 2) := by ring

#print axioms dir_bound

open MeasureTheory in
lemma dir_partial (R : ℝ) (hR : 0 < R) :
    (∫ x in (0 : ℝ)..R, Real.sinc x) = Real.pi / 2 -
      ∫ t in Set.Ioi (0 : ℝ), Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2) := by
  have hk : IntegrableOn (fun t : ℝ =>
      Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)) (Set.Ioi 0) := by
    refine Integrable.mono' ((exp_neg_integrableOn_Ioi 0 hR).const_mul 2) ?_
      (Eventually.of_forall fun t => dir_bound R t)
    exact (Continuous.div (by fun_prop) (by fun_prop) (fun t => by positivity) : Continuous fun t : ℝ =>
      Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)).aestronglyMeasurable
  rw [intervalIntegral.integral_of_le hR.le]
  calc (∫ x in Set.Ioc 0 R, Real.sinc x)
      = ∫ x in Set.Ioc 0 R, ∫ t in Set.Ioi (0 : ℝ), Real.sin x * Real.exp (-x * t) := by
        refine setIntegral_congr_fun measurableSet_Ioc (fun x hx => ?_)
        have hx0 : 0 < x := hx.1
        rw [integral_const_mul, dir_inner_exp x hx0, Real.sinc_of_ne_zero hx0.ne']
        ring
    _ = ∫ t in Set.Ioi (0 : ℝ), ∫ x in Set.Ioc 0 R, Real.sin x * Real.exp (-x * t) :=
        integral_integral_swap (dir_integrable R)
    _ = ∫ t in Set.Ioi (0 : ℝ), ((1 + t ^ 2)⁻¹ -
          Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)) := by
        refine integral_congr_ae (Eventually.of_forall fun t => ?_)
        simp only
        rw [← intervalIntegral.integral_of_le hR.le, dir_inner_sin]
        ring
    _ = Real.pi / 2 - ∫ t in Set.Ioi (0 : ℝ),
          Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2) := by
        rw [integral_sub integrable_inv_one_add_sq.integrableOn hk, integral_Ioi_inv_one_add_sq,
          Real.arctan_zero, sub_zero]

#print axioms dir_partial

open MeasureTheory in
lemma dir_half : Tendsto (fun R : ℝ => ∫ x in (0 : ℝ)..R, Real.sinc x) atTop
    (𝓝 (Real.pi / 2)) := by
  have hE : Tendsto (fun R : ℝ => ∫ t in Set.Ioi (0 : ℝ),
      Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)) atTop (𝓝 0) := by
    have h2 : Tendsto (fun R : ℝ => 2 * R⁻¹) atTop (𝓝 0) := by
      simpa using tendsto_inv_atTop_zero.const_mul (2 : ℝ)
    refine squeeze_zero_norm' ?_ h2
    filter_upwards [eventually_gt_atTop 0] with R hR
    calc _ ≤ ∫ t in Set.Ioi (0 : ℝ), 2 * Real.exp (-R * t) :=
          norm_integral_le_of_norm_le ((exp_neg_integrableOn_Ioi 0 hR).const_mul 2)
            (Eventually.of_forall fun t => dir_bound R t)
      _ = 2 * R⁻¹ := by rw [integral_const_mul, dir_inner_exp R hR, one_div]
  have := hE.const_sub (Real.pi / 2)
  rw [sub_zero] at this
  refine this.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with R hR
  rw [dir_partial R hR]

#print axioms dir_half

open MeasureTheory in
lemma dir_ae_ne : ∀ᵐ x : ℝ, x ≠ 0 := by
  rw [ae_iff]
  simp

#print axioms dir_ae_ne

open MeasureTheory in
lemma dir_split (a b : ℝ) : (∫ x in a..b, Real.sin x / x) =
    (∫ x in (0 : ℝ)..(-a), Real.sinc x) + ∫ x in (0 : ℝ)..b, Real.sinc x := by
  have h1 : (∫ x in a..b, Real.sin x / x) = ∫ x in a..b, Real.sinc x := by
    refine intervalIntegral.integral_congr_ae ?_
    filter_upwards [dir_ae_ne] with x hx _
    rw [Real.sinc_of_ne_zero hx]
  have h2 : (∫ x in (0 : ℝ)..(-a), Real.sinc x) = ∫ x in a..0, Real.sinc x := by
    have h := intervalIntegral.integral_comp_neg (a := a) (b := 0) (f := Real.sinc)
    simp only [Real.sinc_neg, neg_zero] at h
    exact h.symm
  rw [h1, h2, intervalIntegral.integral_add_adjacent_intervals
    (Real.continuous_sinc.intervalIntegrable _ _) (Real.continuous_sinc.intervalIntegrable _ _)]

#print axioms dir_split

/-- The card's main claim, the arc rule. Let f have a simple pole at a with residue c: near a
(but not at a) f(z) = c/(z − a) + g(z), where g is holomorphic at a. Let Γ_ε be the arc
z = a + εe^(it), t running from α to β, so dz = iεe^(it) dt. Then as the radius ε shrinks to 0
the integral of f along Γ_ε tends to i(β − α)c: i times the angle swept times the residue.
The upper dent runs from π to 0, so it keeps −iπ times the residue. -/
theorem arc_integral_tendsto_I_mul_angle_mul_residue
    (f g : ℂ → ℂ) (a c : ℂ) (α β : ℝ)
    (hg : AnalyticAt ℂ g a)
    (hf : ∀ᶠ z in 𝓝[≠] a, f z = c / (z - a) + g z) :
    Tendsto
      (fun ε : ℝ ↦ ∫ t in α..β,
        f (a + (ε : ℂ) * exp ((t : ℂ) * I)) * ((ε : ℂ) * I * exp ((t : ℂ) * I)))
      (𝓝[>] 0) (𝓝 (I * ((β : ℂ) - α) * c)) := by
  rw [eventually_nhdsWithin_iff, Metric.eventually_nhds_iff] at hf
  obtain ⟨r, hr, hfr⟩ := hf
  have hg2 : ∀ᶠ z in 𝓝 a, AnalyticAt ℂ g z ∧ dist (g z) (g a) < 1 :=
    hg.eventually_analyticAt.and
      (Metric.tendsto_nhds.mp hg.continuousAt 1 one_pos)
  obtain ⟨δ, hδ, hgδ⟩ := Metric.eventually_nhds_iff.mp hg2
  set M := ‖g a‖ + 1
  have hnorm : ∀ t : ℝ, ‖exp ((t : ℂ) * I)‖ = 1 := fun t => Complex.norm_exp_ofReal_mul_I t
  have hdist : ∀ (ε : ℝ) (t : ℝ), 0 < ε →
      dist (a + (ε : ℂ) * exp ((t : ℂ) * I)) a = ε := by
    intro ε t hε
    rw [dist_eq_norm, add_sub_cancel_left, norm_mul, hnorm, mul_one, Complex.norm_real,
      Real.norm_eq_abs, abs_of_pos hε]
  rw [tendsto_iff_norm_sub_tendsto_zero]
  have hbound : ∀ᶠ ε : ℝ in 𝓝[>] (0 : ℝ),
      ‖(∫ t in α..β,
        f (a + (ε : ℂ) * exp ((t : ℂ) * I)) * ((ε : ℂ) * I * exp ((t : ℂ) * I)))
        - I * ((β : ℂ) - α) * c‖ ≤ M * |β - α| * ε := by
    have hmem : Set.Ioo (0 : ℝ) (min r δ) ∈ 𝓝[>] (0 : ℝ) :=
      Ioo_mem_nhdsGT (lt_min hr hδ)
    filter_upwards [hmem] with ε hε
    obtain ⟨hε0, hε1⟩ := hε
    have hεr : ε < r := lt_of_lt_of_le hε1 (min_le_left _ _)
    have hεδ : ε < δ := lt_of_lt_of_le hε1 (min_le_right _ _)
    set z : ℝ → ℂ := fun t => a + (ε : ℂ) * exp ((t : ℂ) * I) with hz
    have hzd : ∀ t, dist (z t) a = ε := fun t => hdist ε t hε0
    have hεC : (ε : ℂ) ≠ 0 := by exact_mod_cast hε0.ne'
    have hpt : ∀ t : ℝ, f (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I)) =
        c * I + g (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I)) := by
      intro t
      have hne : z t ≠ a := by
        intro h
        have := hzd t
        rw [h, dist_self] at this
        linarith
      rw [hfr (by rw [hzd t]; exact hεr) hne]
      have hsub : z t - a = (ε : ℂ) * exp ((t : ℂ) * I) := by simp [hz]
      rw [hsub]
      have he : exp ((t : ℂ) * I) ≠ 0 := Complex.exp_ne_zero _
      field_simp
    have hcont : Continuous (fun t : ℝ => g (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I))) := by
      refine Continuous.mul ?_ (by fun_prop)
      rw [continuous_iff_continuousAt]
      intro t
      have hzc : Continuous z := by fun_prop
      exact ((hgδ (by rw [hzd t]; exact hεδ)).1.continuousAt).comp hzc.continuousAt
    rw [intervalIntegral.integral_congr (g := fun t : ℝ =>
        c * I + g (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I))) (fun t _ => hpt t)]
    rw [intervalIntegral.integral_add intervalIntegrable_const (hcont.intervalIntegrable _ _),
      intervalIntegral.integral_const, Complex.real_smul]
    have hrw : ((β - α : ℝ) : ℂ) * (c * I) +
        (∫ t in α..β, g (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I))) - I * ((β : ℂ) - α) * c
        = ∫ t in α..β, g (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I)) := by
      push_cast; ring
    rw [hrw]
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := α) (b := β) (C := M * ε)
      (f := fun t : ℝ => g (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I))) (by
        intro t _
        rw [norm_mul, norm_mul, norm_mul, hnorm, Complex.norm_I, Complex.norm_real,
          Real.norm_eq_abs, abs_of_pos hε0, mul_one, mul_one]
        refine mul_le_mul_of_nonneg_right ?_ hε0.le
        have h1 := (hgδ (by rw [hzd t]; exact hεδ)).2
        rw [dist_eq_norm] at h1
        have h2 := norm_le_norm_add_norm_sub' (g (z t)) (g a)
        simp only [M]
        linarith)
    calc _ ≤ M * ε * |β - α| := this
      _ = M * |β - α| * ε := by ring
  refine squeeze_zero' (Eventually.of_forall fun _ => norm_nonneg _) hbound ?_
  have : Tendsto (fun ε : ℝ => M * |β - α| * ε) (𝓝 0) (𝓝 (M * |β - α| * 0)) :=
    (continuous_const.mul continuous_id).tendsto 0
  rw [mul_zero] at this
  exact this.mono_left nhdsWithin_le_nhds

/-- The shutter's area. The integral of sin x/x from A to B tends to π as A runs to −∞ and B
runs to +∞, each end on its own: the area under sin x/x over the whole line is π. -/
theorem integral_sin_div_self_tendsto_pi :
    Tendsto (fun p : ℝ × ℝ ↦ ∫ x in p.1..p.2, Real.sin x / x) (atBot ×ˢ atTop)
      (𝓝 Real.pi) := by
  simp_rw [dir_split]
  have := (dir_half.comp (tendsto_neg_atBot_atTop.comp tendsto_fst)).add
    (dir_half.comp (tendsto_snd (f := (atBot : Filter ℝ)) (g := (atTop : Filter ℝ))))
  rw [add_halves] at this
  exact this

/-- The second example, f(x) = 1/(x(1 + x²)), with its pole at 0 on the path.
1. The principal value is 0: cut equal gaps (−ε, ε) round 0, integrate from −R to −ε and from
   ε to R, and the sum tends to 0 as ε shrinks to 0 and R grows.
2. The right piece, from ε to 1, grows without bound as ε shrinks to 0.
3. The left piece, from −1 to −ε, falls without bound as ε shrinks to 0. So the ordinary integral
   does not exist.
4. Unequal gaps give a different answer: a left gap 2ε and a right gap ε give ln 2, not 0. -/
theorem principal_value_inv_mul_one_add_sq_eq_zero :
    Tendsto (fun p : ℝ × ℝ ↦
        (∫ x in -p.2..-p.1, 1 / (x * (1 + x ^ 2))) + ∫ x in p.1..p.2, 1 / (x * (1 + x ^ 2)))
      (𝓝[>] 0 ×ˢ atTop) (𝓝 0) ∧
    Tendsto (fun ε : ℝ ↦ ∫ x in ε..1, 1 / (x * (1 + x ^ 2))) (𝓝[>] 0) atTop ∧
    Tendsto (fun ε : ℝ ↦ ∫ x in (-1)..-ε, 1 / (x * (1 + x ^ 2))) (𝓝[>] 0) atBot ∧
    Tendsto (fun ε : ℝ ↦
        (∫ x in (-1)..-(2 * ε), 1 / (x * (1 + x ^ 2))) + ∫ x in ε..1, 1 / (x * (1 + x ^ 2)))
      (𝓝[>] 0) (𝓝 (Real.log 2)) := by
  have h2 : Tendsto (fun ε : ℝ ↦ ∫ x in ε..1, 1 / (x * (1 + x ^ 2))) (𝓝[>] 0) atTop := by
    have hlim : Tendsto (fun ε : ℝ ↦ -(Real.log 2 / 2) + -Real.log ε) (𝓝[>] 0) atTop :=
      tendsto_atTop_add_const_left _ _ (tendsto_neg_atBot_atTop.comp Real.tendsto_log_nhdsGT_zero)
    refine tendsto_atTop_mono' _ ?_ hlim
    filter_upwards [self_mem_nhdsWithin] with ε hε
    rw [G_eq ε hε]
    have : 0 ≤ Real.log (1 + ε ^ 2) := Real.log_nonneg (by nlinarith)
    linarith
  refine ⟨?_, h2, ?_, ?_⟩
  · have : (fun p : ℝ × ℝ ↦
        (∫ x in -p.2..-p.1, 1 / (x * (1 + x ^ 2))) + ∫ x in p.1..p.2, 1 / (x * (1 + x ^ 2)))
        = fun _ => 0 := by
      funext p
      rw [left_eq]
      ring
    rw [this]
    exact tendsto_const_nhds
  · have : (fun ε : ℝ ↦ ∫ x in (-1)..-ε, 1 / (x * (1 + x ^ 2)))
        = fun ε => -∫ x in ε..1, 1 / (x * (1 + x ^ 2)) := by
      funext ε
      exact left_eq ε 1
    rw [this]
    exact tendsto_neg_atTop_atBot.comp h2
  · have hc : Continuous (fun ε : ℝ =>
        Real.log 2 + (Real.log (1 + ε ^ 2) - Real.log (1 + (2 * ε) ^ 2)) / 2) := by
      have h1 : Continuous (fun ε : ℝ => Real.log (1 + ε ^ 2)) :=
        Continuous.log (by fun_prop) (fun x => by positivity)
      have h2 : Continuous (fun ε : ℝ => Real.log (1 + (2 * ε) ^ 2)) :=
        Continuous.log (by fun_prop) (fun x => by positivity)
      fun_prop
    have hl := (hc.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
    simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, add_zero, Real.log_one,
      mul_zero, sub_self, zero_div] at hl
    refine hl.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with ε hε
    have hε' : (0 : ℝ) < ε := hε
    rw [left_eq, G_eq ε hε', G_eq (2 * ε) (by linarith), Real.log_mul (by norm_num) hε'.ne']
    ring

/-- Residue of 1/(z(1 + z²)) at i: 1/(i · 2i) = −1/2. -/
example : (1 : ℂ) / (I * (2 * I)) = -1 / 2 := by
  rw [show I * (2 * I) = 2 * (I * I) by ring, I_mul_I]; norm_num

/-- The loop is 2πi × (−1/2) = −iπ; take away the dent's −iπ × 1 and the principal value is 0. -/
example : 2 * (Real.pi : ℂ) * I * (-1 / 2) - (-(I * Real.pi) * 1) = 0 := by ring

/-- F(x) = ln|x| − ½ ln(1 + x²) has derivative 1/x − x/(1 + x²), which is 1/(x(1 + x²)). -/
example (x : ℝ) (hx : x ≠ 0) : 1 / x - x / (1 + x ^ 2) = 1 / (x * (1 + x ^ 2)) := by
  have h : (1 + x ^ 2) ≠ 0 := by positivity
  field_simp; ring

/-- The double-pole dent for 1/z² is −2/ε: at ε = 1/100 it is −200. -/
example : (-2 : ℝ) / (1 / 100) = -200 := by norm_num

#print axioms arc_integral_tendsto_I_mul_angle_mul_residue
#print axioms integral_sin_div_self_tendsto_pi
#print axioms principal_value_inv_mul_one_add_sq_eq_zero

end IndentedContoursAndPrincipalValues
