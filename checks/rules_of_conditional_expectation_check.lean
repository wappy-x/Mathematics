-- The rules of conditional expectation: on any probability space, conditional expectation given a sub-sigma-algebra is linear, keeps order, obeys the tower rule, lets a known factor out, turns an independent quantity into its mean, satisfies conditional Jensen, and passes monotone and dominated limits inside, all almost surely.
import Mathlib.Probability.ConditionalExpectation
import Mathlib.MeasureTheory.Function.ConditionalExpectation.CondJensen
import Mathlib.MeasureTheory.Function.ConditionalExpectation.PullOut
import Mathlib.MeasureTheory.Integral.DominatedConvergence

open MeasureTheory ProbabilityTheory Filter Topology

variable {Ω : Type*} {m₀ : MeasurableSpace Ω} {μ : Measure Ω} [IsProbabilityMeasure μ]

omit [IsProbabilityMeasure μ] in
/-- A sequence of integrable functions that is almost surely nonnegative and decreasing, with
integrals tending to zero, tends to zero almost surely. -/
lemma ae_tendsto_zero_of_antitone_of_integral (V : ℕ → Ω → ℝ) (hint : ∀ n, Integrable (V n) μ)
    (hV : ∀ᵐ ω ∂μ, Antitone (fun n => V n ω) ∧ ∀ n, 0 ≤ V n ω)
    (hlim : Tendsto (fun n => ∫ ω, V n ω ∂μ) atTop (𝓝 0)) :
    ∀ᵐ ω ∂μ, Tendsto (fun n => V n ω) atTop (𝓝 0) := by
  set L : Ω → ℝ := fun ω => ⨅ n, V n ω with hLdef
  have hLm : AEStronglyMeasurable[m₀] L μ :=
    (AEMeasurable.iInf (fun n => (hint n).1.aemeasurable)).aestronglyMeasurable
  have hgood : ∀ᵐ ω ∂μ, 0 ≤ L ω ∧ (∀ n, L ω ≤ V n ω) ∧
      Tendsto (fun n => V n ω) atTop (𝓝 (L ω)) := by
    filter_upwards [hV] with ω ⟨hanti, hnn⟩
    have hbdd : BddBelow (Set.range fun n => V n ω) := ⟨0, by rintro _ ⟨n, rfl⟩; exact hnn n⟩
    exact ⟨le_ciInf hnn, fun n => ciInf_le hbdd n, tendsto_atTop_ciInf hanti hbdd⟩
  have hLint : Integrable L μ := by
    refine Integrable.mono' (hint 0) hLm ?_
    filter_upwards [hgood] with ω ⟨h0, hle, _⟩
    rw [Real.norm_eq_abs, abs_of_nonneg h0]
    exact hle 0
  have hle : ∀ n, ∫ ω, L ω ∂μ ≤ ∫ ω, V n ω ∂μ := fun n =>
    integral_mono_ae hLint (hint n) (by filter_upwards [hgood] with ω h using h.2.1 n)
  have hL0 : ∫ ω, L ω ∂μ ≤ 0 := ge_of_tendsto' hlim hle
  have hLnn : 0 ≤ᵐ[μ] L := by filter_upwards [hgood] with ω h using h.1
  have hLz : L =ᵐ[μ] 0 :=
    (integral_eq_zero_iff_of_nonneg_ae hLnn hLint).1 (le_antisymm hL0 (integral_nonneg_of_ae hLnn))
  filter_upwards [hgood, hLz] with ω h hz
  simpa [hz] using h.2.2

