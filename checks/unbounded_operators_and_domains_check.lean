-- Unbounded operators: the derivative on square-integrable signals on (0, 1), with the ends held at zero, is closed and densely defined, and its adjoint is minus the derivative with no end conditions.
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.Analysis.InnerProductSpace.LinearPMap
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.AbsolutelyContinuousFun
import Mathlib.MeasureTheory.Integral.IntervalIntegral.LebesgueDifferentiationThm
import Mathlib.Analysis.Distribution.AEEqOfIntegralContDiff
import Mathlib.Analysis.Calculus.BumpFunction.Normed
import Mathlib.Analysis.InnerProductSpace.Projection.Submodule

open MeasureTheory Set
open scoped LinearPMap

noncomputable section

/-- The signals on the bar: `H = L²(0, 1)`, real functions on `(0, 1)` whose square has a
finite integral, two functions equal almost everywhere counting as one. -/
abbrev Bar : Type := Lp ℝ 2 (volume.restrict (Ioo (0 : ℝ) 1))

/-- A smooth probe: a smooth function whose support is a compact subset of `(0, 1)`,
so it vanishes near both ends. -/
def IsProbe (φ : ℝ → ℝ) : Prop :=
  ContDiff ℝ (⊤ : ℕ∞) φ ∧ HasCompactSupport φ ∧ tsupport φ ⊆ Ioo 0 1

/-- `g` is the weak derivative of `f` on `(0, 1)`: integration by parts against every smooth
probe, `∫ f φ' = -∫ g φ`. A signal with such a `g` in `L²` lies in `H¹(0, 1)`. -/
def HasWeakDeriv (f g : Bar) : Prop :=
  ∀ φ : ℝ → ℝ, IsProbe φ →
    ∫ x in Ioo (0 : ℝ) 1, f x * deriv φ x = -∫ x in Ioo (0 : ℝ) 1, g x * φ x

/-- `f` is zero at both ends: it agrees almost everywhere on `(0, 1)` with a function that is
continuous on `[0, 1]` and equals zero at `0` and at `1`. -/
def ZeroAtEnds (f : Bar) : Prop :=
  ∃ F : ℝ → ℝ, ContinuousOn F (Icc 0 1) ∧ F 0 = 0 ∧ F 1 = 0 ∧
    (f : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] F

lemma bar_integrableOn (f : Bar) : IntegrableOn (f : ℝ → ℝ) (Ioo 0 1) :=
  (Lp.memLp f).integrable one_le_two

lemma bar_intervalIntegrable (f : Bar) : IntervalIntegrable (f : ℝ → ℝ) volume 0 1 :=
  (intervalIntegrable_iff_integrableOn_Ioo_of_le zero_le_one).2 (bar_integrableOn f)

lemma inner_bar (f g : Bar) : inner ℝ f g = ∫ x in Ioo (0 : ℝ) 1, f x * g x := by
  rw [L2.inner_def]
  refine integral_congr_ae (Filter.Eventually.of_forall fun x => ?_)
  simp [mul_comm]

lemma inner_bar_ae (f v : Bar) (ψ : ℝ → ℝ) (hv : (v : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] ψ) :
    inner ℝ f v = ∫ x in Ioo (0 : ℝ) 1, f x * ψ x := by
  rw [inner_bar]
  refine integral_congr_ae ?_
  filter_upwards [hv] with x hx
  rw [hx]

