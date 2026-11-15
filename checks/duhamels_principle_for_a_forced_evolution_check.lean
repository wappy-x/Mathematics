-- Duhamel: for a strongly continuous semigroup T(t) with generator A on a Banach space, every classical solution of u' = Au + f equals T(t)u0 + ∫_0^t T(t - s) f(s) ds, the mild solution satisfies the equation in integrated form, and one heating block contributes (q/k)(e^(-k(t-b)) - e^(-k(t-a))).
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Normed.Operator.Mul
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Tactic.NormNum

open Filter Topology Set MeasureTheory

theorem duhamel_aux_tendsto_sub {α X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    {l : Filter α} {L : α → X →L[ℝ] X} {w : α → X} {w0 : X} {C : ℝ}
    (hb : ∀ᶠ a in l, ‖L a‖ ≤ C) (hw : Tendsto w l (𝓝 w0)) :
    Tendsto (fun a => L a (w a) - L a w0) l (𝓝 0) := by
  have h0 : Tendsto (fun a => C * ‖w a - w0‖) l (𝓝 0) := by
    have : Tendsto (fun a => ‖w a - w0‖) l (𝓝 0) := by
      have := (hw.sub_const w0).norm
      simpa using this
    simpa using this.const_mul C
  refine squeeze_zero_norm' ?_ h0
  filter_upwards [hb] with a ha
  rw [← map_sub]
  calc ‖L a (w a - w0)‖ ≤ ‖L a‖ * ‖w a - w0‖ := (L a).le_opNorm _
    _ ≤ C * ‖w a - w0‖ := by gcongr

#print axioms duhamel_aux_tendsto_sub

theorem duhamel_aux_tendsto_apply {α X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    {l : Filter α} {L : α → X →L[ℝ] X} {L0 : X →L[ℝ] X} {w : α → X} {w0 : X} {C : ℝ}
    (hL : Tendsto (fun a => L a w0) l (𝓝 (L0 w0)))
    (hb : ∀ᶠ a in l, ‖L a‖ ≤ C) (hw : Tendsto w l (𝓝 w0)) :
    Tendsto (fun a => L a (w a)) l (𝓝 (L0 w0)) := by
  have := (duhamel_aux_tendsto_sub hb hw).add hL
  simpa using this

#print axioms duhamel_aux_tendsto_apply

theorem duhamel_aux_bound {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (T : ℝ → X →L[ℝ] X)
    (hTbound : ∃ M ω : ℝ, ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ M * Real.exp (ω * t)) (t : ℝ) :
    ∃ C : ℝ, ∀ τ : ℝ, 0 ≤ τ → τ ≤ t → ‖T τ‖ ≤ C := by
  obtain ⟨M, ω, h⟩ := hTbound
  refine ⟨|M| * Real.exp (|ω| * |t|), fun τ h0 h1 => (h τ h0).trans ?_⟩
  have h2 : ω * τ ≤ |ω| * |t| := by
    calc ω * τ ≤ |ω * τ| := le_abs_self _
      _ = |ω| * |τ| := abs_mul _ _
      _ ≤ |ω| * |t| := by
        gcongr
  calc M * Real.exp (ω * τ) ≤ |M| * Real.exp (ω * τ) := by
        gcongr; exact le_abs_self M
    _ ≤ |M| * Real.exp (|ω| * |t|) := by gcongr

#print axioms duhamel_aux_bound

theorem duhamel_aux_strongCont {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (T : ℝ → X →L[ℝ] X)
    (hTadd : ∀ s t : ℝ, 0 ≤ s → 0 ≤ t → T (s + t) = T s * T t)
    (hTcont : ∀ x : X, Tendsto (fun t : ℝ => T t x) (𝓝[≥] 0) (𝓝 x))
    (hTbound : ∃ M ω : ℝ, ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ M * Real.exp (ω * t)) (x : X) :
    ContinuousOn (fun τ => T τ x) (Ici 0) := by
  intro τ hτ
  rw [mem_Ici] at hτ
  rw [← Icc_union_Ici_eq_Ici hτ, continuousWithinAt_union]
  constructor
  · -- from the left
    obtain ⟨C, hC⟩ := duhamel_aux_bound T hTbound τ
    have hw : Tendsto (fun σ => T (τ - σ) x) (𝓝[Icc 0 τ] τ) (𝓝 x) := by
      refine (hTcont x).comp ?_
      refine tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
      · have : Tendsto (fun σ : ℝ => τ - σ) (𝓝 τ) (𝓝 (τ - τ)) :=
          tendsto_const_nhds.sub tendsto_id
        simpa using tendsto_nhdsWithin_of_tendsto_nhds this
      · exact eventually_nhdsWithin_of_forall fun σ hσ => mem_Ici.2 (sub_nonneg.2 hσ.2)
    have hb : ∀ᶠ σ in 𝓝[Icc 0 τ] τ, ‖T σ‖ ≤ C :=
      eventually_nhdsWithin_of_forall fun σ hσ => hC σ hσ.1 hσ.2
    have h1 := duhamel_aux_tendsto_sub hb hw
    have h2 : Tendsto (fun σ => T τ x - (T σ (T (τ - σ) x) - T σ x)) (𝓝[Icc 0 τ] τ)
        (𝓝 (T τ x)) := by
      simpa using (tendsto_const_nhds (x := T τ x)).sub h1
    refine h2.congr' ?_
    refine eventually_nhdsWithin_of_forall fun σ hσ => ?_
    have : T τ = T σ * T (τ - σ) := by
      rw [← hTadd σ (τ - σ) hσ.1 (sub_nonneg.2 hσ.2)]; congr 1; ring
    simp [this]
  · -- from the right
    have hw : Tendsto (fun σ => T (σ - τ) x) (𝓝[Ici τ] τ) (𝓝 x) := by
      refine (hTcont x).comp ?_
      refine tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
      · have : Tendsto (fun σ : ℝ => σ - τ) (𝓝 τ) (𝓝 (τ - τ)) :=
          tendsto_id.sub tendsto_const_nhds
        simpa using tendsto_nhdsWithin_of_tendsto_nhds this
      · exact eventually_nhdsWithin_of_forall fun σ (hσ : τ ≤ σ) => mem_Ici.2 (sub_nonneg.2 hσ)
    have h2 : Tendsto (fun σ => T τ (T (σ - τ) x)) (𝓝[Ici τ] τ) (𝓝 (T τ x)) :=
      ((T τ).continuous.tendsto x).comp hw
    refine h2.congr' ?_
    refine eventually_nhdsWithin_of_forall fun σ (hσ : τ ≤ σ) => ?_
    have : T σ = T τ * T (σ - τ) := by
      rw [← hTadd τ (σ - τ) hτ (sub_nonneg.2 hσ)]; congr 1; ring
    simp [this]

#print axioms duhamel_aux_strongCont

theorem duhamel_aux_jointCont {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (T : ℝ → X →L[ℝ] X)
    (hTadd : ∀ s t : ℝ, 0 ≤ s → 0 ≤ t → T (s + t) = T s * T t)
    (hTcont : ∀ x : X, Tendsto (fun t : ℝ => T t x) (𝓝[≥] 0) (𝓝 x))
    (hTbound : ∃ M ω : ℝ, ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ M * Real.exp (ω * t)) :
    Continuous (fun p : ℝ × X => T (max p.1 0) p.2) := by
  rw [continuous_iff_continuousAt]
  rintro ⟨σ0, x0⟩
  obtain ⟨C, hC⟩ := duhamel_aux_bound T hTbound (max σ0 0 + 1)
  have hSC := duhamel_aux_strongCont T hTadd hTcont hTbound x0 (max σ0 0) (mem_Ici.2 (le_max_right _ _))
  have hL : Tendsto (fun p : ℝ × X => T (max p.1 0) x0) (𝓝 (σ0, x0)) (𝓝 (T (max σ0 0) x0)) := by
    refine hSC.tendsto.comp ?_
    refine tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
    · exact ((continuous_fst.max continuous_const).tendsto (σ0, x0))
    · exact Eventually.of_forall fun p => mem_Ici.2 (le_max_right _ _)
  have hb : ∀ᶠ p : ℝ × X in 𝓝 (σ0, x0), ‖T (max p.1 0)‖ ≤ C := by
    have : ∀ᶠ p : ℝ × X in 𝓝 (σ0, x0), p.1 < σ0 + 1 :=
      (continuous_fst.tendsto (σ0, x0)).eventually (gt_mem_nhds (lt_add_one σ0))
    filter_upwards [this] with p hp
    refine hC _ (le_max_right _ _) ?_
    exact max_le (by linarith [le_max_left σ0 0]) (by linarith [le_max_right σ0 0])
  exact duhamel_aux_tendsto_apply hL hb continuous_snd.continuousAt

#print axioms duhamel_aux_jointCont

theorem duhamel_aux_aesm {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (T : ℝ → X →L[ℝ] X)
    (hTadd : ∀ s t : ℝ, 0 ≤ s → 0 ≤ t → T (s + t) = T s * T t)
    (hTcont : ∀ x : X, Tendsto (fun t : ℝ => T t x) (𝓝[≥] 0) (𝓝 x))
    (hTbound : ∃ M ω : ℝ, ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ M * Real.exp (ω * t))
    {α : Type*} [MeasurableSpace α] {μ : Measure α} {σ : α → ℝ} {g : α → X}
    (hσ : AEStronglyMeasurable σ μ) (hg : AEStronglyMeasurable g μ) :
    AEStronglyMeasurable (fun a => T (max (σ a) 0) (g a)) μ :=
  (duhamel_aux_jointCont T hTadd hTcont hTbound).comp_aestronglyMeasurable₂
    (g := fun s x => T (max s 0) x) hσ hg

#print axioms duhamel_aux_aesm

theorem duhamel_aux_intervalIntegrable {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (T : ℝ → X →L[ℝ] X)
    (hTadd : ∀ s t : ℝ, 0 ≤ s → 0 ≤ t → T (s + t) = T s * T t)
    (hTcont : ∀ x : X, Tendsto (fun t : ℝ => T t x) (𝓝[≥] 0) (𝓝 x))
    (hTbound : ∃ M ω : ℝ, ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ M * Real.exp (ω * t))
    (f : ℝ → X) (t : ℝ) (ht : 0 ≤ t) (hf : IntervalIntegrable f volume 0 t) :
    IntervalIntegrable (fun r => T (t - r) (f r)) volume 0 t := by
  obtain ⟨C, hC⟩ := duhamel_aux_bound T hTbound t
  rw [intervalIntegrable_iff_integrableOn_Ioc_of_le ht] at hf ⊢
  have hm : AEStronglyMeasurable (fun r => T (max (t - r) 0) (f r)) (volume.restrict (Ioc 0 t)) :=
    duhamel_aux_aesm T hTadd hTcont hTbound
      ((continuous_const.sub continuous_id).aestronglyMeasurable) hf.aestronglyMeasurable
  have hm' : AEStronglyMeasurable (fun r => T (t - r) (f r)) (volume.restrict (Ioc 0 t)) := by
    refine hm.congr ?_
    filter_upwards [ae_restrict_mem measurableSet_Ioc] with r hr
    rw [max_eq_left (sub_nonneg.2 hr.2)]
  refine Integrable.mono' (hf.norm.const_mul C) hm' ?_
  filter_upwards [ae_restrict_mem measurableSet_Ioc] with r hr
  calc ‖T (t - r) (f r)‖ ≤ ‖T (t - r)‖ * ‖f r‖ := (T (t - r)).le_opNorm _
    _ ≤ C * ‖f r‖ := by
        gcongr
        exact hC _ (sub_nonneg.2 hr.2) (by linarith [hr.1])

#print axioms duhamel_aux_intervalIntegrable

theorem duhamel_aux_shift {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    (T : ℝ → X →L[ℝ] X)
    (hTadd : ∀ s t : ℝ, 0 ≤ s → 0 ≤ t → T (s + t) = T s * T t)
    (hTcont : ∀ x : X, Tendsto (fun t : ℝ => T t x) (𝓝[≥] 0) (𝓝 x))
    (hTbound : ∃ M ω : ℝ, ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ M * Real.exp (ω * t))
    (τ h : ℝ) (hτ : 0 ≤ τ) (hh : 0 ≤ h) (x : X) :
    T h (∫ σ in (0 : ℝ)..τ, T σ x) - ∫ σ in (0 : ℝ)..τ, T σ x =
      (∫ σ in τ..τ + h, T σ x) - ∫ σ in (0 : ℝ)..h, T σ x := by
  have hSC := duhamel_aux_strongCont T hTadd hTcont hTbound x
  have hi : ∀ a b : ℝ, 0 ≤ a → 0 ≤ b → IntervalIntegrable (fun σ => T σ x) volume a b := by
    intro a b ha hb
    refine (hSC.mono ?_).intervalIntegrable
    intro y hy
    rw [uIcc, mem_Icc] at hy
    exact mem_Ici.2 ((le_min ha hb).trans hy.1)
  have e0 : T h (∫ σ in (0 : ℝ)..τ, T σ x) = ∫ σ in h..τ + h, T σ x := by
    rw [← (T h).intervalIntegral_comp_comm (hi 0 τ le_rfl hτ)]
    have : ∫ σ in (0 : ℝ)..τ, T h (T σ x) = ∫ σ in (0 : ℝ)..τ, T (h + σ) x := by
      refine intervalIntegral.integral_congr fun σ hσ => ?_
      rw [uIcc_of_le hτ, mem_Icc] at hσ
      rw [hTadd h σ hh hσ.1, mul_apply_eq_comp]
    rw [this, intervalIntegral.integral_comp_add_left (fun σ => T σ x) h]
    simp [add_comm]
  have e1 := intervalIntegral.integral_add_adjacent_intervals (hi 0 h le_rfl hh)
    (hi h (τ + h) hh (by linarith))
  have e2 := intervalIntegral.integral_add_adjacent_intervals (hi 0 τ le_rfl hτ)
    (hi τ (τ + h) hτ (by linarith))
  rw [e0]
  rw [← e2] at e1
  have : ∫ σ in h..τ + h, T σ x =
      (∫ σ in (0 : ℝ)..τ, T σ x) + (∫ σ in τ..τ + h, T σ x) - ∫ σ in (0 : ℝ)..h, T σ x := by
    rw [← e1]; abel
  rw [this]; abel

#print axioms duhamel_aux_shift

theorem duhamel_aux_avg {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    (T : ℝ → X →L[ℝ] X)
    (hTadd : ∀ s t : ℝ, 0 ≤ s → 0 ≤ t → T (s + t) = T s * T t)
    (hTcont : ∀ x : X, Tendsto (fun t : ℝ => T t x) (𝓝[≥] 0) (𝓝 x))
    (hTbound : ∃ M ω : ℝ, ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ M * Real.exp (ω * t))
    (τ : ℝ) (hτ : 0 ≤ τ) (x : X) :
    Tendsto (fun h : ℝ => h⁻¹ • ∫ σ in τ..τ + h, T σ x) (𝓝[>] 0) (𝓝 (T τ x)) := by
  have hSC := duhamel_aux_strongCont T hTadd hTcont hTbound x
  have hsub : Ioi τ ⊆ Ici 0 := fun y (hy : τ < y) => mem_Ici.2 (hτ.trans hy.le)
  have hd : HasDerivWithinAt (fun b => ∫ σ in τ..b, T σ x) (T τ x) (Ici τ) τ :=
    intervalIntegral.integral_hasDerivWithinAt_right (IntervalIntegrable.refl)
      ((hSC.mono hsub).stronglyMeasurableAtFilter_nhdsWithin measurableSet_Ioi τ)
      ((hSC τ (mem_Ici.2 hτ)).mono hsub)
  have hd' := hd.mono (Ioi_subset_Ici_self)
  rw [hasDerivWithinAt_iff_tendsto_slope' (lt_irrefl τ)] at hd'
  have hmap : Tendsto (fun h : ℝ => τ + h) (𝓝[>] 0) (𝓝[Ioi τ] τ) := by
    refine tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
    · have : Tendsto (fun h : ℝ => τ + h) (𝓝 0) (𝓝 (τ + 0)) :=
        tendsto_const_nhds.add tendsto_id
      simpa using tendsto_nhdsWithin_of_tendsto_nhds this
    · exact eventually_nhdsWithin_of_forall fun h (hh : 0 < h) => mem_Ioi.2 (by linarith)
  refine (hd'.comp hmap).congr' (Eventually.of_forall fun h => ?_)
  simp [slope_def_module]

#print axioms duhamel_aux_avg

theorem duhamel_aux_gen {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    (T : ℝ → X →L[ℝ] X) (hT0 : T 0 = 1)
    (hTadd : ∀ s t : ℝ, 0 ≤ s → 0 ≤ t → T (s + t) = T s * T t)
    (hTcont : ∀ x : X, Tendsto (fun t : ℝ => T t x) (𝓝[≥] 0) (𝓝 x))
    (hTbound : ∃ M ω : ℝ, ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ M * Real.exp (ω * t))
    (τ : ℝ) (hτ : 0 ≤ τ) (x : X) :
    Tendsto (fun h : ℝ => h⁻¹ • (T h (∫ σ in (0 : ℝ)..τ, T σ x) - ∫ σ in (0 : ℝ)..τ, T σ x))
      (𝓝[>] 0) (𝓝 (T τ x - x)) := by
  have h1 := duhamel_aux_avg T hTadd hTcont hTbound τ hτ x
  have h2 := duhamel_aux_avg T hTadd hTcont hTbound 0 le_rfl x
  simp only [zero_add, hT0, one_apply_eq_self] at h2
  refine (h1.sub h2).congr' ?_
  filter_upwards [self_mem_nhdsWithin] with h (hh : 0 < h)
  rw [duhamel_aux_shift T hTadd hTcont hTbound τ h hτ hh.le x, smul_sub]

#print axioms duhamel_aux_gen

/-- Duhamel's principle for a forced evolution. Let `X` be a Banach space and `T(t)`, `t ≥ 0`, a
strongly continuous semigroup of bounded operators on it: `T(0) = I`, `T(t + s) = T(t)T(s)`,
`T(t)x → x` as `t → 0⁺` for every state `x`, with a growth bound `‖T(t)‖ ≤ M e^(ωt)`. Let `A` with
domain `D(A)` be its generator: `D(A)` is the set of states `x` where `(T(h)x - x)/h` has a limit as
`h → 0⁺`, and `Ax` is that limit. Let the forcing `f` be integrable over every `[0, t]`. If `u` is a
classical solution of `u' = Au + f`, `u(0) = u0` (differentiable, one-sided at `0`, and in `D(A)` at
every moment), then at every time `t ≥ 0` the state is the start carried forward by the unforced flow
plus every past nudge carried forward for its age: `u(t) = T(t)u0 + ∫_0^t T(t - s) f(s) ds`. -/
theorem classical_solution_eq_duhamel_formula
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    (T : ℝ → X →L[ℝ] X) (D : Set X) (A : X → X)
    (hT0 : T 0 = 1)
    (hTadd : ∀ s t : ℝ, 0 ≤ s → 0 ≤ t → T (s + t) = T s * T t)
    (hTcont : ∀ x : X, Tendsto (fun t : ℝ => T t x) (𝓝[≥] 0) (𝓝 x))
    (hTbound : ∃ M ω : ℝ, ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ M * Real.exp (ω * t))
    (hD : ∀ x : X, x ∈ D ↔ ∃ y : X, Tendsto (fun h : ℝ => h⁻¹ • (T h x - x)) (𝓝[>] 0) (𝓝 y))
    (hA : ∀ x ∈ D, Tendsto (fun h : ℝ => h⁻¹ • (T h x - x)) (𝓝[>] 0) (𝓝 (A x)))
    (f : ℝ → X) (hf : ∀ t : ℝ, 0 ≤ t → IntervalIntegrable f volume 0 t)
    (u0 : X) (u : ℝ → X) (hu0 : u 0 = u0)
    (huD : ∀ s : ℝ, 0 ≤ s → u s ∈ D)
    (hu : ∀ s : ℝ, 0 ≤ s → HasDerivWithinAt u (A (u s) + f s) (Ici 0) s) :
    ∀ t : ℝ, 0 ≤ t → u t = T t u0 + ∫ s in (0 : ℝ)..t, T (t - s) (f s) := by
  intro t ht
  obtain ⟨C, hC⟩ := duhamel_aux_bound T hTbound t
  have hSC := duhamel_aux_strongCont T hTadd hTcont hTbound
  set v : ℝ → X := fun s => T (t - s) (u s) with hv
  have hcont : ContinuousOn v (Icc 0 t) := by
    intro s hs
    have hL : Tendsto (fun y => T (t - y) (u s)) (𝓝[Icc 0 t] s) (𝓝 (T (t - s) (u s))) := by
      refine (hSC (u s) (t - s) (mem_Ici.2 (sub_nonneg.2 hs.2))).tendsto.comp ?_
      refine tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
      · exact tendsto_nhdsWithin_of_tendsto_nhds
          ((continuous_const.sub continuous_id).tendsto s)
      · exact eventually_nhdsWithin_of_forall fun y hy => mem_Ici.2 (sub_nonneg.2 hy.2)
    have hb : ∀ᶠ y in 𝓝[Icc 0 t] s, ‖T (t - y)‖ ≤ C :=
      eventually_nhdsWithin_of_forall fun y hy =>
        hC _ (sub_nonneg.2 hy.2) (by linarith [hy.1])
    have hw : Tendsto u (𝓝[Icc 0 t] s) (𝓝 (u s)) :=
      ((hu s hs.1).continuousWithinAt.mono Icc_subset_Ici_self).tendsto
    exact duhamel_aux_tendsto_apply hL hb hw
  have hderiv : ∀ s ∈ Ioo 0 t, HasDerivWithinAt v (T (t - s) (f s)) (Ioi s) s := by
    intro s hs
    rw [hasDerivWithinAt_iff_tendsto_slope' (lt_irrefl s)]
    -- the slope of `u`
    have hu1 : Tendsto (fun y => (y - s)⁻¹ • (u y - u s)) (𝓝[Ioi s] s) (𝓝 (A (u s) + f s)) := by
      have h := ((hu s hs.1.le).mono (s := Ioi s)
        (fun y (hy : s < y) => mem_Ici.2 (hs.1.le.trans hy.le)))
      rw [hasDerivWithinAt_iff_tendsto_slope' (lt_irrefl s)] at h
      refine h.congr' (Eventually.of_forall fun y => ?_)
      rw [slope_def_module]
    -- the generator
    have hs0 : Tendsto (fun y => y - s) (𝓝[Ioi s] s) (𝓝[>] 0) := by
      refine tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
      · have : Tendsto (fun y : ℝ => y - s) (𝓝 s) (𝓝 (s - s)) :=
          tendsto_id.sub tendsto_const_nhds
        simpa using tendsto_nhdsWithin_of_tendsto_nhds this
      · exact eventually_nhdsWithin_of_forall fun y (hy : s < y) => mem_Ioi.2 (sub_pos.2 hy)
    have hu2 : Tendsto (fun y => (y - s)⁻¹ • (T (y - s) (u s) - u s)) (𝓝[Ioi s] s)
        (𝓝 (A (u s))) := (hA (u s) (huD s hs.1.le)).comp hs0
    have hw := hu1.sub hu2
    rw [add_sub_cancel_left] at hw
    have hL : Tendsto (fun y => T (t - y) (f s)) (𝓝[Ioi s] s) (𝓝 (T (t - s) (f s))) := by
      refine (hSC (f s) (t - s) (mem_Ici.2 (sub_nonneg.2 hs.2.le))).tendsto.comp ?_
      refine tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
      · exact tendsto_nhdsWithin_of_tendsto_nhds
          ((continuous_const.sub continuous_id).tendsto s)
      · have : ∀ᶠ y in 𝓝[Ioi s] s, y < t :=
          eventually_nhdsWithin_of_eventually_nhds (gt_mem_nhds hs.2)
        filter_upwards [this] with y hy
        exact mem_Ici.2 (sub_nonneg.2 hy.le)
    have hlt : ∀ᶠ y in 𝓝[Ioi s] s, y < t :=
      eventually_nhdsWithin_of_eventually_nhds (gt_mem_nhds hs.2)
    have hb : ∀ᶠ y in 𝓝[Ioi s] s, ‖T (t - y)‖ ≤ C := by
      filter_upwards [hlt, self_mem_nhdsWithin] with y hy hy'
      exact hC _ (sub_nonneg.2 hy.le) (by linarith [hs.1, mem_Ioi.1 hy'])
    refine (duhamel_aux_tendsto_apply hL hb hw).congr' ?_
    filter_upwards [hlt, self_mem_nhdsWithin] with y hy hy'
    have hsy : s < y := hy'
    have hsplit : T (t - s) = T (t - y) * T (y - s) := by
      rw [← hTadd (t - y) (y - s) (sub_nonneg.2 hy.le) (sub_nonneg.2 hsy.le)]
      congr 1; ring
    rw [slope_def_module]
    simp only [hv, hsplit, mul_apply_eq_comp, map_sub, map_smul]
    rw [smul_sub, smul_sub, smul_sub]
    abel
  have hint : IntervalIntegrable (fun s => T (t - s) (f s)) volume 0 t :=
    duhamel_aux_intervalIntegrable T hTadd hTcont hTbound f t ht (hf t ht)
  have hftc := intervalIntegral.integral_eq_sub_of_hasDeriv_right_of_le ht hcont hderiv hint
  rw [hftc]
  simp [hv, hT0, hu0]

/-- The mild solution solves the equation in integrated form. With the same semigroup `T(t)` and
generator `A` on `D(A)`, take any start `u0` in `X` (no domain needed) and any forcing `f` integrable
over every `[0, t]`, and let `u(t) = T(t)u0 + ∫_0^t T(t - s) f(s) ds` be the mild solution. Then for
every `t ≥ 0` the time integral `∫_0^t u(s) ds` lies in `D(A)`, and
`u(t) = u0 + A ∫_0^t u(s) ds + ∫_0^t f(s) ds`. -/
theorem mild_solution_integrated_form
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    (T : ℝ → X →L[ℝ] X) (D : Set X) (A : X → X)
    (hT0 : T 0 = 1)
    (hTadd : ∀ s t : ℝ, 0 ≤ s → 0 ≤ t → T (s + t) = T s * T t)
    (hTcont : ∀ x : X, Tendsto (fun t : ℝ => T t x) (𝓝[≥] 0) (𝓝 x))
    (hTbound : ∃ M ω : ℝ, ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ M * Real.exp (ω * t))
    (hD : ∀ x : X, x ∈ D ↔ ∃ y : X, Tendsto (fun h : ℝ => h⁻¹ • (T h x - x)) (𝓝[>] 0) (𝓝 y))
    (hA : ∀ x ∈ D, Tendsto (fun h : ℝ => h⁻¹ • (T h x - x)) (𝓝[>] 0) (𝓝 (A x)))
    (f : ℝ → X) (hf : ∀ t : ℝ, 0 ≤ t → IntervalIntegrable f volume 0 t)
    (u0 : X) (t : ℝ) (ht : 0 ≤ t) :
    let u : ℝ → X := fun τ => T τ u0 + ∫ s in (0 : ℝ)..τ, T (τ - s) (f s)
    (∫ s in (0 : ℝ)..t, u s) ∈ D ∧
      u t = u0 + A (∫ s in (0 : ℝ)..t, u s) + ∫ s in (0 : ℝ)..t, f s := by
  intro u
  have hSC := duhamel_aux_strongCont T hTadd hTcont hTbound
  obtain ⟨C, hC⟩ := duhamel_aux_bound T hTbound (t + 1)
  have hC0 : 0 ≤ C := (norm_nonneg _).trans (hC 0 le_rfl (by linarith))
  set μt : Measure ℝ := volume.restrict (Ioc (0 : ℝ) t) with hμt
  have hft : Integrable f μt := (intervalIntegrable_iff_integrableOn_Ioc_of_le ht).1 (hf t ht)
  -- the kernel `K (s, r) = T (s - r) (f r)` for `r ≤ s`, and `0` otherwise
  set K : ℝ × ℝ → X :=
    Set.indicator {p : ℝ × ℝ | p.2 ≤ p.1} (fun p => T (p.1 - p.2) (f p.2)) with hK
  have hKint : Integrable K (μt.prod μt) := by
    have hm0 : AEStronglyMeasurable (fun p : ℝ × ℝ => T (max (p.1 - p.2) 0) (f p.2))
        (μt.prod μt) :=
      duhamel_aux_aesm T hTadd hTcont hTbound
        ((continuous_fst.sub continuous_snd).aestronglyMeasurable)
        hft.aestronglyMeasurable.comp_snd
    have heq : Set.indicator {p : ℝ × ℝ | p.2 ≤ p.1}
        (fun p : ℝ × ℝ => T (max (p.1 - p.2) 0) (f p.2)) = K := by
      rw [hK]
      refine Set.indicator_congr fun p hp => ?_
      rw [max_eq_left (sub_nonneg.2 hp)]
    have hm : AEStronglyMeasurable K (μt.prod μt) := by
      rw [← heq]; exact hm0.indicator (measurableSet_le measurable_snd measurable_fst)
    refine Integrable.mono' ((hft.norm.const_mul C).comp_snd μt) hm ?_
    rw [hμt, Measure.prod_restrict]
    filter_upwards [ae_restrict_mem (measurableSet_Ioc.prod measurableSet_Ioc)] with p hp
    simp only [hK, Set.indicator, mem_ofPred_eq]
    split_ifs with h
    · calc ‖T (p.1 - p.2) (f p.2)‖ ≤ ‖T (p.1 - p.2)‖ * ‖f p.2‖ := (T _).le_opNorm _
        _ ≤ C * ‖f p.2‖ := by
          gcongr
          exact hC _ (sub_nonneg.2 h) (by linarith [hp.1.2, hp.2.1])
    · simp only [norm_zero]; positivity
  have hgK : ∀ s : ℝ, 0 ≤ s → s ≤ t →
      ∫ r in (0 : ℝ)..s, T (s - r) (f r) = ∫ r, K (s, r) ∂μt := by
    intro s hs0 hst
    have : (fun r => K (s, r)) = (Iic s).indicator (fun r => T (s - r) (f r)) := by
      ext r; simp only [hK, Set.indicator, mem_ofPred_eq, mem_Iic]
    rw [this, hμt, setIntegral_indicator measurableSet_Iic, Ioc_inter_Iic, min_eq_right hst,
      intervalIntegral.integral_of_le hs0]
  have hinner : ∀ r ∈ Ioc (0 : ℝ) t,
      ∫ s, K (s, r) ∂μt = ∫ σ in (0 : ℝ)..t - r, T σ (f r) := by
    intro r hr
    have : (fun s => K (s, r)) = (Ici r).indicator (fun s => T (s - r) (f r)) := by
      ext s; simp only [hK, Set.indicator, mem_ofPred_eq, mem_Ici]
    have hset : Ioc 0 t ∩ Ici r = Icc r t := by
      ext s; simp only [mem_inter_iff, mem_Ioc, mem_Ici, mem_Icc]; constructor
      · rintro ⟨⟨_, h2⟩, h3⟩; exact ⟨h3, h2⟩
      · rintro ⟨h3, h2⟩; exact ⟨⟨by linarith [hr.1], h2⟩, h3⟩
    rw [this, hμt, setIntegral_indicator measurableSet_Ici, hset, integral_Icc_eq_integral_Ioc,
      ← intervalIntegral.integral_of_le hr.2,
      intervalIntegral.integral_comp_sub_right (fun σ => T σ (f r)) r, sub_self]
  have hTu0 : IntervalIntegrable (fun s => T s u0) volume 0 t :=
    ((hSC u0).mono (by rw [uIcc_of_le ht]; exact Icc_subset_Ici_self)).intervalIntegrable
  have hG'int : IntervalIntegrable (fun s => ∫ r in (0 : ℝ)..s, T (s - r) (f r)) volume 0 t := by
    rw [intervalIntegrable_iff_integrableOn_Ioc_of_le ht]
    refine hKint.integral_prod_left.congr ?_
    filter_upwards [ae_restrict_mem measurableSet_Ioc] with s hs
    exact (hgK s hs.1.le hs.2).symm
  have hSint : IntervalIntegrable (fun r => ∫ σ in (0 : ℝ)..t - r, T σ (f r)) volume 0 t := by
    rw [intervalIntegrable_iff_integrableOn_Ioc_of_le ht]
    refine hKint.integral_prod_right.congr ?_
    filter_upwards [ae_restrict_mem measurableSet_Ioc] with r hr
    exact hinner r hr
  have hW : ∫ s in (0 : ℝ)..t, u s = (∫ σ in (0 : ℝ)..t, T σ u0) +
      ∫ r in (0 : ℝ)..t, ∫ σ in (0 : ℝ)..t - r, T σ (f r) := by
    simp only [u]
    rw [intervalIntegral.integral_add hTu0 hG'int]
    congr 1
    rw [intervalIntegral.integral_of_le ht, intervalIntegral.integral_of_le ht]
    calc ∫ s in Ioc 0 t, ∫ r in (0 : ℝ)..s, T (s - r) (f r)
          = ∫ s, ∫ r, K (s, r) ∂μt ∂μt := by
            refine integral_congr_ae ?_
            filter_upwards [ae_restrict_mem measurableSet_Ioc] with s hs
            exact hgK s hs.1.le hs.2
      _ = ∫ r, ∫ s, K (s, r) ∂μt ∂μt := integral_integral_swap hKint
      _ = ∫ r in Ioc 0 t, ∫ σ in (0 : ℝ)..t - r, T σ (f r) := by
            refine integral_congr_ae ?_
            filter_upwards [ae_restrict_mem measurableSet_Ioc] with r hr
            exact hinner r hr
  have hlim1 := duhamel_aux_gen T hT0 hTadd hTcont hTbound t ht u0
  have hlim2 : Tendsto (fun h : ℝ => ∫ r in (0 : ℝ)..t,
      h⁻¹ • (T h (∫ σ in (0 : ℝ)..t - r, T σ (f r)) - ∫ σ in (0 : ℝ)..t - r, T σ (f r)))
      (𝓝[>] 0) (𝓝 (∫ r in (0 : ℝ)..t, (T (t - r) (f r) - f r))) := by
    refine intervalIntegral.tendsto_integral_filter_of_dominated_convergence
      (fun r => 2 * C * ‖f r‖) ?_ ?_ ?_ ?_
    · refine Eventually.of_forall fun h => ?_
      rw [uIoc_of_le ht]
      have hcl : Continuous (fun y : X => h⁻¹ • (T h y - y)) :=
        ((T h).continuous.sub continuous_id).const_smul _
      exact hcl.comp_aestronglyMeasurable
        ((intervalIntegrable_iff_integrableOn_Ioc_of_le ht).1 hSint).aestronglyMeasurable
    · filter_upwards [Ioo_mem_nhdsGT (zero_lt_one : (0 : ℝ) < 1)] with h hh
      refine Eventually.of_forall fun r hr => ?_
      rw [uIoc_of_le ht] at hr
      have hτ : 0 ≤ t - r := sub_nonneg.2 hr.2
      rw [duhamel_aux_shift T hTadd hTcont hTbound (t - r) h hτ hh.1.le (f r)]
      have hb1 : ‖∫ σ in t - r..t - r + h, T σ (f r)‖ ≤ C * ‖f r‖ * h := by
        have := intervalIntegral.norm_integral_le_of_norm_le_const (a := t - r)
          (b := t - r + h) (C := C * ‖f r‖) (f := fun σ => T σ (f r)) ?_
        · simpa [abs_of_pos hh.1] using this
        intro σ hσ
        rw [uIoc_of_le (by linarith [hh.1])] at hσ
        calc ‖T σ (f r)‖ ≤ ‖T σ‖ * ‖f r‖ := (T σ).le_opNorm _
          _ ≤ C * ‖f r‖ := by
            gcongr
            exact hC σ (by linarith [hσ.1]) (by linarith [hσ.2, hh.2, hr.1])
      have hb2 : ‖∫ σ in (0 : ℝ)..h, T σ (f r)‖ ≤ C * ‖f r‖ * h := by
        have := intervalIntegral.norm_integral_le_of_norm_le_const (a := 0)
          (b := h) (C := C * ‖f r‖) (f := fun σ => T σ (f r)) ?_
        · simpa [abs_of_pos hh.1] using this
        intro σ hσ
        rw [uIoc_of_le hh.1.le] at hσ
        calc ‖T σ (f r)‖ ≤ ‖T σ‖ * ‖f r‖ := (T σ).le_opNorm _
          _ ≤ C * ‖f r‖ := by
            gcongr
            exact hC σ (by linarith [hσ.1]) (by linarith [hσ.2, hh.2, ht])
      calc ‖h⁻¹ • ((∫ σ in t - r..t - r + h, T σ (f r)) - ∫ σ in (0 : ℝ)..h, T σ (f r))‖
          = h⁻¹ * ‖(∫ σ in t - r..t - r + h, T σ (f r)) - ∫ σ in (0 : ℝ)..h, T σ (f r)‖ := by
            rw [norm_smul, Real.norm_of_nonneg (inv_nonneg.2 hh.1.le)]
        _ ≤ h⁻¹ * (C * ‖f r‖ * h + C * ‖f r‖ * h) := by
            exact mul_le_mul_of_nonneg_left ((norm_sub_le _ _).trans (add_le_add hb1 hb2))
              (inv_nonneg.2 hh.1.le)
        _ = 2 * C * ‖f r‖ := by
            have hh0 : h ≠ 0 := hh.1.ne'
            field_simp; ring
    · exact (hf t ht).norm.const_mul (2 * C)
    · refine Eventually.of_forall fun r hr => ?_
      rw [uIoc_of_le ht] at hr
      exact duhamel_aux_gen T hT0 hTadd hTcont hTbound (t - r) (sub_nonneg.2 hr.2) (f r)
  have hTf : IntervalIntegrable (fun r => T (t - r) (f r)) volume 0 t :=
    duhamel_aux_intervalIntegrable T hTadd hTcont hTbound f t ht (hf t ht)
  rw [intervalIntegral.integral_sub hTf (hf t ht)] at hlim2
  have hval : (T t u0 - u0) + ((∫ r in (0 : ℝ)..t, T (t - r) (f r)) - ∫ r in (0 : ℝ)..t, f r) =
      u t - u0 - ∫ s in (0 : ℝ)..t, f s := by
    simp only [u]; abel
  set W := ∫ s in (0 : ℝ)..t, u s with hWdef
  have hlimW : Tendsto (fun h : ℝ => h⁻¹ • (T h W - W)) (𝓝[>] 0)
      (𝓝 (u t - u0 - ∫ s in (0 : ℝ)..t, f s)) := by
    have := hlim1.add hlim2
    rw [hval] at this
    refine this.congr' (Eventually.of_forall fun h => ?_)
    let Ph : X →L[ℝ] X := h⁻¹ • (T h - 1)
    have hPh : ∀ y, Ph y = h⁻¹ • (T h y - y) := by intro y; simp [Ph]
    have e := Ph.intervalIntegral_comp_comm hSint
    simp only [hPh] at e
    simp only
    rw [e, hW, map_add]
    simp only [smul_sub, smul_add]
    abel
  have hWD : W ∈ D := (hD W).2 ⟨_, hlimW⟩
  refine ⟨hWD, ?_⟩
  have hAW := tendsto_nhds_unique (hA W hWD) hlimW
  rw [hAW]; abel

/-- One heating block in the one-number room. With the walls' pull `k > 0` per hour, the flow is
multiplication by `e^(-kt)`; a radiator adding `q` per hour from time `a` to time `b` contributes, at
any time `t ≥ b`, `∫_a^b e^(-k(t - s)) q ds = (q/k)(e^(-k(t - b)) - e^(-k(t - a)))`. -/
theorem heating_block_duhamel_integral (k q a b t : ℝ) (hk : 0 < k) (hab : a ≤ b) (hbt : b ≤ t) :
    ∫ s in a..b, Real.exp (-k * (t - s)) * q =
      q / k * (Real.exp (-k * (t - b)) - Real.exp (-k * (t - a))) := by
  have hderiv : ∀ x ∈ uIcc a b,
      HasDerivAt (fun s => q / k * Real.exp (-k * (t - s))) (Real.exp (-k * (t - x)) * q) x := by
    intro x _
    have h1 : HasDerivAt (fun s => -k * (t - s)) k x := by
      have := ((hasDerivAt_id x).const_sub t).const_mul (-k)
      simpa using this
    have := (h1.exp).const_mul (q / k)
    convert this using 1
    field_simp
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv]
  · ring
  · exact (by fun_prop : Continuous fun s => Real.exp (-k * (t - s)) * q).intervalIntegrable _ _

-- The room: pull k = 1/2 per hour, radiator q = 5 C/h, so q/k = 10 C, and the radiator-on level 12 + 10 = 22 C.
example : (5 : ℚ) / (1 / 2) = 10 := by norm_num
example : (12 : ℚ) + 5 / (1 / 2) = 22 := by norm_num

-- At noon (t = 6 h after 06:00) block 1 (0 to 1 h) has ages 5 to 6 h, block 2 (3 to 6 h) ages 0 to 3 h.
example : (6 : ℤ) - 1 = 5 ∧ (6 : ℤ) - 0 = 6 ∧ (6 : ℤ) - 6 = 0 ∧ (6 : ℤ) - 3 = 3 := by decide

-- The exponents at noon: k times 6, 5 and 3 hours are 3, 5/2 and 3/2.
example : (1 / 2 : ℚ) * 6 = 3 ∧ (1 / 2 : ℚ) * 5 = 5 / 2 ∧ (1 / 2 : ℚ) * 3 = 3 / 2 := by norm_num

-- No decay: 4 hours of heating at 5 C/h pour in 20 C, so 12 + 4 + 20 = 36 C.
example : (5 : ℤ) * ((1 - 0) + (6 - 3)) = 20 := by decide
example : (12 : ℤ) + 4 + 5 * ((1 - 0) + (6 - 3)) = 36 := by decide

-- An open window triples the pull: 3 times 1/2 is 3/2 per hour.
example : (3 : ℚ) * (1 / 2) = 3 / 2 := by norm_num

#print axioms classical_solution_eq_duhamel_formula
#print axioms mild_solution_integrated_form
#print axioms heating_block_duhamel_integral
