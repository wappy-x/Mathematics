-- Turning and winding numbers: a closed plane loop's heading and its bearing from a point each turn a whole number of times, and these counts survive reshaping that never stops the loop or crosses the point; a loop without self-crossings turns exactly once.
import Mathlib.Analysis.Complex.CoveringMap
import Mathlib.Topology.Homotopy.Lifting
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse
import Mathlib.Topology.UniformSpace.HeineCantor
import Mathlib.Analysis.Calculus.ContDiff.RCLike
import Mathlib.Analysis.Calculus.Deriv.Shift
import Mathlib.Analysis.Calculus.LocalExtr.Basic
import Mathlib.Algebra.Order.ToIntervalMod

open Complex Set Function

/-! The plane is `ℂ`. A closed loop is a map `γ : ℝ → ℂ` with period `L` (`γ (s + L) = γ s`).
A stage-by-stage reshaping is `H : ℝ → ℝ → ℂ`, where `H u` is the loop at stage `u ∈ [0, 1]`.
The heading `θ` is a continuous angle with velocity `γ' s = |γ' s| · e^{iθ(s)}`; the bearing `α`
from a point `a` is a continuous angle with `γ s - a = |γ s - a| · e^{iα(s)}`. The turning number
is `(θ L - θ 0) / 2π` and the winding number round `a` is `(α L - α 0) / 2π`. -/

/-! ### Helper lemmas -/
/-- Two angles giving the same direction differ by a whole number of turns. -/
lemma tw_exp_eq_int {a b : ℝ} (h : exp (a * I) = exp (b * I)) :
    ∃ k : ℤ, a - b = 2 * Real.pi * k := by
  obtain ⟨n, hn⟩ := Complex.exp_eq_exp_iff_exists_int.mp h
  refine ⟨n, ?_⟩
  have := congrArg Complex.im hn
  simp at this
  linarith

