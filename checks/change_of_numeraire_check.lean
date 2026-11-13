-- Change of numeraire: reweighting the odds by how much a positive traded unit U outgrew the old unit A gives a true probability measure under which every traded price counted in U is a fair game (a martingale), using Bayes' rule for conditional averages under a change of measure.
import Mathlib.Probability.Martingale.Basic
import Mathlib.MeasureTheory.Measure.WithDensity

open MeasureTheory

/-- Helper: for an `m`-measurable weight `g ≥ 0`, weighting by `Z` or by `Q[Z | m]` gives the same
lower integral. -/
theorem numeraire_lintegral_mul_condExp {Ω : Type*} {m m0 : MeasurableSpace Ω} (hm : m ≤ m0)
    (Q : Measure Ω) [IsFiniteMeasure Q] (Z : Ω → ℝ) (hZ_nn : 0 ≤ᵐ[Q] Z) (hZ_int : Integrable Z Q)
    (g : Ω → ENNReal) (hg : Measurable[m] g) :
    ∫⁻ ω, g ω * ENNReal.ofReal (Z ω) ∂Q = ∫⁻ ω, g ω * ENNReal.ofReal (Q[Z|m] ω) ∂Q := by
  have hD_nn : 0 ≤ᵐ[Q] Q[Z|m] := condExp_nonneg hZ_nn
  have htrim : (Q.withDensity (fun ω => ENNReal.ofReal (Z ω))).trim hm
      = (Q.withDensity (fun ω => ENNReal.ofReal (Q[Z|m] ω))).trim hm := by
    refine @Measure.ext Ω m _ _ fun s hs => ?_
    rw [trim_measurableSet_eq hm hs, trim_measurableSet_eq hm hs,
      withDensity_apply _ (hm s hs), withDensity_apply _ (hm s hs),
      ← ofReal_integral_eq_lintegral_ofReal hZ_int.integrableOn (ae_restrict_of_ae hZ_nn),
      ← ofReal_integral_eq_lintegral_ofReal integrable_condExp.integrableOn
        (ae_restrict_of_ae hD_nn),
      setIntegral_condExp hm hZ_int hs]
  have hgm : Measurable g := hg.mono hm le_rfl
  have h1 : ∫⁻ ω, g ω * ENNReal.ofReal (Z ω) ∂Q
      = ∫⁻ ω, g ω ∂(Q.withDensity (fun ω => ENNReal.ofReal (Z ω))) := by
    rw [lintegral_withDensity_eq_lintegral_mul₀ hZ_int.aemeasurable.ennreal_ofReal
      hgm.aemeasurable]
    exact lintegral_congr fun ω => mul_comm _ _
  have h2 : ∫⁻ ω, g ω * ENNReal.ofReal (Q[Z|m] ω) ∂Q
      = ∫⁻ ω, g ω ∂(Q.withDensity (fun ω => ENNReal.ofReal (Q[Z|m] ω))) := by
    rw [lintegral_withDensity_eq_lintegral_mul₀ integrable_condExp.aemeasurable.ennreal_ofReal
      hgm.aemeasurable]
    exact lintegral_congr fun ω => mul_comm _ _
  rw [h1, h2, ← lintegral_trim hm hg, ← lintegral_trim hm hg, htrim]

#print axioms numeraire_lintegral_mul_condExp

