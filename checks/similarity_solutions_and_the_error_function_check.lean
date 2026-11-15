-- Similarity solutions: the error-function profile solves the half-line step problem for the heat equation and looks the same at every scale, the stretch x to λx, t to λ²t maps solutions to solutions, and a one-variable profile F(x/(2√(κt))) that solves it must be that error function.
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.Deriv.CompMul
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.IntegralEqImproper

open Real MeasureTheory Filter Topology

/-- The error function, as the card defines it: erf z = (2/√π) ∫₀^z e^(-s^2) ds. -/
noncomputable def erf (z : ℝ) : ℝ :=
  2 / Real.sqrt π * ∫ s in (0 : ℝ)..z, Real.exp (-s ^ 2)

/-- The card's answer: T(x, t) = T_J − (T_J − T_C) erf(x / (2√(κt))). -/
noncomputable def stepProfile (κ TJ TC : ℝ) (x t : ℝ) : ℝ :=
  TJ - (TJ - TC) * erf (x / (2 * Real.sqrt (κ * t)))

/-- The card's problem on the half-line x > 0: T is a bounded classical solution of
T_t = κ T_xx for x > 0, t > 0, with its end held at T_J, starting at T_C, and tending to T_C far
away. Classical means twice differentiable in x, differentiable in t, and taking the data
continuously everywhere except the corner (0, 0). -/
def SolvesStepProblem (κ TJ TC : ℝ) (T : ℝ → ℝ → ℝ) : Prop :=
  (∀ t, 0 < t → ContDiffOn ℝ 2 (fun x => T x t) (Set.Ioi 0)) ∧
  (∀ x t, 0 < x → 0 < t →
    HasDerivAt (fun s => T x s) (κ * deriv (deriv (fun z => T z t)) x) t) ∧
  (∀ t, 0 < t → T 0 t = TJ) ∧
  (∀ t₀, 0 < t₀ → Tendsto (fun p : ℝ × ℝ => T p.1 p.2)
    (𝓝[Set.Ioi (0 : ℝ) ×ˢ Set.Ioi (0 : ℝ)] (0, t₀)) (𝓝 TJ)) ∧
  (∀ x₀, 0 < x₀ → Tendsto (fun p : ℝ × ℝ => T p.1 p.2)
    (𝓝[Set.Ioi (0 : ℝ) ×ˢ Set.Ioi (0 : ℝ)] (x₀, 0)) (𝓝 TC)) ∧
  (∀ t, 0 < t → Tendsto (fun x => T x t) atTop (𝓝 TC)) ∧
  (∃ M, ∀ x t, 0 ≤ x → 0 < t → |T x t| ≤ M)

lemma erf_hasDerivAt (z : ℝ) : HasDerivAt erf (2 / Real.sqrt π * Real.exp (-z ^ 2)) z := by
  have hc : Continuous fun s : ℝ => Real.exp (-s ^ 2) := by fun_prop
  exact ((hc.integral_hasStrictDerivAt 0 z).hasDerivAt).const_mul (2 / Real.sqrt π)

lemma erf_differentiable : Differentiable ℝ erf := fun z => (erf_hasDerivAt z).differentiableAt

lemma deriv_erf : deriv erf = fun z => 2 / Real.sqrt π * Real.exp (-z ^ 2) :=
  funext fun z => (erf_hasDerivAt z).deriv

lemma erf_contDiff : ContDiff ℝ 2 erf := by
  have h : ContDiff ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) erf := by
    rw [contDiff_infty_iff_deriv]
    refine ⟨erf_differentiable, ?_⟩
    rw [deriv_erf]
    fun_prop
  exact h.of_le (WithTop.coe_le_coe.mpr le_top)

lemma erf_zero : erf 0 = 0 := by simp [erf]

lemma erf_monotone : Monotone erf :=
  monotone_of_deriv_nonneg erf_differentiable (fun z => by rw [deriv_erf]; positivity)

