-- Hille-Yosida: an operator generates a strongly continuous flow with ‖T(t)‖ ≤ e^(ωt) exactly when it is closed, densely defined, and has a resolvent of size at most 1/(λ - ω) at every real λ > ω.
import Mathlib.Topology.Algebra.Module.LinearPMap
import Mathlib.Analysis.Normed.Operator.Basic
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.MeanValue

open Filter Topology
open scoped LinearPMap

noncomputable section

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]

/-- `R` is the resolvent `R(λ, A) = (λI - A)⁻¹` of the operator `A` with domain `D(A)`:
a bounded operator on the whole space whose answers lie in `D(A)` and solve the balance problem
`(λI - A) u = f`, and which undoes `λI - A` on `D(A)`. Such an `R` exists exactly when `λ` is in
the resolvent set `ρ(A)`. -/
def IsResolvent (A : E →ₗ.[ℝ] E) (lam : ℝ) (R : E →L[ℝ] E) : Prop :=
  (∀ f : E, ∃ h : R f ∈ A.domain, lam • R f - A ⟨R f, h⟩ = f) ∧
    ∀ u : A.domain, R (lam • (u : E) - A u) = u

/-- `T` is a strongly continuous semigroup (a flow) for times `t ≥ 0`: `T(0) = I`,
`T(s + t) = T(s) T(t)`, and `T(t) f → f` in size as `t → 0` from above, for every `f`. -/
def IsStronglyContinuousSemigroup (T : ℝ → E →L[ℝ] E) : Prop :=
  T 0 = 1 ∧ (∀ s t : ℝ, 0 ≤ s → 0 ≤ t → T (s + t) = T s * T t) ∧
    ∀ f : E, Tendsto (fun t => T t f) (𝓝[≥] 0) (𝓝 f)

/-- `A` is the generator of the flow `T`: `u` is in `D(A)` with `A u = v` exactly when
`(T(t) u - u) / t → v` in size as `t → 0` from above. -/
def IsGenerator (T : ℝ → E →L[ℝ] E) (A : E →ₗ.[ℝ] E) : Prop :=
  ∀ u v : E, Tendsto (fun t : ℝ => t⁻¹ • (T t u - u)) (𝓝[>] 0) (𝓝 v) ↔
    ∃ h : u ∈ A.domain, A ⟨u, h⟩ = v

section HYHelpers

theorem hy_sg_bound_le {T : ℝ → E →L[ℝ] E} {ω : ℝ}
    (hb : ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t)) {s M : ℝ} (hs0 : 0 ≤ s) (hsM : s ≤ M) :
    ‖T s‖ ≤ Real.exp (|ω| * M) := by
  refine (hb s hs0).trans (Real.exp_le_exp.2 ?_)
  calc ω * s ≤ |ω| * s := mul_le_mul_of_nonneg_right (le_abs_self ω) hs0
    _ ≤ |ω| * M := mul_le_mul_of_nonneg_left hsM (abs_nonneg ω)

