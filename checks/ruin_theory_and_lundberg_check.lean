-- Ruin: in the Cramér–Lundberg model, with Poisson claim arrivals, independent light-tailed claims and a positive loading, the chance the surplus ever drops below zero is at most e^(-R u), where R is the positive root of λ(M_X(R) - 1) = c R.
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Probability.Moments.Basic
import Mathlib.Probability.IdentDistrib
import Mathlib.Probability.Independence.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Real

theorem lintegral_ofReal_exp_expMeasure_lt {a s : ℝ} (ha : 0 < a) (hs : s < a) :
    ∫⁻ x, ENNReal.ofReal (exp (s * x)) ∂(expMeasure a) = ENNReal.ofReal (a / (a - s)) := by
  have has : 0 < a - s := by linarith
  have hg : Measurable (gammaPDF 1 a) := (measurable_gammaPDFReal 1 a).ennreal_ofReal
  rw [expMeasure, gammaMeasure, lintegral_withDensity_eq_lintegral_mul _ hg (by fun_prop)]
  have key : ∀ x, (gammaPDF 1 a * fun x => ENNReal.ofReal (exp (s * x))) x
      = ENNReal.ofReal (a / (a - s)) * exponentialPDF (a - s) x := by
    intro x
    show exponentialPDF a x * ENNReal.ofReal (exp (s * x)) = _
    rcases lt_or_ge x 0 with hx | hx
    · simp [exponentialPDF_of_neg hx]
    · rw [exponentialPDF_of_nonneg hx, exponentialPDF_of_nonneg hx,
        ← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul (by positivity)]
      congr 1
      rw [mul_assoc, ← exp_add]
      field_simp
      ring_nf
  simp_rw [key]
  have hg2 : Measurable (exponentialPDF (a - s)) := (measurable_gammaPDFReal 1 (a - s)).ennreal_ofReal
  rw [lintegral_const_mul _ hg2,
    lintegral_exponentialPDF_eq_one has, mul_one]

theorem lintegral_ofReal_exp_expMeasure_ge {a s : ℝ} (ha : 0 < a) (hs : a ≤ s) :
    ∫⁻ x, ENNReal.ofReal (exp (s * x)) ∂(expMeasure a) = ⊤ := by
  have hg : Measurable (gammaPDF 1 a) := (measurable_gammaPDFReal 1 a).ennreal_ofReal
  rw [expMeasure, gammaMeasure, lintegral_withDensity_eq_lintegral_mul _ hg (by fun_prop)]
  apply eq_top_iff.mpr
  calc (⊤ : ENNReal) = ∫⁻ x, (Set.Ici (0:ℝ)).indicator (fun _ => ENNReal.ofReal a) x := by
        rw [lintegral_indicator measurableSet_Ici, setLIntegral_const, Real.volume_Ici,
          ENNReal.mul_top (by simp [ha])]
    _ ≤ _ := by
        apply lintegral_mono
        intro x
        show _ ≤ exponentialPDF a x * ENNReal.ofReal (exp (s * x))
        by_cases hx : x ∈ Set.Ici (0:ℝ)
        · rw [Set.indicator_of_mem hx]
          rw [Set.mem_Ici] at hx
          rw [exponentialPDF_of_nonneg hx, ← ENNReal.ofReal_mul (by positivity)]
          apply ENNReal.ofReal_le_ofReal
          rw [mul_assoc, ← exp_add]
          have : 1 ≤ exp (-(a * x) + s * x) := one_le_exp (by nlinarith)
          nlinarith
        · rw [Set.indicator_of_notMem hx]; exact zero_le