lemma gaussian_interval_tendsto :
    Tendsto (fun z => ∫ s in (0 : ℝ)..z, Real.exp (-s ^ 2)) atTop (𝓝 (Real.sqrt π / 2)) := by
  have hi : IntegrableOn (fun s : ℝ => Real.exp (-s ^ 2)) (Set.Ioi 0) := by
    have := (integrable_exp_neg_mul_sq (b := 1) one_pos).integrableOn (s := Set.Ioi (0 : ℝ))
    simpa using this
  have h := intervalIntegral_tendsto_integral_Ioi 0 hi tendsto_id
  have hv : ∫ s in Set.Ioi (0 : ℝ), Real.exp (-s ^ 2) = Real.sqrt π / 2 := by
    have := integral_gaussian_Ioi 1
    simpa using this
  rw [hv] at h
  exact h

lemma erf_tendsto : Tendsto erf atTop (𝓝 1) := by
  have h2 := gaussian_interval_tendsto.const_mul (2 / Real.sqrt π)
  have hpi : Real.sqrt π ≠ 0 := (Real.sqrt_pos.mpr Real.pi_pos).ne'
  have : 2 / Real.sqrt π * (Real.sqrt π / 2) = 1 := by field_simp
  rw [this] at h2
  exact h2

lemma erf_nonneg {z : ℝ} (hz : 0 ≤ z) : 0 ≤ erf z := erf_zero ▸ erf_monotone hz

lemma erf_le_one (z : ℝ) : erf z ≤ 1 := erf_monotone.ge_of_tendsto erf_tendsto z

#print axioms erf_hasDerivAt
#print axioms erf_differentiable
#print axioms deriv_erf
#print axioms erf_contDiff
#print axioms erf_zero
#print axioms erf_monotone
#print axioms gaussian_interval_tendsto
#print axioms erf_tendsto
#print axioms erf_nonneg
#print axioms erf_le_one