theorem hy_sg_continuousOn {T : ℝ → E →L[ℝ] E} {ω : ℝ} (hT : IsStronglyContinuousSemigroup T)
    (hb : ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t)) (x : E) :
    ContinuousOn (fun t => T t x) (Set.Ici 0) := by
  intro t ht
  have ht' : (0:ℝ) ≤ t := ht
  rw [Metric.continuousWithinAt_iff]
  intro ε hε
  set K := Real.exp (|ω| * (t + 1)) with hKdef
  have hK : 0 < K := Real.exp_pos _
  obtain ⟨δ, hδ, hδ'⟩ := Metric.tendsto_nhdsWithin_nhds.1 (hT.2.2 x) (ε / K) (by positivity)
  refine ⟨min δ 1, by positivity, fun {s} hs hst => ?_⟩
  have hs' : (0:ℝ) ≤ s := hs
  have hd : |s - t| < min δ 1 := by rw [← Real.dist_eq]; exact hst
  have hd1 : |s - t| < δ := lt_of_lt_of_le hd (min_le_left _ _)
  have hd2 : |s - t| < 1 := lt_of_lt_of_le hd (min_le_right _ _)
  rcases le_total t s with h | h
  · have e : T s x - T t x = T t (T (s - t) x - x) := by
      have : T s = T t * T (s - t) := by
        rw [← hT.2.1 t (s - t) ht' (by linarith)]; congr 1; ring
      rw [this, map_sub]; rfl
    have hsmall : ‖T (s - t) x - x‖ < ε / K := by
      have := hδ' (x := s - t) (show (0:ℝ) ≤ s - t by linarith)
        (by rw [Real.dist_eq, sub_zero]; exact hd1)
      rwa [dist_eq_norm] at this
    rw [dist_eq_norm, e]
    calc ‖T t (T (s - t) x - x)‖ ≤ ‖T t‖ * ‖T (s - t) x - x‖ := ContinuousLinearMap.le_opNorm _ _
      _ ≤ K * ‖T (s - t) x - x‖ :=
          mul_le_mul_of_nonneg_right (hy_sg_bound_le hb ht' (by linarith)) (norm_nonneg _)
      _ < K * (ε / K) := by gcongr
      _ = ε := by field_simp
  · have e : T s x - T t x = -(T s (T (t - s) x - x)) := by
      have : T t = T s * T (t - s) := by
        rw [← hT.2.1 s (t - s) hs' (by linarith)]; congr 1; ring
      rw [this, map_sub, neg_sub]; rfl
    have hsmall : ‖T (t - s) x - x‖ < ε / K := by
      have := hδ' (x := t - s) (show (0:ℝ) ≤ t - s by linarith)
        (by rw [Real.dist_eq, sub_zero, abs_sub_comm]; exact hd1)
      rwa [dist_eq_norm] at this
    rw [dist_eq_norm, e, norm_neg]
    calc ‖T s (T (t - s) x - x)‖ ≤ ‖T s‖ * ‖T (t - s) x - x‖ := ContinuousLinearMap.le_opNorm _ _
      _ ≤ K * ‖T (t - s) x - x‖ :=
          mul_le_mul_of_nonneg_right (hy_sg_bound_le hb hs' (by linarith)) (norm_nonneg _)
      _ < K * (ε / K) := by gcongr
      _ = ε := by field_simp

theorem hy_sg_hasDerivWithinAt {T : ℝ → E →L[ℝ] E} (hT : IsStronglyContinuousSemigroup T)
    {y z : E} (hyz : Tendsto (fun h : ℝ => h⁻¹ • (T h y - y)) (𝓝[>] 0) (𝓝 z)) {t : ℝ}
    (ht : 0 ≤ t) : HasDerivWithinAt (fun s => T s y) (T t z) (Set.Ici t) t := by
  rw [hasDerivWithinAt_iff_tendsto_slope, Set.Ici_sdiff_left]
  have h1 : Tendsto (fun s => s - t) (𝓝[>] t) (𝓝[>] 0) := by
    apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
    · have := ((continuous_sub_right t).tendsto t).mono_left (nhdsWithin_le_nhds (s := Set.Ioi t))
      simpa using this
    · filter_upwards [self_mem_nhdsWithin] with s hs
      simpa using hs
  have h2 := ((T t).continuous.tendsto z).comp (hyz.comp h1)
  apply h2.congr'
  filter_upwards [self_mem_nhdsWithin] with s hs
  have hs' : t ≤ s := le_of_lt hs
  have : T s = T t * T (s - t) := by
    rw [← hT.2.1 t (s - t) ht (by linarith)]; congr 1; ring
  simp only [Function.comp, slope_def_module, this, map_smul, map_sub]
  rfl

theorem hy_sg_inj {T : ℝ → E →L[ℝ] E} {ω : ℝ} (hT : IsStronglyContinuousSemigroup T)
    (hb : ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t)) {lam : ℝ} (hlam : ω < lam) {y : E}
    (hy : Tendsto (fun h : ℝ => h⁻¹ • (T h y - y)) (𝓝[>] 0) (𝓝 (lam • y))) : y = 0 := by
  let f := fun s : ℝ => Real.exp (-lam * s) • T s y
  have hcont : ContinuousOn f (Set.Icc 0 1) :=
    ((Real.continuous_exp.comp (continuous_const.mul continuous_id)).continuousOn.smul
      (hy_sg_continuousOn hT hb y)).mono Set.Icc_subset_Ici_self
  have hderiv : ∀ s ∈ Set.Ico (0:ℝ) 1, HasDerivWithinAt f 0 (Set.Ici s) s := by
    intro s hs
    have h1 := hy_sg_hasDerivWithinAt hT hy hs.1
    have h2 : HasDerivWithinAt (fun s => Real.exp (-lam * s)) (Real.exp (-lam * s) * (-lam * 1))
        (Set.Ici s) s := ((hasDerivAt_id s).const_mul (-lam)).exp.hasDerivWithinAt
    have := h2.smul h1
    convert this using 1
    rw [map_smul, smul_smul, ← add_smul]
    simp
  have hc := constant_of_has_deriv_right_zero hcont hderiv 1 ⟨zero_le_one, le_rfl⟩
  simp only [f, mul_zero, Real.exp_zero, one_smul, hT.1, mul_one] at hc
  change Real.exp (-lam) • T 1 y = y at hc
  have hn : ‖y‖ ≤ Real.exp (-lam) * Real.exp ω * ‖y‖ := by
    calc ‖y‖ = ‖Real.exp (-lam) • T 1 y‖ := by rw [hc]
      _ = Real.exp (-lam) * ‖T 1 y‖ := by
          rw [norm_smul, Real.norm_of_nonneg (Real.exp_pos _).le]
      _ ≤ Real.exp (-lam) * (Real.exp ω * ‖y‖) := by
          gcongr
          calc ‖T 1 y‖ ≤ ‖T 1‖ * ‖y‖ := ContinuousLinearMap.le_opNorm _ _
            _ ≤ Real.exp (ω * 1) * ‖y‖ := by gcongr; exact hb 1 zero_le_one
            _ = Real.exp ω * ‖y‖ := by rw [mul_one]
      _ = Real.exp (-lam) * Real.exp ω * ‖y‖ := by ring
  have hlt : Real.exp (-lam) * Real.exp ω < 1 := by
    rw [← Real.exp_add, Real.exp_lt_one_iff]; linarith
  have : ‖y‖ = 0 := by nlinarith [norm_nonneg y]
  exact norm_eq_zero.mp this

theorem hy_res_ident {A : E →ₗ.[ℝ] E} {lam mu : ℝ} {R S : E →L[ℝ] E}
    (hR : IsResolvent A lam R) (hS : IsResolvent A mu S) (f : E) :
    R f - S f = (mu - lam) • R (S f) := by
  obtain ⟨h, hf⟩ := hS.1 f
  have := hR.2 ⟨S f, h⟩
  have e : lam • S f - A ⟨S f, h⟩ = (lam - mu) • S f + (mu • S f - A ⟨S f, h⟩) := by
    rw [sub_smul]; abel
  rw [hf] at e
  change R (lam • S f - A ⟨S f, h⟩) = S f at this
  rw [e, map_add, map_smul] at this
  calc R f - S f = R f - ((lam - mu) • R (S f) + R f) := by rw [this]
    _ = (mu - lam) • R (S f) := by module

theorem hy_res_comm {A : E →ₗ.[ℝ] E} {lam mu : ℝ} {R S : E →L[ℝ] E}
    (hR : IsResolvent A lam R) (hS : IsResolvent A mu S) : Commute R S := by
  ext f
  have h1 := hy_res_ident hR hS f
  have h2 := hy_res_ident hS hR f
  show R (S f) = S (R f)
  by_cases h : lam = mu
  · subst h
    have hRS : R = S := by
      ext g; have := hy_res_ident hR hS g; rw [sub_self, zero_smul, sub_eq_zero] at this
      exact this
    rw [hRS]
  · have : (mu - lam) • (R (S f) - S (R f)) = 0 := by
      rw [smul_sub, ← h1, show (mu - lam) = -(lam - mu) by ring, neg_smul, ← h2]; abel
    rcases smul_eq_zero.1 this with h0 | h0
    · exact absurd (by linarith [sub_eq_zero.1 h0]) h
    · exact sub_eq_zero.1 h0

theorem hy_closed_of_res {A : E →ₗ.[ℝ] E} {lam : ℝ} {R : E →L[ℝ] E}
    (hR : IsResolvent A lam R) : A.IsClosed := by
  have : (A.graph : Set (E × E)) = {p | R (lam • p.1 - p.2) = p.1} := by
    ext ⟨x, y⟩
    simp only [SetLike.mem_coe, LinearPMap.mem_graph_iff, Set.mem_ofPred_eq]
    constructor
    · rintro ⟨u, rfl, rfl⟩; exact hR.2 u
    · intro h
      obtain ⟨hd, he⟩ := hR.1 (lam • x - y)
      revert hd he
      rw [h]
      intro hd he
      exact ⟨⟨x, hd⟩, rfl, sub_right_injective he⟩
  rw [LinearPMap.IsClosed, this]
  exact isClosed_eq (R.continuous.comp ((continuous_const.smul continuous_fst).sub continuous_snd))
    continuous_fst

theorem hy_tendsto_of_dense {F : ℕ → E →L[ℝ] E} {C : ℝ} (hC : ∀ n, ‖F n‖ ≤ C) {D : Set E}
    (hD : Dense D) (h : ∀ z ∈ D, Tendsto (fun n => F n z) atTop (𝓝 z)) (x : E) :
    Tendsto (fun n => F n x) atTop (𝓝 x) := by
  rw [Metric.tendsto_atTop]
  intro ε hε
  have hC0 : 0 ≤ C := (norm_nonneg _).trans (hC 0)
  obtain ⟨z, hz, hxz⟩ := hD.exists_dist_lt x (show 0 < ε / (3 * (C + 1)) by positivity)
  obtain ⟨N, hN⟩ := Metric.tendsto_atTop.1 (h z hz) (ε / 3) (by positivity)
  refine ⟨N, fun n hn => ?_⟩
  have h1 : dist (F n x) (F n z) ≤ C * dist x z := by
    rw [dist_eq_norm, dist_eq_norm, ← map_sub]
    exact (ContinuousLinearMap.le_opNorm _ _).trans (mul_le_mul_of_nonneg_right (hC n) (norm_nonneg _))
  have h2 := hN n hn
  have e : (C + 1) * (ε / (3 * (C + 1))) = ε / 3 := by field_simp
  have h3 : C * dist x z ≤ ε / 3 := by
    rw [← e]
    calc C * dist x z ≤ (C + 1) * dist x z := by nlinarith [dist_nonneg (x := x) (y := z)]
      _ ≤ (C + 1) * (ε / (3 * (C + 1))) := by gcongr
  have h4 : dist z x ≤ ε / 3 := by
    rw [dist_comm]
    calc dist x z ≤ ε / (3 * (C + 1)) := hxz.le
      _ ≤ ε / 3 := by
        apply div_le_div_of_nonneg_left hε.le (by norm_num); nlinarith
  linarith [dist_triangle4 (F n x) (F n z) z x]

theorem hy_cauchy_of_dense {F : ℕ → E →L[ℝ] E} {C : ℝ} (hC : ∀ n, ‖F n‖ ≤ C) {D : Set E}
    (hD : Dense D) (h : ∀ z ∈ D, CauchySeq (fun n => F n z)) (x : E) :
    CauchySeq (fun n => F n x) := by
  rw [Metric.cauchySeq_iff]
  intro ε hε
  have hC0 : 0 ≤ C := (norm_nonneg _).trans (hC 0)
  obtain ⟨z, hz, hxz⟩ := hD.exists_dist_lt x (show 0 < ε / (3 * (C + 1)) by positivity)
  obtain ⟨N, hN⟩ := Metric.cauchySeq_iff.1 (h z hz) (ε / 3) (by positivity)
  refine ⟨N, fun m hm n hn => ?_⟩
  have hb : ∀ k, dist (F k x) (F k z) ≤ ε / 3 := by
    intro k
    have e : (C + 1) * (ε / (3 * (C + 1))) = ε / 3 := by field_simp
    rw [dist_eq_norm, ← map_sub, ← e]
    calc ‖F k (x - z)‖ ≤ ‖F k‖ * ‖x - z‖ := ContinuousLinearMap.le_opNorm _ _
      _ ≤ (C + 1) * ‖x - z‖ := by gcongr; linarith [hC k]
      _ ≤ (C + 1) * (ε / (3 * (C + 1))) := by rw [← dist_eq_norm]; gcongr
  have h2 := hN m hm n hn
  have := dist_triangle4 (F m x) (F m z) (F n z) (F n x)
  rw [dist_comm (F n z)] at this
  linarith [hb m, hb n]

theorem hy_tendsto_apply {F : ℕ → E →L[ℝ] E} {C : ℝ} (hC : ∀ n, ‖F n‖ ≤ C) {y L : E}
    (hF : Tendsto (fun n => F n y) atTop (𝓝 L)) {yn : ℕ → E} (hy : Tendsto yn atTop (𝓝 y)) :
    Tendsto (fun n => F n (yn n)) atTop (𝓝 L) := by
  have h0 : Tendsto (fun n => F n (yn n - y)) atTop (𝓝 0) := by
    apply squeeze_zero_norm (fun n => (ContinuousLinearMap.le_opNorm _ _).trans
      (mul_le_mul_of_nonneg_right (hC n) (norm_nonneg _)))
    simpa using (tendsto_const_nhds (x := C)).mul (tendsto_iff_norm_sub_tendsto_zero.1 hy)
  have := h0.add hF
  simp only [map_sub, sub_add_cancel, zero_add] at this
  exact this

theorem hy_norm_exp_le [CompleteSpace E] (X : E →L[ℝ] E) :
    ‖NormedSpace.exp X‖ ≤ Real.exp ‖X‖ := by
  rw [congrFun (NormedSpace.exp_eq_tsum ℝ) X]
  have hs := NormedSpace.norm_expSeries_summable' (𝕂 := ℝ) X
  refine (norm_tsum_le_tsum_norm hs).trans ?_
  rw [Real.exp_eq_exp_ℝ, congrFun (NormedSpace.exp_eq_tsum ℝ) ‖X‖]
  refine hs.tsum_le_tsum (fun n => ?_) (NormedSpace.expSeries_summable' (𝕂 := ℝ) ‖X‖)
  rw [norm_smul, smul_eq_mul, Real.norm_of_nonneg (by positivity)]
  gcongr
  rcases n with _ | n
  · simp only [pow_zero]; exact ContinuousLinearMap.norm_id_le
  · exact norm_pow_le' _ (Nat.succ_pos _)

open MeasureTheory

/-- The Laplace transform of the orbit `t ↦ T t f`, the candidate resolvent. -/
def hyLap (T : ℝ → E →L[ℝ] E) (lam : ℝ) (f : E) : E :=
  ∫ t in Set.Ioi (0:ℝ), Real.exp (-lam * t) • T t f

theorem hy_lap_cont {T : ℝ → E →L[ℝ] E} {ω : ℝ} (hT : IsStronglyContinuousSemigroup T)
    (hb : ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t)) (lam : ℝ) (f : E) :
    ContinuousOn (fun t => Real.exp (-lam * t) • T t f) (Set.Ici 0) :=
  (Real.continuous_exp.comp (continuous_const.mul continuous_id)).continuousOn.smul
    (hy_sg_continuousOn hT hb f)

theorem hy_lap_bound {T : ℝ → E →L[ℝ] E} {ω : ℝ}
    (hb : ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t)) (lam : ℝ) (f : E) :
    ∀ᵐ t ∂(volume.restrict (Set.Ioi (0:ℝ))),
      ‖Real.exp (-lam * t) • T t f‖ ≤ ‖f‖ * Real.exp ((ω - lam) * t) := by
  refine (ae_restrict_iff' measurableSet_Ioi).2 (Eventually.of_forall fun t ht => ?_)
  have ht' : (0:ℝ) ≤ t := le_of_lt ht
  rw [norm_smul, Real.norm_of_nonneg (Real.exp_pos _).le]
  calc Real.exp (-lam * t) * ‖T t f‖ ≤ Real.exp (-lam * t) * (Real.exp (ω * t) * ‖f‖) := by
        gcongr
        exact (ContinuousLinearMap.le_opNorm _ _).trans (by gcongr; exact hb t ht')
    _ = ‖f‖ * Real.exp ((ω - lam) * t) := by
        rw [show (ω - lam) * t = -lam * t + ω * t by ring, Real.exp_add]; ring

theorem hy_lap_integrable {T : ℝ → E →L[ℝ] E} {ω : ℝ} (hT : IsStronglyContinuousSemigroup T)
    (hb : ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t)) {lam : ℝ} (hlam : ω < lam) (f : E) :
    IntegrableOn (fun t => Real.exp (-lam * t) • T t f) (Set.Ioi 0) :=
  Integrable.mono' ((integrableOn_exp_mul_Ioi (a := ω - lam) (by linarith) 0).const_mul ‖f‖)
    (((hy_lap_cont hT hb lam f).mono Set.Ioi_subset_Ici_self).aestronglyMeasurable
      measurableSet_Ioi) (hy_lap_bound hb lam f)

theorem hy_lap_norm {T : ℝ → E →L[ℝ] E} {ω : ℝ}
    (hb : ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t)) {lam : ℝ} (hlam : ω < lam) (f : E) :
    ‖hyLap T lam f‖ ≤ 1 / (lam - ω) * ‖f‖ := by
  unfold hyLap
  refine (norm_integral_le_of_norm_le
    ((integrableOn_exp_mul_Ioi (a := ω - lam) (by linarith) 0).const_mul ‖f‖)
    (hy_lap_bound hb lam f)).trans_eq ?_
  rw [integral_const_mul, integral_exp_mul_Ioi (by linarith), mul_zero, Real.exp_zero]
  have : lam - ω ≠ 0 := by linarith
  have : ω - lam ≠ 0 := by linarith
  field_simp
  ring

theorem hy_shift_Ioi (g : ℝ → E) (h : ℝ) :
    ∫ t in Set.Ioi (0:ℝ), g (t + h) = ∫ s in Set.Ioi h, g s := by
  rw [← integral_indicator measurableSet_Ioi, ← integral_indicator measurableSet_Ioi]
  conv_rhs => rw [← integral_add_right_eq_self _ h]
  congr 1
  ext t
  simp only [Set.indicator, Set.mem_Ioi]
  congr 1
  apply propext
  constructor <;> intro hh <;> linarith

theorem hy_lap_gen {T : ℝ → E →L[ℝ] E} {ω : ℝ} [CompleteSpace E]
    (hT : IsStronglyContinuousSemigroup T)
    (hb : ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t)) {lam : ℝ} (hlam : ω < lam) (f : E) :
    Tendsto (fun h : ℝ => h⁻¹ • (T h (hyLap T lam f) - hyLap T lam f)) (𝓝[>] 0)
      (𝓝 (lam • hyLap T lam f - f)) := by
  set g := fun t => Real.exp (-lam * t) • T t f with hg
  have hint : IntegrableOn g (Set.Ioi 0) := hy_lap_integrable hT hb hlam f
  have hcont : ContinuousOn g (Set.Ici 0) := hy_lap_cont hT hb lam f
  have hI : HasDerivWithinAt (fun u => ∫ x in (0:ℝ)..u, g x) (g 0) (Set.Ici 0) 0 :=
    intervalIntegral.integral_hasDerivWithinAt_right (by simp)
      ((hcont.mono Set.Ioi_subset_Ici_self).stronglyMeasurableAtFilter_nhdsWithin
        measurableSet_Ioi 0)
      ((hcont 0 Set.self_mem_Ici).mono Set.Ioi_subset_Ici_self)
  have hg0 : g 0 = f := by
    simp only [g, mul_zero, Real.exp_zero, one_smul, hT.1]; rfl
  have hI1 : Tendsto (fun h : ℝ => h⁻¹ • ∫ x in (0:ℝ)..h, g x) (𝓝[>] 0) (𝓝 f) := by
    have := hasDerivWithinAt_iff_tendsto_slope.1 hI
    rw [Set.Ici_sdiff_left] at this
    rw [← hg0]
    refine this.congr' ?_
    filter_upwards with h
    simp [slope_def_module]
  have hI2 : Tendsto (fun h : ℝ => ∫ x in (0:ℝ)..h, g x) (𝓝[>] 0) (𝓝 0) := by
    have := hI.continuousWithinAt.tendsto.mono_left (nhdsWithin_mono _ Set.Ioi_subset_Ici_self)
    simpa using this
  have hE : Tendsto (fun h : ℝ => h⁻¹ * (Real.exp (lam * h) - 1)) (𝓝[>] 0) (𝓝 lam) := by
    have hd : HasDerivAt (fun h => Real.exp (lam * h)) (Real.exp (lam * 0) * (lam * 1)) 0 :=
      ((hasDerivAt_id (0:ℝ)).const_mul lam).exp
    simp only [mul_zero, Real.exp_zero, mul_one, one_mul] at hd
    have := hasDerivAt_iff_tendsto_slope.1 hd
    refine (this.mono_left (nhdsWithin_mono (0:ℝ) (s := Set.Ioi 0)
      (fun x hx => Set.mem_compl_singleton_iff.2 (ne_of_gt (Set.mem_Ioi.1 hx))))).congr' ?_
    filter_upwards with h
    simp [slope_def_field, div_eq_inv_mul]
  have hlim : Tendsto (fun h : ℝ => (h⁻¹ * (Real.exp (lam * h) - 1)) •
      (hyLap T lam f - ∫ x in (0:ℝ)..h, g x) - h⁻¹ • ∫ x in (0:ℝ)..h, g x) (𝓝[>] 0)
      (𝓝 (lam • hyLap T lam f - f)) := by
    have := (hE.smul ((tendsto_const_nhds (x := hyLap T lam f)).sub hI2)).sub hI1
    simpa using this
  refine hlim.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with h (hh : 0 < h)
  have hsplit : (∫ x in (0:ℝ)..h, g x) + ∫ x in Set.Ioi h, g x = hyLap T lam f :=
    intervalIntegral.integral_interval_add_Ioi hint (hint.mono_set (Set.Ioi_subset_Ioi hh.le))
  have hTR : T h (hyLap T lam f) = Real.exp (lam * h) • ∫ x in Set.Ioi h, g x := by
    unfold hyLap
    rw [← (T h).integral_comp_comm hint, ← hy_shift_Ioi g h, ← integral_smul]
    refine setIntegral_congr_fun measurableSet_Ioi (fun t (ht : 0 < t) => ?_)
    have : T (t + h) = T h * T t := by rw [add_comm]; exact hT.2.1 h t hh.le ht.le
    simp only [g, map_smul, this, smul_smul, ← Real.exp_add]
    congr 2
    ring
  rw [hTR, ← hsplit]
  module

theorem hy_lap_mem {T : ℝ → E →L[ℝ] E} {ω : ℝ} [CompleteSpace E] {A : E →ₗ.[ℝ] E}
    (hT : IsStronglyContinuousSemigroup T) (hgen : IsGenerator T A)
    (hb : ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t)) {lam : ℝ} (hlam : ω < lam) (f : E) :
    ∃ h : hyLap T lam f ∈ A.domain, lam • hyLap T lam f - A ⟨hyLap T lam f, h⟩ = f := by
  obtain ⟨h, hA⟩ := (hgen _ _).1 (hy_lap_gen hT hb hlam f)
  exact ⟨h, by rw [hA]; abel⟩

