-- The Cantor set: the middle-thirds Cantor set is closed, contains no interval, has length zero and has as many points as [0, 1], and the coin-flip staircase is a continuous distribution function, flat almost everywhere, with no density.
import Mathlib.Topology.Instances.CantorSet
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.Probability.ProductMeasure
import Mathlib.Probability.CDF
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.SetTheory.Cardinal.Basic
import Mathlib.Analysis.Real.Cardinality

open MeasureTheory ProbabilityTheory Set
open scoped ENNReal Cardinal

/-! `cantorSet` is Mathlib's middle-thirds Cantor set: `preCantorSet 0 = [0, 1]`, each
`preCantorSet (n + 1)` keeps the two closed outer thirds of every stretch of `preCantorSet n`
(so the open middle thirds are cut and the ends kept), and `cantorSet` is the intersection
over every night `n`. Lebesgue measure on `ℝ` is `volume`. -/

/-- One fair coin toss: heads (`true`) and tails (`false`) each with chance one half. -/
noncomputable def fairCoin : Measure Bool :=
  (1 / 2 : ℝ≥0∞) • (Measure.dirac true + Measure.dirac false)

/-- The coin-flip point: toss `k` (counting from 0) writes base-3 digit `k + 1` of the point,
2 for heads and 0 for tails, so `X = ∑ 2 b_k / 3 ^ (k + 1)`. -/
noncomputable def coinFlipPoint (b : ℕ → Bool) : ℝ :=
  Real.ofDigits (fun k => cond (b k) (2 : Fin 3) 0)

/-- The law of the coin-flip point: one fair toss per night, all tosses independent. -/
noncomputable def cantorLaw : Measure ℝ :=
  (Measure.infinitePi (fun _ : ℕ => fairCoin)).map coinFlipPoint

/-! Helper lemmas for the proofs below. -/

lemma cantorHelper_image_div_three (S : Set ℝ) :
    (· / 3) '' S = (fun y : ℝ => 3 * y) ⁻¹' S := by
  ext y
  constructor
  · rintro ⟨x, hx, rfl⟩
    simp only [mem_preimage]
    convert hx using 1
    ring
  · intro hy
    exact ⟨3 * y, hy, by ring⟩

lemma cantorHelper_image_two_add_div_three (S : Set ℝ) :
    (fun x : ℝ => (2 + x) / 3) '' S = (fun y : ℝ => 3 * y) ⁻¹' ((fun z : ℝ => -2 + z) ⁻¹' S) := by
  ext y
  constructor
  · rintro ⟨x, hx, rfl⟩
    simp only [mem_preimage]
    convert hx using 1
    ring
  · intro hy
    exact ⟨-2 + 3 * y, hy, by ring⟩

