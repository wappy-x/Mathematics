-- Fractional integration: the Riesz potential of order α in n dimensions takes L^p to L^q exactly when 1/q = 1/p − α/n with 1 < p < n/α, and with α = 1 in space this gives the Sobolev embedding.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Covering.Vitali
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Measure.Haar.NormedSpace
import Mathlib.MeasureTheory.Constructions.HaarToSphere
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Group.LIntegral
import Mathlib.Analysis.Calculus.ContDiff.Basic

open MeasureTheory Filter Topology
open scoped NNReal ENNReal

/-! ### How the card's objects are written here

Space with `n` dimensions is `EuclideanSpace ℝ (Fin n)`, with the usual distance `‖x - y‖` and
its usual volume (Lebesgue measure). A source is a real function `f` on it.

The card's Riesz potential of order `α`, with no constant in front, is
`I_α f (x) = ∫ f(y) / ‖x - y‖ ^ (n - α) dy`.

The `p`-norm `‖f‖_p` is Mathlib's `eLpNorm f p`, a value in `[0, ∞]`, so a norm that is
infinite is allowed and nothing needs to be assumed finite. "`f` is in `L^p`" is `MemLp f p`.
The exponents `p` and `q` are real numbers, passed to `eLpNorm` as `ENNReal.ofReal p`. -/

/-- The card's Riesz potential of order `α` in `n` dimensions:
`I_α f (x) = ∫ f(y) / |x - y| ^ (n - α) dy`. -/
noncomputable def rieszPotential (n : ℕ) (α : ℝ) (f : EuclideanSpace ℝ (Fin n) → ℝ)
    (x : EuclideanSpace ℝ (Fin n)) : ℝ :=
  ∫ y, f y / ‖x - y‖ ^ ((n : ℝ) - α)

section hlsHelpers

open Metric Set


/-- Dyadic maximal function. -/
noncomputable def hlsMax {n : ℕ} (g : EuclideanSpace ℝ (Fin n) → ℝ≥0∞)
    (x : EuclideanSpace ℝ (Fin n)) : ℝ≥0∞ :=
  ⨆ k : ℤ, (∫⁻ y in ball x ((2:ℝ) ^ k), g y) / volume (ball x ((2:ℝ) ^ k))

lemma hls_measurable_setLIntegral_ball {n : ℕ} {g : EuclideanSpace ℝ (Fin n) → ℝ≥0∞}
    (hg : Measurable g) (r : ℝ) :
    Measurable (fun x : EuclideanSpace ℝ (Fin n) => ∫⁻ y in ball x r, g y) := by
  have : (fun x : EuclideanSpace ℝ (Fin n) => ∫⁻ y in ball x r, g y) = fun x =>
      ∫⁻ y, ({p : EuclideanSpace ℝ (Fin n) × EuclideanSpace ℝ (Fin n) | dist p.2 p.1 < r}.indicator
        (fun p => g p.2)) (x, y) := by
    ext x
    rw [← lintegral_indicator measurableSet_ball]
    rfl
  rw [this]
  exact Measurable.lintegral_prod_right' ((hg.comp measurable_snd).indicator
    (measurableSet_lt (measurable_snd.dist measurable_fst) measurable_const))

lemma hls_measurable_max {n : ℕ} {g : EuclideanSpace ℝ (Fin n) → ℝ≥0∞} (hg : Measurable g) :
    Measurable (hlsMax g) := by
  unfold hlsMax
  refine Measurable.iSup fun k => ?_
  simp_rw [Measure.addHaar_ball_center]
  exact (hls_measurable_setLIntegral_ball hg _).div_const _

lemma hls_setLIntegral_le_max {n : ℕ} (g : EuclideanSpace ℝ (Fin n) → ℝ≥0∞)
    (x : EuclideanSpace ℝ (Fin n)) (k : ℤ) :
    ∫⁻ y in ball x ((2:ℝ) ^ k), g y ≤ volume (ball x ((2:ℝ) ^ k)) * hlsMax g x := by
  have h0 : volume (ball x ((2:ℝ) ^ k)) ≠ 0 := (measure_ball_pos _ _ (by positivity)).ne'
  have h1 : volume (ball x ((2:ℝ) ^ k)) ≠ ∞ := measure_ball_lt_top.ne
  rw [mul_comm, ← ENNReal.div_le_iff_le_mul (Or.inl h0) (Or.inl h1)]
  exact le_iSup (fun k : ℤ => (∫⁻ y in ball x ((2:ℝ) ^ k), g y) / volume (ball x ((2:ℝ) ^ k))) k

/-- Weak (1,1) bound. -/
lemma hls_weak_max {n : ℕ} {g : EuclideanSpace ℝ (Fin n) → ℝ≥0∞} (hg : Measurable g)
    (t : ℝ≥0∞) :
    t * volume {x | t < hlsMax g x} ≤ ENNReal.ofReal ((5:ℝ) ^ n) * ∫⁻ y, g y := by
  set avg : ℤ → EuclideanSpace ℝ (Fin n) → ℝ≥0∞ := fun k x =>
    (∫⁻ y in ball x ((2:ℝ) ^ k), g y) / volume (ball x ((2:ℝ) ^ k)) with havg
  set S : ℕ → Set (EuclideanSpace ℝ (Fin n)) := fun N => {x | ∃ k : ℤ, k ≤ N ∧ t < avg k x}
  have hU : {x | t < hlsMax g x} = ⋃ N, S N := by
    ext x
    simp only [mem_ofPred_eq, mem_iUnion, hlsMax, lt_iSup_iff, S]
    constructor
    · rintro ⟨k, hk⟩
      exact ⟨k.toNat, k, Int.self_le_toNat k, hk⟩
    · rintro ⟨N, k, -, hk⟩
      exact ⟨k, hk⟩
  have hmono : Monotone S := by
    intro N M hNM x hx
    obtain ⟨k, hk, h⟩ := hx
    exact ⟨k, hk.trans (by exact_mod_cast hNM), h⟩
  rw [hU, hmono.measure_iUnion, ENNReal.mul_iSup]
  refine iSup_le fun N => ?_
  -- Vitali on the family of balls
  set T : Set (EuclideanSpace ℝ (Fin n) × ℤ) := {p | p.2 ≤ N ∧ t < avg p.2 p.1}
  obtain ⟨u, huT, hdisj, hcov⟩ := Vitali.exists_disjoint_subfamily_covering_enlargement_ball T
    (fun p => p.1) (fun p => (2:ℝ) ^ p.2) ((2:ℝ) ^ (N:ℤ))
    (fun a ha => zpow_le_zpow_right₀ (by norm_num) ha.1) 5 (by norm_num)
  have hucount : u.Countable := hdisj.countable_of_isOpen (fun _ _ => isOpen_ball)
    (fun a _ => nonempty_ball.2 (by positivity))
  have hsub : S N ⊆ ⋃ b ∈ u, ball b.1 (5 * (2:ℝ) ^ b.2) := by
    rintro x ⟨k, hk, h⟩
    obtain ⟨b, hb, hsb⟩ := hcov (x, k) ⟨hk, h⟩
    exact mem_biUnion hb (hsb (mem_ball_self (by positivity)))
  have hball : ∀ b ∈ u, t * volume (ball b.1 ((2:ℝ) ^ b.2)) ≤ ∫⁻ y in ball b.1 ((2:ℝ) ^ b.2), g y := by
    intro b hb
    have h0 : volume (ball b.1 ((2:ℝ) ^ b.2)) ≠ 0 := (measure_ball_pos _ _ (by positivity)).ne'
    have h1 : volume (ball b.1 ((2:ℝ) ^ b.2)) ≠ ∞ := measure_ball_lt_top.ne
    have := (huT hb).2
    simp only [avg] at this
    exact (ENNReal.le_div_iff_mul_le (Or.inl h0) (Or.inl h1)).1 this.le
  have h5 : ∀ b : EuclideanSpace ℝ (Fin n) × ℤ, volume (ball b.1 (5 * (2:ℝ) ^ b.2)) =
      ENNReal.ofReal ((5:ℝ) ^ n) * volume (ball b.1 ((2:ℝ) ^ b.2)) := by
    intro b
    rw [Measure.addHaar_ball_mul_of_pos _ _ (by norm_num : (0:ℝ) < 5),
      finrank_euclideanSpace_fin, Measure.addHaar_ball_center _ b.1]
  calc t * volume (S N) ≤ t * volume (⋃ b ∈ u, ball b.1 (5 * (2:ℝ) ^ b.2)) :=
        mul_le_mul_right (measure_mono hsub) _
    _ ≤ t * ∑' b : u, volume (ball b.1.1 (5 * (2:ℝ) ^ b.1.2)) :=
        mul_le_mul_right (measure_biUnion_le _ hucount _) _
    _ = ENNReal.ofReal ((5:ℝ) ^ n) * ∑' b : u, t * volume (ball b.1.1 ((2:ℝ) ^ b.1.2)) := by
        simp_rw [h5, ← ENNReal.tsum_mul_left]
        congr 1; ext b; ring
    _ ≤ ENNReal.ofReal ((5:ℝ) ^ n) * ∑' b : u, ∫⁻ y in ball b.1.1 ((2:ℝ) ^ b.1.2), g y :=
        mul_le_mul_right (ENNReal.summable.tsum_le_tsum (fun b : u => hball b.1 b.2)
          ENNReal.summable) _
    _ = ENNReal.ofReal ((5:ℝ) ^ n) * ∫⁻ y in ⋃ b ∈ u, ball b.1 ((2:ℝ) ^ b.2), g y := by
        rw [lintegral_biUnion hucount (fun _ _ => measurableSet_ball) hdisj]
    _ ≤ ENNReal.ofReal ((5:ℝ) ^ n) * ∫⁻ y, g y :=
        mul_le_mul_right (setLIntegral_le_lintegral _ _) _