theorem hy_forward_res {T : ℝ → E →L[ℝ] E} {ω : ℝ} [CompleteSpace E] {A : E →ₗ.[ℝ] E}
    (hT : IsStronglyContinuousSemigroup T) (hgen : IsGenerator T A)
    (hb : ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t)) {lam : ℝ} (hlam : ω < lam) :
    ∃ R : E →L[ℝ] E, IsResolvent A lam R ∧ ‖R‖ ≤ 1 / (lam - ω) := by
  let L : E →ₗ[ℝ] E :=
    { toFun := hyLap T lam
      map_add' := by
        intro f1 f2
        unfold hyLap
        rw [← integral_add (hy_lap_integrable hT hb hlam f1) (hy_lap_integrable hT hb hlam f2)]
        congr 1; ext t; simp [smul_add]
      map_smul' := by
        intro c f
        unfold hyLap
        rw [← integral_smul]
        congr 1; ext t; simp [smul_comm c] }
  have hpos : 0 ≤ 1 / (lam - ω) := by
    have : 0 < lam - ω := by linarith
    positivity
  let R := L.mkContinuous (1 / (lam - ω)) (hy_lap_norm hb hlam)
  have hR : ∀ f, R f = hyLap T lam f := fun f => rfl
  have part1 : ∀ f : E, ∃ h : R f ∈ A.domain, lam • R f - A ⟨R f, h⟩ = f := by
    intro f; rw [hR]; exact hy_lap_mem hT hgen hb hlam f
  refine ⟨R, ⟨part1, fun u => ?_⟩, LinearMap.mkContinuous_norm_le _ hpos _⟩
  obtain ⟨hw, hw'⟩ := part1 (lam • (u : E) - A u)
  set w := R (lam • (u : E) - A u) with hwdef
  have h1 := (hgen w (A ⟨w, hw⟩)).2 ⟨hw, rfl⟩
  have h2 := (hgen u (A u)).2 ⟨u.2, rfl⟩
  have h3 := h1.sub h2
  have e : A ⟨w, hw⟩ - A u = lam • (w - u) := by
    rw [smul_sub]
    have := hw'
    rw [sub_eq_iff_eq_add] at this
    rw [this]; abel
  rw [e] at h3
  have h4 : Tendsto (fun h : ℝ => h⁻¹ • (T h (w - u) - (w - u))) (𝓝[>] 0)
      (𝓝 (lam • (w - u))) := by
    refine h3.congr' (Eventually.of_forall fun h => ?_)
    simp only [map_sub, smul_sub]
    abel
  have := hy_sg_inj hT hb hlam h4
  exact sub_eq_zero.1 this