theorem indepFun_of_depends {Ω ι : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    (f : ι → Ω → ℝ) (hf : iIndepFun f P) (hmeas : ∀ i, Measurable (f i))
    (S T : Set ι) (hST : Disjoint S T) {β γ : Type*} [MeasurableSpace β] [MeasurableSpace γ]
    (F : (ι → ℝ) → β) (G : (ι → ℝ) → γ) (hF : Measurable F) (hG : Measurable G)
    (hFS : ∀ v v' : ι → ℝ, (∀ i ∈ S, v i = v' i) → F v = F v')
    (hGT : ∀ v v' : ι → ℝ, (∀ i ∈ T, v i = v' i) → G v = G v') :
    IndepFun (fun ω => F (fun i => f i ω)) (fun ω => G (fun i => f i ω)) P := by
  classical
  let eS : (S → ℝ) → (ι → ℝ) := fun w i => if h : i ∈ S then w ⟨i, h⟩ else 0
  let eT : (T → ℝ) → (ι → ℝ) := fun w i => if h : i ∈ T then w ⟨i, h⟩ else 0
  have heS : Measurable eS := by
    refine Measurable.of_eval (fun i => ?_)
    by_cases h : i ∈ S
    · simp only [eS, h, dite_true]; exact measurable_pi_apply _
    · simp only [eS, h, dite_false]; exact measurable_const
  have heT : Measurable eT := by
    refine Measurable.of_eval (fun i => ?_)
    by_cases h : i ∈ T
    · simp only [eT, h, dite_true]; exact measurable_pi_apply _
    · simp only [eT, h, dite_false]; exact measurable_const
  have h1 : (fun ω => F (fun i => f i ω)) = (F ∘ eS) ∘ (fun ω (i : S) => f i ω) := by
    funext ω; exact hFS _ _ (fun i hi => by simp [eS, hi])
  have h2 : (fun ω => G (fun i => f i ω)) = (G ∘ eT) ∘ (fun ω (i : T) => f i ω) := by
    funext ω; exact hGT _ _ (fun i hi => by simp [eT, hi])
  rw [h1, h2]
  exact (hf.indepFun_set S T hST hmeas).comp (hF.comp heS) (hG.comp heT)

theorem lintegral_mul_of_depends {Ω ι : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    (f : ι → Ω → ℝ) (hf : iIndepFun f P) (hmeas : ∀ i, Measurable (f i))
    (S T : Set ι) (hST : Disjoint S T)
    (F G : (ι → ℝ) → ENNReal) (hF : Measurable F) (hG : Measurable G)
    (hFS : ∀ v v' : ι → ℝ, (∀ i ∈ S, v i = v' i) → F v = F v')
    (hGT : ∀ v v' : ι → ℝ, (∀ i ∈ T, v i = v' i) → G v = G v') :
    ∫⁻ ω, F (fun i => f i ω) * G (fun i => f i ω) ∂P
      = (∫⁻ ω, F (fun i => f i ω) ∂P) * ∫⁻ ω, G (fun i => f i ω) ∂P := by
  have hV : Measurable (fun ω i => f i ω) := Measurable.of_eval hmeas
  exact lintegral_mul_eq_lintegral_mul_lintegral_of_indepFun'' (hF.comp hV).aemeasurable
    (hG.comp hV).aemeasurable (indepFun_of_depends f hf hmeas S T hST F G hF hG hFS hGT)

/-- The coordinates of block `B`: claim sizes and waits with index in `B`. -/
def blk (B : Set ℕ) : Set (ℕ ⊕ ℕ) := {k | Sum.elim (· ∈ B) (· ∈ B) k}

theorem blk_disjoint {B B' : Set ℕ} (h : Disjoint B B') : Disjoint (blk B) (blk B') := by
  rw [Set.disjoint_left]
  intro k hk hk'
  cases k with
  | inl i => exact Set.disjoint_left.mp h hk hk'
  | inr i => exact Set.disjoint_left.mp h hk hk'

/-- The chance that the sum of `m` independent exponential waits with rate `lam` is at most `t`. -/
noncomputable def erlH (lam : ℝ) (m : ℕ) (t : ℝ) : ℝ :=
  if 0 ≤ t then 1 - exp (-(lam * t)) * ∑ j ∈ Finset.range m, (lam * t) ^ j / (Nat.factorial j : ℝ)
  else 0

theorem erlH_nonneg {lam : ℝ} (hlam : 0 ≤ lam) (m : ℕ) (t : ℝ) : 0 ≤ erlH lam m t := by
  unfold erlH
  split_ifs with ht
  · have h1 := Real.sum_le_exp_of_nonneg (mul_nonneg hlam ht) m
    have h2 : exp (-(lam * t)) * exp (lam * t) = 1 := by rw [← exp_add]; simp
    have h3 : exp (-(lam * t)) * ∑ j ∈ Finset.range m, (lam * t) ^ j / (Nat.factorial j : ℝ)
        ≤ exp (-(lam * t)) * exp (lam * t) := mul_le_mul_of_nonneg_left h1 (exp_pos _).le
    linarith
  · exact le_rfl

theorem erlH_conv {lam : ℝ} (hlam : 0 < lam) (m : ℕ) (t : ℝ) :
    ∫⁻ y, ENNReal.ofReal (erlH lam m (t - y)) ∂(expMeasure lam)
      = ENNReal.ofReal (erlH lam (m + 1) t) := by
  have hmeas : Measurable (gammaPDF 1 lam) := (measurable_gammaPDFReal 1 lam).ennreal_ofReal
  rw [expMeasure, gammaMeasure, lintegral_withDensity_eq_lintegral_mul_non_measurable _ hmeas
    (Filter.Eventually.of_forall (fun _ => ENNReal.ofReal_lt_top))]
  rcases lt_or_ge t 0 with ht | ht
  · have hz : ∀ y, (gammaPDF 1 lam * fun y => ENNReal.ofReal (erlH lam m (t - y))) y = 0 := by
      intro y
      show exponentialPDF lam y * _ = 0
      rcases lt_or_ge y 0 with hy | hy
      · simp [exponentialPDF_of_neg hy]
      · simp [erlH, show ¬ (0 ≤ t - y) by linarith]
    simp only [hz, lintegral_zero]
    simp [erlH, not_le.mpr ht]
  set φ : ℝ → ℝ := fun y => lam * exp (-(lam * y)) - lam * exp (-(lam * t)) *
    ∑ j ∈ Finset.range m, (lam * (t - y)) ^ j / (Nat.factorial j : ℝ) with hφ
  have hφeq : ∀ y, y ≤ t → φ y = lam * exp (-(lam * y)) * erlH lam m (t - y) := by
    intro y hyt
    simp only [hφ, erlH, if_pos (sub_nonneg.mpr hyt)]
    have : exp (-(lam * y)) * exp (-(lam * (t - y))) = exp (-(lam * t)) := by
      rw [← exp_add]; ring_nf
    linear_combination (lam * ∑ j ∈ Finset.range m, (lam * (t - y)) ^ j / (Nat.factorial j : ℝ))
      * this
  have hpt : ∀ y, (gammaPDF 1 lam * fun y => ENNReal.ofReal (erlH lam m (t - y))) y
      = (Set.Icc 0 t).indicator (fun y => ENNReal.ofReal (φ y)) y := by
    intro y
    show exponentialPDF lam y * _ = _
    rcases lt_or_ge y 0 with hy | hy
    · rw [exponentialPDF_of_neg hy, zero_mul, Set.indicator_of_notMem
        (show y ∉ Set.Icc 0 t from fun h => by linarith [h.1])]
    · by_cases hyt : y ≤ t
      · rw [Set.indicator_of_mem (show y ∈ Set.Icc 0 t from ⟨hy, hyt⟩), exponentialPDF_of_nonneg hy,
          ← ENNReal.ofReal_mul (by positivity), hφeq y hyt]
      · rw [Set.indicator_of_notMem (show y ∉ Set.Icc 0 t from fun h => hyt h.2)]
        simp [erlH, show ¬ 0 ≤ t - y by linarith]
  simp only [hpt]
  have hφc : Continuous φ := by rw [hφ]; fun_prop
  rw [lintegral_indicator measurableSet_Icc, ← ofReal_integral_eq_lintegral_ofReal
    (hφc.integrableOn_Icc) ((ae_restrict_iff' measurableSet_Icc).mpr
      (Filter.Eventually.of_forall (fun y hy => by
        rw [hφeq y hy.2]
        exact mul_nonneg (by positivity) (erlH_nonneg hlam.le _ _))))]
  congr 1
  set F : ℝ → ℝ := fun y => -exp (-(lam * y)) + exp (-(lam * t)) *
    ∑ j ∈ Finset.range m, (lam * (t - y)) ^ (j + 1) / (Nat.factorial (j + 1) : ℝ) with hF
  have hderiv : ∀ y, HasDerivAt F (φ y) y := by
    intro y
    have h1 : HasDerivAt (fun y => -exp (-(lam * y))) (lam * exp (-(lam * y))) y := by
      refine (((hasDerivAt_id y).const_mul lam).neg.exp).neg.congr_deriv ?_
      simp [mul_comm]
    have h2 : ∀ j ∈ Finset.range m, HasDerivAt
        (fun y => (lam * (t - y)) ^ (j + 1) / (Nat.factorial (j + 1) : ℝ))
        (-(lam * ((lam * (t - y)) ^ j / (Nat.factorial j : ℝ)))) y := by
      intro j _
      have := ((((hasDerivAt_id y).const_sub t).const_mul lam).pow (j + 1)).div_const
        (Nat.factorial (j + 1) : ℝ)
      refine this.congr_deriv ?_
      simp only [id, Nat.add_sub_cancel, Nat.factorial_succ]
      push_cast
      field_simp
    have h3 := (HasDerivAt.fun_sum h2).const_mul (exp (-(lam * t)))
    convert h1.add h3 using 1
    rw [hφ]
    simp only [Finset.sum_neg_distrib, ← Finset.mul_sum]
    ring
  rw [MeasureTheory.integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le ht,
    intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => hderiv y)
      (hφc.intervalIntegrable _ _)]
  simp only [hF, erlH, if_pos ht, Finset.sum_range_succ', sub_self, mul_zero]
  simp
  ring

theorem erlang_cdf {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (lam : ℝ) (hlam : 0 < lam) (W : ℕ → Ω → ℝ) (hWmeas : ∀ i, Measurable (W i))
    (hWexp : ∀ i, P.map (W i) = expMeasure lam) (hW : iIndepFun W P) (m : ℕ) (t : ℝ) :
    P {ω | ∑ j ∈ Finset.range m, W j ω ≤ t} = ENNReal.ofReal (erlH lam m t) := by
  induction m generalizing t with
  | zero => by_cases ht : 0 ≤ t <;> simp [erlH, ht]
  | succ m ih =>
    set Sm : Ω → ℝ := fun ω => ∑ j ∈ Finset.range m, W j ω with hSmdef
    have hSm : Measurable Sm := Finset.measurable_fun_sum _ (fun j _ => hWmeas j)
    have hind : IndepFun Sm (W m) P := by
      have := hW.indepFun_finsetSum_of_notMem hWmeas (Finset.notMem_range_self (n := m))
      convert this using 1
      funext ω
      simp [Sm, Finset.sum_apply]
    have hset : {ω | ∑ j ∈ Finset.range (m + 1), W j ω ≤ t}
        = (fun ω => (Sm ω, W m ω)) ⁻¹' {p : ℝ × ℝ | p.1 + p.2 ≤ t} := by
      ext ω; simp [Finset.sum_range_succ, Sm]
    have hmeasS : MeasurableSet {p : ℝ × ℝ | p.1 + p.2 ≤ t} :=
      measurableSet_le (by fun_prop) measurable_const
    rw [hset, ← Measure.map_apply (by fun_prop) hmeasS,
      (indepFun_iff_map_prod_eq_prod_map_map hSm.aemeasurable (hWmeas m).aemeasurable).mp hind,
      Measure.prod_apply_symm hmeasS, hWexp m]
    have hy : ∀ y, (P.map Sm) ((fun x => (x, y)) ⁻¹' {p : ℝ × ℝ | p.1 + p.2 ≤ t})
        = ENNReal.ofReal (erlH lam m (t - y)) := by
      intro y
      rw [Measure.map_apply hSm ((by fun_prop : Measurable (fun x : ℝ => (x, y))) hmeasS), ← ih (t - y)]
      congr 1
      ext ω
      simp only [Set.mem_preimage, Set.mem_setOf_eq, Sm]
      constructor <;> intro h <;> linarith
    simp_rw [hy]
    exact erlH_conv hlam m t

/-- Lundberg's inequality. An insurer starts with surplus `u` and collects premium at `c`
dollars a year. Claims arrive as a Poisson stream with `lam > 0` claims a year: the waits
`W 0, W 1, ...` between claims are independent and exponential with rate `lam`, so claim `i`
arrives at time `T_i = W 0 + ... + W i`. Claim sizes `X 0, X 1, ...` are nonnegative, have one
common law, and are independent of each other and of the timing. The loading is positive:
`c > lam * E[X]`. The adjustment coefficient `R > 0` has `M_X(R) = E[e^(R X)]` finite and solves
`lam * (M_X(R) - 1) = c * R`. The surplus at time `t ≥ 0` is `u + c t` minus every claim that has
arrived by `t`; it is below zero exactly when, for some `n`, `u + c t` minus the claims among the
first `n` that have arrived by `t` is below zero. Then the chance that the surplus is ever below
zero is at most `e^(-R u)`. -/
theorem lundberg_inequality
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (lam c u R : ℝ) (hlam : 0 < lam)
    (X W : ℕ → Ω → ℝ) (hXmeas : ∀ i, Measurable (X i)) (hWmeas : ∀ i, Measurable (W i))
    (hXnonneg : ∀ i ω, 0 ≤ X i ω)
    (hXident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hWexp : ∀ i, P.map (W i) = expMeasure lam)
    (hindep : iIndepFun (fun k : ℕ ⊕ ℕ => Sum.elim X W k) P)
    (hload : lam * ∫ ω, X 0 ω ∂P < c)
    (hR : 0 < R) (hlight : Integrable (fun ω => exp (R * X 0 ω)) P)
    (hadj : lam * (mgf (X 0) P R - 1) = c * R) :
    P.real {ω | ∃ t : ℝ, 0 ≤ t ∧ ∃ n : ℕ,
        u + c * t - ∑ i ∈ (Finset.range n).filter
          (fun i => ∑ j ∈ Finset.range (i + 1), W j ω ≤ t), X i ω < 0}
      ≤ exp (-R * u) := by
  classical
  set f : ℕ ⊕ ℕ → Ω → ℝ := fun k => Sum.elim X W k with hfdef
  have hfmeas : ∀ k, Measurable (f k) := by
    intro k
    cases k with
    | inl i => exact hXmeas i
    | inr i => exact hWmeas i
  have hEX : 0 ≤ ∫ ω, X 0 ω ∂P := integral_nonneg (hXnonneg 0)
  have hc : 0 < c := by nlinarith
  rcases lt_or_ge u 0 with hu | hu
  · calc _ ≤ 1 := measureReal_le_one
      _ ≤ exp (-R * u) := one_le_exp (by nlinarith)
  -- functions of the whole vector of claims and waits
  let s : ℕ → (ℕ ⊕ ℕ → ℝ) → ℝ := fun n v =>
    ∑ i ∈ Finset.range n, (v (Sum.inl i) - c * v (Sum.inr i))
  let A : ℕ → Set (ℕ ⊕ ℕ → ℝ) := fun k => {v | u < s (k + 1) v ∧ ∀ j < k, s (j + 1) v ≤ u}
  let z : ℕ → (ℕ ⊕ ℕ → ℝ) → ENNReal := fun i v =>
    ENNReal.ofReal (exp (R * (v (Sum.inl i) - c * v (Sum.inr i))))
  let g : ℕ → (ℕ ⊕ ℕ → ℝ) → ENNReal := fun n v => ENNReal.ofReal (exp (R * s n v))
  let V : Ω → (ℕ ⊕ ℕ → ℝ) := fun ω k => f k ω
  have hV : Measurable V := Measurable.of_eval hfmeas
  have hs : ∀ n, Measurable (s n) := by
    intro n
    apply Finset.measurable_sum
    intro i _
    fun_prop
  have hA : ∀ k, MeasurableSet (A k) := by
    intro k
    have : A k = {v | u < s (k + 1) v} ∩ ⋂ j ∈ Finset.range k, {v | s (j + 1) v ≤ u} := by
      ext v; simp [A]
    rw [this]
    exact (measurableSet_lt measurable_const (hs _)).inter
      (Finset.measurableSet_biInter _ (fun j _ => measurableSet_le (hs _) measurable_const))
  have hz : ∀ i, Measurable (z i) := by
    intro i
    fun_prop
  have hg : ∀ n, Measurable (g n) := fun n => by
    have := hs n
    fun_prop
  have hgprod : ∀ n v, g n v = ∏ i ∈ Finset.range n, z i v := by
    intro n v
    simp only [g, s, z]
    rw [Finset.mul_sum, exp_sum, ENNReal.ofReal_prod_of_nonneg (fun i _ => (exp_pos _).le)]
  -- one step has mean one
  have hM0 : 0 ≤ mgf (X 0) P R := mgf_nonneg
  have hz1 : ∀ i, ∫⁻ ω, z i (V ω) ∂P = 1 := by
    intro i
    have hsplit : ∀ ω, z i (V ω) = ENNReal.ofReal (exp (R * X i ω))
        * ENNReal.ofReal (exp ((-(c * R)) * W i ω)) := by
      intro ω
      simp only [z, V, hfdef, Sum.elim_inl, Sum.elim_inr]
      rw [← ENNReal.ofReal_mul (exp_pos _).le, ← exp_add]
      ring_nf
    simp_rw [hsplit]
    have hind : IndepFun (X i) (W i) P := hindep.indepFun Sum.inl_ne_inr
    rw [lintegral_mul_eq_lintegral_mul_lintegral_of_indepFun''
      ((hXmeas i).const_mul R).exp.ennreal_ofReal.aemeasurable
      ((hWmeas i).const_mul _).exp.ennreal_ofReal.aemeasurable
      (hind.comp (φ := fun x => ENNReal.ofReal (exp (R * x)))
        (ψ := fun x => ENNReal.ofReal (exp ((-(c * R)) * x))) (by fun_prop) (by fun_prop))]
    have e1 : ∫⁻ ω, ENNReal.ofReal (exp (R * X i ω)) ∂P = ENNReal.ofReal (mgf (X 0) P R) := by
      have := ((hXident i).comp (u := fun x => ENNReal.ofReal (exp (R * x)))
        (by fun_prop)).lintegral_eq
      simp only [Function.comp_def] at this
      rw [this, mgf, ofReal_integral_eq_lintegral_ofReal hlight
        (Filter.Eventually.of_forall (fun ω => (exp_pos _).le))]
    have e2 : ∫⁻ ω, ENNReal.ofReal (exp ((-(c * R)) * W i ω)) ∂P
        = ENNReal.ofReal (lam / (lam - (-(c * R)))) := by
      rw [← lintegral_map (f := fun x => ENNReal.ofReal (exp ((-(c * R)) * x))) (by fun_prop)
        (hWmeas i), hWexp i]
      exact lintegral_ofReal_exp_expMeasure_lt hlam (by nlinarith)
    rw [e1, e2, ← ENNReal.ofReal_mul hM0]
    have hden : 0 < lam - -(c * R) := by nlinarith
    have : mgf (X 0) P R * (lam / (lam - -(c * R))) = 1 := by
      rw [mul_div_assoc', div_eq_one_iff_eq hden.ne']
      linarith
    rw [this, ENNReal.ofReal_one]
  -- products over any finite set of steps have mean one
  have hzprod : ∀ t : Finset ℕ, ∫⁻ ω, ∏ i ∈ t, z i (V ω) ∂P = 1 := by
    intro t
    induction t using Finset.induction_on with
    | empty => simp
    | insert j t hj ih =>
      simp_rw [Finset.prod_insert hj]
      rw [lintegral_mul_of_depends f hindep hfmeas (blk {j}) (blk ↑t)
        (blk_disjoint (by simpa using hj)) (z j) (fun v => ∏ i ∈ t, z i v) (hz j)
        (Finset.measurable_prod _ (fun i _ => hz i)) ?_ ?_]
      · change (∫⁻ ω, z j (V ω) ∂P) * ∫⁻ ω, ∏ i ∈ t, z i (V ω) ∂P = 1
        rw [hz1, ih, one_mul]
      · intro v v' h
        simp only [z]
        rw [h (Sum.inl j) (by simp [blk]), h (Sum.inr j) (by simp [blk])]
      · intro v v' h
        apply Finset.prod_congr rfl
        intro i hi
        simp only [z]
        rw [h (Sum.inl i) (by simp [blk, hi]), h (Sum.inr i) (by simp [blk, hi])]
  -- the sets A k are disjoint
  have hAdisj : ∀ k k' v, v ∈ A k → v ∈ A k' → k = k' := by
    intro k k' v hk hk'
    by_contra hne
    rcases Nat.lt_or_gt_of_ne hne with h | h
    · exact absurd (hk'.2 k h) (not_le.mpr hk.1)
    · exact absurd (hk.2 k' h) (not_le.mpr hk'.1)
  -- key bound for each N
  have hfin : ∀ N, ∑ k ∈ Finset.range N, P (V ⁻¹' A k) ≤ ENNReal.ofReal (exp (-R * u)) := by
    intro N
    have hstep : ∀ k ∈ Finset.range N, ENNReal.ofReal (exp (R * u)) * P (V ⁻¹' A k)
        ≤ ∫⁻ ω, (A k).indicator (g N) (V ω) ∂P := by
      intro k hk
      have hkN : k + 1 ≤ N := Finset.mem_range.mp hk
      have e1 : ENNReal.ofReal (exp (R * u)) * P (V ⁻¹' A k)
          ≤ ∫⁻ ω, (A k).indicator (g (k + 1)) (V ω) ∂P := by
        rw [← lintegral_indicator_const (hV (hA k))]
        apply lintegral_mono
        intro ω
        dsimp only
        by_cases hω : V ω ∈ A k
        · rw [Set.indicator_of_mem (show ω ∈ V ⁻¹' A k from hω), Set.indicator_of_mem hω]
          exact ENNReal.ofReal_le_ofReal (exp_le_exp.mpr
            (mul_le_mul_of_nonneg_left hω.1.le hR.le))
        · rw [Set.indicator_of_notMem (show ω ∉ V ⁻¹' A k from hω)]
          exact zero_le
      have hsplit : ∀ v, (A k).indicator (g N) v
          = (A k).indicator (g (k + 1)) v * ∏ i ∈ Finset.Ico (k + 1) N, z i v := by
        intro v
        by_cases hv : v ∈ A k
        · rw [Set.indicator_of_mem hv, Set.indicator_of_mem hv, hgprod, hgprod,
            ← Finset.prod_range_mul_prod_Ico _ hkN]
        · simp [hv]
      have e2 : ∫⁻ ω, (A k).indicator (g N) (V ω) ∂P
          = ∫⁻ ω, (A k).indicator (g (k + 1)) (V ω) ∂P := by
        simp_rw [hsplit]
        rw [lintegral_mul_of_depends f hindep hfmeas (blk {i | i < k + 1}) (blk {i | k + 1 ≤ i})
          (blk_disjoint ?_) ((A k).indicator (g (k + 1)))
          (fun v => ∏ i ∈ Finset.Ico (k + 1) N, z i v)
          ((hg _).indicator (hA k)) (Finset.measurable_prod _ (fun i _ => hz i)) ?_ ?_]
        · change (∫⁻ ω, (A k).indicator (g (k + 1)) (V ω) ∂P)
            * ∫⁻ ω, ∏ i ∈ Finset.Ico (k + 1) N, z i (V ω) ∂P = _
          rw [hzprod, mul_one]
        · rw [Set.disjoint_left]; intro i h1 h2; simp at h1 h2; omega
        · intro v v' h
          have key : ∀ n ≤ k + 1, s n v = s n v' := by
            intro n hn
            apply Finset.sum_congr rfl
            intro i hi
            have hi' : i < k + 1 := by simp at hi; omega
            rw [h (Sum.inl i) (by simpa [blk] using hi'), h (Sum.inr i) (by simpa [blk] using hi')]
          have hmem : v ∈ A k ↔ v' ∈ A k := by
            simp only [A, Set.mem_ofPred_eq]
            rw [key (k + 1) le_rfl]
            exact and_congr_right' (forall₂_congr (fun j hj => by rw [key (j + 1) (by omega)]))
          by_cases hv : v ∈ A k
          · rw [Set.indicator_of_mem hv, Set.indicator_of_mem (hmem.mp hv)]
            simp only [g]; rw [key (k + 1) le_rfl]
          · rw [Set.indicator_of_notMem hv, Set.indicator_of_notMem (fun h' => hv (hmem.mpr h'))]
        · intro v v' h
          apply Finset.prod_congr rfl
          intro i hi
          have hi' : k + 1 ≤ i := (Finset.mem_Ico.mp hi).1
          simp only [z]
          rw [h (Sum.inl i) (by simpa [blk] using hi'), h (Sum.inr i) (by simpa [blk] using hi')]
      rw [e2]; exact e1
    have htot : ∑ k ∈ Finset.range N, ∫⁻ ω, (A k).indicator (g N) (V ω) ∂P ≤ 1 := by
      rw [← lintegral_finsetSum (f := fun k ω => (A k).indicator (g N) (V ω)) _
        (fun k _ => ((hg N).indicator (hA k)).comp hV)]
      calc ∫⁻ ω, ∑ k ∈ Finset.range N, (A k).indicator (g N) (V ω) ∂P
          ≤ ∫⁻ ω, g N (V ω) ∂P := by
            apply lintegral_mono
            intro ω
            dsimp only
            by_cases hex : ∃ k ∈ Finset.range N, V ω ∈ A k
            · obtain ⟨k, hk, hmem⟩ := hex
              rw [Finset.sum_eq_single k]
              · exact Set.indicator_le_self _ _ _
              · intro b _ hb
                rw [Set.indicator_of_notMem]
                intro hb'
                exact hb (hAdisj _ _ _ hb' hmem)
              · intro h; exact absurd hk h
            · push Not at hex
              rw [Finset.sum_eq_zero (fun k hk => Set.indicator_of_notMem (hex k hk) _)]
              exact zero_le
        _ = 1 := by simp_rw [hgprod]; exact hzprod _
    have hmul : ENNReal.ofReal (exp (R * u)) * ∑ k ∈ Finset.range N, P (V ⁻¹' A k) ≤ 1 := by
      rw [Finset.mul_sum]
      exact (Finset.sum_le_sum hstep).trans htot
    have hone : ENNReal.ofReal (exp (-R * u)) * ENNReal.ofReal (exp (R * u)) = 1 := by
      rw [← ENNReal.ofReal_mul (exp_pos _).le, ← exp_add]; simp
    calc ∑ k ∈ Finset.range N, P (V ⁻¹' A k)
        = ENNReal.ofReal (exp (-R * u)) * (ENNReal.ofReal (exp (R * u))
            * ∑ k ∈ Finset.range N, P (V ⁻¹' A k)) := by
          rw [← mul_assoc, hone, one_mul]
      _ ≤ ENNReal.ofReal (exp (-R * u)) * 1 := by gcongr
      _ = _ := mul_one _
  -- the ruin event lies in the union of the A k
  have hsub : {ω | ∃ t : ℝ, 0 ≤ t ∧ ∃ n : ℕ,
        u + c * t - ∑ i ∈ (Finset.range n).filter
          (fun i => ∑ j ∈ Finset.range (i + 1), W j ω ≤ t), X i ω < 0} ⊆ ⋃ k, V ⁻¹' A k := by
    intro ω ⟨t, ht, n, hn⟩
    set B := (Finset.range n).filter (fun i => ∑ j ∈ Finset.range (i + 1), W j ω ≤ t) with hB
    have hex : ∃ k, u < s (k + 1) (V ω) := by
      rcases B.eq_empty_or_nonempty with hBe | hBne
      · rw [hBe, Finset.sum_empty] at hn; nlinarith [mul_nonneg hc.le ht]
      · set k := B.max' hBne
        have hkB : k ∈ B := B.max'_mem hBne
        have hTk : ∑ j ∈ Finset.range (k + 1), W j ω ≤ t := (Finset.mem_filter.mp hkB).2
        have hsubB : B ⊆ Finset.range (k + 1) := by
          intro i hi; rw [Finset.mem_range]; exact Nat.lt_succ_of_le (B.le_max' i hi)
        have hle : ∑ i ∈ B, X i ω ≤ ∑ i ∈ Finset.range (k + 1), X i ω :=
          Finset.sum_le_sum_of_subset_of_nonneg hsubB (fun i _ _ => hXnonneg i ω)
        refine ⟨k, ?_⟩
        have : s (k + 1) (V ω) = ∑ i ∈ Finset.range (k + 1), X i ω
            - c * ∑ j ∈ Finset.range (k + 1), W j ω := by
          simp only [s, V, hfdef, Sum.elim_inl, Sum.elim_inr]
          rw [Finset.sum_sub_distrib, Finset.mul_sum]
        rw [this]
        nlinarith [mul_le_mul_of_nonneg_left hTk hc.le]
    exact Set.mem_iUnion.mpr ⟨Nat.find hex, Nat.find_spec hex,
      fun j hj => not_lt.mp (Nat.find_min hex hj)⟩
  -- conclude
  have hU : P (⋃ k, V ⁻¹' A k) ≤ ENNReal.ofReal (exp (-R * u)) :=
    (measure_iUnion_le _).trans (ENNReal.tsum_le_of_sum_range_le hfin)
  calc _ ≤ P.real (⋃ k, V ⁻¹' A k) := measureReal_mono hsub (measure_ne_top _ _)
    _ ≤ _ := ENNReal.toReal_le_of_le_ofReal (exp_pos _).le hU

/-- Step 1: how an exponential of the claims grows. In the same claim stream, fix a rate `r`
with `M_X(r) = E[e^(r X)]` finite and a time `t ≥ 0`. Let `S_t` be the total of the claims that
have arrived by time `t`. Then the average of `e^(r (S_t - c t))` is `e^(t κ(r))`, with
`κ(r) = lam (M_X(r) - 1) - c r`. -/
theorem compound_poisson_exponential_growth
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (lam c r t : ℝ) (hlam : 0 < lam) (ht : 0 ≤ t)
    (X W : ℕ → Ω → ℝ) (hXmeas : ∀ i, Measurable (X i)) (hWmeas : ∀ i, Measurable (W i))
    (hXident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hWexp : ∀ i, P.map (W i) = expMeasure lam)
    (hindep : iIndepFun (fun k : ℕ ⊕ ℕ => Sum.elim X W k) P)
    (hr : Integrable (fun ω => exp (r * X 0 ω)) P) :
    ∫ ω, exp (r * ((∑' i, if ∑ j ∈ Finset.range (i + 1), W j ω ≤ t then X i ω else 0) - c * t)) ∂P
      = exp (t * (lam * (mgf (X 0) P r - 1) - c * r)) := by
  classical
  set f : ℕ ⊕ ℕ → Ω → ℝ := fun k => Sum.elim X W k with hfdef
  have hfmeas : ∀ k, Measurable (f k) := by
    intro k
    cases k with
    | inl i => exact hXmeas i
    | inr i => exact hWmeas i
  have hW : iIndepFun W P := by
    have h := hindep.precomp Sum.inr_injective
    exact h
  have hX : iIndepFun X P := by
    have h := hindep.precomp Sum.inl_injective
    exact h
  have hXW : IndepFun (fun ω i => X i ω) (fun ω j => W j ω) P :=
    indepFun_of_depends f hindep hfmeas (Set.range Sum.inl) (Set.range Sum.inr)
      Set.isCompl_range_inl_range_inr.disjoint (fun v i => v (Sum.inl i))
      (fun v j => v (Sum.inr j)) (Measurable.of_eval (fun i => measurable_pi_apply _))
      (Measurable.of_eval (fun i => measurable_pi_apply _))
      (fun v v' h => funext fun i => h _ ⟨i, rfl⟩) (fun v v' h => funext fun j => h _ ⟨j, rfl⟩)
  set M := mgf (X 0) P r with hMdef
  have hM0 : 0 ≤ M := mgf_nonneg
  have hXm : ∀ i, ∫⁻ ω, ENNReal.ofReal (exp (r * X i ω)) ∂P = ENNReal.ofReal M := by
    intro i
    have := ((hXident i).comp (u := fun x => ENNReal.ofReal (exp (r * x)))
      (by fun_prop)).lintegral_eq
    simp only [Function.comp_def] at this
    rw [this, hMdef, mgf, ofReal_integral_eq_lintegral_ofReal hr
      (Filter.Eventually.of_forall (fun ω => (exp_pos _).le))]
  -- waits are nonnegative almost surely
  have hWnn : ∀ i, ∀ᵐ ω ∂P, 0 ≤ W i ω := by
    intro i
    have hneg : P (W i ⁻¹' Set.Iio 0) = 0 := by
      rw [← Measure.map_apply (hWmeas i) measurableSet_Iio, hWexp i, expMeasure, gammaMeasure,
        withDensity_apply _ measurableSet_Iio]
      exact lintegral_exponentialPDF_of_nonpos le_rfl
    rw [ae_iff]
    have hset : {a | ¬ 0 ≤ W i a} = W i ⁻¹' Set.Iio 0 := by ext; simp
    rw [hset]; exact hneg
  have hcdf := erlang_cdf P lam hlam W hWmeas hWexp hW
  -- the event "exactly m claims by time t"
  let Ew : ℕ → Set (ℕ → ℝ) := fun m =>
    {w | ∑ j ∈ Finset.range m, w j ≤ t} \ {w | ∑ j ∈ Finset.range (m + 1), w j ≤ t}
  have hEw : ∀ m, MeasurableSet (Ew m) := by
    intro m
    exact (measurableSet_le (Finset.measurable_fun_sum _ (fun j _ => measurable_pi_apply j))
      measurable_const).diff (measurableSet_le (Finset.measurable_fun_sum _
        (fun j _ => measurable_pi_apply j)) measurable_const)
  let Wv : Ω → (ℕ → ℝ) := fun ω j => W j ω
  let Xv : Ω → (ℕ → ℝ) := fun ω i => X i ω
  have hWv : Measurable Wv := Measurable.of_eval hWmeas
  have hXv : Measurable Xv := Measurable.of_eval hXmeas
  have hPE : ∀ m, P (Wv ⁻¹' Ew m)
      = ENNReal.ofReal (exp (-(lam * t)) * (lam * t) ^ m / (Nat.factorial m : ℝ)) := by
    intro m
    set A := {ω | ∑ j ∈ Finset.range m, W j ω ≤ t} with hA
    set B := {ω | ∑ j ∈ Finset.range (m + 1), W j ω ≤ t} with hB
    have hAm : MeasurableSet A := measurableSet_le (Finset.measurable_fun_sum _
      (fun j _ => hWmeas j)) measurable_const
    have hBm : MeasurableSet B := measurableSet_le (Finset.measurable_fun_sum _
      (fun j _ => hWmeas j)) measurable_const
    have h1 : Wv ⁻¹' Ew m = A \ (A ∩ B) := by
      ext ω; simp [Wv, Ew, A, B]
    have h2 : (A ∩ B : Set Ω) =ᵐ[P] B := by
      filter_upwards [hWnn m] with ω hω
      apply propext
      constructor
      · exact fun h => h.2
      · intro h
        refine ⟨?_, h⟩
        simp only [B, Set.mem_setOf_eq, Finset.sum_range_succ] at h
        show ∑ j ∈ Finset.range m, W j ω ≤ t
        linarith
    rw [h1, measure_diff Set.inter_subset_left (hAm.inter hBm).nullMeasurableSet
      (measure_ne_top _ _), measure_congr h2, hA, hB, hcdf, hcdf,
      ← ENNReal.ofReal_sub _ (erlH_nonneg hlam.le _ _)]
    congr 1
    simp only [erlH, if_pos ht, Finset.sum_range_succ]
    ring
  -- almost surely only finitely many claims arrive by time t
  have hfin : ∀ᵐ ω ∂P, ∃ m, t < ∑ j ∈ Finset.range m, W j ω := by
    rw [ae_iff]
    have htend : Filter.Tendsto (fun m => ENNReal.ofReal (erlH lam m t)) Filter.atTop
        (nhds 0) := by
      rw [← ENNReal.ofReal_zero]
      apply ENNReal.tendsto_ofReal
      have hs := (NormedSpace.expSeries_div_hasSum_exp (lam * t)).tendsto_sum_nat
      rw [← Real.exp_eq_exp_ℝ] at hs
      have : Filter.Tendsto (fun m => 1 - exp (-(lam * t)) *
          ∑ j ∈ Finset.range m, (lam * t) ^ j / (Nat.factorial j : ℝ)) Filter.atTop
          (nhds (1 - exp (-(lam * t)) * exp (lam * t))) :=
        tendsto_const_nhds.sub (tendsto_const_nhds.mul hs)
      rw [← exp_add, neg_add_cancel, exp_zero, sub_self] at this
      simpa [erlH, ht] using this
    apply le_antisymm _ (zero_le)
    apply ge_of_tendsto' htend
    intro m
    rw [← hcdf m t]
    apply measure_mono
    intro ω hω
    simp only [Set.mem_setOf_eq, not_exists, not_lt] at hω
    exact hω m
  -- the integrand as a sum over the number of claims
  let C : ℝ := exp (-(r * (c * t)))
  let Gx : ℕ → (ℕ → ℝ) → ENNReal := fun m x =>
    ENNReal.ofReal C * ∏ i ∈ Finset.range m, ENNReal.ofReal (exp (r * x i))
  have hGx : ∀ m, Measurable (Gx m) := by
    intro m
    exact measurable_const.mul (Finset.measurable_fun_prod _ (fun i _ =>
      (measurable_exp.comp (measurable_const.mul (measurable_pi_apply i))).ennreal_ofReal))
  let term : ℕ → Ω → ENNReal := fun m ω => (Ew m).indicator 1 (Wv ω) * Gx m (Xv ω)
  have hterm : ∀ m, Measurable (term m) := fun m =>
    ((measurable_one.indicator (hEw m)).comp hWv).mul ((hGx m).comp hXv)
  have hpt : ∀ᵐ ω ∂P, ENNReal.ofReal (exp (r * ((∑' i, if ∑ j ∈ Finset.range (i + 1), W j ω ≤ t
      then X i ω else 0) - c * t))) = ∑' m, term m ω := by
    filter_upwards [ae_all_iff.mpr hWnn, hfin] with ω hnn hex
    have mono : ∀ a b, a ≤ b → ∑ j ∈ Finset.range a, W j ω ≤ ∑ j ∈ Finset.range b, W j ω :=
      fun a b hab => Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_subset_range.mpr hab)
        (fun i _ _ => hnn i)
    have hm0 : t < ∑ j ∈ Finset.range (Nat.find hex), W j ω := Nat.find_spec hex
    have hm0pos : Nat.find hex ≠ 0 := by
      intro h; rw [h] at hm0; simp at hm0; linarith
    obtain ⟨m, hm⟩ := Nat.exists_eq_succ_of_ne_zero hm0pos
    have hle : ∑ j ∈ Finset.range m, W j ω ≤ t :=
      not_lt.mp (Nat.find_min hex (by omega : m < Nat.find hex))
    have hgt : t < ∑ j ∈ Finset.range (m + 1), W j ω := by rw [hm] at hm0; exact hm0
    have hmem : Wv ω ∈ Ew m := ⟨hle, not_le.mpr hgt⟩
    have hnot : ∀ m' ≠ m, Wv ω ∉ Ew m' := by
      intro m' hne hm'
      rcases Nat.lt_or_gt_of_ne hne with h | h
      · exact hm'.2 ((mono _ _ h).trans hle)
      · exact absurd (hgt.trans_le (mono _ _ h)) (not_lt.mpr hm'.1)
    have hsumX : (∑' i, if ∑ j ∈ Finset.range (i + 1), W j ω ≤ t then X i ω else 0)
        = ∑ i ∈ Finset.range m, X i ω := by
      rw [tsum_eq_sum (s := Finset.range m)]
      · apply Finset.sum_congr rfl
        intro i hi
        rw [if_pos ((mono _ _ (Finset.mem_range.mp hi)).trans hle)]
      · intro i hi
        rw [Finset.mem_range, not_lt] at hi
        rw [if_neg (not_le.mpr (hgt.trans_le (mono _ _ (by omega))))]
    rw [hsumX]
    rw [tsum_eq_single m (fun m' hne => by simp [term, Set.indicator_of_notMem (hnot m' hne)])]
    simp only [term, Set.indicator_of_mem hmem, Pi.one_apply, one_mul, Gx, Xv]
    rw [← ENNReal.ofReal_prod_of_nonneg (fun i _ => (exp_pos _).le),
      ← ENNReal.ofReal_mul (exp_pos _).le, ← exp_sum, ← exp_add]
    congr 2
    rw [← Finset.mul_sum]
    ring
  have hint_term : ∀ m, ∫⁻ ω, term m ω ∂P = ENNReal.ofReal
      (C * (exp (-(lam * t)) * (lam * t * M) ^ m / (Nat.factorial m : ℝ))) := by
    intro m
    have hind : IndepFun (fun ω => (Ew m).indicator (1 : (ℕ → ℝ) → ENNReal) (Wv ω))
        (fun ω => Gx m (Xv ω)) P :=
      hXW.symm.comp (measurable_one.indicator (hEw m)) (hGx m)
    have key := lintegral_mul_eq_lintegral_mul_lintegral_of_indepFun''
      (f := fun ω => (Ew m).indicator (1 : (ℕ → ℝ) → ENNReal) (Wv ω))
      (g := fun ω => Gx m (Xv ω))
      ((measurable_one.indicator (hEw m)).comp hWv).aemeasurable
      ((hGx m).comp hXv).aemeasurable hind
    simp only [term]
    rw [key]
    have e1 : ∫⁻ ω, (Ew m).indicator (1 : (ℕ → ℝ) → ENNReal) (Wv ω) ∂P = P (Wv ⁻¹' Ew m) := by
      rw [← lintegral_map (measurable_one.indicator (hEw m)) hWv, lintegral_indicator_one (hEw m),
        Measure.map_apply hWv (hEw m)]
    have e2 : ∫⁻ ω, Gx m (Xv ω) ∂P = ENNReal.ofReal C * ENNReal.ofReal M ^ m := by
      simp only [Gx, Xv]
      rw [lintegral_const_mul _ (Finset.measurable_fun_prod _ (fun i _ =>
        ((hXmeas i).const_mul r).exp.ennreal_ofReal))]
      rw [lintegral_prod_eq_prod_lintegral_of_indepFun (Finset.range m)
        (fun i ω => ENNReal.ofReal (exp (r * X i ω)))
        (hX.comp (fun _ x => ENNReal.ofReal (exp (r * x))) (fun _ => by fun_prop))
        (fun i => ((hXmeas i).const_mul r).exp.ennreal_ofReal)]
      simp only [hXm, Finset.prod_const, Finset.card_range]
    rw [e1, e2, hPE m, ← ENNReal.ofReal_pow hM0, ← ENNReal.ofReal_mul (exp_pos _).le,
      ← ENNReal.ofReal_mul (by positivity)]
    congr 1
    rw [mul_pow]
    ring
  have hsum : HasSum (fun m => C * (exp (-(lam * t)) * (lam * t * M) ^ m / (Nat.factorial m : ℝ)))
      (C * (exp (-(lam * t)) * exp (lam * t * M))) := by
    have hs := NormedSpace.expSeries_div_hasSum_exp (lam * t * M)
    rw [← Real.exp_eq_exp_ℝ] at hs
    have := (hs.mul_left (exp (-(lam * t)))).mul_left C
    simpa only [mul_div_assoc] using this
  have hL : ∫⁻ ω, ∑' m, term m ω ∂P = ENNReal.ofReal (C * (exp (-(lam * t)) * exp (lam * t * M))) := by
    rw [lintegral_tsum (fun m => (hterm m).aemeasurable)]
    simp_rw [hint_term]
    rw [← ENNReal.ofReal_tsum_of_nonneg (fun m => by positivity) hsum.summable, hsum.tsum_eq]
  have hae : ∀ᵐ ω ∂P, exp (r * ((∑' i, if ∑ j ∈ Finset.range (i + 1), W j ω ≤ t
      then X i ω else 0) - c * t)) = (∑' m, term m ω).toReal :=
    hpt.mono (fun ω h => by rw [← h, ENNReal.toReal_ofReal (exp_pos _).le])
  rw [integral_congr_ae hae, integral_toReal (Measurable.ennreal_tsum hterm).aemeasurable
    (ae_lt_top (Measurable.ennreal_tsum hterm) (by rw [hL]; exact ENNReal.ofReal_ne_top)), hL,
    ENNReal.toReal_ofReal (by positivity)]
  simp only [C, ← exp_add]
  congr 1
  ring

/-- Step 3: the adjustment coefficient for exponential claims. If a claim `X` is exponential
with mean `mu > 0`, there are `lam > 0` claims a year, and the premium is
`c = (1 + theta) lam mu` with a positive loading `theta`, then the adjustment equation
`lam (M_X(R) - 1) = c R` has exactly one positive root: `R = theta / ((1 + theta) mu)`. -/
theorem adjustment_coefficient_exponential_claims
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (lam mu theta : ℝ) (hlam : 0 < lam) (hmu : 0 < mu) (htheta : 0 < theta)
    (X : Ω → ℝ) (hXmeas : Measurable X) (hXexp : P.map X = expMeasure (1 / mu))
    (R : ℝ) (hR : 0 < R) :
    lam * (mgf X P R - 1) = (1 + theta) * lam * mu * R ↔ R = theta / ((1 + theta) * mu) := by
  have hmap : mgf X P R = ∫ x, exp (R * x) ∂(P.map X) := by
    rw [integral_map hXmeas.aemeasurable (by fun_prop)]; rfl
  rw [hXexp, integral_eq_lintegral_of_nonneg_ae (Filter.Eventually.of_forall
    (fun x => (exp_pos _).le)) (by fun_prop)] at hmap
  have ha : 0 < 1 / mu := by positivity
  rcases lt_or_ge R (1 / mu) with hlt | hge
  · rw [lintegral_ofReal_exp_expMeasure_lt ha hlt, ENNReal.toReal_ofReal
      (div_nonneg ha.le (by linarith))] at hmap
    have hmR : mu * R < 1 := by rwa [lt_div_iff₀ hmu, mul_comm] at hlt
    have hM : mgf X P R = 1 / (1 - mu * R) := by
      rw [hmap]; field_simp
    rw [hM]
    have h1 : 0 < 1 - mu * R := by linarith
    constructor
    · intro h
      have h2 : mu * R / (1 - mu * R) = (1 + theta) * mu * R := by
        have : lam * (mu * R / (1 - mu * R)) = lam * ((1 + theta) * mu * R) := by
          calc lam * (mu * R / (1 - mu * R)) = lam * (1 / (1 - mu * R) - 1) := by
                field_simp; ring
            _ = _ := h
            _ = _ := by ring
        exact mul_left_cancel₀ hlam.ne' this
      rw [div_eq_iff h1.ne'] at h2
      have h3 : 1 = (1 + theta) * (1 - mu * R) := by
        have hmR0 : 0 < mu * R := by positivity
        nlinarith
      rw [eq_div_iff (by positivity)]
      nlinarith
    · intro h
      rw [h]
      field_simp
      ring
  · rw [lintegral_ofReal_exp_expMeasure_ge ha hge, ENNReal.toReal_top] at hmap
    rw [hmap]
    constructor
    · intro h
      have : 0 < (1 + theta) * lam * mu * R := by positivity
      nlinarith
    · intro h
      exfalso
      have : theta / ((1 + theta) * mu) < 1 / mu := by
        rw [div_lt_div_iff₀ (by positivity) hmu]; nlinarith
      linarith

-- The insurer: 10 claims a year, mean claim $10,000, 10% loading, surplus $1,000,000.
-- Expected claims a year: 10 × 10,000 = 100,000.
example : (10 : ℕ) * 10000 = 100000 := by norm_num
-- Premium: 1.1 × 100,000 = 110,000.
example : (11 / 10 : ℚ) * 100000 = 110000 := by norm_num
-- R = 1/110,000 solves 10 × (1/(1 - 10,000 R) - 1) = 110,000 R (both sides equal 1).
example : (10 : ℚ) * (1 / (1 - 10000 * (1 / 110000)) - 1) = 110000 * (1 / 110000) := by norm_num
example : (110000 : ℚ) * (1 / 110000) = 1 := by norm_num
-- The closed form theta / ((1 + theta) mu) gives the same R: (1/10) / ((11/10) × 10,000).
example : (1 / 10 : ℚ) / ((1 + 1 / 10) * 10000) = 1 / 110000 := by norm_num
-- Check M_X(R) = 1/(1 - 1/11) = 1.1.
example : (1 : ℚ) / (1 - 1 / 11) = 11 / 10 := by norm_num
-- Exponent R u = 1,000,000 / 110,000 = 100/11, about 9.0909 (also R per $1M).
example : (1000000 : ℚ) * (1 / 110000) = 100 / 11 := by norm_num
-- Claims ten times bigger ($100,000 mean): R per $1M = 1,000,000 / 1,100,000 = 10/11.
example : (1 / 10 : ℚ) / ((1 + 1 / 10) * 100000) * 1000000 = 10 / 11 := by norm_num
-- Mean-variance shortcut 2(c - lam mu)/(lam E[X^2]) with E[X^2] = 2 × 10,000^2: 10 per $1M.
example : (2 : ℚ) * (110000 - 100000) / (10 * (2 * 10000 ^ 2)) * 1000000 = 10 := by norm_num
-- 20 claims a year with premium doubled to 220,000: R is still 1/110,000.
example : (20 : ℚ) * (1 / (1 - 10000 * (1 / 110000)) - 1) = 220000 * (1 / 110000) := by norm_num

#print axioms lundberg_inequality
#print axioms compound_poisson_exponential_growth
#print axioms adjustment_coefficient_exponential_claims
#print axioms lintegral_ofReal_exp_expMeasure_lt
#print axioms lintegral_ofReal_exp_expMeasure_ge
#print axioms indepFun_of_depends
#print axioms lintegral_mul_of_depends
#print axioms blk_disjoint
#print axioms erlH_nonneg
#print axioms erlH_conv
#print axioms erlang_cdf