lemma hls_layer_real {p r : ℝ} (hp : 0 < p) (hr : 0 ≤ r) :
    ∫⁻ t in Ioi (0:ℝ), (Iio r).indicator (fun t => ENNReal.ofReal (t ^ (p - 1))) t =
      ENNReal.ofReal (r ^ p / p) := by
  rw [lintegral_indicator (measurableSet_Iio : MeasurableSet (Iio r)),
    Measure.restrict_restrict (measurableSet_Iio : MeasurableSet (Iio r))]
  have hset : Iio r ∩ Ioi 0 = Ioo 0 r := by
    ext t; simp [and_comm]
  rw [hset, ← ofReal_integral_eq_lintegral_ofReal]
  · rw [← integral_Ioc_eq_integral_Ioo, ← intervalIntegral.integral_of_le hr,
      integral_rpow (Or.inl (by linarith))]
    congr 1
    rw [sub_add_cancel, Real.zero_rpow hp.ne', sub_zero]
  · have := (intervalIntegral.intervalIntegrable_rpow' (a := 0) (b := r)
      (show -1 < p - 1 by linarith)).1
    exact this.mono_set Ioo_subset_Ioc_self
  · filter_upwards [ae_restrict_mem measurableSet_Ioo] with t ht
    exact Real.rpow_nonneg ht.1.le _

lemma hls_layer (a : ℝ≥0∞) {p : ℝ} (hp : 0 < p) :
    ∫⁻ t in Ioi (0:ℝ), {t : ℝ | ENNReal.ofReal t < a}.indicator
      (fun t => ENNReal.ofReal (t ^ (p - 1))) t = a ^ p / ENNReal.ofReal p := by
  have hfin : ∀ b : ℝ≥0∞, b ≠ ∞ →
      ∫⁻ t in Ioi (0:ℝ), {t : ℝ | ENNReal.ofReal t < b}.indicator
        (fun t => ENNReal.ofReal (t ^ (p - 1))) t = b ^ p / ENNReal.ofReal p := by
    intro b hb
    have h1 : ∫⁻ t in Ioi (0:ℝ), {t : ℝ | ENNReal.ofReal t < b}.indicator
        (fun t => ENNReal.ofReal (t ^ (p - 1))) t =
        ∫⁻ t in Ioi (0:ℝ), (Iio b.toReal).indicator
        (fun t => ENNReal.ofReal (t ^ (p - 1))) t := by
      refine setLIntegral_congr_fun measurableSet_Ioi (fun t ht => ?_)
      have : (ENNReal.ofReal t < b) ↔ t < b.toReal := ENNReal.ofReal_lt_iff_lt_toReal ht.le hb
      by_cases h : t < b.toReal
      · rw [indicator_of_mem (show t ∈ {t : ℝ | ENNReal.ofReal t < b} from this.2 h),
          indicator_of_mem (show t ∈ Iio b.toReal from h)]
      · rw [indicator_of_notMem (show t ∉ {t : ℝ | ENNReal.ofReal t < b} from fun h' => h (this.1 h')),
          indicator_of_notMem (show t ∉ Iio b.toReal from h)]
    rw [h1, hls_layer_real hp ENNReal.toReal_nonneg, ENNReal.ofReal_div_of_pos hp,
      ← ENNReal.ofReal_rpow_of_nonneg ENNReal.toReal_nonneg hp.le, ENNReal.ofReal_toReal hb]
  by_cases ha : a = ∞
  · subst ha
    rw [ENNReal.top_rpow_of_pos hp, ENNReal.top_div_of_ne_top ENNReal.ofReal_ne_top]
    refine ENNReal.eq_top_of_forall_nnreal_le fun M => ?_
    have hM : ((M : ℝ≥0∞)) = ENNReal.ofReal (((M:ℝ) * p) ^ (1 / p)) ^ p / ENNReal.ofReal p := by
      rw [ENNReal.ofReal_rpow_of_nonneg (by positivity) hp.le, ← Real.rpow_mul (by positivity),
        one_div_mul_cancel hp.ne', Real.rpow_one, ← ENNReal.ofReal_div_of_pos hp,
        mul_div_cancel_right₀ _ hp.ne', ENNReal.ofReal_coe_nnreal]
    have hle : ENNReal.ofReal (((M:ℝ) * p) ^ (1 / p)) ^ p / ENNReal.ofReal p ≤
        ∫⁻ t in Ioi (0:ℝ), {t : ℝ | ENNReal.ofReal t < ∞}.indicator
          (fun t => ENNReal.ofReal (t ^ (p - 1))) t := by
      rw [← hfin _ ENNReal.ofReal_ne_top]
      refine lintegral_mono fun t => ?_
      simp only [indicator]
      split_ifs <;> simp_all
    rw [hM]
    convert hle using 3
  · exact hfin a ha

lemma hls_max_split {n : ℕ} (g : EuclideanSpace ℝ (Fin n) → ℝ≥0∞) (hg : Measurable g)
    (s : ℝ≥0∞) (x : EuclideanSpace ℝ (Fin n)) :
    hlsMax g x ≤ hlsMax ({y | s < g y}.indicator g) x + s := by
  unfold hlsMax
  refine iSup_le fun k => ?_
  have h0 : volume (ball x ((2:ℝ) ^ k)) ≠ 0 := (measure_ball_pos _ _ (by positivity)).ne'
  have h1 : volume (ball x ((2:ℝ) ^ k)) ≠ ∞ := measure_ball_lt_top.ne
  have hle : ∫⁻ y in ball x ((2:ℝ) ^ k), g y ≤
      (∫⁻ y in ball x ((2:ℝ) ^ k), {y | s < g y}.indicator g y) + s * volume (ball x ((2:ℝ) ^ k)) := by
    calc ∫⁻ y in ball x ((2:ℝ) ^ k), g y ≤
        ∫⁻ y in ball x ((2:ℝ) ^ k), ({y | s < g y}.indicator g y + s) := by
          refine lintegral_mono fun y => ?_
          by_cases h : s < g y
          · rw [indicator_of_mem (show y ∈ {y | s < g y} from h)]; exact le_self_add
          · rw [indicator_of_notMem (show y ∉ {y | s < g y} from h), zero_add]; exact not_lt.1 h
      _ = _ := by
          rw [lintegral_add_right _ measurable_const, setLIntegral_const]
  rw [ENNReal.div_le_iff h0 h1]
  refine hle.trans ?_
  rw [add_mul]
  gcongr
  calc ∫⁻ y in ball x ((2:ℝ) ^ k), {y | s < g y}.indicator g y =
      (∫⁻ y in ball x ((2:ℝ) ^ k), {y | s < g y}.indicator g y) / volume (ball x ((2:ℝ) ^ k)) *
        volume (ball x ((2:ℝ) ^ k)) := (ENNReal.div_mul_cancel h0 h1).symm
    _ ≤ _ := by
      gcongr
      exact le_iSup (fun k : ℤ => (∫⁻ y in ball x ((2:ℝ) ^ k), {y | s < g y}.indicator g y) /
        volume (ball x ((2:ℝ) ^ k))) k

/-- Strong (p,p) bound for the dyadic maximal function. -/
lemma hls_strong_max {n : ℕ} {g : EuclideanSpace ℝ (Fin n) → ℝ≥0∞} (hg : Measurable g)
    {p : ℝ} (hp : 1 < p) :
    ∫⁻ x, hlsMax g x ^ p ≤ (ENNReal.ofReal p * (2 * ENNReal.ofReal ((5:ℝ) ^ n)) *
      (2 ^ (p - 1) / ENNReal.ofReal (p - 1))) * ∫⁻ x, g x ^ p := by
  have hp0 : 0 < p := by linarith
  have hp1 : 0 < p - 1 := by linarith
  set F := hlsMax g with hFdef
  have hF : Measurable F := hls_measurable_max hg
  set C5 := ENNReal.ofReal ((5:ℝ) ^ n)
  set φ : ℝ → ℝ≥0∞ := fun t => ENNReal.ofReal (t ^ (p - 1))
  have hφ : Measurable φ := ENNReal.measurable_ofReal.comp (measurable_id.pow_const _)
  have hpne : ENNReal.ofReal p ≠ 0 := by simpa using hp0
  -- step 1
  have step1 : ∫⁻ x, F x ^ p = ENNReal.ofReal p *
      ∫⁻ x, ∫⁻ t in Ioi (0:ℝ), {t : ℝ | ENNReal.ofReal t < F x}.indicator φ t := by
    rw [← lintegral_const_mul' _ _ ENNReal.ofReal_ne_top]
    refine lintegral_congr fun x => ?_
    rw [hls_layer (F x) hp0, ENNReal.mul_div_cancel hpne ENNReal.ofReal_ne_top]
  -- step 2: swap
  have hmeas1 : Measurable (Function.uncurry fun (x : EuclideanSpace ℝ (Fin n)) (t : ℝ) =>
      {t : ℝ | ENNReal.ofReal t < F x}.indicator φ t) := by
    have : Measurable ({z : EuclideanSpace ℝ (Fin n) × ℝ | ENNReal.ofReal z.2 < F z.1}.indicator
        (fun z => φ z.2)) :=
      (hφ.comp measurable_snd).indicator
        (measurableSet_lt (ENNReal.measurable_ofReal.comp measurable_snd) (hF.comp measurable_fst))
    exact this
  have step2 : ∫⁻ x, ∫⁻ t in Ioi (0:ℝ), {t : ℝ | ENNReal.ofReal t < F x}.indicator φ t =
      ∫⁻ t in Ioi (0:ℝ), φ t * volume {x | ENNReal.ofReal t < F x} := by
    rw [lintegral_lintegral_swap hmeas1.aemeasurable]
    refine lintegral_congr fun t => ?_
    have : (fun x => {t : ℝ | ENNReal.ofReal t < F x}.indicator φ t) =
        {x | ENNReal.ofReal t < F x}.indicator (fun _ => φ t) := by
      ext x; simp [indicator]
    rw [this, lintegral_indicator_const (measurableSet_lt measurable_const hF)]
  -- step 4: pointwise bound
  set g1 : ℝ → EuclideanSpace ℝ (Fin n) → ℝ≥0∞ := fun t =>
    {y | ENNReal.ofReal (t / 2) < g y}.indicator g
  have step4 : ∀ t ∈ Ioi (0:ℝ), φ t * volume {x | ENNReal.ofReal t < F x} ≤
      2 * C5 * (ENNReal.ofReal (t ^ (p - 2)) * ∫⁻ x, g1 t x) := by
    intro t ht
    have ht0 : 0 < t := ht
    set s := ENNReal.ofReal (t / 2)
    have hts : ENNReal.ofReal t = 2 * s := by
      rw [show t = 2 * (t / 2) by ring, ENNReal.ofReal_mul (by norm_num)]
      simp [s]
    have hsub : {x | ENNReal.ofReal t < F x} ⊆ {x | s < hlsMax (g1 t) x} := by
      intro x hx
      simp only [mem_setOf_eq] at hx ⊢
      by_contra hcon
      push_neg at hcon
      have := hls_max_split g hg s x
      have h2 : F x ≤ s + s := this.trans (by gcongr)
      rw [hts, two_mul] at hx
      exact absurd (hx.trans_le h2) (lt_irrefl _)
    have hweak := hls_weak_max (g := g1 t) ((hg.indicator (measurableSet_lt measurable_const hg))) s
    have hφt : φ t = 2 * ENNReal.ofReal (t ^ (p - 2)) * s := by
      simp only [φ, s]
      rw [← ENNReal.ofReal_ofNat 2, ← ENNReal.ofReal_mul (by norm_num),
        ← ENNReal.ofReal_mul (by positivity)]
      congr 1
      rw [show p - 1 = (p - 2) + 1 by ring, Real.rpow_add_one ht0.ne']
      ring
    calc φ t * volume {x | ENNReal.ofReal t < F x}
        ≤ 2 * ENNReal.ofReal (t ^ (p - 2)) * (s * volume {x | s < hlsMax (g1 t) x}) := by
          rw [hφt, mul_assoc]
          gcongr
      _ ≤ 2 * ENNReal.ofReal (t ^ (p - 2)) * (C5 * ∫⁻ x, g1 t x) := by gcongr
      _ = 2 * C5 * (ENNReal.ofReal (t ^ (p - 2)) * ∫⁻ x, g1 t x) := by ring
  -- step 5: swap back
  have hmeas2 : Measurable (Function.uncurry fun (t : ℝ) (x : EuclideanSpace ℝ (Fin n)) =>
      ENNReal.ofReal (t ^ (p - 2)) * g1 t x) := by
    have : Measurable (fun z : ℝ × EuclideanSpace ℝ (Fin n) => ENNReal.ofReal (z.1 ^ (p - 2)) *
        {z : ℝ × EuclideanSpace ℝ (Fin n) | ENNReal.ofReal (z.1 / 2) < g z.2}.indicator
          (fun z => g z.2) z) :=
      (ENNReal.measurable_ofReal.comp (measurable_fst.pow_const _)).mul
        ((hg.comp measurable_snd).indicator (measurableSet_lt
          (ENNReal.measurable_ofReal.comp (measurable_fst.div_const _)) (hg.comp measurable_snd)))
    exact this
  have step5 : ∫⁻ t in Ioi (0:ℝ), ENNReal.ofReal (t ^ (p - 2)) * ∫⁻ x, g1 t x =
      (2 ^ (p - 1) / ENNReal.ofReal (p - 1)) * ∫⁻ x, g x ^ p := by
    have : ∀ t, ENNReal.ofReal (t ^ (p - 2)) * ∫⁻ x, g1 t x =
        ∫⁻ x, ENNReal.ofReal (t ^ (p - 2)) * g1 t x := fun t =>
      (lintegral_const_mul' _ _ ENNReal.ofReal_ne_top).symm
    simp_rw [this]
    rw [lintegral_lintegral_swap hmeas2.aemeasurable, ← lintegral_const_mul' _ _ (by
      refine ENNReal.div_ne_top (ENNReal.rpow_ne_top_of_nonneg hp1.le (by simp)) ?_
      simpa using hp1)]
    refine lintegral_congr fun x => ?_
    have h1 : ∫⁻ t in Ioi (0:ℝ), ENNReal.ofReal (t ^ (p - 2)) * g1 t x =
        g x * ∫⁻ t in Ioi (0:ℝ), {t : ℝ | ENNReal.ofReal t < 2 * g x}.indicator
          (fun t => ENNReal.ofReal (t ^ ((p - 1) - 1))) t := by
      have hm : Measurable (fun t : ℝ => {t : ℝ | ENNReal.ofReal t < 2 * g x}.indicator
          (fun t => ENNReal.ofReal (t ^ (p - 1 - 1))) t) :=
        (ENNReal.measurable_ofReal.comp (measurable_id.pow_const _)).indicator
          (measurableSet_lt ENNReal.measurable_ofReal measurable_const)
      rw [← lintegral_const_mul _ hm]
      refine lintegral_congr fun t => ?_
      have hiff : ENNReal.ofReal (t / 2) < g x ↔ ENNReal.ofReal t < 2 * g x := by
        have hts : ENNReal.ofReal t = 2 * ENNReal.ofReal (t / 2) := by
          rcases le_or_gt t 0 with h | h
          · rw [ENNReal.ofReal_of_nonpos h, ENNReal.ofReal_of_nonpos (by linarith), mul_zero]
          · rw [show t = 2 * (t / 2) by ring, ENNReal.ofReal_mul (by norm_num)]
            simp
        rw [hts]
        exact (ENNReal.mul_lt_mul_iff_right (by norm_num) (by norm_num)).symm
      simp only [g1, indicator, mem_setOf_eq, hiff, show p - 1 - 1 = p - 2 by ring]
      split_ifs <;> ring
    rw [h1, hls_layer _ hp1, ENNReal.mul_rpow_of_nonneg _ _ hp1.le,
      show p = 1 + (p - 1) by ring, ENNReal.rpow_add_of_nonneg _ _ zero_le_one hp1.le,
      ENNReal.rpow_one, show 1 + (p - 1) - 1 = p - 1 by ring]
    simp only [div_eq_mul_inv]
    ring
  calc ∫⁻ x, F x ^ p = ENNReal.ofReal p * ∫⁻ t in Ioi (0:ℝ), φ t * volume {x | ENNReal.ofReal t < F x} := by
        rw [step1, step2]
    _ ≤ ENNReal.ofReal p * ∫⁻ t in Ioi (0:ℝ), 2 * C5 * (ENNReal.ofReal (t ^ (p - 2)) * ∫⁻ x, g1 t x) := by
        exact mul_le_mul_right (setLIntegral_mono' measurableSet_Ioi step4) _
    _ = ENNReal.ofReal p * (2 * C5) * ∫⁻ t in Ioi (0:ℝ), ENNReal.ofReal (t ^ (p - 2)) * ∫⁻ x, g1 t x := by
        rw [lintegral_const_mul' _ _ (ENNReal.mul_ne_top (by norm_num) ENNReal.ofReal_ne_top)]
        ring
    _ = _ := by rw [step5]; ring

/-- Pointwise dyadic shell bound for the Riesz kernel. -/
lemma hls_kernel_shell {n : ℕ} {α : ℝ} (hαn : α < n) (f : EuclideanSpace ℝ (Fin n) → ℝ)
    (x y : EuclideanSpace ℝ (Fin n)) :
    ‖f y / ‖x - y‖ ^ ((n : ℝ) - α)‖ₑ ≤ ∑' k : ℤ, (ball x ((2:ℝ) ^ (k + 1))).indicator
      (fun y => ENNReal.ofReal ((2:ℝ) ^ ((k:ℝ) * (α - n))) * ‖f y‖ₑ) y := by
  by_cases hxy : y = x
  · subst hxy
    simp [Real.zero_rpow (show (n:ℝ) - α ≠ 0 by linarith)]
  have hd : 0 < ‖x - y‖ := norm_pos_iff.2 (sub_ne_zero.2 (Ne.symm hxy))
  obtain ⟨k, hk1, hk2⟩ := exists_mem_Ico_zpow hd (by norm_num : (1:ℝ) < 2)
  refine le_trans ?_ (ENNReal.le_tsum k)
  have hmem : y ∈ ball x ((2:ℝ) ^ (k + 1)) := by
    rw [mem_ball, dist_comm, dist_eq_norm]; exact hk2
  rw [indicator_of_mem hmem, div_eq_mul_inv, enorm_mul, mul_comm]
  gcongr
  rw [Real.enorm_of_nonneg (by positivity)]
  apply ENNReal.ofReal_le_ofReal
  rw [← Real.rpow_neg hd.le, neg_sub, Real.rpow_mul (by norm_num), Real.rpow_intCast]
  exact Real.rpow_le_rpow_of_nonpos (by positivity) hk1 (by linarith)

lemma hls_kernel_integral {n : ℕ} {α : ℝ} (hαn : α < n) {f : EuclideanSpace ℝ (Fin n) → ℝ}
    (hf : Measurable f) (x : EuclideanSpace ℝ (Fin n)) :
    ∫⁻ y, ‖f y / ‖x - y‖ ^ ((n : ℝ) - α)‖ₑ ≤ ∑' k : ℤ, ENNReal.ofReal ((2:ℝ) ^ ((k:ℝ) * (α - n))) *
      ∫⁻ y in ball x ((2:ℝ) ^ (k + 1)), ‖f y‖ₑ := by
  calc ∫⁻ y, ‖f y / ‖x - y‖ ^ ((n : ℝ) - α)‖ₑ
        ≤ ∫⁻ y, ∑' k : ℤ, (ball x ((2:ℝ) ^ (k + 1))).indicator
          (fun y => ENNReal.ofReal ((2:ℝ) ^ ((k:ℝ) * (α - n))) * ‖f y‖ₑ) y :=
        lintegral_mono fun y => hls_kernel_shell hαn f x y
    _ = _ := by
      rw [lintegral_tsum]
      · congr 1; ext k
        rw [lintegral_indicator measurableSet_ball, lintegral_const_mul' _ _ ENNReal.ofReal_ne_top]
      · intro k
        exact (Measurable.indicator (by fun_prop) measurableSet_ball).aemeasurable

lemma hls_tsum_int_split (F : ℤ → ℝ≥0∞) (j : ℤ) :
    ∑' k : ℤ, F k = ∑' m : ℕ, F (j + m) + ∑' m : ℕ, F (j - 1 - m) := by
  rw [← (Equiv.addLeft j).tsum_eq, ← tsum_nat_add_neg_add_one ENNReal.summable, ENNReal.tsum_add]
  congr 2 <;> ext m <;> simp only [Equiv.coe_addLeft] <;> congr 1; ring

lemma hls_holder_ball {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → ℝ} (hf : Measurable f) {p : ℝ}
    (hp : 1 < p) (x : EuclideanSpace ℝ (Fin n)) (r : ℝ) :
    ∫⁻ y in ball x r, ‖f y‖ₑ ≤
      eLpNorm f (ENNReal.ofReal p) volume * volume (ball x r) ^ (1 - 1 / p) := by
  have h1 : (1 : ℝ≥0∞) ≤ ENNReal.ofReal p := by
    rw [← ENNReal.ofReal_one]; exact ENNReal.ofReal_le_ofReal hp.le
  have hfm : AEStronglyMeasurable f (volume.restrict (ball x r)) :=
    hf.stronglyMeasurable.aestronglyMeasurable
  have := eLpNorm_le_eLpNorm_mul_rpow_measure_univ h1 hfm
  rw [eLpNorm_one_eq_lintegral_enorm hfm, Measure.restrict_apply_univ, ENNReal.toReal_one,
    ENNReal.toReal_ofReal (by linarith), div_one] at this
  refine this.trans ?_
  gcongr
  exact Measure.restrict_le_self

lemma hls_geom (c r : ℝ) :
    ∑' m : ℕ, ENNReal.ofReal ((2:ℝ) ^ (c + m * r)) =
      ENNReal.ofReal ((2:ℝ) ^ c) * (1 - ENNReal.ofReal ((2:ℝ) ^ r))⁻¹ := by
  have : ∀ m : ℕ, ENNReal.ofReal ((2:ℝ) ^ (c + m * r)) =
      ENNReal.ofReal ((2:ℝ) ^ c) * ENNReal.ofReal ((2:ℝ) ^ r) ^ m := by
    intro m
    rw [← ENNReal.ofReal_pow (by positivity), ← ENNReal.ofReal_mul (by positivity),
      Real.rpow_add (by norm_num), mul_comm (m:ℝ) r, Real.rpow_mul (by norm_num),
      Real.rpow_natCast]
  simp_rw [this]
  rw [ENNReal.tsum_mul_left, ENNReal.tsum_geometric]

lemma hls_vol_ball {n : ℕ} (x : EuclideanSpace ℝ (Fin n)) (k : ℤ) :
    volume (ball x ((2:ℝ) ^ (k + 1))) =
      ENNReal.ofReal ((2:ℝ) ^ (((k:ℝ) + 1) * n)) * volume (ball (0 : EuclideanSpace ℝ (Fin n)) 1) := by
  rw [Measure.addHaar_ball_of_pos _ _ (by positivity), finrank_euclideanSpace_fin,
    ← Real.rpow_intCast, ← Real.rpow_natCast, ← Real.rpow_mul (by norm_num)]
  push_cast
  rfl

/-- Hedberg's bound, with a free dyadic scale `2^j`. -/
lemma hls_hedberg_j {n : ℕ} {α p : ℝ} (hα0 : 0 < α) (hαn : α < n) (hp : 1 < p)
    (hpn : p < n / α) {f : EuclideanSpace ℝ (Fin n) → ℝ} (hf : Measurable f)
    (x : EuclideanSpace ℝ (Fin n)) (j : ℤ) :
    ∫⁻ y, ‖f y / ‖x - y‖ ^ ((n : ℝ) - α)‖ₑ ≤
      volume (ball (0 : EuclideanSpace ℝ (Fin n)) 1) ^ (1 - 1 / p) *
          eLpNorm f (ENNReal.ofReal p) volume *
          (ENNReal.ofReal ((2:ℝ) ^ (n * (1 - 1 / p) + j * (α - n / p))) *
            (1 - ENNReal.ofReal ((2:ℝ) ^ (α - n / p)))⁻¹) +
        volume (ball (0 : EuclideanSpace ℝ (Fin n)) 1) * hlsMax (fun y => ‖f y‖ₑ) x *
          (ENNReal.ofReal ((2:ℝ) ^ (n + (j - 1) * α)) *
            (1 - ENNReal.ofReal ((2:ℝ) ^ (-α)))⁻¹) := by
  have hn : (0:ℝ) < n := by linarith
  have hγ : α - n / p < 0 := by
    have : α * p < n := by rwa [lt_div_iff₀ hα0, mul_comm] at hpn
    have : α < n / p := by rw [lt_div_iff₀ (by linarith)]; exact this
    linarith
  set V := volume (ball (0 : EuclideanSpace ℝ (Fin n)) 1)
  set B := eLpNorm f (ENNReal.ofReal p) volume
  set A := hlsMax (fun y => ‖f y‖ₑ) x
  set T : ℤ → ℝ≥0∞ := fun k => ENNReal.ofReal ((2:ℝ) ^ ((k:ℝ) * (α - n))) *
      ∫⁻ y in ball x ((2:ℝ) ^ (k + 1)), ‖f y‖ₑ
  have hnear : ∀ k : ℤ, T k ≤ V * A * ENNReal.ofReal ((2:ℝ) ^ (n + k * α)) := by
    intro k
    calc T k ≤ ENNReal.ofReal ((2:ℝ) ^ ((k:ℝ) * (α - n))) *
          (volume (ball x ((2:ℝ) ^ (k + 1))) * A) := by
          simp only [T]
          gcongr
          exact hls_setLIntegral_le_max _ x (k + 1)
      _ = V * A * ENNReal.ofReal ((2:ℝ) ^ (n + k * α)) := by
          rw [hls_vol_ball]
          have : ENNReal.ofReal ((2:ℝ) ^ ((k:ℝ) * (α - n))) *
              ENNReal.ofReal ((2:ℝ) ^ (((k:ℝ) + 1) * n)) = ENNReal.ofReal ((2:ℝ) ^ (n + k * α)) := by
            rw [← ENNReal.ofReal_mul (by positivity), ← Real.rpow_add (by norm_num)]
            congr 2; ring
          rw [← this]; ring
  have hfar : ∀ k : ℤ, T k ≤ V ^ (1 - 1 / p) * B *
      ENNReal.ofReal ((2:ℝ) ^ (n * (1 - 1 / p) + k * (α - n / p))) := by
    intro k
    have hq : 0 ≤ 1 - 1 / p := by
      have : 1 / p < 1 := by rw [div_lt_one (by linarith)]; exact hp
      linarith
    calc T k ≤ ENNReal.ofReal ((2:ℝ) ^ ((k:ℝ) * (α - n))) *
          (B * volume (ball x ((2:ℝ) ^ (k + 1))) ^ (1 - 1 / p)) := by
          simp only [T]
          gcongr
          exact hls_holder_ball hf hp x _
      _ = V ^ (1 - 1 / p) * B *
          ENNReal.ofReal ((2:ℝ) ^ (n * (1 - 1 / p) + k * (α - n / p))) := by
          rw [hls_vol_ball, ENNReal.mul_rpow_of_nonneg _ _ hq,
            ENNReal.ofReal_rpow_of_nonneg (by positivity) hq, ← Real.rpow_mul (by norm_num)]
          have : ENNReal.ofReal ((2:ℝ) ^ ((k:ℝ) * (α - n))) *
              ENNReal.ofReal ((2:ℝ) ^ (((k:ℝ) + 1) * n * (1 - 1 / p))) =
              ENNReal.ofReal ((2:ℝ) ^ (n * (1 - 1 / p) + k * (α - n / p))) := by
            rw [← ENNReal.ofReal_mul (by positivity), ← Real.rpow_add (by norm_num)]
            congr 2
            field_simp
            ring
          rw [← this]; ring
  calc ∫⁻ y, ‖f y / ‖x - y‖ ^ ((n : ℝ) - α)‖ₑ ≤ ∑' k : ℤ, T k := hls_kernel_integral hαn hf x
    _ = ∑' m : ℕ, T (j + m) + ∑' m : ℕ, T (j - 1 - m) := hls_tsum_int_split T j
    _ ≤ ∑' m : ℕ, V ^ (1 - 1 / p) * B *
          ENNReal.ofReal ((2:ℝ) ^ (n * (1 - 1 / p) + ((j + m : ℤ) : ℝ) * (α - n / p))) +
        ∑' m : ℕ, V * A * ENNReal.ofReal ((2:ℝ) ^ (n + ((j - 1 - m : ℤ) : ℝ) * α)) := by
          gcongr with m m
          · exact hfar _
          · exact hnear _
    _ = _ := by
      rw [ENNReal.tsum_mul_left, ENNReal.tsum_mul_left]
      congr 2
      · rw [← hls_geom _ _]
        congr 1; ext m; congr 2; push_cast; ring
      · rw [← hls_geom _ _]
        congr 1; ext m; congr 2; push_cast; ring

lemma hls_cross {n α p a b : ℝ} (hn : 0 < n) (hα0 : 0 < α) (hp : 0 < p) (hγ : α - n / p < 0)
    (ha : 0 < a) (hb : 0 < b) : ∃ j : ℤ,
    (2:ℝ) ^ ((j:ℝ) * α) * a ≤ a ^ (1 - α * p / n) * b ^ (α * p / n) ∧
    (2:ℝ) ^ ((j:ℝ) * (α - n / p)) * b ≤
      (2:ℝ) ^ (-(α - n / p)) * (a ^ (1 - α * p / n) * b ^ (α * p / n)) := by
  set s := (b / a) ^ (p / n) with hs
  have hs0 : 0 < s := by positivity
  obtain ⟨j, hj1, hj2⟩ := exists_mem_Ico_zpow hs0 (by norm_num : (1:ℝ) < 2)
  refine ⟨j, ?_, ?_⟩
  · have hT : (2:ℝ) ^ ((j:ℝ) * α) ≤ s ^ α := by
      rw [Real.rpow_mul (by norm_num), Real.rpow_intCast]
      exact Real.rpow_le_rpow (by positivity) hj1 hα0.le
    have hid : s ^ α * a = a ^ (1 - α * p / n) * b ^ (α * p / n) := by
      rw [hs, ← Real.rpow_mul (by positivity), Real.div_rpow hb.le ha.le,
        show p / n * α = α * p / n by ring, Real.rpow_sub ha, Real.rpow_one]
      field_simp
    calc (2:ℝ) ^ ((j:ℝ) * α) * a ≤ s ^ α * a := by gcongr
      _ = _ := hid
  · have hT : (2:ℝ) ^ ((j:ℝ) * (α - n / p)) ≤ (2:ℝ) ^ (-(α - n / p)) * s ^ (α - n / p) := by
      rw [Real.rpow_mul (by norm_num), Real.rpow_intCast]
      have h2 : s / 2 ≤ (2:ℝ) ^ j := by
        rw [zpow_add_one₀ (by norm_num)] at hj2; linarith
      calc ((2:ℝ) ^ j) ^ (α - n / p) ≤ (s / 2) ^ (α - n / p) :=
            Real.rpow_le_rpow_of_nonpos (by positivity) h2 hγ.le
        _ = (2:ℝ) ^ (-(α - n / p)) * s ^ (α - n / p) := by
            rw [Real.div_rpow hs0.le (by norm_num), Real.rpow_neg (by norm_num)]
            ring
    have hid : s ^ (α - n / p) * b = a ^ (1 - α * p / n) * b ^ (α * p / n) := by
      rw [hs, ← Real.rpow_mul (by positivity), Real.div_rpow hb.le ha.le,
        show p / n * (α - n / p) = α * p / n - 1 by field_simp,
        show (1 : ℝ) - α * p / n = -(α * p / n - 1) by ring, Real.rpow_neg ha.le,
        show b ^ (α * p / n) = b ^ (α * p / n - 1) * b by
          rw [← Real.rpow_add_one hb.ne']; ring_nf]
      field_simp
    calc (2:ℝ) ^ ((j:ℝ) * (α - n / p)) * b ≤ (2:ℝ) ^ (-(α - n / p)) * s ^ (α - n / p) * b := by
          gcongr
      _ = _ := by rw [mul_assoc, hid]

/-- The constant in Hedberg's pointwise bound. -/
noncomputable def hlsK (n : ℕ) (α p : ℝ) : ℝ≥0∞ :=
  volume (ball (0 : EuclideanSpace ℝ (Fin n)) 1) ^ (1 - 1 / p) *
      ENNReal.ofReal ((2:ℝ) ^ (n * (1 - 1 / p))) * (1 - ENNReal.ofReal ((2:ℝ) ^ (α - n / p)))⁻¹ *
      ENNReal.ofReal ((2:ℝ) ^ (-(α - n / p))) +
    volume (ball (0 : EuclideanSpace ℝ (Fin n)) 1) * ENNReal.ofReal ((2:ℝ) ^ ((n:ℝ) - α)) *
      (1 - ENNReal.ofReal ((2:ℝ) ^ (-α)))⁻¹

lemma hlsK_ne_zero (n : ℕ) (α p : ℝ) : hlsK n α p ≠ 0 := by
  unfold hlsK
  intro h
  have h2 := (add_eq_zero.1 h).2
  simp only [mul_eq_zero, ENNReal.inv_eq_zero, ENNReal.ofReal_eq_zero] at h2
  rcases h2 with (h | h) | h
  · exact (measure_ball_pos volume _ one_pos).ne' h
  · exact absurd h (not_le.2 (by positivity))
  · exact ENNReal.sub_ne_top ENNReal.one_ne_top h

lemma hlsK_ne_top (n : ℕ) {α p : ℝ} (hα0 : 0 < α) (hγ : α - n / p < 0) : hlsK n α p ≠ ∞ := by
  have hlt : ∀ r : ℝ, r < 0 → (1 - ENNReal.ofReal ((2:ℝ) ^ r))⁻¹ ≠ ∞ := by
    intro r hr
    rw [ENNReal.inv_ne_top]
    exact (tsub_pos_iff_lt.2 (ENNReal.ofReal_lt_one.2
      (Real.rpow_lt_one_of_one_lt_of_neg (by norm_num) hr))).ne'
  unfold hlsK
  refine ENNReal.add_ne_top.2 ⟨?_, ?_⟩
  · refine ENNReal.mul_ne_top (ENNReal.mul_ne_top (ENNReal.mul_ne_top ?_ ENNReal.ofReal_ne_top)
      (hlt _ hγ)) ENNReal.ofReal_ne_top
    exact ENNReal.rpow_ne_top_of_ne_zero (measure_ball_pos volume _ one_pos).ne'
      measure_ball_lt_top.ne
  · exact ENNReal.mul_ne_top (ENNReal.mul_ne_top measure_ball_lt_top.ne ENNReal.ofReal_ne_top)
      (hlt _ (by linarith))

/-- Hedberg's pointwise bound. -/
lemma hls_hedberg {n : ℕ} {α p : ℝ} (hα0 : 0 < α) (hαn : α < n) (hp : 1 < p)
    (hpn : p < n / α) {f : EuclideanSpace ℝ (Fin n) → ℝ} (hf : Measurable f)
    (x : EuclideanSpace ℝ (Fin n)) (hA0 : hlsMax (fun y => ‖f y‖ₑ) x ≠ 0)
    (hB0 : eLpNorm f (ENNReal.ofReal p) volume ≠ 0) (hBt : eLpNorm f (ENNReal.ofReal p) volume ≠ ∞) :
    ∫⁻ y, ‖f y / ‖x - y‖ ^ ((n : ℝ) - α)‖ₑ ≤
      hlsK n α p * (hlsMax (fun y => ‖f y‖ₑ) x ^ (1 - α * p / n) *
        eLpNorm f (ENNReal.ofReal p) volume ^ (α * p / n)) := by
  have hn : (0:ℝ) < n := by linarith
  have hp0 : 0 < p := by linarith
  have hαp : α * p < n := by rwa [lt_div_iff₀ hα0, mul_comm] at hpn
  have hγ : α - n / p < 0 := by
    have : α < n / p := by rw [lt_div_iff₀ hp0]; exact hαp
    linarith
  have hθ : 0 < 1 - α * p / n := by
    have : α * p / n < 1 := by rw [div_lt_one hn]; exact hαp
    linarith
  have he : 0 < α * p / n := by positivity
  set A := hlsMax (fun y => ‖f y‖ₑ) x with hAdef
  set B := eLpNorm f (ENNReal.ofReal p) volume with hBdef
  set V := volume (ball (0 : EuclideanSpace ℝ (Fin n)) 1)
  by_cases hAt : A = ∞
  · have : A ^ (1 - α * p / n) = ∞ := by rw [hAt]; exact ENNReal.top_rpow_of_pos hθ
    rw [this, ENNReal.top_mul (ENNReal.rpow_pos (pos_iff_ne_zero.2 hB0) hBt).ne',
      ENNReal.mul_top (hlsK_ne_zero n α p)]
    exact le_top
  set a := A.toReal
  set b := B.toReal
  have ha : 0 < a := ENNReal.toReal_pos hA0 hAt
  have hb : 0 < b := ENNReal.toReal_pos hB0 hBt
  obtain ⟨j, hj1, hj2⟩ := hls_cross hn hα0 hp0 hγ ha hb
  set X := a ^ (1 - α * p / n) * b ^ (α * p / n)
  have hX : ENNReal.ofReal X = A ^ (1 - α * p / n) * B ^ (α * p / n) := by
    rw [ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_rpow_of_pos ha,
      ← ENNReal.ofReal_rpow_of_pos hb, ENNReal.ofReal_toReal hAt, ENNReal.ofReal_toReal hBt]
  have h1 : ENNReal.ofReal ((2:ℝ) ^ (n * (1 - 1 / p) + j * (α - n / p))) * B =
      ENNReal.ofReal ((2:ℝ) ^ (n * (1 - 1 / p))) *
        ENNReal.ofReal ((2:ℝ) ^ ((j:ℝ) * (α - n / p)) * b) := by
    rw [← ENNReal.ofReal_toReal hBt, ← ENNReal.ofReal_mul (by positivity),
      ← ENNReal.ofReal_mul (by positivity), Real.rpow_add (by norm_num)]
    congr 1; ring
  have h2 : ENNReal.ofReal ((2:ℝ) ^ (n + (j - 1) * α)) * A =
      ENNReal.ofReal ((2:ℝ) ^ ((n:ℝ) - α)) * ENNReal.ofReal ((2:ℝ) ^ ((j:ℝ) * α) * a) := by
    rw [← ENNReal.ofReal_toReal hAt, ← ENNReal.ofReal_mul (by positivity),
      ← ENNReal.ofReal_mul (by positivity), ← mul_assoc, ← Real.rpow_add (by norm_num)]
    congr 3; ring
  calc ∫⁻ y, ‖f y / ‖x - y‖ ^ ((n : ℝ) - α)‖ₑ
      ≤ V ^ (1 - 1 / p) * B * (ENNReal.ofReal ((2:ℝ) ^ (n * (1 - 1 / p) + j * (α - n / p))) *
            (1 - ENNReal.ofReal ((2:ℝ) ^ (α - n / p)))⁻¹) +
        V * A * (ENNReal.ofReal ((2:ℝ) ^ (n + (j - 1) * α)) *
            (1 - ENNReal.ofReal ((2:ℝ) ^ (-α)))⁻¹) := hls_hedberg_j hα0 hαn hp hpn hf x j
    _ = V ^ (1 - 1 / p) * (1 - ENNReal.ofReal ((2:ℝ) ^ (α - n / p)))⁻¹ *
          (ENNReal.ofReal ((2:ℝ) ^ (n * (1 - 1 / p) + j * (α - n / p))) * B) +
        V * (1 - ENNReal.ofReal ((2:ℝ) ^ (-α)))⁻¹ *
          (ENNReal.ofReal ((2:ℝ) ^ (n + (j - 1) * α)) * A) := by ring
    _ = V ^ (1 - 1 / p) * (1 - ENNReal.ofReal ((2:ℝ) ^ (α - n / p)))⁻¹ *
          (ENNReal.ofReal ((2:ℝ) ^ (n * (1 - 1 / p))) *
            ENNReal.ofReal ((2:ℝ) ^ ((j:ℝ) * (α - n / p)) * b)) +
        V * (1 - ENNReal.ofReal ((2:ℝ) ^ (-α)))⁻¹ *
          (ENNReal.ofReal ((2:ℝ) ^ ((n:ℝ) - α)) * ENNReal.ofReal ((2:ℝ) ^ ((j:ℝ) * α) * a)) := by
        rw [h1, h2]
    _ ≤ V ^ (1 - 1 / p) * (1 - ENNReal.ofReal ((2:ℝ) ^ (α - n / p)))⁻¹ *
          (ENNReal.ofReal ((2:ℝ) ^ (n * (1 - 1 / p))) *
            ENNReal.ofReal ((2:ℝ) ^ (-(α - n / p)) * X)) +
        V * (1 - ENNReal.ofReal ((2:ℝ) ^ (-α)))⁻¹ *
          (ENNReal.ofReal ((2:ℝ) ^ ((n:ℝ) - α)) * ENNReal.ofReal X) := by
        gcongr
    _ = hlsK n α p * (A ^ (1 - α * p / n) * B ^ (α * p / n)) := by
        rw [ENNReal.ofReal_mul (by positivity), hX, hlsK]
        ring

/-- The constant of the strong maximal bound. -/
noncomputable def hlsCm (n : ℕ) (p : ℝ) : ℝ≥0∞ :=
  ENNReal.ofReal p * (2 * ENNReal.ofReal ((5:ℝ) ^ n)) * (2 ^ (p - 1) / ENNReal.ofReal (p - 1))

lemma hlsCm_ne_top (n : ℕ) {p : ℝ} (hp : 1 < p) : hlsCm n p ≠ ∞ := by
  unfold hlsCm
  refine ENNReal.mul_ne_top (ENNReal.mul_ne_top ENNReal.ofReal_ne_top
    (ENNReal.mul_ne_top (by norm_num) ENNReal.ofReal_ne_top)) ?_
  refine ENNReal.div_ne_top (ENNReal.rpow_ne_top_of_nonneg (by linarith) (by norm_num)) ?_
  simp only [ne_eq, ENNReal.ofReal_eq_zero, not_le]; linarith

lemma hls_measurable_kernel {n : ℕ} {α : ℝ} {f : EuclideanSpace ℝ (Fin n) → ℝ} (hf : Measurable f) :
    Measurable (fun z : EuclideanSpace ℝ (Fin n) × EuclideanSpace ℝ (Fin n) =>
      f z.2 / ‖z.1 - z.2‖ ^ ((n : ℝ) - α)) := by
  fun_prop

lemma hls_aesm_riesz {n : ℕ} {α : ℝ} {f : EuclideanSpace ℝ (Fin n) → ℝ} (hf : Measurable f) :
    AEStronglyMeasurable (rieszPotential n α f) volume :=
  ((hls_measurable_kernel (α := α) hf).stronglyMeasurable.integral_prod_right'
    (ν := volume)).aestronglyMeasurable

lemma hls_main_of_measurable {n : ℕ} {α p q : ℝ} (hα0 : 0 < α) (hαn : α < n) (hp1 : 1 < p)
    (hpn : p < n / α) (hq : 1 / q = 1 / p - α / n) {f : EuclideanSpace ℝ (Fin n) → ℝ}
    (hf : Measurable f) (hBt : eLpNorm f (ENNReal.ofReal p) volume ≠ ∞) :
    (∀ᵐ x, Integrable (fun y => f y / ‖x - y‖ ^ ((n : ℝ) - α))) ∧
      eLpNorm (rieszPotential n α f) (ENNReal.ofReal q) ≤
        hlsK n α p * hlsCm n p ^ (1 / q) * eLpNorm f (ENNReal.ofReal p) := by
  have hn : (0:ℝ) < n := by linarith
  have hp0 : 0 < p := by linarith
  have hαp : α * p < n := by rwa [lt_div_iff₀ hα0, mul_comm] at hpn
  have hθq : (1 - α * p / n) * q = p := by
    have h1 : 1 - α * p / n = p * (1 / q) := by rw [hq]; field_simp
    have hq0 : q ≠ 0 := by
      intro h; rw [h, div_zero] at hq
      have : α / n < 1 / p := by
        rw [div_lt_div_iff₀ hn hp0]; linarith
      linarith
    rw [h1]; field_simp
  have hq0 : 0 < q := by
    have : 0 < 1 - α * p / n := by
      have : α * p / n < 1 := by rw [div_lt_one hn]; exact hαp
      linarith
    nlinarith
  have heq : α * p / n * q + p = q := by nlinarith
  set B := eLpNorm f (ENNReal.ofReal p) volume with hBdef
  have hint_meas : ∀ x, AEStronglyMeasurable (fun y => f y / ‖x - y‖ ^ ((n : ℝ) - α)) volume :=
    fun x => (by fun_prop : Measurable (fun y => f y / ‖x - y‖ ^ ((n : ℝ) - α))).aestronglyMeasurable
  have hpne : ENNReal.ofReal p ≠ 0 := by simpa using hp0
  by_cases hB0 : B = 0
  · have hf0 : f =ᵐ[volume] 0 := (eLpNorm_eq_zero_iff hpne).1 hB0
    have hz : ∀ x, (fun y => f y / ‖x - y‖ ^ ((n : ℝ) - α)) =ᵐ[volume] 0 := by
      intro x
      filter_upwards [hf0] with y hy
      simp [hy]
    have hR : rieszPotential n α f = 0 := by
      funext x
      exact integral_eq_zero_of_ae (hz x)
    refine ⟨Filter.Eventually.of_forall fun x => (integrable_zero _ _ _).congr (hz x).symm, ?_⟩
    rw [hR, eLpNorm_zero]
    exact zero_le
  set g : EuclideanSpace ℝ (Fin n) → ℝ≥0∞ := fun y => ‖f y‖ₑ
  have hg : Measurable g := hf.enorm
  set A := hlsMax g
  have hA : Measurable A := hls_measurable_max hg
  -- A never vanishes
  have hA0 : ∀ x, A x ≠ 0 := by
    intro x hx
    have hcover : (univ : Set (EuclideanSpace ℝ (Fin n))) = ⋃ k : ℤ, ball x ((2:ℝ) ^ k) := by
      ext y
      simp only [mem_univ, mem_iUnion, mem_ball, true_iff]
      obtain ⟨m, hm⟩ := pow_unbounded_of_one_lt (dist y x) (by norm_num : (1:ℝ) < 2)
      exact ⟨m, by rw [zpow_natCast]; exact hm⟩
    have h0 : ∫⁻ y, g y = 0 := by
      rw [← setLIntegral_univ, hcover]
      refine le_antisymm ((lintegral_iUnion_le _ _).trans ?_) (zero_le)
      refine le_of_eq (ENNReal.tsum_eq_zero.2 fun k => le_antisymm ?_ (zero_le))
      exact (hls_setLIntegral_le_max g x k).trans (by simp [A] at hx; simp [hx])
    have : f =ᵐ[volume] 0 := by
      filter_upwards [(lintegral_eq_zero_iff hg).1 h0] with y hy
      simpa [g] using hy
    exact hB0 ((eLpNorm_congr_ae this).trans eLpNorm_zero)
  have hHed : ∀ x, ∫⁻ y, ‖f y / ‖x - y‖ ^ ((n : ℝ) - α)‖ₑ ≤
      hlsK n α p * (A x ^ (1 - α * p / n) * B ^ (α * p / n)) :=
    fun x => hls_hedberg hα0 hαn hp1 hpn hf x (hA0 x) hB0 hBt
  have hgp : ∫⁻ x, g x ^ p = B ^ p := by
    rw [hBdef, eLpNorm_eq_eLpNorm' hpne ENNReal.ofReal_ne_top hf.aestronglyMeasurable,
      ENNReal.toReal_ofReal hp0.le]
    exact lintegral_rpow_enorm_eq_rpow_eLpNorm' hp0
  have hAp : ∫⁻ x, A x ^ p ≤ hlsCm n p * B ^ p := by
    rw [← hgp]; exact hls_strong_max hg hp1
  have hAfin : ∀ᵐ x, A x < ∞ := by
    have hne : ∫⁻ x, A x ^ p ≠ ∞ := ne_top_of_le_ne_top
      (ENNReal.mul_ne_top (hlsCm_ne_top n hp1) (ENNReal.rpow_ne_top_of_nonneg hp0.le hBt)) hAp
    filter_upwards [ae_lt_top (hA.pow_const p) hne] with x hx
    by_contra h
    rw [not_lt, top_le_iff] at h
    rw [h, ENNReal.top_rpow_of_pos hp0] at hx
    exact lt_irrefl _ hx
  refine ⟨?_, ?_⟩
  · filter_upwards [hAfin] with x hx
    refine ⟨hint_meas x, ?_⟩
    refine (hHed x).trans_lt ?_
    refine ENNReal.mul_lt_top (lt_top_iff_ne_top.2 (hlsK_ne_top n hα0 ?_)) (ENNReal.mul_lt_top ?_ ?_)
    · have : α < n / p := by rw [lt_div_iff₀ hp0]; exact hαp
      linarith
    · exact ENNReal.rpow_lt_top_of_nonneg (by
        have : α * p / n < 1 := by rw [div_lt_one hn]; exact hαp
        linarith) hx.ne
    · exact ENNReal.rpow_lt_top_of_nonneg (by positivity) hBt
  · have hqne : ENNReal.ofReal q ≠ 0 := by simpa using hq0
    rw [eLpNorm_eq_lintegral_rpow_enorm_toReal hqne ENNReal.ofReal_ne_top (hls_aesm_riesz hf),
      ENNReal.toReal_ofReal hq0.le]
    set K := hlsK n α p
    have hKt : K ≠ ∞ := hlsK_ne_top n hα0 (by
      have : α < n / p := by rw [lt_div_iff₀ hp0]; exact hαp
      linarith)
    have hpt : ∀ x, ‖rieszPotential n α f x‖ₑ ^ q ≤
        K ^ q * B ^ (α * p / n * q) * A x ^ p := by
      intro x
      calc ‖rieszPotential n α f x‖ₑ ^ q ≤ (K * (A x ^ (1 - α * p / n) * B ^ (α * p / n))) ^ q := by
            gcongr
            exact (enorm_integral_le_lintegral_enorm _).trans (hHed x)
        _ = K ^ q * B ^ (α * p / n * q) * A x ^ p := by
            rw [ENNReal.mul_rpow_of_nonneg _ _ hq0.le, ENNReal.mul_rpow_of_nonneg _ _ hq0.le,
              ← ENNReal.rpow_mul, ← ENNReal.rpow_mul, hθq]
            ring
    calc (∫⁻ x, ‖rieszPotential n α f x‖ₑ ^ q) ^ (1 / q)
        ≤ (∫⁻ x, K ^ q * B ^ (α * p / n * q) * A x ^ p) ^ (1 / q) := by
          gcongr with x
          exact hpt x
      _ = (K ^ q * B ^ (α * p / n * q) * ∫⁻ x, A x ^ p) ^ (1 / q) := by
          rw [lintegral_const_mul' _ _ (ENNReal.mul_ne_top
            (ENNReal.rpow_ne_top_of_nonneg hq0.le hKt)
            (ENNReal.rpow_ne_top_of_nonneg (by positivity) hBt))]
      _ ≤ (K ^ q * B ^ (α * p / n * q) * (hlsCm n p * B ^ p)) ^ (1 / q) := by
          gcongr
      _ = (K ^ q * hlsCm n p * B ^ q) ^ (1 / q) := by
          congr 1
          rw [show K ^ q * B ^ (α * p / n * q) * (hlsCm n p * B ^ p) =
            K ^ q * hlsCm n p * (B ^ (α * p / n * q) * B ^ p) by ring,
            ← ENNReal.rpow_add _ _ hB0 hBt, heq]
      _ = K * hlsCm n p ^ (1 / q) * B := by
          rw [ENNReal.mul_rpow_of_nonneg _ _ (by positivity),
            ENNReal.mul_rpow_of_nonneg _ _ (by positivity), one_div,
            ENNReal.rpow_rpow_inv hq0.ne', ENNReal.rpow_rpow_inv hq0.ne']

lemma hls_riesz_scale {n : ℕ} {α : ℝ} {R : ℝ} (hR : 0 < R) (x : EuclideanSpace ℝ (Fin n)) :
    rieszPotential n α ((ball (0 : EuclideanSpace ℝ (Fin n)) R).indicator fun _ => (1:ℝ)) x =
      R ^ α * rieszPotential n α ((ball (0 : EuclideanSpace ℝ (Fin n)) 1).indicator
        fun _ => (1:ℝ)) (R⁻¹ • x) := by
  unfold rieszPotential
  set h : EuclideanSpace ℝ (Fin n) → ℝ := fun y =>
    (ball (0 : EuclideanSpace ℝ (Fin n)) R).indicator (fun _ => (1:ℝ)) y / ‖x - y‖ ^ ((n : ℝ) - α)
  have h1 := Measure.integral_comp_smul_of_nonneg volume h R (hR := hR.le)
  rw [finrank_euclideanSpace_fin] at h1
  have h2 : ∫ y, h y = R ^ n * ∫ z, h (R • z) := by
    rw [h1, smul_eq_mul, ← mul_assoc, mul_inv_cancel₀ (pow_ne_zero _ hR.ne'), one_mul]
  have h3 : ∀ z, h (R • z) = (R ^ ((n:ℝ) - α))⁻¹ *
      ((ball (0 : EuclideanSpace ℝ (Fin n)) 1).indicator (fun _ => (1:ℝ)) z /
        ‖R⁻¹ • x - z‖ ^ ((n : ℝ) - α)) := by
    intro z
    have hind : (ball (0 : EuclideanSpace ℝ (Fin n)) R).indicator (fun _ => (1:ℝ)) (R • z) =
        (ball (0 : EuclideanSpace ℝ (Fin n)) 1).indicator (fun _ => (1:ℝ)) z := by
      simp only [indicator, mem_ball, dist_zero_right, norm_smul, Real.norm_eq_abs,
        abs_of_pos hR]
      congr 1
      apply propext
      constructor
      · intro hh; nlinarith [norm_nonneg z]
      · intro hh; nlinarith [norm_nonneg z]
    have hnorm : ‖x - R • z‖ = R * ‖R⁻¹ • x - z‖ := by
      have : x - R • z = R • (R⁻¹ • x - z) := by rw [smul_sub, smul_inv_smul₀ hR.ne']
      rw [this, norm_smul, Real.norm_of_nonneg hR.le]
    simp only [h]
    rw [hind, hnorm, Real.mul_rpow hR.le (norm_nonneg _)]
    field_simp
  rw [h2]
  simp_rw [h3]
  rw [integral_const_mul, ← mul_assoc, ← Real.rpow_natCast, ← Real.rpow_neg hR.le,
    ← Real.rpow_add hR]
  congr 2
  ring

lemma hls_eLpNorm_comp_inv_smul {n : ℕ} {h : EuclideanSpace ℝ (Fin n) → ℝ}
    (hh : AEStronglyMeasurable h volume) {R : ℝ} (hR : 0 < R) (q : ℝ≥0∞) :
    eLpNorm (fun x => h (R⁻¹ • x)) q volume =
      ENNReal.ofReal (R ^ n) ^ (1 / q).toReal * eLpNorm h q volume := by
  have hmap : Measure.map (fun x : EuclideanSpace ℝ (Fin n) => R⁻¹ • x) volume =
      ENNReal.ofReal (R ^ n) • volume := by
    rw [Measure.map_addHaar_smul volume (inv_ne_zero hR.ne'), finrank_euclideanSpace_fin,
      inv_pow, inv_inv, abs_of_pos (pow_pos hR _)]
  have hc : ENNReal.ofReal (R ^ n) ≠ 0 := by simpa using pow_pos hR n
  have := eLpNorm_map_measure (p := q) (g := h)
    (by rw [hmap]; exact hh.smul_measure _)
    (measurable_const_smul R⁻¹).aemeasurable
  rw [hmap, eLpNorm_smul_measure_of_ne_zero hc] at this
  exact this.symm

lemma hls_riesz_ball_pos {n : ℕ} {α : ℝ} (hαn : α < n) (x : EuclideanSpace ℝ (Fin n))
    (hx : 2 < ‖x‖) :
    0 < rieszPotential n α ((ball (0 : EuclideanSpace ℝ (Fin n)) 1).indicator fun _ => (1:ℝ)) x := by
  unfold rieszPotential
  set φ : EuclideanSpace ℝ (Fin n) → ℝ := fun y =>
    (ball (0 : EuclideanSpace ℝ (Fin n)) 1).indicator (fun _ => (1:ℝ)) y / ‖x - y‖ ^ ((n : ℝ) - α)
  have hnn : ∀ y, 0 ≤ φ y := fun y => div_nonneg (indicator_nonneg (fun _ _ => zero_le_one) y)
    (Real.rpow_nonneg (norm_nonneg _) _)
  have hfar : ∀ y ∈ ball (0 : EuclideanSpace ℝ (Fin n)) 1, 1 < ‖x - y‖ := by
    intro y hy
    rw [mem_ball, dist_zero_right] at hy
    have := norm_sub_norm_le x y
    linarith
  have hle : ∀ y, ‖φ y‖ ≤ (ball (0 : EuclideanSpace ℝ (Fin n)) 1).indicator (fun _ => (1:ℝ)) y := by
    intro y
    rw [Real.norm_of_nonneg (hnn y)]
    by_cases hy : y ∈ ball (0 : EuclideanSpace ℝ (Fin n)) 1
    · simp only [φ, indicator_of_mem hy]
      rw [div_le_one (by have := hfar y hy; positivity)]
      exact Real.one_le_rpow (hfar y hy).le (by linarith)
    · simp [φ, indicator_of_notMem hy]
  have hint : Integrable φ volume := by
    refine Integrable.mono' ((integrable_indicator_iff measurableSet_ball).2
      (integrableOn_const measure_ball_lt_top.ne)) ?_ (Filter.Eventually.of_forall hle)
    exact ((Measurable.indicator measurable_const measurableSet_ball).div
      (by fun_prop)).aestronglyMeasurable
  rw [integral_pos_iff_support_of_nonneg_ae (Filter.Eventually.of_forall hnn) hint]
  refine lt_of_lt_of_le (measure_ball_pos volume (0 : EuclideanSpace ℝ (Fin n)) one_pos)
    (measure_mono fun y hy => ?_)
  simp only [Function.mem_support, φ, indicator_of_mem hy]
  have := hfar y hy
  positivity

lemma hls_rpow_bounded {e K : ℝ} (h : ∀ R : ℝ, 0 < R → R ^ e ≤ K) : e = 0 := by
  by_contra he
  set K' := max K 0 + 1
  have hK' : 0 < K' := by positivity
  have := h (K' ^ (1 / e)) (by positivity)
  rw [← Real.rpow_mul hK'.le, one_div_mul_cancel he, Real.rpow_one] at this
  have : K < K' := by simp only [K']; linarith [le_max_left K 0]
  linarith

lemma hls_ray {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [ProperSpace E]
    {u : E → ℝ} (hu : ContDiff ℝ 1 u) (hlim : Tendsto u (cocompact E) (𝓝 0)) (x ω : E)
    (hω : ‖ω‖ = 1) :
    ENNReal.ofReal |u x| ≤ ∫⁻ r in Ioi (0:ℝ), ENNReal.ofReal ‖fderiv ℝ u (x + r • ω)‖ := by
  set h : ℝ → ℝ := fun r => u (x + r • ω)
  set h' : ℝ → ℝ := fun r => fderiv ℝ u (x + r • ω) ω
  set J := ∫⁻ r in Ioi (0:ℝ), ENNReal.ofReal ‖fderiv ℝ u (x + r • ω)‖
  have hd : ∀ r, HasDerivAt h (h' r) r := by
    intro r
    have h1 : HasDerivAt (fun r : ℝ => x + r • ω) ω r := by
      simpa using ((hasDerivAt_id r).smul_const ω).const_add x
    exact ((hu.differentiable one_ne_zero) (x + r • ω)).hasFDerivAt.comp_hasDerivAt r h1
  have hcont : Continuous h' :=
    ((hu.continuous_fderiv one_ne_zero).comp (continuous_const.add
      (continuous_id.smul continuous_const))).clm_apply continuous_const
  have hbound : ∀ R : ℝ, 0 ≤ R → ENNReal.ofReal |u x| ≤ ENNReal.ofReal |h R| + J := by
    intro R hR
    have hftc := intervalIntegral.integral_eq_sub_of_hasDerivAt (fun r _ => hd r)
      (hcont.intervalIntegrable 0 R)
    have h0 : h 0 = u x := by simp [h]
    set I := ∫ r in (0:ℝ)..R, h' r
    have hux : u x = h R - I := by rw [hftc, h0]; ring
    have hI : ENNReal.ofReal |I| ≤ J := by
      calc ENNReal.ofReal |I| = ‖∫ r in Ioc 0 R, h' r‖ₑ := by
            rw [Real.enorm_eq_ofReal_abs, ← intervalIntegral.integral_of_le hR]
        _ ≤ ∫⁻ r in Ioc 0 R, ‖h' r‖ₑ := enorm_integral_le_lintegral_enorm _
        _ ≤ ∫⁻ r in Ioc 0 R, ENNReal.ofReal ‖fderiv ℝ u (x + r • ω)‖ := by
            refine lintegral_mono fun r => ?_
            rw [Real.enorm_eq_ofReal_abs]
            apply ENNReal.ofReal_le_ofReal
            have := (fderiv ℝ u (x + r • ω)).le_opNorm ω
            rw [hω, mul_one, Real.norm_eq_abs] at this
            exact this
        _ ≤ J := lintegral_mono_set Ioc_subset_Ioi_self
    calc ENNReal.ofReal |u x| ≤ ENNReal.ofReal (|h R| + |I|) := by
          apply ENNReal.ofReal_le_ofReal
          rw [hux]; exact abs_sub _ _
      _ ≤ ENNReal.ofReal |h R| + ENNReal.ofReal |I| := ENNReal.ofReal_add_le
      _ ≤ ENNReal.ofReal |h R| + J := by gcongr
  have hray : Tendsto (fun R : ℝ => x + R • ω) atTop (cocompact E) := by
    rw [← Metric.cobounded_eq_cocompact, ← tendsto_norm_atTop_iff_cobounded]
    refine tendsto_atTop_mono' atTop ?_ (tendsto_atTop_add_const_right atTop (-‖x‖) tendsto_id)
    filter_upwards [eventually_ge_atTop 0] with R hR
    have : ‖R • ω‖ = R := by rw [norm_smul, hω, mul_one, Real.norm_of_nonneg hR]
    have := norm_sub_norm_le (R • ω) (-x)
    rw [sub_neg_eq_add, add_comm, norm_neg] at this
    simp only [id]
    linarith
  have hlim' : Tendsto (fun R => ENNReal.ofReal |h R| + J) atTop (𝓝 (0 + J)) := by
    refine Tendsto.add ?_ tendsto_const_nhds
    have := ((continuous_abs.tendsto 0).comp (hlim.comp hray))
    simp only [abs_zero] at this
    have := (ENNReal.continuous_ofReal.tendsto 0).comp this
    rw [ENNReal.ofReal_zero] at this
    exact this
  rw [← zero_add (ENNReal.ofReal |u x|)]
  rw [zero_add]
  have := ge_of_tendsto hlim' (eventually_atTop.2 ⟨0, hbound⟩)
  rwa [zero_add] at this

lemma hls_sobolev_pointwise {u : EuclideanSpace ℝ (Fin 3) → ℝ} (hu : ContDiff ℝ 1 u)
    (hlim : Tendsto u (cocompact _) (𝓝 0)) (x : EuclideanSpace ℝ (Fin 3)) :
    ENNReal.ofReal |u x| ≤ ENNReal.ofReal (1 / (4 * Real.pi)) *
      ∫⁻ y, ENNReal.ofReal (‖fderiv ℝ u y‖ / ‖x - y‖ ^ 2) := by
  set H : EuclideanSpace ℝ (Fin 3) → ℝ≥0∞ := fun z =>
    ENNReal.ofReal (‖fderiv ℝ u (x + z)‖ / ‖z‖ ^ 2) with hHdef
  have hfm : Measurable (fun y => fderiv ℝ u y) := (hu.continuous_fderiv one_ne_zero).measurable
  have hH : Measurable H := by
    simp only [hHdef]
    exact ENNReal.measurable_ofReal.comp
      (((hfm.comp (measurable_const_add x)).norm).div (measurable_norm.pow_const 2))
  have hT : ∫⁻ y, ENNReal.ofReal (‖fderiv ℝ u y‖ / ‖x - y‖ ^ 2) = ∫⁻ z, H z := by
    rw [← lintegral_add_left_eq_self _ x]
    congr 1; ext z
    simp only [hHdef, sub_add_cancel_left, norm_neg]
  set T := homeomorphUnitSphereProd (EuclideanSpace ℝ (Fin 3))
  have hmp := (volume : Measure (EuclideanSpace ℝ (Fin 3))).measurePreserving_homeomorphUnitSphereProd
  rw [finrank_euclideanSpace_fin] at hmp
  set G : (sphere (0 : EuclideanSpace ℝ (Fin 3)) 1 × Ioi (0:ℝ)) → ℝ≥0∞ :=
    fun p => H ((T.symm p : ({0}ᶜ : Set (EuclideanSpace ℝ (Fin 3)))) : EuclideanSpace ℝ (Fin 3))
  have hG : Measurable G := hH.comp (continuous_subtype_val.comp T.symm.continuous).measurable
  have hsub : ∫⁻ z in ({0}ᶜ : Set (EuclideanSpace ℝ (Fin 3))), H z ≤ ∫⁻ z, H z :=
    setLIntegral_le_lintegral _ _
  rw [← lintegral_subtype_comap (measurableSet_singleton 0).compl] at hsub
  have hcomp : ∫⁻ z : ({0}ᶜ : Set (EuclideanSpace ℝ (Fin 3))), H z
      ∂(volume.comap Subtype.val) = ∫⁻ p, G p
        ∂((volume : Measure (EuclideanSpace ℝ (Fin 3))).toSphere.prod (Measure.volumeIoiPow (3 - 1))) := by
    rw [← hmp.lintegral_comp_emb T.measurableEmbedding G]
    congr 1; ext z
    exact congrArg H (congrArg Subtype.val (T.symm_apply_apply z).symm)
  rw [hcomp, lintegral_prod _ hG.aemeasurable] at hsub
  have hinner : ∀ ω : sphere (0 : EuclideanSpace ℝ (Fin 3)) 1,
      ENNReal.ofReal |u x| ≤ ∫⁻ r, G (ω, r) ∂(Measure.volumeIoiPow (3 - 1)) := by
    intro ω
    have hω : ‖(ω : EuclideanSpace ℝ (Fin 3))‖ = 1 := norm_eq_of_mem_sphere ω
    have hwd := lintegral_withDensity_eq_lintegral_mul (Measure.comap Subtype.val volume)
      (f := fun r : Ioi (0:ℝ) => ENNReal.ofReal (r.1 ^ (3 - 1)))
      (ENNReal.measurable_ofReal.comp (measurable_subtype_coe.pow_const _))
      (g := fun r => G (ω, r)) (hG.comp measurable_prodMk_left)
    rw [Measure.volumeIoiPow, hwd]
    have : ∀ r : Ioi (0:ℝ), ((fun r : Ioi (0:ℝ) => ENNReal.ofReal (r.1 ^ (3 - 1))) *
        (fun r => G (ω, r))) r =
        (fun t : ℝ => ENNReal.ofReal (t ^ 2) * H (t • (ω : EuclideanSpace ℝ (Fin 3)))) r.1 := by
      intro r
      simp [G, T]
    rw [lintegral_congr this, lintegral_subtype_comap measurableSet_Ioi
      (fun t : ℝ => ENNReal.ofReal (t ^ 2) * H (t • (ω : EuclideanSpace ℝ (Fin 3))))]
    refine (hls_ray hu hlim x ω hω).trans (le_of_eq ?_)
    refine setLIntegral_congr_fun measurableSet_Ioi (fun t ht => ?_)
    have ht0 : 0 < t := ht
    simp only [hHdef]
    rw [← ENNReal.ofReal_mul (by positivity), norm_smul, hω, mul_one, Real.norm_of_nonneg ht0.le]
    congr 1
    field_simp
  have hσ : (volume : Measure (EuclideanSpace ℝ (Fin 3))).toSphere univ =
      ENNReal.ofReal (4 * Real.pi) := by
    rw [Measure.toSphere_apply_univ, finrank_euclideanSpace_fin, EuclideanSpace.volume_ball_fin_three]
    rw [ENNReal.ofReal_one, one_pow, one_mul, show ((3:ℕ) : ℝ≥0∞) = ENNReal.ofReal 3 by simp,
      ← ENNReal.ofReal_mul (by norm_num)]
    congr 1; ring
  have hlow : ENNReal.ofReal |u x| * ENNReal.ofReal (4 * Real.pi) ≤ ∫⁻ z, H z := by
    refine le_trans ?_ hsub
    rw [← hσ, ← lintegral_const]
    exact lintegral_mono fun ω => hinner ω
  rw [hT]
  calc ENNReal.ofReal |u x| = ENNReal.ofReal (1 / (4 * Real.pi)) *
        (ENNReal.ofReal |u x| * ENNReal.ofReal (4 * Real.pi)) := by
        rw [mul_comm (ENNReal.ofReal |u x|), ← mul_assoc, ← ENNReal.ofReal_mul (by positivity),
          one_div, inv_mul_cancel₀ (by positivity), ENNReal.ofReal_one, one_mul]
    _ ≤ _ := by gcongr

#print axioms hls_measurable_setLIntegral_ball
#print axioms hls_measurable_max
#print axioms hls_setLIntegral_le_max
#print axioms hls_weak_max
#print axioms hls_layer_real
#print axioms hls_layer
#print axioms hls_max_split
#print axioms hls_strong_max
#print axioms hls_kernel_shell
#print axioms hls_kernel_integral
#print axioms hls_tsum_int_split
#print axioms hls_holder_ball
#print axioms hls_geom
#print axioms hls_vol_ball
#print axioms hls_hedberg_j
#print axioms hls_cross
#print axioms hlsK_ne_zero
#print axioms hlsK_ne_top
#print axioms hls_hedberg
#print axioms hlsCm_ne_top
#print axioms hls_measurable_kernel
#print axioms hls_aesm_riesz
#print axioms hls_main_of_measurable
#print axioms hls_riesz_scale
#print axioms hls_eLpNorm_comp_inv_smul
#print axioms hls_riesz_ball_pos
#print axioms hls_rpow_bounded
#print axioms hls_ray
#print axioms hls_sobolev_pointwise

end hlsHelpers

/-- The Hardy-Littlewood-Sobolev inequality (Hedberg's proof on the card). Let the order `α`
lie strictly between 0 and `n`, let `1 < p < n/α`, and let `q` obey the exponent rule
`1/q = 1/p - α/n`. Then there is one constant `C`, depending only on `n`, `α` and `p`, such that
for every source `f` in `L^p` the integral defining `I_α f (x)` converges for almost every `x`,
and `‖I_α f‖_q ≤ C ‖f‖_p`. -/
theorem hardy_littlewood_sobolev_inequality {n : ℕ} {α p q : ℝ}
    (hα0 : 0 < α) (hαn : α < n) (hp1 : 1 < p) (hpn : p < n / α)
    (hq : 1 / q = 1 / p - α / n) :
    ∃ C : ℝ≥0, ∀ f : EuclideanSpace ℝ (Fin n) → ℝ, MemLp f (ENNReal.ofReal p) →
      (∀ᵐ x, Integrable (fun y => f y / ‖x - y‖ ^ ((n : ℝ) - α))) ∧
      eLpNorm (rieszPotential n α f) (ENNReal.ofReal q) ≤
        (C : ℝ≥0∞) * eLpNorm f (ENNReal.ofReal p) := by
  have hn : (0:ℝ) < n := by linarith
  have hq0 : 0 ≤ 1 / q := by
    rw [hq]
    have : α / n < 1 / p := by
      have hαp : α * p < n := by rwa [lt_div_iff₀ hα0, mul_comm] at hpn
      rw [div_lt_div_iff₀ hn (by linarith)]; linarith
    linarith
  have hfin : hlsK n α p * hlsCm n p ^ (1 / q) ≠ ∞ := by
    refine ENNReal.mul_ne_top (hlsK_ne_top n hα0 ?_)
      (ENNReal.rpow_ne_top_of_nonneg hq0 (hlsCm_ne_top n hp1))
    have hαp : α * p < n := by rwa [lt_div_iff₀ hα0, mul_comm] at hpn
    have : α < n / p := by rw [lt_div_iff₀ (by linarith)]; exact hαp
    linarith
  refine ⟨(hlsK n α p * hlsCm n p ^ (1 / q)).toNNReal, fun f hfp => ?_⟩
  have hf' : Measurable (hfp.aestronglyMeasurable.mk f) := hfp.aestronglyMeasurable.stronglyMeasurable_mk.measurable
  have hff' : f =ᵐ[volume] hfp.aestronglyMeasurable.mk f := hfp.aestronglyMeasurable.ae_eq_mk
  have hB' : eLpNorm (hfp.aestronglyMeasurable.mk f) (ENNReal.ofReal p) volume ≠ ∞ := by
    rw [← eLpNorm_congr_ae hff']; exact hfp.eLpNorm_ne_top
  obtain ⟨h1, h2⟩ := hls_main_of_measurable hα0 hαn hp1 hpn hq hf' hB'
  have hR : rieszPotential n α f = rieszPotential n α (hfp.aestronglyMeasurable.mk f) := by
    funext x
    refine integral_congr_ae ?_
    filter_upwards [hff'] with y hy
    rw [hy]
  refine ⟨?_, ?_⟩
  · filter_upwards [h1] with x hx
    refine hx.congr ?_
    filter_upwards [hff'] with y hy
    rw [hy]
  · rw [hR, eLpNorm_congr_ae hff', ENNReal.coe_toNNReal hfin]
    exact h2

/-- Scaling fixes the exponent (Step 1 of the card). With `0 < α < n` and `1 < p < n/α`, if a
single constant `C` gives `‖I_α f‖_q ≤ C ‖f‖_p` for every `f` in `L^p`, for some exponent
`q > 0`, then `q` must obey the exponent rule `1/q = 1/p - α/n`: any other `q` fails for every
`C`, because rescaling a ball by `R` multiplies the ratio of the two sides by `R ^ (α + n/q - n/p)`. -/
theorem exponent_rule_forced_by_scaling {n : ℕ} {α p q : ℝ}
    (hα0 : 0 < α) (hαn : α < n) (hp1 : 1 < p) (hpn : p < n / α) (hq0 : 0 < q)
    (hC : ∃ C : ℝ≥0, ∀ f : EuclideanSpace ℝ (Fin n) → ℝ, MemLp f (ENNReal.ofReal p) →
      eLpNorm (rieszPotential n α f) (ENNReal.ofReal q) ≤
        (C : ℝ≥0∞) * eLpNorm f (ENNReal.ofReal p)) :
    1 / q = 1 / p - α / n := by
  obtain ⟨C, hC⟩ := hC
  have hn : (0:ℝ) < n := by linarith
  have hnN : 0 < n := by exact_mod_cast hn
  have hp0 : 0 < p := by linarith
  have hpne : ENNReal.ofReal p ≠ 0 := by simpa using hp0
  have hqne : ENNReal.ofReal q ≠ 0 := by simpa using hq0
  set V := volume (Metric.ball (0 : EuclideanSpace ℝ (Fin n)) 1) with hVdef
  have hV0 : V ≠ 0 := (Metric.measure_ball_pos volume _ one_pos).ne'
  have hVt : V ≠ ∞ := measure_ball_lt_top.ne
  set fR : ℝ → EuclideanSpace ℝ (Fin n) → ℝ := fun R =>
    (Metric.ball (0 : EuclideanSpace ℝ (Fin n)) R).indicator fun _ => (1:ℝ)
  have hmem : ∀ R, MemLp (fR R) (ENNReal.ofReal p) volume := fun R =>
    memLp_indicator_const _ measurableSet_ball.nullMeasurableSet 1 (Or.inr measure_ball_lt_top.ne)
  have hnormR : ∀ R, 0 < R → eLpNorm (fR R) (ENNReal.ofReal p) volume =
      (ENNReal.ofReal (R ^ n) * V) ^ (1 / p) := by
    intro R hR
    rw [eLpNorm_indicator_const measurableSet_ball.nullMeasurableSet hpne ENNReal.ofReal_ne_top,
      ENNReal.toReal_ofReal hp0.le, Measure.addHaar_ball_of_pos _ _ hR, finrank_euclideanSpace_fin]
    simp [V]
  set A := eLpNorm (rieszPotential n α (fR 1)) (ENNReal.ofReal q) volume with hAdef
  have hAt : A ≠ ∞ := by
    refine ne_top_of_le_ne_top ?_ (hC (fR 1) (hmem 1))
    rw [hnormR 1 one_pos]
    exact ENNReal.mul_ne_top ENNReal.coe_ne_top
      (ENNReal.rpow_ne_top_of_nonneg (by positivity) (ENNReal.mul_ne_top ENNReal.ofReal_ne_top hVt))
  have hA0 : A ≠ 0 := by
    intro h
    rw [hAdef, eLpNorm_eq_zero_iff hqne] at h
    have : Nontrivial (EuclideanSpace ℝ (Fin n)) :=
      Module.nontrivial_of_finrank_pos (R := ℝ) (by rw [finrank_euclideanSpace_fin]; exact hnN)
    obtain ⟨v, hv⟩ := exists_ne (0 : EuclideanSpace ℝ (Fin n))
    have hvn : 0 < ‖v‖ := norm_pos_iff.2 hv
    have hx0 : 2 < ‖(3 / ‖v‖) • v‖ := by
      rw [norm_smul, Real.norm_of_nonneg (by positivity), div_mul_cancel₀ _ hvn.ne']
      norm_num
    have hopen : IsOpen {x : EuclideanSpace ℝ (Fin n) | 2 < ‖x‖} :=
      isOpen_lt continuous_const continuous_norm
    have hpos := hopen.measure_pos volume ⟨_, hx0⟩
    have hnull : volume {x : EuclideanSpace ℝ (Fin n) | 2 < ‖x‖} = 0 := by
      refine measure_mono_null (fun x hx => ?_) (ae_iff.1 h)
      exact (hls_riesz_ball_pos hαn x hx).ne'
    exact hpos.ne' hnull
  have hmeas1 : AEStronglyMeasurable (rieszPotential n α (fR 1)) volume :=
    hls_aesm_riesz (Measurable.indicator measurable_const measurableSet_ball)
  -- the scaled inequality
  have hineq : ∀ R : ℝ, 0 < R → ENNReal.ofReal (R ^ α) * (ENNReal.ofReal (R ^ n) ^ (1 / q) * A) ≤
      (C : ℝ≥0∞) * (ENNReal.ofReal (R ^ n) * V) ^ (1 / p) := by
    intro R hR
    have h := hC (fR R) (hmem R)
    rw [hnormR R hR] at h
    have hfun : rieszPotential n α (fR R) =
        R ^ α • fun x => rieszPotential n α (fR 1) (R⁻¹ • x) := by
      funext x
      simp only [Pi.smul_apply, smul_eq_mul]
      exact hls_riesz_scale hR x
    rw [hfun, eLpNorm_const_smul, hls_eLpNorm_comp_inv_smul hmeas1 hR,
      Real.enorm_of_nonneg (by positivity), one_div, ENNReal.toReal_inv,
      ENNReal.toReal_ofReal hq0.le] at h
    rw [one_div]
    exact h
  set a := A.toReal
  set v := V.toReal
  have ha : 0 < a := ENNReal.toReal_pos hA0 hAt
  have hv : 0 < v := ENNReal.toReal_pos hV0 hVt
  have hreal : ∀ R : ℝ, 0 < R → R ^ (α + n / q - n / p) ≤ C * v ^ (1 / p) / a := by
    intro R hR
    have h := hineq R hR
    rw [← ENNReal.ofReal_toReal hAt, ← ENNReal.ofReal_toReal hVt,
      ENNReal.ofReal_rpow_of_nonneg (by positivity) (by positivity),
      ← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul (by positivity),
      ← ENNReal.ofReal_mul (by positivity),
      ENNReal.ofReal_rpow_of_nonneg (by positivity) (by positivity),
      ← ENNReal.ofReal_coe_nnreal, ← ENNReal.ofReal_mul (by positivity),
      ENNReal.ofReal_le_ofReal_iff (by positivity)] at h
    rw [le_div_iff₀ ha]
    have e1 : (R ^ n) ^ (1 / q) = R ^ ((n:ℝ) / q) := by
      rw [← Real.rpow_natCast, ← Real.rpow_mul hR.le]; ring_nf
    have e2 : (R ^ n * v) ^ (1 / p) = R ^ ((n:ℝ) / p) * v ^ (1 / p) := by
      rw [Real.mul_rpow (by positivity) hv.le, ← Real.rpow_natCast, ← Real.rpow_mul hR.le]
      ring_nf
    rw [e1, e2] at h
    have e3 : R ^ (α + n / q - n / p) = R ^ α * R ^ ((n:ℝ) / q) / R ^ ((n:ℝ) / p) := by
      rw [Real.rpow_sub hR, Real.rpow_add hR]
    rw [e3, div_mul_eq_mul_div, div_le_iff₀ (by positivity)]
    calc R ^ α * R ^ ((n:ℝ) / q) * a = R ^ α * (R ^ ((n:ℝ) / q) * a) := by ring
      _ ≤ C * (R ^ ((n:ℝ) / p) * v ^ (1 / p)) := h
      _ = _ := by ring
  have he := hls_rpow_bounded hreal
  field_simp at he ⊢
  linarith

/-- Sobolev embedding in one line (Step 5 of the card), in space (`n = 3`). Let `u` have a
continuous gradient and fade at infinity. Then at every point
`|u(x)| ≤ (1/(4π)) ∫ |∇u(y)| / |x - y|² dy = (1/(4π)) I₁|∇u| (x)`,
and, for `1 < p < 3` and `p* = 3p/(3 - p)`, one constant `C'` gives `‖u‖_{p*} ≤ C' ‖∇u‖_p`
for every such `u`. The size of the slope `|∇u(y)|` is the norm of the derivative `fderiv ℝ u y`.
The pointwise integral is written in `[0, ∞]`, so it is the true integral even when infinite. -/
theorem sobolev_embedding_from_riesz_potential {p : ℝ} (hp1 : 1 < p) (hp3 : p < 3) :
    (∀ u : EuclideanSpace ℝ (Fin 3) → ℝ, ContDiff ℝ 1 u →
        Tendsto u (cocompact _) (𝓝 0) → ∀ x,
          ENNReal.ofReal |u x| ≤ ENNReal.ofReal (1 / (4 * Real.pi)) *
            ∫⁻ y, ENNReal.ofReal (‖fderiv ℝ u y‖ / ‖x - y‖ ^ 2)) ∧
    ∃ C' : ℝ≥0, ∀ u : EuclideanSpace ℝ (Fin 3) → ℝ, ContDiff ℝ 1 u →
      Tendsto u (cocompact _) (𝓝 0) →
        eLpNorm u (ENNReal.ofReal (3 * p / (3 - p))) ≤
          (C' : ℝ≥0∞) * eLpNorm (fun x => ‖fderiv ℝ u x‖) (ENNReal.ofReal p) := by
  refine ⟨fun u hu hlim x => hls_sobolev_pointwise hu hlim x, ?_⟩
  have hp0 : 0 < p := by linarith
  have h3p : 0 < 3 - p := by linarith
  have hq : 1 / (3 * p / (3 - p)) = 1 / p - 1 / ((3 : ℕ) : ℝ) := by
    push_cast
    field_simp
  obtain ⟨C, hC⟩ := hardy_littlewood_sobolev_inequality (n := 3) (α := 1) (p := p)
    (q := 3 * p / (3 - p)) one_pos (by norm_num) hp1 (by norm_num; exact hp3) hq
  refine ⟨Real.toNNReal (1 / (4 * Real.pi)) * C + 1, fun u hu hlim => ?_⟩
  set g : EuclideanSpace ℝ (Fin 3) → ℝ := fun x => ‖fderiv ℝ u x‖ with hgdef
  have hgc : Continuous g := (hu.continuous_fderiv one_ne_zero).norm
  have hC0 : ((Real.toNNReal (1 / (4 * Real.pi)) * C + 1 : ℝ≥0) : ℝ≥0∞) ≠ 0 := by
    rw [ENNReal.coe_ne_zero]
    exact (add_pos_of_nonneg_of_pos zero_le one_pos).ne'
  by_cases hgt : eLpNorm g (ENNReal.ofReal p) volume = ∞
  · rw [hgt, ENNReal.mul_top hC0]
    exact le_top
  have hmem : MemLp g (ENNReal.ofReal p) volume := lt_top_iff_ne_top.2 hgt
  obtain ⟨hint, hbd⟩ := hC g hmem
  have hnn : ∀ x, 0 ≤ rieszPotential 3 1 g x := fun x =>
    integral_nonneg fun y => div_nonneg (norm_nonneg _) (Real.rpow_nonneg (norm_nonneg _) _)
  have hpt : ∀ᵐ x, ‖u x‖ ≤ ‖(1 / (4 * Real.pi)) * rieszPotential 3 1 g x‖ := by
    filter_upwards [hint] with x hx
    have h1 := hls_sobolev_pointwise hu hlim x
    have hk : (fun y => ENNReal.ofReal (‖fderiv ℝ u y‖ / ‖x - y‖ ^ 2)) =
        fun y => ENNReal.ofReal (g y / ‖x - y‖ ^ (((3 : ℕ) : ℝ) - 1)) := by
      ext y
      congr 2
      rw [show ((3 : ℕ) : ℝ) - 1 = 2 by norm_num, Real.rpow_two]
    rw [hk, ← ofReal_integral_eq_lintegral_ofReal hx
      (Filter.Eventually.of_forall fun y => div_nonneg (norm_nonneg _)
        (Real.rpow_nonneg (norm_nonneg _) _)),
      ← ENNReal.ofReal_mul (by positivity)] at h1
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_nonneg (mul_nonneg (by positivity) (hnn x))]
    exact (ENNReal.ofReal_le_ofReal_iff (mul_nonneg (by positivity) (hnn x))).1 h1
  calc eLpNorm u (ENNReal.ofReal (3 * p / (3 - p))) volume
      ≤ eLpNorm (fun x => (1 / (4 * Real.pi)) * rieszPotential 3 1 g x)
          (ENNReal.ofReal (3 * p / (3 - p))) volume := eLpNorm_mono_ae hu.continuous.aestronglyMeasurable hpt
    _ = ENNReal.ofReal (1 / (4 * Real.pi)) *
          eLpNorm (rieszPotential 3 1 g) (ENNReal.ofReal (3 * p / (3 - p))) volume := by
        rw [show (fun x => (1 / (4 * Real.pi)) * rieszPotential 3 1 g x) =
          (1 / (4 * Real.pi)) • rieszPotential 3 1 g from rfl, eLpNorm_const_smul,
          Real.enorm_of_nonneg (by positivity)]
    _ ≤ ENNReal.ofReal (1 / (4 * Real.pi)) * ((C : ℝ≥0∞) * eLpNorm g (ENNReal.ofReal p) volume) := by
        gcongr
    _ ≤ ((Real.toNNReal (1 / (4 * Real.pi)) * C + 1 : ℝ≥0) : ℝ≥0∞) *
          eLpNorm g (ENNReal.ofReal p) volume := by
        rw [← mul_assoc]
        gcongr
        rw [ENNReal.coe_add, ENNReal.coe_mul]
        exact le_self_add

/-! ### The card's worked numbers, checked exactly -/

-- The example: n = 3, α = 2, p = 6/5 lies in 1 < p < n/α = 3/2, and the rule gives q = 6.
example : (1 : ℝ) < 6 / 5 ∧ (6 / 5 : ℝ) < 3 / 2 := by norm_num
example : (1 : ℝ) / 6 = 1 / (6 / 5) - 2 / 3 := by norm_num

-- The ball's scaling power α + n/q - n/p: +1/4 at q = 4, 0 at q = 6, -1/8 at q = 8.
example : (2 : ℝ) + 3 / 4 - 3 / (6 / 5) = 1 / 4 := by norm_num
example : (2 : ℝ) + 3 / 6 - 3 / (6 / 5) = 0 := by norm_num
example : (2 : ℝ) + 3 / 8 - 3 / (6 / 5) = -1 / 8 := by norm_num

-- What breaks: p = 1 gives q = 3; p = 3/2 = n/α asks for 1/q = 0, that is q = ∞.
example : (1 : ℝ) / 3 = 1 / 1 - 2 / 3 := by norm_num
example : (1 : ℝ) / (3 / 2) - 2 / 3 = 0 := by norm_num

-- Sobolev: at p = 2 the exponent p* = 3p/(3 - p) is 6, the rule with α = 1.
example : (3 : ℝ) * 2 / (3 - 2) = 6 := by norm_num
example : (1 : ℝ) / 6 = 1 / 2 - 1 / 3 := by norm_num

-- The open pair: α = 1, p = 4/3 in space gives q = 12/5.
example : (1 : ℝ) / (12 / 5) = 1 / (4 / 3) - 1 / 3 := by norm_num

-- J = ∫₀¹ (3 - r²)⁶ r² dr, expanded by the binomial theorem as in the check, is 1140032/15015
-- exactly (the card's 75.926207).
example : (∑ k ∈ Finset.range 7,
    ((Nat.choose 6 k : ℚ) * 3 ^ (6 - k) * (-1) ^ k / (2 * k + 3))) = 1140032 / 15015 := by
  simp only [Finset.sum_range_succ, Finset.sum_range_zero]
  norm_num [Nat.choose]

#print axioms hardy_littlewood_sobolev_inequality
#print axioms exponent_rule_forced_by_scaling
#print axioms sobolev_embedding_from_riesz_potential