theorem hy_forward_dense {T : ℝ → E →L[ℝ] E} {ω : ℝ} [CompleteSpace E] {A : E →ₗ.[ℝ] E}
    (hT : IsStronglyContinuousSemigroup T) (hgen : IsGenerator T A)
    (hb : ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t)) : Dense (A.domain : Set E) := by
  intro x
  set a : ℝ := 2 * |ω| + 1 with ha
  have ha0 : 0 < a := by positivity
  let lamn : ℕ → ℝ := fun n => n + a
  have hlpos : ∀ n, a ≤ lamn n := fun n => by simp [lamn]
  have hl : ∀ n, 0 < lamn n := fun n => lt_of_lt_of_le ha0 (hlpos n)
  have hlω : ∀ n, ω < lamn n := fun n => by
    have := hlpos n; have := le_abs_self ω; have := abs_nonneg ω; linarith
  have hTb : ∀ n, ∀ s : ℝ, 0 ≤ s → ‖T (s / lamn n) x‖ ≤ Real.exp (s / 2) * ‖x‖ := by
    intro n s hs
    refine (ContinuousLinearMap.le_opNorm _ _).trans (mul_le_mul_of_nonneg_right ?_ (norm_nonneg _))
    refine (hb _ (div_nonneg hs (hl n).le)).trans (Real.exp_le_exp.2 ?_)
    rw [show ω * (s / lamn n) = (ω * s) / lamn n by ring, div_le_iff₀ (hl n)]
    have h1 := hlpos n
    have h2 : ω * s ≤ |ω| * s := mul_le_mul_of_nonneg_right (le_abs_self ω) hs
    nlinarith [abs_nonneg ω]
  have hcontn : ∀ n, ContinuousOn (fun s => T (s / lamn n) x) (Set.Ioi 0) := fun n =>
    (hy_sg_continuousOn hT hb x).comp (continuous_id.div_const _).continuousOn
      (fun s hs => le_of_lt (div_pos hs (hl n)))
  have hi2 : IntegrableOn (fun s : ℝ => Real.exp (-s) • x) (Set.Ioi 0) := by
    have := (integrableOn_exp_mul_Ioi (a := -1) (by norm_num) 0).smul_const x
    simp only [neg_mul, one_mul] at this
    exact this
  have key : ∀ n, lamn n • hyLap T (lamn n) x - x =
      ∫ s in Set.Ioi (0:ℝ), Real.exp (-s) • (T (s / lamn n) x - x) := by
    intro n
    have e1 : lamn n • hyLap T (lamn n) x =
        ∫ s in Set.Ioi (0:ℝ), Real.exp (-s) • T (s / lamn n) x := by
      unfold hyLap
      have := integral_comp_mul_left_Ioi' (fun s => Real.exp (-s) • T (s / lamn n) x) 0 (hl n)
      rw [mul_zero] at this
      rw [← this]
      congr 2
      ext t
      have : lamn n ≠ 0 := (hl n).ne'
      congr 2
      · ring
      · field_simp
    have e2 : x = ∫ s in Set.Ioi (0:ℝ), Real.exp (-s) • x := by
      rw [integral_smul_const, integral_exp_neg_Ioi_zero, one_smul]
    have hi1 : IntegrableOn (fun s => Real.exp (-s) • T (s / lamn n) x) (Set.Ioi 0) := by
      refine Integrable.mono' ((integrableOn_exp_mul_Ioi (a := -(1/2)) (by norm_num) 0).mul_const ‖x‖)
        (((Real.continuous_exp.comp continuous_neg).continuousOn.smul (hcontn n)).aestronglyMeasurable
          measurableSet_Ioi) ?_
      refine (ae_restrict_iff' measurableSet_Ioi).2 (Eventually.of_forall fun s hs => ?_)
      rw [norm_smul, Real.norm_of_nonneg (Real.exp_pos _).le]
      calc Real.exp (-s) * ‖T (s / lamn n) x‖ ≤ Real.exp (-s) * (Real.exp (s / 2) * ‖x‖) := by
            gcongr; exact hTb n s (le_of_lt hs)
        _ = Real.exp (-(1/2) * s) * ‖x‖ := by
            rw [← mul_assoc, ← Real.exp_add]; congr 2; ring
    rw [e1]
    nth_rewrite 2 [e2]
    rw [← integral_sub hi1 hi2]
    congr 1; ext s; rw [smul_sub]
  have hdct : Tendsto (fun n => ∫ s in Set.Ioi (0:ℝ), Real.exp (-s) • (T (s / lamn n) x - x))
      atTop (𝓝 (∫ s in Set.Ioi (0:ℝ), (0:E))) := by
    refine tendsto_integral_of_dominated_convergence
      (fun s => (Real.exp (-(1/2) * s) + Real.exp (-1 * s)) * ‖x‖) (fun n => ?_) ?_ (fun n => ?_) ?_
    · exact ((Real.continuous_exp.comp continuous_neg).continuousOn.smul
        ((hcontn n).sub continuousOn_const)).aestronglyMeasurable measurableSet_Ioi
    · exact ((integrableOn_exp_mul_Ioi (a := -(1/2)) (by norm_num) 0).add
        (integrableOn_exp_mul_Ioi (a := -1) (by norm_num) 0)).mul_const ‖x‖
    · refine (ae_restrict_iff' measurableSet_Ioi).2 (Eventually.of_forall fun s hs => ?_)
      rw [norm_smul, Real.norm_of_nonneg (Real.exp_pos _).le]
      calc Real.exp (-s) * ‖T (s / lamn n) x - x‖
          ≤ Real.exp (-s) * (Real.exp (s / 2) * ‖x‖ + ‖x‖) := by
            gcongr; exact (norm_sub_le _ _).trans (by linarith [hTb n s (le_of_lt hs)])
        _ = (Real.exp (-(1/2) * s) + Real.exp (-1 * s)) * ‖x‖ := by
            rw [mul_add, ← mul_assoc, ← Real.exp_add]; ring_nf
    · refine (ae_restrict_iff' measurableSet_Ioi).2 (Eventually.of_forall fun s hs => ?_)
      have h1 : Tendsto (fun n => s / lamn n) atTop (𝓝[≥] 0) := by
        refine tendsto_nhdsWithin_iff.2 ⟨?_, Eventually.of_forall fun n =>
          (show (0:ℝ) ≤ s / lamn n from div_nonneg (le_of_lt hs) (hl n).le)⟩
        exact tendsto_const_nhds.div_atTop
          (tendsto_atTop_add_const_right _ a tendsto_natCast_atTop_atTop)
      have h2 := ((hT.2.2 x).comp h1).sub_const x
      have h3 := h2.const_smul (Real.exp (-s))
      simpa using h3
  rw [integral_zero] at hdct
  have hconv : Tendsto (fun n => lamn n • hyLap T (lamn n) x) atTop (𝓝 x) := by
    have := (hdct.congr (fun n => (key n).symm)).add_const x
    simpa using this
  exact mem_closure_of_tendsto hconv (Eventually.of_forall fun n =>
    A.domain.smul_mem _ (hy_lap_mem hT hgen hb (hlω n) x).1)

/-! ### Backward direction: the Yosida approximation -/

/-- The sample points `λ_n = n + 2|ω| + 1`, all above `max ω (2ω)`. -/
def hyL (ω : ℝ) (n : ℕ) : ℝ := n + (2 * |ω| + 1)

/-- The Yosida approximation `A_n = λ_n² R_n - λ_n`. -/
def hyY (ω : ℝ) (R : ℕ → E →L[ℝ] E) (n : ℕ) : E →L[ℝ] E :=
  (hyL ω n) ^ 2 • R n - hyL ω n • (1 : E →L[ℝ] E)

/-- The approximating flows `exp (t A_n)`. -/
def hyS (ω : ℝ) (R : ℕ → E →L[ℝ] E) (n : ℕ) (t : ℝ) : E →L[ℝ] E :=
  NormedSpace.exp (t • hyY ω R n)

theorem hyL_ge (ω : ℝ) (n : ℕ) : 2 * |ω| + 1 ≤ hyL ω n := by
  simp [hyL]

theorem hyL_pos (ω : ℝ) (n : ℕ) : 0 < hyL ω n := by
  have := hyL_ge ω n; have := abs_nonneg ω; linarith

theorem hyL_gt (ω : ℝ) (n : ℕ) : ω < hyL ω n := by
  have := hyL_ge ω n; have := le_abs_self ω; have := abs_nonneg ω; linarith

theorem hyL_tendsto (ω : ℝ) : Tendsto (fun n => hyL ω n - ω) atTop atTop := by
  have : (fun n => hyL ω n - ω) = fun n : ℕ => (n : ℝ) + (2 * |ω| + 1 - ω) := by
    ext n; simp [hyL]; ring
  rw [this]
  exact tendsto_atTop_add_const_right _ _ tendsto_natCast_atTop_atTop

theorem hy_lamR_norm {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω)) (n : ℕ) : ‖hyL ω n • R n‖ ≤ 2 := by
  have h1 := hyL_gt ω n
  have h2 := hyL_ge ω n
  have hp : 0 < hyL ω n - ω := by linarith
  rw [norm_smul, Real.norm_of_nonneg (hyL_pos ω n).le]
  calc hyL ω n * ‖R n‖ ≤ hyL ω n * (1 / (hyL ω n - ω)) :=
        mul_le_mul_of_nonneg_left (hRn n) (hyL_pos ω n).le
    _ ≤ 2 := by
        rw [mul_one_div, div_le_iff₀ hp]
        have := le_abs_self ω
        linarith

theorem hy_lamR_tendsto [CompleteSpace E] {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω))
    (hdense : Dense (A.domain : Set E)) (y : E) :
    Tendsto (fun n => hyL ω n • R n y) atTop (𝓝 y) := by
  refine hy_tendsto_of_dense (F := fun n => hyL ω n • R n) (hy_lamR_norm hRn) hdense
    (fun z hz => ?_) y
  rw [tendsto_iff_norm_sub_tendsto_zero]
  refine squeeze_zero (fun n => norm_nonneg _) (fun n => ?_)
    ((tendsto_const_nhds (x := ‖A ⟨z, hz⟩‖)).div_atTop (hyL_tendsto ω))
  have h := (hR n).2 ⟨z, hz⟩
  simp only [map_sub, map_smul] at h
  have e : (hyL ω n • R n) z - z = R n (A ⟨z, hz⟩) := by
    rw [ContinuousLinearMap.smul_apply]
    calc hyL ω n • R n z - z = hyL ω n • R n z - (hyL ω n • R n z - R n (A ⟨z, hz⟩)) := by
          rw [h]
      _ = R n (A ⟨z, hz⟩) := by abel
  rw [e]
  calc ‖R n (A ⟨z, hz⟩)‖ ≤ ‖R n‖ * ‖A ⟨z, hz⟩‖ := ContinuousLinearMap.le_opNorm _ _
    _ ≤ 1 / (hyL ω n - ω) * ‖A ⟨z, hz⟩‖ := by gcongr; exact hRn n
    _ = ‖A ⟨z, hz⟩‖ / (hyL ω n - ω) := by ring

theorem hy_Y_apply {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (n : ℕ) (z : A.domain) :
    hyY ω R n z = hyL ω n • R n (A z) := by
  have h := (hR n).2 z
  simp only [map_sub, map_smul] at h
  have h' : hyL ω n • R n z = z + R n (A z) := by
    calc hyL ω n • R n z = (hyL ω n • R n z - R n (A z)) + R n (A z) := by abel
      _ = z + R n (A z) := by rw [h]
  have e : hyY ω R n z = hyL ω n • (hyL ω n • R n z) - hyL ω n • (z : E) := by
    simp [hyY, smul_smul, pow_two]
  rw [e, h', smul_add]; abel

theorem hy_Y_tendsto [CompleteSpace E] {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω))
    (hdense : Dense (A.domain : Set E)) (z : A.domain) :
    Tendsto (fun n => hyY ω R n z) atTop (𝓝 (A z)) := by
  simp_rw [hy_Y_apply hR]
  exact hy_lamR_tendsto hR hRn hdense (A z)

theorem hy_Y_norm_le {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω))
    (n : ℕ) (z : A.domain) : ‖hyY ω R n z‖ ≤ 2 * ‖A z‖ := by
  rw [hy_Y_apply hR, ← ContinuousLinearMap.smul_apply]
  exact (ContinuousLinearMap.le_opNorm _ _).trans
    (mul_le_mul_of_nonneg_right (hy_lamR_norm hRn n) (norm_nonneg _))

theorem hy_S_norm [CompleteSpace E] {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω)) (n : ℕ) {t : ℝ} (ht : 0 ≤ t) :
    ‖hyS ω R n t‖ ≤ Real.exp (t * (hyL ω n * ω / (hyL ω n - ω))) := by
  have hp : 0 < hyL ω n - ω := by linarith [hyL_gt ω n]
  have hl := hyL_pos ω n
  unfold hyS hyY
  have e : t • ((hyL ω n) ^ 2 • R n - hyL ω n • (1 : E →L[ℝ] E)) =
      (t * (hyL ω n) ^ 2) • R n + (-(t * hyL ω n)) • (1 : E →L[ℝ] E) := by
    rw [smul_sub, smul_smul, smul_smul]; module
  letI : NormedAlgebra ℚ (E →L[ℝ] E) := NormedAlgebra.restrictScalars ℚ ℝ (E →L[ℝ] E)
  rw [e, NormedSpace.exp_add_of_commute (((Commute.one_right (R n)).smul_left _).smul_right _)]
  have e2 : NormedSpace.exp ((-(t * hyL ω n)) • (1 : E →L[ℝ] E)) =
      Real.exp (-(t * hyL ω n)) • (1 : E →L[ℝ] E) := by
    rw [← Algebra.algebraMap_eq_smul_one, ← NormedSpace.algebraMap_exp_comm, Real.exp_eq_exp_ℝ,
      Algebra.algebraMap_eq_smul_one]
  rw [e2, mul_smul_comm, mul_one, norm_smul, Real.norm_of_nonneg (Real.exp_pos _).le]
  calc Real.exp (-(t * hyL ω n)) * ‖NormedSpace.exp ((t * hyL ω n ^ 2) • R n)‖
      ≤ Real.exp (-(t * hyL ω n)) * Real.exp ‖(t * hyL ω n ^ 2) • R n‖ := by
        gcongr; exact hy_norm_exp_le _
    _ ≤ Real.exp (-(t * hyL ω n)) * Real.exp (t * hyL ω n ^ 2 * (1 / (hyL ω n - ω))) := by
        gcongr
        rw [norm_smul, Real.norm_of_nonneg (by positivity)]
        gcongr; exact hRn n
    _ = Real.exp (t * (hyL ω n * ω / (hyL ω n - ω))) := by
        rw [← Real.exp_add]; congr 1; field_simp; ring