/-- Helper: the conditional average of a strictly positive integrable function is positive
almost everywhere. -/
theorem numeraire_condExp_pos {Ω : Type*} {m m0 : MeasurableSpace Ω} (hm : m ≤ m0)
    (Q : Measure Ω) [IsFiniteMeasure Q] (Z : Ω → ℝ) (hZ_pos : ∀ ω, 0 < Z ω)
    (hZ_int : Integrable Z Q) : ∀ᵐ ω ∂Q, 0 < Q[Z|m] ω := by
  have hs : MeasurableSet[m] {ω | Q[Z|m] ω ≤ 0} :=
    (stronglyMeasurable_condExp (μ := Q) (f := Z) (m := m)).measurable
      (measurableSet_Iic (a := (0 : ℝ)))
  have key := numeraire_lintegral_mul_condExp hm Q Z (ae_of_all _ fun ω => (hZ_pos ω).le) hZ_int
    ({ω | Q[Z|m] ω ≤ 0}.indicator 1)
    (Measurable.indicator (m := m) (@measurable_one ENNReal Ω _ m _) hs)
  have hR : ∫⁻ ω, {ω | Q[Z|m] ω ≤ 0}.indicator 1 ω * ENNReal.ofReal (Q[Z|m] ω) ∂Q = 0 := by
    refine (lintegral_congr fun ω => ?_).trans lintegral_zero
    by_cases h : Q[Z|m] ω ≤ 0
    · simp [ENNReal.ofReal_eq_zero.2 h]
    · simp [Set.indicator, h]
  rw [hR, lintegral_eq_zero_iff'] at key
  · filter_upwards [key] with ω hω
    by_contra h
    have h' : Q[Z|m] ω ≤ 0 := not_lt.1 h
    have : ENNReal.ofReal (Z ω) = 0 := by simpa [Set.indicator, h'] using hω
    exact absurd (ENNReal.ofReal_eq_zero.1 this) (not_le.2 (hZ_pos ω))
  · exact ((measurable_one.indicator (hm _ hs)).aemeasurable).mul
      hZ_int.aemeasurable.ennreal_ofReal

#print axioms numeraire_condExp_pos

/-- Helper: integrability under `Q` reweighted by a positive `Z` is integrability of `Z * f`
under `Q`. -/
theorem numeraire_integrable_withDensity_iff {Ω : Type*} {m0 : MeasurableSpace Ω}
    (Q : Measure Ω) (Z f : Ω → ℝ) (hZ_pos : ∀ ω, 0 < Z ω) (hZm : AEMeasurable Z Q) :
    Integrable f (Q.withDensity fun ω => ENNReal.ofReal (Z ω))
      ↔ Integrable (fun ω => Z ω * f ω) Q := by
  have h := integrable_withDensity_iff_integrable_smul₀ (μ := Q) hZm.real_toNNReal (g := f)
  have e : (fun x => (Z x).toNNReal • f x) = fun ω => Z ω * f ω := by
    funext x
    rw [NNReal.smul_def, smul_eq_mul, Real.coe_toNNReal _ (hZ_pos x).le]
  rw [e] at h
  exact h

#print axioms numeraire_integrable_withDensity_iff

/-- Helper: set integrals under `Q` reweighted by a positive `Z`. -/
theorem numeraire_setIntegral_withDensity {Ω : Type*} {m0 : MeasurableSpace Ω}
    (Q : Measure Ω) (Z f : Ω → ℝ) (hZ_pos : ∀ ω, 0 < Z ω) (hZm : AEMeasurable Z Q)
    {s : Set Ω} (hs : MeasurableSet s) :
    ∫ ω in s, f ω ∂(Q.withDensity fun ω => ENNReal.ofReal (Z ω))
      = ∫ ω in s, Z ω * f ω ∂Q := by
  have h := setIntegral_withDensity_eq_setIntegral_smul₀ (μ := Q)
    hZm.real_toNNReal.restrict f hs
  have e : (fun x => (Z x).toNNReal • f x) = fun ω => Z ω * f ω := by
    funext x
    rw [NNReal.smul_def, smul_eq_mul, Real.coe_toNNReal _ (hZ_pos x).le]
  rw [e] at h
  exact h

#print axioms numeraire_setIntegral_withDensity

/-- Helper: Bayes' rule for conditional averages under a change of measure. -/
theorem numeraire_bayes {Ω : Type*} {m m0 : MeasurableSpace Ω} (hm : m ≤ m0)
    (Q : Measure Ω) [IsProbabilityMeasure Q] (Z X : Ω → ℝ)
    (hZ_pos : ∀ ω, 0 < Z ω) (hZ_int : Integrable Z Q)
    (hZX : Integrable (fun ω => Z ω * X ω) Q) :
    (Q.withDensity (fun ω => ENNReal.ofReal (Z ω)))[X | m]
      =ᵐ[Q.withDensity (fun ω => ENNReal.ofReal (Z ω))]
        fun ω => Q[fun ω => Z ω * X ω | m] ω / Q[Z | m] ω := by
  have hZm : AEMeasurable Z Q := hZ_int.aemeasurable
  have : IsFiniteMeasure (Q.withDensity (fun ω => ENNReal.ofReal (Z ω))) :=
    isFiniteMeasure_withDensity_ofReal hZ_int.2
  have hDpos := numeraire_condExp_pos hm Q Z hZ_pos hZ_int
  set N := Q[fun ω => Z ω * X ω | m] with hN
  set D := Q[Z | m] with hD
  set Y : Ω → ℝ := fun ω => N ω / D ω with hYdef
  have hYm : StronglyMeasurable[m] Y :=
    (stronglyMeasurable_condExp.measurable.div stronglyMeasurable_condExp.measurable).stronglyMeasurable
  have hX : Integrable X (Q.withDensity (fun ω => ENNReal.ofReal (Z ω))) :=
    (numeraire_integrable_withDensity_iff Q Z X hZ_pos hZm).2 hZX
  have hZY : Integrable (fun ω => Z ω * Y ω) Q := by
    refine ⟨hZ_int.1.mul (hYm.mono hm).aestronglyMeasurable, ?_⟩
    rw [hasFiniteIntegral_iff_enorm]
    have hY_meas : Measurable[m] (fun ω => ENNReal.ofReal |Y ω|) :=
      ENNReal.measurable_ofReal.comp (continuous_abs.measurable.comp hYm.measurable)
    calc ∫⁻ ω, ‖Z ω * Y ω‖ₑ ∂Q
        = ∫⁻ ω, ENNReal.ofReal |Y ω| * ENNReal.ofReal (Z ω) ∂Q := by
          refine lintegral_congr fun ω => ?_
          rw [Real.enorm_eq_ofReal_abs, ← ENNReal.ofReal_mul (abs_nonneg _)]
          congr 1
          rw [abs_mul, abs_of_pos (hZ_pos ω)]
          ring
      _ = ∫⁻ ω, ENNReal.ofReal |Y ω| * ENNReal.ofReal (D ω) ∂Q :=
          numeraire_lintegral_mul_condExp hm Q Z (ae_of_all _ fun ω => (hZ_pos ω).le) hZ_int _
            hY_meas
      _ = ∫⁻ ω, ‖N ω‖ₑ ∂Q := by
          refine lintegral_congr_ae ?_
          filter_upwards [hDpos] with ω hω
          rw [← ENNReal.ofReal_mul (abs_nonneg _), Real.enorm_eq_ofReal_abs]
          congr 1
          simp only [hYdef, abs_div, abs_of_pos hω]
          field_simp
      _ < ⊤ := integrable_condExp.2
  have hY : Integrable Y (Q.withDensity (fun ω => ENNReal.ofReal (Z ω))) :=
    (numeraire_integrable_withDensity_iff Q Z Y hZ_pos hZm).2 hZY
  have hEq : ∀ s, MeasurableSet[m] s →
      ∫ ω in s, Y ω ∂(Q.withDensity (fun ω => ENNReal.ofReal (Z ω)))
        = ∫ ω in s, X ω ∂(Q.withDensity (fun ω => ENNReal.ofReal (Z ω))) := by
    intro s hs
    rw [numeraire_setIntegral_withDensity Q Z Y hZ_pos hZm (hm s hs),
      numeraire_setIntegral_withDensity Q Z X hZ_pos hZm (hm s hs),
      ← setIntegral_condExp hm hZX hs, ← setIntegral_condExp hm hZY hs]
    have hpull : Q[fun ω => Z ω * Y ω | m] =ᵐ[Q] Y * D := by
      have e : (fun ω => Z ω * Y ω) = Y * Z := by funext ω; simp [mul_comm]
      rw [e]
      have hYZ : Integrable (Y * Z) Q := by rw [← e]; exact hZY
      exact condExp_mul_of_stronglyMeasurable_left hYm hYZ hZ_int
    refine setIntegral_congr_ae (hm s hs) ?_
    filter_upwards [hpull, hDpos] with ω h1 h2 _
    rw [h1, Pi.mul_apply]
    exact div_mul_cancel₀ _ h2.ne'
  exact (ae_eq_condExp_of_forall_setIntegral_eq hm hX (fun s _ _ => hY.integrableOn)
    (fun s hs _ => hEq s hs) hYm.aestronglyMeasurable).symm

#print axioms numeraire_bayes

/-- Helper: the numeraire density has total mass 1. -/
theorem numeraire_density_lintegral {Ω ι : Type*} {m0 : MeasurableSpace Ω}
    [Preorder ι] [OrderBot ι]
    (Q : Measure Ω) [IsProbabilityMeasure Q] (ℱ : Filtration ι m0)
    (A U : ι → Ω → ℝ) (T : ι)
    (hA_pos : ∀ t ω, 0 < A t ω) (hU_pos : ∀ t ω, 0 < U t ω)
    (hU : Martingale (fun t ω => U t ω / A t ω) ℱ Q) :
    ∫⁻ ω, ENNReal.ofReal ((U T ω / U ⊥ ω) / (A T ω / A ⊥ ω)) ∂Q = 1 := by
  have hM0 : StronglyMeasurable[ℱ ⊥] (fun ω => U ⊥ ω / A ⊥ ω) := hU.stronglyAdapted ⊥
  have hg : Measurable[ℱ ⊥] (fun ω => ENNReal.ofReal (1 / (U ⊥ ω / A ⊥ ω))) :=
    ENNReal.measurable_ofReal.comp (measurable_const.div hM0.measurable)
  have e : ∀ ω, ENNReal.ofReal ((U T ω / U ⊥ ω) / (A T ω / A ⊥ ω))
      = ENNReal.ofReal (1 / (U ⊥ ω / A ⊥ ω)) * ENNReal.ofReal (U T ω / A T ω) := by
    intro ω
    have h1 := hU_pos ⊥ ω
    have h2 := hA_pos ⊥ ω
    rw [← ENNReal.ofReal_mul (by positivity)]
    congr 1
    field_simp
  have key := numeraire_lintegral_mul_condExp (ℱ.le ⊥) Q (fun ω => U T ω / A T ω)
    (ae_of_all _ fun ω => (div_pos (hU_pos T ω) (hA_pos T ω)).le) (hU.integrable T) _ hg
  rw [lintegral_congr e, key]
  have hce : Q[fun ω => U T ω / A T ω | ℱ ⊥] =ᵐ[Q] fun ω => U ⊥ ω / A ⊥ ω :=
    hU.condExp_ae_eq bot_le
  rw [lintegral_congr_ae (g := fun _ => (1 : ENNReal)) ?_]
  · simp
  · filter_upwards [hce] with ω hω
    rw [hω, ← ENNReal.ofReal_mul (by have := hU_pos ⊥ ω; have := hA_pos ⊥ ω; positivity)]
    have h1 := hU_pos ⊥ ω
    have h2 := hA_pos ⊥ ω
    rw [one_div_mul_cancel (by positivity), ENNReal.ofReal_one]

#print axioms numeraire_density_lintegral

/-- The numeraire theorem. Let `A` (the old unit) and `U` (the new unit) be strictly positive
traded prices, and let `Q` be a probability measure under which every traded price counted in `A`
is a martingale (a fair game); in particular `U / A` and `V / A` are `Q`-martingales. Reweight `Q`
by the density `Z_T = (U_T / U_0) / (A_T / A_0)`, how much the new unit outgrew the old one by the
end date `T`, to get the new measure `Q^U`. If the payoff counted in the new unit has a finite
average under `Q^U`, then at every time `t ≤ T` the price counted in the new unit is the
`Q^U`-average of the payoff counted in the new unit: `E^U[V_T / U_T | F_t] = V_t / U_t`.
Time is any ordered index with a first time `⊥` ("today"), so it covers discrete and
continuous time. -/
theorem change_of_numeraire_price_is_fair_game {Ω ι : Type*} {m0 : MeasurableSpace Ω}
    [Preorder ι] [OrderBot ι]
    (Q : Measure Ω) [IsProbabilityMeasure Q] (ℱ : Filtration ι m0)
    (A U V : ι → Ω → ℝ) (T : ι)
    (hA_pos : ∀ t ω, 0 < A t ω) (hU_pos : ∀ t ω, 0 < U t ω)
    (hU : Martingale (fun t ω => U t ω / A t ω) ℱ Q)
    (hV : Martingale (fun t ω => V t ω / A t ω) ℱ Q)
    (hfin : Integrable (fun ω => V T ω / U T ω)
      (Q.withDensity (fun ω => ENNReal.ofReal ((U T ω / U ⊥ ω) / (A T ω / A ⊥ ω)))))
    (t : ι) (ht : t ≤ T) :
    (Q.withDensity (fun ω => ENNReal.ofReal ((U T ω / U ⊥ ω) / (A T ω / A ⊥ ω))))[
        fun ω => V T ω / U T ω | ℱ t]
      =ᵐ[Q.withDensity (fun ω => ENNReal.ofReal ((U T ω / U ⊥ ω) / (A T ω / A ⊥ ω)))]
        fun ω => V t ω / U t ω := by
  have hZpos : ∀ ω, 0 < (U T ω / U ⊥ ω) / (A T ω / A ⊥ ω) := fun ω => by
    have := hU_pos T ω; have := hU_pos ⊥ ω; have := hA_pos T ω; have := hA_pos ⊥ ω
    positivity
  have hZeq : (fun ω => (U T ω / U ⊥ ω) / (A T ω / A ⊥ ω))
      = fun ω => (U T ω / A T ω) / (U ⊥ ω / A ⊥ ω) :=
    funext fun ω => div_div_div_comm _ _ _ _
  have hZsm : AEStronglyMeasurable (fun ω => (U T ω / U ⊥ ω) / (A T ω / A ⊥ ω)) Q := by
    rw [hZeq]
    exact (((hU.stronglyAdapted T).mono (ℱ.le T)).measurable.div
      ((hU.stronglyAdapted ⊥).mono (ℱ.le ⊥)).measurable).aestronglyMeasurable
  have hZ_int : Integrable (fun ω => (U T ω / U ⊥ ω) / (A T ω / A ⊥ ω)) Q := by
    refine ⟨hZsm, (hasFiniteIntegral_iff_ofReal (ae_of_all _ fun ω => (hZpos ω).le)).2 ?_⟩
    rw [numeraire_density_lintegral Q ℱ A U T hA_pos hU_pos hU]
    exact ENNReal.one_lt_top
  have hZX := (numeraire_integrable_withDensity_iff Q
    (fun ω => (U T ω / U ⊥ ω) / (A T ω / A ⊥ ω)) (fun ω => V T ω / U T ω) hZpos
    hZ_int.aemeasurable).1 hfin
  have hB := numeraire_bayes (ℱ.le t) Q (fun ω => (U T ω / U ⊥ ω) / (A T ω / A ⊥ ω))
    (fun ω => V T ω / U T ω) hZpos hZ_int hZX
  refine hB.trans ?_
  have hc : StronglyMeasurable[ℱ t] (fun ω => 1 / (U ⊥ ω / A ⊥ ω)) :=
    (measurable_const.div ((hU.stronglyAdapted ⊥).mono (ℱ.mono bot_le)).measurable).stronglyMeasurable
  have e1 : (fun ω => (U T ω / U ⊥ ω) / (A T ω / A ⊥ ω) * (V T ω / U T ω))
      = (fun ω => 1 / (U ⊥ ω / A ⊥ ω)) * fun ω => V T ω / A T ω := by
    funext ω
    have := hU_pos T ω; have := hU_pos ⊥ ω; have := hA_pos T ω; have := hA_pos ⊥ ω
    simp only [Pi.mul_apply]
    field_simp
  have e2 : (fun ω => (U T ω / U ⊥ ω) / (A T ω / A ⊥ ω))
      = (fun ω => 1 / (U ⊥ ω / A ⊥ ω)) * fun ω => U T ω / A T ω := by
    funext ω
    have := hU_pos T ω; have := hU_pos ⊥ ω; have := hA_pos T ω; have := hA_pos ⊥ ω
    simp only [Pi.mul_apply]
    field_simp
  have hN : Q[fun ω => (U T ω / U ⊥ ω) / (A T ω / A ⊥ ω) * (V T ω / U T ω) | ℱ t]
      =ᵐ[Q] (fun ω => 1 / (U ⊥ ω / A ⊥ ω)) * fun ω => V t ω / A t ω := by
    have hi : Integrable ((fun ω => 1 / (U ⊥ ω / A ⊥ ω)) * fun ω => V T ω / A T ω) Q := by
      rw [← e1]; exact hZX
    rw [e1]
    exact (condExp_mul_of_stronglyMeasurable_left hc hi (hV.integrable T)).trans
      (Filter.EventuallyEq.rfl.mul (hV.condExp_ae_eq ht))
  have hD : Q[fun ω => (U T ω / U ⊥ ω) / (A T ω / A ⊥ ω) | ℱ t]
      =ᵐ[Q] (fun ω => 1 / (U ⊥ ω / A ⊥ ω)) * fun ω => U t ω / A t ω := by
    have hi : Integrable ((fun ω => 1 / (U ⊥ ω / A ⊥ ω)) * fun ω => U T ω / A T ω) Q := by
      rw [← e2]; exact hZ_int
    rw [e2]
    exact (condExp_mul_of_stronglyMeasurable_left hc hi (hU.integrable T)).trans
      (Filter.EventuallyEq.rfl.mul (hU.condExp_ae_eq ht))
  refine Filter.Eventually.filter_mono (withDensity_absolutelyContinuous Q _).ae_le ?_
  filter_upwards [hN, hD] with ω h1 h2
  rw [h1, h2]
  have := hU_pos t ω; have := hU_pos ⊥ ω; have := hA_pos t ω; have := hA_pos ⊥ ω
  simp only [Pi.mul_apply]
  field_simp

/-- The reweighting is a genuine density. Under the same conditions on the units (`A` and `U`
strictly positive, `U / A` a `Q`-martingale), the density `Z_T = (U_T / U_0) / (A_T / A_0)` has
average 1 under `Q`, so the new measure `Q^U` it defines is a probability measure. -/
theorem numeraire_density_is_probability {Ω ι : Type*} {m0 : MeasurableSpace Ω}
    [Preorder ι] [OrderBot ι]
    (Q : Measure Ω) [IsProbabilityMeasure Q] (ℱ : Filtration ι m0)
    (A U : ι → Ω → ℝ) (T : ι)
    (hA_pos : ∀ t ω, 0 < A t ω) (hU_pos : ∀ t ω, 0 < U t ω)
    (hU : Martingale (fun t ω => U t ω / A t ω) ℱ Q) :
    IsProbabilityMeasure
      (Q.withDensity (fun ω => ENNReal.ofReal ((U T ω / U ⊥ ω) / (A T ω / A ⊥ ω)))) := by
  constructor
  rw [withDensity_apply _ MeasurableSet.univ, Measure.restrict_univ]
  exact numeraire_density_lintegral Q ℱ A U T hA_pos hU_pos hU

/-- Bayes' rule for conditional averages under a change of measure. Let `Z > 0` with
`E^Q[Z] = 1`, let `Q'` be `Q` reweighted by `Z`, and let `X` have `E^Q[Z |X|]` finite (that is,
`E^{Q'}|X|` finite). Then for any information `m` known at some time, the `Q'`-average of `X`
given `m` is `E^Q[Z X | m] / E^Q[Z | m]`. -/
theorem bayes_rule_change_of_measure {Ω : Type*} {m m0 : MeasurableSpace Ω} (hm : m ≤ m0)
    (Q : Measure Ω) [IsProbabilityMeasure Q] (Z X : Ω → ℝ)
    (hZ_pos : ∀ ω, 0 < Z ω) (hZ_int : Integrable Z Q) (hZ_one : ∫ ω, Z ω ∂Q = 1)
    (hZX : Integrable (fun ω => Z ω * X ω) Q) :
    (Q.withDensity (fun ω => ENNReal.ofReal (Z ω)))[X | m]
      =ᵐ[Q.withDensity (fun ω => ENNReal.ofReal (Z ω))]
        fun ω => Q[fun ω => Z ω * X ω | m] ω / Q[Z | m] ω := by
  exact numeraire_bayes hm Q Z X hZ_pos hZ_int hZX

-- The house example: S0 = K = 100, r = 5/100, sigma = 20/100, T = 1, real-world drift 8/100.
-- Log drift under the share measure: r + sigma^2/2 = 7/100.
example : ((5 : ℚ) / 100 + (1 / 2) * (20 / 100) ^ 2) = 7 / 100 := by norm_num
-- d1 = (0 + 7/100) / (20/100) = 35/100, and d2 = d1 - sigma = 15/100.
example : (((5 : ℚ) / 100 + (1 / 2) * (20 / 100) ^ 2) / (20 / 100)) = 35 / 100 := by norm_num
example : ((35 : ℚ) / 100 - 20 / 100) = 15 / 100 := by norm_num
-- Real-world distance dP = (mu - sigma^2/2) / sigma = 30/100.
example : (((8 : ℚ) / 100 - (1 / 2) * (20 / 100) ^ 2) / (20 / 100)) = 30 / 100 := by norm_num
-- The share's drift under the share measure is r + sigma^2 = 9/100.
example : ((5 : ℚ) / 100 + (20 / 100) ^ 2) = 9 / 100 := by norm_num
-- Market price of risk lambda = (mu - r) / sigma = 15/100.
example : (((8 : ℚ) / 100 - 5 / 100) / (20 / 100)) = 15 / 100 := by norm_num
-- Log drifts: under Q, r - sigma^2/2 = 3/100; under P, mu - sigma^2/2 = 6/100.
example : ((5 : ℚ) / 100 - (1 / 2) * (20 / 100) ^ 2) = 3 / 100 := by norm_num
example : ((8 : ℚ) / 100 - (1 / 2) * (20 / 100) ^ 2) = 6 / 100 := by norm_num
-- With sigma = 40/100: d1 = (5/100 + 8/100) / (40/100) = 325/1000 and d2 = -75/1000.
example : (((5 : ℚ) / 100 + (1 / 2) * (40 / 100) ^ 2) / (40 / 100)) = 325 / 1000 := by norm_num
example : ((325 : ℚ) / 1000 - 40 / 100) = -75 / 1000 := by norm_num

#print axioms change_of_numeraire_price_is_fair_game
#print axioms numeraire_density_is_probability
#print axioms bayes_rule_change_of_measure
