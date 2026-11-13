-- Conditioning on a random variable: E[X | Y] equals g(Y) for a Borel function g that matches X's average over every event "Y in B", with a joint density g is the average of x under f(x, y)/f_Y(y), and under Q with density Z against P the abstract Bayes formula E_Q[X | G] = E_P[Z X | G] / E_P[Z | G] holds Q-almost surely.
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Basic
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Constructions.BorelSpace.Real
import Mathlib.MeasureTheory.Function.FactorsThrough
import Mathlib.MeasureTheory.Function.ConditionalExpectation.PullOut
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Tactic.NormNum

open MeasureTheory

/-- **E[X | Y] is a function of Y** (Step 1, Doob–Dynkin). On a probability space, for an
integrable real `X` and a real random variable `Y`, the conditional expectation of `X` given
`σ(Y)` (the events "Y in B") equals `g(Y)` almost surely for some Borel function `g`, and `g` is
pinned down by matching averages: `E[X 1{Y ∈ B}] = E[g(Y) 1{Y ∈ B}]` for every Borel set `B`. -/
theorem condexp_given_random_variable_is_function_of_it
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X Y : Ω → ℝ) (hX : Integrable X P) (hY : Measurable Y) :
    ∃ g : ℝ → ℝ, Measurable g ∧
      condExp (MeasurableSpace.comap Y inferInstance) P X =ᵐ[P] (fun ω => g (Y ω)) ∧
      ∀ B : Set ℝ, MeasurableSet B →
        ∫ ω in Y ⁻¹' B, X ω ∂P = ∫ ω in Y ⁻¹' B, g (Y ω) ∂P := by
  obtain ⟨g, hg, hgeq⟩ :=
    (stronglyMeasurable_condExp (m := MeasurableSpace.comap Y inferInstance) (μ := P)
      (f := X)).exists_eq_measurable_comp
  refine ⟨g, hg.measurable, ?_, ?_⟩
  · rw [hgeq]; rfl
  · intro B hB
    have hs : MeasurableSet[MeasurableSpace.comap Y inferInstance] (Y ⁻¹' B) := ⟨B, hB, rfl⟩
    rw [← setIntegral_condExp hY.comap_le hX hs, hgeq]
    rfl

/-- **The conditional density gives E[X | Y]** (Step 2). If the pair `(X, Y)` has a joint
density `f ≥ 0` on the plane and `X` is integrable, then with `f_Y(y) = ∫ f(x, y) dx` and the
conditional density `f(x | y) = f(x, y) / f_Y(y)`, the rule `g(y) = ∫ x f(x | y) dx` gives
`E[X | Y] = g(Y)` almost surely. (Where `f_Y(y) = 0` Lean's division gives `0`; that set of
temperatures has probability zero.) -/
theorem condexp_from_joint_density
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X Y : Ω → ℝ) (hXm : Measurable X) (hYm : Measurable Y) (hX : Integrable X P)
    (f : ℝ × ℝ → ℝ) (hf : Measurable f) (hf0 : ∀ p, 0 ≤ f p)
    (hjoint : P.map (fun ω => (X ω, Y ω)) =
      (volume : Measure (ℝ × ℝ)).withDensity (fun p => ENNReal.ofReal (f p))) :
    condExp (MeasurableSpace.comap Y inferInstance) P X =ᵐ[P]
      fun ω => ∫ x, x * (f (x, Y ω) / ∫ x', f (x', Y ω)) := by
  obtain ⟨F, hF⟩ : ∃ F : ℝ → ℝ, F = fun y => ∫ x', f (x', y) := ⟨_, rfl⟩
  obtain ⟨h, hh⟩ : ∃ h : ℝ → ℝ, h = fun y => ∫ x, x * (f (x, y) / F y) := ⟨_, rfl⟩
  have hgoal : (fun ω => ∫ x, x * (f (x, Y ω) / ∫ x', f (x', Y ω))) = fun ω => h (Y ω) := by
    rw [hh, hF]
  rw [hgoal]
  have hXY : Measurable (fun ω => (X ω, Y ω)) := hXm.prodMk hYm
  have hfnn : Measurable (fun p => (f p).toNNReal) := hf.real_toNNReal
  have hμ : P.map (fun ω => (X ω, Y ω)) =
      (volume : Measure (ℝ × ℝ)).withDensity (fun p => ((f p).toNNReal : ENNReal)) := hjoint
  have hsmul : ∀ g : ℝ × ℝ → ℝ, (fun p => (f p).toNNReal • g p) = fun p => f p * g p := by
    intro g; ext p
    rw [NNReal.smul_def, smul_eq_mul, Real.coe_toNNReal _ (hf0 p)]
  -- integrability transfer
  have hint_iff : ∀ φ : ℝ × ℝ → ℝ, Measurable φ →
      (Integrable (fun ω => φ (X ω, Y ω)) P ↔ Integrable (fun p => f p * φ p) volume) := by
    intro φ hφ
    have e1 := integrable_map_measure (μ := P) (g := φ) hφ.aestronglyMeasurable hXY.aemeasurable
    rw [hμ, integrable_withDensity_iff_integrable_smul hfnn, hsmul] at e1
    exact e1.symm
  have hFm : Measurable F := by
    rw [hF]; exact (hf.stronglyMeasurable.integral_prod_left' (μ := volume)).measurable
  have hhm : Measurable h := by
    rw [hh]
    have : Measurable (fun p : ℝ × ℝ => p.1 * (f p / F p.2)) :=
      measurable_fst.mul (hf.div (hFm.comp measurable_snd))
    exact (this.stronglyMeasurable.integral_prod_left' (μ := volume)).measurable
  have hfint : Integrable f (volume.prod volume) := by
    have := (hint_iff (fun _ => 1) measurable_const).mp (integrable_const _)
    simp only [mul_one] at this
    exact this
  have hxint : Integrable (fun p : ℝ × ℝ => f p * p.1) (volume.prod volume) :=
    (hint_iff Prod.fst measurable_fst).mp hX
  have hae1 : ∀ᵐ y ∂(volume : Measure ℝ), Integrable (fun x => f (x, y)) volume :=
    hfint.prod_left_ae
  have hkey : ∀ᵐ y ∂(volume : Measure ℝ), F y * h y = ∫ x, f (x, y) * x := by
    filter_upwards [hae1] with y hy
    have hI : h y = (∫ x, f (x, y) * x) / F y := by
      rw [← integral_div, hh]
      dsimp only
      congr 1; funext x; ring
    by_cases hF0 : F y = 0
    · have hFy : ∫ x', f (x', y) = 0 := by rw [← hF0, hF]
      have hz : (fun x => f (x, y)) =ᵐ[volume] 0 :=
        (integral_eq_zero_iff_of_nonneg (fun x => hf0 _) hy).mp hFy
      rw [hF0, zero_mul]
      symm
      apply integral_eq_zero_of_ae
      filter_upwards [hz] with x hx
      simp only [Pi.zero_apply] at hx ⊢
      rw [hx, zero_mul]
    · rw [hI]; field_simp
  have hFnn : ∀ y, 0 ≤ F y := fun y => by rw [hF]; exact integral_nonneg fun x => hf0 _
  have hfh : Integrable (fun p : ℝ × ℝ => f p * h p.2) (volume.prod volume) := by
    have hm : Measurable (fun p : ℝ × ℝ => f p * h p.2) := hf.mul (hhm.comp measurable_snd)
    rw [integrable_prod_iff' hm.aestronglyMeasurable]
    refine ⟨?_, ?_⟩
    · filter_upwards [hae1] with y hy
      exact hy.mul_const _
    · refine hxint.integral_norm_prod_right.mono'
        (hm.norm.stronglyMeasurable.integral_prod_left' (μ := volume)).aestronglyMeasurable ?_
      filter_upwards [hkey] with y hy
      have e : ∫ x, ‖f (x, y) * h y‖ = F y * |h y| := by
        have : (fun x => ‖f (x, y) * h y‖) = fun x => f (x, y) * |h y| := by
          ext x; rw [norm_mul, Real.norm_of_nonneg (hf0 _), Real.norm_eq_abs]
        rw [this, integral_mul_const, hF]
      rw [e, Real.norm_of_nonneg (mul_nonneg (hFnn y) (abs_nonneg _))]
      calc F y * |h y| = |F y * h y| := by rw [abs_mul, abs_of_nonneg (hFnn y)]
        _ = ‖∫ x, f (x, y) * x‖ := by rw [hy, Real.norm_eq_abs]
        _ ≤ ∫ x, ‖f (x, y) * x‖ := norm_integral_le_integral_norm _
  have hhY : Integrable (fun ω => h (Y ω)) P :=
    (hint_iff (fun p => h p.2) (hhm.comp measurable_snd)).mpr hfh
  -- set integral transfer
  have htrans : ∀ φ : ℝ × ℝ → ℝ, Measurable φ → ∀ B : Set ℝ, MeasurableSet B →
      ∫ ω in Y ⁻¹' B, φ (X ω, Y ω) ∂P =
        ∫ p, f p * φ p ∂((volume : Measure ℝ).prod (volume.restrict B)) := by
    intro φ hφ B hB
    have hS : MeasurableSet (Prod.snd ⁻¹' B : Set (ℝ × ℝ)) := hB.preimage measurable_snd
    have e1 := setIntegral_map (μ := P) (g := fun ω => (X ω, Y ω)) (f := φ) hS
      hφ.aestronglyMeasurable hXY.aemeasurable
    refine e1.symm.trans ?_
    rw [hμ, setIntegral_withDensity_eq_setIntegral_smul hfnn _ hS, hsmul,
      Measure.volume_eq_prod, ← Set.univ_prod, ← Measure.prod_restrict, Measure.restrict_univ]
  have hres : ∀ B : Set ℝ, (volume : Measure ℝ).prod (volume.restrict B) =
      ((volume : Measure ℝ).prod volume).restrict (Set.univ ×ˢ B) := by
    intro B; rw [← Measure.prod_restrict, Measure.restrict_univ]
  symm
  refine ae_eq_condExp_of_forall_setIntegral_eq hYm.comap_le hX
    (fun s _ _ => hhY.integrableOn) (fun s hs _ => ?_)
    ((hhm.stronglyMeasurable.comp_measurable (comap_measurable Y)).aestronglyMeasurable)
  obtain ⟨B, hB, rfl⟩ := hs
  have e1 := htrans (fun p => h p.2) (hhm.comp measurable_snd) B hB
  have e2 := htrans Prod.fst measurable_fst B hB
  refine e1.trans (Eq.trans ?_ e2.symm)
  rw [integral_prod_symm _ (by rw [hres]; exact hfh.restrict),
    integral_prod_symm _ (by rw [hres]; exact hxint.restrict)]
  refine integral_congr_ae ?_
  filter_upwards [ae_restrict_of_ae hkey] with y hy
  rw [integral_mul_const, ← hy, hF]

/-- **Abstract Bayes formula** (Step 4). Let `P` and `Q` be probabilities on the full space
`(Ω, mΩ)`, with `Q` having density `Z ≥ 0` against `P`, so `Q(A) = E_P[Z 1_A]`. For any
sub-sigma-algebra `G ≤ mΩ` and any `X` with finite `E_Q|X|`,
`E_Q[X | G] = E_P[Z X | G] / E_P[Z | G]`, `Q`-almost surely. (Where `E_P[Z | G] = 0` Lean's
division gives `0`, as in the card's proof; `Q` puts no weight there.) -/
theorem abstract_bayes_formula
    {Ω : Type*} {G mΩ : MeasurableSpace Ω} (hG : G ≤ mΩ)
    (P Q : @Measure Ω mΩ) [IsProbabilityMeasure P] [IsProbabilityMeasure Q]
    (Z : Ω → ℝ) (hZ : Measurable[mΩ] Z) (hZ0 : ∀ ω, 0 ≤ Z ω)
    (hQ : Q = P.withDensity (fun ω => ENNReal.ofReal (Z ω)))
    (X : Ω → ℝ) (hX : Integrable X Q) :
    Q[X | G] =ᵐ[Q] fun ω => P[fun ω => Z ω * X ω | G] ω / P[Z | G] ω := by
  have hZnn : Measurable[mΩ] (fun ω => (Z ω).toNNReal) := hZ.real_toNNReal
  have hQ' : Q = P.withDensity (fun ω => ((Z ω).toNNReal : ENNReal)) := hQ
  have hsmul : ∀ g : Ω → ℝ, (fun ω => (Z ω).toNNReal • g ω) = fun ω => Z ω * g ω := by
    intro g; ext ω
    rw [NNReal.smul_def, smul_eq_mul, Real.coe_toNNReal _ (hZ0 ω)]
  have hint : ∀ g : Ω → ℝ, Integrable g Q → Integrable (fun ω => Z ω * g ω) P := by
    intro g hg
    rw [hQ', integrable_withDensity_iff_integrable_smul hZnn, hsmul] at hg
    exact hg
  have hset : ∀ (g : Ω → ℝ) (s : Set Ω), MeasurableSet[mΩ] s →
      ∫ ω in s, g ω ∂Q = ∫ ω in s, Z ω * g ω ∂P := by
    intro g s hs
    rw [hQ', setIntegral_withDensity_eq_setIntegral_smul hZnn g hs, hsmul]
  have hac : Q ≪ P := by rw [hQ]; exact withDensity_absolutelyContinuous _ _
  set U := Q[X | G] with hU
  set W := P[Z | G] with hW
  have hUm : StronglyMeasurable[G] U := stronglyMeasurable_condExp
  have hWm : StronglyMeasurable[G] W := stronglyMeasurable_condExp
  have hUZ : Integrable (U * Z) P := by
    have := hint U integrable_condExp
    refine this.congr (Filter.Eventually.of_forall fun ω => ?_)
    simp [mul_comm]
  have hZint : Integrable Z P := by
    have := hint (fun _ => 1) (integrable_const _)
    simpa using this
  have hZX : Integrable (fun ω => Z ω * X ω) P := hint X hX
  -- Step A
  have hA : P[fun ω => Z ω * X ω | G] =ᵐ[P] P[U * Z | G] := by
    refine ae_eq_condExp_of_forall_setIntegral_eq hG hUZ
      (fun s _ _ => integrable_condExp.integrableOn) (fun s hs _ => ?_)
      stronglyMeasurable_condExp.aestronglyMeasurable
    rw [setIntegral_condExp hG hZX hs, ← hset X s (hG s hs),
      ← setIntegral_condExp hG hX hs, hset U s (hG s hs)]
    simp only [Pi.mul_apply, mul_comm]
  -- Step B
  have hB : P[U * Z | G] =ᵐ[P] U * W := condExp_mul_of_stronglyMeasurable_left hUm hUZ hZint
  have hVQ : P[fun ω => Z ω * X ω | G] =ᵐ[Q] U * W := hac.ae_le (hA.trans hB)
  -- Step C
  have hpos : ∀ᵐ ω ∂Q, 0 < W ω := by
    have hsG : MeasurableSet[G] {ω | W ω ≤ 0} := hWm.measurable measurableSet_Iic
    have hs : MeasurableSet[mΩ] {ω | W ω ≤ 0} := hG _ hsG
    have hreal : Q.real {ω | W ω ≤ 0} ≤ 0 := by
      have h1 : Q.real {ω | W ω ≤ 0} = ∫ ω in {ω | W ω ≤ 0}, (1 : ℝ) ∂Q := by simp
      rw [h1, hset _ _ hs]
      simp only [mul_one]
      rw [← setIntegral_condExp hG hZint hsG]
      exact setIntegral_nonpos hs fun ω hω => hω
    have h0 : Q {ω | W ω ≤ 0} = 0 := by
      rw [← measureReal_eq_zero_iff]
      exact le_antisymm hreal measureReal_nonneg
    rw [ae_iff]
    simpa [not_lt] using h0
  filter_upwards [hVQ, hpos] with ω h1 h2
  rw [h1, Pi.mul_apply, mul_div_assoc, div_self h2.ne', mul_one]

-- The four-season table: 8 equally likely months, rainfall 20, 40; 50, 70; 80, 100; 30, 50 mm.
-- E_P[X | S = s] is the lookup table g = 30, 60, 90, 40.
example : ((20 : ℚ) + 40) / 2 = 30 ∧ ((50 : ℚ) + 70) / 2 = 60 ∧
    ((80 : ℚ) + 100) / 2 = 90 ∧ ((30 : ℚ) + 50) / 2 = 40 := by norm_num
-- Bayes with Z = X/55: E_Q[X | S = s] = E_P[Z X | S = s] / E_P[Z | S = s] = 100/3, 185/3, 820/9, 85/2,
-- which is (m^2 + 100)/m for the season mean m.
example :
    ((20 * (20 / 55) + 40 * (40 / 55)) / 2) / ((20 / 55 + 40 / 55) / 2) = (100 / 3 : ℚ) ∧
    ((50 * (50 / 55) + 70 * (70 / 55)) / 2) / ((50 / 55 + 70 / 55) / 2) = (185 / 3 : ℚ) ∧
    ((80 * (80 / 55) + 100 * (100 / 55)) / 2) / ((80 / 55 + 100 / 55) / 2) = (820 / 9 : ℚ) ∧
    ((30 * (30 / 55) + 50 * (50 / 55)) / 2) / ((30 / 55 + 50 / 55) / 2) = (85 / 2 : ℚ) := by
  norm_num
example : ((30 : ℚ) ^ 2 + 100) / 30 = 100 / 3 ∧ ((60 : ℚ) ^ 2 + 100) / 60 = 185 / 3 ∧
    ((90 : ℚ) ^ 2 + 100) / 90 = 820 / 9 ∧ ((40 : ℚ) ^ 2 + 100) / 40 = 85 / 2 := by norm_num
-- Forgetting the denominator: E_P[Z X | S = s] = 200/11, 740/11, 1640/11, 340/11.
example :
    (20 * (20 / 55) + 40 * (40 / 55)) / 2 = (200 / 11 : ℚ) ∧
    (50 * (50 / 55) + 70 * (70 / 55)) / 2 = (740 / 11 : ℚ) ∧
    (80 * (80 / 55) + 100 * (100 / 55)) / 2 = (1640 / 11 : ℚ) ∧
    (30 * (30 / 55) + 50 * (50 / 55)) / 2 = (340 / 11 : ℚ) := by norm_num
-- Q(S = s) = m/220: 3/22, 3/11, 9/22, 2/11.
example : (1 / 8 : ℚ) * (20 / 55 + 40 / 55) = 3 / 22 ∧ (1 / 8 : ℚ) * (50 / 55 + 70 / 55) = 3 / 11 ∧
    (1 / 8 : ℚ) * (80 / 55 + 100 / 55) = 9 / 22 ∧ (1 / 8 : ℚ) * (30 / 55 + 50 / 55) = 2 / 11 := by
  norm_num
-- E_Q[X] = E_P[Z X] month by month = 730/11, and the tower under Q gives the same.
example : (1 / 8 : ℚ) * ((20 ^ 2 + 40 ^ 2 + 50 ^ 2 + 70 ^ 2 + 80 ^ 2 + 100 ^ 2 + 30 ^ 2 + 50 ^ 2) / 55)
    = 730 / 11 := by norm_num
example : (3 / 22 : ℚ) * (100 / 3) + 3 / 11 * (185 / 3) + 9 / 22 * (820 / 9) + 2 / 11 * (85 / 2)
    = 730 / 11 := by norm_num

-- The station, in exact fractions: correlation -3/5, spreads 20 and 5, tilt a = 1/40.
-- Slope -12/5 mm per degree, and g(20) = 55 - (12/5)(20 - 15) = 43 mm.
example : (-3 / 5 : ℚ) * 20 / 5 = -12 / 5 ∧ (55 : ℚ) + (-12 / 5) * (20 - 15) = 43 := by norm_num
-- Slice variance 20^2 (1 - 9/25) = 256 = 16^2; tilt shift (1/40)(256) = 32/5, so h(20) = 247/5 mm.
example : (20 : ℚ) ^ 2 * (1 - (3 / 5) ^ 2) = 16 ^ 2 ∧ (1 / 40 : ℚ) * 16 ^ 2 = 32 / 5 ∧
    (43 : ℚ) + 32 / 5 = 247 / 5 := by norm_num
-- Second road: Q-centres 55 + 400/40 = 65 and 15 - 60/40 = 27/2; Q-line at 20 is 247/5 again.
example : (55 : ℚ) + 1 / 40 * 400 = 65 ∧ (15 : ℚ) + 1 / 40 * (-60) = 27 / 2 ∧
    (65 : ℚ) - 12 / 5 * (20 - 27 / 2) = 247 / 5 := by norm_num
-- The mistake: shifting by the unconditional change gives 43 + 10 = 53, not 247/5.
example : (43 : ℚ) + 1 / 40 * 400 = 53 ∧ (53 : ℚ) ≠ 247 / 5 := by norm_num

#print axioms condexp_given_random_variable_is_function_of_it
#print axioms condexp_from_joint_density
#print axioms abstract_bayes_formula
