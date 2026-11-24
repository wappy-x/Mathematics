-- Schwarz reflection: a function holomorphic above a stretch of the real axis, continuous up to it and real on it, is continued across that stretch by its mirror image conj f(conj z), this continuation is the only one, and the Cayley map sends mirror pairs in the real axis to mirror pairs in the unit circle.
import Mathlib.Analysis.Complex.HasPrimitives
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.Analytic.IsolatedZeros
import Mathlib.Analysis.Complex.Exponential
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Star

open ComplexConjugate
open scoped Interval

open Set Metric in
/-- A point of a rectangle in a disc centred on the real axis, pushed vertically toward the axis,
stays in the disc. -/
lemma srp_mem_ball {z : ℂ} (hz : z.im = 0) {r : ℝ} {a b : ℂ}
    (h : Complex.Rectangle a b ⊆ ball z r) {u : ℂ} (hre : u.re ∈ [[a.re, b.re]])
    (him : u.im ∈ [[a.im, 0]] ∨ u.im ∈ [[0, b.im]]) : u ∈ ball z r := by
  have key : ∀ v : ℂ, v ∈ ball z r → u.re = v.re → |u.im| ≤ |v.im| → u ∈ ball z r := by
    intro v hv hre' him'
    rw [mem_ball, Complex.dist_eq_re_im] at hv ⊢
    refine lt_of_le_of_lt (Real.sqrt_le_sqrt ?_) hv
    rw [hz, hre', sub_zero, sub_zero]
    have h1 : u.im ^ 2 ≤ v.im ^ 2 := by
      rw [← sq_abs u.im, ← sq_abs v.im]
      exact pow_le_pow_left₀ (abs_nonneg _) him' 2
    linarith
  rcases him with him | him
  · refine key ⟨u.re, a.im⟩ (h ?_) rfl ?_
    · exact Complex.mem_reProdIm.mpr ⟨hre, left_mem_uIcc⟩
    · rcases mem_uIcc.mp him with ⟨h1, h2⟩ | ⟨h1, h2⟩
      · show |u.im| ≤ |a.im|
        rw [abs_of_nonpos h2, abs_of_nonpos (h1.trans h2)]; linarith
      · show |u.im| ≤ |a.im|
        rw [abs_of_nonneg h1, abs_of_nonneg (h1.trans h2)]; linarith
  · refine key ⟨u.re, b.im⟩ (h ?_) rfl ?_
    · exact Complex.mem_reProdIm.mpr ⟨hre, right_mem_uIcc⟩
    · rcases mem_uIcc.mp him with ⟨h1, h2⟩ | ⟨h1, h2⟩
      · show |u.im| ≤ |b.im|
        rw [abs_of_nonneg h1, abs_of_nonneg (h1.trans h2)]; linarith
      · show |u.im| ≤ |b.im|
        rw [abs_of_nonpos h2, abs_of_nonpos (h1.trans h2)]; linarith

#print axioms srp_mem_ball

open Set Metric in
/-- Morera step: a function continuous on a disc centred on the real axis and holomorphic at every
point of the disc off the axis has vanishing integral round every rectangle in the disc. -/
lemma srp_isConservativeOn {F : ℂ → ℂ} {z : ℂ} (hz : z.im = 0) {r : ℝ}
    (hc : ContinuousOn F (ball z r))
    (hd : ∀ w ∈ ball z r, w.im ≠ 0 → DifferentiableAt ℂ F w) :
    Complex.IsConservativeOn F (ball z r) := by
  intro a b hab
  rw [← add_eq_zero_iff_eq_neg, Complex.wedgeIntegral_add_wedgeIntegral_eq]
  -- the vertical sides are integrable on each piece
  have hvert : ∀ c : ℝ, c ∈ [[a.re, b.re]] → ∀ s t : ℝ,
      (s = a.im ∧ t = 0 ∨ s = 0 ∧ t = b.im) →
      IntervalIntegrable (fun y : ℝ => F (c + y * Complex.I)) MeasureTheory.volume s t := by
    intro c hcm s t hst
    apply ContinuousOn.intervalIntegrable
    refine hc.comp (by fun_prop) ?_
    intro y hy
    apply srp_mem_ball hz hab
    · simpa using hcm
    · simp only [Complex.add_im, Complex.ofReal_im, Complex.mul_im, Complex.ofReal_re,
        Complex.I_re, Complex.I_im, mul_zero, mul_one, zero_add, add_zero]
      rcases hst with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
      · exact Or.inl hy
      · exact Or.inr hy
  have hrect : ∀ p q : ℂ, p.re ∈ [[a.re, b.re]] → q.re ∈ [[a.re, b.re]] →
      ((p.im = a.im ∧ q.im = 0) ∨ (p.im = 0 ∧ q.im = b.im)) →
      (∫ x : ℝ in p.re..q.re, F (x + p.im * Complex.I)) -
        (∫ x : ℝ in p.re..q.re, F (x + q.im * Complex.I)) +
        Complex.I • (∫ y : ℝ in p.im..q.im, F (q.re + y * Complex.I)) -
        Complex.I • (∫ y : ℝ in p.im..q.im, F (p.re + y * Complex.I)) = 0 := by
    intro p q hp hq hpq
    have hsub : ∀ u : ℂ, u ∈ [[p.re, q.re]] ×ℂ [[p.im, q.im]] → u ∈ ball z r := by
      intro u hu
      rw [Complex.mem_reProdIm] at hu
      apply srp_mem_ball hz hab
      · exact uIcc_subset_uIcc hp hq hu.1
      · rcases hpq with ⟨h1, h2⟩ | ⟨h1, h2⟩
        · rw [h1, h2] at hu; exact Or.inl hu.2
        · rw [h1, h2] at hu; exact Or.inr hu.2
    apply Complex.integral_boundary_rect_eq_zero_of_continuousOn_of_differentiableOn
    · exact hc.mono hsub
    · intro u hu
      have hu' : u ∈ [[p.re, q.re]] ×ℂ [[p.im, q.im]] := by
        rw [Complex.mem_reProdIm] at hu ⊢
        exact ⟨Ioo_subset_Icc_self hu.1, Ioo_subset_Icc_self hu.2⟩
      apply DifferentiableAt.differentiableWithinAt
      apply hd u (hsub u hu')
      intro h0
      rw [Complex.mem_reProdIm, h0] at hu
      obtain ⟨-, hlo, hhi⟩ := hu
      rcases hpq with ⟨h1, h2⟩ | ⟨h1, h2⟩
      · rw [h2] at hlo hhi
        rcases le_total p.im 0 with h | h
        · rw [max_eq_right h] at hhi; exact lt_irrefl _ hhi
        · rw [min_eq_right h] at hlo; exact lt_irrefl _ hlo
      · rw [h1] at hlo hhi
        rcases le_total 0 q.im with h | h
        · rw [min_eq_left h] at hlo; exact lt_irrefl _ hlo
        · rw [max_eq_left h] at hhi; exact lt_irrefl _ hhi
  have e1 := hrect a (b.re : ℂ) left_mem_uIcc (by simp) (Or.inl ⟨rfl, by simp⟩)
  have e2 := hrect (a.re : ℂ) b (by simp) right_mem_uIcc (Or.inr ⟨by simp, rfl⟩)
  simp only [Complex.ofReal_re, Complex.ofReal_im] at e1 e2
  rw [← intervalIntegral.integral_add_adjacent_intervals
      (hvert b.re right_mem_uIcc a.im 0 (Or.inl ⟨rfl, rfl⟩))
      (hvert b.re right_mem_uIcc 0 b.im (Or.inr ⟨rfl, rfl⟩)),
    ← intervalIntegral.integral_add_adjacent_intervals
      (hvert a.re left_mem_uIcc a.im 0 (Or.inl ⟨rfl, rfl⟩))
      (hvert a.re left_mem_uIcc 0 b.im (Or.inr ⟨rfl, rfl⟩))]
  simp only [smul_eq_mul] at e1 e2 ⊢
  linear_combination e1 + e2

#print axioms srp_isConservativeOn

/-- The Schwarz reflection principle, the card's main claim. Let Ω be an open region symmetric
about the real axis (the mirror conj z of every point z of Ω is in Ω). Let f be holomorphic
(complex differentiable) on Ω⁺, the part of Ω above the axis, continuous up to the stretch
I = Ω ∩ ℝ, and real on I. Then the reflected extension F, equal to f on and above the axis and
to conj f(conj z) below it, is holomorphic on all of Ω. -/
theorem schwarz_reflection_extension_holomorphic {Ω : Set ℂ} {f : ℂ → ℂ}
    (hΩ : IsOpen Ω) (hsymm : ∀ z ∈ Ω, conj z ∈ Ω)
    (hf : DifferentiableOn ℂ f (Ω ∩ {z | 0 < z.im}))
    (hcont : ContinuousOn f (Ω ∩ {z | 0 ≤ z.im}))
    (hreal : ∀ z ∈ Ω, z.im = 0 → (f z).im = 0) :
    DifferentiableOn ℂ (fun z => if 0 ≤ z.im then f z else conj (f (conj z))) Ω := by
  set F : ℂ → ℂ := fun z => if 0 ≤ z.im then f z else conj (f (conj z)) with hFdef
  have hUopen : IsOpen (Ω ∩ {z : ℂ | 0 < z.im}) :=
    hΩ.inter (isOpen_lt continuous_const Complex.continuous_im)
  -- off the axis F is holomorphic
  have hoff : ∀ w ∈ Ω, w.im ≠ 0 → DifferentiableAt ℂ F w := by
    intro w hw hw0
    rcases lt_or_gt_of_ne hw0 with hneg | hpos
    · have hcw : conj w ∈ Ω ∩ {z : ℂ | 0 < z.im} :=
        ⟨hsymm w hw, by simp only [Set.mem_ofPred_eq, Complex.conj_im]; linarith⟩
      have hd : DifferentiableAt ℂ (conj ∘ f ∘ conj) w :=
        differentiableAt_conj_conj_iff.mpr ((hf _ hcw).differentiableAt (hUopen.mem_nhds hcw))
      refine hd.congr_of_eventuallyEq ?_
      filter_upwards [(isOpen_lt Complex.continuous_im continuous_const).mem_nhds
        (show w ∈ {z : ℂ | z.im < 0} from hneg)] with u hu
      simp only [hFdef, Function.comp_apply]
      simp [not_le.mpr hu]
    · have hw' : w ∈ Ω ∩ {z : ℂ | 0 < z.im} := ⟨hw, hpos⟩
      refine ((hf _ hw').differentiableAt (hUopen.mem_nhds hw')).congr_of_eventuallyEq ?_
      filter_upwards [hUopen.mem_nhds hw'] with u hu
      simp only [hFdef]
      simp [le_of_lt (show (0:ℝ) < u.im from hu.2)]
  -- F is continuous on Ω
  have hFcont : ContinuousOn F Ω := by
    apply ContinuousOn.if
    · intro a ha
      have ha0 : a.im = 0 := by
        have := frontier_le_subset_eq continuous_const Complex.continuous_im ha.2
        exact this.symm
      have hca : conj a = a := Complex.conj_eq_iff_im.mpr ha0
      rw [hca]
      exact (Complex.conj_eq_iff_im.mpr (hreal a ha.1 ha0)).symm
    · refine hcont.mono ?_
      rw [(isClosed_le continuous_const Complex.continuous_im).closure_eq]
    · have hsub : closure {a : ℂ | ¬ 0 ≤ a.im} ⊆ {a : ℂ | a.im ≤ 0} :=
        closure_minimal (fun a ha => le_of_lt (not_le.mp ha))
          (isClosed_le Complex.continuous_im continuous_const)
      have hg : ContinuousOn (fun z => conj (f (conj z))) (Ω ∩ {a : ℂ | a.im ≤ 0}) := by
        refine Complex.continuous_conj.comp_continuousOn
          (hcont.comp Complex.continuous_conj.continuousOn ?_)
        intro a ha
        refine ⟨hsymm a ha.1, ?_⟩
        simp only [Set.mem_ofPred_eq, Complex.conj_im]
        have := ha.2; simp only [Set.mem_ofPred_eq] at this; linarith
      exact hg.mono (Set.inter_subset_inter_right _ hsub)
  intro w hw
  by_cases hw0 : w.im = 0
  · obtain ⟨r, hr, hball⟩ := Metric.isOpen_iff.mp hΩ w hw
    have hdisc : DifferentiableOn ℂ F (Metric.ball w r) :=
      (Complex.isConservativeOn_and_continuousOn_iff_isDifferentiableOn Metric.isOpen_ball).mp
        ⟨srp_isConservativeOn hw0 (hFcont.mono hball)
          (fun u hu hu0 => hoff u (hball hu) hu0), hFcont.mono hball⟩
    exact ((hdisc w (Metric.mem_ball_self hr)).differentiableAt
      (Metric.isOpen_ball.mem_nhds (Metric.mem_ball_self hr))).differentiableWithinAt
  · exact (hoff w hw hw0).differentiableWithinAt

/-- The reflected extension is the only one. On a connected open region Ω symmetric about the
real axis, with f as in the main claim, every function holomorphic on all of Ω that equals f
above the axis is the reflected extension F at every point of Ω. -/
theorem schwarz_reflection_extension_unique {Ω : Set ℂ} {f G : ℂ → ℂ}
    (hΩ : IsOpen Ω) (hconn : IsConnected Ω) (hsymm : ∀ z ∈ Ω, conj z ∈ Ω)
    (hf : DifferentiableOn ℂ f (Ω ∩ {z | 0 < z.im}))
    (hcont : ContinuousOn f (Ω ∩ {z | 0 ≤ z.im}))
    (hreal : ∀ z ∈ Ω, z.im = 0 → (f z).im = 0)
    (hG : DifferentiableOn ℂ G Ω) (hGf : Set.EqOn G f (Ω ∩ {z | 0 < z.im})) :
    Set.EqOn G (fun z => if 0 ≤ z.im then f z else conj (f (conj z))) Ω := by
  have hF := schwarz_reflection_extension_holomorphic hΩ hsymm hf hcont hreal
  have hUopen : IsOpen (Ω ∩ {z : ℂ | 0 < z.im}) :=
    hΩ.inter (isOpen_lt continuous_const Complex.continuous_im)
  -- Ω has a point strictly above the axis
  obtain ⟨z₀, hz₀⟩ : (Ω ∩ {z : ℂ | 0 < z.im}).Nonempty := by
    obtain ⟨z, hz⟩ := hconn.nonempty
    rcases lt_trichotomy z.im 0 with h | h | h
    · exact ⟨conj z, hsymm z hz, by simp only [Set.mem_ofPred_eq, Complex.conj_im]; linarith⟩
    · obtain ⟨r, hr, hball⟩ := Metric.isOpen_iff.mp hΩ z hz
      refine ⟨z + (r / 2 : ℝ) * Complex.I, hball ?_, ?_⟩
      · rw [Metric.mem_ball, dist_eq_norm, add_sub_cancel_left, norm_mul, Complex.norm_I,
          mul_one, Complex.norm_real, Real.norm_eq_abs, abs_of_pos (by positivity)]
        linarith
      · simp [h]; positivity
    · exact ⟨z, hz, h⟩
  refine (hG.analyticOnNhd hΩ).eqOn_of_preconnected_of_eventuallyEq (hF.analyticOnNhd hΩ)
    hconn.isPreconnected hz₀.1 ?_
  filter_upwards [hUopen.mem_nhds hz₀] with u hu
  have hu0 : 0 ≤ u.im := le_of_lt (show 0 < u.im from hu.2)
  rw [hGf hu]
  simp [hu0]

/-- The Cayley map C(z) = (z - i)/(z + i) sends mirror pairs to mirror pairs: C at the mirror
point conj z is the mirror of C(z) in the unit circle, 1/conj C(z). (At z = i and z = -i both
sides are 0 under Lean's convention 1/0 = 0.) -/
theorem cayley_conj_eq_circle_mirror (z : ℂ) :
    (conj z - Complex.I) / (conj z + Complex.I) =
      1 / conj ((z - Complex.I) / (z + Complex.I)) := by
  rw [map_div₀, map_sub, map_add, Complex.conj_I, one_div_div, sub_neg_eq_add, ← sub_eq_add_neg]

-- The lead example: e^z is real on the axis, and its mirror conj e^(conj z) is e^z itself.
example (z : ℂ) : conj (Complex.exp (conj z)) = Complex.exp z := by
  rw [← Complex.exp_conj, Complex.conj_conj]
-- The non-example: the constant i mirrors to -i, so the halves do not meet.
example : conj Complex.I = -Complex.I := by simp
-- p = 0.3 + 0.4i, mirrored in the unit circle: p* = 1/conj p = 1.2 + 1.6i.
example : 1 / conj ((3 : ℂ) / 10 + 4 / 10 * Complex.I) = 6 / 5 + 8 / 5 * Complex.I := by
  rw [Complex.ext_iff]; simp [Complex.div_re, Complex.div_im, Complex.normSq]; norm_num
-- The triangle crosses the axis at -0.2125 and 0.4125: chord 0.625, and -2i times it is -1.25i.
example : (33 : ℚ) / 80 - (-17 / 80) = 5 / 8 := by norm_num
example : -2 * Complex.I * ((5 : ℂ) / 8) = -(5 / 4) * Complex.I := by ring
-- Cayley map: C(p) = -15/41 - 12/41 i and C(conj p) = -5/3 - 4/3 i.
example : ((3 : ℂ) / 10 + 4 / 10 * Complex.I - Complex.I) / ((3 : ℂ) / 10 + 4 / 10 * Complex.I + Complex.I)
    = -15 / 41 - 12 / 41 * Complex.I := by
  rw [Complex.ext_iff]; simp [Complex.div_re, Complex.div_im, Complex.normSq]; norm_num
example : ((3 : ℂ) / 10 - 4 / 10 * Complex.I - Complex.I) / ((3 : ℂ) / 10 - 4 / 10 * Complex.I + Complex.I)
    = -5 / 3 - 4 / 3 * Complex.I := by
  rw [Complex.ext_iff]; simp [Complex.div_re, Complex.div_im, Complex.normSq]; norm_num
-- Half-disc map g(z) = ((1 + z)/(1 - z))^2: g(0.5) = 9 on the diameter.
example : ((1 + (1 : ℚ) / 2) / (1 - 1 / 2)) ^ 2 = 9 := by norm_num
-- g(p) = (-31 + 480i)/169, about -0.183432 + 2.840237i.
example : ((1 + ((3 : ℂ) / 10 + 4 / 10 * Complex.I)) / (1 - ((3 : ℂ) / 10 + 4 / 10 * Complex.I))) ^ 2
    = -31 / 169 + 480 / 169 * Complex.I := by
  rw [Complex.ext_iff]; simp [Complex.div_re, Complex.div_im, Complex.normSq, pow_two]; norm_num
-- Taylor coefficients 1/n! of e^z for n = 0..4 are 1, 1, 1/2, 1/6, 1/24: the factorials are 1, 1, 2, 6, 24.
example : (List.range 5).map Nat.factorial = [1, 1, 2, 6, 24] := by decide

#print axioms schwarz_reflection_extension_holomorphic
#print axioms schwarz_reflection_extension_unique
#print axioms cayley_conj_eq_circle_mirror