lemma cantorHelper_volume_preCantorSet (n : ℕ) :
    volume (preCantorSet n) ≤ (2 / 3 : ℝ≥0∞) ^ n := by
  induction n with
  | zero => simp [Real.volume_Icc]
  | succ n ih =>
    rw [preCantorSet_succ, cantorHelper_image_div_three, cantorHelper_image_two_add_div_three]
    have h3 : ENNReal.ofReal |(3 : ℝ)⁻¹| = 3⁻¹ := by
      rw [abs_of_pos (by norm_num), ENNReal.ofReal_inv_of_pos (by norm_num)]
      simp
    calc volume (_ ∪ _)
        ≤ volume ((fun y : ℝ => 3 * y) ⁻¹' preCantorSet n) +
          volume ((fun y : ℝ => 3 * y) ⁻¹' ((fun z : ℝ => -2 + z) ⁻¹' preCantorSet n)) :=
          measure_union_le _ _
      _ = 3⁻¹ * volume (preCantorSet n) + 3⁻¹ * volume (preCantorSet n) := by
          rw [Real.volume_preimage_mul_left (by norm_num), Real.volume_preimage_mul_left (by norm_num),
            measure_preimage_add, h3]
      _ = (2 / 3) * volume (preCantorSet n) := by
          rw [← add_mul, ← two_mul, div_eq_mul_inv]
      _ ≤ (2 / 3) * (2 / 3) ^ n := by gcongr
      _ = (2 / 3 : ℝ≥0∞) ^ (n + 1) := by rw [pow_succ']

lemma cantorHelper_volume_cantorSet : volume cantorSet = 0 := by
  apply nonpos_iff_eq_zero.mp
  apply ge_of_tendsto' (ENNReal.tendsto_pow_atTop_nhds_zero_of_lt_one (r := 2 / 3) ?_)
  · intro n
    exact (measure_mono (iInter_subset _ n)).trans (cantorHelper_volume_preCantorSet n)
  · rw [ENNReal.div_lt_iff (by norm_num) (by norm_num)]
    norm_num

lemma cantorHelper_fairCoin_singleton (x : Bool) : fairCoin {x} = 1 / 2 := by
  cases x <;> simp [fairCoin]

instance cantorHelper_fairCoin_isProb : IsProbabilityMeasure fairCoin := by
  constructor
  simp only [fairCoin, Measure.smul_apply, Measure.add_apply, measure_univ, smul_eq_mul]
  rw [one_add_one_eq_two, one_div, ENNReal.inv_mul_cancel (by norm_num) (by norm_num)]

lemma cantorHelper_continuous_coinFlipPoint : Continuous coinFlipPoint :=
  Real.continuous_ofDigits.comp
    (continuous_pi fun k => (continuous_of_discreteTopology (f := fun x : Bool => cond x (2 : Fin 3) 0)).comp
      (continuous_apply k))

lemma cantorHelper_measurable_coinFlipPoint : Measurable coinFlipPoint :=
  cantorHelper_continuous_coinFlipPoint.measurable

instance cantorHelper_cantorLaw_isProb : IsProbabilityMeasure cantorLaw := by
  rw [cantorLaw]
  infer_instance

lemma cantorHelper_cylinder (b : ℕ → Bool) (n : ℕ) :
    Measure.infinitePi (fun _ : ℕ => fairCoin)
      (Set.pi (Finset.range n : Set ℕ) (fun i => {b i})) = (1 / 2) ^ n := by
  rw [Measure.infinitePi_pi _ (fun i _ => measurableSet_singleton _)]
  simp [cantorHelper_fairCoin_singleton]

lemma cantorHelper_singleton (b : ℕ → Bool) :
    Measure.infinitePi (fun _ : ℕ => fairCoin) {b} = 0 := by
  apply nonpos_iff_eq_zero.mp
  apply ge_of_tendsto' (ENNReal.tendsto_pow_atTop_nhds_zero_of_lt_one (r := 1 / 2) (by norm_num))
  intro n
  rw [← cantorHelper_cylinder b n]
  apply measure_mono
  intro x hx
  rw [mem_singleton_iff.mp hx]
  intro i _
  rfl

lemma cantorHelper_injective : Function.Injective coinFlipPoint := by
  intro a b h
  have := ofDigits_zero_two_sequence_unique (a := fun k => cond (a k) (2 : Fin 3) 0)
    (b := fun k => cond (b k) (2 : Fin 3) 0)
    (by intro n; cases a n <;> decide) (by intro n; cases b n <;> decide) h
  funext k
  have hk := congrFun this k
  cases ha : a k <;> cases hb : b k <;> simp_all

lemma cantorHelper_cantorLaw_singleton (x : ℝ) : cantorLaw {x} = 0 := by
  rw [cantorLaw, Measure.map_apply cantorHelper_measurable_coinFlipPoint (measurableSet_singleton x)]
  by_cases h : ∃ b, coinFlipPoint b = x
  · obtain ⟨b, rfl⟩ := h
    have : coinFlipPoint ⁻¹' {coinFlipPoint b} = {b} := by
      ext a
      simp [cantorHelper_injective.eq_iff]
    rw [this, cantorHelper_singleton]
  · push Not at h
    have : coinFlipPoint ⁻¹' {x} = ∅ := by
      ext a
      simp [h a]
    simp [this]

lemma cantorHelper_cantorLaw_cantorSet : cantorLaw cantorSet = 1 := by
  rw [cantorLaw, Measure.map_apply cantorHelper_measurable_coinFlipPoint
    isClosed_cantorSet.measurableSet]
  have : coinFlipPoint ⁻¹' cantorSet = univ := by
    ext b
    simp only [mem_preimage, mem_univ, iff_true]
    exact ofDigits_bool_to_fin_three_mem_cantorSet b
  rw [this, measure_univ]

lemma cantorHelper_continuous_cdf : Continuous (cdf cantorLaw) := by
  rw [continuous_iff_continuousAt]
  intro x
  rw [(monotone_cdf cantorLaw).continuousAt_iff_leftLim_eq_rightLim,
    StieltjesFunction.rightLim_eq]
  have h := (cdf cantorLaw).measure_singleton x
  rw [measure_cdf, cantorHelper_cantorLaw_singleton] at h
  have h1 : cdf cantorLaw x - Function.leftLim (cdf cantorLaw) x ≤ 0 :=
    ENNReal.ofReal_eq_zero.mp h.symm
  have h2 := (monotone_cdf cantorLaw).leftLim_le (le_refl x)
  linarith

lemma cantorHelper_lt (a b : ℕ → Bool) (n : ℕ) (hlt : ∀ i < n, a i = b i)
    (ha : a n = false) (hb : b n = true) : coinFlipPoint a < coinFlipPoint b := by
  have hs : ∑ i ∈ Finset.range n, Real.ofDigitsTerm (fun k => cond (a k) (2 : Fin 3) 0) i =
      ∑ i ∈ Finset.range n, Real.ofDigitsTerm (fun k => cond (b k) (2 : Fin 3) 0) i := by
    apply Finset.sum_congr rfl
    intro i hi
    simp [Real.ofDigitsTerm, hlt i (Finset.mem_range.mp hi)]
  have eA := Real.ofDigits_eq_sum_add_ofDigits (fun k => cond (a k) (2 : Fin 3) 0) (n + 1)
  have eB := Real.ofDigits_eq_sum_add_ofDigits (fun k => cond (b k) (2 : Fin 3) 0) (n + 1)
  rw [Finset.sum_range_succ, hs] at eA
  rw [Finset.sum_range_succ] at eB
  unfold coinFlipPoint
  rw [eA, eB]
  have hta := Real.ofDigits_le_one (fun i => cond (a (i + (n + 1))) (2 : Fin 3) 0)
  have htb := Real.ofDigits_nonneg (fun i => cond (b (i + (n + 1))) (2 : Fin 3) 0)
  simp only [Real.ofDigitsTerm, ha, hb, Bool.cond_true, Bool.cond_false]
  have hp : (0 : ℝ) < ((3 : ℕ) : ℝ) ^ (n + 1) := by positivity
  have hq : (0 : ℝ) < (((3 : ℕ) : ℝ) ^ (n + 1))⁻¹ := inv_pos.mpr hp
  set q := (((3 : ℕ) : ℝ) ^ (n + 1))⁻¹
  set ta := Real.ofDigits (fun i => cond (a (i + (n + 1))) (2 : Fin 3) 0)
  set tb := Real.ofDigits (fun i => cond (b (i + (n + 1))) (2 : Fin 3) 0)
  have e0 : (((0 : Fin 3) : ℕ) : ℝ) = 0 := by simp
  have e2 : (((2 : Fin 3) : ℕ) : ℝ) = 2 := by simp
  rw [e0, e2]
  nlinarith

lemma cantorHelper_le_iff (a b : ℕ → Bool) :
    coinFlipPoint a ≤ coinFlipPoint b ↔
      a = b ∨ ∃ n, (∀ i < n, a i = b i) ∧ a n = false ∧ b n = true := by
  constructor
  · intro h
    by_cases hab : a = b
    · exact Or.inl hab
    · right
      have hex : ∃ n, a n ≠ b n := Function.ne_iff.mp hab
      classical
      refine ⟨Nat.find hex, fun i hi => ?_, ?_⟩
      · by_contra hne
        exact Nat.find_min hex hi hne
      · have hspec := Nat.find_spec hex
        have hmin : ∀ i < Nat.find hex, b i = a i := fun i hi => by
          by_contra hne
          exact Nat.find_min hex hi (Ne.symm hne)
        cases ha : a (Nat.find hex) <;> cases hb : b (Nat.find hex)
        · rw [ha, hb] at hspec; exact absurd rfl hspec
        · exact ⟨rfl, rfl⟩
        · exact absurd h (not_le.mpr (cantorHelper_lt b a _ hmin hb ha))
        · rw [ha, hb] at hspec; exact absurd rfl hspec
  · rintro (rfl | ⟨n, hlt, ha, hb⟩)
    · exact le_refl _
    · exact (cantorHelper_lt a b n hlt ha hb).le

lemma cantorHelper_cdf_coinFlipPoint (b : ℕ → Bool) :
    cdf cantorLaw (coinFlipPoint b) = Real.ofDigits (fun k => cond (b k) (1 : Fin 2) 0) := by
  set μ := Measure.infinitePi (fun _ : ℕ => fairCoin) with hμ
  let P : ℕ → Set (ℕ → Bool) := fun n =>
    {a | (∀ i < n, a i = b i) ∧ a n = false ∧ b n = true}
  have hP : ∀ n, P n = if b n then Set.pi (Finset.range (n + 1) : Set ℕ)
      (fun i => {if i < n then b i else false}) else ∅ := by
    intro n
    cases hbn : b n
    · ext a
      simp [P, hbn]
    · ext a
      simp only [P, hbn, mem_ofPred_eq, and_true, ite_true, Set.mem_pi, Finset.coe_range,
        mem_Iio, mem_singleton_iff]
      constructor
      · rintro ⟨h1, h2⟩ i hi
        rcases Nat.lt_succ_iff_lt_or_eq.mp hi with hi | rfl
        · simp [hi, h1 i hi]
        · simp [h2]
      · intro h
        refine ⟨fun i hi => ?_, ?_⟩
        · have := h i (by omega)
          simpa [hi] using this
        · have := h n (by omega)
          simpa using this
  have hPm : ∀ n, MeasurableSet (P n) := by
    intro n
    rw [hP n]
    split_ifs
    · exact MeasurableSet.pi (Finset.countable_toSet _) (fun _ _ => measurableSet_singleton _)
    · exact MeasurableSet.empty
  have hPμ : ∀ n, μ (P n) = if b n then (1 / 2) ^ (n + 1) else 0 := by
    intro n
    rw [hP n]
    split_ifs
    · rw [hμ, Measure.infinitePi_pi _ (fun i _ => measurableSet_singleton _)]
      simp [cantorHelper_fairCoin_singleton]
    · simp
  have hdisj : Pairwise (Function.onFun Disjoint P) := by
    have key : ∀ m n, m < n → Disjoint (P m) (P n) := by
      intro m n hmn
      rw [Set.disjoint_left]
      rintro a ⟨_, ham, hbm⟩ ⟨hn, _, _⟩
      have := hn m hmn
      rw [ham, hbm] at this
      exact Bool.false_ne_true this
    intro m n hmn
    rcases lt_or_gt_of_ne hmn with h | h
    · exact key m n h
    · exact (key n m h).symm
  have hA : coinFlipPoint ⁻¹' Iic (coinFlipPoint b) = insert b (⋃ n, P n) := by
    ext a
    simp only [mem_preimage, mem_Iic, cantorHelper_le_iff, mem_insert_iff, mem_iUnion, P,
      mem_ofPred_eq]
  have hμA : μ (coinFlipPoint ⁻¹' Iic (coinFlipPoint b)) = ∑' n, μ (P n) := by
    rw [hA, ← measure_iUnion hdisj hPm]
    apply le_antisymm
    · calc μ (insert b (⋃ n, P n)) ≤ μ {b} + μ (⋃ n, P n) := by
            rw [insert_eq]
            exact measure_union_le _ _
        _ = μ (⋃ n, P n) := by rw [hμ, cantorHelper_singleton, zero_add]
    · exact measure_mono (subset_insert _ _)
  rw [cdf_eq_real, cantorLaw, map_measureReal_apply cantorHelper_measurable_coinFlipPoint
    measurableSet_Iic, measureReal_def, ← hμ, hμA,
    ENNReal.tsum_toReal_eq (fun n => by rw [hPμ]; split_ifs <;> simp)]
  rw [Real.ofDigits]
  congr 1
  funext n
  rw [hPμ, Real.ofDigitsTerm]
  cases b n <;> simp

lemma cantorHelper_coinFlipPoint_false : coinFlipPoint (fun _ => false) = 0 := by
  simp [coinFlipPoint, Real.ofDigits, Real.ofDigitsTerm]

lemma cantorHelper_coinFlipPoint_true : coinFlipPoint (fun _ => true) = 1 := by
  have := Real.ofDigits_const_last_eq_one 2
  simpa [coinFlipPoint] using this

lemma cantorHelper_hasDerivAt (x : ℝ) (hx : x ∉ cantorSet) :
    HasDerivAt (cdf cantorLaw) 0 x := by
  have hopen : IsOpen cantorSetᶜ := isClosed_cantorSet.isOpen_compl
  obtain ⟨ε, hε, hball⟩ := Metric.isOpen_iff.mp hopen x hx
  have hnull : cantorLaw cantorSetᶜ = 0 :=
    (prob_compl_eq_zero_iff isClosed_cantorSet.measurableSet).mpr cantorHelper_cantorLaw_cantorSet
  have key : ∀ u v, u ≤ v → u ∈ Metric.ball x ε → v ∈ Metric.ball x ε →
      cdf cantorLaw v = cdf cantorLaw u := by
    intro u v huv hu hv
    have hsub : Ioc u v ⊆ cantorSetᶜ := by
      intro z hz
      apply hball
      rw [Metric.mem_ball, Real.dist_eq, abs_sub_lt_iff] at hu hv ⊢
      constructor <;> linarith [hz.1, hz.2]
    have h0 : cantorLaw (Ioc u v) = 0 := measure_mono_null hsub hnull
    have h := (cdf cantorLaw).measure_Ioc u v
    rw [measure_cdf, h0] at h
    have h1 : cdf cantorLaw v - cdf cantorLaw u ≤ 0 := ENNReal.ofReal_eq_zero.mp h.symm
    have h2 := monotone_cdf cantorLaw huv
    linarith
  apply (hasDerivAt_const x (cdf cantorLaw x)).congr_of_eventuallyEq
  filter_upwards [Metric.ball_mem_nhds x hε] with y hy
  rcases le_total x y with h | h
  · exact key x y h (Metric.mem_ball_self hε) hy
  · exact (key y x h hy (Metric.mem_ball_self hε)).symm

#print axioms cantorHelper_image_div_three
#print axioms cantorHelper_image_two_add_div_three
#print axioms cantorHelper_volume_preCantorSet
#print axioms cantorHelper_volume_cantorSet
#print axioms cantorHelper_fairCoin_singleton
#print axioms cantorHelper_fairCoin_isProb
#print axioms cantorHelper_continuous_coinFlipPoint
#print axioms cantorHelper_measurable_coinFlipPoint
#print axioms cantorHelper_cantorLaw_isProb
#print axioms cantorHelper_cylinder
#print axioms cantorHelper_singleton
#print axioms cantorHelper_injective
#print axioms cantorHelper_cantorLaw_singleton
#print axioms cantorHelper_cantorLaw_cantorSet
#print axioms cantorHelper_continuous_cdf
#print axioms cantorHelper_lt
#print axioms cantorHelper_le_iff
#print axioms cantorHelper_cdf_coinFlipPoint
#print axioms cantorHelper_coinFlipPoint_false
#print axioms cantorHelper_coinFlipPoint_true
#print axioms cantorHelper_hasDerivAt

/-- Cutting the open middle third of every remaining stretch, for ever, leaves a set that is
closed, contains no stretch of road of positive length (its interior is empty), has
Lebesgue length zero, and has as many points as the whole road `[0, 1]`. -/
theorem cantor_set_closed_null_with_as_many_points_as_the_road :
    IsClosed cantorSet ∧ interior cantorSet = ∅ ∧ volume cantorSet = 0 ∧
      #cantorSet = #(Icc (0 : ℝ) 1) := by
  refine ⟨isClosed_cantorSet, ?_, cantorHelper_volume_cantorSet, ?_⟩
  · have h : volume (interior cantorSet) = 0 :=
      measure_mono_null interior_subset cantorHelper_volume_cantorSet
    exact (isOpen_interior.measure_eq_zero_iff volume).mp h
  · rw [Cardinal.mk_Icc_real (by norm_num : (0 : ℝ) < 1),
      Cardinal.mk_congr cantorSetEquivNatToBool, ← Cardinal.power_def, Cardinal.mk_bool,
      Cardinal.mk_nat, Cardinal.two_power_aleph0]

/-- The coin-flip point lands in the Cantor set with certainty, no single point carries
probability, its distribution function (the Cantor staircase) is continuous, and it has
no density: its law is not Lebesgue measure weighted by any function `f`. -/
theorem coin_flip_point_lives_on_cantor_set_with_no_density :
    cantorLaw cantorSet = 1 ∧ (∀ x : ℝ, cantorLaw {x} = 0) ∧
      Continuous (cdf cantorLaw) ∧ ∀ f : ℝ → ℝ≥0∞, cantorLaw ≠ volume.withDensity f := by
  refine ⟨cantorHelper_cantorLaw_cantorSet, cantorHelper_cantorLaw_singleton,
    cantorHelper_continuous_cdf, ?_⟩
  intro f hf
  have h1 := cantorHelper_cantorLaw_cantorSet
  have h0 : volume.withDensity f cantorSet = 0 :=
    withDensity_absolutelyContinuous _ _ cantorHelper_volume_cantorSet
  rw [hf, h0] at h1
  exact zero_ne_one h1

/-- The staircase `F = P(X ≤ x)` reads the coin-flip point's 0-and-2 address with every 2
turned into a 1, in base 2; it climbs from `F 0 = 0` to `F 1 = 1`, yet its slope is zero
at almost every point of the road. -/
theorem cantor_staircase_climbs_with_slope_zero_almost_everywhere :
    (∀ b : ℕ → Bool, cdf cantorLaw (coinFlipPoint b) =
        Real.ofDigits (fun k => cond (b k) (1 : Fin 2) 0)) ∧
      cdf cantorLaw 0 = 0 ∧ cdf cantorLaw 1 = 1 ∧
      ∀ᵐ x ∂(volume : Measure ℝ), HasDerivAt (cdf cantorLaw) 0 x := by
  refine ⟨cantorHelper_cdf_coinFlipPoint, ?_, ?_, ?_⟩
  · have h := cantorHelper_cdf_coinFlipPoint (fun _ => false)
    rw [cantorHelper_coinFlipPoint_false] at h
    rw [h]
    simp [Real.ofDigits, Real.ofDigitsTerm]
  · have h := cantorHelper_cdf_coinFlipPoint (fun _ => true)
    rw [cantorHelper_coinFlipPoint_true] at h
    rw [h]
    simpa using Real.ofDigits_const_last_eq_one 1
  · exact (measure_eq_zero_iff_ae_notMem.mp cantorHelper_volume_cantorSet).mono
      fun x hx => cantorHelper_hasDerivAt x hx

/-! The card's exact worked numbers. -/

-- After night n there are 2^n stretches, each 3^(-n) km long: 1024 stretches after night 10,
-- 4096 after night 12, and night 12's 4095 gaps.
example : (2 : ℕ) ^ 10 = 1024 := by norm_num
example : (2 : ℕ) ^ 12 = 4096 ∧ (3 : ℕ) ^ 12 = 531441 ∧ 2 ^ 12 - 1 = 4095 := by norm_num

-- Waiting length after night n is (2/3)^n km: 666.67 m is 2/3 km, 444.44 m is 4/9 km.
example : (2 / 3 : ℚ) ^ 1 = 2 / 3 ∧ (2 / 3 : ℚ) ^ 2 = 4 / 9 := by norm_num

-- Night 18 is the first with under a metre left: 1000 * (2/3)^18 < 1 <= 1000 * (2/3)^17.
example : 1000 * 2 ^ 18 < 3 ^ 18 ∧ 3 ^ 17 ≤ 1000 * 2 ^ 17 := by norm_num

-- The gaps take the whole kilometre: 1/3 + 2/9 + 4/27 + ... = (1/3) / (1 - 2/3) = 1.
example : (1 / 3 : ℚ) / (1 - 2 / 3) = 1 := by norm_num

-- The 250 m mark is 1/4 km = 0.020202... in base 3: 2/9 + 2/81 + ... = (2/9) / (1 - 1/9).
example : (2 / 9 : ℚ) / (1 - 1 / 9) = 1 / 4 := by norm_num

-- F at 250 m reads 0.010101... in base 2: 1/4 + 1/16 + ... = (1/4) / (1 - 1/4) = 1/3.
example : (1 / 4 : ℚ) / (1 - 1 / 4) = 1 / 3 := by norm_num

-- F at 800 m reads 0.11 in base 2, which is 3/4.
example : (1 / 2 : ℚ) + 1 / 4 = 3 / 4 := by norm_num

-- The 800 m mark, 4/5 km, lies in the night-2 gap from 7/9 to 8/9 km.
example : (7 / 9 : ℚ) < 4 / 5 ∧ (4 / 5 : ℚ) < 8 / 9 := by norm_num

-- On night 6 each of the 64 stretches carries a rise of 1/64 of the staircase.
example : (64 : ℚ) * (1 / 64) = 1 := by norm_num

#print axioms cantor_set_closed_null_with_as_many_points_as_the_road
#print axioms coin_flip_point_lives_on_cantor_set_with_no_density
#print axioms cantor_staircase_climbs_with_slope_zero_almost_everywhere