/-- Conditional dominated convergence, as a standalone lemma. -/
lemma condExp_ae_tendsto_of_dominated (𝓖 : MeasurableSpace Ω) (h𝓖 : 𝓖 ≤ m₀)
    (Xs : ℕ → Ω → ℝ) (X W : Ω → ℝ) (hXs : ∀ n, AEStronglyMeasurable[m₀] (Xs n) μ)
    (hlim : ∀ᵐ ω ∂μ, Tendsto (fun n => Xs n ω) atTop (𝓝 (X ω)))
    (hbound : ∀ n, ∀ᵐ ω ∂μ, |Xs n ω| ≤ W ω) (hW : Integrable W μ) :
    ∀ᵐ ω ∂μ, Tendsto (fun n => μ[Xs n | 𝓖] ω) atTop (𝓝 (μ[X | 𝓖] ω)) := by
  have hXm : AEStronglyMeasurable[m₀] X μ := aestronglyMeasurable_of_tendsto_ae atTop hXs hlim
  have hgood : ∀ᵐ ω ∂μ, (∀ n, |Xs n ω| ≤ W ω) ∧ Tendsto (fun n => Xs n ω) atTop (𝓝 (X ω)) :=
    (ae_all_iff.2 hbound).and hlim
  have hXW : ∀ᵐ ω ∂μ, |X ω| ≤ W ω := by
    filter_upwards [hgood] with ω ⟨hb, ht⟩
    exact le_of_tendsto' ht.abs hb
  have hXsint : ∀ n, Integrable (Xs n) μ := fun n =>
    hW.mono' (hXs n) (by simpa [Real.norm_eq_abs] using hbound n)
  have hXint : Integrable X μ := hW.mono' hXm (by simpa [Real.norm_eq_abs] using hXW)
  set Z : ℕ → Ω → ℝ := fun n ω => ⨆ k, |Xs (n + k) ω - X ω| with hZdef
  have hZm : ∀ n, AEStronglyMeasurable[m₀] (Z n) μ := fun n =>
    (AEMeasurable.iSup (fun k => (continuous_abs.comp_aestronglyMeasurable ((hXs (n + k)).sub hXm)).aemeasurable)).aestronglyMeasurable
  -- pointwise facts on the good set
  have hZgood : ∀ᵐ ω ∂μ, (∀ n, |Xs n ω - X ω| ≤ Z n ω) ∧ (∀ n, 0 ≤ Z n ω) ∧
      (∀ n, Z n ω ≤ 2 * W ω) ∧ (∀ n, Z (n + 1) ω ≤ Z n ω) ∧
      Tendsto (fun n => Z n ω) atTop (𝓝 0) := by
    filter_upwards [hgood, hXW] with ω ⟨hb, ht⟩ hxw
    have hk : ∀ n k, |Xs (n + k) ω - X ω| ≤ 2 * W ω := fun n k => by
      calc |Xs (n + k) ω - X ω| ≤ |Xs (n + k) ω| + |X ω| := abs_sub _ _
        _ ≤ 2 * W ω := by linarith [hb (n + k)]
    have hbdd : ∀ n, BddAbove (Set.range fun k => |Xs (n + k) ω - X ω|) := fun n =>
      ⟨2 * W ω, by rintro _ ⟨k, rfl⟩; exact hk n k⟩
    refine ⟨fun n => le_ciSup (hbdd n) 0, fun n => (abs_nonneg _).trans (le_ciSup (hbdd n) 0),
      fun n => ciSup_le (hk n), fun n => ciSup_le fun k => ?_, ?_⟩
    · have := le_ciSup (hbdd n) (k + 1)
      simpa [Nat.add_assoc, Nat.add_comm 1 k] using this
    · rw [Metric.tendsto_atTop]
      intro ε hε
      obtain ⟨N, hN⟩ := Metric.tendsto_atTop.1 ht (ε / 2) (by linarith)
      refine ⟨N, fun n hn => ?_⟩
      have hle : Z n ω ≤ ε / 2 := ciSup_le fun k => by
        have := hN (n + k) (by omega)
        rw [Real.dist_eq] at this
        exact this.le
      have hnn : 0 ≤ Z n ω := (abs_nonneg _).trans (le_ciSup (hbdd n) 0)
      rw [Real.dist_eq, sub_zero, abs_of_nonneg hnn]
      linarith
  have hZint : ∀ n, Integrable (Z n) μ := fun n => by
    refine (hW.const_mul 2).mono' (hZm n) ?_
    filter_upwards [hZgood] with ω h
    rw [Real.norm_eq_abs, abs_of_nonneg (h.2.1 n)]
    exact h.2.2.1 n
  have hZlim : Tendsto (fun n => ∫ ω, Z n ω ∂μ) atTop (𝓝 0) := by
    have := tendsto_integral_of_dominated_convergence (fun ω => 2 * W ω) hZm (hW.const_mul 2)
      (fun n => by
        filter_upwards [hZgood] with ω h
        rw [Real.norm_eq_abs, abs_of_nonneg (h.2.1 n)]
        exact h.2.2.1 n)
      (by filter_upwards [hZgood] with ω h using h.2.2.2.2)
    simpa using this
  set V : ℕ → Ω → ℝ := fun n => μ[Z n | 𝓖] with hVdef
  have hVmono : ∀ᵐ ω ∂μ, ∀ n, V (n + 1) ω ≤ V n ω := by
    refine ae_all_iff.2 fun n => condExp_mono (hZint (n + 1)) (hZint n) ?_
    filter_upwards [hZgood] with ω h using h.2.2.2.1 n
  have hVnn : ∀ᵐ ω ∂μ, ∀ n, 0 ≤ V n ω := by
    refine ae_all_iff.2 fun n => condExp_nonneg ?_
    filter_upwards [hZgood] with ω h using h.2.1 n
  have hV0 : ∀ᵐ ω ∂μ, Tendsto (fun n => V n ω) atTop (𝓝 0) := by
    refine ae_tendsto_zero_of_antitone_of_integral V (fun n => integrable_condExp) ?_ ?_
    · filter_upwards [hVmono, hVnn] with ω h1 h2
      exact ⟨antitone_nat_of_succ_le h1, h2⟩
    · simpa [hVdef, integral_condExp h𝓖] using hZlim
  have hdiff : ∀ᵐ ω ∂μ, ∀ n, |μ[Xs n | 𝓖] ω - μ[X | 𝓖] ω| ≤ V n ω := by
    refine ae_all_iff.2 fun n => ?_
    have h1 := condExp_sub (hXsint n) hXint 𝓖 (μ := μ)
    have h2 := norm_condExp_le (μ := μ) (m := 𝓖) (Xs n - X)
    have h3 : μ[fun ω => ‖(Xs n - X) ω‖ | 𝓖] ≤ᵐ[μ] μ[Z n | 𝓖] := by
      refine condExp_mono ((hXsint n).sub hXint).norm (hZint n) ?_
      filter_upwards [hZgood] with ω h
      simpa [Real.norm_eq_abs] using h.1 n
    filter_upwards [h1, h2, h3] with ω e1 e2 e3
    have : ‖μ[Xs n - X | 𝓖] ω‖ ≤ V n ω := e2.trans e3
    rwa [e1, Real.norm_eq_abs] at this
  filter_upwards [hdiff, hV0] with ω hd hv
  rw [tendsto_iff_norm_sub_tendsto_zero]
  simp only [Real.norm_eq_abs]
  exact squeeze_zero (fun n => abs_nonneg _) hd hv