theorem hy_kappa_le (ω : ℝ) (n : ℕ) : hyL ω n * ω / (hyL ω n - ω) ≤ 2 * |ω| := by
  have h1 := hyL_ge ω n
  have hp : 0 < hyL ω n - ω := by linarith [hyL_gt ω n]
  rw [div_le_iff₀ hp]
  rcases le_total 0 ω with h | h
  · rw [abs_of_nonneg h] at h1 ⊢; nlinarith
  · rw [abs_of_nonpos h] at h1 ⊢; nlinarith

theorem hy_S_norm' [CompleteSpace E] {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω)) (n : ℕ) {t : ℝ} (ht : 0 ≤ t) :
    ‖hyS ω R n t‖ ≤ Real.exp (2 * |ω| * t) := by
  refine (hy_S_norm hRn n ht).trans (Real.exp_le_exp.2 ?_)
  rw [mul_comm (2 * |ω|)]
  exact mul_le_mul_of_nonneg_left (hy_kappa_le ω n) ht

theorem hy_Y_comm {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (n m : ℕ) : Commute (hyY ω R n) (hyY ω R m) := by
  have h := hy_res_comm (hR n) (hR m)
  unfold hyY
  exact Commute.sub_left
    (Commute.sub_right ((h.smul_left _).smul_right _)
      (((Commute.one_right (R n)).smul_left _).smul_right _))
    ((Commute.one_left _).smul_left _)

theorem hy_S_zero {R : ℕ → E →L[ℝ] E} {ω : ℝ} (n : ℕ) : hyS ω R n 0 = 1 := by
  simp [hyS, NormedSpace.exp_zero]

theorem hy_S_add [CompleteSpace E] {R : ℕ → E →L[ℝ] E} {ω : ℝ} (n : ℕ) (s t : ℝ) :
    hyS ω R n (s + t) = hyS ω R n s * hyS ω R n t := by
  letI : NormedAlgebra ℚ (E →L[ℝ] E) := NormedAlgebra.restrictScalars ℚ ℝ (E →L[ℝ] E)
  unfold hyS
  rw [add_smul]
  exact NormedSpace.exp_add_of_commute (((Commute.refl _).smul_left _).smul_right _)

theorem hy_S_deriv [CompleteSpace E] {R : ℕ → E →L[ℝ] E} {ω : ℝ} (n : ℕ) (t : ℝ) :
    HasDerivAt (fun t => hyS ω R n t) (hyS ω R n t * hyY ω R n) t := by
  show HasDerivAt (fun t => NormedSpace.exp (t • hyY ω R n)) (NormedSpace.exp (t • hyY ω R n) * hyY ω R n) t
  exact hasDerivAt_exp_smul_const (𝕂 := ℝ) (𝔸 := E →L[ℝ] E) _ _

theorem hy_Y_S_comm [CompleteSpace E] {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (n m : ℕ) (s : ℝ) :
    Commute (hyY ω R n) (hyS ω R m s) := by
  show Commute (hyY ω R n) (NormedSpace.exp (s • hyY ω R m))
  exact Commute.exp_right (𝔸 := E →L[ℝ] E) ((hy_Y_comm hR n m).smul_right s)

theorem hy_S_mvt [CompleteSpace E] {R : ℕ → E →L[ℝ] E} {ω : ℝ} (n : ℕ) (y w : E) {t : ℝ}
    (ht : 0 ≤ t) {C : ℝ} (hC : ∀ s ∈ Set.Ico 0 t, ‖hyS ω R n s (hyY ω R n y) - w‖ ≤ C) :
    ‖hyS ω R n t y - y - t • w‖ ≤ C * t := by
  have hd : ∀ s ∈ Set.Icc 0 t, HasDerivWithinAt (fun s => hyS ω R n s y - s • w)
      (hyS ω R n s (hyY ω R n y) - w) (Set.Icc 0 t) s := by
    intro s _
    have h1 := (ContinuousLinearMap.apply ℝ E y).hasFDerivAt.comp_hasDerivAt s (hy_S_deriv (R := R) (ω := ω) n s)
    have h2 := (hasDerivAt_id s).smul_const w
    have := (h1.sub h2).hasDerivWithinAt (s := Set.Icc 0 t)
    convert this using 1
    · rfl
    · rw [one_smul]; rfl
  have := norm_image_sub_le_of_norm_deriv_le_segment' hd hC t ⟨ht, le_rfl⟩
  simp only [hy_S_zero, zero_smul, sub_zero] at this
  rw [ContinuousLinearMap.one_apply] at this
  convert this using 2
  abel

theorem hy_S_diff [CompleteSpace E] {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω))
    (n m : ℕ) (x : E) {t : ℝ} (ht : 0 ≤ t) :
    ‖hyS ω R n t x - hyS ω R m t x‖ ≤
      Real.exp (2 * |ω| * t) * ‖hyY ω R m x - hyY ω R n x‖ * t := by
  set φ : ℝ → E →L[ℝ] E := fun s => hyS ω R n (t - s) * hyS ω R m s with hφ
  have hd : ∀ s ∈ Set.Icc 0 t, HasDerivWithinAt (fun s => φ s x)
      ((hyS ω R n (t - s) * hyS ω R m s) ((hyY ω R m - hyY ω R n) x)) (Set.Icc 0 t) s := by
    intro s _
    have hc := (hy_S_deriv (R := R) (ω := ω) n (t - s)).scomp s ((hasDerivAt_id s).const_sub t)
    have hdd := hy_S_deriv (R := R) (ω := ω) m s
    have hm := hc.fun_mul hdd
    have hcomm := (hy_Y_S_comm hR n m s).eq
    have hm' : HasDerivAt φ (hyS ω R n (t - s) * hyS ω R m s * (hyY ω R m - hyY ω R n)) s := by
      convert hm using 1
      · rfl
      simp only [Function.comp_apply, neg_smul, one_smul, neg_mul, mul_sub]
      rw [mul_assoc (hyS ω R n (t - s)) (hyY ω R n), hcomm, ← mul_assoc, ← mul_assoc]
      abel
    have h1 := (ContinuousLinearMap.apply ℝ E x).hasFDerivAt.comp_hasDerivAt s hm'
    exact h1.hasDerivWithinAt
  have hC : ∀ s ∈ Set.Ico 0 t, ‖(hyS ω R n (t - s) * hyS ω R m s) ((hyY ω R m - hyY ω R n) x)‖ ≤
      Real.exp (2 * |ω| * t) * ‖hyY ω R m x - hyY ω R n x‖ := by
    intro s hs
    have hs0 : 0 ≤ s := hs.1
    have hts : 0 ≤ t - s := by linarith [hs.2]
    calc ‖(hyS ω R n (t - s) * hyS ω R m s) ((hyY ω R m - hyY ω R n) x)‖
        ≤ ‖hyS ω R n (t - s) * hyS ω R m s‖ * ‖(hyY ω R m - hyY ω R n) x‖ :=
          ContinuousLinearMap.le_opNorm _ _
      _ ≤ (‖hyS ω R n (t - s)‖ * ‖hyS ω R m s‖) * ‖(hyY ω R m - hyY ω R n) x‖ := by
          gcongr; exact norm_mul_le _ _
      _ ≤ (Real.exp (2 * |ω| * (t - s)) * Real.exp (2 * |ω| * s)) *
            ‖(hyY ω R m - hyY ω R n) x‖ := by
          gcongr
          · exact hy_S_norm' hRn n hts
          · exact hy_S_norm' hRn m hs0
      _ = Real.exp (2 * |ω| * t) * ‖hyY ω R m x - hyY ω R n x‖ := by
          rw [← Real.exp_add, ContinuousLinearMap.sub_apply]; congr 2; ring
  have := norm_image_sub_le_of_norm_deriv_le_segment' hd hC t ⟨ht, le_rfl⟩
  simp only [hφ, sub_self, sub_zero, hy_S_zero, one_mul, mul_one] at this
  rw [norm_sub_rev]
  exact this

theorem hy_unif [CompleteSpace E] {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω))
    (hdense : Dense (A.domain : Set E)) (y : E) {ε : ℝ} (hε : 0 < ε) :
    ∃ δ > 0, ∀ n s, 0 ≤ s → s ≤ δ → ‖hyS ω R n s y - y‖ ≤ ε := by
  set K := Real.exp (2 * |ω|) with hK
  have hK0 : 0 < K := Real.exp_pos _
  obtain ⟨z, hz, hyz⟩ := hdense.exists_dist_lt y (show 0 < ε / (2 * (K + 1)) by positivity)
  set zd : A.domain := ⟨z, hz⟩
  set M := 2 * K * ‖A zd‖ + 1 with hM
  have hM0 : 0 < M := by positivity
  refine ⟨min 1 (ε / (2 * M)), by positivity, fun n s hs hsδ => ?_⟩
  have hs1 : s ≤ 1 := hsδ.trans (min_le_left _ _)
  have hs2 : s ≤ ε / (2 * M) := hsδ.trans (min_le_right _ _)
  have hSK : ∀ r, 0 ≤ r → r ≤ 1 → ‖hyS ω R n r‖ ≤ K := fun r hr0 hr1 =>
    (hy_S_norm' hRn n hr0).trans (Real.exp_le_exp.2 (by nlinarith [abs_nonneg ω]))
  have hz1 : ‖hyS ω R n s z - z‖ ≤ (K * (2 * ‖A zd‖)) * s := by
    have := hy_S_mvt (R := R) (ω := ω) n z 0 hs (C := K * (2 * ‖A zd‖)) (fun r hr => by
      rw [sub_zero]
      calc ‖hyS ω R n r (hyY ω R n z)‖ ≤ ‖hyS ω R n r‖ * ‖hyY ω R n z‖ :=
            ContinuousLinearMap.le_opNorm _ _
        _ ≤ K * (2 * ‖A zd‖) := mul_le_mul (hSK r hr.1 (hr.2.le.trans hs1))
            (hy_Y_norm_le hR hRn n zd) (norm_nonneg _) hK0.le)
    simpa using this
  have h1 : (K + 1) * ‖y - z‖ ≤ ε / 2 := by
    have : ‖y - z‖ ≤ ε / (2 * (K + 1)) := by rw [← dist_eq_norm]; exact hyz.le
    calc (K + 1) * ‖y - z‖ ≤ (K + 1) * (ε / (2 * (K + 1))) := by gcongr
      _ = ε / 2 := by field_simp
  have h2 : K * (2 * ‖A zd‖) * s ≤ ε / 2 := by
    calc K * (2 * ‖A zd‖) * s ≤ M * s := by
          apply mul_le_mul_of_nonneg_right _ hs; rw [hM]; linarith
      _ ≤ M * (ε / (2 * M)) := by gcongr
      _ = ε / 2 := by field_simp
  have e : hyS ω R n s y - y = hyS ω R n s (y - z) + (hyS ω R n s z - z) + (z - y) := by
    rw [map_sub]; abel
  rw [e]
  calc ‖hyS ω R n s (y - z) + (hyS ω R n s z - z) + (z - y)‖
      ≤ ‖hyS ω R n s (y - z)‖ + ‖hyS ω R n s z - z‖ + ‖z - y‖ := norm_add₃_le
    _ ≤ K * ‖y - z‖ + K * (2 * ‖A zd‖) * s + ‖y - z‖ := by
        gcongr
        · exact (ContinuousLinearMap.le_opNorm _ _).trans
            (mul_le_mul_of_nonneg_right (hSK s hs hs1) (norm_nonneg _))
        · rw [norm_sub_rev]
    _ ≤ ε := by nlinarith

theorem hy_cauchy [CompleteSpace E] {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω))
    (hdense : Dense (A.domain : Set E)) {t : ℝ} (ht : 0 ≤ t) (x : E) :
    CauchySeq (fun n => hyS ω R n t x) := by
  refine hy_cauchy_of_dense (F := fun n => hyS ω R n t) (fun n => hy_S_norm' hRn n ht) hdense
    (fun z hz => ?_) x
  rw [Metric.cauchySeq_iff]
  intro ε hε
  set B := Real.exp (2 * |ω| * t) * t with hB
  have hB0 : 0 ≤ B := by positivity
  obtain ⟨N, hN⟩ := Metric.cauchySeq_iff.1 (hy_Y_tendsto hR hRn hdense ⟨z, hz⟩).cauchySeq
    (ε / (B + 1)) (by positivity)
  refine ⟨N, fun m hm n hn => ?_⟩
  have hd := hN n hn m hm
  rw [dist_eq_norm] at hd
  rw [dist_eq_norm]
  have := hy_S_diff hR hRn m n z ht
  calc ‖hyS ω R m t z - hyS ω R n t z‖
      ≤ Real.exp (2 * |ω| * t) * ‖hyY ω R n z - hyY ω R m z‖ * t := this
    _ = B * ‖hyY ω R n z - hyY ω R m z‖ := by rw [hB]; ring
    _ ≤ (B + 1) * ‖hyY ω R n z - hyY ω R m z‖ := by nlinarith [norm_nonneg (hyY ω R n z - hyY ω R m z)]
    _ < (B + 1) * (ε / (B + 1)) := by gcongr
    _ = ε := by field_simp

theorem hy_kappa_tendsto (ω : ℝ) :
    Tendsto (fun n => hyL ω n * ω / (hyL ω n - ω)) atTop (𝓝 ω) := by
  have e : ∀ n, hyL ω n * ω / (hyL ω n - ω) = ω + ω ^ 2 / (hyL ω n - ω) := by
    intro n
    have : hyL ω n - ω ≠ 0 := by linarith [hyL_gt ω n]
    field_simp; ring
  simp_rw [e]
  simpa using (tendsto_const_nhds (x := ω)).add
    ((tendsto_const_nhds (x := ω ^ 2)).div_atTop (hyL_tendsto ω))

theorem hy_lim_norm [CompleteSpace E] {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω)) {t : ℝ} (ht : 0 ≤ t) (x : E) {L : E}
    (hL : Tendsto (fun n => hyS ω R n t x) atTop (𝓝 L)) :
    ‖L‖ ≤ Real.exp (ω * t) * ‖x‖ := by
  have hb : Tendsto (fun n => Real.exp (t * (hyL ω n * ω / (hyL ω n - ω))) * ‖x‖) atTop
      (𝓝 (Real.exp (t * ω) * ‖x‖)) :=
    (((Real.continuous_exp.tendsto _).comp
      ((tendsto_const_nhds (x := t)).mul (hy_kappa_tendsto ω))).mul_const ‖x‖)
  rw [mul_comm ω t]
  exact le_of_tendsto_of_tendsto' hL.norm hb (fun n =>
    (ContinuousLinearMap.le_opNorm _ _).trans
      (mul_le_mul_of_nonneg_right (hy_S_norm hRn n ht) (norm_nonneg _)))

