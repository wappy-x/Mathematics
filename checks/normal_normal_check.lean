-- Normal-normal: with a normal prior on an unknown value and independent normal readings of known noise variance, the posterior is normal with the precision-weighted mean and summed precision, and the next reading is normal with the reading noise added to the posterior variance.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Distributions.Gaussian.HasGaussianLaw.Independence
import Mathlib.Probability.Kernel.CondDistrib
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.HasLaw
import Mathlib.MeasureTheory.Constructions.Pi

open MeasureTheory ProbabilityTheory
open scoped NNReal

namespace NormalNormal

lemma condDistrib_add_of_indep {Ω β : Type*} [MeasurableSpace Ω] [MeasurableSpace β]
    {P : Measure Ω} [IsProbabilityMeasure P]
    {Y : Ω → β} {Z : Ω → ℝ} {g : β → ℝ} (hg : Measurable g)
    (hY : AEMeasurable Y P) (hZ : AEMeasurable Z P) (m : ℝ) (v : ℝ≥0)
    (hlaw : P.map Z = gaussianReal m v) (hind : IndepFun Y Z P) :
    ⇑(condDistrib (fun ω => Z ω + g (Y ω)) Y P) =ᵐ[P.map Y]
      fun y => gaussianReal (m + g y) v := by
  let κ : Kernel β ℝ :=
    { toFun := fun y => gaussianReal (m + g y) v
      measurable' := by
        have h := measurable_gaussianReal.comp (f := fun y : β => (m + g y, v)) (by fun_prop)
        exact h }
  have : IsMarkovKernel κ :=
    ⟨fun y => (inferInstance : IsProbabilityMeasure (gaussianReal (m + g y) v))⟩
  have hT : AEMeasurable (fun ω => Z ω + g (Y ω)) P := hZ.add (hg.comp_aemeasurable hY)
  have h := condDistrib_ae_eq_of_measure_eq_compProd (μ := P) (κ := κ) hY hT ?_
  · filter_upwards [h] with y hy
    rw [hy]; rfl
  · rw [show (fun x => (Y x, Z x + g (Y x)))
        = (fun p : β × ℝ => (p.1, p.2 + g p.1)) ∘ (fun x => (Y x, Z x)) from rfl]
    rw [← AEMeasurable.map_map_of_aemeasurable (by fun_prop) (hY.prodMk hZ)]
    rw [(indepFun_iff_map_prod_eq_prod_map_map hY hZ).1 hind, hlaw]
    ext s hs
    rw [Measure.map_apply (by fun_prop) hs, Measure.prod_apply (hs.preimage (by fun_prop)),
      Measure.compProd_apply hs]
    refine lintegral_congr fun y => ?_
    show (gaussianReal m v) _ = (gaussianReal (m + g y) v) _
    rw [← gaussianReal_map_add_const, Measure.map_apply (by fun_prop) (measurable_prodMk_left hs)]
    rfl

#print axioms condDistrib_add_of_indep

