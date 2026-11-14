-- Vasicek's large-pool loss curve: when the default fraction is the conditional default chance of a standard normal economy, its distribution and its α-quantile are Vasicek's closed forms, and the default fraction of a pool of n one-factor loans converges to that conditional chance as n grows.
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Independence.Basic

open MeasureTheory ProbabilityTheory Filter Topology

lemma vasicek_gauss_singleton (a : ℝ) : gaussianReal 0 1 {a} = 0 :=
  (nullSingletonClass_gaussianReal (μ := 0) one_ne_zero).measure_singleton a

lemma vasicek_cdf_strictMono : StrictMono (cdf (gaussianReal 0 1)) := by
  intro a b hab
  have h1 := (cdf (gaussianReal 0 1)).measure_Ioc a b
  rw [measure_cdf] at h1
  have h2 : gaussianReal 0 1 (Set.Ioc a b) ≠ 0 := by
    intro h
    have := gaussianReal_absolutelyContinuous' 0 one_ne_zero h
    rw [Real.volume_Ioc] at this
    simp at this
    linarith
  rw [h1] at h2
  have := mt ENNReal.ofReal_eq_zero.mpr h2
  linarith [not_le.mp this]

lemma vasicek_cdf_leftLim (a : ℝ) :
    Function.leftLim (cdf (gaussianReal 0 1)) a = cdf (gaussianReal 0 1) a := by
  have h1 := (cdf (gaussianReal 0 1)).measure_singleton a
  rw [measure_cdf, vasicek_gauss_singleton] at h1
  have h2 : Function.leftLim (cdf (gaussianReal 0 1)) a ≤ cdf (gaussianReal 0 1) a :=
    Monotone.leftLim_le (monotone_cdf _) le_rfl
  have h3 := ENNReal.ofReal_eq_zero.mp h1.symm
  linarith

lemma vasicek_cdf_contWithin (a : ℝ) :
    ContinuousWithinAt (cdf (gaussianReal 0 1)) (Set.Iio a) a :=
  (monotone_cdf _).continuousWithinAt_Iio_iff_leftLim_eq.2 (vasicek_cdf_leftLim a)

lemma vasicek_gauss_Ici (t : ℝ) :
    (gaussianReal 0 1).real (Set.Ici t) = cdf (gaussianReal 0 1) (-t) := by
  rw [cdf_eq_real]
  have h : (gaussianReal 0 1).map (fun x => -x) = gaussianReal 0 1 := by
    simpa using gaussianReal_map_neg (μ := 0) (v := 1)
  conv_lhs => rw [← h]
  rw [map_measureReal_apply measurable_neg measurableSet_Ici]
  congr 1
  ext x
  simp

