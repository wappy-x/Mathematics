-- Brownian motion: a fair coin-tossing walk with n steps a second, each of size one over root n, converges at any finite set of times to the law of Brownian motion, whose positions have covariance the earlier time.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.CentralLimitTheorem
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Independence.Process.HasIndepIncrements.Basic

open MeasureTheory ProbabilityTheory Filter
open scoped NNReal ENNReal

/-! Helper lemmas. -/

lemma cos_sub_exp_bound (x : ℝ) : |Real.cos x - Real.exp (-(x ^ 2 / 2))| ≤ 2 * x ^ 4 := by
  have hx4 : |x| ^ 4 = x ^ 4 := by rw [pow_abs]; exact abs_of_nonneg (by positivity)
  by_cases h : |x| ≤ 1
  · have h1 := Real.cos_bound h
    have hx2 : x ^ 2 ≤ 1 := by
      have := pow_le_one₀ (n := 2) (abs_nonneg x) h
      rwa [sq_abs] at this
    have h2 := Real.abs_exp_sub_one_sub_id_le (x := -(x ^ 2 / 2)) (by
      rw [abs_neg, abs_of_nonneg (by positivity)]; linarith)
    rw [hx4] at h1
    have h3 : Real.cos x - Real.exp (-(x ^ 2 / 2)) =
        (Real.cos x - (1 - x ^ 2 / 2)) - (Real.exp (-(x ^ 2 / 2)) - 1 - -(x ^ 2 / 2)) := by ring
    rw [h3]
    refine (abs_sub _ _).trans ?_
    have : (-(x ^ 2 / 2)) ^ 2 = x ^ 4 / 4 := by ring
    rw [this] at h2
    nlinarith [pow_two_nonneg (x ^ 2)]
  · push Not at h
    have : 1 < x ^ 4 := by rw [← hx4]; exact one_lt_pow₀ h (by norm_num)
    have hc := Real.abs_cos_le_one x
    have he : |Real.exp (-(x ^ 2 / 2))| ≤ 1 := by
      rw [abs_of_pos (Real.exp_pos _)]
      exact Real.exp_le_one_iff.2 (by nlinarith [sq_nonneg x])
    linarith [abs_sub (Real.cos x) (Real.exp (-(x ^ 2 / 2)))]

#print axioms cos_sub_exp_bound

lemma abs_prod_sub_prod_le (s : Finset ℕ) (a b : ℕ → ℝ) (ha : ∀ k ∈ s, |a k| ≤ 1)
    (hb : ∀ k ∈ s, |b k| ≤ 1) :
    |∏ k ∈ s, a k - ∏ k ∈ s, b k| ≤ ∑ k ∈ s, |a k - b k| := by
  induction s using Finset.induction_on with
  | empty => simp
  | insert k s hk ih =>
    rw [Finset.prod_insert hk, Finset.prod_insert hk, Finset.sum_insert hk]
    have ih' := ih (fun j hj ↦ ha j (Finset.mem_insert_of_mem hj))
      (fun j hj ↦ hb j (Finset.mem_insert_of_mem hj))
    have hak := ha k (Finset.mem_insert_self k s)
    have hpb : |∏ j ∈ s, b j| ≤ 1 := by
      rw [Finset.abs_prod]
      exact Finset.prod_le_one₀ (fun _ _ ↦ abs_nonneg _)
        (fun j hj ↦ hb j (Finset.mem_insert_of_mem hj))
    have e : a k * ∏ j ∈ s, a j - b k * ∏ j ∈ s, b j =
        a k * (∏ j ∈ s, a j - ∏ j ∈ s, b j) + (a k - b k) * ∏ j ∈ s, b j := by ring
    rw [e]
    refine (abs_add_le _ _).trans ?_
    rw [abs_mul, abs_mul]
    have h1 : |a k| * |∏ j ∈ s, a j - ∏ j ∈ s, b j| ≤ |∏ j ∈ s, a j - ∏ j ∈ s, b j| :=
      mul_le_of_le_one_left (abs_nonneg _) hak
    have h2 : |a k - b k| * |∏ j ∈ s, b j| ≤ |a k - b k| :=
      mul_le_of_le_one_right (abs_nonneg _) hpb
    linarith

#print axioms abs_prod_sub_prod_le