/-- The limit flow `T(t) x = lim_n exp (t A_n) x` (frozen at `T 0` for negative `t`). -/
def hyT [CompleteSpace E] {A : E →ₗ.[ℝ] E} (ω : ℝ) (R : ℕ → E →L[ℝ] E)
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω))
    (hdense : Dense (A.domain : Set E)) (t : ℝ) : E →L[ℝ] E :=
  (linearMapOfTendsto (fun x => limUnder atTop (fun n => hyS ω R n (max t 0) x))
    (fun n => (hyS ω R n (max t 0) : E →ₗ[ℝ] E))
    (tendsto_pi_nhds.2 fun x =>
      (hy_cauchy hR hRn hdense (le_max_right t 0) x).tendsto_limUnder)).mkContinuous
    (Real.exp (ω * max t 0))
    (fun x => hy_lim_norm hRn (le_max_right t 0) x
      (hy_cauchy hR hRn hdense (le_max_right t 0) x).tendsto_limUnder)

theorem hy_T_tendsto [CompleteSpace E] {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω))
    (hdense : Dense (A.domain : Set E)) {t : ℝ} (ht : 0 ≤ t) (x : E) :
    Tendsto (fun n => hyS ω R n t x) atTop (𝓝 (hyT ω R hR hRn hdense t x)) := by
  show Tendsto (fun n => hyS ω R n t x) atTop
    (𝓝 (limUnder atTop (fun n => hyS ω R n (max t 0) x)))
  rw [max_eq_left ht]
  exact (hy_cauchy hR hRn hdense ht x).tendsto_limUnder