lemma vasicek_prob_le {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (M : Ω → ℝ) (hM : HasLaw M (gaussianReal 0 1) P)
    {ρ c : ℝ} (hρ0 : 0 < ρ) (hρ1 : ρ < 1) (y : ℝ) :
    P.real {ω | (c - Real.sqrt ρ * M ω) / Real.sqrt (1 - ρ) ≤ y} =
      cdf (gaussianReal 0 1) ((Real.sqrt (1 - ρ) * y - c) / Real.sqrt ρ) := by
  have hs : 0 < Real.sqrt ρ := Real.sqrt_pos.2 hρ0
  have hr : 0 < Real.sqrt (1 - ρ) := Real.sqrt_pos.2 (by linarith)
  have hset : {ω | (c - Real.sqrt ρ * M ω) / Real.sqrt (1 - ρ) ≤ y} =
      {ω | (c - Real.sqrt (1 - ρ) * y) / Real.sqrt ρ ≤ M ω} := by
    ext ω
    simp only [Set.mem_ofPred_eq]
    rw [div_le_iff₀ hr, div_le_iff₀ hs]
    constructor <;> intro h <;> linarith
  rw [hset, hM.measureReal_eq (p := fun m => (c - Real.sqrt (1 - ρ) * y) / Real.sqrt ρ ≤ m)
    measurableSet_Ici]
  rw [show {x : ℝ | (c - Real.sqrt (1 - ρ) * y) / Real.sqrt ρ ≤ x} =
    Set.Ici ((c - Real.sqrt (1 - ρ) * y) / Real.sqrt ρ) from rfl, vasicek_gauss_Ici]
  congr 1
  ring

#print axioms vasicek_gauss_singleton
#print axioms vasicek_cdf_strictMono
#print axioms vasicek_cdf_leftLim
#print axioms vasicek_cdf_contWithin
#print axioms vasicek_gauss_Ici
#print axioms vasicek_prob_le

/-- The loss curve. Let the economy `M` be a standard normal draw, the asset correlation `ρ`
lie strictly between 0 and 1, and the default threshold `c` satisfy `N c = p` (so `c = N⁻¹(p)`),
where `N` is the standard normal distribution function. In a very large pool the default
fraction is `L = N((c - √ρ M) / √(1 - ρ))`. Then for every level `x` strictly between 0 and 1,
with `y = N⁻¹(x)` (that is, `N y = x`), the chance that `L` is at most `x` is
`N((√(1 - ρ) N⁻¹(x) - N⁻¹(p)) / √ρ)`. -/
theorem vasicek_loss_distribution
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (M : Ω → ℝ) (hM : HasLaw M (gaussianReal 0 1) P)
    {ρ p c : ℝ} (hρ0 : 0 < ρ) (hρ1 : ρ < 1) (hc : cdf (gaussianReal 0 1) c = p)
    {x y : ℝ} (hx0 : 0 < x) (hx1 : x < 1) (hy : cdf (gaussianReal 0 1) y = x) :
    P.real {ω | cdf (gaussianReal 0 1) ((c - Real.sqrt ρ * M ω) / Real.sqrt (1 - ρ)) ≤ x} =
      cdf (gaussianReal 0 1) ((Real.sqrt (1 - ρ) * y - c) / Real.sqrt ρ) := by
  have hset : {ω | cdf (gaussianReal 0 1) ((c - Real.sqrt ρ * M ω) / Real.sqrt (1 - ρ)) ≤ x} =
      {ω | (c - Real.sqrt ρ * M ω) / Real.sqrt (1 - ρ) ≤ y} := by
    ext ω
    simp only [Set.mem_ofPred_eq]
    rw [← hy, vasicek_cdf_strictMono.le_iff_le]
  rw [hset, vasicek_prob_le M hM hρ0 hρ1 y]

/-- The bad-year default rate. Under the same model, for a confidence level `α` strictly between
0 and 1 with `z = N⁻¹(α)`, the level `x_α = N((N⁻¹(p) + √ρ N⁻¹(α)) / √(1 - ρ))` is exactly the
`α`-quantile of the large-pool default fraction: the fraction stays at or below `x_α` with chance
`α`, and stays at or below any lower level with chance less than `α`. -/
theorem vasicek_quantile
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (M : Ω → ℝ) (hM : HasLaw M (gaussianReal 0 1) P)
    {ρ p c : ℝ} (hρ0 : 0 < ρ) (hρ1 : ρ < 1) (hc : cdf (gaussianReal 0 1) c = p)
    {α z : ℝ} (hα0 : 0 < α) (hα1 : α < 1) (hz : cdf (gaussianReal 0 1) z = α) :
    let L : Ω → ℝ := fun ω => cdf (gaussianReal 0 1) ((c - Real.sqrt ρ * M ω) / Real.sqrt (1 - ρ))
    let xα : ℝ := cdf (gaussianReal 0 1) ((c + Real.sqrt ρ * z) / Real.sqrt (1 - ρ))
    P.real {ω | L ω ≤ xα} = α ∧ ∀ x < xα, P.real {ω | L ω ≤ x} < α := by
  intro L xα
  have hs : 0 < Real.sqrt ρ := Real.sqrt_pos.2 hρ0
  have hr : 0 < Real.sqrt (1 - ρ) := Real.sqrt_pos.2 (by linarith)
  set u : ℝ := (c + Real.sqrt ρ * z) / Real.sqrt (1 - ρ) with hu
  have hkey : (Real.sqrt (1 - ρ) * u - c) / Real.sqrt ρ = z := by
    rw [hu]; field_simp; ring
  have hLset : ∀ y : ℝ, {ω | L ω ≤ cdf (gaussianReal 0 1) y} =
      {ω | (c - Real.sqrt ρ * M ω) / Real.sqrt (1 - ρ) ≤ y} := by
    intro y
    ext ω
    simp only [Set.mem_ofPred_eq, L]
    rw [vasicek_cdf_strictMono.le_iff_le]
  refine ⟨?_, ?_⟩
  · show P.real {ω | L ω ≤ cdf (gaussianReal 0 1) u} = α
    rw [hLset, vasicek_prob_le M hM hρ0 hρ1 u, hkey, hz]
  · intro x hx
    have hev : ∀ᶠ v in 𝓝[<] u, x < cdf (gaussianReal 0 1) v ∧ v < u :=
      ((vasicek_cdf_contWithin u).eventually (lt_mem_nhds hx)).and self_mem_nhdsWithin
    obtain ⟨y', hy'x, hy'u⟩ := hev.exists
    have hsub : {ω | L ω ≤ x} ⊆ {ω | (c - Real.sqrt ρ * M ω) / Real.sqrt (1 - ρ) ≤ y'} := by
      intro ω hω
      simp only [Set.mem_ofPred_eq, L] at hω ⊢
      by_contra hcon
      push Not at hcon
      have := monotone_cdf (gaussianReal 0 1) hcon.le
      linarith
    calc P.real {ω | L ω ≤ x}
        ≤ P.real {ω | (c - Real.sqrt ρ * M ω) / Real.sqrt (1 - ρ) ≤ y'} := measureReal_mono hsub
      _ = cdf (gaussianReal 0 1) ((Real.sqrt (1 - ρ) * y' - c) / Real.sqrt ρ) :=
          vasicek_prob_le M hM hρ0 hρ1 y'
      _ < cdf (gaussianReal 0 1) ((Real.sqrt (1 - ρ) * u - c) / Real.sqrt ρ) := by
          apply vasicek_cdf_strictMono
          apply div_lt_div_of_pos_right _ hs
          have := mul_lt_mul_of_pos_left hy'u hr
          linarith
      _ = α := by rw [hkey, hz]

/-- The large-pool limit. Company `i` has health `√ρ M + √(1 - ρ) Z_i`, where the economy `M`
and the private lucks `Z_0, Z_1, …` are independent standard normal draws, and defaults when its
health falls below the threshold `c`. Then the default fraction of the first `n` companies comes
within any `ε > 0` of the conditional default chance `N((c - √ρ M) / √(1 - ρ))` with chance
tending to 1 as `n` grows: in a very large pool the private luck averages out. -/
theorem large_pool_default_fraction_tendsto
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (M : Ω → ℝ) (Z : ℕ → Ω → ℝ)
    (hM : HasLaw M (gaussianReal 0 1) P) (hZ : ∀ i, HasLaw (Z i) (gaussianReal 0 1) P)
    (hind : iIndepFun (fun i : Option ℕ => i.elim M Z) P)
    {ρ c : ℝ} (hρ0 : 0 ≤ ρ) (hρ1 : ρ < 1) {ε : ℝ} (hε : 0 < ε) :
    Tendsto (fun n : ℕ => P {ω | ε <
      |((Finset.range n).filter
          (fun i => Real.sqrt ρ * M ω + Real.sqrt (1 - ρ) * Z i ω < c)).card / (n : ℝ) -
        cdf (gaussianReal 0 1) ((c - Real.sqrt ρ * M ω) / Real.sqrt (1 - ρ))|})
      atTop (𝓝 0) := by
  have hr : 0 < Real.sqrt (1 - ρ) := Real.sqrt_pos.2 (by linarith)
  set s := Real.sqrt ρ with hs_def
  set r := Real.sqrt (1 - ρ) with hr_def
  set N : ℝ → ℝ := fun t => cdf (gaussianReal 0 1) t with hN_def
  set f : ℝ → ℝ := fun m => (c - s * m) / r with hf_def
  let h : ℝ → ℝ → ℝ := fun m z => (if s * m + r * z < c then 1 else 0) - N (f m)
  have hN_meas : Measurable N := (monotone_cdf (gaussianReal 0 1)).measurable
  have hf_meas : Measurable f := by
    simp only [hf_def]; fun_prop
  have hh_meas : Measurable (fun p : ℝ × ℝ => h p.1 p.2) := by
    refine Measurable.sub (Measurable.ite ?_ measurable_const measurable_const)
      (hN_meas.comp (hf_meas.comp measurable_fst))
    exact measurableSet_lt (by fun_prop) measurable_const
  have hh_bound : ∀ m z, |h m z| ≤ 1 := by
    intro m z
    have h0 := cdf_nonneg (gaussianReal 0 1) (f m)
    have h1 := cdf_le_one (gaussianReal 0 1) (f m)
    simp only [h, hN_def]
    rw [abs_le]
    split_ifs <;> constructor <;> linarith
  have hh_int0 : ∀ m, ∫ z, h m z ∂(gaussianReal 0 1) = 0 := by
    intro m
    have hfun : (fun z => (if s * m + r * z < c then (1 : ℝ) else 0)) =
        (Set.Iio (f m)).indicator 1 := by
      funext z
      simp only [Set.indicator_apply, Set.mem_Iio, Pi.one_apply, hf_def]
      congr 1
      apply propext
      rw [lt_div_iff₀ hr]
      constructor <;> intro hh <;> linarith
    simp only [h]
    rw [integral_sub, hfun, integral_indicator_one measurableSet_Iio, integral_const]
    · rw [measureReal_congr (Iio_ae_eq_Iic' (vasicek_gauss_singleton (f m))), ← cdf_eq_real]
      simp [hN_def]
    · rw [hfun]
      exact (integrable_const 1).indicator measurableSet_Iio
    · exact integrable_const _
  -- the centred indicators
  let X : ℕ → Ω → ℝ := fun i ω => h (M ω) (Z i ω)
  have hmeasF : ∀ k : Option ℕ, AEMeasurable (k.elim M Z) P := by
    intro k
    cases k with
    | none => exact hM.aemeasurable
    | some i => exact (hZ i).aemeasurable
  have hX_aesm : ∀ i, AEStronglyMeasurable (X i) P := fun i =>
    (hh_meas.comp_aemeasurable (hM.aemeasurable.prodMk (hZ i).aemeasurable)).aestronglyMeasurable
  have hX_bound : ∀ i ω, |X i ω| ≤ 1 := fun i ω => hh_bound _ _
  have hXX_int : ∀ i j, Integrable (fun ω => X i ω * X j ω) P := by
    intro i j
    refine Integrable.of_bound ((hX_aesm i).mul (hX_aesm j)) 1 (ae_of_all _ fun ω => ?_)
    rw [norm_mul, Real.norm_eq_abs, Real.norm_eq_abs]
    nlinarith [hX_bound i ω, hX_bound j ω, abs_nonneg (X i ω), abs_nonneg (X j ω)]
  have hcross : ∀ i j, i ≠ j → ∫ ω, X i ω * X j ω ∂P = 0 := by
    intro i j hij
    have hind1 : IndepFun (fun ω => (Z i ω, Z j ω)) M P :=
      hind.indepFun_prodMk₀ hmeasF (some i) (some j) none (by simp) (by simp)
    have hind2 : IndepFun (Z i) (Z j) P :=
      hind.indepFun (i := some i) (j := some j) (by simpa using hij)
    have hlaw2 : HasLaw (fun ω => (Z i ω, Z j ω))
        ((gaussianReal 0 1).prod (gaussianReal 0 1)) P := hind2.hasLaw_prod (hZ i) (hZ j)
    have hlaw3 : HasLaw (fun ω => (M ω, (Z i ω, Z j ω)))
        ((gaussianReal 0 1).prod ((gaussianReal 0 1).prod (gaussianReal 0 1))) P :=
      hind1.symm.hasLaw_prod hM hlaw2
    let G : ℝ × ℝ × ℝ → ℝ := fun q => h q.1 q.2.1 * h q.1 q.2.2
    have hG_meas : Measurable G :=
      (hh_meas.comp (measurable_fst.prodMk (measurable_fst.comp measurable_snd))).mul
        (hh_meas.comp (measurable_fst.prodMk (measurable_snd.comp measurable_snd)))
    have hG_int : Integrable G
        ((gaussianReal 0 1).prod ((gaussianReal 0 1).prod (gaussianReal 0 1))) := by
      refine Integrable.of_bound hG_meas.aestronglyMeasurable 1 (ae_of_all _ fun q => ?_)
      rw [Real.norm_eq_abs, abs_mul]
      nlinarith [hh_bound q.1 q.2.1, hh_bound q.1 q.2.2, abs_nonneg (h q.1 q.2.1),
        abs_nonneg (h q.1 q.2.2)]
    have h1 : ∫ ω, X i ω * X j ω ∂P = ∫ q, G q
        ∂((gaussianReal 0 1).prod ((gaussianReal 0 1).prod (gaussianReal 0 1))) :=
      hlaw3.integral_comp hG_meas.aestronglyMeasurable
    rw [h1, integral_prod G hG_int]
    have h2 : ∀ m, ∫ q, G (m, q) ∂((gaussianReal 0 1).prod (gaussianReal 0 1)) = 0 := by
      intro m
      have := integral_prod_mul (μ := gaussianReal 0 1) (ν := gaussianReal 0 1)
        (fun a => h m a) (fun b => h m b)
      simp only [G]
      rw [this, hh_int0, zero_mul]
    simp [h2]
  have hdiag : ∀ i, ∫ ω, X i ω * X i ω ∂P ≤ 1 := by
    intro i
    have : ∫ ω, X i ω * X i ω ∂P ≤ ∫ _ω, (1 : ℝ) ∂P := by
      refine integral_mono (hXX_int i i) (integrable_const 1) (fun ω => ?_)
      have := hX_bound i ω
      have : X i ω * X i ω = |X i ω| * |X i ω| := (abs_mul_abs_self _).symm
      nlinarith [abs_nonneg (X i ω)]
    simpa [Function.comp_def] using this
  have hsq_eq : ∀ n : ℕ, (fun ω => (∑ i ∈ Finset.range n, X i ω) ^ 2) =
      fun ω => ∑ i ∈ Finset.range n, ∑ j ∈ Finset.range n, X i ω * X j ω := by
    intro n; funext ω; rw [sq, Finset.sum_mul_sum]
  have hsq_int : ∀ n : ℕ, Integrable (fun ω => (∑ i ∈ Finset.range n, X i ω) ^ 2) P := by
    intro n
    rw [hsq_eq]
    exact integrable_finsetSum _ fun i _ => integrable_finsetSum _ fun j _ => hXX_int i j
  have hmom : ∀ n : ℕ, ∫ ω, (∑ i ∈ Finset.range n, X i ω) ^ 2 ∂P ≤ n := by
    intro n
    rw [hsq_eq, integral_finsetSum _ fun i _ =>
      integrable_finsetSum _ fun j _ => hXX_int i j]
    calc ∑ i ∈ Finset.range n, ∫ ω, ∑ j ∈ Finset.range n, X i ω * X j ω ∂P
        ≤ ∑ i ∈ Finset.range n, (1 : ℝ) := by
          refine Finset.sum_le_sum fun i hi => ?_
          rw [integral_finsetSum _ fun j _ => hXX_int i j]
          rw [Finset.sum_eq_single i (fun j _ hji => hcross i j (Ne.symm hji))
            (fun hi' => absurd hi hi')]
          exact hdiag i
      _ = n := by simp
  -- the bound for each n ≥ 1
  have hbound : ∀ n : ℕ, 1 ≤ n → P {ω | ε <
      |((Finset.range n).filter
          (fun i => s * M ω + r * Z i ω < c)).card / (n : ℝ) - N (f (M ω))|}
      ≤ ENNReal.ofReal (1 / ε ^ 2 / n) := by
    intro n hn
    have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    have hid : ∀ ω, ((Finset.range n).filter
          (fun i => s * M ω + r * Z i ω < c)).card / (n : ℝ) - N (f (M ω)) =
        (∑ i ∈ Finset.range n, X i ω) / n := by
      intro ω
      simp only [X, h, Finset.sum_sub_distrib, Finset.card_filter, Finset.sum_const,
        Finset.card_range, nsmul_eq_mul]
      push_cast
      field_simp
    have hsub : {ω | ε < |((Finset.range n).filter
          (fun i => s * M ω + r * Z i ω < c)).card / (n : ℝ) - N (f (M ω))|} ⊆
        {ω | ε ^ 2 * (n : ℝ) ^ 2 ≤ (∑ i ∈ Finset.range n, X i ω) ^ 2} := by
      intro ω hω
      simp only [Set.mem_ofPred_eq] at hω ⊢
      rw [hid, abs_div, abs_of_pos hn', lt_div_iff₀ hn'] at hω
      have h2 : (ε * n) ^ 2 ≤ |∑ i ∈ Finset.range n, X i ω| ^ 2 :=
        pow_le_pow_left₀ (by positivity) hω.le 2
      rw [sq_abs] at h2
      linarith [mul_pow ε (n : ℝ) 2]
    have hmarkov := mul_meas_ge_le_integral_of_nonneg
      (ae_of_all P fun ω => sq_nonneg (∑ i ∈ Finset.range n, X i ω)) (hsq_int n)
      (ε ^ 2 * (n : ℝ) ^ 2)
    have hreal : P.real {ω | ε ^ 2 * (n : ℝ) ^ 2 ≤ (∑ i ∈ Finset.range n, X i ω) ^ 2}
        ≤ 1 / ε ^ 2 / n := by
      have hpos : 0 < ε ^ 2 * (n : ℝ) ^ 2 := by positivity
      rw [show (1 : ℝ) / ε ^ 2 / n = n / (ε ^ 2 * (n : ℝ) ^ 2) by field_simp]
      rw [le_div_iff₀ hpos]
      linarith [hmom n]
    calc _ ≤ P {ω | ε ^ 2 * (n : ℝ) ^ 2 ≤ (∑ i ∈ Finset.range n, X i ω) ^ 2} := measure_mono hsub
      _ = ENNReal.ofReal (P.real {ω | ε ^ 2 * (n : ℝ) ^ 2 ≤ (∑ i ∈ Finset.range n, X i ω) ^ 2}) :=
          (ofReal_measureReal (measure_ne_top _ _)).symm
      _ ≤ _ := ENNReal.ofReal_le_ofReal hreal
  have hlim : Tendsto (fun n : ℕ => ENNReal.ofReal (1 / ε ^ 2 / n)) atTop (𝓝 0) := by
    have := (ENNReal.continuous_ofReal.tendsto 0).comp
      (tendsto_const_div_atTop_nhds_zero_nat (1 / ε ^ 2))
    simpa [Function.comp_def] using this
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hlim
    (Eventually.of_forall fun _ => bot_le) ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  exact hbound n hn

/-- Expected loss per $100 loan: $100 × LGD 60% × PD 2% = $1.20. -/
example : (100 : ℚ) * (60 / 100) * (2 / 100) = 6 / 5 := by norm_num

/-- Basel's factor 12.5 is 1 divided by 8%: risk-weighted assets times 8% give back the capital. -/
example : (25 / 2 : ℚ) * (8 / 100) = 1 := by norm_num

#print axioms vasicek_loss_distribution
#print axioms vasicek_quantile
#print axioms large_pool_default_fraction_tendsto