lemma sum_range_ite_lt {M : Type*} [AddCommMonoid M] (f : ℕ → M) {m N : ℕ} (h : m ≤ N) :
    ∑ k ∈ Finset.range N, (if k < m then f k else 0) = ∑ k ∈ Finset.range m, f k := by
  rw [← Finset.sum_filter]
  congr 1
  ext k; simp; omega

#print axioms sum_range_ite_lt

lemma charFun_coin (x : ℝ) :
    charFun ((2⁻¹ : ℝ≥0∞) • (Measure.dirac (1:ℝ) + Measure.dirac (-1))) x = Real.cos x := by
  rw [charFun_apply_real, integral_smul_measure, integral_add_measure (integrable_dirac (by simp))
    (integrable_dirac (by simp))]
  simp [Complex.ofReal_cos, Complex.cos]
  ring_nf

#print axioms charFun_coin

lemma floor_div_tendsto (τ : ℝ≥0) :
    Tendsto (fun n : ℕ ↦ (⌊(n : ℝ≥0) * τ⌋₊ : ℝ) / n) atTop (nhds (τ : ℝ)) := by
  have h := (tendsto_nat_floor_mul_div_atTop (R := ℝ) (a := (τ : ℝ)) τ.2).comp
    tendsto_natCast_atTop_atTop
  refine h.congr fun n ↦ ?_
  simp only [Function.comp_apply]
  congr 2
  rw [show ⌊(n : ℝ≥0) * τ⌋₊ = ⌊(((n : ℝ≥0) * τ : ℝ≥0) : ℝ)⌋₊ from rfl]
  push_cast; ring_nf

#print axioms floor_div_tendsto

lemma sum_sq_coeff {ι : Type*} [Fintype ι] (u : ι → ℝ) (A : ι → ℕ) (N : ℕ) (hA : ∀ i, A i ≤ N) :
    ∑ k ∈ Finset.range N, (∑ i, if k < A i then u i else 0) ^ 2 =
      ∑ i, ∑ j, u i * u j * (min (A i) (A j) : ℕ) := by
  simp_rw [sq, Finset.sum_mul_sum]
  have e : ∀ k i j, (if k < A i then u i else 0) * (if k < A j then u j else 0) =
      if k < min (A i) (A j) then u i * u j else 0 := by
    intro k i j
    by_cases hi : k < A i <;> by_cases hj : k < A j <;> simp [hi, hj, lt_min_iff]
  simp_rw [e]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun i _ ↦ ?_
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun j _ ↦ ?_
  rw [sum_range_ite_lt (fun _ ↦ u i * u j) ((min_le_left _ _).trans (hA i))]
  simp [mul_comm]

#print axioms sum_sq_coeff

