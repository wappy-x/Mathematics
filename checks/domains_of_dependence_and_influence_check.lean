-- Dependence and influence: a wave-equation solution at a point and time depends only on the starting data within distance c·t of that point, while a heat-equation hot spot warms every point at once.
import Mathlib.Analysis.InnerProductSpace.Laplacian
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.LineDeriv.IntegrationByParts
import Mathlib.Analysis.Calculus.ParametricIntegral
import Mathlib.Analysis.SpecialFunctions.SmoothTransition
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.InnerProductSpace.Calculus

open Laplacian Metric

section WaveHelpers

open MeasureTheory Set Filter Topology

lemma wave_aux_time {d : ℕ} {F : ℝ × EuclideanSpace ℝ (Fin d) → ℝ}
    {F' : ℝ × EuclideanSpace ℝ (Fin d) →L[ℝ] ℝ} {t : ℝ} {x : EuclideanSpace ℝ (Fin d)}
    (h : HasFDerivAt F F' (t, x)) : HasDerivAt (fun s => F (s, x)) (F' (1, 0)) t := by
  have hl : HasDerivAt (fun s : ℝ => (s, x)) ((1 : ℝ), (0 : EuclideanSpace ℝ (Fin d))) t :=
    (hasDerivAt_id t).prodMk (hasDerivAt_const t x)
  exact h.comp_hasDerivAt t hl

lemma wave_aux_space {d : ℕ} {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {F : ℝ × EuclideanSpace ℝ (Fin d) → V}
    {F' : ℝ × EuclideanSpace ℝ (Fin d) →L[ℝ] V} {t : ℝ} {x : EuclideanSpace ℝ (Fin d)}
    (h : HasFDerivAt F F' (t, x)) :
    HasFDerivAt (fun y => F (t, y)) (F'.comp (ContinuousLinearMap.inr ℝ ℝ _)) x := by
  have hl : HasFDerivAt (fun y : EuclideanSpace ℝ (Fin d) => (t, y))
      (ContinuousLinearMap.inr ℝ ℝ (EuclideanSpace ℝ (Fin d))) x :=
    (hasFDerivAt_const t x).prodMk (hasFDerivAt_id x)
  exact h.comp x hl
lemma wave_aux_integrable {d : ℕ} {φ : EuclideanSpace ℝ (Fin d) → ℝ}
    (x₀ : EuclideanSpace ℝ (Fin d)) (R : ℝ) (hφ : Continuous φ)
    (hs : ∀ x, R < ‖x - x₀‖ → φ x = 0) : Integrable φ := by
  apply hφ.integrable_of_hasCompactSupport
  apply HasCompactSupport.intro (isCompact_closedBall x₀ R)
  intro x hx
  apply hs
  simpa [mem_closedBall, dist_eq_norm] using hx

lemma wave_aux_glue_deriv (s : ℝ) :
    0 ≤ deriv expNegInvGlue s ∧ (s ≤ 0 → deriv expNegInvGlue s = 0) := by
  constructor
  · exact expNegInvGlue.monotone.deriv_nonneg
  · intro hs
    apply IsLocalMin.deriv_eq_zero
    filter_upwards with y
    rw [expNegInvGlue.zero_of_nonpos hs]
    exact expNegInvGlue.nonneg y

lemma wave_aux_hasDerivAt_integral {d : ℕ} {K : ℝ × EuclideanSpace ℝ (Fin d) → ℝ}
    (hK : ContDiff ℝ 1 K) (x₀ : EuclideanSpace ℝ (Fin d)) (R a b t : ℝ)
    (hsupp : ∀ s ∈ Ioo a b, ∀ x, R < ‖x - x₀‖ → K (s, x) = 0) (ht : t ∈ Ioo a b) :
    HasDerivAt (fun s => ∫ x, K (s, x)) (∫ x, fderiv ℝ K (t, x) (1, 0)) t := by
  have hKc : Continuous K := hK.continuous
  have hK'c : Continuous (fderiv ℝ K) := hK.continuous_fderiv one_ne_zero
  have hKd : ∀ p, HasFDerivAt K (fderiv ℝ K p) p :=
    fun p => (hK.differentiable one_ne_zero p).hasFDerivAt
  have hc1 : Continuous fun p : ℝ × EuclideanSpace ℝ (Fin d) => fderiv ℝ K p (1, 0) := by
    fun_prop
  obtain ⟨M, hM⟩ : ∃ M, ∀ p ∈ Icc a b ×ˢ closedBall x₀ R, ‖fderiv ℝ K p (1, 0)‖ ≤ M :=
    (isCompact_Icc.prod (isCompact_closedBall x₀ R)).exists_bound_of_continuousOn hc1.continuousOn
  have hvan : ∀ s ∈ Ioo a b, ∀ x, R < ‖x - x₀‖ → fderiv ℝ K (s, x) (1, 0) = 0 := by
    intro s hs x hx
    have hopen : IsOpen (Ioo a b ×ˢ {y : EuclideanSpace ℝ (Fin d) | R < ‖y - x₀‖}) :=
      isOpen_Ioo.prod (isOpen_lt continuous_const (by fun_prop))
    have : K =ᶠ[𝓝 (s, x)] fun _ => 0 := by
      filter_upwards [hopen.mem_nhds ⟨hs, hx⟩] with p hp
      exact hsupp p.1 hp.1 p.2 hp.2
    rw [this.fderiv_eq]
    simp
  refine (hasDerivAt_integral_of_dominated_loc_of_deriv_le (Ioo_mem_nhds ht.1 ht.2)
    (F := fun s x => K (s, x)) (F' := fun s x => fderiv ℝ K (s, x) (1, 0))
    (bound := indicator (closedBall x₀ R) (fun _ => M)) ?_ ?_ ?_ ?_ ?_ ?_).2
  · exact Eventually.of_forall fun s => (by fun_prop : Continuous fun x => K (s, x)).aestronglyMeasurable
  · exact wave_aux_integrable x₀ R (by fun_prop) (hsupp t ht)
  · exact (by fun_prop : Continuous fun x => fderiv ℝ K (t, x) (1, 0)).aestronglyMeasurable
  · refine Eventually.of_forall fun x s hs => ?_
    by_cases hx : x ∈ closedBall x₀ R
    · rw [indicator_of_mem hx]
      exact hM (s, x) ⟨Ioo_subset_Icc_self hs, hx⟩
    · rw [indicator_of_notMem hx]
      have : R < ‖x - x₀‖ := by simpa [mem_closedBall, dist_eq_norm] using hx
      simp [hvan s hs x this]
  · exact (integrable_indicator_iff measurableSet_closedBall).2
      (integrableOn_const measure_closedBall_lt_top.ne)
  · exact Eventually.of_forall fun x s _ => wave_aux_time (hKd (s, x))

lemma wave_aux_core {d : ℕ} (W : ℝ × EuclideanSpace ℝ (Fin d) → ℝ) (hW : ContDiff ℝ 2 W)
    (c t₀ : ℝ) (x₀ : EuclideanSpace ℝ (Fin d)) (hc : 0 < c) (ht₀ : 0 ≤ t₀)
    (hwave : ∀ t ∈ Icc (0 : ℝ) t₀, ∀ x, fderiv ℝ (fderiv ℝ W) (t, x) (1, 0) (1, 0) =
      c ^ 2 * ∑ i, fderiv ℝ (fderiv ℝ W) (t, x) (0, EuclideanSpace.single i 1)
        (0, EuclideanSpace.single i 1))
    (h0 : ∀ y ∈ closedBall x₀ (c * t₀), W (0, y) = 0)
    (h1 : ∀ y ∈ closedBall x₀ (c * t₀), fderiv ℝ W (0, y) (1, 0) = 0) :
    W (t₀, x₀) = 0 := by
  set D := fderiv ℝ W with hDdef
  set D2 := fderiv ℝ (fderiv ℝ W) with hD2def
  have hD1 : ContDiff ℝ 1 D := hW.fderiv_right (m := 1) (by norm_num)
  have hDd : ∀ p, HasFDerivAt W (D p) p :=
    fun p => (hW.differentiable (by norm_num) p).hasFDerivAt
  have hD2d : ∀ p, HasFDerivAt D (D2 p) p :=
    fun p => (hD1.differentiable (by norm_num) p).hasFDerivAt
  have hD2c : Continuous D2 := hD1.continuous_fderiv one_ne_zero
  have hsymm : ∀ p v w, D2 p v w = D2 p w v :=
    fun p v w => hW.contDiffAt.isSymmSndFDerivAt (by simp) v w
  let h := expNegInvGlue
  let h' := deriv expNegInvGlue
  have hh : ContDiff ℝ 2 h := expNegInvGlue.contDiff
  have hh'c : Continuous h' := hh.continuous_deriv (by norm_num)
  let τ : ℝ × EuclideanSpace ℝ (Fin d) := (1, 0)
  let η : Fin d → ℝ × EuclideanSpace ℝ (Fin d) := fun i => (0, EuclideanSpace.single i 1)
  let q : ℝ × EuclideanSpace ℝ (Fin d) → ℝ := fun p => c ^ 2 * (t₀ - p.1) ^ 2 - ‖p.2 - x₀‖ ^ 2
  have hq : ContDiff ℝ 2 q := by
    have : ContDiff ℝ 2 fun p : ℝ × EuclideanSpace ℝ (Fin d) => ‖p.2 - x₀‖ ^ 2 :=
      (contDiff_norm_sq ℝ).comp (contDiff_snd.sub contDiff_const)
    exact (contDiff_const.mul ((contDiff_const.sub contDiff_fst).pow 2)).sub this
  let ψ : ℝ × EuclideanSpace ℝ (Fin d) → ℝ := fun p => h (q p)
  let A : ℝ × EuclideanSpace ℝ (Fin d) → ℝ := fun p => D p τ
  let G : Fin d → ℝ × EuclideanSpace ℝ (Fin d) → ℝ := fun i p => D p (η i)
  let K : ℝ × EuclideanSpace ℝ (Fin d) → ℝ :=
    fun p => ψ p * (A p ^ 2 + c ^ 2 * ∑ i, G i p ^ 2)
  have hK : ContDiff ℝ 1 K := by
    have hA : ContDiff ℝ 1 A := hD1.clm_apply contDiff_const
    have hG : ∀ i, ContDiff ℝ 1 (G i) := fun i => hD1.clm_apply contDiff_const
    have hψ : ContDiff ℝ 1 ψ := (hh.comp hq).of_le (by norm_num)
    exact hψ.mul ((hA.pow 2).add (contDiff_const.mul (ContDiff.sum fun i _ => (hG i).pow 2)))
  have hKd : ∀ p, HasFDerivAt K (fderiv ℝ K p) p :=
    fun p => (hK.differentiable one_ne_zero p).hasFDerivAt
  have hh'd : ∀ r, HasDerivAt h (h' r) r :=
    fun r => (hh.differentiable (by norm_num) r).hasDerivAt
  -- time derivative of K
  have hKt : ∀ t x, fderiv ℝ K (t, x) τ =
      h' (q (t, x)) * (-2 * c ^ 2 * (t₀ - t)) * (A (t, x) ^ 2 + c ^ 2 * ∑ i, G i (t, x) ^ 2)
      + ψ (t, x) * (2 * A (t, x) * D2 (t, x) τ τ
        + c ^ 2 * ∑ i, 2 * G i (t, x) * D2 (t, x) τ (η i)) := by
    intro t x
    have hqt : HasDerivAt (fun s => q (s, x)) (-2 * c ^ 2 * (t₀ - t)) t := by
      have := ((((hasDerivAt_id t).const_sub t₀).pow 2).const_mul (c ^ 2)).sub_const
        (‖x - x₀‖ ^ 2)
      convert this using 1
      · rfl
      · simp only [id_eq]; norm_num; ring
    have hψt := (hh'd (q (t, x))).comp t hqt
    have hAt : HasDerivAt (fun s => A (s, x)) (D2 (t, x) τ τ) t := by
      simpa using wave_aux_time ((hD2d (t, x)).clm_apply (hasFDerivAt_const τ (t, x)))
    have hGt : ∀ i, HasDerivAt (fun s => G i (s, x)) (D2 (t, x) τ (η i)) t := by
      intro i
      simpa using wave_aux_time ((hD2d (t, x)).clm_apply (hasFDerivAt_const (η i) (t, x)))
    have hsum := HasDerivAt.fun_sum (u := Finset.univ) fun i _ => (hGt i).pow 2
    have := hψt.mul ((hAt.pow 2).add (hsum.const_mul (c ^ 2)))
    rw [(wave_aux_time (hKd (t, x))).unique this]
    simp only [Function.comp_apply, Pi.add_apply, Pi.pow_apply, ψ]
    push_cast
    ring_nf
  -- space derivatives
  have hfd : ∀ t x i, fderiv ℝ (fun y => ψ (t, y) * A (t, y)) x (EuclideanSpace.single i 1) =
      h' (q (t, x)) * (-2 * (x - x₀) i) * A (t, x) + ψ (t, x) * D2 (t, x) (η i) τ := by
    intro t x i
    have h1 := (((hasFDerivAt_id x).sub_const x₀).norm_sq).const_sub (c ^ 2 * (t₀ - t) ^ 2)
    have h2 := (hh'd (q (t, x))).comp_hasFDerivAt x h1
    have h3 := wave_aux_space ((hD2d (t, x)).clm_apply (hasFDerivAt_const τ (t, x)))
    have h4 : HasFDerivAt (fun y => ψ (t, y) * A (t, y)) _ x := h2.mul h3
    rw [h4.fderiv]
    simp [EuclideanSpace.inner_single_right, η, ψ, A]
    ring
  have hgd : ∀ t x i, fderiv ℝ (fun y => G i (t, y)) x (EuclideanSpace.single i 1) =
      D2 (t, x) (η i) (η i) := by
    intro t x i
    have h3 := wave_aux_space ((hD2d (t, x)).clm_apply (hasFDerivAt_const (η i) (t, x)))
    have h4 : HasFDerivAt (fun y => G i (t, y)) _ x := h3
    rw [h4.fderiv]
    simp [η]
  -- where `q ≤ 0`, the weight and its rate vanish
  have hvan : ∀ p, q p ≤ 0 → ψ p = 0 ∧ h' (q p) = 0 :=
    fun p hp => ⟨expNegInvGlue.zero_of_nonpos hp, (wave_aux_glue_deriv _).2 hp⟩
  have hqneg : ∀ t ∈ Icc (0 : ℝ) t₀, ∀ x, c * t₀ < ‖x - x₀‖ → q (t, x) ≤ 0 := by
    intro t ht x hx
    have h1' : c * (t₀ - t) ≤ c * t₀ := by nlinarith [ht.1]
    have h2' : 0 ≤ c * (t₀ - t) := by nlinarith [ht.2]
    show c ^ 2 * (t₀ - t) ^ 2 - ‖x - x₀‖ ^ 2 ≤ 0
    nlinarith [norm_nonneg (x - x₀)]
  have hA1 : ContDiff ℝ 1 A := hD1.clm_apply contDiff_const
  have hG1 : ∀ i, ContDiff ℝ 1 (G i) := fun i => hD1.clm_apply contDiff_const
  have hψ1 : ContDiff ℝ 1 ψ := (hh.comp hq).of_le (by norm_num)
  have hAc : Continuous A := hD1.continuous.clm_apply continuous_const
  have hGc : ∀ i, Continuous (G i) := fun i => hD1.continuous.clm_apply continuous_const
  have hqc : Continuous q := hq.continuous
  have hψc : Continuous ψ := hh.continuous.comp hqc
  have hKc : Continuous K := hK.continuous
  have hsec : ∀ t, Continuous fun x : EuclideanSpace ℝ (Fin d) => ((t, x) : ℝ × _) :=
    fun t => by fun_prop
  -- the pointwise sign
  have hP : ∀ t ∈ Icc (0 : ℝ) t₀, ∀ x,
      h' (q (t, x)) * (-2 * c ^ 2 * (t₀ - t)) * (A (t, x) ^ 2 + c ^ 2 * ∑ i, G i (t, x) ^ 2)
      + 4 * c ^ 2 * h' (q (t, x)) * A (t, x) * ∑ i, (x - x₀) i * G i (t, x) ≤ 0 := by
    intro t ht x
    have hnn : 0 ≤ h' (q (t, x)) := (wave_aux_glue_deriv (q (t, x))).1
    have hz : q (t, x) ≤ 0 → h' (q (t, x)) = 0 := (wave_aux_glue_deriv (q (t, x))).2
    by_cases hpos : 0 < q (t, x)
    · have hL : 0 ≤ c * (t₀ - t) := by nlinarith [ht.2]
      have hnorm : ‖x - x₀‖ ^ 2 = ∑ i, (x - x₀) i ^ 2 := EuclideanSpace.real_norm_sq_eq _
      have hρ : ∑ i, (x - x₀) i ^ 2 < (c * (t₀ - t)) ^ 2 := by
        rw [← hnorm]; have : 0 < q (t, x) := hpos; simp only [q] at this; nlinarith
      have hCS := Finset.sum_mul_sq_le_sq_mul_sq Finset.univ (fun i => (x - x₀) i)
        (fun i => G i (t, x))
      have hS : 0 ≤ ∑ i, G i (t, x) ^ 2 := Finset.sum_nonneg fun i _ => sq_nonneg _
      have hρ0 : 0 ≤ ∑ i, (x - x₀) i ^ 2 := Finset.sum_nonneg fun i _ => sq_nonneg _
      set S := ∑ i, G i (t, x) ^ 2
      set Pp := ∑ i, (x - x₀) i * G i (t, x)
      set ρ2 := ∑ i, (x - x₀) i ^ 2
      set L := c * (t₀ - t)
      set a := A (t, x)
      have hLpos : 0 < L := by nlinarith
      have hPp : Pp ^ 2 ≤ L ^ 2 * S := le_trans hCS (by nlinarith)
      have hbr : 0 ≤ L * (a ^ 2 + c ^ 2 * S) - 2 * c * a * Pp := by
        have : 0 ≤ L * (L * (a ^ 2 + c ^ 2 * S) - 2 * c * a * Pp) := by
          nlinarith [sq_nonneg (L * a - c * Pp), sq_nonneg c]
        by_contra hneg
        push Not at hneg
        nlinarith
      have heq : h' (q (t, x)) * (-2 * c ^ 2 * (t₀ - t)) * (a ^ 2 + c ^ 2 * S)
          + 4 * c ^ 2 * h' (q (t, x)) * a * Pp
          = -(2 * c * h' (q (t, x))) * (L * (a ^ 2 + c ^ 2 * S) - 2 * c * a * Pp) := by
        simp only [L]; ring
      rw [heq]
      have : 0 ≤ 2 * c * h' (q (t, x)) := by positivity
      nlinarith
    · rw [hz (not_lt.1 hpos)]
      simp
  -- the energy rate at each time in `[0, t₀]` is at most zero
  have key : ∀ t ∈ Icc (0 : ℝ) t₀, ∫ x, fderiv ℝ K (t, x) τ ≤ 0 := by
    intro t ht
    let f : EuclideanSpace ℝ (Fin d) → ℝ := fun y => ψ (t, y) * A (t, y)
    let g : Fin d → EuclideanSpace ℝ (Fin d) → ℝ := fun i y => G i (t, y)
    let f' : Fin d → EuclideanSpace ℝ (Fin d) → ℝ := fun i x =>
      h' (q (t, x)) * (-2 * (x - x₀) i) * A (t, x) + ψ (t, x) * D2 (t, x) (η i) τ
    let g' : Fin d → EuclideanSpace ℝ (Fin d) → ℝ := fun i x => D2 (t, x) (η i) (η i)
    let P : EuclideanSpace ℝ (Fin d) → ℝ := fun x =>
      h' (q (t, x)) * (-2 * c ^ 2 * (t₀ - t)) * (A (t, x) ^ 2 + c ^ 2 * ∑ i, G i (t, x) ^ 2)
      + 4 * c ^ 2 * h' (q (t, x)) * A (t, x) * ∑ i, (x - x₀) i * G i (t, x)
    have hpt : ∀ x, fderiv ℝ K (t, x) τ =
        P x + 2 * c ^ 2 * ∑ i, (f x * g' i x + f' i x * g i x) := by
      intro x
      have hs1 : ∑ i, (f x * g' i x + f' i x * g i x) =
          ψ (t, x) * A (t, x) * ∑ i, D2 (t, x) (η i) (η i)
          + (-2 * h' (q (t, x)) * A (t, x)) * ∑ i, (x - x₀) i * G i (t, x)
          + ψ (t, x) * ∑ i, G i (t, x) * D2 (t, x) τ (η i) := by
        simp only [Finset.mul_sum, ← Finset.sum_add_distrib]
        refine Finset.sum_congr rfl fun i _ => ?_
        simp only [f, f', g, g']
        rw [hsymm (t, x) (η i) τ]
        ring
      have hs2 : ∑ i, 2 * G i (t, x) * D2 (t, x) τ (η i) =
          2 * ∑ i, G i (t, x) * D2 (t, x) τ (η i) := by
        rw [Finset.mul_sum]
        exact Finset.sum_congr rfl fun i _ => by ring
      rw [hKt, hs1, hs2]
      have hw := hwave t ht x
      simp only [P]
      have hAτ : D2 (t, x) τ τ = c ^ 2 * ∑ i, D2 (t, x) (η i) (η i) := hw
      rw [hAτ]
      ring
    have hint : ∀ φ : EuclideanSpace ℝ (Fin d) → ℝ, Continuous φ →
        (∀ x, q (t, x) ≤ 0 → φ x = 0) → Integrable φ :=
      fun φ hφ hz => wave_aux_integrable x₀ (c * t₀) hφ fun x hx => hz x (hqneg t ht x hx)
    have hAx : Continuous fun x => A (t, x) := hAc.comp (hsec t)
    have hGx : ∀ i, Continuous fun x => G i (t, x) := fun i => (hGc i).comp (hsec t)
    have hψx : Continuous fun x => ψ (t, x) := hψc.comp (hsec t)
    have hh'x : Continuous fun x => h' (q (t, x)) := hh'c.comp (hqc.comp (hsec t))
    have hD2x : ∀ v w, Continuous fun x => D2 (t, x) v w :=
      fun v w => ((hD2c.comp (hsec t)).clm_apply continuous_const).clm_apply continuous_const
    have hcoord : ∀ i, Continuous fun x : EuclideanSpace ℝ (Fin d) => (x - x₀) i :=
      fun i => (EuclideanSpace.proj (𝕜 := ℝ) i).continuous.comp (continuous_id.sub continuous_const)
    have hfg' : ∀ i, Integrable fun x => f x * g' i x := fun i =>
      hint _ ((hψx.mul hAx).mul (hD2x _ _)) fun x hx => by simp [f, (hvan _ hx).1]
    have hf'g : ∀ i, Integrable fun x => f' i x * g i x := fun i =>
      hint _ (((hh'x.mul (continuous_const.mul (hcoord i))).mul hAx).add
        (hψx.mul (hD2x _ _)) |>.mul (hGx i))
        fun x hx => by simp [f', g, (hvan _ hx).1, (hvan _ hx).2]
    have hfg : ∀ i, Integrable fun x => f x * g i x := fun i =>
      hint _ ((hψx.mul hAx).mul (hGx i)) fun x hx => by simp [f, (hvan _ hx).1]
    have hibp : ∀ i, ∫ x, (f x * g' i x + f' i x * g i x) = 0 := by
      intro i
      have hfdf : (fun x => fderiv ℝ f x (EuclideanSpace.single i 1)) = f' i :=
        funext fun x => hfd t x i
      have hgdf : (fun x => fderiv ℝ (g i) x (EuclideanSpace.single i 1)) = g' i :=
        funext fun x => hgd t x i
      have hf'g2 : Integrable fun x => fderiv ℝ f x (EuclideanSpace.single i 1) * g i x := by
        simpa only [← hfdf] using hf'g i
      have hfg'2 : Integrable fun x => f x * fderiv ℝ (g i) x (EuclideanSpace.single i 1) := by
        simpa only [← hgdf] using hfg' i
      have hfdiff : Differentiable ℝ f :=
        ((hψ1.comp (contDiff_const.prodMk contDiff_id)).mul
          (hA1.comp (contDiff_const.prodMk contDiff_id))).differentiable one_ne_zero
      have hgdiff : Differentiable ℝ (g i) :=
        ((hG1 i).comp (contDiff_const.prodMk contDiff_id)).differentiable one_ne_zero
      have := integral_mul_fderiv_eq_neg_fderiv_mul_of_integrable (μ := volume)
        hf'g2 hfg'2 (hfg i) (fun x _ => hfdiff x) (fun x _ => hgdiff x)
      have e1 : ∀ x, fderiv ℝ f x (EuclideanSpace.single i 1) = f' i x := fun x => hfd t x i
      have e2 : ∀ x, fderiv ℝ (g i) x (EuclideanSpace.single i 1) = g' i x :=
        fun x => hgd t x i
      simp only [e1, e2] at this
      rw [integral_add (hfg' i) (hf'g i), this]
      ring
    have hsumint : Integrable fun x => 2 * c ^ 2 * ∑ i, (f x * g' i x + f' i x * g i x) :=
      (integrable_finsetSum _ fun i _ => (hfg' i).add (hf'g i)).const_mul _
    have hPint : Integrable P :=
      hint _ (by
        have hsum1 : Continuous fun x => ∑ i, G i (t, x) ^ 2 :=
          continuous_finsetSum _ fun i _ => (hGx i).pow 2
        have hsum2 : Continuous fun x => ∑ i, (x - x₀) i * G i (t, x) :=
          continuous_finsetSum _ fun i _ => (hcoord i).mul (hGx i)
        exact ((hh'x.mul continuous_const).mul ((hAx.pow 2).add (continuous_const.mul hsum1))).add
          (((continuous_const.mul hh'x).mul hAx).mul hsum2))
        fun x hx => by simp [P, (hvan _ hx).2]
    rw [integral_congr_ae (Eventually.of_forall hpt), integral_add hPint hsumint,
      integral_const_mul, integral_finsetSum (f := fun i x => f x * g' i x + f' i x * g i x) _
        fun i _ => (hfg' i).add (hf'g i)]
    simp only [hibp, Finset.sum_const_zero, mul_zero, add_zero]
    exact integral_nonpos fun x => hP t ht x
  -- the energy `E t = ∫ K (t, x) dx`
  have hsupp : ∀ s ∈ Ioo (-1 : ℝ) (t₀ + 1), ∀ x, c * (t₀ + 1) < ‖x - x₀‖ → K (s, x) = 0 := by
    intro s hs x hx
    have hq0 : q (s, x) ≤ 0 := by
      have h1' : (t₀ - s) ^ 2 ≤ (t₀ + 1) ^ 2 := by nlinarith [hs.1, hs.2]
      have h2' : (c * (t₀ + 1)) ^ 2 ≤ ‖x - x₀‖ ^ 2 := by
        have : 0 ≤ c * (t₀ + 1) := by positivity
        nlinarith
      show c ^ 2 * (t₀ - s) ^ 2 - ‖x - x₀‖ ^ 2 ≤ 0
      nlinarith [sq_nonneg c]
    simp [K, (hvan _ hq0).1]
  have hEd : ∀ t ∈ Ioo (-1 : ℝ) (t₀ + 1),
      HasDerivAt (fun s => ∫ x, K (s, x)) (∫ x, fderiv ℝ K (t, x) τ) t :=
    fun t ht => wave_aux_hasDerivAt_integral hK x₀ (c * (t₀ + 1)) (-1) (t₀ + 1) t hsupp ht
  have hIcc : ∀ t ∈ Icc (0 : ℝ) t₀, t ∈ Ioo (-1 : ℝ) (t₀ + 1) :=
    fun t ht => ⟨by linarith [ht.1], by linarith [ht.2]⟩
  have hanti : AntitoneOn (fun s => ∫ x, K (s, x)) (Icc 0 t₀) := by
    apply antitoneOn_of_deriv_nonpos (convex_Icc 0 t₀)
    · exact fun t ht => (hEd t (hIcc t ht)).continuousAt.continuousWithinAt
    · rw [interior_Icc]
      exact fun t ht =>
        (hEd t (hIcc t (Ioo_subset_Icc_self ht))).differentiableAt.differentiableWithinAt
    · rw [interior_Icc]
      intro t ht
      rw [(hEd t (hIcc t (Ioo_subset_Icc_self ht))).deriv]
      exact key t (Ioo_subset_Icc_self ht)
  have hKnn : ∀ p, 0 ≤ K p := fun p =>
    mul_nonneg (expNegInvGlue.nonneg _) (by positivity)
  -- at time zero the energy vanishes
  have hK0 : ∀ x, K (0, x) = 0 := by
    intro x
    by_cases hq0 : q (0, x) ≤ 0
    · simp [K, (hvan _ hq0).1]
    · have hxb : x ∈ ball x₀ (c * t₀) := by
        rw [mem_ball, dist_eq_norm]
        have : 0 < q (0, x) := lt_of_not_ge hq0
        simp only [q] at this
        have : 0 ≤ c * t₀ := by positivity
        nlinarith [norm_nonneg (x - x₀)]
      have hA0 : A (0, x) = 0 := h1 x (ball_subset_closedBall hxb)
      have hG0 : ∀ i, G i (0, x) = 0 := by
        intro i
        have hz : (fun y => W (0, y)) =ᶠ[𝓝 x] fun _ => (0 : ℝ) := by
          filter_upwards [isOpen_ball.mem_nhds hxb] with y hy
          exact h0 y (ball_subset_closedBall hy)
        have hf := (wave_aux_space (hDd (0, x))).fderiv
        rw [hz.fderiv_eq] at hf
        have := congrArg (fun L => L (EuclideanSpace.single i (1 : ℝ))) hf
        simpa [G, η] using this.symm
      simp [K, hA0, hG0]
  have hE0 : ∫ x, K (0, x) = 0 := by simp [hK0]
  have hKz : ∀ t ∈ Icc (0 : ℝ) t₀, ∀ x, K (t, x) = 0 := by
    intro t ht x
    have hEt : ∫ x, K (t, x) = 0 :=
      le_antisymm (hE0 ▸ hanti ⟨le_rfl, ht₀⟩ ht ht.1) (integral_nonneg fun x => hKnn _)
    have hint : Integrable fun x => K (t, x) :=
      wave_aux_integrable x₀ (c * t₀) (hKc.comp (hsec t)) fun x hx => by
        simp [K, (hvan _ (hqneg t ht x hx)).1]
    have hae := (integral_eq_zero_iff_of_nonneg (fun x => hKnn _) hint).1 hEt
    have := (Continuous.ae_eq_iff_eq volume (hKc.comp (hsec t)) continuous_const).1 hae
    exact congrFun this x
  -- so the time rate at `x₀` vanishes on `[0, t₀)`
  have hAz : ∀ s ∈ Ico (0 : ℝ) t₀, A (s, x₀) = 0 := by
    intro s hs
    have hKs := hKz s (Ico_subset_Icc_self hs) x₀
    have hψpos : 0 < ψ (s, x₀) := by
      apply expNegInvGlue.pos_of_pos
      show 0 < c ^ 2 * (t₀ - s) ^ 2 - ‖x₀ - x₀‖ ^ 2
      have : 0 < t₀ - s := by linarith [hs.2]
      rw [sub_self, norm_zero]
      nlinarith [pow_pos (mul_pos hc this) 2]
    have he : A (s, x₀) ^ 2 + c ^ 2 * ∑ i, G i (s, x₀) ^ 2 = 0 := by
      rcases mul_eq_zero.1 hKs with h | h
      · exact absurd h hψpos.ne'
      · exact h
    have hS : 0 ≤ c ^ 2 * ∑ i, G i (s, x₀) ^ 2 := by positivity
    have : A (s, x₀) ^ 2 = 0 := le_antisymm (by linarith) (sq_nonneg _)
    exact pow_eq_zero_iff (n := 2) (by norm_num) |>.1 this
  have hconst := constant_of_has_deriv_right_zero (f := fun s => W (s, x₀)) (a := 0) (b := t₀)
    (fun s _ => (hW.continuous.comp (continuous_id.prodMk continuous_const)).continuousAt
      |>.continuousWithinAt)
    (fun s hs => by
      have := wave_aux_time (hDd (s, x₀))
      have h0' : D (s, x₀) (1, 0) = 0 := hAz s hs
      rw [h0'] at this
      exact this.hasDerivWithinAt)
    t₀ ⟨ht₀, le_rfl⟩
  rw [hconst]
  exact h0 x₀ (mem_closedBall_self (by positivity))

lemma wave_aux_iteratedDeriv {d : ℕ} {U : ℝ × EuclideanSpace ℝ (Fin d) → ℝ}
    (hU : ContDiff ℝ 2 U) (t : ℝ) (x : EuclideanSpace ℝ (Fin d)) :
    iteratedDeriv 2 (fun s => U (s, x)) t = fderiv ℝ (fderiv ℝ U) (t, x) (1, 0) (1, 0) := by
  have hd : ∀ p, HasFDerivAt U (fderiv ℝ U p) p :=
    fun p => (hU.differentiable (by norm_num) p).hasFDerivAt
  have hd2 : ∀ p, HasFDerivAt (fderiv ℝ U) (fderiv ℝ (fderiv ℝ U) p) p :=
    fun p => ((hU.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num) p).hasFDerivAt
  have h1 : deriv (fun s => U (s, x)) = fun s => fderiv ℝ U (s, x) (1, 0) :=
    funext fun s => (wave_aux_time (hd (s, x))).deriv
  rw [iteratedDeriv_succ, iteratedDeriv_one, h1]
  have := wave_aux_time ((hd2 (t, x)).clm_apply
    (hasFDerivAt_const ((1 : ℝ), (0 : EuclideanSpace ℝ (Fin d))) (t, x)))
  rw [this.deriv]
  simp

lemma wave_aux_deriv {d : ℕ} {U : ℝ × EuclideanSpace ℝ (Fin d) → ℝ}
    (hU : ContDiff ℝ 2 U) (t : ℝ) (x : EuclideanSpace ℝ (Fin d)) :
    deriv (fun s => U (s, x)) t = fderiv ℝ U (t, x) (1, 0) :=
  (wave_aux_time ((hU.differentiable (by norm_num) _).hasFDerivAt)).deriv

lemma wave_aux_laplacian {d : ℕ} {U : ℝ × EuclideanSpace ℝ (Fin d) → ℝ}
    (hU : ContDiff ℝ 2 U) (t : ℝ) (x : EuclideanSpace ℝ (Fin d)) :
    Δ (fun y => U (t, y)) x = ∑ i, fderiv ℝ (fderiv ℝ U) (t, x)
      (0, EuclideanSpace.single i 1) (0, EuclideanSpace.single i 1) := by
  have hd : ∀ p, HasFDerivAt U (fderiv ℝ U p) p :=
    fun p => (hU.differentiable (by norm_num) p).hasFDerivAt
  have hd2 : ∀ p, HasFDerivAt (fderiv ℝ U) (fderiv ℝ (fderiv ℝ U) p) p :=
    fun p => ((hU.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num) p).hasFDerivAt
  have h1 : fderiv ℝ (fun y => U (t, y)) = fun y =>
      (fderiv ℝ U (t, y)).comp (ContinuousLinearMap.inr ℝ ℝ _) :=
    funext fun y => (wave_aux_space (hd (t, y))).fderiv
  rw [InnerProductSpace.laplacian_eq_iteratedFDeriv_orthonormalBasis _ (EuclideanSpace.basisFun (Fin d) ℝ)]
  simp only [iteratedFDeriv_two_apply, EuclideanSpace.basisFun_apply, h1]
  refine Finset.sum_congr rfl fun i _ => ?_
  have := (wave_aux_space (hd2 (t, x))).clm_comp
    (hasFDerivAt_const (ContinuousLinearMap.inr ℝ ℝ (EuclideanSpace ℝ (Fin d))) x)
  rw [this.fderiv]
  simp

#print axioms wave_aux_time
#print axioms wave_aux_space
#print axioms wave_aux_integrable
#print axioms wave_aux_glue_deriv
#print axioms wave_aux_hasDerivAt_integral
#print axioms wave_aux_core
#print axioms wave_aux_iteratedDeriv
#print axioms wave_aux_deriv
#print axioms wave_aux_laplacian

end WaveHelpers

/-- Domain of dependence for the wave equation in any number `d` of space dimensions.
Let `c > 0`, and let `u` and `v` be solutions with continuous second rates of
`u_tt = c² Δu` for `0 ≤ t ≤ t₀` on the whole space. If their starting shapes and starting
speeds agree on the ball of radius `c·t₀` around `x₀`, then `u` and `v` agree at `x₀` at time
`t₀`: the answer there depends only on the starting data within distance `c·t₀`. -/
theorem wave_solution_depends_only_on_data_in_backward_cone
    {d : ℕ} (c t₀ : ℝ) (x₀ : EuclideanSpace ℝ (Fin d))
    (u v : ℝ → EuclideanSpace ℝ (Fin d) → ℝ)
    (hc : 0 < c) (ht₀ : 0 ≤ t₀)
    (hu : ContDiff ℝ 2 (fun p : ℝ × EuclideanSpace ℝ (Fin d) => u p.1 p.2))
    (hv : ContDiff ℝ 2 (fun p : ℝ × EuclideanSpace ℝ (Fin d) => v p.1 p.2))
    (hu_wave : ∀ t ∈ Set.Icc (0 : ℝ) t₀, ∀ x,
      iteratedDeriv 2 (fun s => u s x) t = c ^ 2 * Δ (u t) x)
    (hv_wave : ∀ t ∈ Set.Icc (0 : ℝ) t₀, ∀ x,
      iteratedDeriv 2 (fun s => v s x) t = c ^ 2 * Δ (v t) x)
    (h_shape : ∀ y ∈ closedBall x₀ (c * t₀), u 0 y = v 0 y)
    (h_speed : ∀ y ∈ closedBall x₀ (c * t₀),
      deriv (fun s => u s y) 0 = deriv (fun s => v s y) 0) :
    u t₀ x₀ = v t₀ x₀ := by
  set U : ℝ × EuclideanSpace ℝ (Fin d) → ℝ := fun p => u p.1 p.2 with hUdef
  set V : ℝ × EuclideanSpace ℝ (Fin d) → ℝ := fun p => v p.1 p.2 with hVdef
  have hUd : Differentiable ℝ U := hu.differentiable (by norm_num)
  have hVd : Differentiable ℝ V := hv.differentiable (by norm_num)
  have hU1d : Differentiable ℝ (fderiv ℝ U) :=
    (hu.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  have hV1d : Differentiable ℝ (fderiv ℝ V) :=
    (hv.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  have hD : fderiv ℝ (fun p => U p - V p) = fun p => fderiv ℝ U p - fderiv ℝ V p :=
    funext fun p => fderiv_sub (hUd p) (hVd p)
  have hD2 : ∀ p, fderiv ℝ (fderiv ℝ (fun p => U p - V p)) p =
      fderiv ℝ (fderiv ℝ U) p - fderiv ℝ (fderiv ℝ V) p := by
    intro p
    rw [hD]
    exact fderiv_sub (hU1d p) (hV1d p)
  have key := wave_aux_core (fun p => U p - V p) (hu.sub hv) c t₀ x₀ hc ht₀
    (fun t ht x => by
      rw [hD2]
      have e1 := wave_aux_iteratedDeriv hu t x
      have e2 := wave_aux_iteratedDeriv hv t x
      have l1 := wave_aux_laplacian hu t x
      have l2 := wave_aux_laplacian hv t x
      have w1 := hu_wave t ht x
      have w2 := hv_wave t ht x
      simp only [sub_apply, Finset.sum_sub_distrib]
      have a1 : fderiv ℝ (fderiv ℝ U) (t, x) (1, 0) (1, 0) =
          c ^ 2 * ∑ i, fderiv ℝ (fderiv ℝ U) (t, x)
            (0, EuclideanSpace.single i 1) (0, EuclideanSpace.single i 1) := by
        rw [← e1, ← l1]; exact w1
      have a2 : fderiv ℝ (fderiv ℝ V) (t, x) (1, 0) (1, 0) =
          c ^ 2 * ∑ i, fderiv ℝ (fderiv ℝ V) (t, x)
            (0, EuclideanSpace.single i 1) (0, EuclideanSpace.single i 1) := by
        rw [← e2, ← l2]; exact w2
      rw [a1, a2]
      ring)
    (fun y hy => by simp [U, V, h_shape y hy])
    (fun y hy => by
      rw [hD]
      simp only [sub_apply]
      rw [← wave_aux_deriv hu 0 y, ← wave_aux_deriv hv 0 y]
      exact sub_eq_zero.2 (h_speed y hy))
  exact sub_eq_zero.1 key

/-- Domain of influence for the wave equation. Let `c > 0`, and let `u` and `v` be solutions
with continuous second rates of `u_tt = c² Δu` for `0 ≤ s ≤ t`, whose starting shapes and
speeds differ only inside a region `D`. Then at time `t` they agree at every point `x` farther
than `c·t` from every point of `D`: data in `D` reach only points within `c·t` of `D`. -/
theorem wave_data_influence_stays_within_ct
    {d : ℕ} (c t : ℝ) (D : Set (EuclideanSpace ℝ (Fin d))) (x : EuclideanSpace ℝ (Fin d))
    (u v : ℝ → EuclideanSpace ℝ (Fin d) → ℝ)
    (hc : 0 < c) (ht : 0 ≤ t)
    (hu : ContDiff ℝ 2 (fun p : ℝ × EuclideanSpace ℝ (Fin d) => u p.1 p.2))
    (hv : ContDiff ℝ 2 (fun p : ℝ × EuclideanSpace ℝ (Fin d) => v p.1 p.2))
    (hu_wave : ∀ s ∈ Set.Icc (0 : ℝ) t, ∀ y,
      iteratedDeriv 2 (fun r => u r y) s = c ^ 2 * Δ (u s) y)
    (hv_wave : ∀ s ∈ Set.Icc (0 : ℝ) t, ∀ y,
      iteratedDeriv 2 (fun r => v r y) s = c ^ 2 * Δ (v s) y)
    (h_shape : ∀ y ∉ D, u 0 y = v 0 y)
    (h_speed : ∀ y ∉ D, deriv (fun s => u s y) 0 = deriv (fun s => v s y) 0)
    (hx : ∀ y ∈ D, c * t < dist x y) :
    u t x = v t x := by
  have hnot : ∀ y ∈ closedBall x (c * t), y ∉ D := by
    intro y hy hyD
    have h1 := hx y hyD
    rw [mem_closedBall, dist_comm] at hy
    linarith
  exact wave_solution_depends_only_on_data_in_backward_cone c t x u v hc ht hu hv hu_wave hv_wave
    (fun y hy => h_shape y (hnot y hy)) (fun y hy => h_speed y (hnot y hy))

/-- Diffusion's instant reach. Heat a stretch of a line, from `b - a` to `b + a` with `a > 0`,
by one unit above the surroundings, and let it spread by the heat equation `u_t = κ u_xx` with
`κ > 0`. The heat-kernel solution `u(x, t) = ∫_{b-a}^{b+a} e^{-(x-s)²/(4κt)} / √(4πκt) ds` is
strictly positive at every point `x` after every time `t > 0`, however far `x` is from the hot
spot: for the heat equation the domain of influence is the whole line. -/
theorem heat_hot_spot_reaches_every_point_instantly
    (κ a b t x : ℝ) (hκ : 0 < κ) (ha : 0 < a) (ht : 0 < t) :
    0 < ∫ s in (b - a)..(b + a),
      Real.exp (-(x - s) ^ 2 / (4 * κ * t)) / Real.sqrt (4 * Real.pi * κ * t) := by
  apply intervalIntegral.intervalIntegral_pos_of_pos_on
  · apply Continuous.intervalIntegrable
    fun_prop
  · intro s _
    have : 0 < 4 * Real.pi * κ * t := by positivity
    exact div_pos (Real.exp_pos _) (Real.sqrt_pos.2 this)
  · linarith

-- The card's worked numbers, in SI units as exact fractions.
-- Wave speed: c² = T/ρ = 100 N / (1/100 kg/m), so c = 100 m/s.
example : (100 : ℚ) ^ 2 = 100 / (1 / 100) := by norm_num
-- Dependence of (10 cm, 1 ms) at 10 cm per ms: from 0 cm to 20 cm.
example : (10 : ℚ) - 10 * 1 = 0 ∧ (10 : ℚ) + 10 * 1 = 20 := by norm_num
-- Influence of the tap (half-width 1 cm) at 1 ms: |x| ≤ 11 cm.
example : (1 : ℚ) + 10 * 1 = 11 := by norm_num
-- u(10 cm, 1 ms) = v₀ · (1 cm of tap) / (2c) = 1/40000 m = 25 µm.
example : (1 / 2 : ℚ) * (1 / 100) / (2 * 100) = 25 / 1000000 := by norm_num
-- First motion at 10 cm: (10 - 1) cm / (10 cm per ms) = 9/10 ms; full by 11/10 ms.
example : ((10 : ℚ) - 1) / 10 = 9 / 10 ∧ ((10 : ℚ) + 1) / 10 = 11 / 10 := by norm_num
-- Plateau v₀ a / c = 0.5 · 0.01 / 100 m = 50 µm.
example : (1 / 2 : ℚ) * (1 / 100) / 100 = 50 / 1000000 := by norm_num
-- 3-D ball tap at r = 10 cm, t = 1 ms: v₀ (a² - (r - ct)²) / (4 c r) = 1.25 µm.
example : (1 / 2 : ℚ) * ((1 / 100) ^ 2 - (1 / 10 - 100 * (1 / 1000)) ^ 2) / (4 * 100 * (1 / 10))
    = 125 / 100000000 := by norm_num
-- Point-source rule for the heat peak: x₀² / (2κ) with κ = 12 mm²/s is 1250/3 s, about 416.7 s.
example : (1 / 10 : ℚ) ^ 2 / (2 * (12 / 1000000)) = 1250 / 3 := by norm_num

#print axioms wave_solution_depends_only_on_data_in_backward_cone
#print axioms wave_data_influence_stays_within_ct
#print axioms heat_hot_spot_reaches_every_point_instantly
