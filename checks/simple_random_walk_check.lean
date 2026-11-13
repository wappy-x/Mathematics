-- Simple random walk: for independent plus-or-minus-one rounds that each win with the same chance p, the position after n rounds is a relabelled binomial count with mean n(2p − 1), variance 4np(1 − p) and covariance 4ap(1 − p) between rounds a ≤ b, and a fair walk visits zero (2m + 1) C(2m, m)/4^m − 1 times on average in 2m rounds.
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Moments.Covariance
import Mathlib.Data.Nat.Choose.Central
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.NormNum.RealSqrt

open MeasureTheory ProbabilityTheory

/-- The walk's position after `n` rounds: the sum `S_n = ξ_0 + ξ_1 + ⋯ + ξ_(n-1)` of the first
`n` round results, with `S_0 = 0`. -/
def walk {Ω : Type*} (ξ : ℕ → Ω → ℝ) (n : ℕ) : Ω → ℝ :=
  fun ω => ∑ i ∈ Finset.range n, ξ i ω

lemma srw_preimage_neg {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X : Ω → ℝ) (hX : Measurable X) (hstep : ∀ ω, X ω = 1 ∨ X ω = -1) :
    P.real (X ⁻¹' {-1}) = 1 - P.real (X ⁻¹' {1}) := by
  have : X ⁻¹' {-1} = (X ⁻¹' {1})ᶜ := by
    ext ω
    simp only [Set.mem_preimage, Set.mem_singleton_iff, Set.mem_compl_iff]
    rcases hstep ω with h | h <;> rw [h] <;> norm_num
  rw [this, probReal_compl_eq_one_sub (hX (measurableSet_singleton 1))]

lemma srw_filter_card (n : ℕ) (s : Finset ℕ) (hs : s ⊆ Finset.range n) :
    (Finset.range n).filter (· ∈ s) = s ∧
      ((Finset.range n).filter (· ∉ s)).card = n - s.card := by
  have hc : (Finset.range n).filter (· ∈ s) = s := by
    ext i
    simp only [Finset.mem_filter, and_iff_right_iff_imp]
    exact fun h => hs h
  refine ⟨hc, ?_⟩
  have := Finset.card_filter_add_card_filter_not (s := Finset.range n) (· ∈ s)
  rw [hc, Finset.card_range] at this
  omega