lemma prod_cos_tendsto {ι : Type*} [Fintype ι] (τ : ι → ℝ≥0) (u : ι → ℝ) (N : ℕ → ℕ) (T : ℝ)
    (hAN : ∀ (n : ℕ) i, ⌊(n : ℝ≥0) * τ i⌋₊ ≤ N n) (hNT : ∀ n : ℕ, (N n : ℝ) ≤ n * T) :
    Tendsto (fun n : ℕ ↦ ∏ k ∈ Finset.range (N n),
        Real.cos ((√n)⁻¹ * ∑ i, if k < ⌊(n : ℝ≥0) * τ i⌋₊ then u i else 0)) atTop
      (nhds (Real.exp (-(∑ i, ∑ j, u i * u j * ((min (τ i) (τ j) : ℝ≥0) : ℝ)) / 2))) := by
  set A : ℕ → ι → ℕ := fun n i ↦ ⌊(n : ℝ≥0) * τ i⌋₊ with hAdef
  set c : ℕ → ℕ → ℝ := fun n k ↦ ∑ i, if k < A n i then u i else 0 with hcdef
  set C : ℝ := ∑ i, |u i| with hCdef
  have hc : ∀ n k, |c n k| ≤ C := by
    intro n k
    refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun i _ ↦ ?_)
    split_ifs <;> simp
  have hC : 0 ≤ C := Finset.sum_nonneg fun _ _ ↦ abs_nonneg _
  have hsq : ∀ n : ℕ, ((√(n : ℝ))⁻¹) ^ 2 = (n : ℝ)⁻¹ := by
    intro n; rw [inv_pow, Real.sq_sqrt (Nat.cast_nonneg _)]
  -- Step 1: sum of squares
  have hS : ∀ n : ℕ, ∑ k ∈ Finset.range (N n), ((√(n : ℝ))⁻¹ * c n k) ^ 2 =
      ∑ i, ∑ j, u i * u j * (min ((A n i : ℝ) / n) ((A n j : ℝ) / n)) := by
    intro n
    simp_rw [mul_pow, hsq, ← Finset.mul_sum]
    rw [hcdef]
    simp only
    rw [sum_sq_coeff u (A n) (N n) (hAN n), Finset.mul_sum]
    refine Finset.sum_congr rfl fun i _ ↦ ?_
    rw [Finset.mul_sum]
    refine Finset.sum_congr rfl fun j _ ↦ ?_
    rw [min_div_div_right (Nat.cast_nonneg _), div_eq_inv_mul]
    push_cast
    ring
  -- Step 2: limit of sum of squares
  have hlim : Tendsto (fun n : ℕ ↦ ∑ k ∈ Finset.range (N n), ((√(n : ℝ))⁻¹ * c n k) ^ 2) atTop
      (nhds (∑ i, ∑ j, u i * u j * ((min (τ i) (τ j) : ℝ≥0) : ℝ))) := by
    simp_rw [hS, NNReal.coe_min]
    refine tendsto_finsetSum _ fun i _ ↦ tendsto_finsetSum _ fun j _ ↦ ?_
    exact ((floor_div_tendsto (τ i)).min (floor_div_tendsto (τ j))).const_mul _
  -- Step 3: product of exponentials
  have hexp : Tendsto (fun n : ℕ ↦ ∏ k ∈ Finset.range (N n),
      Real.exp (-(((√(n : ℝ))⁻¹ * c n k) ^ 2 / 2))) atTop
      (nhds (Real.exp (-(∑ i, ∑ j, u i * u j * ((min (τ i) (τ j) : ℝ≥0) : ℝ)) / 2))) := by
    have := (Real.continuous_exp.tendsto _).comp ((hlim.neg).div_const 2)
    refine this.congr fun n ↦ ?_
    simp only [Function.comp_apply]
    rw [← Real.exp_sum, Finset.sum_neg_distrib, ← Finset.sum_div, neg_div]
  -- Step 4: the difference goes to zero
  have hdiff : Tendsto (fun n : ℕ ↦ ∏ k ∈ Finset.range (N n), Real.cos ((√(n : ℝ))⁻¹ * c n k) -
      ∏ k ∈ Finset.range (N n), Real.exp (-(((√(n : ℝ))⁻¹ * c n k) ^ 2 / 2))) atTop (nhds 0) := by
    have hbound : ∀ n : ℕ, 0 < n →
        ‖∏ k ∈ Finset.range (N n), Real.cos ((√(n : ℝ))⁻¹ * c n k) -
          ∏ k ∈ Finset.range (N n), Real.exp (-(((√(n : ℝ))⁻¹ * c n k) ^ 2 / 2))‖ ≤
        2 * T * C ^ 4 * (n : ℝ)⁻¹ := by
      intro n hn
      have hn' : (0 : ℝ) < n := by exact_mod_cast hn
      rw [Real.norm_eq_abs]
      refine (abs_prod_sub_prod_le _ _ _ (fun k _ ↦ Real.abs_cos_le_one _) (fun k _ ↦ ?_)).trans ?_
      · rw [abs_of_pos (Real.exp_pos _)]
        exact Real.exp_le_one_iff.2 (by nlinarith [sq_nonneg ((√(n : ℝ))⁻¹ * c n k)])
      refine (Finset.sum_le_sum fun k _ ↦ cos_sub_exp_bound _).trans ?_
      have hk : ∀ k, 2 * ((√(n : ℝ))⁻¹ * c n k) ^ 4 ≤ 2 * ((n : ℝ)⁻¹ ^ 2 * C ^ 4) := by
        intro k
        have h4 : ((√(n : ℝ))⁻¹ * c n k) ^ 4 = (n : ℝ)⁻¹ ^ 2 * c n k ^ 4 := by
          rw [mul_pow, show (4 : ℕ) = 2 * 2 from rfl, pow_mul, hsq]
        rw [h4]
        have : c n k ^ 4 ≤ C ^ 4 := by
          rw [← (show Even 4 from ⟨2, rfl⟩).pow_abs (c n k)]
          exact pow_le_pow_left₀ (abs_nonneg _) (hc n k) 4
        have : (0 : ℝ) ≤ (n : ℝ)⁻¹ ^ 2 := by positivity
        nlinarith
      refine (Finset.sum_le_sum fun k _ ↦ hk k).trans ?_
      rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
      have hpos : 0 ≤ 2 * ((n : ℝ)⁻¹ ^ 2 * C ^ 4) := by positivity
      calc (N n : ℝ) * (2 * ((n : ℝ)⁻¹ ^ 2 * C ^ 4))
          ≤ (n * T) * (2 * ((n : ℝ)⁻¹ ^ 2 * C ^ 4)) := mul_le_mul_of_nonneg_right (hNT n) hpos
        _ = 2 * T * C ^ 4 * (n : ℝ)⁻¹ := by field_simp
    have h0 : Tendsto (fun n : ℕ ↦ 2 * T * C ^ 4 * (n : ℝ)⁻¹) atTop (nhds 0) := by
      simpa using (tendsto_inv_atTop_nhds_zero_nat (𝕜 := ℝ)).const_mul (2 * T * C ^ 4)
    refine squeeze_zero_norm' ?_ h0
    filter_upwards [eventually_gt_atTop 0] with n hn using hbound n hn
  have := hdiff.add hexp
  simp only [zero_add, sub_add_cancel] at this
  exact this

