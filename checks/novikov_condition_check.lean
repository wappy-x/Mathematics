-- Novikov: the exponential weight of a tilt is a supermartingale, so it always averages at most 1 and averaging exactly 1 makes it a fair game on [0, T]; the self-feeding tilt's weight averages only 2Φ(1/√T) - 1.
import Mathlib.Probability.Process.LocalProperty
import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic

open MeasureTheory ProbabilityTheory Real
open scoped NNReal ENNReal

/-! Setting, as on the card. Time runs over `ℝ≥0`; `ℱ t` is what is known by time `t`.
The tilt is `θ t ω`. Its accumulated square is `A t ω = ∫₀ᵗ θ_s² ds`, written out below as an
interval integral. The card's `M t = -∫₀ᵗ θ_s dW_s` is an Ito integral, which Mathlib does not
build yet. So `M` is taken as given, with the properties the Ito integral has on the card:
it is known by time `t` (adapted to `ℱ`), it starts at 0, and the weight
`Z_t = exp (M_t - A_t / 2)` is a local martingale (the card's Step 1, by Ito's lemma).
Mathlib's `Locally (fun Y => Martingale Y ℱ P) ℱ X P` is "X is a local martingale":
there are stopping times rising to infinity at which the stopped process is a martingale.
The card's "When it holds": the tilt is chosen from the past (progressive measurability) and
its total square is finite on every path (interval integrability).

Scope. The full Novikov theorem (`E[exp (A_T / 2)] < ∞` gives `E[Z_T] = 1`) is not stated here:
its proof needs optional stopping at general continuous-time stopping times, uniform
integrability and a Hölder limit, which this Mathlib does not supply in a usable size.
This file states the card's Step 2 (the weights always average at most 1, and averaging
exactly 1 forces the fair game), the tilt C average from the card's code, and the card's
exact arithmetic. -/