lemma cov_lin {Ω ι : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    [Fintype ι] (X : ι → Ω → ℝ) (hX : ∀ k, MemLp (X k) 2 P)
    (hunc : ∀ k l, k ≠ l → cov[X k, X l; P] = 0) (a c : ι → ℝ) :
    cov[fun ω => ∑ k, a k * X k ω, fun ω => ∑ k, c k * X k ω; P]
      = ∑ k, a k * c k * Var[X k; P] := by
  classical
  rw [covariance_fun_sum_fun_sum (X := fun k ω => a k * X k ω) (Y := fun k ω => c k * X k ω)
    (fun k => (hX k).const_mul (a k)) (fun k => (hX k).const_mul (c k))]
  refine Finset.sum_congr rfl fun k _ => ?_
  rw [Finset.sum_eq_single k]
  · rw [covariance_const_mul_left, covariance_const_mul_right,
      covariance_self (hX k).aemeasurable]; ring
  · intro l _ hl
    rw [covariance_const_mul_left, covariance_const_mul_right, hunc k l (Ne.symm hl)]; ring
  · simp

#print axioms cov_lin

lemma gauss_cond {Ω ι : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    [Fintype ι] {n : ℕ} (X : ι → Ω → ℝ)
    (hG : HasGaussianLaw (fun ω k => X k ω) P)
    (μ : ι → ℝ) (σ : ι → ℝ≥0) (hlaw : ∀ k, HasLaw (X k) (gaussianReal (μ k) (σ k)) P)
    (hunc : ∀ k l, k ≠ l → cov[X k, X l; P] = 0)
    (t : ι → ℝ) (c : Fin n → ι → ℝ) (w : Fin n → ℝ)
    (horth : ∀ j, ∑ k, (t k - ∑ i, w i * c i k) * c j k * (σ k : ℝ) = 0) :
    ⇑(condDistrib (fun ω => ∑ k, t k * X k ω) (fun ω j => ∑ k, c j k * X k ω) P)
      =ᵐ[P.map (fun ω j => ∑ k, c j k * X k ω)]
      fun y => gaussianReal (∑ k, (t k - ∑ i, w i * c i k) * μ k + ∑ j, w j * y j)
        (∑ k, (t k - ∑ i, w i * c i k) ^ 2 * (σ k : ℝ)).toNNReal := by
  set a : ι → ℝ := fun k => t k - ∑ i, w i * c i k with ha
  set Z : Ω → ℝ := fun ω => ∑ k, a k * X k ω with hZdef
  set Yv : Ω → Fin n → ℝ := fun ω j => ∑ k, c j k * X k ω with hYdef
  have hXm : ∀ k, MemLp (X k) 2 P := fun k => (hG.eval k).memLp_two
  have hVar : ∀ k, Var[X k; P] = σ k := fun k => by
    rw [(hlaw k).variance_eq, variance_id_gaussianReal]
  have hMean : ∀ k, P[X k] = μ k := fun k => by
    rw [(hlaw k).integral_eq, integral_id_gaussianReal]
  let Lin : (ι → ℝ) →ₗ[ℝ] (Unit → ℝ) × (Fin n → ℝ) :=
    { toFun := fun x => (fun _ => ∑ k, a k * x k, fun j => ∑ k, c j k * x k)
      map_add' := by
        intro x y; ext <;> simp [mul_add, Finset.sum_add_distrib]
      map_smul' := by
        intro r x; ext <;> simp [Finset.mul_sum, mul_left_comm] }
  have hPair : HasGaussianLaw (fun ω => ((fun _ : Unit => Z ω), Yv ω)) P :=
    hG.map_fun (LinearMap.toContinuousLinearMap Lin)
  have hind0 := hPair.indepFun_of_covariance_eval (X := fun _ : Unit => Z)
    (Y := fun j ω => Yv ω j) (fun _ j => by
      rw [cov_lin X hXm hunc a (c j)]; simpa [hVar] using horth j)
  have hind : IndepFun Yv Z P :=
    (hind0.comp (φ := fun u : Unit → ℝ => u ()) (ψ := id) (measurable_pi_apply _)
      measurable_id).symm
  have hZG : HasGaussianLaw Z P := hPair.fst.eval (X := fun _ : Unit => Z) ()
  have hZlaw : P.map Z = gaussianReal (∑ k, a k * μ k) (∑ k, a k ^ 2 * (σ k : ℝ)).toNNReal := by
    rw [hZG.map_eq_gaussianReal]
    congr 1
    · rw [hZdef, integral_finsetSum _ (fun k _ => ((hXm k).integrable one_le_two).const_mul (a k))]
      simp [integral_const_mul, hMean]
    · rw [← covariance_self hZG.aemeasurable, hZdef, cov_lin X hXm hunc a a]
      simp [hVar, sq]
  have hT : (fun ω => ∑ k, t k * X k ω) = fun ω => Z ω + (fun y => ∑ j, w j * y j) (Yv ω) := by
    funext ω
    simp only [hZdef, hYdef, ha, sub_mul, Finset.sum_sub_distrib, Finset.mul_sum, Finset.sum_mul]
    rw [Finset.sum_comm]
    simp [mul_assoc]
  rw [hT]
  exact condDistrib_add_of_indep (g := fun y => ∑ j, w j * y j) (by fun_prop)
    hPair.aemeasurable.snd hZG.aemeasurable _ _ hZlaw hind

#print axioms gauss_cond

lemma opt_family {Ω ι : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    [Fintype ι] (X : ι → Ω → ℝ) (W : Ω → ℝ) (μ : ι → ℝ) (σ : ι → ℝ≥0) (mW : ℝ) (σW : ℝ≥0)
    (hG : HasGaussianLaw (fun ω k => X k ω) P)
    (hlaw : ∀ k, HasLaw (X k) (gaussianReal (μ k) (σ k)) P)
    (hunc : ∀ k l, k ≠ l → cov[X k, X l; P] = 0)
    (hW : HasLaw W (gaussianReal mW σW) P)
    (hind : IndepFun (fun ω k => X k ω) W P) :
    HasGaussianLaw (fun ω (k : Option ι) => Option.elim k (W ω) (fun k => X k ω)) P ∧
    (∀ k : Option ι, HasLaw (fun ω => Option.elim k (W ω) (fun k => X k ω))
      (gaussianReal (Option.elim k mW μ) (Option.elim k σW σ)) P) ∧
    (∀ k l : Option ι, k ≠ l → cov[fun ω => Option.elim k (W ω) (fun k => X k ω),
      fun ω => Option.elim l (W ω) (fun k => X k ω); P] = 0) := by
  have hWG : HasGaussianLaw W P := hW.hasGaussianLaw
  have hXm : ∀ k, MemLp (X k) 2 P := fun k => (hG.eval k).memLp_two
  refine ⟨?_, ?_, ?_⟩
  · have h := IndepFun.hasGaussianLaw hG hWG hind
    let Lin : (ι → ℝ) × ℝ →ₗ[ℝ] (Option ι → ℝ) :=
      { toFun := fun p k => Option.elim k p.2 p.1
        map_add' := by intro p q; ext k; cases k <;> simp
        map_smul' := by intro r p; ext k; cases k <;> simp }
    exact h.map_fun (LinearMap.toContinuousLinearMap Lin)
  · rintro (_ | k)
    · exact hW
    · exact hlaw k
  · have hc : ∀ k, cov[W, X k; P] = 0 := fun k =>
      (hind.comp (φ := fun x : ι → ℝ => x k) (ψ := id) (measurable_pi_apply _)
        measurable_id).symm.covariance_eq_zero hWG.memLp_two (hXm k)
    rintro (_ | k) (_ | l) hkl
    · exact absurd rfl hkl
    · exact hc l
    · simp only [Option.elim]
      rw [covariance_comm]; exact hc k
    · exact hunc k l (fun h => hkl (by rw [h]))

#print axioms opt_family

lemma coord_family {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {n : ℕ} (s2 : ℝ≥0) (ε : Ω → Fin n → ℝ)
    (hε : HasLaw ε (Measure.pi fun _ : Fin n => gaussianReal 0 s2) P) :
    HasGaussianLaw (fun ω i => ε ω i) P ∧
    (∀ i, HasLaw (fun ω => ε ω i) (gaussianReal 0 s2) P) ∧
    (∀ i j, i ≠ j → cov[fun ω => ε ω i, fun ω => ε ω j; P] = 0) := by
  have hc : ∀ i, HasLaw (fun ω => ε ω i) (gaussianReal 0 s2) P := by
    intro i
    have h1 : HasLaw (Function.eval i) (gaussianReal 0 s2)
        (Measure.pi fun _ : Fin n => gaussianReal 0 s2) :=
      ⟨(measurable_pi_apply i).aemeasurable, by rw [Measure.pi_map_eval]; simp⟩
    exact h1.comp hε
  have hi : iIndepFun (fun i ω => ε ω i) P := by
    rw [iIndepFun_iff_map_fun_eq_pi_map (fun i => (hc i).aemeasurable)]
    simp only [(hc _).map_eq]
    exact hε.map_eq
  have hG : HasGaussianLaw (fun ω i => ε ω i) P :=
    hi.hasGaussianLaw (fun i => (hc i).hasGaussianLaw)
  refine ⟨hG, hc, fun i j hij => ?_⟩
  exact (hi.indepFun hij).covariance_eq_zero (hc i).hasGaussianLaw.memLp_two
    (hc j).hasGaussianLaw.memLp_two

#print axioms coord_family

/-- The posterior centre `m_n = (a₀ m₀ + a_D ȳ) / (a₀ + a_D)`, with prior precision
`a₀ = 1 / v₀`, readings' precision `a_D = n / s²` and readings' average `ȳ`. -/
noncomputable def postMean (n : ℕ) (m₀ : ℝ) (v₀ s2 : ℝ≥0) (y : Fin n → ℝ) : ℝ :=
  let a₀ : ℝ := 1 / (v₀ : ℝ)
  let aD : ℝ := (n : ℝ) / (s2 : ℝ)
  let ybar : ℝ := (∑ i, y i) / (n : ℝ)
  (a₀ * m₀ + aD * ybar) / (a₀ + aD)

/-- The posterior variance `v_n = 1 / (a₀ + a_D)`, with `a₀ = 1 / v₀` and `a_D = n / s²`. -/
noncomputable def postVar (n : ℕ) (v₀ s2 : ℝ≥0) : ℝ≥0 :=
  1 / (1 / v₀ + (n : ℝ≥0) / s2)

/-- **Normal-normal update.** Let the true value `θ` have the normal prior `N(m₀, v₀)` with
`v₀ > 0`, and let the `n` readings be `Yᵢ = θ + εᵢ`, where the noises `εᵢ` are independent
`N(0, s²)` with known variance `s² > 0` and independent of `θ` (so the readings are independent
`N(θ, s²)` given `θ`). Then, given the readings `y`, the true value is normal: its law is
`N(m_n, v_n)`, centred at the precision-weighted average of `m₀` and `ȳ`, with precision
`1/v₀ + n/s²`. -/
theorem normal_normal_posterior {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (n : ℕ) (m₀ : ℝ) (v₀ s2 : ℝ≥0) (hv₀ : 0 < v₀) (hs2 : 0 < s2)
    (θ : Ω → ℝ) (ε : Ω → Fin n → ℝ)
    (hθ : HasLaw θ (gaussianReal m₀ v₀) P)
    (hε : HasLaw ε (Measure.pi fun _ : Fin n => gaussianReal 0 s2) P)
    (hind : IndepFun θ ε P) :
    ⇑(condDistrib θ (fun ω i => θ ω + ε ω i) P)
      =ᵐ[P.map (fun ω i => θ ω + ε ω i)]
        fun y => gaussianReal (postMean n m₀ v₀ s2 y) (postVar n v₀ s2) := by
  obtain ⟨hεG, hεc, hεu⟩ := coord_family s2 ε hε
  obtain ⟨hG, hlaw, hunc⟩ := opt_family (fun i ω => ε ω i) θ (fun _ => 0) (fun _ => s2) m₀ v₀
    hεG hεc hεu hθ hind.symm
  have hv : (0 : ℝ) < v₀ := hv₀
  have hs : (0 : ℝ) < s2 := hs2
  set b : ℝ := v₀ / (s2 + n * v₀) with hb
  have key := gauss_cond _ hG _ _ hlaw hunc (fun k => Option.elim k 1 (fun _ => 0))
    (fun j k => Option.elim k 1 (fun i => if i = j then 1 else 0)) (fun _ => b) (by
      intro j
      simp [Fintype.sum_option]
      have : (s2 : ℝ) + n * v₀ ≠ 0 := by positivity
      rw [hb]; field_simp; ring)
  have e1 : (fun ω => ∑ k : Option (Fin n), Option.elim k 1 (fun _ => 0) *
      Option.elim k (θ ω) (fun i => ε ω i)) = θ := by
    funext ω; simp [Fintype.sum_option]
  have e2 : (fun ω (j : Fin n) => ∑ k : Option (Fin n),
      Option.elim k 1 (fun i => if i = j then 1 else 0) *
      Option.elim k (θ ω) (fun i => ε ω i)) = fun ω i => θ ω + ε ω i := by
    funext ω j; simp [Fintype.sum_option]
  rw [e1, e2] at key
  filter_upwards [key] with y hy
  rw [hy]
  congr 1
  · simp [Fintype.sum_option, postMean]
    have : (s2 : ℝ) + n * v₀ ≠ 0 := by positivity
    rw [← Finset.mul_sum, hb]
    rcases Nat.eq_zero_or_pos n with h | h
    · subst h; simp; field_simp
    · have : (n : ℝ) ≠ 0 := by positivity
      field_simp; ring
  · simp [Fintype.sum_option, postVar]
    have : (s2 : ℝ) + n * v₀ ≠ 0 := by positivity
    rw [← NNReal.coe_inj, Real.coe_toNNReal _ (by positivity)]
    push_cast
    rw [hb]; field_simp; ring

/-- **The next reading.** In the same model, take a fresh reading `Y_new = θ + ε_new`, where the
new noise `ε_new` is `N(0, s²)` and independent of the true value and the earlier noises. Given
the readings `y`, the next reading is `N(m_n, v_n + s²)`: centred where the belief is centred,
with the belief's variance plus one reading's noise variance. -/
theorem normal_normal_predictive {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (n : ℕ) (m₀ : ℝ) (v₀ s2 : ℝ≥0) (hv₀ : 0 < v₀) (hs2 : 0 < s2)
    (θ : Ω → ℝ) (ε : Ω → Fin n → ℝ) (εnew : Ω → ℝ)
    (hθ : HasLaw θ (gaussianReal m₀ v₀) P)
    (hε : HasLaw ε (Measure.pi fun _ : Fin n => gaussianReal 0 s2) P)
    (hεnew : HasLaw εnew (gaussianReal 0 s2) P)
    (hind : IndepFun θ ε P)
    (hindnew : IndepFun (fun ω => (θ ω, ε ω)) εnew P) :
    ⇑(condDistrib (fun ω => θ ω + εnew ω) (fun ω i => θ ω + ε ω i) P)
      =ᵐ[P.map (fun ω i => θ ω + ε ω i)]
        fun y => gaussianReal (postMean n m₀ v₀ s2 y) (postVar n v₀ s2 + s2) := by
  obtain ⟨hεG, hεc, hεu⟩ := coord_family s2 ε hε
  obtain ⟨hG1, hlaw1, hunc1⟩ := opt_family (fun i ω => ε ω i) θ (fun _ => 0) (fun _ => s2) m₀ v₀
    hεG hεc hεu hθ hind.symm
  have hind2 : IndepFun (fun ω (k : Option (Fin n)) => Option.elim k (θ ω) (fun i => ε ω i))
      εnew P := by
    have hφ : Measurable (fun (p : ℝ × (Fin n → ℝ)) (k : Option (Fin n)) =>
        Option.elim k p.1 (fun i => p.2 i)) := by
      refine measurable_pi_iff.2 fun k => ?_
      rcases k with _ | i
      · exact measurable_fst
      · exact (measurable_pi_apply i).comp measurable_snd
    exact hindnew.comp hφ measurable_id
  obtain ⟨hG, hlaw, hunc⟩ := opt_family _ εnew _ _ 0 s2 hG1 hlaw1 hunc1 hεnew hind2
  have hv : (0 : ℝ) < v₀ := hv₀
  have hs : (0 : ℝ) < s2 := hs2
  set b : ℝ := v₀ / (s2 + n * v₀) with hb
  have key := gauss_cond _ hG _ _ hlaw hunc
    (fun k => Option.elim k 1 (fun k => Option.elim k 1 (fun _ => 0)))
    (fun j k => Option.elim k 0 (fun k => Option.elim k 1 (fun i => if i = j then 1 else 0)))
    (fun _ => b) (by
      intro j
      simp [Fintype.sum_option]
      have : (s2 : ℝ) + n * v₀ ≠ 0 := by positivity
      rw [hb]; field_simp; ring)
  have e1 : (fun ω => ∑ k : Option (Option (Fin n)),
      Option.elim k 1 (fun k => Option.elim k 1 (fun _ => 0)) *
      Option.elim k (εnew ω) (fun k => Option.elim k (θ ω) (fun i => ε ω i)))
        = fun ω => θ ω + εnew ω := by
    funext ω; simp [Fintype.sum_option]; ring
  have e2 : (fun ω (j : Fin n) => ∑ k : Option (Option (Fin n)),
      Option.elim k 0 (fun k => Option.elim k 1 (fun i => if i = j then 1 else 0)) *
      Option.elim k (εnew ω) (fun k => Option.elim k (θ ω) (fun i => ε ω i)))
        = fun ω i => θ ω + ε ω i := by
    funext ω j; simp [Fintype.sum_option]
  rw [e1, e2] at key
  filter_upwards [key] with y hy
  rw [hy]
  congr 1
  · simp [Fintype.sum_option, postMean]
    have : (s2 : ℝ) + n * v₀ ≠ 0 := by positivity
    rw [← Finset.mul_sum, hb]
    rcases Nat.eq_zero_or_pos n with h | h
    · subst h; simp; field_simp
    · have : (n : ℝ) ≠ 0 := by positivity
      field_simp; ring
  · simp [Fintype.sum_option, postVar]
    have : (s2 : ℝ) + n * v₀ ≠ 0 := by positivity
    rw [← NNReal.coe_inj, Real.coe_toNNReal _ (by positivity)]
    push_cast
    rw [hb]; field_simp; ring

/-- **Completing the square (Step 3).** For precisions `a₀ > 0` and `a_D ≥ 0`, the weighted sum
of squares `a₀(θ - m₀)² + a_D(θ - ȳ)²` equals `(a₀ + a_D)(θ - m_n)²` plus a term free of `θ`,
where `m_n` is the precision-weighted average: precisions add. -/
theorem precision_weighted_complete_square (a₀ aD m₀ ybar θ : ℝ) (ha₀ : 0 < a₀) (haD : 0 ≤ aD) :
    a₀ * (θ - m₀) ^ 2 + aD * (θ - ybar) ^ 2
      = (a₀ + aD) * (θ - (a₀ * m₀ + aD * ybar) / (a₀ + aD)) ^ 2
        + a₀ * aD / (a₀ + aD) * (ybar - m₀) ^ 2 := by
  have h : a₀ + aD ≠ 0 := by positivity
  field_simp
  ring

/-! The card's worked numbers, as exact fractions: prior centre 20, prior variance 1/4,
noise variance 1, five readings 21.3, 19.8, 22.1, 20.9, 21.4. -/

-- the readings sum to 105.5 and average 21.1
example : (213 / 10 + 198 / 10 + 221 / 10 + 209 / 10 + 214 / 10 : ℚ) = 211 / 2 := by norm_num
example : ((211 / 2 : ℚ)) / 5 = 211 / 10 := by norm_num
-- prior precision 1/0.25 = 4, readings' precision 5/1.0 = 5, total 9
example : (1 / (1 / 4) : ℚ) = 4 := by norm_num
example : ((5 : ℚ) / 1) = 5 ∧ (4 : ℚ) + 5 = 9 := by norm_num
-- posterior centre (4 × 20 + 5 × 21.1)/9 = 371/18 = 20.6111...
example : ((4 * 20 + 5 * (211 / 10)) / 9 : ℚ) = 371 / 18 := by norm_num
-- posterior variance 1/9 (spread 1/3) and predictive variance 1/9 + 1 = 10/9
example : ((1 : ℚ) / 9) = (1 / 3) ^ 2 ∧ (1 : ℚ) / 9 + 1 = 10 / 9 := by norm_num
-- sequential update: after the first reading, (4 × 20 + 1 × 21.3)/5 = 20.26
example : ((4 * 20 + 1 * (213 / 10)) / 5 : ℚ) = 2026 / 100 := by norm_num
-- mistake: weighting by variances gives (0.25 × 20 + 0.2 × 21.1)/0.45 = 9.22/0.45 = 20.4888...
example : (((1 / 4) * 20 + (1 / 5) * (211 / 10)) / (1 / 4 + 1 / 5) : ℚ) = 922 / 45 := by norm_num
-- mistake: five readings counted as one gives (4 × 20 + 1 × 21.1)/5 = 20.22
example : ((4 * 20 + 1 * (211 / 10)) / 5 : ℚ) = 1011 / 50 := by norm_num
-- correlated errors: average's error variance 0.5 + 0.5/5 = 0.6, and the centre's true error
-- variance (4/9)² × 0.25 + (5/9)² × 0.6 = 19/81
example : ((1 / 2 + (1 / 2) / 5 : ℚ)) = 3 / 5 := by norm_num
example : ((4 / 9) ^ 2 * (1 / 4) + (5 / 9) ^ 2 * (3 / 5) : ℚ) = 19 / 81 := by norm_num
-- the step-3 leftover coefficient a₀a_D/(a₀ + a_D) = 20/9 equals 1/(v₀ + s²/n) = 1/0.45
example : ((4 : ℚ) * 5 / (4 + 5)) = 20 / 9 ∧ 1 / ((1 : ℚ) / 4 + 1 / 5) = 20 / 9 := by norm_num

#print axioms normal_normal_posterior
#print axioms normal_normal_predictive
#print axioms precision_weighted_complete_square

end NormalNormal