lemma exists_toBar (ψ : ℝ → ℝ) (hψ : Continuous ψ) :
    ∃ v : Bar, (v : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] ψ := by
  obtain ⟨C, hC⟩ := (isCompact_Icc (a := (0:ℝ)) (b := 1)).exists_bound_of_continuousOn
    hψ.continuousOn
  have hm : MemLp ψ 2 (volume.restrict (Ioo (0 : ℝ) 1)) := by
    refine MemLp.of_bound hψ.aestronglyMeasurable C ?_
    rw [ae_restrict_iff' measurableSet_Ioo]
    exact Filter.Eventually.of_forall fun x hx => hC x (Ioo_subset_Icc_self hx)
  exact ⟨hm.toLp ψ, hm.coeFn_toLp⟩

lemma interval_eq_Ioo (f : ℝ → ℝ) :
    ∫ x in (0:ℝ)..1, f x = ∫ x in Ioo (0:ℝ) 1, f x := by
  rw [intervalIntegral.integral_of_le zero_le_one, integral_Ioc_eq_integral_Ioo]

lemma ac_ibp {k V : ℝ → ℝ} (hk : IntervalIntegrable k volume 0 1) (c : ℝ)
    (hV : AbsolutelyContinuousOnInterval V 0 1) :
    ∫ x in Ioo (0:ℝ) 1, (c + ∫ t in (0:ℝ)..x, k t) * deriv V x =
      (c + ∫ t in (0:ℝ)..1, k t) * V 1 - c * V 0 - ∫ x in Ioo (0:ℝ) 1, k x * V x := by
  have hP := hk.absolutelyContinuousOnInterval_intervalIntegral (c := 0) (by simp)
  have hF : AbsolutelyContinuousOnInterval (fun x => c + ∫ t in (0:ℝ)..x, k t) 0 1 := by
    have h1 : AbsolutelyContinuousOnInterval (fun _ : ℝ => c) 0 1 :=
      (LipschitzWith.const c).lipschitzOnWith.absolutelyContinuousOnInterval
    exact h1.add hP
  have h := hF.integral_mul_deriv_eq_deriv_mul hV
  have hd : ∫ x in (0:ℝ)..1, deriv (fun x => c + ∫ t in (0:ℝ)..x, k t) x * V x =
      ∫ x in (0:ℝ)..1, k x * V x := by
    refine intervalIntegral.integral_congr_ae ?_
    filter_upwards [hk.ae_hasDerivAt_integral] with x hx hxI
    have hx' := hx (uIoc_subset_uIcc hxI) 0 (by simp)
    rw [(hx'.const_add c).deriv]
  rw [hd] at h
  simp only [intervalIntegral.integral_same, add_zero] at h
  rw [← interval_eq_Ioo (fun x => (c + ∫ t in (0:ℝ)..x, k t) * deriv V x),
    ← interval_eq_Ioo (fun x => k x * V x)]
  exact h

lemma probe_eq_zero {φ : ℝ → ℝ} (hφ : IsProbe φ) {x : ℝ} (hx : x ∉ Ioo (0:ℝ) 1) : φ x = 0 :=
  image_eq_zero_of_notMem_tsupport fun h => hx (hφ.2.2 h)

lemma probe_zero {φ : ℝ → ℝ} (hφ : IsProbe φ) : φ 0 = 0 := probe_eq_zero hφ (by simp)

lemma probe_one {φ : ℝ → ℝ} (hφ : IsProbe φ) : φ 1 = 0 := probe_eq_zero hφ (by simp)

lemma probe_contDiff_one {φ : ℝ → ℝ} (hφ : IsProbe φ) : ContDiff ℝ 1 φ :=
  hφ.1.of_le (by exact_mod_cast le_top)

lemma probe_ac {φ : ℝ → ℝ} (hφ : IsProbe φ) : AbsolutelyContinuousOnInterval φ 0 1 :=
  (probe_contDiff_one hφ).contDiffOn.absolutelyContinuousOnInterval

lemma intOn_mul_cont {w φ : ℝ → ℝ} (hw : IntegrableOn w (Ioo (0:ℝ) 1)) (hφ : Continuous φ) :
    IntegrableOn (fun x => w x * φ x) (Ioo (0:ℝ) 1) :=
  hw.mul_continuousOn_of_subset hφ.continuousOn measurableSet_Ioo isCompact_Icc Ioo_subset_Icc_self

lemma fundamental {w : ℝ → ℝ} (hw : IntegrableOn w (Ioo (0:ℝ) 1))
    (h : ∀ φ, IsProbe φ → ∫ x in Ioo (0:ℝ) 1, w x * φ x = 0) :
    ∀ᵐ x ∂(volume.restrict (Ioo (0:ℝ) 1)), w x = 0 := by
  have := isOpen_Ioo.ae_eq_zero_of_integral_contDiff_smul_eq_zero (μ := volume)
    hw.locallyIntegrableOn ?_
  · rw [ae_restrict_iff' measurableSet_Ioo]; exact this
  intro g hg hgc hgs
  have h' := h g ⟨hg, hgc, hgs⟩
  rw [← setIntegral_eq_integral_of_forall_compl_eq_zero (s := Ioo (0:ℝ) 1)]
  · simpa [mul_comm] using h'
  · intro x hx; simp [image_eq_zero_of_notMem_tsupport (fun h => hx (hgs h))]

lemma smooth_ibp {u φ : ℝ → ℝ} (hu : ContDiff ℝ 1 u) (hφ : IsProbe φ) :
    ∫ x in Ioo (0:ℝ) 1, u x * deriv φ x = -∫ x in Ioo (0:ℝ) 1, deriv u x * φ x := by
  have hua : AbsolutelyContinuousOnInterval u 0 1 := hu.contDiffOn.absolutelyContinuousOnInterval
  have h := hua.integral_mul_deriv_eq_deriv_mul (probe_ac hφ)
  rw [interval_eq_Ioo, interval_eq_Ioo, probe_zero hφ, probe_one hφ] at h
  simpa using h

lemma hasWeakDeriv_smooth {u : ℝ → ℝ} (hu : ContDiff ℝ 1 u) (f g : Bar)
    (hf : (f : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] u)
    (hg : (g : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] deriv u) : HasWeakDeriv f g := by
  intro φ hφ
  have e1 : ∫ x in Ioo (0:ℝ) 1, f x * deriv φ x = ∫ x in Ioo (0:ℝ) 1, u x * deriv φ x :=
    integral_congr_ae (by filter_upwards [hf] with x hx; rw [hx])
  have e2 : ∫ x in Ioo (0:ℝ) 1, g x * φ x = ∫ x in Ioo (0:ℝ) 1, deriv u x * φ x :=
    integral_congr_ae (by filter_upwards [hg] with x hx; rw [hx])
  rw [e1, e2]
  exact smooth_ibp hu hφ

lemma exists_bump : ∃ ψ : ℝ → ℝ, IsProbe ψ ∧ ∫ x in Ioo (0:ℝ) 1, ψ x = 1 := by
  let b : ContDiffBump (1/2 : ℝ) := ⟨1/8, 1/4, by norm_num, by norm_num⟩
  have hsub : tsupport (b.normed volume) ⊆ Ioo 0 1 := by
    rw [b.tsupport_normed_eq]
    intro x hx
    rw [Metric.mem_closedBall, Real.dist_eq, abs_le] at hx
    have : b.rOut = 1/4 := rfl
    rw [this] at hx
    constructor <;> linarith [hx.1, hx.2]
  refine ⟨b.normed volume, ⟨b.contDiff_normed, b.hasCompactSupport_normed, hsub⟩, ?_⟩
  rw [setIntegral_eq_integral_of_forall_compl_eq_zero]
  · exact b.integral_normed
  · intro x hx; exact image_eq_zero_of_notMem_tsupport fun h => hx (hsub h)

lemma probe_sub_smul {ψ ψ₀ : ℝ → ℝ} (hψ : IsProbe ψ) (hψ₀ : IsProbe ψ₀) (a : ℝ) :
    IsProbe (fun x => ψ x - a * ψ₀ x) := by
  refine ⟨hψ.1.sub (contDiff_const.mul hψ₀.1), hψ.2.1.sub (hψ₀.2.1.mul_left), ?_⟩
  have hs : tsupport (fun x => ψ x - a * ψ₀ x) ⊆ tsupport ψ ∪ tsupport ψ₀ := by
    refine closure_minimal ?_ ((isClosed_tsupport _).union (isClosed_tsupport _))
    intro x hx
    by_contra hn
    simp only [mem_union, not_or] at hn
    apply hx
    simp [image_eq_zero_of_notMem_tsupport hn.1, image_eq_zero_of_notMem_tsupport hn.2]
  exact hs.trans (union_subset hψ.2.2 hψ₀.2.2)

lemma compact_in_Ioo {K : Set ℝ} (hK : IsCompact K) (hKs : K ⊆ Ioo 0 1) :
    ∃ a b : ℝ, 0 < a ∧ b < 1 ∧ K ⊆ Icc a b := by
  rcases K.eq_empty_or_nonempty with rfl | hne
  · exact ⟨1/2, 1/2, by norm_num, by norm_num, empty_subset _⟩
  obtain ⟨m, hm, hmin⟩ := hK.exists_isLeast hne
  obtain ⟨M, hM, hmax⟩ := hK.exists_isGreatest hne
  exact ⟨m, M, (hKs hm).1, (hKs hM).2, fun x hx => ⟨hmin hx, hmax hx⟩⟩

lemma probe_prim {χ : ℝ → ℝ} (hχ : IsProbe χ) (h0 : ∫ x in (0:ℝ)..1, χ x = 0) :
    IsProbe (fun x => ∫ t in (0:ℝ)..x, χ t) ∧ deriv (fun x => ∫ t in (0:ℝ)..x, χ t) = χ := by
  have hc : Continuous χ := hχ.1.continuous
  have hder : ∀ x, HasDerivAt (fun x => ∫ t in (0:ℝ)..x, χ t) (χ x) x :=
    fun x => (hc.integral_hasStrictDerivAt 0 x).hasDerivAt
  have hd : deriv (fun x => ∫ t in (0:ℝ)..x, χ t) = χ := funext fun x => (hder x).deriv
  refine ⟨⟨?_, ?_⟩, hd⟩
  · rw [contDiff_infty_iff_deriv, hd]
    exact ⟨fun x => (hder x).differentiableAt, hχ.1⟩
  obtain ⟨a, b, ha, hb, hK⟩ := compact_in_Ioo hχ.2.1 hχ.2.2
  have hz : ∀ x, x ∉ Icc a b → χ x = 0 := fun x hx =>
    image_eq_zero_of_notMem_tsupport fun h => hx (hK h)
  have hzero : ∀ x, x ∉ Icc a b → ∫ t in (0:ℝ)..x, χ t = 0 := by
    intro x hx
    rw [mem_Icc, not_and_or, not_le, not_le] at hx
    rcases hx with hx | hx
    · have : EqOn χ (fun _ => 0) (uIcc 0 x) := by
        intro t ht
        apply hz
        rw [mem_Icc, not_and_or, not_le]
        left
        rcases le_total 0 x with h | h
        · rw [uIcc_of_le h] at ht; linarith [ht.2]
        · rw [uIcc_of_ge h] at ht; linarith [ht.2]
      rw [intervalIntegral.integral_congr this]; simp
    · have hii : ∀ p q : ℝ, IntervalIntegrable χ volume p q := fun p q =>
        hc.intervalIntegrable p q
      rw [← intervalIntegral.integral_add_adjacent_intervals (hii 0 1) (hii 1 x), h0, zero_add]
      have : EqOn χ (fun _ => 0) (uIcc 1 x) := by
        intro t ht
        apply hz
        rw [mem_Icc, not_and_or, not_le]
        right
        rcases le_total 1 x with h | h
        · rw [uIcc_of_le h] at ht; linarith [ht.1]
        · rw [uIcc_of_ge h] at ht; linarith [ht.1]
      rw [intervalIntegral.integral_congr this]; simp
  have hsupp : tsupport (fun x => ∫ t in (0:ℝ)..x, χ t) ⊆ Icc a b := by
    refine closure_minimal ?_ isClosed_Icc
    intro x hx
    by_contra hn
    exact hx (hzero x hn)
  refine ⟨HasCompactSupport.intro isCompact_Icc hzero, ?_⟩
  exact hsupp.trans (Icc_subset_Ioo ha hb)

lemma prim_continuousOn (g : Bar) :
    ContinuousOn (fun x => ∫ t in (0:ℝ)..x, g t) (Icc 0 1) := by
  have := intervalIntegral.continuousOn_primitive_interval (μ := volume) (a := (0:ℝ)) (b := 1)
    (f := (g : ℝ → ℝ)) (by
      rw [uIcc_of_le zero_le_one, integrableOn_Icc_iff_integrableOn_Ioo]
      exact bar_integrableOn g)
  rwa [uIcc_of_le zero_le_one] at this

lemma rep {f g : Bar} (h : HasWeakDeriv f g) :
    ∃ c : ℝ, (f : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)]
      fun x => c + ∫ t in (0:ℝ)..x, g t := by
  set G : ℝ → ℝ := fun x => ∫ t in (0:ℝ)..x, g t with hGdef
  have hgi := bar_intervalIntegrable g
  have hGi : IntegrableOn G (Ioo (0:ℝ) 1) :=
    ((prim_continuousOn g).integrableOn_Icc).mono_set Ioo_subset_Icc_self
  have hwi : IntegrableOn (fun x => f x - G x) (Ioo (0:ℝ) 1) := (bar_integrableOn f).sub hGi
  have key : ∀ φ, IsProbe φ → ∫ x in Ioo (0:ℝ) 1, (f x - G x) * deriv φ x = 0 := by
    intro φ hφ
    have h1 := h φ hφ
    have h2 := ac_ibp hgi 0 (probe_ac hφ)
    rw [probe_zero hφ, probe_one hφ] at h2
    simp only [zero_add, mul_zero, sub_zero, zero_sub] at h2
    have hdc : Continuous (deriv φ) := hφ.1.continuous_deriv (by exact_mod_cast le_top)
    simp_rw [sub_mul]
    rw [integral_sub (intOn_mul_cont (bar_integrableOn f) hdc) (intOn_mul_cont hGi hdc), h1]
    rw [hGdef] at *
    rw [h2]; ring
  obtain ⟨ψ₀, hψ₀, hint⟩ := exists_bump
  set c := ∫ x in Ioo (0:ℝ) 1, (f x - G x) * ψ₀ x with hc
  refine ⟨c, ?_⟩
  have hz := fundamental (w := fun x => f x - G x - c) (hwi.sub (integrableOn_const (by simp)))
    (by
      intro ψ hψ
      set I := ∫ x in Ioo (0:ℝ) 1, ψ x with hI
      have hχ := probe_sub_smul hψ hψ₀ I
      have hψc : Continuous ψ := hψ.1.continuous
      have hψ₀c : Continuous ψ₀ := hψ₀.1.continuous
      have hψi : IntegrableOn ψ (Ioo (0:ℝ) 1) :=
        (hψc.continuousOn.integrableOn_Icc).mono_set Ioo_subset_Icc_self
      have hψ₀i : IntegrableOn ψ₀ (Ioo (0:ℝ) 1) :=
        (hψ₀c.continuousOn.integrableOn_Icc).mono_set Ioo_subset_Icc_self
      have hχ0 : ∫ x in (0:ℝ)..1, (ψ x - I * ψ₀ x) = 0 := by
        rw [interval_eq_Ioo, integral_sub hψi (hψ₀i.const_mul I), integral_const_mul, hint]
        ring
      obtain ⟨hΦ, hdΦ⟩ := probe_prim hχ hχ0
      have hk := key _ hΦ
      rw [hdΦ] at hk
      simp only [mul_sub] at hk
      rw [integral_sub (intOn_mul_cont hwi hψc) (intOn_mul_cont hwi (by fun_prop : Continuous (fun x => I * ψ₀ x)))]
        at hk
      have e : ∫ x in Ioo (0:ℝ) 1, (f x - G x) * (I * ψ₀ x) = I * c := by
        rw [hc, ← integral_const_mul]; congr 1; funext x; ring
      rw [e] at hk
      have e3 : ∫ x in Ioo (0:ℝ) 1, (f x - G x - c) * ψ x =
          (∫ x in Ioo (0:ℝ) 1, (f x - G x) * ψ x) - c * I := by
        rw [hI, ← integral_const_mul, ← integral_sub (intOn_mul_cont hwi hψc) (hψi.const_mul c)]
        congr 1; funext x; ring
      refine e3.trans ?_
      linarith)
  filter_upwards [hz] with x hx
  linarith

lemma weak_iff_inner (f g : Bar) : HasWeakDeriv f g ↔
    ∀ φ : ℝ → ℝ, IsProbe φ → ∀ v w : Bar,
      (v : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] deriv φ →
      (w : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] φ →
      inner ℝ f v = -inner ℝ g w := by
  constructor
  · intro h φ hφ v w hv hw
    rw [inner_bar_ae f v _ hv, inner_bar_ae g w _ hw]
    exact h φ hφ
  · intro h φ hφ
    obtain ⟨v, hv⟩ := exists_toBar (deriv φ) (hφ.1.continuous_deriv (by exact_mod_cast le_top))
    obtain ⟨w, hw⟩ := exists_toBar φ hφ.1.continuous
    have := h φ hφ v w hv hw
    rwa [inner_bar_ae f v _ hv, inner_bar_ae g w _ hw] at this

lemma weak_add {f g f' g' : Bar} (h : HasWeakDeriv f g) (h' : HasWeakDeriv f' g') :
    HasWeakDeriv (f + f') (g + g') := by
  rw [weak_iff_inner] at *
  intro φ hφ v w hv hw
  rw [inner_add_left, inner_add_left, h φ hφ v w hv hw, h' φ hφ v w hv hw]
  ring

lemma weak_smul {f g : Bar} (a : ℝ) (h : HasWeakDeriv f g) : HasWeakDeriv (a • f) (a • g) := by
  rw [weak_iff_inner] at *
  intro φ hφ v w hv hw
  rw [real_inner_smul_left, real_inner_smul_left, h φ hφ v w hv hw]
  ring

lemma weak_zero : HasWeakDeriv 0 0 := by
  rw [weak_iff_inner]
  intro φ hφ v w hv hw
  simp

lemma weak_zero_left {g : Bar} (h : HasWeakDeriv 0 g) : g = 0 := by
  rw [Lp.eq_zero_iff_ae_eq_zero]
  refine fundamental (bar_integrableOn g) fun φ hφ => ?_
  have h1 := h φ hφ
  have e : ∫ x in Ioo (0:ℝ) 1, (0 : Bar) x * deriv φ x = 0 := by
    rw [integral_congr_ae (g := fun _ => (0:ℝ))]
    · simp
    · filter_upwards [Lp.coeFn_zero ℝ 2 (volume.restrict (Ioo (0 : ℝ) 1))] with x hx
      rw [hx]; simp
  linarith

lemma zae_add {f f' : Bar} (h : ZeroAtEnds f) (h' : ZeroAtEnds f') : ZeroAtEnds (f + f') := by
  obtain ⟨F, hc, h0, h1, hF⟩ := h
  obtain ⟨F', hc', h0', h1', hF'⟩ := h'
  refine ⟨fun x => F x + F' x, hc.add hc', by simp [h0, h0'], by simp [h1, h1'], ?_⟩
  filter_upwards [Lp.coeFn_add f f', hF, hF'] with x hx h2 h3
  rw [hx, Pi.add_apply, h2, h3]

lemma zae_smul {f : Bar} (a : ℝ) (h : ZeroAtEnds f) : ZeroAtEnds (a • f) := by
  obtain ⟨F, hc, h0, h1, hF⟩ := h
  refine ⟨fun x => a * F x, continuousOn_const.mul hc, by simp [h0], by simp [h1], ?_⟩
  filter_upwards [Lp.coeFn_smul a f, hF] with x hx h2
  rw [hx, Pi.smul_apply, h2, smul_eq_mul]

lemma zae_zero : ZeroAtEnds 0 := by
  refine ⟨fun _ => 0, continuousOn_const, rfl, rfl, ?_⟩
  filter_upwards [Lp.coeFn_zero ℝ 2 (volume.restrict (Ioo (0 : ℝ) 1))] with x hx
  rw [hx]; rfl

lemma exists_weak_submodule : ∃ S : Submodule ℝ (Bar × Bar),
    ∀ p : Bar × Bar, p ∈ S ↔ HasWeakDeriv p.1 p.2 :=
  ⟨{ carrier := {p | HasWeakDeriv p.1 p.2}
     add_mem' := fun ha hb => weak_add ha hb
     zero_mem' := weak_zero
     smul_mem' := fun a _ hp => weak_smul a hp }, fun _ => Iff.rfl⟩

lemma exists_zero_submodule : ∃ S : Submodule ℝ (Bar × Bar),
    ∀ p : Bar × Bar, p ∈ S ↔ ZeroAtEnds p.1 ∧ HasWeakDeriv p.1 p.2 :=
  ⟨{ carrier := {p | ZeroAtEnds p.1 ∧ HasWeakDeriv p.1 p.2}
     add_mem' := fun ha hb => ⟨zae_add ha.1 hb.1, weak_add ha.2 hb.2⟩
     zero_mem' := ⟨zae_zero, weak_zero⟩
     smul_mem' := fun a _ hp => ⟨zae_smul a hp.1, weak_smul a hp.2⟩ }, fun _ => Iff.rfl⟩

lemma mem_adjoint_graph (T : Bar →ₗ.[ℝ] Bar) (hT : Dense (T.domain : Set Bar)) (y z : Bar) :
    (y, z) ∈ T†.graph ↔ ∀ x w : Bar, (x, w) ∈ T.graph → inner ℝ z x = inner ℝ y w := by
  constructor
  · intro hyz x w hxw
    rw [LinearPMap.mem_graph_iff] at hyz hxw
    obtain ⟨y', hy1, hy2⟩ := hyz
    obtain ⟨x', hx1, hx2⟩ := hxw
    have := LinearPMap.adjoint_isFormalAdjoint hT y' x'
    simp only at hy1 hy2 hx1 hx2
    rw [← hy1, ← hy2, ← hx1, ← hx2]
    exact this
  · intro H
    have hy : y ∈ T†.domain :=
      LinearPMap.mem_adjoint_domain_of_exists y ⟨z, fun x => H x (T x) (T.mem_graph x)⟩
    have hval : T† ⟨y, hy⟩ = z :=
      LinearPMap.adjoint_apply_eq hT ⟨y, hy⟩ fun x => H x (T x) (T.mem_graph x)
    rw [LinearPMap.mem_graph_iff]
    exact ⟨⟨y, hy⟩, by simp [hval]⟩

lemma dense_of_probes (D : Submodule ℝ Bar)
    (h : ∀ φ : ℝ → ℝ, IsProbe φ → ∀ v : Bar,
      (v : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] φ → v ∈ D) :
    Dense (D : Set Bar) := by
  rw [Submodule.dense_iff_topologicalClosure_eq_top, Submodule.topologicalClosure_eq_top_iff,
    Submodule.eq_bot_iff]
  intro v hv
  rw [Submodule.mem_orthogonal] at hv
  rw [Lp.eq_zero_iff_ae_eq_zero]
  refine fundamental (bar_integrableOn v) fun φ hφ => ?_
  obtain ⟨w, hw⟩ := exists_toBar φ hφ.1.continuous
  have := hv w (h φ hφ w hw)
  rw [real_inner_comm, inner_bar_ae v w φ hw] at this
  exact this

lemma ac_const_prim {k : ℝ → ℝ} (hk : IntervalIntegrable k volume 0 1) (d : ℝ) :
    AbsolutelyContinuousOnInterval (fun x => d + ∫ t in (0:ℝ)..x, k t) 0 1 :=
  (LipschitzWith.const d).lipschitzOnWith.absolutelyContinuousOnInterval.add
    (hk.absolutelyContinuousOnInterval_intervalIntegral (c := 0) (by simp))

lemma deriv_prim_ae {k : ℝ → ℝ} (hk : IntervalIntegrable k volume 0 1) (d : ℝ) :
    ∀ᵐ x ∂(volume.restrict (Ioo (0 : ℝ) 1)),
      deriv (fun x => d + ∫ t in (0:ℝ)..x, k t) x = k x := by
  rw [ae_restrict_iff' measurableSet_Ioo]
  filter_upwards [hk.ae_hasDerivAt_integral] with x hx hxI
  have hx' := hx (by rw [uIcc_of_le zero_le_one]; exact Ioo_subset_Icc_self hxI) 0 (by simp)
  exact (hx'.const_add d).deriv

lemma master {g f f' k : Bar} {c d : ℝ}
    (hg : (g : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] fun x => c + ∫ t in (0:ℝ)..x, k t)
    (hf : (f : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] fun x => d + ∫ t in (0:ℝ)..x, f' t) :
    inner ℝ g f' = (c + ∫ t in (0:ℝ)..1, k t) * (d + ∫ t in (0:ℝ)..1, f' t) - c * d
      - inner ℝ k f := by
  have h := ac_ibp (bar_intervalIntegrable k) c (ac_const_prim (bar_intervalIntegrable f') d)
  simp only [intervalIntegral.integral_same, add_zero] at h
  rw [inner_bar, inner_bar]
  have e1 : ∫ x in Ioo (0:ℝ) 1, g x * f' x = ∫ x in Ioo (0:ℝ) 1,
      (c + ∫ t in (0:ℝ)..x, k t) * deriv (fun x => d + ∫ t in (0:ℝ)..x, f' t) x := by
    refine integral_congr_ae ?_
    filter_upwards [hg, deriv_prim_ae (bar_intervalIntegrable f') d] with x h1 h2
    rw [h1, h2]
  have e2 : ∫ x in Ioo (0:ℝ) 1, k x * f x = ∫ x in Ioo (0:ℝ) 1,
      k x * (d + ∫ t in (0:ℝ)..x, f' t) := by
    refine integral_congr_ae ?_
    filter_upwards [hf] with x h1
    rw [h1]
  rw [e1, e2, h]

lemma zeroAtEnds_rep {f : Bar} {a : ℝ → ℝ} {c : ℝ} (hz : ZeroAtEnds f)
    (hf : (f : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] fun x => c + ∫ t in (0:ℝ)..x, a t)
    (ha : ContinuousOn (fun x => ∫ t in (0:ℝ)..x, a t) (Icc 0 1)) :
    c = 0 ∧ c + ∫ t in (0:ℝ)..1, a t = 0 := by
  obtain ⟨F, hFc, hF0, hF1, hF⟩ := hz
  have hae : F =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] fun x => c + ∫ t in (0:ℝ)..x, a t :=
    hF.symm.trans hf
  have hc2 : ContinuousOn (fun x => c + ∫ t in (0:ℝ)..x, a t) (Icc 0 1) :=
    continuousOn_const.add ha
  have hEq := (Measure.eqOn_open_of_ae_eq hae isOpen_Ioo (hFc.mono Ioo_subset_Icc_self)
    (hc2.mono Ioo_subset_Icc_self)).of_subset_closure hFc hc2 Ioo_subset_Icc_self
    (by rw [closure_Ioo zero_ne_one])
  have e0 := hEq (left_mem_Icc.2 zero_le_one)
  have e1 := hEq (right_mem_Icc.2 zero_le_one)
  simp only [intervalIntegral.integral_same, add_zero] at e0 e1
  constructor <;> linarith

lemma weak_of_tests {g h : Bar}
    (H : ∀ φ : ℝ → ℝ, IsProbe φ → ∀ v v' : Bar,
      (v : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] φ →
      (v' : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] deriv φ →
      inner ℝ h v = inner ℝ g v') : HasWeakDeriv g (-h) := by
  intro φ hφ
  obtain ⟨v', hv'⟩ := exists_toBar (deriv φ) (hφ.1.continuous_deriv (by exact_mod_cast le_top))
  obtain ⟨v, hv⟩ := exists_toBar φ hφ.1.continuous
  have := H φ hφ v v' hv hv'
  rw [inner_bar_ae h v φ hv, inner_bar_ae g v' _ hv'] at this
  have e : ∫ x in Ioo (0:ℝ) 1, (-h : Bar) x * φ x = ∫ x in Ioo (0:ℝ) 1, -(h x * φ x) := by
    refine integral_congr_ae ?_
    filter_upwards [Lp.coeFn_neg h] with x hx
    rw [hx, Pi.neg_apply, neg_mul]
  rw [e, integral_neg, neg_neg, this]

lemma probe_in_graph (A : Bar →ₗ.[ℝ] Bar)
    (hA : ∀ f g : Bar, (f, g) ∈ A.graph ↔ HasWeakDeriv f g) {φ : ℝ → ℝ} (hφ : IsProbe φ)
    (v : Bar) (hv : (v : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] φ)
    (v' : Bar) (hv' : (v' : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] deriv φ) :
    (v, v') ∈ A.graph :=
  (hA v v').2 (hasWeakDeriv_smooth (probe_contDiff_one hφ) v v' hv hv')

lemma H1_dense (A : Bar →ₗ.[ℝ] Bar)
    (hA : ∀ f g : Bar, (f, g) ∈ A.graph ↔ HasWeakDeriv f g) : Dense (A.domain : Set Bar) := by
  refine dense_of_probes A.domain fun φ hφ v hv => ?_
  obtain ⟨v', hv'⟩ := exists_toBar (deriv φ) (hφ.1.continuous_deriv (by exact_mod_cast le_top))
  exact LinearPMap.mem_domain_iff.2 ⟨v', probe_in_graph A hA hφ v hv v' hv'⟩

lemma H1_op_exists : ∃ A : Bar →ₗ.[ℝ] Bar,
    (∀ f g : Bar, (f, g) ∈ A.graph ↔ HasWeakDeriv f g) ∧ A.IsClosed := by
  obtain ⟨S, hS⟩ := exists_weak_submodule
  have hS0 : ∀ (x : Bar × Bar) (_hx : x ∈ S) (_hx' : x.fst = 0), x.snd = 0 := by
    intro x hx hx0
    rw [hS, hx0] at hx
    exact weak_zero_left hx
  refine ⟨S.toLinearPMap, fun f g => by rw [Submodule.toLinearPMap_graph_eq S hS0, hS], ?_⟩
  unfold LinearPMap.IsClosed
  rw [Submodule.toLinearPMap_graph_eq S hS0]
  have : (S : Set (Bar × Bar)) = ⋂ (φ : ℝ → ℝ) (_ : IsProbe φ) (v : Bar) (w : Bar)
      (_ : (v : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] deriv φ)
      (_ : (w : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] φ),
      {p : Bar × Bar | inner ℝ p.1 v = -inner ℝ p.2 w} := by
    ext p
    simp only [SetLike.mem_coe, hS, weak_iff_inner, mem_iInter, mem_ofPred_eq]
  rw [this]
  refine isClosed_iInter fun φ => isClosed_iInter fun _ => isClosed_iInter fun v =>
    isClosed_iInter fun w => isClosed_iInter fun _ => isClosed_iInter fun _ => ?_
  exact isClosed_eq (continuous_fst.inner continuous_const)
    (continuous_snd.inner continuous_const).neg

lemma adj_H1 (A : Bar →ₗ.[ℝ] Bar)
    (hA : ∀ f g : Bar, (f, g) ∈ A.graph ↔ HasWeakDeriv f g) :
    ∀ g h : Bar, (g, h) ∈ A†.graph ↔ ZeroAtEnds g ∧ HasWeakDeriv g (-h) := by
  intro g h
  rw [mem_adjoint_graph A (H1_dense A hA)]
  constructor
  · intro H
    have hw : HasWeakDeriv g (-h) := weak_of_tests fun φ hφ v v' hv hv' =>
      H v v' (probe_in_graph A hA hφ v hv v' hv')
    refine ⟨?_, hw⟩
    obtain ⟨c, hc⟩ := rep hw
    obtain ⟨one, hone⟩ := exists_toBar (fun _ => (1:ℝ)) continuous_const
    obtain ⟨e, he⟩ := exists_toBar (fun x => x) continuous_id
    have hw1 : HasWeakDeriv one 0 := hasWeakDeriv_smooth (u := fun _ => (1:ℝ)) contDiff_const
      one 0 hone (by
        filter_upwards [Lp.coeFn_zero ℝ 2 (volume.restrict (Ioo (0 : ℝ) 1))] with x hx
        rw [hx]; simp)
    have hw2 : HasWeakDeriv e one := hasWeakDeriv_smooth (u := fun x => x) contDiff_id
      e one he (by filter_upwards [hone] with x hx; rw [hx]; simp)
    have h1 := H one 0 ((hA one 0).2 hw1)
    have h2 := H e one ((hA e one).2 hw2)
    rw [inner_zero_right, inner_bar_ae h one _ hone] at h1
    simp only [mul_one] at h1
    rw [inner_bar_ae h e _ he, inner_bar_ae g one _ hone] at h2
    have hK1 : ∫ t in (0:ℝ)..1, (-h : Bar) t = 0 := by
      rw [interval_eq_Ioo, integral_congr_ae (Lp.coeFn_neg h)]
      simp only [Pi.neg_apply]
      rw [integral_neg, h1, neg_zero]
    have hI := ac_ibp (bar_intervalIntegrable (-h)) c (V := fun x => x)
      (contDiff_id.contDiffOn.absolutelyContinuousOnInterval)
    have e1 : ∫ x in Ioo (0:ℝ) 1, g x * 1 = ∫ x in Ioo (0:ℝ) 1,
        (c + ∫ t in (0:ℝ)..x, (-h : Bar) t) * deriv (fun x => x) x := by
      refine integral_congr_ae ?_
      filter_upwards [hc] with x hx
      rw [hx]; simp
    have e2 : ∫ x in Ioo (0:ℝ) 1, (-h : Bar) x * x = -∫ x in Ioo (0:ℝ) 1, h x * x := by
      rw [← integral_neg]
      refine integral_congr_ae ?_
      filter_upwards [Lp.coeFn_neg h] with x hx
      rw [hx, Pi.neg_apply, neg_mul]
    rw [hK1, e2] at hI
    have hc0 : c = 0 := by linarith
    refine ⟨fun x => c + ∫ t in (0:ℝ)..x, (-h : Bar) t,
      continuousOn_const.add (prim_continuousOn _), by simp [hc0],
      by show c + ∫ t in (0:ℝ)..1, (-h : Bar) t = 0; rw [hK1, hc0, add_zero], hc⟩
  · rintro ⟨hz, hw⟩ f f' hff'
    rw [hA] at hff'
    obtain ⟨c, hc⟩ := rep hw
    obtain ⟨hc0, hc1⟩ := zeroAtEnds_rep hz hc (prim_continuousOn _)
    obtain ⟨d, hd⟩ := rep hff'
    rw [master hc hd, hc1, hc0, inner_neg_left]
    ring

/-- Main claim. Let `A = d/dx` on `L²(0, 1)` with domain `H¹₀(0, 1)` (signals with a
square-integrable weak slope that are zero at both ends). Such an operator exists; its domain is
dense; it is closed; and its adjoint is `A* = -d/dx` on all of `H¹(0, 1)`, with no end
conditions: `g` is in `D(A*)` with `A* g = h` exactly when `g` has weak derivative `-h`. -/
theorem adjoint_of_derivative_with_zero_ends :
    ∃ A : Bar →ₗ.[ℝ] Bar,
      (∀ f g : Bar, (f, g) ∈ A.graph ↔ ZeroAtEnds f ∧ HasWeakDeriv f g) ∧
      Dense (A.domain : Set Bar) ∧ A.IsClosed ∧
      ∀ g h : Bar, (g, h) ∈ A†.graph ↔ HasWeakDeriv g (-h) := by
  obtain ⟨S, hS⟩ := exists_zero_submodule
  have hS0 : ∀ (x : Bar × Bar) (_hx : x ∈ S) (_hx' : x.fst = 0), x.snd = 0 := by
    intro x hx hx0
    rw [hS, hx0] at hx
    exact weak_zero_left hx.2
  have hgr := Submodule.toLinearPMap_graph_eq S hS0
  have hprobe : ∀ φ : ℝ → ℝ, IsProbe φ → ∀ v v' : Bar,
      (v : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] φ →
      (v' : ℝ → ℝ) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)] deriv φ →
      (v, v') ∈ S.toLinearPMap.graph := by
    intro φ hφ v v' hv hv'
    rw [hgr, hS]
    exact ⟨⟨φ, hφ.1.continuous.continuousOn, probe_zero hφ, probe_one hφ, hv⟩,
      hasWeakDeriv_smooth (probe_contDiff_one hφ) v v' hv hv'⟩
  have hdense : Dense (S.toLinearPMap.domain : Set Bar) := by
    refine dense_of_probes _ fun φ hφ v hv => ?_
    obtain ⟨v', hv'⟩ :=
      exists_toBar (deriv φ) (hφ.1.continuous_deriv (by exact_mod_cast le_top))
    exact LinearPMap.mem_domain_iff.2 ⟨v', hprobe φ hφ v v' hv hv'⟩
  obtain ⟨B, hB, -⟩ := H1_op_exists
  refine ⟨S.toLinearPMap, fun f g => by rw [hgr, hS], hdense, ?_, ?_⟩
  · unfold LinearPMap.IsClosed
    rw [hgr]
    have : (S : Set (Bar × Bar)) = (fun p : Bar × Bar => (p.1, -p.2)) ⁻¹' (B†.graph : Set _) := by
      ext p
      simp only [SetLike.mem_coe, mem_preimage, hS, adj_H1 B hB, neg_neg]
    rw [this]
    exact (LinearPMap.adjoint_isClosed (H1_dense B hB)).preimage
      (continuous_fst.prodMk continuous_snd.neg)
  · intro g h
    rw [mem_adjoint_graph _ hdense]
    constructor
    · intro H
      exact weak_of_tests fun φ hφ v v' hv hv' => H v v' (hprobe φ hφ v v' hv hv')
    · intro hw f f' hff'
      rw [hgr, hS] at hff'
      obtain ⟨hz, hff⟩ := hff'
      obtain ⟨c, hc⟩ := rep hw
      obtain ⟨d, hd⟩ := rep hff
      obtain ⟨hd0, hd1⟩ := zeroAtEnds_rep hz hd (prim_continuousOn _)
      rw [master hc hd, hd1, hd0, inner_neg_left]
      ring

/-- The derivative on its natural domain is closed: `A = d/dx` with domain `H¹(0, 1)` exists as
an operator on `L²(0, 1)`, and whenever `fₖ → f` and `fₖ' → g` in size, `f` is in `H¹(0, 1)`
with `f' = g`. -/
theorem derivative_on_H1_is_closed :
    ∃ A : Bar →ₗ.[ℝ] Bar,
      (∀ f g : Bar, (f, g) ∈ A.graph ↔ HasWeakDeriv f g) ∧ A.IsClosed := by
  exact H1_op_exists

/-- Move the end conditions and the adjoint moves them back: for `A = d/dx` with domain all of
`H¹(0, 1)`, the adjoint is `A* = -d/dx` with domain `H¹₀(0, 1)`, so `g` must be zero at both
ends. -/
theorem adjoint_of_derivative_without_end_conditions (A : Bar →ₗ.[ℝ] Bar)
    (hA : ∀ f g : Bar, (f, g) ∈ A.graph ↔ HasWeakDeriv f g) :
    ∀ g h : Bar, (g, h) ∈ A†.graph ↔ ZeroAtEnds g ∧ HasWeakDeriv g (-h) := by
  exact adj_H1 A hA

/-! The card's exact worked numbers. With `f = x` and `g = x²` (no end conditions on `f`):
`⟨f', g⟩ = 1/3`, `⟨f, -g'⟩ = -2/3`, and the gap is the end term `f(1)g(1) - f(0)g(0) = 1`. -/

example : ∫ x in (0 : ℝ)..1, (1 : ℝ) * x ^ 2 = 1 / 3 := by
  norm_num [integral_pow]

example : ∫ x in (0 : ℝ)..1, x * (-(2 * x)) = -2 / 3 := by
  have : (fun x : ℝ => x * (-(2 * x))) = fun x => -2 * x ^ 2 := by funext x; ring
  rw [this, intervalIntegral.integral_const_mul]; norm_num [integral_pow]

example : (1 : ℚ) / 3 - (-2 / 3) = 1 * 1 ^ 2 - 0 * 0 ^ 2 := by
  norm_num

#print axioms adjoint_of_derivative_with_zero_ends
#print axioms derivative_on_H1_is_closed
#print axioms adjoint_of_derivative_without_end_conditions
#print axioms bar_integrableOn
#print axioms bar_intervalIntegrable
#print axioms inner_bar
#print axioms inner_bar_ae
#print axioms exists_toBar
#print axioms interval_eq_Ioo
#print axioms ac_ibp
#print axioms probe_eq_zero
#print axioms probe_zero
#print axioms probe_one
#print axioms probe_contDiff_one
#print axioms probe_ac
#print axioms intOn_mul_cont
#print axioms fundamental
#print axioms smooth_ibp
#print axioms hasWeakDeriv_smooth
#print axioms exists_bump
#print axioms probe_sub_smul
#print axioms compact_in_Ioo
#print axioms probe_prim
#print axioms prim_continuousOn
#print axioms rep
#print axioms weak_iff_inner
#print axioms weak_add
#print axioms weak_smul
#print axioms weak_zero
#print axioms weak_zero_left
#print axioms zae_add
#print axioms zae_smul
#print axioms zae_zero
#print axioms exists_weak_submodule
#print axioms exists_zero_submodule
#print axioms mem_adjoint_graph
#print axioms dense_of_probes
#print axioms ac_const_prim
#print axioms deriv_prim_ae
#print axioms master
#print axioms zeroAtEnds_rep
#print axioms weak_of_tests
#print axioms probe_in_graph
#print axioms H1_dense
#print axioms H1_op_exists
#print axioms adj_H1