section NovikovHelpers1
open Filter Topology
/-- Key set-integral inequality for a nonnegative local martingale. -/
lemma nonneg_localMart_lintegral_le {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (Z : ℝ≥0 → Ω → ℝ)
    (hZnn : ∀ t ω, 0 ≤ Z t ω)
    (hloc : Locally (fun Y => Martingale Y ℱ P) ℱ Z P)
    {i j : ℝ≥0} (hij : i ≤ j) {A : Set Ω} (hA : MeasurableSet[ℱ i] A) :
    ∫⁻ ω in A, ENNReal.ofReal (Z j ω) ∂P ≤ ∫⁻ ω in A, ENNReal.ofReal (Z i ω) ∂P := by
  obtain ⟨τ, hτ, hmart⟩ := hloc
  set Y : ℕ → ℝ≥0 → Ω → ℝ :=
    fun n => stoppedProcess (fun r ↦ {ω | ⊥ < τ n ω}.indicator (Z r)) (τ n) with hY
  have hYnn : ∀ n r ω, 0 ≤ Y n r ω := by
    intro n r ω
    simp only [hY, stoppedProcess]
    exact Set.indicator_nonneg (fun ω _ => hZnn _ ω) ω
  set B : ℕ → Set Ω := fun n => A ∩ {ω | (i : WithTop ℝ≥0) < τ n ω} with hB
  have hBmeas : ∀ n, MeasurableSet[ℱ i] (B n) := by
    intro n
    refine hA.inter ?_
    have h := (hτ.isStoppingTime n) i
    have : {ω | (i : WithTop ℝ≥0) < τ n ω} = {ω | τ n ω ≤ i}ᶜ := by
      ext ω; simp only [Set.mem_ofPred_eq, Set.mem_compl_iff, not_le]
    rw [this]; exact h.compl
  have hYi : ∀ n, ∀ ω ∈ B n, Y n i ω = Z i ω := by
    intro n ω hω
    have h1 : (i : WithTop ℝ≥0) < τ n ω := hω.2
    have h2 : (⊥ : WithTop ℝ≥0) < τ n ω := lt_of_le_of_lt bot_le h1
    simp only [hY, stoppedProcess, min_eq_left h1.le]
    rw [Set.indicator_of_mem (show ω ∈ {ω | ⊥ < τ n ω} from h2)]
    rfl
  -- bound for each n
  have hbound : ∀ n, ∫⁻ ω in B n, ENNReal.ofReal (Y n j ω) ∂P
      ≤ ∫⁻ ω in A, ENNReal.ofReal (Z i ω) ∂P := by
    intro n
    have hm := hmart n
    have hint_j : Integrable (Y n j) P := hm.integrable j
    have hint_i : Integrable (Y n i) P := hm.integrable i
    have heq := hm.setIntegral_eq hij (hBmeas n)
    rw [← ofReal_integral_eq_lintegral_ofReal hint_j.integrableOn
      (ae_of_all _ (fun ω => hYnn n j ω)), ← heq,
      ofReal_integral_eq_lintegral_ofReal hint_i.integrableOn
      (ae_of_all _ (fun ω => hYnn n i ω))]
    calc ∫⁻ ω in B n, ENNReal.ofReal (Y n i ω) ∂P
        = ∫⁻ ω in B n, ENNReal.ofReal (Z i ω) ∂P := by
          refine setLIntegral_congr_fun (ℱ.le i _ (hBmeas n)) ?_
          intro ω hω; dsimp only; rw [hYi n ω hω]
      _ ≤ ∫⁻ ω in A, ENNReal.ofReal (Z i ω) ∂P :=
          lintegral_mono_set Set.inter_subset_left
  -- Fatou
  have hmeasY : ∀ n, Measurable fun ω => (B n).indicator (fun ω => ENNReal.ofReal (Y n j ω)) ω := by
    intro n
    refine Measurable.indicator ?_ (ℱ.le i _ (hBmeas n))
    exact ENNReal.measurable_ofReal.comp
      (((hmart n).stronglyAdapted j).mono (ℱ.le j)).measurable
  have hlim : ∀ᵐ ω ∂P, liminf (fun n => (B n).indicator (fun ω => ENNReal.ofReal (Y n j ω)) ω)
      atTop = A.indicator (fun ω => ENNReal.ofReal (Z j ω)) ω := by
    filter_upwards [hτ.tendsto_top] with ω hω
    have hev : ∀ᶠ n in atTop, (j : WithTop ℝ≥0) < τ n ω :=
      hω.eventually (lt_mem_nhds (WithTop.coe_lt_top j))
    have hEv : (fun n => (B n).indicator (fun ω => ENNReal.ofReal (Y n j ω)) ω)
        =ᶠ[atTop] fun _ => A.indicator (fun ω => ENNReal.ofReal (Z j ω)) ω := by
      filter_upwards [hev] with n hn
      have hin : (i : WithTop ℝ≥0) < τ n ω := lt_of_le_of_lt (WithTop.coe_le_coe.2 hij) hn
      have h2 : (⊥ : WithTop ℝ≥0) < τ n ω := lt_of_le_of_lt bot_le hn
      have hYj : Y n j ω = Z j ω := by
        simp only [hY, stoppedProcess, min_eq_left hn.le]
        rw [Set.indicator_of_mem (show ω ∈ {ω | ⊥ < τ n ω} from h2)]
        rfl
      by_cases hωA : ω ∈ A
      · have : ω ∈ B n := ⟨hωA, hin⟩
        rw [Set.indicator_of_mem this, Set.indicator_of_mem hωA, hYj]
      · have : ω ∉ B n := fun h => hωA h.1
        rw [Set.indicator_of_notMem this, Set.indicator_of_notMem hωA]
    rw [Filter.liminf_congr hEv, liminf_const]
  calc ∫⁻ ω in A, ENNReal.ofReal (Z j ω) ∂P
      = ∫⁻ ω, A.indicator (fun ω => ENNReal.ofReal (Z j ω)) ω ∂P :=
        (lintegral_indicator (ℱ.le i _ hA) _).symm
    _ = ∫⁻ ω, liminf (fun n => (B n).indicator (fun ω => ENNReal.ofReal (Y n j ω)) ω) atTop ∂P :=
        lintegral_congr_ae (hlim.mono fun ω h => h.symm)
    _ ≤ liminf (fun n => ∫⁻ ω, (B n).indicator (fun ω => ENNReal.ofReal (Y n j ω)) ω ∂P) atTop :=
        lintegral_liminf_le hmeasY
    _ ≤ ∫⁻ ω in A, ENNReal.ofReal (Z i ω) ∂P := by
        refine liminf_le_of_frequently_le' (Frequently.of_forall fun n => ?_)
        rw [lintegral_indicator (ℱ.le i _ (hBmeas n))]
        exact hbound n

lemma nonneg_localMart_supermartingale {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (Z : ℝ≥0 → Ω → ℝ)
    (hZad : StronglyAdapted ℱ Z) (hZnn : ∀ t ω, 0 ≤ Z t ω) (hZ0 : ∀ ω, Z 0 ω = 1)
    (hloc : Locally (fun Y => Martingale Y ℱ P) ℱ Z P) :
    Supermartingale Z ℱ P := by
  have hint : ∀ t, Integrable (Z t) P := by
    intro t
    refine ⟨((hZad t).mono (ℱ.le t)).aestronglyMeasurable, ?_⟩
    rw [hasFiniteIntegral_iff_ofReal (ae_of_all _ (hZnn t))]
    have h := nonneg_localMart_lintegral_le P ℱ Z hZnn hloc (zero_le : (0:ℝ≥0) ≤ t)
      (MeasurableSet.univ)
    simp only [Measure.restrict_univ, hZ0, ENNReal.ofReal_one, lintegral_const,
      measure_univ, mul_one] at h
    exact lt_of_le_of_lt h ENNReal.one_lt_top
  have hsub : Submartingale (-Z) ℱ P := by
    refine submartingale_of_setIntegral_le hZad.neg (fun t => (hint t).neg) ?_
    intro i j hij A hA
    simp only [Pi.neg_apply, integral_neg, neg_le_neg_iff]
    have h := nonneg_localMart_lintegral_le P ℱ Z hZnn hloc hij hA
    rw [← ofReal_integral_eq_lintegral_ofReal (hint j).integrableOn
      (ae_of_all _ (hZnn j)), ← ofReal_integral_eq_lintegral_ofReal (hint i).integrableOn
      (ae_of_all _ (hZnn i))] at h
    exact (ENNReal.ofReal_le_ofReal_iff (setIntegral_nonneg (ℱ.le i _ hA)
      (fun ω _ => hZnn i ω))).1 h
  simpa using hsub.neg

lemma supermartingale_stopped_martingale {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (Z : ℝ≥0 → Ω → ℝ)
    (hZ : Supermartingale Z ℱ P) (hZ0 : ∫ ω, Z 0 ω ∂P = 1) (T : ℝ≥0)
    (hT : ∫ ω, Z T ω ∂P = 1) :
    Martingale (fun t ω => Z (min t T) ω) ℱ P := by
  refine ⟨fun t => (hZ.1 (min t T)).mono (ℱ.mono (min_le_left t T)), fun i j hij => ?_⟩
  rcases le_or_gt T i with hTi | hiT
  · have h1 : min i T = T := min_eq_right hTi
    have h2 : min j T = T := min_eq_right (hTi.trans hij)
    simp only [h1, h2]
    exact (condExp_of_stronglyMeasurable (ℱ.le i) ((hZ.1 T).mono (ℱ.mono hTi))
      (hZ.integrable T)).eventuallyEq
  · have h1 : min i T = i := min_eq_left hiT.le
    simp only [h1]
    have hle : P[Z (min j T) | ℱ i] ≤ᵐ[P] Z i := hZ.2.1 i (min j T) (le_min hij hiT.le)
    have hE1 : ∫ ω, Z (min j T) ω ∂P ≥ 1 := by
      have := hZ.setIntegral_le (min_le_right j T) (s := Set.univ) MeasurableSet.univ
      simp only [Measure.restrict_univ] at this
      linarith
    have hE2 : ∫ ω, Z i ω ∂P ≤ 1 := by
      have := hZ.setIntegral_le (zero_le : (0:ℝ≥0) ≤ i) (s := Set.univ) MeasurableSet.univ
      simp only [Measure.restrict_univ] at this
      linarith
    have hg : 0 ≤ᵐ[P] fun ω => Z i ω - P[Z (min j T) | ℱ i] ω := by
      filter_upwards [hle] with ω hω; show (0:ℝ) ≤ _; linarith
    have hgint : Integrable (fun ω => Z i ω - P[Z (min j T) | ℱ i] ω) P :=
      (hZ.integrable i).sub integrable_condExp
    have hzero : ∫ ω, (Z i ω - P[Z (min j T) | ℱ i] ω) ∂P = 0 := by
      rw [integral_sub (hZ.integrable i) integrable_condExp, integral_condExp (ℱ.le i)]
      have := integral_nonneg_of_ae hg
      rw [integral_sub (hZ.integrable i) integrable_condExp, integral_condExp (ℱ.le i)] at this
      linarith
    have := (integral_eq_zero_iff_of_nonneg_ae hg hgint).1 hzero
    filter_upwards [this] with ω hω
    simp only [Pi.zero_apply] at hω
    linarith
lemma stronglyMeasurable_integral_sq_of_slice {Ω : Type*} [MeasurableSpace Ω]
    (θ : ℝ≥0 → Ω → ℝ) (t : ℝ≥0)
    (hΘ : StronglyMeasurable fun p : Set.Iic t × Ω => θ p.1 p.2) :
    StronglyMeasurable fun ω => ∫ s in (0 : ℝ)..t, θ s.toNNReal ω ^ 2 := by
  let g : ℝ → Set.Iic t := fun s => ⟨min s.toNNReal t, Set.mem_Iic.2 (min_le_right _ _)⟩
  have hg : Measurable g :=
    (measurable_real_toNNReal.min measurable_const).subtype_mk
  have hφ : Measurable fun p : ℝ × Ω => (g p.1, p.2) :=
    (hg.comp measurable_fst).prodMk measurable_snd
  have hH : StronglyMeasurable (Function.uncurry fun (s : ℝ) (ω : Ω) => θ (g s).1 ω ^ 2) := by
    have := (hΘ.comp_measurable hφ)
    exact this.pow 2
  have hint := hH.integral_prod_left (μ := (volume : Measure ℝ).restrict (Set.Ioc 0 t))
  convert hint using 1
  funext ω
  rw [intervalIntegral.integral_of_le (NNReal.coe_nonneg t)]
  refine setIntegral_congr_fun measurableSet_Ioc (fun s hs => ?_)
  have : s.toNNReal ≤ t := (Real.toNNReal_le_iff_le_coe).2 hs.2
  simp only [g, min_eq_left this]

lemma stronglyAdapted_exp_weight {Ω : Type*} {mΩ : MeasurableSpace Ω}
    (ℱ : Filtration ℝ≥0 mΩ) (θ M : ℝ≥0 → Ω → ℝ)
    (hθ : IsStronglyProgressive ℱ θ) (hMad : StronglyAdapted ℱ M) :
    StronglyAdapted ℱ
      (fun t ω => exp (M t ω - 1 / 2 * ∫ s in (0 : ℝ)..t, θ s.toNNReal ω ^ 2)) := by
  intro t
  have hI := @stronglyMeasurable_integral_sq_of_slice Ω (ℱ t) θ t (hθ t)
  have h := (hMad t).sub (hI.const_mul (1 / 2))
  exact Real.continuous_exp.comp_stronglyMeasurable h

end NovikovHelpers1

/-- **The weights always average at most 1 (Step 2).** Let the tilt `θ` be chosen from the past,
with finite total square `A_t = ∫₀ᵗ θ_s² ds` on every path, and let `M_t = -∫₀ᵗ θ_s dW_s`
(see the setting above), so the candidate weight is `Z_t = exp (M_t - A_t / 2)`, a positive
local martingale starting at 1. Then, with no further condition, `Z` is a supermartingale
(its forecast never exceeds its present value), so `E[Z_T] ≤ 1` at every horizon `T`; and if
`E[Z_T] = 1` at a horizon `T`, then `Z` is a true martingale on `[0, T]` (written as the
process stopped at `T`). -/
theorem exponential_weight_supermartingale {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (θ M : ℝ≥0 → Ω → ℝ)
    (hθ : IsStronglyProgressive ℱ θ)
    (hθsq : ∀ ω (t : ℝ≥0), IntervalIntegrable (fun s : ℝ => θ s.toNNReal ω ^ 2) volume 0 t)
    (hMad : StronglyAdapted ℱ M) (hM0 : ∀ ω, M 0 ω = 0)
    (hZloc : Locally (fun Y => Martingale Y ℱ P) ℱ
      (fun t ω => exp (M t ω - 1 / 2 * ∫ s in (0 : ℝ)..t, θ s.toNNReal ω ^ 2)) P) :
    Supermartingale (fun t ω => exp (M t ω - 1 / 2 * ∫ s in (0 : ℝ)..t, θ s.toNNReal ω ^ 2))
        ℱ P ∧
      ∀ T : ℝ≥0,
        ∫ ω, exp (M T ω - 1 / 2 * ∫ s in (0 : ℝ)..T, θ s.toNNReal ω ^ 2) ∂P ≤ 1 ∧
        (∫ ω, exp (M T ω - 1 / 2 * ∫ s in (0 : ℝ)..T, θ s.toNNReal ω ^ 2) ∂P = 1 →
          Martingale (fun t ω => exp (M (min t T) ω
            - 1 / 2 * ∫ s in (0 : ℝ)..(min t T : ℝ≥0), θ s.toNNReal ω ^ 2)) ℱ P) := by
  have hZad := stronglyAdapted_exp_weight ℱ θ M hθ hMad
  have hZ0 : ∀ ω, (fun (t : ℝ≥0) ω => exp (M t ω - 1 / 2 * ∫ s in (0 : ℝ)..t,
      θ s.toNNReal ω ^ 2)) 0 ω = 1 := by
    intro ω; simp [hM0]
  have hsup := nonneg_localMart_supermartingale P ℱ _ hZad (fun t ω => (exp_pos _).le) hZ0 hZloc
  have hint0 : ∫ ω, (fun (t : ℝ≥0) ω => exp (M t ω - 1 / 2 * ∫ s in (0 : ℝ)..t,
      θ s.toNNReal ω ^ 2)) 0 ω ∂P = 1 := by
    simp only [hZ0, integral_const, probReal_univ, smul_eq_mul, mul_one]
  refine ⟨hsup, fun T => ⟨?_, fun h => ?_⟩⟩
  · have := hsup.setIntegral_le (zero_le : (0:ℝ≥0) ≤ T) (s := Set.univ) MeasurableSet.univ
    simp only [Measure.restrict_univ] at this
    exact this.trans hint0.le
  · exact supermartingale_stopped_martingale P ℱ _ hsup hint0 T h

section NovikovHelpers2
open Filter Topology
/-- One coordinate: `E[exp (-λ (a + Y)²)]` for `Y` normal with mean 0 and variance `v`. -/
lemma integral_exp_neg_mul_sq_add_gaussianReal (v : ℝ≥0) (hv : v ≠ 0) (lam a : ℝ)
    (hlam : 0 ≤ lam) :
    ∫ y, exp (-lam * (a + y) ^ 2) ∂(gaussianReal 0 v)
      = (√(1 + 2 * lam * v))⁻¹ * exp (-lam * a ^ 2 / (1 + 2 * lam * v)) := by
  have hv' : (0 : ℝ) < v := lt_of_le_of_ne v.2 (fun h => hv (NNReal.coe_eq_zero.1 h.symm))
  set k : ℝ := 1 + 2 * lam * v with hk
  have hkpos : 0 < k := by rw [hk]; positivity
  set β : ℝ := k / (2 * v) with hβ
  have hβpos : 0 < β := by rw [hβ]; positivity
  set γ : ℝ := 2 * lam * a * v / k with hγ
  set δ : ℝ := -lam * a ^ 2 / k with hδ
  rw [integral_gaussianReal_eq_integral_smul hv]
  have hpt : ∀ x : ℝ, gaussianPDFReal 0 v x • exp (-lam * (a + x) ^ 2)
      = ((√(2 * π * v))⁻¹ * exp δ) * exp (-β * (x + γ) ^ 2) := by
    intro x
    rw [gaussianPDFReal, smul_eq_mul, mul_assoc, ← exp_add,
      mul_assoc ((√(2 * π * v))⁻¹) (exp δ), ← exp_add]
    congr 2
    rw [hδ, hβ, hγ]
    field_simp
    rw [hk]
    ring
  simp_rw [hpt]
  rw [integral_const_mul, integral_add_right_eq_self (fun x => exp (-β * x ^ 2)) γ,
    integral_gaussian]
  have h1 : π / β = (2 * π * v) / k := by rw [hβ]; field_simp
  rw [h1, Real.sqrt_div (by positivity)]
  have h2 : (0 : ℝ) < √(2 * π * v) := Real.sqrt_pos.2 (by positivity)
  field_simp

/-- The three-coordinate Gaussian average of `exp (-(q/2) s²)`, `q = |(1,0,0) + x|²`. -/
lemma integral_exp_neg_half_sq_pi (T : ℝ≥0) (hT : T ≠ 0) (s : ℝ) :
    ∫ x, exp (-(((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2) * s ^ 2)
        ∂(Measure.pi fun _ : Fin 3 => gaussianReal 0 T)
      = exp (-(s ^ 2 / (1 + T * s ^ 2)) / 2) / ((1 + T * s ^ 2) * √(1 + T * s ^ 2)) := by
  let f : Fin 3 → ℝ → ℝ := fun i y => exp (-(s ^ 2 / 2) * ((if i = 0 then 1 else 0) + y) ^ 2)
  have hpt : ∀ x : Fin 3 → ℝ, exp (-(((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2) * s ^ 2)
      = ∏ i, f i (x i) := by
    intro x
    simp only [f, Fin.prod_univ_three]
    simp only [Fin.isValue, ↓reduceIte, one_ne_zero, Fin.reduceEq, zero_add]
    rw [← exp_add, ← exp_add]
    congr 1
    ring
  simp_rw [hpt]
  rw [integral_fintype_prod_eq_prod]
  have hlam : (0 : ℝ) ≤ s ^ 2 / 2 := by positivity
  have hk : 1 + 2 * (s ^ 2 / 2) * (T : ℝ) = 1 + T * s ^ 2 := by ring
  simp only [f, integral_exp_neg_mul_sq_add_gaussianReal T hT _ _ hlam, hk, Fin.prod_univ_three]
  simp only [Fin.isValue, ↓reduceIte, one_ne_zero, Fin.reduceEq, one_pow, mul_one, ne_eq,
    OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero, zero_div, exp_zero]
  have hkpos : 0 < 1 + (T : ℝ) * s ^ 2 := by positivity
  have hsq : √(1 + (T : ℝ) * s ^ 2) ^ 2 = 1 + T * s ^ 2 := Real.sq_sqrt hkpos.le
  have hsqpos : 0 < √(1 + (T : ℝ) * s ^ 2) := Real.sqrt_pos.2 hkpos
  have he : -(s ^ 2 / 2) / (1 + T * s ^ 2) = -(s ^ 2 / (1 + T * s ^ 2)) / 2 := by ring
  rw [he]
  field_simp
  rw [hsq]

lemma hasDerivAt_normal_primitive_comp (T : ℝ) (hT : 0 ≤ T) (s : ℝ) :
    HasDerivAt (fun s => ∫ v in (0 : ℝ)..(s / √(1 + T * s ^ 2)), exp (-v ^ 2 / 2))
      (exp (-(s ^ 2 / (1 + T * s ^ 2)) / 2) / ((1 + T * s ^ 2) * √(1 + T * s ^ 2))) s := by
  have hk : 0 < 1 + T * s ^ 2 := by positivity
  have hsqpos : 0 < √(1 + T * s ^ 2) := Real.sqrt_pos.2 hk
  have hsq : √(1 + T * s ^ 2) ^ 2 = 1 + T * s ^ 2 := Real.sq_sqrt hk.le
  have h1 : HasDerivAt (fun s => 1 + T * s ^ 2) (T * (2 * s)) s := by
    have := ((hasDerivAt_pow 2 s).const_mul T).const_add 1
    simpa using this
  have h2 := h1.sqrt hk.ne'
  have h3 := (hasDerivAt_id s).div h2 hsqpos.ne'
  have hu : HasDerivAt (fun s => s / √(1 + T * s ^ 2))
      (1 / ((1 + T * s ^ 2) * √(1 + T * s ^ 2))) s := by
    refine h3.congr_deriv ?_
    simp only [id]
    field_simp
    rw [hsq]
    ring
  have hΨ : HasDerivAt (fun u => ∫ v in (0 : ℝ)..u, exp (-v ^ 2 / 2))
      (exp (-(s / √(1 + T * s ^ 2)) ^ 2 / 2)) (s / √(1 + T * s ^ 2)) :=
    (Continuous.integral_hasStrictDerivAt (by fun_prop) 0 _).hasDerivAt
  refine (hΨ.comp s hu).congr_deriv ?_
  rw [div_pow, hsq]
  field_simp

lemma tendsto_div_sqrt_one_add (T : ℝ) (hT : 0 < T) :
    Tendsto (fun s => s / √(1 + T * s ^ 2)) atTop (𝓝 (1 / √T)) := by
  have key : ∀ s : ℝ, 0 < s → s / √(1 + T * s ^ 2) = √((T + (s ^ 2)⁻¹)⁻¹) := by
    intro s hs
    have h : 1 + T * s ^ 2 = s ^ 2 * (T + (s ^ 2)⁻¹) := by field_simp; ring
    rw [h, Real.sqrt_mul (sq_nonneg s), Real.sqrt_sq hs.le, Real.sqrt_inv]
    have : 0 < √(T + (s ^ 2)⁻¹) := Real.sqrt_pos.2 (by positivity)
    field_simp
  have hlim : Tendsto (fun s : ℝ => √((T + (s ^ 2)⁻¹)⁻¹)) atTop (𝓝 (√((T + 0)⁻¹))) := by
    refine Tendsto.sqrt (Tendsto.inv₀ ?_ (by simp [hT.ne']))
    exact tendsto_const_nhds.add
      (tendsto_inv_atTop_zero.comp (tendsto_pow_atTop two_ne_zero))
  rw [add_zero, Real.sqrt_inv, ← one_div] at hlim
  refine hlim.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with s hs
  exact (key s hs).symm

lemma integral_Ioi_weight (T : ℝ) (hT : 0 < T) :
    IntegrableOn (fun s => exp (-(s ^ 2 / (1 + T * s ^ 2)) / 2)
        / ((1 + T * s ^ 2) * √(1 + T * s ^ 2))) (Set.Ioi 0) ∧
    ∫ s in Set.Ioi (0 : ℝ), exp (-(s ^ 2 / (1 + T * s ^ 2)) / 2)
        / ((1 + T * s ^ 2) * √(1 + T * s ^ 2))
      = ∫ v in (0 : ℝ)..(1 / √T), exp (-v ^ 2 / 2) := by
  have hderiv := hasDerivAt_normal_primitive_comp T hT.le
  have hΨc : Continuous fun u => ∫ v in (0 : ℝ)..u, exp (-v ^ 2 / 2) :=
    continuous_iff_continuousAt.2 fun u =>
      (Continuous.integral_hasStrictDerivAt (by fun_prop) 0 u).hasDerivAt.continuousAt
  have hlim : Tendsto (fun s => ∫ v in (0 : ℝ)..(s / √(1 + T * s ^ 2)), exp (-v ^ 2 / 2))
      atTop (𝓝 (∫ v in (0 : ℝ)..(1 / √T), exp (-v ^ 2 / 2))) :=
    (hΨc.tendsto _).comp (tendsto_div_sqrt_one_add T hT)
  have hcont : ContinuousWithinAt
      (fun s => ∫ v in (0 : ℝ)..(s / √(1 + T * s ^ 2)), exp (-v ^ 2 / 2)) (Set.Ici 0) 0 :=
    (hderiv 0).continuousAt.continuousWithinAt
  have hpos : ∀ s ∈ Set.Ioi (0 : ℝ), 0 ≤ exp (-(s ^ 2 / (1 + T * s ^ 2)) / 2)
      / ((1 + T * s ^ 2) * √(1 + T * s ^ 2)) := fun s _ => by positivity
  refine ⟨integrableOn_Ioi_deriv_of_nonneg hcont (fun s _ => hderiv s) hpos hlim, ?_⟩
  rw [integral_Ioi_of_hasDerivAt_of_nonneg hcont (fun s _ => hderiv s) hpos hlim]
  simp

lemma one_div_sqrt_eq_integral_Ioi (q : ℝ) (hq : 0 ≤ q) :
    1 / √q = 2 / √(2 * π) * ∫ s in Set.Ioi (0 : ℝ), exp (-(q / 2) * s ^ 2) := by
  rw [integral_gaussian_Ioi]
  rcases hq.eq_or_lt with h | h
  · subst h; simp
  · have h1 : π / (q / 2) = (2 * π) / q := by field_simp
    rw [h1, Real.sqrt_div (by positivity)]
    have : 0 < √(2 * π) := Real.sqrt_pos.2 (by positivity)
    have : 0 < √q := Real.sqrt_pos.2 h
    field_simp

lemma two_cdf_standard_normal_sub_one (y : ℝ) :
    2 * cdf (gaussianReal 0 1) y - 1 = 2 / √(2 * π) * ∫ v in (0 : ℝ)..y, exp (-v ^ 2 / 2) := by
  have hφ : ∀ x, gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
    intro x
    simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  have hcdf : cdf (gaussianReal 0 1) y = ∫ x in Set.Iic y, gaussianPDFReal 0 1 x := by
    rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral 0 one_ne_zero,
      ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
        (fun x _ => gaussianPDFReal_nonneg 0 1 x))]
  have hint := integrable_gaussianPDFReal 0 1
  have hsplit := intervalIntegral.integral_Iic_sub_Iic (f := gaussianPDFReal 0 1) (a := 0)
    (b := y) (μ := volume) hint.integrableOn hint.integrableOn
  have hhalf : ∫ x in Set.Iic (0 : ℝ), gaussianPDFReal 0 1 x = 1 / 2 := by
    have heven : (fun x => gaussianPDFReal 0 1 x) = fun x => gaussianPDFReal 0 1 (-x) := by
      funext x; simp only [hφ, even_two, Even.neg_pow]
    rw [heven, integral_comp_neg_Iic, neg_zero]
    simp_rw [hφ]
    rw [integral_const_mul]
    have he : (fun x : ℝ => exp (-x ^ 2 / 2)) = fun x => exp (-(1 / 2) * x ^ 2) := by
      funext x; ring_nf
    rw [he, integral_gaussian_Ioi]
    have h1 : π / (1 / 2) = 2 * π := by field_simp
    rw [h1]
    have : 0 < √(2 * π) := Real.sqrt_pos.2 (by positivity)
    field_simp
  rw [hcdf, ← sub_add_cancel (∫ x in Set.Iic y, gaussianPDFReal 0 1 x)
    (∫ x in Set.Iic (0 : ℝ), gaussianPDFReal 0 1 x), hsplit, hhalf]
  simp_rw [hφ]
  rw [intervalIntegral.integral_const_mul]
  have : 0 < √(2 * π) := Real.sqrt_pos.2 (by positivity)
  field_simp
  ring

end NovikovHelpers2

/-- **Tilt C leaks (Step 5 and its fold).** For the tilt `θ_t = -Z_t`, so `dZ_t = Z_t² dW_t`
from `Z_0 = 1`, the weight at horizon `T` has the law of `1 / |(1, 0, 0) + G|`, where `G` is
three independent normal draws with mean 0 and variance `T` (the three-dimensional Bessel
picture the code uses; that identification is cited on the card, not proved here). Its average
is `2 Φ(1/√T) - 1`, which is below 1: at `T = 1` it is 0.682689, and 0.317311 of the
probability has leaked. Here `Φ` is the standard normal cumulative distribution function. -/
theorem self_feeding_tilt_average (T : ℝ≥0) (hT : 0 < T) :
    ∫ x, 1 / √((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2)
        ∂(Measure.pi fun _ : Fin 3 => gaussianReal 0 T)
      = 2 * cdf (gaussianReal 0 1) (1 / √(T : ℝ)) - 1 := by
  have hT0 : T ≠ 0 := hT.ne'
  have hTr : (0 : ℝ) < T := hT
  have h1 : ∀ x : Fin 3 → ℝ, 1 / √((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2)
      = 2 / √(2 * π) * ∫ s in Set.Ioi (0 : ℝ),
          exp (-(((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2) * s ^ 2) :=
    fun x => one_div_sqrt_eq_integral_Ioi _ (by positivity)
  simp_rw [h1]
  rw [integral_const_mul]
  have hW := integral_Ioi_weight (T : ℝ) hTr
  have hint : Integrable (Function.uncurry fun (x : Fin 3 → ℝ) (s : ℝ) =>
      exp (-(((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2) * s ^ 2))
      ((Measure.pi fun _ : Fin 3 => gaussianReal 0 T).prod
        ((volume : Measure ℝ).restrict (Set.Ioi 0))) := by
    have hc : Continuous (Function.uncurry fun (x : Fin 3 → ℝ) (s : ℝ) =>
        exp (-(((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2) * s ^ 2)) := by
      unfold Function.uncurry; fun_prop
    rw [integrable_prod_iff' hc.aestronglyMeasurable]
    refine ⟨ae_of_all _ fun s => ?_, ?_⟩
    · refine Integrable.of_bound (by fun_prop : Continuous fun x : Fin 3 → ℝ =>
        exp (-(((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2) * s ^ 2)).aestronglyMeasurable 1
        (ae_of_all _ fun x => ?_)
      simp only [Function.uncurry_apply_pair]
      rw [Real.norm_of_nonneg (exp_pos _).le, exp_le_one_iff]
      have : 0 ≤ ((1 + x 0) ^ 2 + x 1 ^ 2 + x 2 ^ 2) / 2 * s ^ 2 := by positivity
      linarith
    · simp only [Function.uncurry_apply_pair, Real.norm_of_nonneg (exp_pos _).le,
        integral_exp_neg_half_sq_pi T hT0]
      exact hW.1
  rw [integral_integral_swap hint]
  simp_rw [integral_exp_neg_half_sq_pi T hT0]
  rw [hW.2, two_cdf_standard_normal_sub_one]

/-! The card's exact worked arithmetic and the proof's algebra. -/

-- Tilt A, the share: θ = (μ - r)/σ = (0.08 - 0.05)/0.20 = 0.15.
example : ((8 : ℚ) / 100 - 5 / 100) / (20 / 100) = 15 / 100 := by norm_num
-- Its square 0.0225, and half the total squared tilt over T = 1 year, 0.01125.
example : ((15 : ℚ) / 100) ^ 2 = 225 / 10000 := by norm_num
example : (225 : ℚ) / 10000 * 1 / 2 = 1125 / 100000 := by norm_num
-- Drift under Q: μ - σ θ = 0.08 - 0.20 × 0.15 = 0.05.
example : (8 : ℚ) / 100 - 20 / 100 * (15 / 100) = 5 / 100 := by norm_num
-- Tilt C at one year: the leaked mass 1 - 0.682689 = 0.317311.
example : (1 : ℚ) - 682689 / 1000000 = 317311 / 1000000 := by norm_num
-- Tilt C without noise: dy = y³ dt from 1 gives y = 1/√(1 - 2t), which blows up at t = 1/2.
example : (1 : ℚ) - 2 * (1 / 2) = 0 := by norm_num
-- Step 5, Ito's lemma for R = 1/Z with dZ = Z² dW: the dW coefficient f'(z) z² is -1 and the
-- dt coefficient f''(z) (z²)² / 2 is z, so dR = -dW + Z dt.
example (z : ℝ) (hz : z ≠ 0) :
    -(1 / z ^ 2) * z ^ 2 = -1 ∧ 1 / 2 * (2 / z ^ 3) * (z ^ 2) ^ 2 = z := by
  constructor <;> field_simp
-- Detailed proof, point 2: Z^(λ) = Z^(λ²) e^(λ(1-λ)M), as an identity of exponents.
example (lam M A : ℝ) :
    lam * M - lam ^ 2 * A / 2 = lam ^ 2 * (M - A / 2) + lam * (1 - lam) * M := by ring
-- Point 3: γ = λ(1-λ)/(1-λ²) = λ/(1+λ), and γ(1-λ²) = λ(1-λ), for 0 < λ < 1.
example (lam : ℝ) (h0 : 0 < lam) (h1 : lam < 1) :
    lam * (1 - lam) / (1 - lam ^ 2) = lam / (1 + lam) := by
  have h2 : (1 - lam ^ 2) ≠ 0 := by nlinarith
  have h3 : (1 + lam) ≠ 0 := by linarith
  field_simp
  ring
example (lam : ℝ) (h1 : lam < 1) (h0 : 0 < lam) :
    lam / (1 + lam) * (1 - lam ^ 2) = lam * (1 - lam) := by
  have h3 : (1 + lam) ≠ 0 := by linarith
  field_simp
  ring
-- Tilt B: with a = c/2, b = c²/2, κ = √(2b) = c, the Cameron-Martin bracket is
-- cosh cT + sinh cT = e^(cT), so E[Z_T] = e^(cT/2) e^(-cT/2) = 1.
example (x : ℝ) : cosh x + sinh x = exp x := by rw [cosh_add_sinh]
example (x : ℝ) : exp (x / 2) * exp (-(x / 2)) = 1 := by rw [← exp_add]; simp

#print axioms nonneg_localMart_lintegral_le
#print axioms nonneg_localMart_supermartingale
#print axioms supermartingale_stopped_martingale
#print axioms stronglyMeasurable_integral_sq_of_slice
#print axioms stronglyAdapted_exp_weight
#print axioms integral_exp_neg_mul_sq_add_gaussianReal
#print axioms integral_exp_neg_half_sq_pi
#print axioms hasDerivAt_normal_primitive_comp
#print axioms tendsto_div_sqrt_one_add
#print axioms integral_Ioi_weight
#print axioms one_div_sqrt_eq_integral_Ioi
#print axioms two_cdf_standard_normal_sub_one
#print axioms exponential_weight_supermartingale
#print axioms self_feeding_tilt_average