/-- A step start is solved by the error function: with constant diffusivity κ > 0, a rod with no
length of its own (the half-line x > 0), its end held at T_J and its start at T_C, the profile
T_J − (T_J − T_C) erf(x/(2√(κt))) is a bounded classical solution, and it looks the same at every
scale: stretching distance by λ and time by λ² leaves every value unchanged. -/
theorem step_start_solved_by_erf_profile (κ TJ TC : ℝ) (hκ : 0 < κ) :
    SolvesStepProblem κ TJ TC (stepProfile κ TJ TC) ∧
    ∀ (l x t : ℝ), 0 < l → 0 < t →
      stepProfile κ TJ TC (l * x) (l ^ 2 * t) = stepProfile κ TJ TC x t := by
  have hpi : Real.sqrt π ≠ 0 := (Real.sqrt_pos.mpr Real.pi_pos).ne'
  refine ⟨⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩, ?_⟩
  · intro t ht
    unfold stepProfile
    exact (contDiff_const.sub (contDiff_const.mul
      (erf_contDiff.comp (contDiff_id.div_const _)))).contDiffOn
  · intro x t hx ht
    have hkt : 0 < κ * t := mul_pos hκ ht
    have hr0 : 0 < Real.sqrt (κ * t) := Real.sqrt_pos.mpr hkt
    have hr2 : Real.sqrt (κ * t) ^ 2 = κ * t := Real.sq_sqrt hkt.le
    have hd1 : ∀ z, HasDerivAt (fun z => stepProfile κ TJ TC z t)
        (-((TJ - TC) * (2 / Real.sqrt π * Real.exp (-(z / (2 * Real.sqrt (κ * t))) ^ 2) *
          (1 / (2 * Real.sqrt (κ * t)))))) z := by
      intro z
      exact (((erf_hasDerivAt _).comp z ((hasDerivAt_id z).div_const
        (2 * Real.sqrt (κ * t)))).const_mul (TJ - TC)).const_sub TJ
    have e1 : deriv (fun z => stepProfile κ TJ TC z t) = fun z =>
        -((TJ - TC) * (2 / Real.sqrt π * Real.exp (-(z / (2 * Real.sqrt (κ * t))) ^ 2) *
          (1 / (2 * Real.sqrt (κ * t))))) := funext fun z => (hd1 z).deriv
    have h2 := (((((((hasDerivAt_id x).div_const (2 * Real.sqrt (κ * t))).pow 2).neg.exp).const_mul
      (2 / Real.sqrt π)).mul_const (1 / (2 * Real.sqrt (κ * t)))).const_mul (TJ - TC)).neg
    have h2' : HasDerivAt (fun z => -((TJ - TC) * (2 / Real.sqrt π *
        Real.exp (-(z / (2 * Real.sqrt (κ * t))) ^ 2) * (1 / (2 * Real.sqrt (κ * t)))))) _ x := h2
    rw [e1, h2'.deriv]
    have hs1 : HasDerivAt (fun s => κ * s) κ t := by
      simpa using (hasDerivAt_id t).const_mul κ
    have hs2 := (hs1.sqrt hkt.ne').const_mul 2
    have hs3 := (hasDerivAt_const t x).div hs2 (by positivity)
    have hs4 := (((erf_hasDerivAt _).comp t hs3).const_mul (TJ - TC)).const_sub TJ
    refine hs4.congr_deriv ?_
    simp only [Pi.div_apply, Pi.pow_apply, Pi.neg_apply, id, Nat.cast_ofNat]
    field_simp
    rw [show (2 : ℕ) - 1 = 1 from rfl, pow_one]
    field_simp
    ring
  · intro t ht
    simp [stepProfile, erf]
  · intro t₀ ht₀
    have hden : (2 * Real.sqrt (κ * t₀)) ≠ 0 := by
      have : 0 < Real.sqrt (κ * t₀) := Real.sqrt_pos.mpr (mul_pos hκ ht₀)
      positivity
    have hc : ContinuousAt (fun p : ℝ × ℝ => p.1 / (2 * Real.sqrt (κ * p.2))) (0, t₀) :=
      ContinuousAt.div (by fun_prop) (by fun_prop) hden
    have h := (erf_contDiff.continuous.continuousAt.comp hc).tendsto
    have h' := (tendsto_const_nhds (x := TJ)).sub ((tendsto_const_nhds (x := TJ - TC)).mul h)
    have h'' := h'.mono_left (nhdsWithin_le_nhds (s := Set.Ioi (0 : ℝ) ×ˢ Set.Ioi (0 : ℝ)))
    simpa [Function.comp_def, erf_zero, stepProfile] using h''
  · intro x₀ hx₀
    have hden : Tendsto (fun p : ℝ × ℝ => 2 * Real.sqrt (κ * p.2))
        (𝓝[Set.Ioi (0 : ℝ) ×ˢ Set.Ioi (0 : ℝ)] (x₀, 0)) (𝓝[>] 0) := by
      rw [tendsto_nhdsWithin_iff]
      constructor
      · have : Continuous (fun p : ℝ × ℝ => 2 * Real.sqrt (κ * p.2)) := by fun_prop
        have h := this.tendsto (x₀, 0)
        simp only [mul_zero, Real.sqrt_zero] at h
        exact h.mono_left nhdsWithin_le_nhds
      · filter_upwards [self_mem_nhdsWithin] with p hp
        have : 0 < Real.sqrt (κ * p.2) := Real.sqrt_pos.mpr (mul_pos hκ hp.2)
        show 0 < 2 * Real.sqrt (κ * p.2)
        positivity
    have hnum : Tendsto (fun p : ℝ × ℝ => p.1)
        (𝓝[Set.Ioi (0 : ℝ) ×ˢ Set.Ioi (0 : ℝ)] (x₀, 0)) (𝓝 x₀) :=
      (continuous_fst.tendsto (x₀, 0)).mono_left nhdsWithin_le_nhds
    have hq := hnum.pos_mul_atTop hx₀ (tendsto_inv_nhdsGT_zero.comp hden)
    have h := erf_tendsto.comp hq
    have h' := (tendsto_const_nhds (x := TJ)).sub ((tendsto_const_nhds (x := TJ - TC)).mul h)
    simp only [mul_one, sub_sub_cancel] at h'
    refine h'.congr (fun p => ?_)
    simp [stepProfile, div_eq_mul_inv]
  · intro t ht
    have hc : 0 < 2 * Real.sqrt (κ * t) := by
      have : 0 < Real.sqrt (κ * t) := Real.sqrt_pos.mpr (mul_pos hκ ht)
      positivity
    have h := erf_tendsto.comp (tendsto_id.atTop_div_const hc)
    have h' := (tendsto_const_nhds (x := TJ)).sub ((tendsto_const_nhds (x := TJ - TC)).mul h)
    simp only [mul_one, sub_sub_cancel] at h'
    exact h'
  · refine ⟨|TJ| + |TJ - TC|, fun x t hx ht => ?_⟩
    have hc : 0 < 2 * Real.sqrt (κ * t) := by
      have : 0 < Real.sqrt (κ * t) := Real.sqrt_pos.mpr (mul_pos hκ ht)
      positivity
    have h0 := erf_nonneg (div_nonneg hx hc.le)
    have h1 := erf_le_one (x / (2 * Real.sqrt (κ * t)))
    unfold stepProfile
    calc |TJ - (TJ - TC) * erf (x / (2 * Real.sqrt (κ * t)))|
        ≤ |TJ| + |(TJ - TC) * erf (x / (2 * Real.sqrt (κ * t)))| := abs_sub _ _
      _ = |TJ| + |TJ - TC| * |erf (x / (2 * Real.sqrt (κ * t)))| := by rw [abs_mul]
      _ ≤ |TJ| + |TJ - TC| * 1 := by
          gcongr
          rw [abs_le]
          constructor <;> linarith
      _ = |TJ| + |TJ - TC| := by ring
  · intro l x t hl ht
    unfold stepProfile
    have hkt : 0 < κ * t := mul_pos hκ ht
    have hr0 : 0 < Real.sqrt (κ * t) := Real.sqrt_pos.mpr hkt
    have hs : Real.sqrt (κ * (l ^ 2 * t)) = l * Real.sqrt (κ * t) := by
      rw [show κ * (l ^ 2 * t) = l ^ 2 * (κ * t) by ring, Real.sqrt_mul (sq_nonneg l),
        Real.sqrt_sq hl.le]
    rw [hs]
    congr 2
    field_simp

/-- A problem with no ruler cannot tell a zoomed copy from itself: if T solves the half-line step
problem, then so does its stretched copy T(λx, λ²t) for every λ > 0, because the heat equation and
the data are both unchanged by the stretch. -/
theorem stretched_solution_solves_same_problem (κ TJ TC : ℝ) (hκ : 0 < κ) (T : ℝ → ℝ → ℝ)
    (hT : SolvesStepProblem κ TJ TC T) (l : ℝ) (hl : 0 < l) :
    SolvesStepProblem κ TJ TC (fun x t => T (l * x) (l ^ 2 * t)) := by
  obtain ⟨h1, h2, h3, h4, h5, h6, ⟨M, hM⟩⟩ := hT
  have hl2 : 0 < l ^ 2 := by positivity
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ⟨M, ?_⟩⟩
  · intro t ht
    have := h1 (l ^ 2 * t) (mul_pos hl2 ht)
    exact this.comp (contDiff_const.mul contDiff_id).contDiffOn (fun x hx => mul_pos hl hx)
  · intro x t hx ht
    have hd := h2 (l * x) (l ^ 2 * t) (mul_pos hl hx) (mul_pos hl2 ht)
    have hc : HasDerivAt (fun s => l ^ 2 * s) (l ^ 2) t := by
      simpa using (hasDerivAt_id t).const_mul (l ^ 2)
    have hcomp := hd.comp t hc
    have e1 : deriv (fun z => T (l * z) (l ^ 2 * t)) =
        fun z => l * deriv (fun z => T z (l ^ 2 * t)) (l * z) := by
      funext z
      exact deriv_comp_mul_left l (fun z => T z (l ^ 2 * t)) z
    have hdd : deriv (deriv (fun z => T (l * z) (l ^ 2 * t))) x =
        l * (l * deriv (deriv (fun z => T z (l ^ 2 * t))) (l * x)) := by
      rw [e1, deriv_const_mul_field']
      show l * deriv (fun z => deriv (fun z => T z (l ^ 2 * t)) (l * z)) x = _
      rw [deriv_comp_mul_left, smul_eq_mul]
    rw [hdd]
    exact hcomp.congr_deriv (by ring)
  · intro t ht
    show T (l * 0) (l ^ 2 * t) = TJ
    rw [mul_zero]
    exact h3 _ (mul_pos hl2 ht)
  · intro t₀ ht₀
    have hc : ContinuousWithinAt (fun p : ℝ × ℝ => (l * p.1, l ^ 2 * p.2))
        (Set.Ioi 0 ×ˢ Set.Ioi 0) (0, t₀) := by fun_prop
    have hmap := hc.tendsto_nhdsWithin (t := Set.Ioi 0 ×ˢ Set.Ioi 0)
      (fun p hp => ⟨mul_pos hl hp.1, mul_pos hl2 hp.2⟩)
    simp only [mul_zero] at hmap
    exact (h4 (l ^ 2 * t₀) (mul_pos hl2 ht₀)).comp hmap
  · intro x₀ hx₀
    have hc : ContinuousWithinAt (fun p : ℝ × ℝ => (l * p.1, l ^ 2 * p.2))
        (Set.Ioi 0 ×ˢ Set.Ioi 0) (x₀, 0) := by fun_prop
    have hmap := hc.tendsto_nhdsWithin (t := Set.Ioi 0 ×ˢ Set.Ioi 0)
      (fun p hp => ⟨mul_pos hl hp.1, mul_pos hl2 hp.2⟩)
    simp only [mul_zero] at hmap
    exact (h5 (l * x₀) (mul_pos hl hx₀)).comp hmap
  · intro t ht
    exact (h6 _ (mul_pos hl2 ht)).comp (tendsto_id.const_mul_atTop hl)
  · intro x t hx ht
    exact hM _ _ (mul_nonneg hl.le hx) (mul_pos hl2 ht)

/-- The heat equation shrinks to an ordinary differential equation, and the data force its
answer: if a profile u(x, t) = F(x/(2√(κt))) of one variable solves T_t = κ T_xx for x > 0, t > 0,
with F(0) = T_J at the end and F(η) → T_C far out, then F(η) = T_J − (T_J − T_C) erf(η) for η ≥ 0. -/
theorem similarity_profile_forced_to_erf (κ TJ TC : ℝ) (hκ : 0 < κ) (F : ℝ → ℝ)
    (hF : ContDiffOn ℝ 2 F (Set.Ici 0))
    (heq : ∀ x t, 0 < x → 0 < t →
      HasDerivAt (fun s => F (x / (2 * Real.sqrt (κ * s))))
        (κ * deriv (deriv (fun z => F (z / (2 * Real.sqrt (κ * t))))) x) t)
    (h0 : F 0 = TJ) (hinf : Tendsto F atTop (𝓝 TC)) :
    ∀ η, 0 ≤ η → F η = TJ - (TJ - TC) * erf η := by
  have hpi : Real.sqrt π ≠ 0 := (Real.sqrt_pos.mpr Real.pi_pos).ne'
  have hk : 0 < Real.sqrt κ := Real.sqrt_pos.mpr hκ
  have hk2 : Real.sqrt κ ^ 2 = κ := Real.sq_sqrt hκ.le
  have hFo : ContDiffOn ℝ 2 F (Set.Ioi 0) := hF.mono Set.Ioi_subset_Ici_self
  obtain ⟨hdiffF, -, hF1⟩ := (contDiffOn_succ_iff_deriv_of_isOpen (n := 1) isOpen_Ioi).1 hFo
  have hdiffF' : DifferentiableOn ℝ (deriv F) (Set.Ioi 0) := hF1.differentiableOn (by norm_num)
  have hdF : ∀ η, 0 < η → HasDerivAt F (deriv F η) η := fun η hη =>
    ((hdiffF η hη).differentiableAt (isOpen_Ioi.mem_nhds hη)).hasDerivAt
  -- the heat equation becomes F'' = -2 η F'
  have hode : ∀ η, 0 < η → deriv (deriv F) η = -2 * η * deriv F η := by
    intro η hη
    obtain ⟨c, hcdef⟩ : ∃ c, c = 2 * Real.sqrt (κ * 1) := ⟨_, rfl⟩
    have hc : c = 2 * Real.sqrt κ := by rw [hcdef, mul_one]
    have hc0 : 0 < c := by rw [hc]; positivity
    obtain ⟨x, hxdef⟩ : ∃ x, x = c * η := ⟨_, rfl⟩
    have hx : 0 < x := by rw [hxdef]; exact mul_pos hc0 hη
    have hxc : x / c = η := by rw [hxdef]; field_simp
    have h := heq x 1 hx one_pos
    rw [← hcdef] at h
    have e1 : deriv (fun z => F (z / c)) = fun z => c⁻¹ * deriv F (c⁻¹ * z) := by
      funext z
      have := deriv_comp_mul_left c⁻¹ F z
      rw [smul_eq_mul] at this
      rw [← this]
      congr 1
      funext w
      rw [div_eq_inv_mul]
    have e2 : deriv (deriv (fun z => F (z / c))) x = c⁻¹ * (c⁻¹ * deriv (deriv F) η) := by
      rw [e1, deriv_const_mul_field']
      show c⁻¹ * deriv (fun z => deriv F (c⁻¹ * z)) x = _
      rw [deriv_comp_mul_left, smul_eq_mul, ← div_eq_inv_mul x c, hxc]
    rw [e2] at h
    have hs1 : HasDerivAt (fun s => κ * s) κ 1 := by
      simpa using (hasDerivAt_id (1 : ℝ)).const_mul κ
    have hs2 := (hs1.sqrt (by simpa using hκ.ne')).const_mul 2
    have hs3 := (hasDerivAt_const (1 : ℝ) x).div hs2 (by simp; positivity)
    have hF' : HasDerivAt F (deriv F (x / (2 * Real.sqrt (κ * 1)))) (x / (2 * Real.sqrt (κ * 1))) := by
      rw [← hcdef, hxc]; exact hdF η hη
    have h2 := hF'.comp (1 : ℝ) hs3
    have hu := h.unique h2
    rw [← hcdef, hxc] at hu
    have key : deriv (deriv F) η = c ^ 2 / κ * (κ * (c⁻¹ * (c⁻¹ * deriv (deriv F) η))) := by
      field_simp
    rw [key, hu, hxdef]
    field_simp
    ring
  -- e^(η²) F'(η) is constant on η > 0
  have hG : ∀ η, 0 < η → HasDerivAt (fun y => Real.exp (y ^ 2) * deriv F y) 0 η := by
    intro η hη
    have h1 : HasDerivAt (deriv F) (deriv (deriv F) η) η :=
      ((hdiffF' η hη).differentiableAt (isOpen_Ioi.mem_nhds hη)).hasDerivAt
    have h2 : HasDerivAt (fun y => Real.exp (y ^ 2)) (Real.exp (η ^ 2) * (2 * η)) η := by
      have := (hasDerivAt_pow 2 η).exp
      convert this using 1
      norm_num
    refine (h2.mul h1).congr_deriv ?_
    rw [hode η hη]
    ring
  obtain ⟨C, hC⟩ : ∃ C, ∀ η, 0 < η → deriv F η = C * Real.exp (-η ^ 2) := by
    obtain ⟨a, ha⟩ := isOpen_Ioi.exists_is_const_of_deriv_eq_zero isPreconnected_Ioi
      (f := fun y => Real.exp (y ^ 2) * deriv F y)
      (fun y hy => (hG y hy).differentiableAt.differentiableWithinAt)
      (fun y hy => (hG y hy).deriv)
    refine ⟨a, fun η hη => ?_⟩
    have h := ha η hη
    rw [← h, mul_comm, ← mul_assoc, ← Real.exp_add]
    simp
  -- integrate F' from 0
  have hFform : ∀ η, 0 ≤ η → F η = TJ + C * ∫ s in (0 : ℝ)..η, Real.exp (-s ^ 2) := by
    intro η hη
    have hcont : ContinuousOn F (Set.Icc 0 η) := hF.continuousOn.mono Set.Icc_subset_Ici_self
    have h := intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hη hcont
      (f' := fun s => C * Real.exp (-s ^ 2))
      (fun s hs => by rw [← hC s hs.1]; exact hdF s hs.1)
      (by apply Continuous.intervalIntegrable; fun_prop)
    rw [intervalIntegral.integral_const_mul] at h
    rw [h, h0]
    ring
  -- the far-field value fixes C
  have hlim : Tendsto F atTop (𝓝 (TJ + C * (Real.sqrt π / 2))) := by
    have := (gaussian_interval_tendsto.const_mul C).const_add TJ
    refine this.congr' ?_
    filter_upwards [eventually_ge_atTop 0] with η hη
    exact (hFform η hη).symm
  have hTC : TC = TJ + C * (Real.sqrt π / 2) := tendsto_nhds_unique hinf hlim
  intro η hη
  rw [hFform η hη, hTC]
  unfold erf
  field_simp
  ring

-- The card's exact arithmetic.
-- The joint of two equal rods at 100 C and 20 C sits at their average, 60 C; the drop is 40 C.
example : ((100 : ℚ) + 20) / 2 = 60 ∧ (60 : ℚ) - 20 = 40 := by norm_num
-- At the joint η = 0 and erf 0 = 0, so the profile reads 60 C.
example (κ t : ℝ) : stepProfile κ 60 20 0 t = 60 := by
  simp [stepProfile, erf]
-- The stretch λ = 2 takes (5 cm, 60 s) to (10 cm, 240 s); λ = 1/2 takes it to (2.5 cm, 15 s).
example : (2 : ℚ) * 5 = 10 ∧ (2 : ℚ) ^ 2 * 60 = 240 := by norm_num
example : (1 / 2 : ℚ) * 5 = 5 / 2 ∧ (1 / 2 : ℚ) ^ 2 * 60 = 15 := by norm_num
-- Twice the distance in twice the time is the wrong stretch: it needs λ² = 2 and λ = 2 at once.
example : (2 : ℚ) ^ 2 ≠ 2 := by norm_num
-- The powers of time: α − 1 = α − 2β forces β = 1/2.
example (α β : ℚ) (h : α - 1 = α - 2 * β) : β = 1 / 2 := by linarith
-- The constant in F' = C e^(-η^2): C √π / 2 = −40 gives C = −80/√π.
example : (-80 / Real.sqrt π) * Real.sqrt π / 2 = -40 := by
  have h : Real.sqrt π ≠ 0 := (Real.sqrt_pos.mpr Real.pi_pos).ne'
  field_simp
  norm_num
-- A hot rod at 200 C on a 20 C rod: joint (200 + 20)/2 = 110 C, drop 90 C.
example : ((200 : ℚ) + 20) / 2 = 110 ∧ (110 : ℚ) - 20 = 90 := by norm_num

#print axioms step_start_solved_by_erf_profile
#print axioms stretched_solution_solves_same_problem
#print axioms similarity_profile_forced_to_erf
