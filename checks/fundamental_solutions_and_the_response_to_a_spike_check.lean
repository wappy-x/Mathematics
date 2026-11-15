-- Fundamental solution: the rail's dip G solves EI G'''' + k G = δ as distributions, its convolution with any integrable or bounded load solves EI w'''' + k w = q, and k times the area under G is 1.
import Mathlib.Analysis.Convolution
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.MeasureTheory.Measure.Lebesgue.Integral
import Mathlib.MeasureTheory.Integral.ExpDecay

open MeasureTheory Real
open scoped Convolution ContDiff

/-- The rail's decay rate β = (k / (4 EI))^(1/4), per metre. -/
noncomputable def railBeta (EI k : ℝ) : ℝ := (k / (4 * EI)) ^ ((1 : ℝ) / 4)

/-- The rail's dip from a unit spike at 0:
G(x) = β/(2k) · e^(−β|x|) · (cos β|x| + sin β|x|). -/
noncomputable def railG (EI k : ℝ) (x : ℝ) : ℝ :=
  railBeta EI k / (2 * k) * Real.exp (-(railBeta EI k * |x|)) *
    (Real.cos (railBeta EI k * |x|) + Real.sin (railBeta EI k * |x|))

/-- The rail's operator L applied to a probe: (Lφ)(x) = EI φ''''(x) + k φ(x). -/
noncomputable def railL (EI k : ℝ) (φ : ℝ → ℝ) (x : ℝ) : ℝ :=
  EI * iteratedDeriv 4 φ x + k * φ x

open Set Filter Topology in
lemma rail_aux_derivs (b x : ℝ) :
    HasDerivAt (fun x => exp (-(b*x)) * (cos (b*x) + sin (b*x)))
      (-2*b*(exp (-(b*x))*sin (b*x))) x ∧
    HasDerivAt (fun x => -2*b*(exp (-(b*x))*sin (b*x)))
      (2*b^2*(exp (-(b*x))*(sin (b*x) - cos (b*x)))) x ∧
    HasDerivAt (fun x => 2*b^2*(exp (-(b*x))*(sin (b*x) - cos (b*x))))
      (4*b^3*(exp (-(b*x))*cos (b*x))) x ∧
    HasDerivAt (fun x => 4*b^3*(exp (-(b*x))*cos (b*x)))
      (-4*b^4*(exp (-(b*x))*(cos (b*x) + sin (b*x)))) x := by
  have hbx : HasDerivAt (fun x => b*x) b x := by simpa using (hasDerivAt_id x).const_mul b
  have hn : HasDerivAt (fun x => -(b*x)) (-b) x := hbx.neg
  have he := hn.exp
  have hc := hbx.cos
  have hs := hbx.sin
  refine ⟨?_, ?_, ?_, ?_⟩
  · exact (he.mul (hc.add hs)).congr_deriv (by simp only [Pi.add_apply]; ring)
  · exact ((he.mul hs).const_mul (-2*b)).congr_deriv (by ring)
  · exact ((he.mul (hs.sub hc)).const_mul (2*b^2)).congr_deriv
      (by simp only [Pi.sub_apply]; ring)
  · exact ((he.mul hc).const_mul (4*b^3)).congr_deriv (by ring)

open Set Filter Topology in
lemma rail_iteratedDeriv_facts (φ : ℝ → ℝ) (hφ : ContDiff ℝ ∞ φ) (hφc : HasCompactSupport φ)
    (n : ℕ) :
    HasCompactSupport (iteratedDeriv n φ) ∧ Continuous (iteratedDeriv n φ) ∧
    ∀ x, HasDerivAt (iteratedDeriv n φ) (iteratedDeriv (n+1) φ x) x := by
  refine ⟨?_, hφ.continuous_iteratedDeriv n (by exact_mod_cast le_top), fun x => ?_⟩
  · induction n with
    | zero => simpa using hφc
    | succ n ih => rw [iteratedDeriv_succ]; exact ih.deriv
  · rw [iteratedDeriv_succ]
    exact ((hφ.differentiable_iteratedDeriv n
      (by exact_mod_cast WithTop.coe_lt_top _)) x).hasDerivAt


open Set Filter Topology in
lemma rail_half_line (EI k b : ℝ) (hb : 4 * b^4 * EI = k) (φ : ℝ → ℝ)
    (hφ : ContDiff ℝ ∞ φ) (hφc : HasCompactSupport φ) :
    ∫ x in Ioi 0, exp (-(b*x)) * (cos (b*x) + sin (b*x)) *
        (EI * iteratedDeriv 4 φ x + k * φ x)
      = -EI * (iteratedDeriv 3 φ 0 - 2*b^2 * iteratedDeriv 1 φ 0 - 4*b^3 * φ 0) := by
  obtain ⟨c0, -, d0⟩ := rail_iteratedDeriv_facts φ hφ hφc 0
  obtain ⟨c1, -, d1⟩ := rail_iteratedDeriv_facts φ hφ hφc 1
  obtain ⟨c2, -, d2⟩ := rail_iteratedDeriv_facts φ hφ hφc 2
  obtain ⟨c3, -, d3⟩ := rail_iteratedDeriv_facts φ hφ hφc 3
  obtain ⟨c4, k4, -⟩ := rail_iteratedDeriv_facts φ hφ hφc 4
  simp only [iteratedDeriv_zero, zero_add] at c0 d0
  set D1 := iteratedDeriv 1 φ
  set D2 := iteratedDeriv 2 φ
  set D3 := iteratedDeriv 3 φ
  set D4 := iteratedDeriv 4 φ
  set g0 : ℝ → ℝ := fun x => exp (-(b*x)) * (cos (b*x) + sin (b*x)) with hg0
  set g1 : ℝ → ℝ := fun x => -2*b*(exp (-(b*x))*sin (b*x)) with hg1
  set g2 : ℝ → ℝ := fun x => 2*b^2*(exp (-(b*x))*(sin (b*x) - cos (b*x))) with hg2
  set g3 : ℝ → ℝ := fun x => 4*b^3*(exp (-(b*x))*cos (b*x)) with hg3
  set F : ℝ → ℝ := (fun _ => EI) * (g0 * D3 - g1 * D2 + g2 * D1 - g3 * φ) with hF
  have hFd : ∀ x, HasDerivAt F (g0 x * (EI * D4 x + k * φ x)) x := by
    intro x
    obtain ⟨e0, e1, e2, e3⟩ := rail_aux_derivs b x
    have := (((((e0.mul (d3 x)).sub (e1.mul (d2 x))).add (e2.mul (d1 x))).sub
      (e3.mul (d0 x))).const_mul EI)
    refine this.congr_deriv ?_
    simp only [g0, ← hb]
    ring
  have hFc : HasCompactSupport F :=
    ((((c3.mul_left).sub c2.mul_left).add c1.mul_left).sub c0.mul_left).mul_left
  have hint : HasCompactSupport (fun x => g0 x * (EI * D4 x + k * φ x)) :=
    HasCompactSupport.mul_left (f := g0) (f' := (fun _ => EI) * D4 + (fun _ => k) * φ)
      (c4.mul_left.add c0.mul_left)
  have hcont : Continuous (fun x => g0 x * (EI * D4 x + k * φ x)) := by
    have := hφ.continuous
    fun_prop
  rw [integral_Ioi_of_hasDerivAt_of_tendsto (f := F) (m := 0)
    (hFd 0).continuousAt.continuousWithinAt (fun x _ => hFd x)
    (hcont.integrable_of_hasCompactSupport hint).integrableOn
    (hFc.is_zero_at_infty.mono_left atTop_le_cocompact)]
  simp only [F, g0, g1, g2, g3, Pi.mul_apply, Pi.sub_apply, Pi.add_apply, mul_zero, neg_zero,
    exp_zero, cos_zero, sin_zero]
  ring

open Set Filter Topology in
lemma railBeta_facts (EI k : ℝ) (hEI : 0 < EI) (hk : 0 < k) :
    0 < railBeta EI k ∧ 4 * railBeta EI k ^ 4 * EI = k := by
  have hpos : 0 < k / (4 * EI) := by positivity
  refine ⟨Real.rpow_pos_of_pos hpos _, ?_⟩
  have : railBeta EI k ^ 4 = k / (4 * EI) := by
    unfold railBeta
    rw [← Real.rpow_natCast, ← Real.rpow_mul hpos.le]
    norm_num
  rw [this]
  field_simp

open Set Filter Topology in
lemma railG_continuous (EI k : ℝ) : Continuous (railG EI k) := by
  unfold railG; fun_prop

open Set Filter Topology in
lemma railL_facts (EI k : ℝ) (φ : ℝ → ℝ) (hφ : ContDiff ℝ ∞ φ) (hφc : HasCompactSupport φ) :
    Continuous (railL EI k φ) ∧ HasCompactSupport (railL EI k φ) := by
  obtain ⟨c0, -, -⟩ := rail_iteratedDeriv_facts φ hφ hφc 0
  obtain ⟨c4, k4, -⟩ := rail_iteratedDeriv_facts φ hφ hφc 4
  simp only [iteratedDeriv_zero] at c0
  refine ⟨?_, HasCompactSupport.add (f := (fun _ => EI) * iteratedDeriv 4 φ)
      (f' := (fun _ => k) * φ) c4.mul_left c0.mul_left⟩
  have := hφ.continuous
  unfold railL
  fun_prop

open Set Filter Topology in
lemma rail_g0_integral (b : ℝ) (hb : 0 < b) :
    IntegrableOn (fun x => exp (-(b*x)) * (cos (b*x) + sin (b*x))) (Ioi 0) ∧
    ∫ x in Ioi 0, exp (-(b*x)) * (cos (b*x) + sin (b*x)) = 1 / b := by
  have hint : IntegrableOn (fun x => exp (-(b*x)) * (cos (b*x) + sin (b*x))) (Ioi 0) := by
    refine Integrable.mono' ((exp_neg_integrableOn_Ioi 0 hb).const_mul 2)
      (by fun_prop : Continuous _).aestronglyMeasurable.restrict
      (Eventually.of_forall fun x => ?_)
    rw [Real.norm_eq_abs, abs_mul, abs_of_pos (exp_pos _), neg_mul]
    have h1 : |cos (b*x) + sin (b*x)| ≤ 2 :=
      (abs_add_le _ _).trans (by linarith [abs_cos_le_one (b*x), abs_sin_le_one (b*x)])
    nlinarith [exp_pos (-(b*x))]
  refine ⟨hint, ?_⟩
  have hd : ∀ x, HasDerivAt (fun x => -1/b * (exp (-(b*x)) * cos (b*x)))
      (exp (-(b*x)) * (cos (b*x) + sin (b*x))) x := by
    intro x
    have hbx : HasDerivAt (fun x => b*x) b x := by simpa using (hasDerivAt_id x).const_mul b
    have hn : HasDerivAt (fun x => -(b*x)) (-b) x := hbx.neg
    refine ((hn.exp.mul hbx.cos).const_mul (-1/b)).congr_deriv ?_
    field_simp
    ring
  have hlim : Tendsto (fun x => -1/b * (exp (-(b*x)) * cos (b*x))) atTop (𝓝 0) := by
    have he : Tendsto (fun x => exp (-(b*x))) atTop (𝓝 0) :=
      tendsto_exp_neg_atTop_nhds_zero.comp (tendsto_id.const_mul_atTop hb)
    have : Tendsto (fun x => 1/b * exp (-(b*x))) atTop (𝓝 0) := by
      simpa using he.const_mul (1/b)
    refine squeeze_zero_norm (fun x => ?_) this
    rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_of_pos (exp_pos _), abs_div, abs_neg, abs_one,
      abs_of_pos hb]
    have hcos := abs_cos_le_one (b*x)
    have he0 := exp_pos (-(b*x))
    have hb' : 0 < 1/b := by positivity
    exact mul_le_mul_of_nonneg_left (mul_le_of_le_one_right he0.le hcos) hb'.le
  rw [integral_Ioi_of_hasDerivAt_of_tendsto (hd 0).continuousAt.continuousWithinAt
    (fun x _ => hd x) hint hlim]
  simp only [mul_zero, neg_zero, exp_zero, cos_zero, mul_one]
  ring

open Set Filter Topology in
lemma railG_integrable (EI k : ℝ) (hEI : 0 < EI) (hk : 0 < k) : Integrable (railG EI k) := by
  obtain ⟨hβ, -⟩ := railBeta_facts EI k hEI hk
  set β := railBeta EI k with hβdef
  set H : ℝ → ℝ := Set.indicator (Ici 0) (fun x => exp (-β * x)) with hHdef
  have hH : Integrable H := (integrable_indicator_iff measurableSet_Ici).2
    ((integrableOn_Ici_iff_integrableOn_Ioi).2 (exp_neg_integrableOn_Ioi 0 hβ))
  have hc : 0 < β / (2 * k) := by positivity
  refine Integrable.mono' ((hH.add hH.comp_neg).const_mul (β / (2 * k) * 2))
    (railG_continuous EI k).aestronglyMeasurable (Eventually.of_forall fun x => ?_)
  have key : ‖railG EI k x‖ ≤ β / (2 * k) * 2 * exp (-(β * |x|)) := by
    rw [Real.norm_eq_abs, railG, ← hβdef, abs_mul, abs_mul, abs_of_pos hc,
      abs_of_pos (exp_pos _)]
    have h1 : |cos (β*|x|) + sin (β*|x|)| ≤ 2 :=
      (abs_add_le _ _).trans (by linarith [abs_cos_le_one (β*|x|), abs_sin_le_one (β*|x|)])
    have := exp_pos (-(β * |x|))
    have := mul_le_mul_of_nonneg_left h1 (mul_pos hc this).le
    linarith
  have h2 : exp (-(β * |x|)) ≤ H x + H (-x) := by
    have hnn : ∀ y, 0 ≤ H y := fun y => Set.indicator_nonneg (fun _ _ => (exp_pos _).le) y
    rcases le_or_gt 0 x with hx | hx
    · have : H x = exp (-(β * |x|)) := by
        rw [hHdef, Set.indicator_of_mem (by exact hx), abs_of_nonneg hx, neg_mul]
      linarith [hnn (-x)]
    · have : H (-x) = exp (-(β * |x|)) := by
        rw [hHdef, Set.indicator_of_mem (by simp; linarith), abs_of_neg hx, neg_mul]
      linarith [hnn x]
  calc ‖railG EI k x‖ ≤ β / (2 * k) * 2 * exp (-(β * |x|)) := key
    _ ≤ β / (2 * k) * 2 * (H x + H (-x)) := by gcongr

/-- The card's main claim, LG = δ as distributions: if the rail's bending stiffness EI and the
bed's stiffness k are both positive, then for every test function φ (smooth and zero outside a
bounded interval) the rail's dip G read against Lφ = EI φ'''' + k φ gives φ(0), that is
∫ G(x) (EI φ''''(x) + k φ(x)) dx = φ(0). -/
theorem rail_dip_is_fundamental_solution (EI k : ℝ) (hEI : 0 < EI) (hk : 0 < k)
    (φ : ℝ → ℝ) (hφ : ContDiff ℝ ∞ φ) (hφc : HasCompactSupport φ) :
    ∫ x, railG EI k x * railL EI k φ x = φ 0 := by
  obtain ⟨hβ, hβ4⟩ := railBeta_facts EI k hEI hk
  set β := railBeta EI k with hβdef
  obtain ⟨hLcont, hLc⟩ := railL_facts EI k φ hφ hφc
  have hint : Integrable (fun x => railG EI k x * railL EI k φ x) :=
    Continuous.integrable_of_hasCompactSupport ((railG_continuous EI k).mul hLcont)
      (hLc.mul_left (f := railG EI k))
  rw [← intervalIntegral.integral_Iic_add_Ioi (b := 0) hint.integrableOn hint.integrableOn]
  -- right half
  have hR : ∫ x in Set.Ioi 0, railG EI k x * railL EI k φ x
      = β / (2 * k) * (-EI * (iteratedDeriv 3 φ 0 - 2*β^2 * iteratedDeriv 1 φ 0
          - 4*β^3 * φ 0)) := by
    rw [← rail_half_line EI k β hβ4 φ hφ hφc, ← integral_const_mul]
    refine setIntegral_congr_fun measurableSet_Ioi (fun x hx => ?_)
    have : |x| = x := abs_of_pos hx
    simp only [railG, railL, this, ← hβdef]
    ring
  -- left half
  set ψ : ℝ → ℝ := fun x => φ (-x) with hψ
  have hψs : ContDiff ℝ ∞ ψ := hφ.comp contDiff_neg
  have hψc : HasCompactSupport ψ := hφc.comp_homeomorph (Homeomorph.neg ℝ)
  have hL : ∫ x in Set.Iic 0, railG EI k x * railL EI k φ x
      = β / (2 * k) * (-EI * (iteratedDeriv 3 ψ 0 - 2*β^2 * iteratedDeriv 1 ψ 0
          - 4*β^3 * ψ 0)) := by
    have h := integral_comp_neg_Ioi 0 (fun x => railG EI k x * railL EI k φ x)
    rw [neg_zero] at h
    rw [← h, ← rail_half_line EI k β hβ4 ψ hψs hψc, ← integral_const_mul]
    refine setIntegral_congr_fun measurableSet_Ioi (fun x hx => ?_)
    have : |-x| = x := by rw [abs_neg]; exact abs_of_pos hx
    simp only [railG, railL, this, ← hβdef, hψ, iteratedDeriv_comp_neg]
    norm_num
    ring
  rw [hL, hR]
  simp only [hψ, iteratedDeriv_comp_neg, neg_zero]
  have hk0 : k ≠ 0 := hk.ne'
  rw [← hβ4] at hk0 ⊢
  field_simp
  ring

/-- Convolving solves every load: if EI and k are positive and the load q is integrable, or
measurable and bounded, then the sag w = G * q solves L w = q as distributions: for every test
function φ, ∫ (G * q)(x) (EI φ''''(x) + k φ(x)) dx = ∫ q(s) φ(s) ds. -/
theorem convolution_with_rail_dip_solves_any_load (EI k : ℝ) (hEI : 0 < EI) (hk : 0 < k)
    (q : ℝ → ℝ)
    (hq : Integrable q ∨ (AEStronglyMeasurable q volume ∧ ∃ M : ℝ, ∀ s, |q s| ≤ M))
    (φ : ℝ → ℝ) (hφ : ContDiff ℝ ∞ φ) (hφc : HasCompactSupport φ) :
    ∫ x, (railG EI k ⋆[ContinuousLinearMap.lsmul ℝ ℝ] q) x * railL EI k φ x
      = ∫ s, q s * φ s := by
  obtain ⟨hLcont, hLc⟩ := railL_facts EI k φ hφ hφc
  have hG := railG_integrable EI k hEI hk
  obtain ⟨C, hC⟩ := hLcont.bounded_above_of_compact_support hLc
  have hconv : ∀ x, (railG EI k ⋆[ContinuousLinearMap.lsmul ℝ ℝ] q) x
      = ∫ s, railG EI k (x - s) * q s := by
    intro x
    rw [convolution_lsmul_swap]
    simp only [smul_eq_mul]
  have hInt : Integrable (fun p : ℝ × ℝ => railG EI k (p.1 - p.2) * q p.2 * railL EI k φ p.1)
      (volume.prod volume) := by
    rcases hq with hq | ⟨hqm, M, hM⟩
    · have h1 := hq.convolution_integrand (ContinuousLinearMap.lsmul ℝ ℝ) hG
        (μ := volume) (ν := volume)
      have h2 := h1.mul_bdd (hLcont.aestronglyMeasurable.comp_fst) (c := C)
        (Filter.Eventually.of_forall fun p => hC p.1)
      refine h2.congr (Filter.Eventually.of_forall fun p => ?_)
      simp only [ContinuousLinearMap.lsmul_apply, smul_eq_mul]
      ring
    · have h1 := (hLcont.integrable_of_hasCompactSupport hLc).convolution_integrand
        (ContinuousLinearMap.lsmul ℝ ℝ) hG (μ := volume) (ν := volume)
      have h2 := h1.swap.mul_bdd (hqm.comp_snd) (c := M)
        (Filter.Eventually.of_forall fun p => by rw [Real.norm_eq_abs]; exact hM p.2)
      refine h2.congr (Filter.Eventually.of_forall fun p => ?_)
      simp only [Function.comp, Prod.fst_swap, Prod.snd_swap, ContinuousLinearMap.lsmul_apply,
        smul_eq_mul]
      have : railG EI k (p.2 - p.1) = railG EI k (p.1 - p.2) := by
        simp only [railG, abs_sub_comm]
      rw [this]
      ring
  simp_rw [hconv, ← integral_mul_const]
  rw [integral_integral_swap hInt]
  refine integral_congr_ae (Filter.Eventually.of_forall fun s => ?_)
  have e1 : (fun x => railG EI k (x - s) * q s * railL EI k φ x)
      = fun x => q s * (railG EI k (x - s) * railL EI k φ (x - s + s)) := by
    funext x
    rw [sub_add_cancel]
    ring
  simp only
  rw [e1, integral_const_mul,
    integral_sub_right_eq_self (fun y => railG EI k y * railL EI k φ (y + s)) s]
  congr 1
  have hφs : ContDiff ℝ ∞ (fun y => φ (y + s)) := hφ.comp (contDiff_id.add contDiff_const)
  have hφsc : HasCompactSupport (fun y => φ (y + s)) :=
    hφc.comp_homeomorph (Homeomorph.addRight s)
  have := rail_dip_is_fundamental_solution EI k hEI hk _ hφs hφsc
  simp only [zero_add] at this
  rw [← this]
  congr 1
  funext y
  simp only [railL, iteratedDeriv_comp_add_const]

/-- A load spread evenly everywhere sags the rail by load / k, so the bed's stiffness times the
area under the dip is 1: k ∫ G(x) dx = 1, and G is integrable. -/
theorem bed_stiffness_times_area_under_dip (EI k : ℝ) (hEI : 0 < EI) (hk : 0 < k) :
    Integrable (railG EI k) ∧ k * ∫ x, railG EI k x = 1 := by
  obtain ⟨hβ, hβ4⟩ := railBeta_facts EI k hEI hk
  set β := railBeta EI k with hβdef
  obtain ⟨-, hval⟩ := rail_g0_integral β hβ
  refine ⟨railG_integrable EI k hEI hk, ?_⟩
  have h := integral_comp_abs (f := fun t => β / (2 * k) * exp (-(β * t)) *
    (cos (β * t) + sin (β * t)))
  have h' : ∫ x, railG EI k x = 2 * ∫ t in Set.Ioi 0, β / (2 * k) * exp (-(β * t)) *
      (cos (β * t) + sin (β * t)) := h
  simp only [mul_assoc] at h'
  rw [h', integral_const_mul, hval]
  field_simp

-- Step 1: (1 + i)^4 = -4, so β(±1 ± i) are the four roots of r^4 = -4β^4.
example : (1 + Complex.I) ^ 4 = -4 := by
  have h : (1 + Complex.I) ^ 2 = 2 * Complex.I := by
    ring_nf; rw [Complex.I_sq]; ring
  rw [show (4 : ℕ) = 2 * 2 from rfl, pow_mul, h]
  ring_nf; rw [Complex.I_sq]; norm_num

-- Worked numbers: EI = 210 × 10^9 × 3055 × 10^(-8) N m² is 6,415,500 N m² (6.4155 MN m²).
example : (210 * 10 ^ 9 : ℚ) * (3055 / 10 ^ 8) = 6415500 := by
  norm_num

-- Mistake 2, no bending stiffness: the grid's sag P/(k h), in mm, with P = 100,000 N and
-- k = 40,000,000 N/m², is 25, 50 and 100 mm at h = 1/10, 1/20 and 1/40 m.
example : (100000 : ℚ) / (40000000 * (1 / 10)) * 1000 = 25 := by
  norm_num
example : (100000 : ℚ) / (40000000 * (1 / 20)) * 1000 = 50 := by
  norm_num
example : (100000 : ℚ) / (40000000 * (1 / 40)) * 1000 = 100 := by
  norm_num

#print axioms rail_aux_derivs
#print axioms rail_iteratedDeriv_facts
#print axioms rail_half_line
#print axioms railBeta_facts
#print axioms railG_continuous
#print axioms railL_facts
#print axioms rail_g0_integral
#print axioms railG_integrable
#print axioms rail_dip_is_fundamental_solution
#print axioms convolution_with_rail_dip_solves_any_load
#print axioms bed_stiffness_times_area_under_dip