#print axioms prod_cos_tendsto

lemma coin_integral_id :
    ∫ x, x ∂((2⁻¹ : ℝ≥0∞) • (Measure.dirac (1:ℝ) + Measure.dirac (-1))) = 0 := by
  rw [integral_smul_measure, integral_add_measure] <;>
    first | simp | exact integrable_dirac (by simp)

#print axioms coin_integral_id

lemma coin_variance :
    Var[id; (2⁻¹ : ℝ≥0∞) • (Measure.dirac (1:ℝ) + Measure.dirac (-1))] = 1 := by
  rw [variance_eq_integral aemeasurable_id]
  simp only [id_eq]
  rw [coin_integral_id]
  rw [integral_smul_measure, integral_add_measure (integrable_dirac (by simp))
    (integrable_dirac (by simp))]
  simp; norm_num

#print axioms coin_variance

lemma coin_ae_bound {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {X : Ω → ℝ}
    (h : HasLaw X ((2⁻¹ : ℝ≥0∞) • (Measure.dirac 1 + Measure.dirac (-1))) P) :
    ∀ᵐ ω ∂P, ‖X ω‖ ≤ 1 := by
  have : ∀ᵐ x ∂((2⁻¹ : ℝ≥0∞) • (Measure.dirac (1:ℝ) + Measure.dirac (-1))), ‖x‖ ≤ 1 := by
    refine Measure.ae_smul_measure ?_ _
    rw [ae_add_measure_iff]
    constructor <;> rw [ae_dirac_iff (measurableSet_le (by fun_prop) (by fun_prop))] <;> simp
  exact (h.ae_iff (p := fun x : ℝ ↦ ‖x‖ ≤ 1) (by fun_prop)).2 this

#print axioms coin_ae_bound

lemma coin_memLp {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsFiniteMeasure P] {X : Ω → ℝ}
    (h : HasLaw X ((2⁻¹ : ℝ≥0∞) • (Measure.dirac 1 + Measure.dirac (-1))) P) (p : ℝ≥0∞) :
    MemLp X p P :=
  MemLp.of_bound h.aemeasurable.aestronglyMeasurable 1 (coin_ae_bound h)

#print axioms coin_memLp

/-- **The scaled walk converges to Brownian motion at any finite set of times.**
Take fair, independent coin-toss steps `ξ k`, each `+1` or `-1` with chance one half.
Take `n` steps a second, each shrunk to one over root `n`; after `t` seconds the walk is
`S⁽ⁿ⁾_t = (ξ_1 + ⋯ + ξ_⌊n t⌋) / √n`. Then for every finite set of times `I`, the vector of
positions `(S⁽ⁿ⁾_t)_{t ∈ I}` converges in distribution, as `n → ∞`, to the vector of positions
`(B_t)_{t ∈ I}` of a Brownian motion `B` (any process whose laws at finitely many times are
those of Brownian motion). -/
theorem scaled_walk_tendsto_brownian_at_finite_times
    {Ω Ω' : Type*} [MeasurableSpace Ω] [MeasurableSpace Ω']
    {P : Measure Ω} [IsProbabilityMeasure P] {P' : Measure Ω'} [IsProbabilityMeasure P']
    (ξ : ℕ → Ω → ℝ)
    (hfair : ∀ k, HasLaw (ξ k) ((2⁻¹ : ℝ≥0∞) • (Measure.dirac 1 + Measure.dirac (-1))) P)
    (hindep : iIndepFun ξ P)
    (B : ℝ≥0 → Ω' → ℝ) (hB : IsPreBrownianReal B P')
    (I : Finset ℝ≥0) :
    TendstoInDistribution
      (fun (n : ℕ) ω (t : I) ↦ (√n)⁻¹ * ∑ k ∈ Finset.range ⌊(n : ℝ≥0) * t⌋₊, ξ k ω)
      atTop (fun ω (t : I) ↦ B t ω) (fun _ ↦ P) P' := by
  have hξm : ∀ k, AEMeasurable (ξ k) P := fun k ↦ (hfair k).aemeasurable
  have hXm : ∀ n : ℕ, AEMeasurable
      (fun ω (t : I) ↦ (√n)⁻¹ * ∑ k ∈ Finset.range ⌊(n : ℝ≥0) * t⌋₊, ξ k ω) P :=
    fun n ↦ AEMeasurable.of_eval fun t ↦
      (Finset.aemeasurable_fun_sum _ fun k _ ↦ hξm k).const_mul _
  have hL : HasLaw (fun ω ↦ WithLp.toLp 2 (fun t : I ↦ B t ω))
      (multivariateGaussian 0 (BrownianReal.covMatrix I)) P' :=
    (BrownianReal.measurePreserving_toLp_projectiveFamily I).hasLaw.comp (hB.hasLaw I)
  set T : ℝ≥0 := ∑ i : I, (i : ℝ≥0) with hT
  set N : ℕ → ℕ := fun n ↦ ⌊(n : ℝ≥0) * T⌋₊ with hN
  have hAN : ∀ (n : ℕ) (i : I), ⌊(n : ℝ≥0) * (i : ℝ≥0)⌋₊ ≤ N n := by
    intro n i
    refine Nat.floor_le_floor (mul_le_mul_right ?_ _)
    exact Finset.single_le_sum (f := fun i : I ↦ (i : ℝ≥0)) (fun _ _ ↦ zero_le)
      (Finset.mem_univ i)
  have hNT : ∀ n : ℕ, (N n : ℝ) ≤ n * (T : ℝ) := by
    intro n
    have := Nat.floor_le (zero_le (a := (n : ℝ≥0) * T))
    exact_mod_cast this
  have key : TendstoInDistribution
      (fun (n : ℕ) ω ↦ WithLp.toLp 2 (fun t : I ↦ (√n)⁻¹ * ∑ k ∈ Finset.range ⌊(n : ℝ≥0) * t⌋₊, ξ k ω))
      atTop (fun ω ↦ WithLp.toLp 2 (fun t : I ↦ B t ω)) (fun _ ↦ P) P' := by
    refine TendstoInDistribution.of_tendsto_charFun (fun n ↦ ?_) hL.aemeasurable fun u ↦ ?_
    · exact (PiLp.continuous_toLp 2 _).measurable.comp_aemeasurable (hXm n)
    rw [hL.map_eq, charFun_multivariateGaussian (BrownianReal.posSemidef_covMatrix I)]
    have hn : ∀ n : ℕ, charFun (P.map (fun ω ↦ WithLp.toLp 2
        (fun t : I ↦ (√n)⁻¹ * ∑ k ∈ Finset.range ⌊(n : ℝ≥0) * t⌋₊, ξ k ω))) u =
        ((∏ k ∈ Finset.range (N n), Real.cos ((√n)⁻¹ *
          ∑ i : I, if k < ⌊(n : ℝ≥0) * (i : ℝ≥0)⌋₊ then u i else 0) : ℝ) : ℂ) := by
      intro n
      have hXm' : AEMeasurable (fun ω ↦ WithLp.toLp 2
          (fun t : I ↦ (√n)⁻¹ * ∑ k ∈ Finset.range ⌊(n : ℝ≥0) * t⌋₊, ξ k ω)) P :=
        (PiLp.continuous_toLp 2 _).measurable.comp_aemeasurable (hXm n)
      rw [charFun_map_eq_charFun_map_inner_one hXm']
      set a : ℕ → ℝ := fun k ↦ (√n)⁻¹ *
          ∑ i : I, if k < ⌊(n : ℝ≥0) * (i : ℝ≥0)⌋₊ then u i else 0 with ha
      have hfun : (fun ω ↦ inner ℝ (WithLp.toLp 2
          (fun t : I ↦ (√n)⁻¹ * ∑ k ∈ Finset.range ⌊(n : ℝ≥0) * t⌋₊, ξ k ω)) u) =
          fun ω ↦ ∑ k ∈ Finset.range (N n), a k * ξ k ω := by
        ext ω
        simp only [PiLp.inner_apply, RCLike.inner_apply, conj_trivial]
        symm
        calc ∑ k ∈ Finset.range (N n), a k * ξ k ω
            = ∑ k ∈ Finset.range (N n), ∑ i : I,
                (if k < ⌊(n : ℝ≥0) * (i : ℝ≥0)⌋₊ then u i * ((√n)⁻¹ * ξ k ω) else 0) := by
              refine Finset.sum_congr rfl fun k _ ↦ ?_
              rw [ha]
              simp only
              rw [Finset.mul_sum, Finset.sum_mul]
              refine Finset.sum_congr rfl fun i _ ↦ ?_
              split_ifs <;> ring
          _ = ∑ i : I, ∑ k ∈ Finset.range (N n),
                (if k < ⌊(n : ℝ≥0) * (i : ℝ≥0)⌋₊ then u i * ((√n)⁻¹ * ξ k ω) else 0) :=
              Finset.sum_comm
          _ = ∑ i : I, ∑ k ∈ Finset.range ⌊(n : ℝ≥0) * (i : ℝ≥0)⌋₊, u i * ((√n)⁻¹ * ξ k ω) :=
              Finset.sum_congr rfl fun i _ ↦ sum_range_ite_lt _ (hAN n i)
          _ = _ := by
              refine Finset.sum_congr rfl fun i _ ↦ ?_
              rw [Finset.mul_sum, Finset.mul_sum]
      rw [hfun, iIndepFun.charFun_map_fun_finsetSum_eq_prod (X := fun k ω ↦ a k * ξ k ω)
        (fun k _ ↦ (hξm k).const_mul _)
        ((hindep.comp (fun k x ↦ a k * x) (fun k ↦ measurable_const_mul (a k))).restrict _),
        Finset.prod_apply, Complex.ofReal_prod]
      refine Finset.prod_congr rfl fun k _ ↦ ?_
      rw [charFun_map_mul_comp (hξm k), (hfair k).map_eq, charFun_coin, mul_one]
    simp_rw [hn]
    have := (Complex.continuous_ofReal.tendsto _).comp
      (prod_cos_tendsto (fun i : I ↦ (i : ℝ≥0)) (fun i ↦ u i) N T hAN hNT)
    have hQ : (u.ofLp ⬝ᵥ (BrownianReal.covMatrix I).mulVec u.ofLp) =
        ∑ i : I, ∑ j : I, u.ofLp i * u.ofLp j * ((min (i : ℝ≥0) (j : ℝ≥0) : ℝ≥0) : ℝ) := by
      simp only [dotProduct, Matrix.mulVec, Finset.mul_sum, BrownianReal.covMatrix_apply]
      refine Finset.sum_congr rfl fun i _ ↦ Finset.sum_congr rfl fun j _ ↦ ?_
      ring
    have hlimC : Complex.exp (↑(inner ℝ u 0) * Complex.I -
        ↑(u.ofLp ⬝ᵥ (BrownianReal.covMatrix I).mulVec u.ofLp) / 2) =
        ↑(Real.exp ((-∑ i : I, ∑ j : I, u.ofLp i * u.ofLp j *
          ((min (i : ℝ≥0) (j : ℝ≥0) : ℝ≥0) : ℝ)) / 2)) := by
      rw [inner_zero_right, hQ]
      push_cast
      ring_nf
    rw [hlimC]
    exact this
  exact key.continuous_comp (g := WithLp.ofLp) (by fun_prop)

/-- **Covariance of two positions is the earlier time.**
If `W` starts at zero, its move between times `s < t` is a bell curve `N(0, t - s)`, and its
moves over non-overlapping stretches are independent, then `Cov(W_s, W_t) = min(s, t)`. -/
theorem brownian_covariance_eq_min
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (W : ℝ≥0 → Ω → ℝ)
    (h0 : ∀ᵐ ω ∂P, W 0 ω = 0)
    (hinc : ∀ s t : ℝ≥0, s < t → HasLaw (W t - W s) (gaussianReal 0 (t - s)) P)
    (hindep : HasIndepIncrements W P)
    (s t : ℝ≥0) :
    cov[W s, W t; P] = min s t := by
  have law : ∀ t, HasLaw (W t) (gaussianReal 0 t) P := by
    intro t
    rcases eq_or_lt_of_le (zero_le (a := t)) with ht | ht
    · rw [← ht]
      rw [gaussianReal_zero_var]
      refine ⟨(aemeasurable_const (b := (0:ℝ))).congr ?_, ?_⟩
      · filter_upwards [h0] with ω hω using hω.symm
      · rw [Measure.map_congr (g := fun _ ↦ (0:ℝ)) h0]
        simp
    · have := hinc 0 t ht
      simp only [tsub_zero] at this
      refine this.congr ?_
      filter_upwards [h0] with ω hω
      simp [hω]
  exact (hindep.isPreBrownianReal_of_hasLaw law).covariance_eval s t

/-- **The scaled walk's variance equals the time, for every `n`.**
With fair, independent `±1` steps, `n ≥ 1` steps a second each of size one over root `n`, and a
time `t` at which the walk has taken a whole number `n t` of steps, the variance of the walk's
position `S⁽ⁿ⁾_t` is exactly `t`. -/
theorem scaled_walk_variance_eq_time
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ)
    (hfair : ∀ k, HasLaw (ξ k) ((2⁻¹ : ℝ≥0∞) • (Measure.dirac 1 + Measure.dirac (-1))) P)
    (hindep : iIndepFun ξ P)
    (n : ℕ) (hn : 0 < n) (t : ℝ≥0) (hgrid : ∃ m : ℕ, (n : ℝ≥0) * t = m) :
    Var[fun ω ↦ (√n)⁻¹ * ∑ k ∈ Finset.range ⌊(n : ℝ≥0) * t⌋₊, ξ k ω; P] = t := by
  obtain ⟨m, hm⟩ := hgrid
  rw [hm, Nat.floor_natCast, variance_const_mul]
  have hsum : (fun ω ↦ ∑ k ∈ Finset.range m, ξ k ω) = ∑ k ∈ Finset.range m, ξ k := by
    ext ω; simp
  rw [hsum, IndepFun.variance_sum (fun k _ ↦ coin_memLp (hfair k) 2)
    (fun i _ j _ hij ↦ hindep.indepFun hij)]
  simp only [(hfair _).variance_eq, coin_variance, Finset.sum_const, Finset.card_range,
    nsmul_eq_mul, mul_one]
  have hn' : (0:ℝ) < n := by exact_mod_cast hn
  have : (t : ℝ) = m / n := by
    rw [eq_div_iff hn'.ne', mul_comm]; exact_mod_cast hm
  rw [this, inv_pow, Real.sq_sqrt hn'.le]
  field_simp

/-! Worked examples from the card, checked exactly. -/

-- Ten fair 1 μm steps: the walk ends beyond 5 μm (height 2j - 10 ≥ 6, so j ≥ 8 heads)
-- in 56 of the 2^10 = 1024 equally likely runs.
example : (∑ j ∈ (Finset.range 11).filter (fun j : ℕ => (6 : ℤ) ≤ 2 * (j : ℤ) - 10), Nat.choose 10 j) = 56 := by
  decide
example : 2 ^ 10 = 1024 := by norm_num

-- The chart's centre bar: the walk is back at 0 after ten steps in 252 of 1024 runs.
example : Nat.choose 10 5 = 252 := by decide

-- Ten fair 1 μm steps have variance 10: the sum of C(10, j) (2j - 10)^2 is 10 · 2^10.
example : (∑ j ∈ Finset.range 11, (Nat.choose 10 j : ℤ) * (2 * j - 10) ^ 2) = 10 * 2 ^ 10 := by
  decide

-- Covariance of the 4 s and 10 s positions is the earlier time, 4.
example : min (4 : ℝ≥0) 10 = 4 := by norm_num

-- Steps of 1/n instead of 1/√n at n = 100: 1000 steps of 1/100 μm give variance 1/10.
example : (1000 : ℚ) * (1 / 100) ^ 2 = 1 / 10 := by norm_num

#print axioms scaled_walk_tendsto_brownian_at_finite_times
#print axioms brownian_covariance_eq_min
#print axioms scaled_walk_variance_eq_time