#print axioms ae_tendsto_zero_of_antitone_of_integral
#print axioms condExp_ae_tendsto_of_dominated

/-- The rules. Let `𝓗 ⊆ 𝓖` be sub-sigma-algebras of the probability space. Then, almost surely:
linearity, `E[aX + bY | 𝓖] = a E[X | 𝓖] + b E[Y | 𝓖]` for integrable `X`, `Y`;
order, `X ≤ Y` implies `E[X | 𝓖] ≤ E[Y | 𝓖]`;
the tower, `E[E[X | 𝓖] | 𝓗] = E[X | 𝓗] = E[E[X | 𝓗] | 𝓖]`;
taking out what is known, `E[Z X | 𝓖] = Z E[X | 𝓖]` when `Z` is `𝓖`-measurable and `Z X` is
integrable; and dropping what is independent, `E[X | 𝓖] = E[X]` when `X` is independent of `𝓖`. -/
theorem rules_of_conditional_expectation (𝓖 𝓗 : MeasurableSpace Ω) (h𝓖 : 𝓖 ≤ m₀) (h𝓗𝓖 : 𝓗 ≤ 𝓖) :
    -- linearity
    (∀ (X Y : Ω → ℝ) (a b : ℝ), Integrable X μ → Integrable Y μ →
      μ[fun ω => a * X ω + b * Y ω | 𝓖] =ᵐ[μ] fun ω => a * μ[X | 𝓖] ω + b * μ[Y | 𝓖] ω) ∧
    -- order
    (∀ X Y : Ω → ℝ, Integrable X μ → Integrable Y μ → X ≤ᵐ[μ] Y → μ[X | 𝓖] ≤ᵐ[μ] μ[Y | 𝓖]) ∧
    -- the tower, both orders
    (∀ X : Ω → ℝ, Integrable X μ →
      μ[μ[X | 𝓖] | 𝓗] =ᵐ[μ] μ[X | 𝓗] ∧ μ[μ[X | 𝓗] | 𝓖] =ᵐ[μ] μ[X | 𝓗]) ∧
    -- taking out what is known
    (∀ X Z : Ω → ℝ, Integrable X μ → Measurable[𝓖] Z → Integrable (fun ω => Z ω * X ω) μ →
      μ[fun ω => Z ω * X ω | 𝓖] =ᵐ[μ] fun ω => Z ω * μ[X | 𝓖] ω) ∧
    -- dropping what is independent
    (∀ X : Ω → ℝ, Integrable X μ → Indep (MeasurableSpace.comap X inferInstance) 𝓖 μ →
      μ[X | 𝓖] =ᵐ[μ] fun _ => ∫ ω, X ω ∂μ) := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · intro X Y a b hX hY
    have h1 := condExp_add (hX.const_mul a) (hY.const_mul b) 𝓖 (μ := μ)
    have h2 := condExp_smul a X 𝓖 (μ := μ)
    have h3 := condExp_smul b Y 𝓖 (μ := μ)
    filter_upwards [h1, h2, h3] with ω e1 e2 e3
    have e1' : μ[fun ω => a * X ω + b * Y ω | 𝓖] ω
        = μ[fun ω => a * X ω | 𝓖] ω + μ[fun ω => b * Y ω | 𝓖] ω := e1
    have e2' : μ[fun ω => a * X ω | 𝓖] ω = a * μ[X | 𝓖] ω := by
      simpa [Pi.smul_def] using e2
    have e3' : μ[fun ω => b * Y ω | 𝓖] ω = b * μ[Y | 𝓖] ω := by
      simpa [Pi.smul_def] using e3
    rw [e1', e2', e3']
  · intro X Y hX hY hXY
    exact condExp_mono hX hY hXY
  · intro X hX
    refine ⟨condExp_condExp_of_le h𝓗𝓖 h𝓖, ?_⟩
    rw [condExp_of_stronglyMeasurable h𝓖 (stronglyMeasurable_condExp.mono h𝓗𝓖) integrable_condExp]
  · intro X Z hX hZ hZX
    have hZs : StronglyMeasurable[𝓖] Z := hZ.stronglyMeasurable
    exact condExp_mul_of_stronglyMeasurable_left hZs hZX hX
  · intro X hX hind
    set X' := hX.1.mk X with hX'
    have hXX' : X =ᵐ[μ] X' := hX.1.ae_eq_mk
    have hX'm : Measurable[m₀] X' := hX.1.stronglyMeasurable_mk.measurable
    have hind' : Indep (MeasurableSpace.comap X' inferInstance) 𝓖 μ := by
      rw [Indep_iff] at hind ⊢
      rintro t1 t2 ⟨s, hs, rfl⟩ ht2
      have hpre : X ⁻¹' s =ᵐ[μ] X' ⁻¹' s := by
        filter_upwards [hXX'] with ω hω
        simp [hω]
      have := hind (X ⁻¹' s) t2 ⟨s, hs, rfl⟩ ht2
      rw [measure_congr hpre, measure_congr (hpre.inter (Filter.EventuallyEq.rfl : (t2 : Set Ω) =ᵐ[μ] t2))] at this
      exact this
    have hsm : StronglyMeasurable[MeasurableSpace.comap X' inferInstance] X' :=
      (comap_measurable X').stronglyMeasurable
    have key := condExp_indep_eq (μ := μ) hX'm.comap_le h𝓖 hsm hind'
    refine (condExp_congr_ae hXX').trans ?_
    rw [integral_congr_ae hXX']
    exact key

/-- Conditional Jensen: for a convex `φ : ℝ → ℝ` with `X` and `φ(X)` integrable,
`φ(E[X | 𝓖]) ≤ E[φ(X) | 𝓖]` almost surely. -/
theorem conditional_jensen (𝓖 : MeasurableSpace Ω) (h𝓖 : 𝓖 ≤ m₀) (φ : ℝ → ℝ)
    (hφ : ConvexOn ℝ Set.univ φ) (X : Ω → ℝ) (hX : Integrable X μ)
    (hφX : Integrable (fun ω => φ (X ω)) μ) :
    (fun ω => φ (μ[X | 𝓖] ω)) ≤ᵐ[μ] μ[fun ω => φ (X ω) | 𝓖] := by
  have hc : Continuous φ := continuousOn_univ.mp (hφ.continuousOn isOpen_univ)
  exact hφ.map_condExp_le_univ h𝓖 hc.lowerSemicontinuous hX hφX

/-- The limit theorems conditioned. Monotone convergence: if `0 ≤ Xₙ` rise to an integrable `X`
almost surely, then `E[Xₙ | 𝓖]` rise to `E[X | 𝓖]` almost surely. Dominated convergence: if
`Xₙ → X` almost surely and `|Xₙ| ≤ W` with `W` integrable, then `E[Xₙ | 𝓖] → E[X | 𝓖]`
almost surely. -/
theorem conditional_limit_theorems (𝓖 : MeasurableSpace Ω) (h𝓖 : 𝓖 ≤ m₀) :
    -- conditional monotone convergence; every `Xₙ` is a random variable on the full space `m₀`
    (∀ (Xs : ℕ → Ω → ℝ) (X : Ω → ℝ), (∀ n, AEStronglyMeasurable[m₀] (Xs n) μ) →
      Integrable[m₀] X μ →
      (∀ᵐ ω ∂μ, (∀ n, 0 ≤ Xs n ω) ∧ Monotone (fun n => Xs n ω) ∧
        Tendsto (fun n => Xs n ω) atTop (𝓝 (X ω))) →
      ∀ᵐ ω ∂μ, Monotone (fun n => μ[Xs n | 𝓖] ω) ∧
        Tendsto (fun n => μ[Xs n | 𝓖] ω) atTop (𝓝 (μ[X | 𝓖] ω))) ∧
    -- conditional dominated convergence; every `Xₙ` is a random variable on the full space `m₀`
    (∀ (Xs : ℕ → Ω → ℝ) (X W : Ω → ℝ), (∀ n, AEStronglyMeasurable[m₀] (Xs n) μ) →
      (∀ᵐ ω ∂μ, Tendsto (fun n => Xs n ω) atTop (𝓝 (X ω))) →
      (∀ n, ∀ᵐ ω ∂μ, |Xs n ω| ≤ W ω) → Integrable[m₀] W μ →
      ∀ᵐ ω ∂μ, Tendsto (fun n => μ[Xs n | 𝓖] ω) atTop (𝓝 (μ[X | 𝓖] ω))) := by
  refine ⟨?_, ?_⟩
  · intro Xs X hXs hX hmono
    have hXs' : ∀ n, AEStronglyMeasurable[m₀] (Xs n) μ := hXs
    have hbound : ∀ n, ∀ᵐ ω ∂μ, |Xs n ω| ≤ X ω := fun n => by
      filter_upwards [hmono] with ω ⟨hnn, hm, ht⟩
      rw [abs_of_nonneg (hnn n)]
      exact hm.ge_of_tendsto ht n
    have hXsint : ∀ n, Integrable (Xs n) μ := fun n =>
      hX.mono' (hXs' n) (by simpa [Real.norm_eq_abs] using hbound n)
    have hlim : ∀ᵐ ω ∂μ, Tendsto (fun n => Xs n ω) atTop (𝓝 (X ω)) := by
      filter_upwards [hmono] with ω h using h.2.2
    have hcm : ∀ᵐ ω ∂μ, ∀ n, μ[Xs n | 𝓖] ω ≤ μ[Xs (n + 1) | 𝓖] ω := by
      refine ae_all_iff.2 fun n => condExp_mono (hXsint n) (hXsint (n + 1)) ?_
      filter_upwards [hmono] with ω h using h.2.1 (Nat.le_succ n)
    filter_upwards [hcm, condExp_ae_tendsto_of_dominated 𝓖 h𝓖 Xs X X hXs' hlim hbound hX]
      with ω h1 h2
    exact ⟨monotone_nat_of_le_succ h1, h2⟩
  · intro Xs X W hXs hlim hbound hW
    exact condExp_ae_tendsto_of_dominated 𝓖 h𝓖 Xs X W hXs hlim hbound hW

/-! The card's worked numbers on the rain gauge, exactly. -/

-- winter rainfall: 3/5 and 7/5 of the month means 25, 30, 35
example : ((3 : ℚ) / 5 * 25, (7 : ℚ) / 5 * 25, (3 : ℚ) / 5 * 30, (7 : ℚ) / 5 * 30,
    (3 : ℚ) / 5 * 35, (7 : ℚ) / 5 * 35) = (15, 35, 18, 42, 21, 49) := by norm_num
-- month forecasts, then the tower: averaging them gives the direct season forecast 30
example : ((15 + 35 : ℚ) / 2, (18 + 42 : ℚ) / 2, (21 + 49 : ℚ) / 2) = (25, 30, 35) := by norm_num
example : (25 + 30 + 35 : ℚ) / 3 = 30 := by norm_num
example : (15 + 35 + 18 + 42 + 21 + 49 : ℚ) / 6 = 30 := by norm_num
-- the year: the season forecasts average to the plain mean 55
example : (30 + 60 + 90 + 40 : ℚ) / 4 = 55 := by norm_num
-- taking out what is known: umbrella sales 4 × 30 = 120, and so on; yearly mean 117.5
example : ((4 : ℚ) * 30, (3 : ℚ) * 60, (1 : ℚ) * 90, (2 : ℚ) * 40) = (120, 180, 90, 80) := by norm_num
example : (120 + 180 + 90 + 80 : ℚ) / 4 = 235 / 2 := by norm_num
-- multiplying plain means instead gives 137.5
example : (4 + 3 + 1 + 2 : ℚ) / 4 * 55 = 275 / 2 := by norm_num
-- dropping what is independent: the gauge error averages −1; the reading forecasts
example : (-3 + 1 : ℚ) / 2 = -1 := by norm_num
example : ((30 : ℚ) - 1, (60 : ℚ) - 1, (90 : ℚ) - 1, (40 : ℚ) - 1) = (29, 59, 89, 39) := by norm_num
-- conditional Jensen: spring flood payout (X − 50)⁺ forecasts 17, against 10 at the forecast
example : (0 + 20 + 0 + 34 + 0 + 48 : ℚ) / 6 = 17 ∧ max ((60 : ℚ) - 50) 0 = 10 := by norm_num
-- what breaks: two-month blocks give winter 65/2, not 30
example : ((25 + 30 : ℚ) / 2 + (25 + 30) / 2 + (35 + 50) / 2) / 3 = 65 / 2 := by norm_num
-- what breaks: V = 1 dry, 3 wet does not come out; winter forecast 72, not 2 × 30 = 60
example : (1 * 15 + 3 * 35 + 1 * 18 + 3 * 42 + 1 * 21 + 3 * 49 : ℚ) / 6 = 72 := by norm_num
-- what breaks: a summer evaporation loss of 4 mm; summer −5, the year −2
example : (-3 + 1 : ℚ) / 2 - 4 = -5 ∧ (-1 + -1 + -5 + -1 : ℚ) / 4 = -2 := by norm_num
-- what breaks: a burst of height n on [0, 1/n) has early-half forecast n · (1/n) / (1/2) = 2
example : ∀ n : ℕ, 2 ≤ n → (n : ℚ) * (1 / n) / (1 / 2) = 2 := by
  intro n hn
  have : (n : ℚ) ≠ 0 := by positivity
  field_simp

#print axioms rules_of_conditional_expectation
#print axioms conditional_jensen
#print axioms conditional_limit_theorems