/-- Two continuous angle functions giving the same direction differ by a constant. -/
lemma tw_lift_diff {X : Type*} [TopologicalSpace X] {S : Set X} (hS : IsPreconnected S)
    {f g : X → ℝ} (hf : ContinuousOn f S) (hg : ContinuousOn g S)
    (h : ∀ x ∈ S, exp (f x * I) = exp (g x * I)) {x y : X} (hx : x ∈ S) (hy : y ∈ S) :
    f x - g x = f y - g y := by
  have hint : ∀ z ∈ S, ∃ k : ℤ, f z - g z = 2 * Real.pi * k :=
    fun z hz => tw_exp_eq_int (h z hz)
  have hd : ContinuousOn (fun z => f z - g z) S := hf.sub hg
  have key : ∀ x ∈ S, ∀ y ∈ S, f x - g x < f y - g y → False := by
    intro x hx y hy hlt
    obtain ⟨m, hm⟩ := hint x hx
    obtain ⟨n, hn⟩ := hint y hy
    have hmn : m < n := by
      by_contra hc
      have : (n : ℝ) ≤ m := by exact_mod_cast (not_lt.mp hc)
      nlinarith [Real.pi_pos]
    have hmn' : (m : ℝ) + 1 ≤ n := by exact_mod_cast hmn
    have hmem : 2 * Real.pi * (m + 1 / 2) ∈ Icc (f x - g x) (f y - g y) := by
      constructor <;> nlinarith [Real.pi_pos]
    obtain ⟨z, hz, hzv⟩ := hS.intermediate_value hx hy hd hmem
    obtain ⟨k, hk⟩ := hint z hz
    have hzv' : f z - g z = 2 * Real.pi * (m + 1 / 2) := hzv
    have h1 : (k : ℝ) = m + 1 / 2 := by
      have := mul_left_cancel₀ (by positivity : (2 * Real.pi) ≠ 0) (hk.symm.trans hzv')
      exact this
    have h2 : ((2 * k : ℤ) : ℝ) = ((2 * m + 1 : ℤ) : ℝ) := by push_cast; linarith
    have h3 : 2 * k = 2 * m + 1 := by exact_mod_cast h2
    omega
  by_contra hne
  rcases lt_or_gt_of_ne hne with hlt | hlt
  · exact key x hx y hy hlt
  · exact key y hy x hx hlt

lemma tw_exp_arg_of_norm_one {z : ℂ} (h : ‖z‖ = 1) : exp (arg z * I) = z := by
  have := norm_mul_exp_arg_mul_I z
  rw [h] at this
  simpa using this

/-- A continuous nowhere-zero map on a compact convex set has a continuous angle. -/
lemma tw_exists_lift {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {K : Set E}
    (hK : IsCompact K) (hconv : Convex ℝ K) {p₀ : E} (hp₀ : p₀ ∈ K) {g : E → ℂ}
    (hg : ContinuousOn g K) (hne : ∀ p ∈ K, g p ≠ 0) :
    ∃ Θ : E → ℝ, ContinuousOn Θ K ∧ ∀ p ∈ K, g p = (‖g p‖ : ℂ) * exp (Θ p * I) := by
  set u : E → ℂ := fun p => g p / (‖g p‖ : ℂ) with hu_def
  have hnorm_ne : ∀ p ∈ K, (‖g p‖ : ℂ) ≠ 0 := fun p hp => by
    exact_mod_cast (norm_ne_zero_iff.mpr (hne p hp))
  have hu_cont : ContinuousOn u K :=
    hg.div (Complex.continuous_ofReal.comp_continuousOn hg.norm) hnorm_ne
  have hu_norm : ∀ p ∈ K, ‖u p‖ = 1 := by
    intro p hp
    simp only [hu_def, norm_div, Complex.norm_real, norm_norm]
    exact div_self (norm_ne_zero_iff.mpr (hne p hp))
  have hu_ne : ∀ p ∈ K, u p ≠ 0 := by
    intro p hp h
    have := hu_norm p hp
    rw [h, norm_zero] at this
    exact zero_ne_one this
  obtain ⟨δ, hδ, hδu⟩ := Metric.uniformContinuousOn_iff.mp
    (hK.uniformContinuousOn_of_continuous hu_cont) 1 one_pos
  obtain ⟨R, hR⟩ := (Metric.isBounded_iff_subset_closedBall p₀).mp hK.isBounded
  have hR0 : 0 ≤ R := by
    have := hR hp₀
    simpa using this
  obtain ⟨N, hN⟩ := exists_nat_gt (R / δ)
  have hNpos : (0 : ℝ) < N := lt_of_le_of_lt (div_nonneg hR0 hδ.le) hN
  set pt : ℕ → E → E := fun j p => p₀ + ((j : ℝ) / N) • (p - p₀) with hpt
  have hpt_mem : ∀ j ≤ N, ∀ p ∈ K, pt j p ∈ K := by
    intro j hj p hp
    apply hconv.add_smul_sub_mem hp₀ hp
    constructor
    · positivity
    · rw [div_le_one hNpos]
      exact_mod_cast hj
  have hpt_cont : ∀ j, Continuous (pt j) := fun j => by
    simp only [hpt]
    fun_prop
  have hstep : ∀ j, ∀ p ∈ K, dist (pt (j + 1) p) (pt j p) < δ := by
    intro j p hp
    have hdiff : pt (j + 1) p - pt j p = (1 / (N : ℝ)) • (p - p₀) := by
      simp only [hpt]
      rw [add_sub_add_left_eq_sub, ← sub_smul]
      congr 1
      push_cast
      ring
    rw [dist_eq_norm, hdiff, norm_smul]
    have hp' : ‖p - p₀‖ ≤ R := by
      have := hR hp
      rwa [Metric.mem_closedBall, dist_eq_norm] at this
    rw [Real.norm_eq_abs, abs_of_pos (by positivity)]
    have hRN : R < δ * N := by
      rw [div_lt_iff₀ hδ] at hN
      linarith
    calc 1 / (N : ℝ) * ‖p - p₀‖ ≤ 1 / N * R := by gcongr
      _ = R / N := by ring
      _ < δ := by rw [div_lt_iff₀ hNpos]; linarith
  set w : ℕ → E → ℂ := fun j p => u (pt (j + 1) p) / u (pt j p) with hw
  have hw_norm : ∀ j < N, ∀ p ∈ K, ‖w j p‖ = 1 := by
    intro j hj p hp
    simp only [hw, norm_div, hu_norm _ (hpt_mem (j + 1) hj p hp),
      hu_norm _ (hpt_mem j hj.le p hp), div_one]
  have hw_slit : ∀ j < N, ∀ p ∈ K, w j p ∈ slitPlane := by
    intro j hj p hp
    have h1 := hpt_mem (j + 1) hj p hp
    have h0 := hpt_mem j hj.le p hp
    have hd : ‖u (pt (j + 1) p) - u (pt j p)‖ < 1 := by
      rw [← dist_eq_norm]
      exact hδu _ h1 _ h0 (hstep j p hp)
    have hw1 : ‖w j p - 1‖ < 1 := by
      have : w j p - 1 = (u (pt (j + 1) p) - u (pt j p)) / u (pt j p) := by
        simp only [hw]
        field_simp [hu_ne _ h0]
      rw [this, norm_div, hu_norm _ h0, div_one]
      exact hd
    have hre : |(w j p - 1).re| < 1 := lt_of_le_of_lt (Complex.abs_re_le_norm _) hw1
    rw [Complex.sub_re, Complex.one_re] at hre
    rw [Complex.mem_slitPlane_iff]
    left
    linarith [(abs_lt.mp hre).1]
  refine ⟨fun p => arg (u p₀) + ∑ j ∈ Finset.range N, arg (w j p), ?_, ?_⟩
  · apply continuousOn_const.add
    apply continuousOn_finsetSum
    intro j hj
    have hj' := Finset.mem_range.mp hj
    intro p hp
    have h1 : ContinuousOn (fun p => u (pt (j + 1) p)) K :=
      hu_cont.comp (hpt_cont _).continuousOn (fun q hq => hpt_mem _ hj' q hq)
    have h0 : ContinuousOn (fun p => u (pt j p)) K :=
      hu_cont.comp (hpt_cont _).continuousOn (fun q hq => hpt_mem _ hj'.le q hq)
    have hwc : ContinuousWithinAt (w j) K p :=
      (h1.div h0 (fun q hq => hu_ne _ (hpt_mem _ hj'.le q hq))) p hp
    exact (continuousAt_arg (hw_slit j hj' p hp)).comp_continuousWithinAt hwc
  · intro p hp
    have key : ∀ n ≤ N,
        exp (((arg (u p₀) + ∑ j ∈ Finset.range n, arg (w j p) : ℝ) : ℂ) * I) = u (pt n p) := by
      intro n
      induction n with
      | zero =>
        intro _
        simp only [Finset.range_zero, Finset.sum_empty, add_zero, hpt, Nat.cast_zero, zero_div,
          zero_smul]
        exact tw_exp_arg_of_norm_one (hu_norm p₀ hp₀)
      | succ n ih =>
        intro hn
        rw [Finset.sum_range_succ, ← add_assoc, Complex.ofReal_add, add_mul, Complex.exp_add,
          ih (by omega), tw_exp_arg_of_norm_one (hw_norm n (by omega) p hp)]
        simp only [hw]
        field_simp [hu_ne _ (hpt_mem n (by omega) p hp)]
    have hptN : pt N p = p := by
      simp only [hpt]
      rw [div_self hNpos.ne', one_smul, add_sub_cancel]
    have := key N le_rfl
    rw [hptN] at this
    show g p = (‖g p‖ : ℂ) * exp (((arg (u p₀) + ∑ j ∈ Finset.range N, arg (w j p) : ℝ) : ℂ) * I)
    rw [this]
    simp only [hu_def]
    field_simp [hnorm_ne p hp]

/-- A unit-length angle from a polar form. -/
lemma tw_exp_eq_of_polar {z : ℂ} (hz : z ≠ 0) {a b : ℝ} (ha : z = (‖z‖ : ℂ) * exp (a * I))
    (hb : z = (‖z‖ : ℂ) * exp (b * I)) : exp (a * I) = exp (b * I) := by
  have hn : (‖z‖ : ℂ) ≠ 0 := by exact_mod_cast (norm_ne_zero_iff.mpr hz)
  exact mul_left_cancel₀ hn (ha.symm.trans hb)

lemma tw_deriv_periodic {f : ℝ → ℂ} {L : ℝ} (h : Periodic f L) (s : ℝ) :
    deriv f (s + L) = deriv f s := by
  have hf : (fun x => f (x + L)) = f := funext h
  rw [← deriv_comp_add_const, hf]


/-- The unit vector in the direction of `z`. -/
noncomputable def twUnit (z : ℂ) : ℂ := z / (‖z‖ : ℂ)

lemma tw_unit_norm {z : ℂ} (hz : z ≠ 0) : ‖twUnit z‖ = 1 := by
  simp only [twUnit, norm_div, Complex.norm_real, norm_norm]
  exact div_self (norm_ne_zero_iff.mpr hz)

lemma tw_unit_ne {z : ℂ} (hz : z ≠ 0) : twUnit z ≠ 0 := by
  intro h
  have := tw_unit_norm hz
  rw [h, norm_zero] at this
  exact zero_ne_one this

lemma tw_unit_continuousAt {z : ℂ} (hz : z ≠ 0) : ContinuousAt twUnit z := by
  have hn : (‖z‖ : ℂ) ≠ 0 := by exact_mod_cast (norm_ne_zero_iff.mpr hz)
  exact continuousAt_id.div (Complex.continuous_ofReal.comp continuous_norm).continuousAt hn

lemma tw_unit_im (z : ℂ) : (twUnit z).im = z.im / ‖z‖ := by
  simp only [twUnit, Complex.div_ofReal_im]

lemma tw_unit_div_pos (z : ℂ) {r : ℝ} (hr : 0 < r) : twUnit (z / (r : ℂ)) = twUnit z := by
  simp only [twUnit, norm_div, Complex.norm_real, Real.norm_eq_abs, abs_of_pos hr]
  have hr' : (r : ℂ) ≠ 0 := by exact_mod_cast hr.ne'
  rcases eq_or_ne z 0 with h | h
  · simp [h]
  have hz : (‖z‖ : ℂ) ≠ 0 := by exact_mod_cast (norm_ne_zero_iff.mpr h)
  push_cast
  field_simp

lemma tw_exp_eq_unit {z : ℂ} (hz : z ≠ 0) {a : ℝ} (h : z = (‖z‖ : ℂ) * exp (a * I)) :
    exp (a * I) = twUnit z := by
  have hn : (‖z‖ : ℂ) ≠ 0 := by exact_mod_cast (norm_ne_zero_iff.mpr hz)
  rw [twUnit, eq_div_iff hn, mul_comm]
  exact h.symm

lemma tw_exp_eq_self {z : ℂ} (h1 : ‖z‖ = 1) {a : ℝ} (h : z = (‖z‖ : ℂ) * exp (a * I)) :
    exp (a * I) = z := by
  rw [h1] at h
  simpa using h.symm

/-- On the closed upper half of the unit circle, `arccos` of the real part is an angle. -/
lemma tw_exp_arccos {z : ℂ} (h1 : ‖z‖ = 1) (him : 0 ≤ z.im) :
    exp (Real.arccos z.re * I) = z := by
  have hre := Complex.abs_re_le_norm z
  rw [h1] at hre
  have hsq : z.im ^ 2 = 1 - z.re ^ 2 := by
    have := Complex.sq_norm_sub_sq_re z
    rw [h1] at this
    linarith
  rw [Complex.exp_mul_I, ← Complex.ofReal_cos, ← Complex.ofReal_sin,
    Real.cos_arccos (abs_le.mp hre).1 (abs_le.mp hre).2, Real.sin_arccos, ← hsq,
    Real.sqrt_sq him]
  apply Complex.ext <;> simp

/-- On the closed lower half of the unit circle, minus `arccos` of the real part is an angle. -/
lemma tw_exp_neg_arccos {z : ℂ} (h1 : ‖z‖ = 1) (him : z.im ≤ 0) :
    exp ((-Real.arccos z.re : ℝ) * I) = z := by
  have hre := Complex.abs_re_le_norm z
  rw [h1] at hre
  have hsq : (-z.im) ^ 2 = 1 - z.re ^ 2 := by
    have := Complex.sq_norm_sub_sq_re z
    rw [h1] at this
    linarith
  rw [Complex.exp_mul_I, ← Complex.ofReal_cos, ← Complex.ofReal_sin, Real.cos_neg, Real.sin_neg,
    Real.cos_arccos (abs_le.mp hre).1 (abs_le.mp hre).2, Real.sin_arccos, ← hsq,
    Real.sqrt_sq (by linarith)]
  apply Complex.ext <;> simp

/-- The chord slope of a `C¹` curve, with the velocity on the diagonal, is continuous. -/
lemma tw_slope_continuous {γ : ℝ → ℂ} (hsmooth : ContDiff ℝ 1 γ) :
    Continuous (fun p : ℝ × ℝ =>
      if p.1 = p.2 then deriv γ p.1 else (γ p.2 - γ p.1) / ((p.2 - p.1 : ℝ) : ℂ)) := by
  have hγc : Continuous γ := hsmooth.continuous
  rw [continuous_iff_continuousAt]
  rintro ⟨x, y⟩
  by_cases hxy : x = y
  · subst hxy
    have hval : (if x = x then deriv γ x else (γ x - γ x) / ((x - x : ℝ) : ℂ)) = deriv γ x := by
      simp
    show Filter.Tendsto _ _
      (nhds (if x = x then deriv γ x else (γ x - γ x) / ((x - x : ℝ) : ℂ)))
    rw [hval]
    apply Filter.Tendsto.if
    · exact (((hsmooth.continuous_deriv le_rfl).tendsto x).comp
        (continuous_fst.tendsto (x, x))).mono_left inf_le_left
    · have hs : HasStrictDerivAt γ (deriv γ x) x :=
        hsmooth.contDiffAt.hasStrictDerivAt (by norm_num)
      have lo := hasDerivAtFilter_iff_isLittleO.mp hs
      have t := (lo.tendsto_inv_smul_nhds_zero.mono_left
        (inf_le_left : nhds (x, x) ⊓ Filter.principal {p : ℝ × ℝ | ¬p.1 = p.2} ≤ nhds (x, x))).add_const
        (deriv γ x)
      rw [zero_add] at t
      refine t.congr' ?_
      refine Filter.eventually_inf_principal.mpr (Filter.Eventually.of_forall ?_)
      intro p hp
      have h1 : (p.1 : ℂ) - p.2 ≠ 0 := sub_ne_zero.mpr (by exact_mod_cast hp)
      have h2 : (p.2 : ℂ) - p.1 ≠ 0 := sub_ne_zero.mpr (by exact_mod_cast (Ne.symm hp))
      simp only [Complex.real_smul]
      push_cast
      field_simp
      ring
  · have hopen : IsOpen {p : ℝ × ℝ | p.1 ≠ p.2} := isOpen_ne_fun continuous_fst continuous_snd
    have hev : (fun p : ℝ × ℝ => (γ p.2 - γ p.1) / ((p.2 - p.1 : ℝ) : ℂ)) =ᶠ[nhds (x, y)]
        (fun p : ℝ × ℝ =>
          if p.1 = p.2 then deriv γ p.1 else (γ p.2 - γ p.1) / ((p.2 - p.1 : ℝ) : ℂ)) := by
      filter_upwards [hopen.mem_nhds (show (x, y) ∈ {p : ℝ × ℝ | p.1 ≠ p.2} from hxy)] with p hp
      simp [hp]
    refine ContinuousAt.congr ?_ hev
    have hden : (((y - x : ℝ)) : ℂ) ≠ 0 := by
      exact_mod_cast sub_ne_zero.mpr (Ne.symm hxy)
    exact ((hγc.comp continuous_snd).sub (hγc.comp continuous_fst)).continuousAt.div
      (Complex.continuous_ofReal.comp (continuous_snd.sub continuous_fst)).continuousAt hden

/-- At a lowest point of a differentiable curve the velocity is horizontal. -/
lemma tw_im_deriv_zero_of_min {γ : ℝ → ℂ} (hd : Differentiable ℝ γ) {c : ℝ}
    (hmin : ∀ s, (γ c).im ≤ (γ s).im) : (deriv γ c).im = 0 := by
  have h := Complex.imCLM.hasFDerivAt.comp_hasDerivAt c (hd c).hasDerivAt
  have hloc : IsLocalMin (Complex.imCLM ∘ γ) c :=
    Filter.Eventually.of_forall (fun s => by simpa using hmin s)
  simpa using hloc.hasDerivAt_eq_zero h

lemma tw_unit_re (z : ℂ) : (twUnit z).re = z.re / ‖z‖ := by
  simp only [twUnit, Complex.div_ofReal_re]

/-- Hopf's theorem for a loop whose lowest point is at parameter `0`. -/
lemma tw_hopf_core (L : ℝ) (hL : 0 < L) (γ : ℝ → ℂ)
    (hclosed : Periodic γ L) (hsmooth : ContDiff ℝ 1 γ)
    (hmoving : ∀ s, deriv γ s ≠ 0) (hsimple : InjOn γ (Ico 0 L))
    (hmin : ∀ s, (γ 0).im ≤ (γ s).im)
    (θ : ℝ → ℝ) (hθ : Continuous θ)
    (hhead : ∀ s, deriv γ s = (‖deriv γ s‖ : ℂ) * exp (θ s * I)) :
    θ L - θ 0 = 2 * Real.pi ∨ θ L - θ 0 = -(2 * Real.pi) := by
  set D : ℝ × ℝ → ℂ := fun p =>
    if p.1 = p.2 then deriv γ p.1 else (γ p.2 - γ p.1) / ((p.2 - p.1 : ℝ) : ℂ) with hD
  have hDc : Continuous D := tw_slope_continuous hsmooth
  have hDdiag : ∀ s, D (s, s) = deriv γ s := fun s => by simp [hD]
  have hDoff : ∀ s t, s ≠ t → D (s, t) = (γ t - γ s) / ((t - s : ℝ) : ℂ) :=
    fun s t h => by simp [hD, h]
  have hγL : γ L = γ 0 := by simpa using hclosed 0
  have hdL : deriv γ L = deriv γ 0 := by simpa using tw_deriv_periodic hclosed 0
  have him0 : (deriv γ 0).im = 0 :=
    tw_im_deriv_zero_of_min (hsmooth.differentiable (by norm_num)) hmin
  have hinj : ∀ s t, 0 ≤ s → s < t → t ≤ L → t - s < L → γ t ≠ γ s := by
    intro s t hs hst htL hlt heq
    rcases lt_or_eq_of_le htL with ht | ht
    · have := hsimple ⟨by linarith, ht⟩ ⟨hs, by linarith⟩ heq
      linarith
    · rw [ht, hγL] at heq
      have := hsimple ⟨le_rfl, hL⟩ ⟨hs, by linarith⟩ heq
      linarith
  set K : Set (ℝ × ℝ) := {p | 0 ≤ p.1 ∧ p.1 ≤ p.2 ∧ p.2 ≤ L} with hK
  have hKc : IsCompact K := by
    apply (isCompact_Icc.prod isCompact_Icc :
      IsCompact (Icc (0 : ℝ) L ×ˢ Icc (0 : ℝ) L)).of_isClosed_subset
    · exact (isClosed_le continuous_const continuous_fst).inter
        ((isClosed_le continuous_fst continuous_snd).inter
          (isClosed_le continuous_snd continuous_const))
    · rintro ⟨s, t⟩ ⟨h1, h2, h3⟩
      exact ⟨⟨h1, by simp only at *; linarith⟩, ⟨by simp only at *; linarith, h3⟩⟩
  have hKconv : Convex ℝ K := by
    intro p hp q hq a b ha hb hab
    obtain ⟨hp1, hp2, hp3⟩ := hp
    obtain ⟨hq1, hq2, hq3⟩ := hq
    simp only [hK, mem_ofPred_eq, Prod.fst_add, Prod.snd_add, Prod.smul_fst, Prod.smul_snd,
      smul_eq_mul]
    refine ⟨by positivity, by nlinarith, by nlinarith⟩
  have h00 : ((0 : ℝ), (0 : ℝ)) ∈ K := ⟨le_rfl, le_rfl, hL.le⟩
  set g : ℝ × ℝ → ℂ := fun p =>
    if p.2 - p.1 < L then twUnit (D p) else twUnit (-D (p.2 - L, p.1)) with hg
  have hKcorner : ∀ p ∈ K, ¬ (p.2 - p.1 < L) → p = (0, L) := by
    rintro ⟨s, t⟩ ⟨h1, h2, h3⟩ h
    simp only at h h1 h2 h3
    have h4 : s = 0 := by linarith
    have h5 : t = L := by linarith
    rw [h4, h5]
  have hDne : ∀ p ∈ K, p.2 - p.1 < L → D p ≠ 0 := by
    rintro ⟨s, t⟩ ⟨h1, h2, h3⟩ h
    simp only at h h1 h2 h3
    by_cases hst : s = t
    · rw [hst, hDdiag]
      exact hmoving t
    · rw [hDoff s t hst]
      have hlt : s < t := lt_of_le_of_ne h2 hst
      refine div_ne_zero (sub_ne_zero.mpr (hinj s t h1 hlt h3 h)) ?_
      exact_mod_cast sub_ne_zero.mpr (Ne.symm hst)
  have hgcorner : g (0, L) = twUnit (-deriv γ 0) := by
    simp [hg, hDdiag]
  have hgdiag : ∀ s, g (s, s) = twUnit (deriv γ s) := by
    intro s
    simp [hg, hL, hDdiag]
  have hgne : ∀ p ∈ K, g p ≠ 0 := by
    intro p hp
    by_cases h : p.2 - p.1 < L
    · simp only [hg, h, ite_true]
      exact tw_unit_ne (hDne p hp h)
    · rw [hKcorner p hp h, hgcorner]
      exact tw_unit_ne (neg_ne_zero.mpr (hmoving 0))
  have hgnorm : ∀ p ∈ K, ‖g p‖ = 1 := by
    intro p hp
    by_cases h : p.2 - p.1 < L
    · simp only [hg, h, ite_true]
      exact tw_unit_norm (hDne p hp h)
    · rw [hKcorner p hp h, hgcorner]
      exact tw_unit_norm (neg_ne_zero.mpr (hmoving 0))
  have hgcont : ContinuousOn g K := by
    intro p hp
    by_cases h : p.2 - p.1 < L
    · have hev : (fun q => twUnit (D q)) =ᶠ[nhds p] g := by
        filter_upwards [(isOpen_lt (continuous_snd.sub continuous_fst) continuous_const).mem_nhds
          (show p ∈ {q : ℝ × ℝ | q.2 - q.1 < L} from h)] with q hq
        have hq' : q.2 - q.1 < L := hq
        simp only [hg, hq', ite_true]
      exact (((tw_unit_continuousAt (hDne p hp h)).comp hDc.continuousAt).congr
        hev).continuousWithinAt
    · rw [hKcorner p hp h]
      have hF : ContinuousAt (fun q : ℝ × ℝ => twUnit (-D (q.2 - L, q.1))) (0, L) := by
        have h1 : ContinuousAt (fun q : ℝ × ℝ => -D (q.2 - L, q.1)) (0, L) :=
          (hDc.comp (by fun_prop : Continuous fun q : ℝ × ℝ => (q.2 - L, q.1))).neg.continuousAt
        have h2 : -D (((0 : ℝ), L).2 - L, ((0 : ℝ), L).1) ≠ 0 := by
          simp only [sub_self, hDdiag]
          exact neg_ne_zero.mpr (hmoving 0)
        exact (tw_unit_continuousAt h2).comp (f := fun q : ℝ × ℝ => -D (q.2 - L, q.1)) h1
      refine hF.continuousWithinAt.congr_of_eventuallyEq ?_ ?_
      · have hopen : {q : ℝ × ℝ | q.1 < q.2} ∈ nhds ((0 : ℝ), L) :=
          (isOpen_lt continuous_fst continuous_snd).mem_nhds (show (0 : ℝ) < L from hL)
        filter_upwards [self_mem_nhdsWithin, mem_nhdsWithin_of_mem_nhds hopen] with q hqK hq
        have hq' : q.1 < q.2 := hq
        obtain ⟨hq1, hq2, hq3⟩ := hqK
        by_cases hlt : q.2 - q.1 < L
        · simp only [hg, hlt, ite_true]
          rw [hDoff _ _ (ne_of_lt hq'), hDoff _ _ (by linarith : q.2 - L ≠ q.1),
            hclosed.sub_eq, ← neg_div, neg_sub, tw_unit_div_pos _ (by linarith : (0 : ℝ) < q.2 - q.1),
            tw_unit_div_pos _ (by linarith : (0 : ℝ) < q.1 - (q.2 - L))]
        · simp only [hg, hlt, ite_false]
      · simp [hg]
  obtain ⟨Θ, hΘc, hΘ⟩ := tw_exists_lift hKc hKconv h00 hgcont hgne
  have hΘe : ∀ p ∈ K, exp (Θ p * I) = g p := fun p hp => tw_exp_eq_self (hgnorm p hp) (hΘ p hp)
  have hmemd : ∀ s ∈ Icc (0 : ℝ) L, (s, s) ∈ K := fun s hs => ⟨hs.1, le_rfl, hs.2⟩
  have hmem1 : ∀ t ∈ Icc (0 : ℝ) L, ((0 : ℝ), t) ∈ K := fun t ht => ⟨le_rfl, ht.1, ht.2⟩
  have hmem2 : ∀ s ∈ Icc (0 : ℝ) L, (s, L) ∈ K := fun s hs => ⟨hs.1, hs.2, le_rfl⟩
  have hL0 : (0 : ℝ) ∈ Icc (0 : ℝ) L := left_mem_Icc.2 hL.le
  have hLL : L ∈ Icc (0 : ℝ) L := right_mem_Icc.2 hL.le
  have hcd : ContinuousOn (fun s : ℝ => g (s, s)) (Icc 0 L) :=
    hgcont.comp (by fun_prop : Continuous fun s : ℝ => (s, s)).continuousOn hmemd
  have hc1 : ContinuousOn (fun t : ℝ => g (0, t)) (Icc 0 L) :=
    hgcont.comp (by fun_prop : Continuous fun t : ℝ => ((0 : ℝ), t)).continuousOn hmem1
  have hc2 : ContinuousOn (fun s : ℝ => g (s, L)) (Icc 0 L) :=
    hgcont.comp (by fun_prop : Continuous fun s : ℝ => (s, L)).continuousOn hmem2
  -- along the diagonal the lift follows the heading
  have hdiag := tw_lift_diff isPreconnected_Icc (f := θ) (g := fun s => Θ (s, s))
    hθ.continuousOn
    (hΘc.comp (by fun_prop : Continuous fun s : ℝ => (s, s)).continuousOn hmemd)
    (fun s hs => by
      show exp (θ s * I) = exp (Θ (s, s) * I)
      rw [hΘe _ (hmemd s hs), hgdiag]
      exact tw_exp_eq_unit (hmoving s) (hhead s)) hLL hL0
  -- the chord from the lowest point stays in the upper half plane
  have hup : ∀ t ∈ Icc (0 : ℝ) L, 0 ≤ (g (0, t)).im := by
    intro t ht
    by_cases h : t - 0 < L
    · simp only [hg, h, ite_true]
      rw [tw_unit_im]
      apply div_nonneg _ (norm_nonneg _)
      by_cases h0 : (0 : ℝ) = t
      · rw [← h0, hDdiag, him0]
      · rw [hDoff 0 t h0, Complex.div_ofReal_im, Complex.sub_im]
        apply div_nonneg
        · linarith [hmin t]
        · linarith [ht.1]
    · have : t = L := by linarith [ht.2]
      rw [this, hgcorner, tw_unit_im]
      simp [him0]
  -- the chord into the lowest point stays in the lower half plane
  have hlow : ∀ s ∈ Icc (0 : ℝ) L, (g (s, L)).im ≤ 0 := by
    intro s hs
    by_cases h : L - s < L
    · simp only [hg, h, ite_true]
      rw [tw_unit_im]
      apply div_nonpos_of_nonpos_of_nonneg _ (norm_nonneg _)
      by_cases hsL : s = L
      · rw [hsL, hDdiag, hdL, him0]
      · rw [hDoff s L hsL, Complex.div_ofReal_im, Complex.sub_im, hγL]
        apply div_nonpos_of_nonpos_of_nonneg
        · linarith [hmin s]
        · linarith [hs.2]
    · have : s = 0 := by linarith [hs.1]
      rw [this, hgcorner, tw_unit_im]
      simp [him0]
  have hedge1 := tw_lift_diff isPreconnected_Icc (f := fun t => Θ (0, t))
    (g := fun t => Real.arccos (g (0, t)).re)
    (hΘc.comp (by fun_prop : Continuous fun t : ℝ => ((0 : ℝ), t)).continuousOn hmem1)
    (Real.continuous_arccos.comp_continuousOn (Complex.continuous_re.comp_continuousOn hc1))
    (fun t ht => by
      show exp (Θ (0, t) * I) = exp (Real.arccos (g (0, t)).re * I)
      rw [hΘe _ (hmem1 t ht), tw_exp_arccos (hgnorm _ (hmem1 t ht)) (hup t ht)]) hLL hL0
  have hedge2 := tw_lift_diff isPreconnected_Icc (f := fun s => Θ (s, L))
    (g := fun s => -Real.arccos (g (s, L)).re)
    (hΘc.comp (by fun_prop : Continuous fun s : ℝ => (s, L)).continuousOn hmem2)
    ((Real.continuous_arccos.comp_continuousOn
      (Complex.continuous_re.comp_continuousOn hc2)).neg)
    (fun s hs => by
      show exp (Θ (s, L) * I) = exp ((-Real.arccos (g (s, L)).re : ℝ) * I)
      rw [hΘe _ (hmem2 s hs), tw_exp_neg_arccos (hgnorm _ (hmem2 s hs)) (hlow s hs)]) hLL hL0
  set r : ℝ := (deriv γ 0).re / ‖deriv γ 0‖ with hr
  have hg00 : (g (0, 0)).re = r := by rw [hgdiag, tw_unit_re]
  have hgLL : (g (L, L)).re = r := by rw [hgdiag, hdL, tw_unit_re]
  have hg0L : (g (0, L)).re = -r := by
    rw [hgcorner, tw_unit_re, norm_neg, Complex.neg_re, neg_div]
  rw [hg00, hg0L] at hedge1
  rw [hgLL, hg0L] at hedge2
  have hr2 : r ^ 2 = 1 := by
    have hn : ‖deriv γ 0‖ ≠ 0 := norm_ne_zero_iff.mpr (hmoving 0)
    have hre2 : (deriv γ 0).re ^ 2 = ‖deriv γ 0‖ ^ 2 := by
      have := Complex.sq_norm_sub_sq_re (deriv γ 0)
      rw [him0] at this
      linarith
    rw [hr, div_pow, hre2, div_self (pow_ne_zero 2 hn)]
  have hr' : (r - 1) * (r + 1) = 0 := by nlinarith
  rcases mul_eq_zero.mp hr' with h | h
  · have : r = 1 := by linarith
    rw [this, Real.arccos_one, Real.arccos_neg_one] at hedge1 hedge2
    left
    linarith
  · have : r = -1 := by linarith
    rw [this, neg_neg, Real.arccos_one, Real.arccos_neg_one] at hedge1 hedge2
    right
    linarith

#print axioms tw_exp_eq_int
#print axioms tw_lift_diff
#print axioms tw_exp_arg_of_norm_one
#print axioms tw_exists_lift
#print axioms tw_exp_eq_of_polar
#print axioms tw_deriv_periodic
#print axioms tw_unit_norm
#print axioms tw_unit_ne
#print axioms tw_unit_continuousAt
#print axioms tw_unit_im
#print axioms tw_unit_div_pos
#print axioms tw_exp_eq_unit
#print axioms tw_exp_eq_self
#print axioms tw_exp_arccos
#print axioms tw_exp_neg_arccos
#print axioms tw_slope_continuous
#print axioms tw_im_deriv_zero_of_min
#print axioms tw_unit_re
#print axioms tw_hopf_core

/-- **The turning number is a whole number and survives regular reshaping.** Take a family of
closed plane loops, stage `u` running from 0 to 1, that changes continuously, each loop smooth
enough to have a velocity and never stopping (speed above zero everywhere), with the velocity also
changing continuously. Follow the heading of the first loop and of the last loop continuously.
Then over one lap both headings turn through the same whole number `k` of full turns, `2πk`. -/
theorem turning_number_survives_regular_homotopy (L : ℝ) (H : ℝ → ℝ → ℂ)
    (hH : ContinuousOn (fun p : ℝ × ℝ => H p.1 p.2) (Icc 0 1 ×ˢ univ))
    (hclosed : ∀ u ∈ Icc (0 : ℝ) 1, Periodic (H u) L)
    (hsmooth : ∀ u ∈ Icc (0 : ℝ) 1, ContDiff ℝ 1 (H u))
    (hvel : ContinuousOn (fun p : ℝ × ℝ => deriv (H p.1) p.2) (Icc 0 1 ×ˢ univ))
    (hmoving : ∀ u ∈ Icc (0 : ℝ) 1, ∀ s, deriv (H u) s ≠ 0)
    (θ₀ θ₁ : ℝ → ℝ) (hθ₀ : Continuous θ₀) (hθ₁ : Continuous θ₁)
    (hhead₀ : ∀ s, deriv (H 0) s = (‖deriv (H 0) s‖ : ℂ) * exp (θ₀ s * I))
    (hhead₁ : ∀ s, deriv (H 1) s = (‖deriv (H 1) s‖ : ℂ) * exp (θ₁ s * I)) :
    ∃ k : ℤ, θ₀ L - θ₀ 0 = 2 * Real.pi * k ∧ θ₁ L - θ₁ 0 = 2 * Real.pi * k := by
  have hKsub : Icc (0 : ℝ) 1 ×ˢ uIcc 0 L ⊆ Icc 0 1 ×ˢ univ := prod_mono subset_rfl (subset_univ _)
  have h00 : ((0 : ℝ), (0 : ℝ)) ∈ Icc (0 : ℝ) 1 ×ˢ uIcc 0 L :=
    ⟨left_mem_Icc.2 zero_le_one, left_mem_uIcc⟩
  obtain ⟨Θ, hΘc, hΘ⟩ := tw_exists_lift (isCompact_Icc.prod isCompact_uIcc)
    ((convex_Icc 0 1).prod (convex_uIcc 0 L)) h00 (g := fun p => deriv (H p.1) p.2) (hvel.mono hKsub)
    (fun p hp => hmoving p.1 (hKsub hp).1 p.2)
  have hu0 : (0 : ℝ) ∈ Icc (0 : ℝ) 1 := left_mem_Icc.2 zero_le_one
  have hu1 : (1 : ℝ) ∈ Icc (0 : ℝ) 1 := right_mem_Icc.2 zero_le_one
  have hdper : ∀ u ∈ Icc (0 : ℝ) 1, deriv (H u) L = deriv (H u) 0 := by
    intro u hu
    simpa using tw_deriv_periodic (hclosed u hu) 0
  -- the lap angle of the lift does not change with the stage
  have hstage : Θ (0, L) - Θ (0, 0) = Θ (1, L) - Θ (1, 0) := by
    refine tw_lift_diff isPreconnected_Icc (f := fun u => Θ (u, L)) (g := fun u => Θ (u, 0))
      (hΘc.comp (by fun_prop : Continuous fun u : ℝ => (u, L)).continuousOn
        (fun u hu => ⟨hu, right_mem_uIcc⟩))
      (hΘc.comp (by fun_prop : Continuous fun u : ℝ => (u, (0 : ℝ))).continuousOn
        (fun u hu => ⟨hu, left_mem_uIcc⟩)) ?_ hu0 hu1
    intro u hu
    have h1 := hΘ (u, L) ⟨hu, right_mem_uIcc⟩
    have h2 := hΘ (u, 0) ⟨hu, left_mem_uIcc⟩
    simp only at h1 h2
    rw [← hdper u hu] at h2
    exact tw_exp_eq_of_polar (hmoving u hu L) h1 h2
  -- a given heading differs from the lift by a constant
  have hcmp : ∀ u ∈ Icc (0 : ℝ) 1, ∀ θ : ℝ → ℝ, Continuous θ →
      (∀ s, deriv (H u) s = (‖deriv (H u) s‖ : ℂ) * exp (θ s * I)) →
      θ L - θ 0 = Θ (u, L) - Θ (u, 0) := by
    intro u hu θ hθ hh
    have := tw_lift_diff isPreconnected_uIcc (f := θ) (g := fun s => Θ (u, s)) hθ.continuousOn
      (hΘc.comp (by fun_prop : Continuous fun s : ℝ => (u, s)).continuousOn
        (fun s hs => ⟨hu, hs⟩))
      (fun s hs => by
        have h2 := hΘ (u, s) ⟨hu, hs⟩
        exact tw_exp_eq_of_polar (hmoving u hu s) (hh s) h2)
      (right_mem_uIcc : L ∈ uIcc 0 L) (left_mem_uIcc : (0 : ℝ) ∈ uIcc 0 L)
    linarith
  have e0 := hcmp 0 hu0 θ₀ hθ₀ hhead₀
  have e1 := hcmp 1 hu1 θ₁ hθ₁ hhead₁
  have hex : exp (θ₀ L * I) = exp (θ₀ 0 * I) := by
    have h1 := hhead₀ L
    have h2 := hhead₀ 0
    rw [← hdper 0 hu0] at h2
    exact tw_exp_eq_of_polar (hmoving 0 hu0 L) h1 h2
  obtain ⟨k, hk⟩ := tw_exp_eq_int hex
  exact ⟨k, hk, by linarith⟩

/-- **The winding number is a whole number and survives reshaping that avoids the point.** Take a
family of closed plane loops, stage `u` running from 0 to 1, that changes continuously and never
touches the point `a`. Follow the bearing from `a` to the first loop and to the last loop
continuously. Then over one lap both bearings turn through the same whole number `k` of full
turns, `2πk`. -/
theorem winding_number_survives_homotopy_avoiding_point (L : ℝ) (a : ℂ) (H : ℝ → ℝ → ℂ)
    (hH : ContinuousOn (fun p : ℝ × ℝ => H p.1 p.2) (Icc 0 1 ×ˢ univ))
    (hclosed : ∀ u ∈ Icc (0 : ℝ) 1, Periodic (H u) L)
    (havoid : ∀ u ∈ Icc (0 : ℝ) 1, ∀ s, H u s ≠ a)
    (α₀ α₁ : ℝ → ℝ) (hα₀ : Continuous α₀) (hα₁ : Continuous α₁)
    (hbear₀ : ∀ s, H 0 s - a = (‖H 0 s - a‖ : ℂ) * exp (α₀ s * I))
    (hbear₁ : ∀ s, H 1 s - a = (‖H 1 s - a‖ : ℂ) * exp (α₁ s * I)) :
    ∃ k : ℤ, α₀ L - α₀ 0 = 2 * Real.pi * k ∧ α₁ L - α₁ 0 = 2 * Real.pi * k := by
  have hKsub : Icc (0 : ℝ) 1 ×ˢ uIcc 0 L ⊆ Icc 0 1 ×ˢ univ := prod_mono subset_rfl (subset_univ _)
  have h00 : ((0 : ℝ), (0 : ℝ)) ∈ Icc (0 : ℝ) 1 ×ˢ uIcc 0 L :=
    ⟨left_mem_Icc.2 zero_le_one, left_mem_uIcc⟩
  have hne : ∀ u ∈ Icc (0 : ℝ) 1, ∀ s, H u s - a ≠ 0 :=
    fun u hu s => sub_ne_zero.mpr (havoid u hu s)
  obtain ⟨Θ, hΘc, hΘ⟩ := tw_exists_lift (isCompact_Icc.prod isCompact_uIcc)
    ((convex_Icc 0 1).prod (convex_uIcc 0 L)) h00 (g := fun p => H p.1 p.2 - a)
    ((hH.mono hKsub).sub continuousOn_const)
    (fun p hp => hne p.1 (hKsub hp).1 p.2)
  have hu0 : (0 : ℝ) ∈ Icc (0 : ℝ) 1 := left_mem_Icc.2 zero_le_one
  have hu1 : (1 : ℝ) ∈ Icc (0 : ℝ) 1 := right_mem_Icc.2 zero_le_one
  have hper : ∀ u ∈ Icc (0 : ℝ) 1, H u L - a = H u 0 - a := by
    intro u hu
    simpa using congrArg (· - a) (hclosed u hu 0)
  have hstage : Θ (0, L) - Θ (0, 0) = Θ (1, L) - Θ (1, 0) := by
    refine tw_lift_diff isPreconnected_Icc (f := fun u => Θ (u, L)) (g := fun u => Θ (u, 0))
      (hΘc.comp (by fun_prop : Continuous fun u : ℝ => (u, L)).continuousOn
        (fun u hu => ⟨hu, right_mem_uIcc⟩))
      (hΘc.comp (by fun_prop : Continuous fun u : ℝ => (u, (0 : ℝ))).continuousOn
        (fun u hu => ⟨hu, left_mem_uIcc⟩)) ?_ hu0 hu1
    intro u hu
    have h1 := hΘ (u, L) ⟨hu, right_mem_uIcc⟩
    have h2 := hΘ (u, 0) ⟨hu, left_mem_uIcc⟩
    simp only at h1 h2
    rw [← hper u hu] at h2
    exact tw_exp_eq_of_polar (hne u hu L) h1 h2
  have hcmp : ∀ u ∈ Icc (0 : ℝ) 1, ∀ α : ℝ → ℝ, Continuous α →
      (∀ s, H u s - a = (‖H u s - a‖ : ℂ) * exp (α s * I)) →
      α L - α 0 = Θ (u, L) - Θ (u, 0) := by
    intro u hu α hα hh
    have := tw_lift_diff isPreconnected_uIcc (f := α) (g := fun s => Θ (u, s)) hα.continuousOn
      (hΘc.comp (by fun_prop : Continuous fun s : ℝ => (u, s)).continuousOn
        (fun s hs => ⟨hu, hs⟩))
      (fun s hs => by
        have h2 := hΘ (u, s) ⟨hu, hs⟩
        exact tw_exp_eq_of_polar (hne u hu s) (hh s) h2)
      (right_mem_uIcc : L ∈ uIcc 0 L) (left_mem_uIcc : (0 : ℝ) ∈ uIcc 0 L)
    linarith
  have e0 := hcmp 0 hu0 α₀ hα₀ hbear₀
  have e1 := hcmp 1 hu1 α₁ hα₁ hbear₁
  have hex : exp (α₀ L * I) = exp (α₀ 0 * I) := by
    have h1 := hbear₀ L
    have h2 := hbear₀ 0
    rw [← hper 0 hu0] at h2
    exact tw_exp_eq_of_polar (hne 0 hu0 L) h1 h2
  obtain ⟨k, hk⟩ := tw_exp_eq_int hex
  exact ⟨k, hk, by linarith⟩

/-- **Hopf's theorem: a loop without self-crossings turns exactly once.** A closed plane loop of
lap length `L > 0`, smooth enough to have a velocity, that never stops and never crosses itself
within one lap, has heading that turns through exactly one full turn over the lap: `+2π` when
run anticlockwise, `-2π` when run clockwise. So its turning number is `1` or `-1`. -/
theorem simple_loop_turning_number_eq_one_or_neg_one (L : ℝ) (hL : 0 < L) (γ : ℝ → ℂ)
    (hclosed : Periodic γ L) (hsmooth : ContDiff ℝ 1 γ)
    (hmoving : ∀ s, deriv γ s ≠ 0) (hsimple : InjOn γ (Ico 0 L))
    (θ : ℝ → ℝ) (hθ : Continuous θ)
    (hhead : ∀ s, deriv γ s = (‖deriv γ s‖ : ℂ) * exp (θ s * I)) :
    θ L - θ 0 = 2 * Real.pi ∨ θ L - θ 0 = -(2 * Real.pi) := by
  obtain ⟨c, -, hcmin⟩ := isCompact_Icc.exists_isMinOn (nonempty_Icc.2 hL.le)
    (Complex.continuous_im.comp hsmooth.continuous).continuousOn
  have hmin : ∀ s, (γ c).im ≤ (γ s).im := by
    intro s
    obtain ⟨y, hy, hys⟩ := hclosed.exists_mem_Ico₀ hL s
    rw [hys]
    exact hcmin (Ico_subset_Icc_self hy)
  have hmod : ∀ x, γ (toIcoMod hL 0 x) = γ x := fun x => by
    rw [← self_sub_toIcoDiv_zsmul]
    exact hclosed.sub_zsmul_eq _
  have hper' : Periodic (fun s => γ (s + c)) L := fun s => by
    show γ (s + L + c) = γ (s + c)
    rw [add_right_comm]
    exact hclosed _
  have hsm' : ContDiff ℝ 1 (fun s => γ (s + c)) :=
    hsmooth.comp (contDiff_id.add contDiff_const)
  have hder' : ∀ s, deriv (fun s => γ (s + c)) s = deriv γ (s + c) :=
    fun s => deriv_comp_add_const _ _ _
  have hinj' : InjOn (fun s => γ (s + c)) (Ico 0 L) := by
    intro s hs t ht hst
    simp only at hst
    have hm : toIcoMod hL 0 (s + c) = toIcoMod hL 0 (t + c) := by
      apply hsimple
      · simpa using toIcoMod_mem_Ico hL 0 (s + c)
      · simpa using toIcoMod_mem_Ico hL 0 (t + c)
      · rw [hmod, hmod]
        exact hst
    obtain ⟨n, hn⟩ := (toIcoMod_eq_toIcoMod hL).mp hm
    rw [zsmul_eq_mul] at hn
    have hts : t - s = n * L := by linarith
    have hn0 : n = 0 := by
      by_contra hne
      rcases lt_or_gt_of_ne hne with h | h
      · have : (n : ℝ) + 1 ≤ 0 := by exact_mod_cast (Int.lt_iff_add_one_le.mp h)
        nlinarith [hs.1, hs.2, ht.1, ht.2]
      · have : (1 : ℝ) ≤ n := by exact_mod_cast h
        nlinarith [hs.1, hs.2, ht.1, ht.2]
    rw [hn0] at hts
    simp at hts
    linarith
  have hcore := tw_hopf_core L hL (fun s => γ (s + c)) hper' hsm'
    (fun s => by rw [hder']; exact hmoving _) hinj'
    (fun s => by simp only [zero_add]; exact hmin _)
    (fun s => θ (s + c)) (hθ.comp (continuous_id.add continuous_const))
    (fun s => by rw [hder']; exact hhead _)
  have hshift := tw_lift_diff isPreconnected_univ (f := fun s => θ (s + L)) (g := θ)
    (hθ.comp (continuous_id.add continuous_const)).continuousOn hθ.continuousOn
    (fun s _ => by
      show exp (θ (s + L) * I) = exp (θ s * I)
      rw [tw_exp_eq_unit (hmoving _) (hhead (s + L)), tw_exp_eq_unit (hmoving _) (hhead s),
        tw_deriv_periodic hclosed s])
    (mem_univ c) (mem_univ 0)
  simp only [zero_add] at hcore hshift
  rcases hcore with h | h
  · left
    rw [add_comm L c] at h
    linarith
  · right
    rw [add_comm L c] at h
    linarith

-- The track's lap, by pieces, in degrees: straight, bend, straight, bend.
example : (0 + 180 + 0 + 180 : ℕ) = 360 := by norm_num

-- One whole turn of the heading: turning number 1.
example : ((0 + 180 + 0 + 180 : ℤ) : ℚ) / 360 = 1 := by norm_num

#print axioms turning_number_survives_regular_homotopy
#print axioms winding_number_survives_homotopy_avoiding_point
#print axioms simple_loop_turning_number_eq_one_or_neg_one