theorem hy_T_norm [CompleteSpace E] {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω))
    (hdense : Dense (A.domain : Set E)) {t : ℝ} (ht : 0 ≤ t) :
    ‖hyT ω R hR hRn hdense t‖ ≤ Real.exp (ω * t) :=
  ContinuousLinearMap.opNorm_le_bound _ (Real.exp_pos _).le
    (fun x => hy_lim_norm hRn ht x (hy_T_tendsto hR hRn hdense ht x))

theorem hy_T_semigroup [CompleteSpace E] {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω))
    (hdense : Dense (A.domain : Set E)) :
    IsStronglyContinuousSemigroup (hyT ω R hR hRn hdense) := by
  refine ⟨?_, ?_, ?_⟩
  · ext x
    refine tendsto_nhds_unique (hy_T_tendsto hR hRn hdense le_rfl x) ?_
    simp only [hy_S_zero]
    exact tendsto_const_nhds
  · intro s t hs ht
    ext x
    refine tendsto_nhds_unique (hy_T_tendsto hR hRn hdense (add_nonneg hs ht) x) ?_
    have h2 := hy_tendsto_apply (F := fun n => hyS ω R n s) (fun n => hy_S_norm' hRn n hs)
      (hy_T_tendsto hR hRn hdense hs (hyT ω R hR hRn hdense t x))
      (hy_T_tendsto hR hRn hdense ht x)
    simp only [hy_S_add]
    exact h2
  · intro f
    rw [Metric.tendsto_nhdsWithin_nhds]
    intro ε hε
    obtain ⟨δ, hδ, hU⟩ := hy_unif hR hRn hdense f (half_pos hε)
    refine ⟨δ, hδ, fun {s} hs hsd => ?_⟩
    have hs0 : (0:ℝ) ≤ s := hs
    have hsδ : s ≤ δ := by
      rw [Real.dist_eq, sub_zero, abs_of_nonneg hs0] at hsd; exact hsd.le
    rw [dist_eq_norm]
    have := le_of_tendsto' ((hy_T_tendsto hR hRn hdense hs0 f).sub_const f).norm
      (fun n => hU n s hs0 hsδ)
    linarith

theorem hy_T_gen_mem [CompleteSpace E] {A : E →ₗ.[ℝ] E} {R : ℕ → E →L[ℝ] E} {ω : ℝ}
    (hR : ∀ n, IsResolvent A (hyL ω n) (R n)) (hRn : ∀ n, ‖R n‖ ≤ 1 / (hyL ω n - ω))
    (hdense : Dense (A.domain : Set E)) (u : A.domain) :
    Tendsto (fun t : ℝ => t⁻¹ • (hyT ω R hR hRn hdense t u - u)) (𝓝[>] 0) (𝓝 (A u)) := by
  rw [Metric.tendsto_nhdsWithin_nhds]
  intro ε hε
  set y := A u with hy
  obtain ⟨δ, hδ, hU⟩ := hy_unif hR hRn hdense y (show 0 < ε / 4 by positivity)
  refine ⟨δ, hδ, fun {t} ht htd => ?_⟩
  have ht0 : (0:ℝ) < t := ht
  have htδ : t ≤ δ := by
    rw [Real.dist_eq, sub_zero, abs_of_pos ht0] at htd; exact htd.le
  set c := 2 * |ω| with hc
  have key : ‖hyT ω R hR hRn hdense t u - u - t • y‖ ≤ ε / 4 * t := by
    have hlim : Tendsto (fun n => ‖hyS ω R n t u - u - t • y‖) atTop
        (𝓝 ‖hyT ω R hR hRn hdense t u - u - t • y‖) :=
      (((hy_T_tendsto hR hRn hdense ht0.le u).sub_const (u : E)).sub_const (t • y)).norm
    have hY := hy_Y_tendsto hR hRn hdense u
    have hbound : Tendsto (fun n => ((Real.exp (c * t) + 1) * ‖hyY ω R n u - y‖ + ε / 4) * t)
        atTop (𝓝 (((Real.exp (c * t) + 1) * 0 + ε / 4) * t)) :=
      (((tendsto_const_nhds).mul (tendsto_iff_norm_sub_tendsto_zero.1 hY)).add_const _).mul_const t
    rw [mul_zero, zero_add] at hbound
    refine le_of_tendsto_of_tendsto' hlim hbound (fun n => hy_S_mvt n (u : E) y ht0.le
      (fun r hr => ?_))
    have hr0 : 0 ≤ r := hr.1
    have hrt : r ≤ t := hr.2.le
    have hSr : ‖hyS ω R n r‖ ≤ Real.exp (c * t) :=
      (hy_S_norm' hRn n hr0).trans (Real.exp_le_exp.2 (mul_le_mul_of_nonneg_left hrt (by positivity)))
    calc ‖hyS ω R n r (hyY ω R n u) - y‖
        = ‖hyS ω R n r (hyY ω R n u - y) + (hyS ω R n r y - y)‖ := by rw [map_sub]; abel_nf
      _ ≤ ‖hyS ω R n r (hyY ω R n u - y)‖ + ‖hyS ω R n r y - y‖ := norm_add_le _ _
      _ ≤ Real.exp (c * t) * ‖hyY ω R n u - y‖ + ε / 4 :=
          add_le_add ((ContinuousLinearMap.le_opNorm _ _).trans
            (mul_le_mul_of_nonneg_right hSr (norm_nonneg _))) (hU n r hr0 (hrt.trans htδ))
      _ ≤ (Real.exp (c * t) + 1) * ‖hyY ω R n u - y‖ + ε / 4 := by
          nlinarith [norm_nonneg (hyY ω R n u - y)]
  rw [dist_eq_norm]
  have e : t⁻¹ • (hyT ω R hR hRn hdense t u - u) - y =
      t⁻¹ • (hyT ω R hR hRn hdense t u - u - t • y) := by
    simp only [smul_sub, smul_smul, inv_mul_cancel₀ ht0.ne', one_smul]
  rw [e, norm_smul, Real.norm_of_nonneg (inv_nonneg.2 ht0.le)]
  calc t⁻¹ * ‖hyT ω R hR hRn hdense t u - u - t • y‖ ≤ t⁻¹ * (ε / 4 * t) := by gcongr
    _ = ε / 4 := by field_simp
    _ < ε := by linarith

theorem hy_backward [CompleteSpace E] (A : E →ₗ.[ℝ] E) (ω : ℝ)
    (hdense : Dense (A.domain : Set E))
    (hres : ∀ lam : ℝ, ω < lam → ∃ R : E →L[ℝ] E, IsResolvent A lam R ∧ ‖R‖ ≤ 1 / (lam - ω)) :
    ∃ T : ℝ → E →L[ℝ] E, IsStronglyContinuousSemigroup T ∧ IsGenerator T A ∧
      ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t) := by
  choose R hR hRn using fun n : ℕ => hres (hyL ω n) (hyL_gt ω n)
  have hsg := hy_T_semigroup hR hRn hdense
  have hbd : ∀ t : ℝ, 0 ≤ t → ‖hyT ω R hR hRn hdense t‖ ≤ Real.exp (ω * t) :=
    fun t ht => hy_T_norm hR hRn hdense ht
  refine ⟨hyT ω R hR hRn hdense, hsg, fun u v => ⟨fun h => ?_, ?_⟩, hbd⟩
  · obtain ⟨hw, hw'⟩ := (hR 0).1 (hyL ω 0 • u - v)
    generalize R 0 (hyL ω 0 • u - v) = w at hw hw'
    have hw'' : hyL ω 0 • w - A ⟨w, hw⟩ = hyL ω 0 • u - v := hw'
    have h1 := hy_T_gen_mem hR hRn hdense ⟨w, hw⟩
    have h3 := h1.sub h
    have e : A ⟨w, hw⟩ - v = hyL ω 0 • (w - u) := by
      rw [smul_sub]
      rw [sub_eq_iff_eq_add] at hw''
      have : A ⟨w, hw⟩ = hyL ω 0 • w - (hyL ω 0 • u - v) := by rw [hw'']; abel
      rw [this]; abel
    rw [e] at h3
    have h4 : Tendsto (fun h : ℝ => h⁻¹ • (hyT ω R hR hRn hdense h (w - u) - (w - u))) (𝓝[>] 0)
        (𝓝 (hyL ω 0 • (w - u))) := by
      refine h3.congr' (Eventually.of_forall fun h => ?_)
      simp only [map_sub, smul_sub]
      abel
    have := hy_sg_inj hsg hbd (hyL_gt ω 0) h4
    have huw : w = u := sub_eq_zero.1 this
    subst huw
    exact ⟨hw, sub_right_injective hw''⟩
  · rintro ⟨hu, rfl⟩
    exact hy_T_gen_mem hR hRn hdense ⟨u, hu⟩

end HYHelpers

/-- Hille-Yosida. On a Banach space, an operator `A` with domain `D(A)` generates a strongly
continuous flow `T(t)` with `‖T(t)‖ ≤ e^(ωt)` for all `t ≥ 0` exactly when `A` is closed, `D(A)` is
dense, and for every real `λ > ω` the balance problem `(λI - A) u = f` has a bounded answer map
`R(λ, A)` of size at most `1 / (λ - ω)`. -/
theorem hille_yosida_generator_iff_resolvent_bound [CompleteSpace E]
    (A : E →ₗ.[ℝ] E) (ω : ℝ) :
    (∃ T : ℝ → E →L[ℝ] E, IsStronglyContinuousSemigroup T ∧ IsGenerator T A ∧
        ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ Real.exp (ω * t)) ↔
      A.IsClosed ∧ Dense (A.domain : Set E) ∧
        ∀ lam : ℝ, ω < lam →
          ∃ R : E →L[ℝ] E, IsResolvent A lam R ∧ ‖R‖ ≤ 1 / (lam - ω) := by
  constructor
  · rintro ⟨T, hT, hgen, hb⟩
    obtain ⟨R1, hR1, -⟩ := hy_forward_res hT hgen hb (show ω < ω + 1 by linarith)
    exact ⟨hy_closed_of_res hR1, hy_forward_dense hT hgen hb,
      fun lam hlam => hy_forward_res hT hgen hb hlam⟩
  · rintro ⟨-, hdense, hres⟩
    exact hy_backward A ω hdense hres

/-- The Lumer-Phillips shortcut used on the heat operator. On a real inner product space, if `A`
is dissipative (`⟨A u, u⟩ ≤ 0` for every `u` in `D(A)`) and the balance problem
`(λI - A) u = f` can be solved for every `f` at some `λ > 0`, then the resolvent `R(λ, A)` exists
and has size at most `1 / λ`. -/
theorem dissipative_and_onto_gives_resolvent_bound
    {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H]
    (A : H →ₗ.[ℝ] H) (hdiss : ∀ u : A.domain, inner ℝ (A u) (u : H) ≤ 0)
    (lam : ℝ) (hlam : 0 < lam) (honto : ∀ f : H, ∃ u : A.domain, lam • (u : H) - A u = f) :
    ∃ R : H →L[ℝ] H, IsResolvent A lam R ∧ ‖R‖ ≤ 1 / lam := by
  -- the key estimate
  have key : ∀ u : A.domain, lam * ‖(u : H)‖ ≤ ‖lam • (u : H) - A u‖ := by
    intro u
    have h1 : lam * ‖(u : H)‖ ^ 2 ≤ inner ℝ (lam • (u : H) - A u) (u : H) := by
      rw [inner_sub_left, real_inner_smul_left, real_inner_self_eq_norm_sq]
      linarith [hdiss u]
    have h2 : inner ℝ (lam • (u : H) - A u) (u : H) ≤ ‖lam • (u : H) - A u‖ * ‖(u : H)‖ :=
      real_inner_le_norm _ _
    rcases eq_or_lt_of_le (norm_nonneg (u : H)) with h0 | hpos
    · rw [← h0]; simp
    · nlinarith
  let B : A.domain →ₗ[ℝ] H := lam • (A.domain.subtype) - A.toFun
  have Binj : ∀ u v : A.domain, B u = B v → u = v := by
    intro u v huv
    have : B (u - v) = 0 := by rw [map_sub, huv, sub_self]
    have hk := key (u - v)
    have e : B (u - v) = lam • ((u - v : A.domain) : H) - A (u - v) := rfl
    rw [← e, this, norm_zero] at hk
    have : ‖((u - v : A.domain) : H)‖ = 0 :=
      le_antisymm (by nlinarith [norm_nonneg ((u - v : A.domain) : H)]) (norm_nonneg _)
    rw [norm_eq_zero] at this
    exact sub_eq_zero.mp (Subtype.ext (by simpa using this))
  have hB : ∀ f, ∃ u, B u = f := honto
  choose g hg using hB
  let L : H →ₗ[ℝ] H :=
    { toFun := fun f => (g f : H)
      map_add' := by
        intro f1 f2
        have : g (f1 + f2) = g f1 + g f2 := Binj _ _ (by rw [map_add, hg, hg, hg])
        rw [this]; rfl
      map_smul' := by
        intro c f
        have : g (c • f) = c • g f := Binj _ _ (by rw [map_smul, hg, hg])
        rw [this]; rfl }
  have Lbd : ∀ f, ‖L f‖ ≤ 1 / lam * ‖f‖ := by
    intro f
    have := key (g f)
    have e : lam • ((g f : A.domain) : H) - A (g f) = f := hg f
    rw [e] at this
    show ‖(g f : H)‖ ≤ _
    rw [div_mul_eq_mul_div, one_mul, le_div_iff₀ hlam]; linarith
  refine ⟨L.mkContinuous (1 / lam) Lbd, ⟨fun f => ⟨(g f).2, hg f⟩, fun u => ?_⟩,
    LinearMap.mkContinuous_norm_le _ (by positivity) _⟩
  show ((g (lam • (u : H) - A u)) : H) = u
  have : g (lam • (u : H) - A u) = u := Binj _ _ (by rw [hg]; rfl)
  rw [this]

/-- Why the backward heat operator fails the test. If `A` has eigenvalues beyond every bound
(for every `ω` some `λ > ω` and some nonzero `u` in `D(A)` with `A u = λ u`), then no half-line
`(ω, ∞)` lies in the resolvent set: for every `ω` some `λ > ω` has no resolvent at all. -/
theorem unbounded_eigenvalues_fail_resolvent_test (A : E →ₗ.[ℝ] E)
    (heig : ∀ ω : ℝ, ∃ lam : ℝ, ω < lam ∧ ∃ u : A.domain, (u : E) ≠ 0 ∧ A u = lam • (u : E)) :
    ∀ ω : ℝ, ∃ lam : ℝ, ω < lam ∧ ∀ R : E →L[ℝ] E, ¬ IsResolvent A lam R := by
  intro ω
  obtain ⟨lam, hlt, u, hu, hAu⟩ := heig ω
  refine ⟨lam, hlt, fun R hR => hu ?_⟩
  have := hR.2 u
  rw [hAu, sub_self, map_zero] at this
  exact this.symm

end

#print axioms hy_sg_bound_le
#print axioms hy_sg_continuousOn
#print axioms hy_sg_hasDerivWithinAt
#print axioms hy_sg_inj
#print axioms hy_res_ident
#print axioms hy_res_comm
#print axioms hy_closed_of_res
#print axioms hy_tendsto_of_dense
#print axioms hy_cauchy_of_dense
#print axioms hy_tendsto_apply
#print axioms hy_norm_exp_le
#print axioms hy_lap_cont
#print axioms hy_lap_bound
#print axioms hy_lap_integrable
#print axioms hy_lap_norm
#print axioms hy_shift_Ioi
#print axioms hy_lap_gen
#print axioms hy_lap_mem
#print axioms hy_forward_res
#print axioms hy_forward_dense
#print axioms hyL_ge
#print axioms hyL_pos
#print axioms hyL_gt
#print axioms hyL_tendsto
#print axioms hy_lamR_norm
#print axioms hy_lamR_tendsto
#print axioms hy_Y_apply
#print axioms hy_Y_tendsto
#print axioms hy_Y_norm_le
#print axioms hy_S_norm
#print axioms hy_kappa_le
#print axioms hy_S_norm'
#print axioms hy_Y_comm
#print axioms hy_S_zero
#print axioms hy_S_add
#print axioms hy_S_deriv
#print axioms hy_Y_S_comm
#print axioms hy_S_mvt
#print axioms hy_S_diff
#print axioms hy_unif
#print axioms hy_cauchy
#print axioms hy_kappa_tendsto
#print axioms hy_lim_norm
#print axioms hy_T_tendsto
#print axioms hy_T_norm
#print axioms hy_T_semigroup
#print axioms hy_T_gen_mem
#print axioms hy_backward
#print axioms hille_yosida_generator_iff_resolvent_bound
#print axioms dissipative_and_onto_gives_resolvent_bound
#print axioms unbounded_eigenvalues_fail_resolvent_test