lemma srw_cyl_prob {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ P)
    (hstep : ∀ i ω, ξ i ω = 1 ∨ ξ i ω = -1)
    (p : ℝ) (hp : ∀ i, P.real {ω | ξ i ω = 1} = p) (n : ℕ) (s : Finset ℕ)
    (hs : s ⊆ Finset.range n) :
    P.real (⋂ i ∈ Finset.range n, ξ i ⁻¹' {if i ∈ s then (1 : ℝ) else -1})
      = p ^ s.card * (1 - p) ^ (n - s.card) := by
  rw [measureReal_def, hind.measure_inter_preimage_eq_mul (Finset.range n)
    (fun i _ => measurableSet_singleton _), ENNReal.toReal_prod]
  have h1 : ∀ i ∈ Finset.range n, (P (ξ i ⁻¹' {if i ∈ s then (1 : ℝ) else -1})).toReal
      = if i ∈ s then p else 1 - p := by
    intro i _
    split_ifs
    · exact hp i
    · rw [← measureReal_def, srw_preimage_neg P (ξ i) (hmeas i) (hstep i), ← hp i]
      rfl
  obtain ⟨hc, hc'⟩ := srw_filter_card n s hs
  rw [Finset.prod_congr rfl h1, Finset.prod_ite, Finset.prod_const, Finset.prod_const, hc, hc']

lemma srw_walk_on_cyl {Ω : Type*} (ξ : ℕ → Ω → ℝ) (n : ℕ) (s : Finset ℕ)
    (hs : s ⊆ Finset.range n) (ω : Ω)
    (hω : ∀ i ∈ Finset.range n, ξ i ω = if i ∈ s then (1 : ℝ) else -1) :
    walk ξ n ω = 2 * (s.card : ℝ) - n := by
  obtain ⟨hc, hc'⟩ := srw_filter_card n s hs
  have hle : s.card ≤ n := by simpa using Finset.card_le_card hs
  unfold walk
  rw [Finset.sum_congr rfl hω, Finset.sum_ite, Finset.sum_const, Finset.sum_const, hc, hc']
  simp only [nsmul_eq_mul, mul_one, mul_neg]
  rw [Nat.cast_sub hle]
  ring

lemma srw_law_sum {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ P)
    (hstep : ∀ i ω, ξ i ω = 1 ∨ ξ i ω = -1)
    (p : ℝ) (hp : ∀ i, P.real {ω | ξ i ω = 1} = p) (n : ℕ) (x : ℝ) :
    P.real {ω | walk ξ n ω = x} =
      ∑ s ∈ (Finset.range n).powerset.filter (fun s => 2 * (s.card : ℝ) - n = x),
        p ^ s.card * (1 - p) ^ (n - s.card) := by
  classical
  set A : Finset ℕ → Set Ω :=
    fun s => ⋂ i ∈ Finset.range n, ξ i ⁻¹' {if i ∈ s then (1 : ℝ) else -1} with hA
  have hmem : ∀ s ω, ω ∈ A s ↔ ∀ i ∈ Finset.range n, ξ i ω = if i ∈ s then (1 : ℝ) else -1 := by
    intro s ω
    simp [hA]
  have hset : {ω | walk ξ n ω = x} =
      ⋃ s ∈ (Finset.range n).powerset.filter (fun s => 2 * (s.card : ℝ) - n = x), A s := by
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_filter, Finset.mem_powerset,
      exists_prop]
    constructor
    · intro h
      refine ⟨(Finset.range n).filter (fun i => ξ i ω = 1), ⟨Finset.filter_subset _ _, ?_⟩, ?_⟩
      · rw [← h]
        refine (srw_walk_on_cyl ξ n _ (Finset.filter_subset _ _) ω ?_).symm
        intro i hi
        simp only [Finset.mem_filter, hi, true_and]
        split_ifs with h1
        · exact h1
        · exact (hstep i ω).resolve_left h1
      · rw [hmem]
        intro i hi
        simp only [Finset.mem_filter, hi, true_and]
        split_ifs with h1
        · exact h1
        · exact (hstep i ω).resolve_left h1
    · rintro ⟨s, ⟨hs, hx⟩, hω⟩
      rw [hmem] at hω
      rw [srw_walk_on_cyl ξ n s hs ω hω, hx]
  rw [hset, measureReal_biUnion_finset]
  · refine Finset.sum_congr rfl fun s hs => ?_
    simp only [Finset.mem_filter, Finset.mem_powerset] at hs
    exact srw_cyl_prob P ξ hmeas hind hstep p hp n s hs.1
  · intro s hs t ht hst
    simp only [Finset.coe_filter, Finset.mem_powerset, Set.mem_ofPred_eq] at hs ht
    rw [Function.onFun, Set.disjoint_left]
    intro ω hωs hωt
    rw [hmem] at hωs hωt
    apply hst
    ext i
    by_cases hi : i ∈ Finset.range n
    · have e1 := hωs i hi
      have e2 := hωt i hi
      constructor
      · intro his
        by_contra hit
        simp only [his, hit, ite_true, ite_false] at e1 e2
        linarith
      · intro hit
        by_contra his
        simp only [his, hit, ite_true, ite_false] at e1 e2
        linarith
    · exact ⟨fun h => absurd (hs.1 h) hi, fun h => absurd (ht.1 h) hi⟩
  · intro s _
    exact Finset.measurableSet_biInter _ fun i _ => hmeas i (measurableSet_singleton _)

lemma srw_memLp {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X : Ω → ℝ) (hX : Measurable X) (hstep : ∀ ω, X ω = 1 ∨ X ω = -1) :
    MemLp X 2 P :=
  MemLp.of_bound hX.aestronglyMeasurable 1
    (ae_of_all _ fun ω => by rcases hstep ω with h | h <;> simp [h])

lemma srw_step_mean {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X : Ω → ℝ) (hX : Measurable X) (hstep : ∀ ω, X ω = 1 ∨ X ω = -1) :
    ∫ ω, X ω ∂P = 2 * P.real {ω | X ω = 1} - 1 := by
  have hms : MeasurableSet {ω | X ω = 1} := hX (measurableSet_singleton 1)
  have hfun : ∀ ω, X ω = 2 * ({ω | X ω = 1}.indicator 1 ω) - 1 := by
    intro ω
    rcases hstep ω with h | h <;> simp [Set.indicator, h] <;> norm_num
  rw [integral_congr_ae (ae_of_all _ hfun), integral_sub, integral_const_mul, integral_indicator_one hms]
  · simp
  · exact ((integrable_const (1 : ℝ)).indicator hms).const_mul 2
  · exact integrable_const _

lemma srw_step_var {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X : Ω → ℝ) (hX : Measurable X) (hstep : ∀ ω, X ω = 1 ∨ X ω = -1) :
    variance X P = 4 * P.real {ω | X ω = 1} * (1 - P.real {ω | X ω = 1}) := by
  rw [variance_eq_sub (srw_memLp P X hX hstep), srw_step_mean P X hX hstep]
  have hsq : X ^ 2 = fun _ => (1 : ℝ) := by
    funext ω
    rcases hstep ω with h | h <;> simp [h]
  rw [hsq]
  simp
  ring

#print axioms srw_preimage_neg
#print axioms srw_filter_card
#print axioms srw_cyl_prob
#print axioms srw_walk_on_cyl
#print axioms srw_law_sum
#print axioms srw_memLp
#print axioms srw_step_mean
#print axioms srw_step_var

/-- The law of the walk after `n` rounds. Each round's result is `+1` or `−1`, the rounds are
independent, and every round is a win (`+1`) with the same chance `p`. Then the walk stands at
height `2j − n` (that is, it won exactly `j` of the `n` rounds) with chance
`C(n, j) p^j (1 − p)^(n − j)`. Every other height has chance 0: one whose parity differs from
`n`, or one farther than `n` from 0. -/
theorem walk_law_is_relabelled_binomial
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ P)
    (hstep : ∀ i ω, ξ i ω = 1 ∨ ξ i ω = -1)
    (p : ℝ) (hp : ∀ i, P.real {ω | ξ i ω = 1} = p) (n : ℕ) :
    (∀ j ≤ n, P.real {ω | walk ξ n ω = 2 * (j : ℝ) - n}
        = (n.choose j : ℝ) * p ^ j * (1 - p) ^ (n - j)) ∧
    (∀ k : ℤ, (Odd ((n : ℤ) + k) ∨ (n : ℤ) < |k|) → P.real {ω | walk ξ n ω = k} = 0) := by
  constructor
  · intro j hj
    rw [srw_law_sum P ξ hmeas hind hstep p hp n]
    have hF : (Finset.range n).powerset.filter
        (fun s => 2 * (s.card : ℝ) - n = 2 * (j : ℝ) - n) = Finset.powersetCard j (Finset.range n) := by
      ext s
      simp only [Finset.mem_filter, Finset.mem_powerset, Finset.mem_powersetCard]
      constructor
      · rintro ⟨h1, h2⟩
        refine ⟨h1, ?_⟩
        have : (s.card : ℝ) = j := by linarith
        exact_mod_cast this
      · rintro ⟨h1, h2⟩
        exact ⟨h1, by rw [h2]⟩
    rw [hF, Finset.sum_congr rfl (g := fun _ => p ^ j * (1 - p) ^ (n - j))]
    · rw [Finset.sum_const, Finset.card_powersetCard, Finset.card_range, nsmul_eq_mul]
      ring
    · intro s hs
      rw [(Finset.mem_powersetCard.mp hs).2]
  · intro k hk
    rw [srw_law_sum P ξ hmeas hind hstep p hp n]
    apply Finset.sum_eq_zero
    intro s hs
    exfalso
    simp only [Finset.mem_filter, Finset.mem_powerset] at hs
    obtain ⟨hs1, hs2⟩ := hs
    have hle : s.card ≤ n := by simpa using Finset.card_le_card hs1
    have hz : 2 * (s.card : ℤ) - n = k := by exact_mod_cast hs2
    rcases hk with ⟨c, hc⟩ | hk
    · omega
    · rw [lt_abs] at hk
      omega

/-- Mean, variance and shared rounds. Under the same conditions, the mean position after `n`
rounds is `n (2p − 1)` and its variance is `4 n p (1 − p)`. For rounds `a ≤ b` the covariance of
the positions there is `4 a p (1 − p)`, the variance at the earlier round. -/
theorem walk_mean_variance_covariance
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ P)
    (hstep : ∀ i ω, ξ i ω = 1 ∨ ξ i ω = -1)
    (p : ℝ) (hp : ∀ i, P.real {ω | ξ i ω = 1} = p) :
    (∀ n : ℕ, ∫ ω, walk ξ n ω ∂P = n * (2 * p - 1)) ∧
    (∀ n : ℕ, variance (walk ξ n) P = 4 * n * p * (1 - p)) ∧
    (∀ a b : ℕ, a ≤ b → covariance (walk ξ a) (walk ξ b) P = 4 * a * p * (1 - p)) := by
  have hL : ∀ i, MemLp (ξ i) 2 P := fun i => srw_memLp P (ξ i) (hmeas i) (hstep i)
  have hcov : ∀ i j, covariance (ξ i) (ξ j) P = if i = j then 4 * p * (1 - p) else 0 := by
    intro i j
    split_ifs with hij
    · subst hij
      rw [covariance_self (hmeas i).aemeasurable, srw_step_var P (ξ i) (hmeas i) (hstep i), hp i]
    · exact (hind.indepFun hij).covariance_eq_zero (hL i) (hL j)
  have hC : ∀ a b : ℕ, a ≤ b → covariance (walk ξ a) (walk ξ b) P = 4 * a * p * (1 - p) := by
    intro a b hab
    unfold walk
    rw [covariance_fun_sum_fun_sum' (fun i _ => hL i) (fun i _ => hL i)]
    simp_rw [hcov, Finset.sum_ite_eq]
    rw [Finset.sum_congr rfl (g := fun _ => 4 * p * (1 - p))]
    · simp
      ring
    · intro i hi
      rw [ite_eq_left_iff.mpr (fun h => absurd ?_ h)]
      simp only [Finset.mem_range] at hi ⊢
      omega
  refine ⟨?_, ?_, hC⟩
  · intro n
    unfold walk
    rw [integral_finsetSum _ (fun i _ => (hL i).integrable one_le_two)]
    simp_rw [srw_step_mean P (ξ _) (hmeas _) (hstep _), hp]
    simp
    ring
  · intro n
    have hm : Measurable (walk ξ n) := by
      unfold walk
      exact Finset.measurable_sum _ fun i _ => hmeas i
    rw [← covariance_self hm.aemeasurable, hC n n le_rfl]

/-- Returns to zero for a fair walk (`p = 1/2`). The expected number of rounds among the first
`2m` at which the walk stands at 0 is `(2m + 1) u_m − 1`, where `u_m = C(2m, m)/4^m` is the chance
of standing at 0 after `2m` rounds. -/
theorem fair_walk_expected_visits_to_zero
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ P)
    (hstep : ∀ i ω, ξ i ω = 1 ∨ ξ i ω = -1)
    (hp : ∀ i, P.real {ω | ξ i ω = 1} = 1 / 2) (m : ℕ) :
    ∫ ω, (((Finset.Icc 1 (2 * m)).filter (fun t => walk ξ t ω = 0)).card : ℝ) ∂P
      = (2 * m + 1) * (Nat.centralBinom m : ℝ) / 4 ^ m - 1 := by
  classical
  have hm : ∀ t, Measurable (walk ξ t) := fun t => Finset.measurable_sum _ fun i _ => hmeas i
  have hms : ∀ t, MeasurableSet {ω | walk ξ t ω = 0} :=
    fun t => hm t (measurableSet_singleton 0)
  have hcount : ∀ ω, (((Finset.Icc 1 (2 * m)).filter (fun t => walk ξ t ω = 0)).card : ℝ)
      = ∑ t ∈ Finset.Icc 1 (2 * m), {ω | walk ξ t ω = 0}.indicator 1 ω := by
    intro ω
    rw [Finset.natCast_card_filter]
    refine Finset.sum_congr rfl fun t _ => ?_
    simp [Set.indicator]
  rw [integral_congr_ae (ae_of_all _ hcount),
    integral_finsetSum (f := fun t => {ω | walk ξ t ω = 0}.indicator (1 : Ω → ℝ)) _
      (fun t _ => (integrable_const (1 : ℝ)).indicator (hms t))]
  simp_rw [integral_indicator_one (hms _)]
  have hodd : ∀ k : ℕ, P.real {ω | walk ξ (2 * k + 1) ω = 0} = 0 := by
    intro k
    have := (walk_law_is_relabelled_binomial P ξ hmeas hind hstep (1 / 2) hp (2 * k + 1)).2 0
      (Or.inl ⟨k, by push_cast; ring⟩)
    simpa using this
  have heven : ∀ k : ℕ, P.real {ω | walk ξ (2 * k) ω = 0} = (Nat.centralBinom k : ℝ) / 4 ^ k := by
    intro k
    have := (walk_law_is_relabelled_binomial P ξ hmeas hind hstep (1 / 2) hp (2 * k)).1 k
      (by omega)
    have e : 2 * (k : ℝ) - ((2 * k : ℕ) : ℝ) = 0 := by push_cast; ring
    rw [e] at this
    rw [this, Nat.centralBinom_eq_two_mul_choose, show 2 * k - k = k by omega]
    rw [show (1 : ℝ) - 1 / 2 = 1 / 2 by norm_num, mul_assoc, ← mul_pow,
      show (1 : ℝ) / 2 * (1 / 2) = 1 / 4 by norm_num, div_pow, one_pow, mul_one_div]
  clear hcount
  induction m with
  | zero => simp
  | succ m ih =>
    rw [show 2 * (m + 1) = (2 * m + 1) + 1 by ring, Finset.sum_Icc_succ_top (by omega),
      Finset.sum_Icc_succ_top (by omega), ih, hodd, show 2 * m + 1 + 1 = 2 * (m + 1) by ring,
      heven]
    have key : ((m : ℝ) + 1) * (Nat.centralBinom (m + 1) : ℝ)
        = 2 * (2 * m + 1) * (Nat.centralBinom m : ℝ) := by
      exact_mod_cast Nat.succ_mul_centralBinom_succ m
    rw [pow_succ]
    field_simp
    push_cast
    linear_combination (-2) * key

-- Order does not matter: W L W W and W W W L both end at +2, three wins and one loss, 2 × 3 − 4.
example : (1 + -1 + 1 + 1 : ℤ) = 2 ∧ (1 + 1 + 1 + -1 : ℤ) = 2 ∧ 2 * 3 - 4 = 2 := by norm_num
-- Fair game, 100 rounds: one round's mean 1 × 1/2 + (−1) × 1/2 = 0 and variance 1 − 0 × 0 = 1;
-- after 100 rounds the mean is 0, the variance 100 and the spread √100 = 10.
example : (1 : ℚ) * (1 / 2) + (-1) * (1 / 2) = 0 ∧ (1 : ℚ) - 0 * 0 = 1 := by norm_num
example : (100 : ℝ) * (2 * (1 / 2) - 1) = 0 ∧ 4 * (100 : ℝ) * (1 / 2) * (1 - 1 / 2) = 100 := by
  norm_num
example : Real.sqrt 100 = 10 := by norm_num
-- Spread against rounds: 25, 100, 400, 1,600 rounds give $5, $10, $20, $40.
example : Real.sqrt 25 = 5 ∧ Real.sqrt 100 = 10 ∧ Real.sqrt 400 = 20 ∧ Real.sqrt 1600 = 40 := by
  norm_num
-- Ending level after 100 fair rounds: C(100, 50) of the 2^100 equally likely paths.
example : Nat.choose 100 50 = 100891344545564193334812497256 := by
  rw [Nat.choose_eq_factorial_div_factorial (by norm_num)]; norm_num [Nat.factorial]
example : 2 ^ 100 = 1267650600228229401496703205376 := by norm_num
-- Shared rounds: Cov(S_50, S_100) = 4 × 50 × 1/2 × 1/2 = 50; the correlation 50/√(50 × 100)
-- squares to 1/2 (it is 0.7071).
example : 4 * (50 : ℝ) * (1 / 2) * (1 - 1 / 2) = 50 := by norm_num
example : ((50 : ℝ) / Real.sqrt (50 * 100)) ^ 2 = 1 / 2 := by
  rw [div_pow, Real.sq_sqrt (by norm_num)]; norm_num
-- Red at European roulette, p = 18/37: after 100 spins the mean is −100/37 (−$2.70) and the
-- variance 136800/1369; after 10,000 spins the mean is −10000/37 (−$270.27).
example : (100 : ℚ) * (2 * (18 / 37) - 1) = -100 / 37 := by norm_num
example : 4 * (100 : ℚ) * (18 / 37) * (1 - 18 / 37) = 136800 / 1369 := by norm_num
example : (10000 : ℚ) * (2 * (18 / 37) - 1) = -10000 / 37 := by norm_num
-- Visits to 0 in 100 rounds (m = 50): u_0 + u_1 + ⋯ + u_50 = 101 u_50, in whole numbers after
-- multiplying by 4^50, so the expected visits are 101 × C(100, 50)/2^100 − 1.
example : ∑ k ∈ Finset.range 51, Nat.centralBinom k * 4 ^ (50 - k) = 101 * Nat.centralBinom 50 := by
  decide +kernel

#print axioms walk_law_is_relabelled_binomial
#print axioms walk_mean_variance_covariance
#print axioms fair_walk_expected_visits_to_zero
