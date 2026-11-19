-- Regular curve and arc length: a curve whose velocity never vanishes and has no jumps can be relabelled by the distance travelled along it, so that it moves at speed one, the labelling is unique once a start and a direction are chosen, and the card's airtime hill uses exactly 45/2 (20/9 + ln 3) metres of rail.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Arsinh
import Mathlib.Order.Interval.Set.OrdConnected
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Inverse
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.FDeriv.WithLp
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Topology.Order.MonotoneContinuity
import Mathlib.Tactic

open Set

namespace RegularCurvesAndArcLength

/-- The arc length from the clock reading `t₀` to `t` of a curve whose velocity at each
reading `w` is `r' w`: the speed `‖r' w‖` added up from `t₀` to `t`,
`s(t) = ∫_{t₀}^{t} |ṙ(w)| dw`. -/
noncomputable def arcLength {E : Type*} [NormedAddCommGroup E] (r' : ℝ → E) (t₀ t : ℝ) : ℝ :=
  ∫ w in t₀..t, ‖r' w‖

/-- Helper: the integral of a function continuous on an interval has that function as its
derivative within the interval. -/
theorem hasDerivWithinAt_integral_of_ordConnected {f : ℝ → ℝ} {I : Set ℝ} (hI : I.OrdConnected)
    (hf : ContinuousOn f I) {t₀ t : ℝ} (ht₀ : t₀ ∈ I) (ht : t ∈ I) :
    HasDerivWithinAt (fun u => ∫ w in t₀..u, f w) (f t) I t := by
  have hint : ∀ a ∈ I, ∀ b ∈ I, IntervalIntegrable f MeasureTheory.volume a b :=
    fun a ha b hb => (hf.mono (hI.uIcc_subset ha hb)).intervalIntegrable
  rw [hasDerivWithinAt_iff_isLittleO, Asymptotics.isLittleO_iff]
  intro c hc
  have hcont := hf t ht
  rw [Metric.continuousWithinAt_iff] at hcont
  obtain ⟨δ, hδ, hδ'⟩ := hcont c hc
  rw [eventually_nhdsWithin_iff, Metric.eventually_nhds_iff]
  refine ⟨δ, hδ, fun u hu huI => ?_⟩
  rw [intervalIntegral.integral_interval_sub_left (hint t₀ ht₀ u huI) (hint t₀ ht₀ t ht)]
  have hconst : (u - t) • f t = ∫ _ in t..u, f t := by simp
  rw [hconst, ← intervalIntegral.integral_sub (hint t ht u huI) intervalIntegrable_const,
    Real.norm_eq_abs (u - t)]
  apply intervalIntegral.norm_integral_le_of_norm_le_const
  intro w hw
  have hw' : w ∈ uIcc t u := uIoc_subset_uIcc hw
  have hwI : w ∈ I := hI.uIcc_subset ht huI hw'
  have hdist : dist w t < δ := by
    rw [Real.dist_eq]
    exact lt_of_le_of_lt (abs_sub_left_of_mem_uIcc hw') (by rwa [Real.dist_eq] at hu)
  have := hδ' hwI hdist
  rw [dist_eq_norm] at this
  exact this.le

/-- **A regular curve can be relabelled by arc length, and then it has unit speed.**
A curve `r` has its clock `t` running over an interval `I` (one unbroken stretch of readings,
open, closed or half-open, possibly unbounded). Its velocity `r' t` changes without jumps
(`r` has derivative `r' t` at each reading of `I`, one-sided at an end of `I`, and `r'` is
continuous on `I`), and it is never zero (the curve is regular). Fix a start reading `t₀` in `I`
and let `s(t)` be the arc length from `t₀`. Then:
* the rail is added at the rate of the speed: `ds/dt = |ṙ(t)|`;
* `s` strictly increases on `I`, so it takes each value once, and its values form an interval `J`;
* `s` can be run backwards: there is a clock reading `t(s)` in `I` for each distance `s` in `J`,
  with `t(s(t)) = t`;
* the relabelled curve `r̃(s) = r(t(s))` has velocity per unit of arc length equal to
  `T(s) = ṙ(t) / |ṙ(t)|`, the old velocity divided by its own length, so `|T(s)| = 1`.
This is global: it holds along the whole interval, not only near one point. -/
theorem regular_curve_relabels_by_arc_length_to_unit_speed
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {I : Set ℝ} (hI : I.OrdConnected) {r r' : ℝ → E}
    (hr : ∀ t ∈ I, HasDerivWithinAt r (r' t) I t) (hr' : ContinuousOn r' I)
    (hreg : ∀ t ∈ I, r' t ≠ 0) {t₀ : ℝ} (ht₀ : t₀ ∈ I) :
    (∀ t ∈ I, HasDerivWithinAt (arcLength r' t₀) ‖r' t‖ I t) ∧
      StrictMonoOn (arcLength r' t₀) I ∧ (arcLength r' t₀ '' I).OrdConnected ∧
      ∃ tOf : ℝ → ℝ, MapsTo tOf (arcLength r' t₀ '' I) I ∧
        (∀ t ∈ I, tOf (arcLength r' t₀ t) = t) ∧
        ∀ σ ∈ arcLength r' t₀ '' I,
          HasDerivWithinAt (fun σ => r (tOf σ)) (‖r' (tOf σ)‖⁻¹ • r' (tOf σ))
            (arcLength r' t₀ '' I) σ ∧
          ‖‖r' (tOf σ)‖⁻¹ • r' (tOf σ)‖ = 1 := by
  set F := arcLength r' t₀ with hFdef
  have hderiv : ∀ t ∈ I, HasDerivWithinAt F ‖r' t‖ I t := fun t ht =>
    hasDerivWithinAt_integral_of_ordConnected hI hr'.norm ht₀ ht
  have hFcont : ContinuousOn F I := fun t ht => (hderiv t ht).continuousWithinAt
  have hmono : StrictMonoOn F I := by
    refine strictMonoOn_of_hasDerivWithinAt_pos hI.convex hFcont
      (fun x hx => (hderiv x (interior_subset hx)).mono interior_subset)
      (fun x hx => norm_pos_iff.2 (hreg x (interior_subset hx)))
  have hJ : (F '' I).OrdConnected := (hI.isPreconnected.image F hFcont).ordConnected
  refine ⟨hderiv, hmono, hJ, ?_⟩
  classical
  have : I.OrdConnected := hI
  have : (F '' I).OrdConnected := hJ
  let e : I ≃o (F '' I) := StrictMonoOn.orderIso F I hmono
  let tOf : ℝ → ℝ := fun σ => if h : σ ∈ F '' I then (e.symm ⟨σ, h⟩ : ℝ) else t₀
  have hmaps : MapsTo tOf (F '' I) I := by
    intro σ hσ
    rw [show tOf σ = (e.symm ⟨σ, hσ⟩ : ℝ) from dite_eq_left hσ]
    exact (e.symm ⟨σ, hσ⟩).2
  have hleft : ∀ t ∈ I, tOf (F t) = t := by
    intro t ht
    have hmem : F t ∈ F '' I := mem_image_of_mem F ht
    rw [show tOf (F t) = (e.symm ⟨F t, hmem⟩ : ℝ) from dite_eq_left hmem]
    have : e.symm ⟨F t, hmem⟩ = ⟨t, ht⟩ := by
      rw [OrderIso.symm_apply_eq]
      rfl
    rw [this]
  have hright : ∀ σ ∈ F '' I, F (tOf σ) = σ := by
    intro σ hσ
    rw [show tOf σ = (e.symm ⟨σ, hσ⟩ : ℝ) from dite_eq_left hσ]
    exact congrArg Subtype.val (e.apply_symm_apply ⟨σ, hσ⟩)
  have hcont : ContinuousOn tOf (F '' I) := by
    rw [continuousOn_iff_continuous_domRestrict]
    have : (F '' I).domRestrict tOf = fun y => ((e.symm y : I) : ℝ) := by
      funext y
      exact dite_eq_left y.2
    rw [this]
    exact continuous_subtype_val.comp e.symm.continuous
  refine ⟨tOf, hmaps, hleft, fun σ hσ => ⟨?_, ?_⟩⟩
  · have ht : tOf σ ∈ I := hmaps hσ
    have hne : ‖r' (tOf σ)‖ ≠ 0 := norm_ne_zero_iff.2 (hreg _ ht)
    have hinv : HasDerivWithinAt tOf ‖r' (tOf σ)‖⁻¹ (F '' I) σ :=
      HasFDerivWithinAt.of_local_left_inverse
        (f' := ContinuousLinearEquiv.unitsEquivAut ℝ (Units.mk0 _ hne))
        ((hcont σ hσ).tendsto_nhdsWithin hmaps) (hderiv _ ht) hσ
        (eventually_nhdsWithin_of_forall hright)
    exact (hr _ ht).scomp σ hinv hmaps
  · have hv := hreg _ (hmaps hσ)
    rw [norm_smul, norm_inv, norm_norm, inv_mul_cancel₀ (norm_ne_zero_iff.2 hv)]

/-- **The arc-length labelling is unique up to its start and its direction.**
Let `c` be a unit-speed labelling of a curve over an interval `J` (velocity `T s` of length 1)
and `γ` another unit-speed labelling over an interval `K` (velocity `γ' σ` of length 1). Suppose
they are the same curve under a change of label `σ = h(s)` from `J` into `K` whose rate `h' s`
is continuous and never zero, so `c(s) = γ(h(s))`. Then `h(s) = s + b` for every `s` in `J`, or
`h(s) = -s + b` for every `s` in `J`, for one constant `b`: the only freedom is where the label
`0` sits and which way is forward. -/
theorem unit_speed_relabelling_unique_up_to_start_and_direction
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {J K : Set ℝ} (hJ : J.OrdConnected) (hK : K.OrdConnected)
    {c γ T γ' : ℝ → E} {h h' : ℝ → ℝ}
    (hc : ∀ s ∈ J, HasDerivWithinAt c (T s) J s) (hT : ∀ s ∈ J, ‖T s‖ = 1)
    (hγ : ∀ σ ∈ K, HasDerivWithinAt γ (γ' σ) K σ) (hγ' : ∀ σ ∈ K, ‖γ' σ‖ = 1)
    (hh : ∀ s ∈ J, HasDerivWithinAt h (h' s) J s) (hh' : ContinuousOn h' J)
    (hh0 : ∀ s ∈ J, h' s ≠ 0) (hmaps : MapsTo h J K) (heq : ∀ s ∈ J, c s = γ (h s)) :
    ∃ b : ℝ, (∀ s ∈ J, h s = s + b) ∨ (∀ s ∈ J, h s = -s + b) := by
  rcases J.eq_empty_or_nonempty with hJe | ⟨s0, hs0⟩
  · exact ⟨0, Or.inl (by simp [hJe])⟩
  by_cases hnt : ∃ a ∈ J, ∃ b ∈ J, a < b
  swap
  · push Not at hnt
    refine ⟨h s0 - s0, Or.inl fun s hs => ?_⟩
    have h1 := hnt s hs s0 hs0
    have h2 := hnt s0 hs0 s hs
    have : s = s0 := le_antisymm h2 h1
    subst this; ring
  obtain ⟨a, ha, b, hb, hab⟩ := hnt
  have huniq : UniqueDiffOn ℝ J := by
    refine uniqueDiffOn_convex hJ.convex ⟨(a + b) / 2, ?_⟩
    have : Ioo a b ⊆ interior J := by
      rw [← interior_Icc]; exact interior_mono (hJ.out ha hb)
    exact this ⟨by linarith, by linarith⟩
  have habs : ∀ s ∈ J, h' s = 1 ∨ h' s = -1 := by
    intro s hs
    have hcomp : HasDerivWithinAt (γ ∘ h) (h' s • γ' (h s)) J s :=
      (hγ (h s) (hmaps hs)).scomp s (hh s hs) hmaps
    have hc' : HasDerivWithinAt (γ ∘ h) (T s) J s :=
      (hc s hs).congr (fun x hx => (heq x hx).symm) (heq s hs).symm
    have hTs : T s = h' s • γ' (h s) := (huniq s hs).eq_deriv _ hc' hcomp
    have hn := hT s hs
    rw [hTs, norm_smul, hγ' _ (hmaps hs), mul_one, Real.norm_eq_abs] at hn
    exact abs_eq (zero_le_one) |>.1 hn
  have hconst : ∀ (g : ℝ → ℝ) (g' : ℝ → ℝ), (∀ s ∈ J, HasDerivWithinAt g (g' s) J s) →
      (∀ s ∈ J, g' s = 0) → ∀ s ∈ J, g s = g s0 := by
    intro g g' hg hg0 s hs
    have := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le (C := 0) hg
      (fun x hx => by rw [hg0 x hx, norm_zero]) hJ.convex hs0 hs
    rw [zero_mul] at this
    exact sub_eq_zero.1 (norm_le_zero_iff.1 this)
  rcases habs s0 hs0 with hpos | hneg
  · have hall : ∀ s ∈ J, h' s = 1 := by
      intro s hs
      rcases habs s hs with h1 | h1
      · exact h1
      exfalso
      obtain ⟨z, hz, hz0⟩ := hJ.isPreconnected.intermediate_value hs hs0 hh'
        (show (0 : ℝ) ∈ Icc (h' s) (h' s0) by rw [h1, hpos]; norm_num)
      exact hh0 z hz hz0
    refine ⟨h s0 - s0, Or.inl fun s hs => ?_⟩
    have : h s - s = h s0 - s0 := hconst (fun s => h s - s) (fun s => h' s - 1)
      (fun s hs => (hh s hs).sub (hasDerivWithinAt_id s J))
      (fun s hs => by rw [hall s hs]; ring) s hs
    linarith
  · have hall : ∀ s ∈ J, h' s = -1 := by
      intro s hs
      rcases habs s hs with h1 | h1
      · exfalso
        obtain ⟨z, hz, hz0⟩ := hJ.isPreconnected.intermediate_value hs0 hs hh'
          (show (0 : ℝ) ∈ Icc (h' s0) (h' s) by rw [h1, hneg]; norm_num)
        exact hh0 z hz hz0
      · exact h1
    refine ⟨h s0 + s0, Or.inr fun s hs => ?_⟩
    have : h s + s = h s0 + s0 := hconst (fun s => h s + s) (fun s => h' s + 1)
      (fun s hs => (hh s hs).add (hasDerivWithinAt_id s J))
      (fun s hs => by rw [hall s hs]; ring) s hs
    linarith

/-- The airtime hill, labelled by ground position `x` in metres: the rail's centre line is at
`r(x) = (x, 20 (1 - (x/30)²))`, a hump 20 m high over 60 m of ground, `x` from `-30` to `30`. -/
noncomputable def hill (x : ℝ) : EuclideanSpace ℝ (Fin 2) :=
  !₂[x, 20 * (1 - (x / 30) ^ 2)]

/-- Helper: the hill's velocity. -/
theorem hill_hasDerivAt (x : ℝ) : HasDerivAt hill (!₂[1, -(2 * x / 45)]) x := by
  have h1 : HasDerivAt (fun y : ℝ => 20 * (1 - (y / 30) ^ 2)) (-(2 * x / 45)) x := by
    have := ((hasDerivAt_const x (1:ℝ)).sub (((hasDerivAt_id' x).div_const 30).pow 2)).const_mul 20
    convert this using 1
    simp; ring
  have hv : HasDerivAt (fun y : ℝ => (![y, 20 * (1 - (y / 30) ^ 2)] : Fin 2 → ℝ))
      (![1, -(2 * x / 45)]) x := by
    rw [hasDerivAt_pi]
    intro i
    fin_cases i
    · simpa using hasDerivAt_id' x
    · simpa using h1
  have := (PiLp.hasFDerivAt_toLp (𝕜 := ℝ) 2 (![x, 20 * (1 - (x / 30) ^ 2)] : Fin 2 → ℝ)).comp_hasDerivAt x hv
  have e : hill = WithLp.toLp 2 ∘ fun y : ℝ => (![y, 20 * (1 - (y / 30) ^ 2)] : Fin 2 → ℝ) := rfl
  rw [e]
  convert this using 1
  rfl

/-- Helper: the hill's speed. -/
theorem norm_deriv_hill (x : ℝ) : ‖deriv hill x‖ = Real.sqrt (1 + (2 * x / 45) ^ 2) := by
  rw [(hill_hasDerivAt x).deriv, EuclideanSpace.norm_eq]
  simp [Fin.sum_univ_two]

/-- Helper: an antiderivative of the hill's speed. -/
theorem antideriv (x : ℝ) :
    HasDerivAt (fun x : ℝ => 45 / 4 * (2 * x / 45 * Real.sqrt (1 + (2 * x / 45) ^ 2)
      + Real.arsinh (2 * x / 45))) (Real.sqrt (1 + (2 * x / 45) ^ 2)) x := by
  have hu : HasDerivAt (fun x : ℝ => 2 * x / 45) (2 / 45) x := by
    simpa using ((hasDerivAt_id x).const_mul 2).div_const 45
  have hpos : 0 < 1 + (2 * x / 45) ^ 2 := by positivity
  have hS : HasDerivAt (fun x : ℝ => Real.sqrt (1 + (2 * x / 45) ^ 2))
      ((2 * (2 * x / 45) * (2/45)) / (2 * Real.sqrt (1 + (2 * x / 45) ^ 2))) x := by
    have := ((hasDerivAt_const x (1:ℝ)).add (hu.pow 2)).sqrt hpos.ne'
    convert this using 1
    simp
  have := ((hu.mul hS).add hu.arsinh).const_mul (45 / 4)
  convert this using 1
  have hs0 : 0 < Real.sqrt (1 + (2 * x / 45) ^ 2) := Real.sqrt_pos.2 hpos
  have hsq := Real.sq_sqrt hpos.le
  rw [smul_eq_mul]
  generalize Real.sqrt (1 + (2 * x / 45) ^ 2) = S at hs0 hsq ⊢
  field_simp
  nlinarith [hsq]

/-- **The airtime hill's rail length.** Measured from the left foot `x = -30`, the rail up to
the top `x = 0` is exactly `45/4 · (20/9 + ln 3)` metres (about 37.359388 m), and the whole hill
to the right foot `x = 30` is exactly `45/2 · (20/9 + ln 3)` metres (about 74.718776 m): the
integral of the speed `|ṙ(x)| = √(1 + (2x/45)²)` in the ground clock. -/
theorem airtime_hill_rail_length :
    arcLength (deriv hill) (-30) 0 = 45 / 4 * (20 / 9 + Real.log 3) ∧
      arcLength (deriv hill) (-30) 30 = 45 / 2 * (20 / 9 + Real.log 3) := by
  have hint : ∀ a b : ℝ, arcLength (deriv hill) a b =
      45 / 4 * (2 * b / 45 * Real.sqrt (1 + (2 * b / 45) ^ 2) + Real.arsinh (2 * b / 45)) -
      45 / 4 * (2 * a / 45 * Real.sqrt (1 + (2 * a / 45) ^ 2) + Real.arsinh (2 * a / 45)) := by
    intro a b
    unfold arcLength
    simp_rw [norm_deriv_hill]
    exact intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => antideriv x)
      (Continuous.intervalIntegrable (by fun_prop) _ _)
  have hs : Real.sqrt (1 + (2 * 30 / 45) ^ 2) = 5 / 3 := by
    rw [show (1 : ℝ) + (2 * 30 / 45) ^ 2 = (5 / 3) ^ 2 by norm_num]
    exact Real.sqrt_sq (by norm_num)
  have hs' : Real.sqrt (1 + (2 * (-30) / 45) ^ 2) = 5 / 3 := by
    rw [show (1 : ℝ) + (2 * (-30) / 45) ^ 2 = (5 / 3) ^ 2 by norm_num]
    exact Real.sqrt_sq (by norm_num)
  have ha : Real.arsinh (2 * 30 / 45) = Real.log 3 := by
    rw [show (2 : ℝ) * 30 / 45 = 4 / 3 by norm_num, Real.arsinh,
      show (1 : ℝ) + (4 / 3) ^ 2 = (5 / 3) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
    norm_num
  have ha' : Real.arsinh (2 * (-30) / 45) = -Real.log 3 := by
    rw [show (2 : ℝ) * (-30) / 45 = -(2 * 30 / 45) by norm_num, Real.arsinh_neg, ha]
  rw [hint, hint, hs, hs', ha, ha']
  constructor
  · norm_num; ring
  · ring

-- The slope -2x/45 at the right foot x = 30 is -4/3.
example : -2 * (30 : ℚ) / 45 = -4 / 3 := by norm_num
-- The speed there: 1 + (4/3)^2 = 25/9 = (5/3)^2, so the stretch is 5/3 rail metres per ground metre.
example : 1 + ((4 : ℚ) / 3) ^ 2 = (5 / 3) ^ 2 := by norm_num
-- The unit tangent there: (1, -4/3) divided by 5/3 is (3/5, -4/5), and it has length one.
example : (1 : ℚ) / (5 / 3) = 3 / 5 ∧ (-4 / 3 : ℚ) / (5 / 3) = -4 / 5 ∧
    ((3 : ℚ) / 5) ^ 2 + (-4 / 5) ^ 2 = 1 := by norm_num
-- The first term of the half-hill formula: 4/3 · 5/3 = 20/9.
example : (4 : ℚ) / 3 * (5 / 3) = 20 / 9 := by norm_num
-- The second term: asinh(4/3) = ln(4/3 + √(1 + 16/9)) = ln(4/3 + 5/3) = ln 3.
example : Real.arsinh (4 / 3) = Real.log 3 := by
  rw [Real.arsinh, show (1 : ℝ) + (4 / 3) ^ 2 = (5 / 3) ^ 2 by norm_num,
    Real.sqrt_sq (by norm_num)]
  norm_num
-- The half-hill factor: 45/4 = 11.25, and the whole hill is twice the half hill.
example : (45 : ℚ) / 4 = 1125 / 100 ∧ 2 * ((45 : ℚ) / 4) = 45 / 2 := by norm_num
-- The cusp (t², t³) has velocity (2t, 3t²), which is (0, 0) at t = 0: it stalls.
example : (2 * (0 : ℚ), 3 * (0 : ℚ) ^ 2) = (0, 0) := by norm_num
-- The cusp's length from t = 0 to 1 is (13^(3/2) - 8)/27; here 13³ = 2197 and 8² = 64.
example : (13 : ℕ) ^ 3 = 2197 ∧ (8 : ℕ) = 2 ^ 3 := by norm_num
-- The straight rail (t³, t³) has velocity (3t², 3t²), which is zero at t = 0: the clock stalls.
example : 3 * (0 : ℚ) ^ 2 = 0 := by norm_num
-- Chords: four times as many chords fall short 4² = 16 times less.
example : ((4096 : ℚ) / 1024) ^ 2 = 16 := by norm_num

#print axioms hasDerivWithinAt_integral_of_ordConnected
#print axioms regular_curve_relabels_by_arc_length_to_unit_speed
#print axioms unit_speed_relabelling_unique_up_to_start_and_direction
#print axioms hill_hasDerivAt
#print axioms norm_deriv_hill
#print axioms antideriv
#print axioms airtime_hill_rail_length

end RegularCurvesAndArcLength
