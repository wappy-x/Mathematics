-- Splitting and merging: labelling a Poisson count's arrivals by independent coins gives two independent Poisson counts whose means share out the original mean, and adding two independent Poisson counts gives a Poisson count whose arrivals carry binomial source labels, with the race of exponential waits behind it.
import Mathlib.Probability.Distributions.Poisson.Basic
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Probability.Distributions.Bernoulli
import Mathlib.Probability.Independence.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory unitInterval
open scoped NNReal

theorem coin_count_measure {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (p : I) (L : ℕ → Ω → Bool)
    (hL : ∀ i, HasLaw (L i) (bernoulliMeasure true false p) P)
    (hLindep : iIndepFun L P) (n a : ℕ) :
    P {ω | ((Finset.range n).filter (fun i => L i ω = true)).card = a} =
      (n.choose a : ENNReal) * ((toNNReal p : ENNReal)) ^ a * ((toNNReal (σ p) : ENNReal)) ^ (n - a) := by
  classical
  let E : Finset ℕ → Set Ω := fun s => ⋂ i ∈ Finset.range n, L i ⁻¹' {decide (i ∈ s)}
  have hEchar : ∀ s, s ⊆ Finset.range n → ∀ ω ∈ E s,
      (Finset.range n).filter (fun i => L i ω = true) = s := by
    intro s hs ω hω
    have h' : ∀ i ∈ Finset.range n, L i ω = decide (i ∈ s) := by
      simpa [E] using hω
    ext i
    simp only [Finset.mem_filter]
    constructor
    · rintro ⟨hi, hLi⟩
      have := h' i hi
      rw [hLi] at this
      exact of_decide_eq_true this.symm
    · intro his
      exact ⟨hs his, by rw [h' i (hs his)]; exact decide_eq_true his⟩
  have hset : {ω | ((Finset.range n).filter (fun i => L i ω = true)).card = a} =
      ⋃ s ∈ (Finset.range n).powersetCard a, E s := by
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_powersetCard, exists_prop]
    constructor
    · intro h
      refine ⟨_, ⟨Finset.filter_subset _ _, h⟩, ?_⟩
      simp only [E, Set.mem_iInter, Set.mem_preimage, Set.mem_singleton_iff]
      intro i hi
      by_cases hLi : L i ω = true <;> simp [hLi, hi]
    · rintro ⟨s, ⟨hs, hcard⟩, hE⟩
      rw [hEchar s hs ω hE, hcard]
  have hdisj : Set.Pairwise (↑((Finset.range n).powersetCard a)) (Function.onFun (AEDisjoint P) E) := by
    intro s hs s' hs' hne
    apply Disjoint.aedisjoint
    rw [Set.disjoint_left]
    intro ω h1 h2
    rw [Finset.mem_coe, Finset.mem_powersetCard] at hs hs'
    exact hne ((hEchar s hs.1 ω h1).symm.trans (hEchar s' hs'.1 ω h2))
  have hnull : ∀ s ∈ (Finset.range n).powersetCard a, NullMeasurableSet (E s) P := by
    intro s _
    exact Finset.nullMeasurableSet_biInter _
      (fun i _ => (hL i).aemeasurable.nullMeasurable (measurableSet_singleton _))
  have hval : ∀ i b, P (L i ⁻¹' {b}) = bernoulliMeasure true false p {b} := fun i b =>
    (hL i).measure_eq (p := fun x => x = b) (measurableSet_singleton b)
  have hEs : ∀ s ∈ (Finset.range n).powersetCard a,
      P (E s) = ((toNNReal p : ENNReal)) ^ a * ((toNNReal (σ p) : ENNReal)) ^ (n - a) := by
    intro s hs
    rw [Finset.mem_powersetCard] at hs
    have h1 : P (E s) = ∏ i ∈ Finset.range n, P (L i ⁻¹' {decide (i ∈ s)}) :=
      hLindep.measure_inter_preimage_eq_mul (Finset.range n)
        (sets := fun i => {decide (i ∈ s)}) (fun i _ => measurableSet_singleton _)
    rw [h1]
    have h2 : ∀ i ∈ Finset.range n, P (L i ⁻¹' {decide (i ∈ s)}) =
        if i ∈ s then ((toNNReal p : ENNReal)) else ((toNNReal (σ p) : ENNReal)) := by
      intro i _
      rw [hval]
      by_cases his : i ∈ s
      · simp [his]
      · simp [his]
    rw [Finset.prod_congr rfl h2, Finset.prod_ite, Finset.prod_const, Finset.prod_const]
    have hf1 : (Finset.range n).filter (fun i => i ∈ s) = s := by
      ext i; simp only [Finset.mem_filter]; exact ⟨fun h => h.2, fun h => ⟨hs.1 h, h⟩⟩
    have hf2 := Finset.card_filter_add_card_filter_not (s := Finset.range n) (fun i => i ∈ s)
    rw [hf1, hs.2, Finset.card_range] at hf2
    rw [hf1, hs.2, show ((Finset.range n).filter fun i => i ∉ s).card = n - a by omega]
  rw [hset, measure_biUnion_finset₀ hdisj hnull, Finset.sum_congr rfl hEs, Finset.sum_const,
    Finset.card_powersetCard, Finset.card_range, nsmul_eq_mul, mul_assoc]

#print axioms coin_count_measure

theorem thin_algebra (lam p q : ℝ) (hpq : p + q = 1) (a b : ℕ) :
    Real.exp (-lam) * lam ^ (a + b) / ((a + b).factorial : ℝ) *
        (((a + b).choose a : ℝ) * p ^ a * q ^ b) =
      Real.exp (-(p * lam)) * (p * lam) ^ a / (a.factorial : ℝ) *
        (Real.exp (-(q * lam)) * (q * lam) ^ b / (b.factorial : ℝ)) := by
  rw [Nat.cast_choose ℝ (Nat.le_add_right a b), Nat.add_sub_cancel_left]
  have he : Real.exp (-lam) = Real.exp (-(p * lam)) * Real.exp (-(q * lam)) := by
    rw [← Real.exp_add]; congr 1; linear_combination lam * hpq
  rw [he]
  field_simp
  ring

#print axioms thin_algebra

theorem merge_algebra (A B : ℝ) (hA : 0 ≤ A) (hB : 0 ≤ B) (n a : ℕ) (han : a ≤ n) :
    Real.exp (-A) * A ^ a / (a.factorial : ℝ) * (Real.exp (-B) * B ^ (n - a) / ((n - a).factorial : ℝ)) =
      Real.exp (-(A + B)) * (A + B) ^ n / (n.factorial : ℝ) * (n.choose a : ℝ) *
        (A / (A + B)) ^ a * (1 - A / (A + B)) ^ (n - a) := by
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le han
  rw [Nat.add_sub_cancel_left]
  rcases (add_nonneg hA hB).eq_or_lt with h0 | hpos
  · have hA0 : A = 0 := by linarith
    have hB0 : B = 0 := by linarith
    subst hA0 hB0
    rcases Nat.eq_zero_or_pos a with ha | ha <;> rcases Nat.eq_zero_or_pos k with hk | hk
    · subst ha hk; simp
    · subst ha; simp [zero_pow hk.ne']
    · subst hk; simp [zero_pow ha.ne']
    · simp [zero_pow ha.ne', zero_pow hk.ne']
  · have h1 : 1 - A / (A + B) = B / (A + B) := by field_simp; ring
    rw [h1, Nat.cast_choose ℝ (Nat.le_add_right a k), Nat.add_sub_cancel_left, div_pow, div_pow,
      neg_add, Real.exp_add]
    have : (0:ℝ) < (A+B)^(a+k) := by positivity
    field_simp
    ring

#print axioms merge_algebra

theorem expMeasure_real_tail {r : ℝ} (hr : 0 < r) (x : ℝ) :
    (expMeasure r).real {y | x < y} = if 0 ≤ x then Real.exp (-(r * x)) else 1 := by
  have := isProbabilityMeasure_expMeasure hr
  have h : {y : ℝ | x < y} = (Set.Iic x)ᶜ := by ext y; simp
  rw [h, probReal_compl_eq_one_sub measurableSet_Iic, ← ProbabilityTheory.cdf_eq_real, cdf_expMeasure_eq hr]
  split_ifs <;> ring

#print axioms expMeasure_real_tail

theorem exponentialPDF_mul_tail {l₁ l₂ : ℝ} (hl₁ : 0 < l₁) (hl₂ : 0 < l₂) (s : ℝ) :
    exponentialPDF l₁ s * ENNReal.ofReal (if 0 ≤ s then Real.exp (-(l₂ * s)) else 1) =
      ENNReal.ofReal (l₁ / (l₁ + l₂)) * exponentialPDF (l₁ + l₂) s := by
  rcases lt_or_ge s 0 with hs | hs
  · simp [exponentialPDF_of_neg hs]
  · rw [exponentialPDF_of_nonneg hs, exponentialPDF_of_nonneg hs, ite_eq_left_iff.mpr (fun h => absurd hs h),
      ← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul (by positivity)]
    congr 1
    have hsum : 0 < l₁ + l₂ := add_pos hl₁ hl₂
    rw [mul_assoc, ← Real.exp_add]
    field_simp
    ring_nf

#print axioms exponentialPDF_mul_tail

/-- Splitting, in one window. The switchboard's count `N` in a window of length `t` is Poisson
with mean `lam * t`. The coins `L 0, L 1, ...` are independent, each `true` (sales) with chance
`p` (a number in `[0, 1]`; `σ p` is `1 - p`), and the whole coin sequence is independent of the
count. Send the `i`-th call to sales when `L i` is `true`. Then the sales count and the support
count are independent, the sales count is Poisson with mean `p * lam * t`, and the support count
is Poisson with mean `(1 - p) * lam * t`. -/
theorem poisson_split_independent_poisson_counts
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (lam t : ℝ≥0) (p : I)
    (N : Ω → ℕ) (L : ℕ → Ω → Bool)
    (hN : HasLaw N (poissonMeasure (lam * t)) P)
    (hL : ∀ i, HasLaw (L i) (bernoulliMeasure true false p) P)
    (hLindep : iIndepFun L P)
    (hNL : IndepFun N (fun ω i => L i ω) P) :
    let sales : Ω → ℕ := fun ω => ((Finset.range (N ω)).filter (fun i => L i ω = true)).card
    let support : Ω → ℕ := fun ω => ((Finset.range (N ω)).filter (fun i => L i ω = false)).card
    IndepFun sales support P ∧
      HasLaw sales (poissonMeasure (toNNReal p * (lam * t))) P ∧
      HasLaw support (poissonMeasure (toNNReal (σ p) * (lam * t))) P := by
  intro sales support
  classical
  let V : Ω → (ℕ → Bool) := fun ω i => L i ω
  let cnt : ℕ → (ℕ → Bool) → ℕ := fun n f => ((Finset.range n).filter (fun i => f i = true)).card
  let cntF : ℕ → (ℕ → Bool) → ℕ :=
    fun n f => ((Finset.range n).filter (fun i => f i = false)).card
  have hcnt : ∀ n, Measurable (cnt n) := by
    intro n
    have : cnt n = fun f => ∑ i ∈ Finset.range n, (if f i = true then 1 else 0) := by
      funext f; simp only [cnt, Finset.card_filter]
    rw [this]
    exact Finset.measurable_sum _ (fun i _ =>
      (measurable_of_countable (fun b : Bool => if b = true then 1 else 0)).comp
        (measurable_pi_apply i))
  have hcntF : ∀ n, Measurable (cntF n) := by
    intro n
    have : cntF n = fun f => ∑ i ∈ Finset.range n, (if f i = false then 1 else 0) := by
      funext f; simp only [cntF, Finset.card_filter]
    rw [this]
    exact Finset.measurable_sum _ (fun i _ =>
      (measurable_of_countable (fun b : Bool => if b = false then 1 else 0)).comp
        (measurable_pi_apply i))
  let G : ℕ × (ℕ → Bool) → ℕ × ℕ := fun q => (cnt q.1 q.2, cntF q.1 q.2)
  have hG : Measurable G :=
    measurable_from_prod_countable_right (fun n => (hcnt n).prodMk (hcntF n))
  let F : Ω → ℕ × ℕ := fun ω => (sales ω, support ω)
  have hFG : F = G ∘ (fun ω => (N ω, V ω)) := rfl
  have hVm : AEMeasurable V P := AEMeasurable.of_eval (fun i => (hL i).aemeasurable)
  have hFm : AEMeasurable F P := by
    rw [hFG]; exact hG.comp_aemeasurable (hN.aemeasurable.prodMk hVm)
  have hsum : ∀ ω, sales ω + support ω = N ω := by
    intro ω
    have := Finset.card_filter_add_card_filter_not (s := Finset.range (N ω))
      (fun i => L i ω = true)
    simpa [Bool.not_eq_true] using this
  set μ₁ := poissonMeasure (toNNReal p * (lam * t)) with hμ₁
  set μ₂ := poissonMeasure (toNNReal (σ p) * (lam * t)) with hμ₂
  have hF : HasLaw F (μ₁.prod μ₂) P := by
    refine ⟨hFm, ?_⟩
    apply Measure.ext_of_singleton
    rintro ⟨a, b⟩
    rw [Measure.map_apply_of_aemeasurable hFm (measurableSet_singleton _)]
    have hpre : F ⁻¹' {(a, b)} = N ⁻¹' {a + b} ∩ V ⁻¹' {f | cnt (a + b) f = a} := by
      ext ω
      simp only [Set.mem_preimage, Set.mem_singleton_iff, Set.mem_inter_iff, Set.mem_ofPred_eq,
        Prod.ext_iff, F]
      have h := hsum ω
      constructor
      · rintro ⟨ha, hb⟩
        have hN' : N ω = a + b := by omega
        refine ⟨hN', ?_⟩
        show ((Finset.range (a + b)).filter (fun i => L i ω = true)).card = a
        rw [← hN']; exact ha
      · rintro ⟨hN', hc⟩
        have ha : sales ω = a := by
          show ((Finset.range (N ω)).filter (fun i => L i ω = true)).card = a
          rw [hN']; exact hc
        exact ⟨ha, by omega⟩
    have hind : P (N ⁻¹' {a + b} ∩ V ⁻¹' {f | cnt (a + b) f = a}) =
        P (N ⁻¹' {a + b}) * P (V ⁻¹' {f | cnt (a + b) f = a}) :=
      hNL.measure_inter_preimage_eq_mul _ _ (measurableSet_singleton _)
        (hcnt (a + b) (measurableSet_singleton a))
    rw [hpre, ← Set.singleton_prod_singleton, Measure.prod_prod, hind]
    have hNa : P (N ⁻¹' {a + b}) = poissonMeasure (lam * t) {a + b} :=
      hN.measure_eq (p := fun x => x = a + b) (measurableSet_singleton _)
    have hVa : P (V ⁻¹' {f | cnt (a + b) f = a}) =
        ((a + b).choose a : ENNReal) * ((toNNReal p : ENNReal)) ^ a *
          ((toNNReal (σ p) : ENNReal)) ^ (a + b - a) :=
      coin_count_measure p L hL hLindep (a + b) a
    rw [hNa, hVa, Nat.add_sub_cancel_left, hμ₁, hμ₂, poissonMeasure_singleton,
      poissonMeasure_singleton, poissonMeasure_singleton]
    have hc : ((a + b).choose a : ENNReal) * ((toNNReal p : ENNReal)) ^ a *
        ((toNNReal (σ p) : ENNReal)) ^ b =
        ENNReal.ofReal (((a + b).choose a : ℝ) * ((toNNReal p : ℝ)) ^ a *
          ((toNNReal (σ p) : ℝ)) ^ b) := by
      rw [ENNReal.ofReal_mul (by positivity), ENNReal.ofReal_mul (by positivity),
        ENNReal.ofReal_pow (by positivity), ENNReal.ofReal_pow (by positivity),
        ENNReal.ofReal_natCast, ENNReal.ofReal_coe_nnreal, ENNReal.ofReal_coe_nnreal]
    rw [hc, ← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul (by positivity)]
    congr 1
    have hpq : (toNNReal p : ℝ) + (toNNReal (σ p) : ℝ) = 1 := by
      rw [← NNReal.coe_add, toNNReal_add_toNNReal_symm, NNReal.coe_one]
    simp only [NNReal.coe_mul]
    exact thin_algebra _ _ _ hpq a b
  have h1 : HasLaw sales μ₁ P := by
    have hfst : HasLaw Prod.fst μ₁ (μ₁.prod μ₂) :=
      ⟨measurable_fst.aemeasurable, by simp [hμ₂]⟩
    exact hfst.comp hF
  have h2 : HasLaw support μ₂ P := by
    have hsnd : HasLaw Prod.snd μ₂ (μ₁.prod μ₂) :=
      ⟨measurable_snd.aemeasurable, by simp [hμ₁]⟩
    exact hsnd.comp hF
  exact ⟨(indepFun_iff_hasLaw_prodMk_prod h1 h2).2 hF, h1, h2⟩

/-- Merging, in one window. If the two lines' counts `X` and `Y` are independent and Poisson
with means `r₁` and `r₂`, the merged count `X + Y` is Poisson with mean `r₁ + r₂`, and, given
that the merged line took `n` calls, the number from the first line is binomial: each of the `n`
calls came from the first line with chance `r₁ / (r₁ + r₂)`, independently. -/
theorem poisson_merge_sum_and_source_labels
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (r₁ r₂ : ℝ≥0) (X Y : Ω → ℕ)
    (hXY : IndepFun X Y P)
    (hX : HasLaw X (poissonMeasure r₁) P) (hY : HasLaw Y (poissonMeasure r₂) P) :
    HasLaw (X + Y) (poissonMeasure (r₁ + r₂)) P ∧
      ∀ n a : ℕ, a ≤ n →
        P.real {ω | X ω = a ∧ X ω + Y ω = n} =
          P.real {ω | X ω + Y ω = n} * (n.choose a : ℝ) *
            ((r₁ : ℝ) / (r₁ + r₂)) ^ a * (1 - (r₁ : ℝ) / (r₁ + r₂)) ^ (n - a) := by
  have hsum := hXY.hasLaw_add_poissonMeasure hX hY
  refine ⟨hsum, ?_⟩
  intro n a han
  have h1 : {ω | X ω = a ∧ X ω + Y ω = n} = X ⁻¹' {a} ∩ Y ⁻¹' {n - a} := by
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_inter_iff, Set.mem_preimage, Set.mem_singleton_iff]
    omega
  have h2 : P.real {ω | X ω = a ∧ X ω + Y ω = n} =
      P.real (X ⁻¹' {a}) * P.real (Y ⁻¹' {n - a}) := by
    rw [h1, measureReal_def, hXY.measure_inter_preimage_eq_mul _ _ (measurableSet_singleton _)
      (measurableSet_singleton _), ENNReal.toReal_mul]
    rfl
  have hXa : P.real (X ⁻¹' {a}) = Real.exp (-(r₁ : ℝ)) * (r₁ : ℝ) ^ a / (a.factorial : ℝ) := by
    rw [← poissonMeasure_real_singleton]
    exact hX.measureReal_eq (p := fun x => x = a) (measurableSet_singleton a)
  have hYb : P.real (Y ⁻¹' {n - a}) =
      Real.exp (-(r₂ : ℝ)) * (r₂ : ℝ) ^ (n - a) / ((n - a).factorial : ℝ) := by
    rw [← poissonMeasure_real_singleton]
    exact hY.measureReal_eq (p := fun x => x = n - a) (measurableSet_singleton _)
  have hS : P.real {ω | X ω + Y ω = n} =
      Real.exp (-((r₁ : ℝ) + r₂)) * ((r₁ : ℝ) + r₂) ^ n / (n.factorial : ℝ) := by
    have := hsum.measureReal_eq (p := fun x => x = n) (measurableSet_singleton n)
    have h' : Po(r₁ + r₂).real {x | x = n} = Po(r₁ + r₂).real {n} := rfl
    rw [h', poissonMeasure_real_singleton] at this
    simpa using this
  rw [h2, hXa, hYb, hS]
  exact merge_algebra _ _ r₁.2 r₂.2 n a han

/-- Merging, seen through the waits. If the wait `S` for the next sales call and the wait `U`
for the next support call are independent exponentials with rates `l₁ > 0` and `l₂ > 0`, the
merged line's wait `min S U` is exponential with rate `l₁ + l₂`, and sales rings first with
chance `l₁ / (l₁ + l₂)`. -/
theorem exponential_race_min_and_first
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (l₁ l₂ : ℝ) (hl₁ : 0 < l₁) (hl₂ : 0 < l₂) (S U : Ω → ℝ)
    (hSU : IndepFun S U P)
    (hS : HasLaw S (expMeasure l₁) P) (hU : HasLaw U (expMeasure l₂) P) :
    HasLaw (fun ω => min (S ω) (U ω)) (expMeasure (l₁ + l₂)) P ∧
      P.real {ω | S ω < U ω} = l₁ / (l₁ + l₂) := by
  have hSm := hS.aemeasurable
  have hUm := hU.aemeasurable
  have hm : AEMeasurable (fun ω => min (S ω) (U ω)) P := hSm.min hUm
  have hl : 0 < l₁ + l₂ := add_pos hl₁ hl₂
  refine ⟨⟨hm, ?_⟩, ?_⟩
  · have : IsProbabilityMeasure (P.map fun ω => min (S ω) (U ω)) :=
      (Measure.isProbabilityMeasure_map_iff hm).2 inferInstance
    have := isProbabilityMeasure_expMeasure hl
    apply Measure.eq_of_cdf
    ext x
    rw [ProbabilityTheory.cdf_eq_real, cdf_expMeasure_eq hl, map_measureReal_apply_of_aemeasurable hm measurableSet_Iic]
    have hset : (fun ω => min (S ω) (U ω)) ⁻¹' Set.Iic x =
        (S ⁻¹' Set.Ioi x ∩ U ⁻¹' Set.Ioi x)ᶜ := by
      ext ω; simp only [Set.mem_preimage, Set.mem_Iic, Set.mem_compl_iff, Set.mem_inter_iff,
        Set.mem_Ioi, min_le_iff]; grind
    have hnull : NullMeasurableSet (S ⁻¹' Set.Ioi x ∩ U ⁻¹' Set.Ioi x) P :=
      (hSm.nullMeasurable measurableSet_Ioi).inter (hUm.nullMeasurable measurableSet_Ioi)
    have hind : P.real (S ⁻¹' Set.Ioi x ∩ U ⁻¹' Set.Ioi x) =
        P.real (S ⁻¹' Set.Ioi x) * P.real (U ⁻¹' Set.Ioi x) := by
      rw [measureReal_def, hSU.measure_inter_preimage_eq_mul _ _ measurableSet_Ioi
        measurableSet_Ioi, ENNReal.toReal_mul]
      rfl
    have hS' : P.real (S ⁻¹' Set.Ioi x) = if 0 ≤ x then Real.exp (-(l₁ * x)) else 1 := by
      rw [← expMeasure_real_tail hl₁ x]
      exact hS.measureReal_eq (p := fun y => x < y) measurableSet_Ioi
    have hU' : P.real (U ⁻¹' Set.Ioi x) = if 0 ≤ x then Real.exp (-(l₂ * x)) else 1 := by
      rw [← expMeasure_real_tail hl₂ x]
      exact hU.measureReal_eq (p := fun y => x < y) measurableSet_Ioi
    rw [hset, probReal_compl_eq_one_sub₀ hnull, hind, hS', hU']
    split_ifs
    · rw [← Real.exp_add]; ring_nf
    · ring
  · have hpair : HasLaw (fun ω => (S ω, U ω)) ((expMeasure l₁).prod (expMeasure l₂)) P :=
      (indepFun_iff_hasLaw_prodMk_prod hS hU).1 hSU
    have hmeas : MeasurableSet {q : ℝ × ℝ | q.1 < q.2} :=
      measurableSet_lt measurable_fst measurable_snd
    have h := hpair.measure_eq (p := fun q => q.1 < q.2) hmeas
    rw [measureReal_def]
    simp only at h
    have := isProbabilityMeasure_expMeasure hl₂
    rw [h, Measure.prod_apply hmeas]
    have key : ∀ s : ℝ, expMeasure l₂ (Prod.mk s ⁻¹' {q : ℝ × ℝ | q.1 < q.2}) =
        ENNReal.ofReal (if 0 ≤ s then Real.exp (-(l₂ * s)) else 1) := by
      intro s
      have := isProbabilityMeasure_expMeasure hl₂
      rw [← expMeasure_real_tail hl₂ s, ofReal_measureReal]
      rfl
    simp_rw [key]
    have hmeasf : Measurable fun s : ℝ => ENNReal.ofReal (if 0 ≤ s then Real.exp (-(l₂ * s)) else 1) := by
      apply Measurable.ennreal_ofReal
      exact Measurable.ite measurableSet_Ici (by fun_prop) measurable_const
    rw [expMeasure, gammaMeasure, lintegral_withDensity_eq_lintegral_mul _
      (show Measurable (gammaPDF 1 l₁) from (measurable_gammaPDFReal 1 l₁).ennreal_ofReal) hmeasf]
    have hpt : (gammaPDF 1 l₁ * fun s : ℝ => ENNReal.ofReal (if 0 ≤ s then Real.exp (-(l₂ * s)) else 1))
        = fun s => ENNReal.ofReal (l₁ / (l₁ + l₂)) * exponentialPDF (l₁ + l₂) s := by
      funext s
      exact exponentialPDF_mul_tail hl₁ hl₂ s
    rw [hpt, lintegral_const_mul' _ _ ENNReal.ofReal_ne_top, lintegral_exponentialPDF_eq_one hl,
      mul_one, ENNReal.toReal_ofReal (by positivity)]

-- The desks' rates: 0.25 × 4 = 1 and 0.75 × 4 = 3 calls an hour; merged back, 1 + 3 = 4.
example : (1 / 4 : ℚ) * 4 = 1 ∧ (3 / 4 : ℚ) * 4 = 3 ∧ (1 : ℚ) + 3 = 4 := by norm_num
-- The coins give 1 sales, 2 support: 3 orders × 0.25 × 0.75 × 0.75 = 27/64 (0.421875).
example : Nat.choose 3 1 = 3 := by decide
example : (Nat.choose 3 1 : ℚ) * (1 / 4) * (3 / 4) ^ 2 = 27 / 64 := by norm_num [Nat.choose]
-- The two roads agree: e^(-4) 4^3/3! × 27/64 = (e^(-1) 1^1/1!) × (e^(-3) 3^2/2!).
example : Real.exp (-4) * 4 ^ 3 / (Nat.factorial 3 : ℝ) * (27 / 64)
    = (Real.exp (-1) * 1 ^ 1 / (Nat.factorial 1 : ℝ)) *
      (Real.exp (-3) * 3 ^ 2 / (Nat.factorial 2 : ℝ)) := by
  rw [show (-4 : ℝ) = -1 + -3 by norm_num, Real.exp_add]
  norm_num [Nat.factorial]
  ring
-- Every label word for switchboard totals 0 to 16: 1 + 2 + ... + 2^16 = 131071.
example : (Finset.range 17).sum (fun n => 2 ^ n) = 131071 := by decide
-- Merging: sales rings first with chance 1/(1 + 3) = 1/4; the merged mean wait is 1/4 hour.
example : (1 : ℚ) / (1 + 3) = 1 / 4 ∧ (1 : ℚ) / 4 = 0.25 := by norm_num
-- Told the switchboard took 3: sales is silent only if all 3 coins say support, 0.75^3 = 27/64.
example : (3 / 4 : ℚ) ^ 3 = 27 / 64 := by norm_num
-- Calls on the quarter hour (4 each hour): sales silent 0.75^4 = 81/256 (0.3164), and the
-- covariance is minus a binomial variance, -4 × 0.25 × 0.75 = -3/4.
example : (3 / 4 : ℚ) ^ 4 = 81 / 256 ∧ -(4 : ℚ) * (1 / 4) * (3 / 4) = -3 / 4 := by norm_num

#print axioms poisson_split_independent_poisson_counts
#print axioms poisson_merge_sum_and_source_labels
#print axioms exponential_race_min_and_first
