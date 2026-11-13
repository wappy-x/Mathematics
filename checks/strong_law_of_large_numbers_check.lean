-- The strong law of large numbers: for independent draws from one law with a finite mean, the running average converges to that mean on a set of outcomes of probability one, and under a finite fourth moment the fourth power of the total error has expectation n m₄ + 3n(n - 1)σ⁴, so the chance of a bad average at draw n is at most (m₄ + 3σ⁴)/(n²ε⁴).
import Mathlib.Probability.StrongLaw
import Mathlib.Probability.IdentDistrib
import Mathlib.Probability.Independence.Basic

open MeasureTheory ProbabilityTheory Filter Topology

/-- Powers up to four of a function with finite fourth moment are integrable. -/
lemma slln_integrable_pow {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {f : Ω → ℝ} (hf : MemLp f 4 P) {k : ℕ} (hk : k ≤ 4) :
    Integrable (fun ω => f ω ^ k) P := by
  have h4 : Integrable (fun ω => f ω ^ 4) P := by
    have := hf.integrable_norm_pow (p := 4) (by norm_num)
    refine this.congr (Filter.Eventually.of_forall fun ω => ?_)
    simp only [Real.norm_eq_abs]
    rw [pow_abs]; exact abs_of_nonneg (by positivity)
  refine Integrable.mono' ((integrable_const (1 : ℝ)).add h4) (hf.aestronglyMeasurable.pow k) ?_
  refine Filter.Eventually.of_forall fun ω => ?_
  simp only [Real.norm_eq_abs, abs_pow, Pi.add_apply]
  have h4' : |f ω| ^ 4 = f ω ^ 4 := by rw [pow_abs]; exact abs_of_nonneg (by positivity)
  have h0 : 0 ≤ f ω ^ 4 := by positivity
  rcases le_or_gt (|f ω|) 1 with h | h
  · have : |f ω| ^ k ≤ 1 := pow_le_one₀ (abs_nonneg _) h
    linarith
  · have : |f ω| ^ k ≤ |f ω| ^ 4 := pow_le_pow_right₀ h.le hk
    linarith

/-- The fourth-moment identity for centred independent identically distributed draws. -/
lemma slln_fourth_moment_centered {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (Y : ℕ → Ω → ℝ) (hind : iIndepFun Y P)
    (hident : ∀ i, IdentDistrib (Y i) (Y 0) P P) (h4 : MemLp (Y 0) 4 P)
    (hmean : ∫ ω, Y 0 ω ∂P = 0) (n : ℕ) :
    ∫ ω, (∑ i ∈ Finset.range n, Y i ω) ^ 4 ∂P =
      n * ∫ ω, Y 0 ω ^ 4 ∂P + 3 * n * (n - 1) * (∫ ω, Y 0 ω ^ 2 ∂P) ^ 2 := by
  have hm : ∀ i, AEMeasurable (Y i) P := fun i => (hident i).aemeasurable_fst
  have hL : ∀ i, MemLp (Y i) 4 P := fun i => (hident i).memLp_iff.2 h4
  have hmom : ∀ i k, ∫ ω, Y i ω ^ k ∂P = ∫ ω, Y 0 ω ^ k ∂P := fun i k =>
    ((hident i).comp (measurable_id.pow_const k)).integral_eq
  have hY1 : ∀ i, ∫ ω, Y i ω ∂P = 0 := fun i => by
    have := hmom i 1; simp only [pow_one] at this; rw [this, hmean]
  set S : ℕ → Ω → ℝ := fun n ω => ∑ i ∈ Finset.range n, Y i ω with hS
  have hSL : ∀ n, MemLp (S n) 4 P := fun n => by
    have := memLp_finsetSum' (Finset.range n) (fun i _ => hL i)
    convert this using 1; ext ω; simp [S]
  have hind' : ∀ n, IndepFun (S n) (Y n) P := fun n => by
    have := hind.indepFun_sum_range_succ₀ hm n
    convert this using 1; ext ω; simp [S]
  have hprod : ∀ n a b, ∫ ω, S n ω ^ a * Y n ω ^ b ∂P
      = (∫ ω, S n ω ^ a ∂P) * ∫ ω, Y n ω ^ b ∂P := fun n a b =>
    ((hind' n).comp (measurable_id.pow_const a)
      (measurable_id.pow_const b)).integral_fun_mul_eq_mul_integral
      ((hSL n).aestronglyMeasurable.pow a) ((hL n).aestronglyMeasurable.pow b)
  have hprodI : ∀ n a b, a ≤ 4 → b ≤ 4 → Integrable (fun ω => S n ω ^ a * Y n ω ^ b) P :=
    fun n a b ha hb =>
    ((hind' n).comp (measurable_id.pow_const a) (measurable_id.pow_const b)).integrable_mul
      (slln_integrable_pow (hSL n) ha) (slln_integrable_pow (hL n) hb)
  have hsucc : ∀ n ω, S (n+1) ω = S n ω + Y n ω := fun n ω => by
    simp [S, Finset.sum_range_succ]
  have hS1 : ∀ n, ∫ ω, S n ω ^ 1 ∂P = 0 := fun n => by
    simp only [S, pow_one]
    rw [integral_finsetSum _ (fun i _ => (hL i).integrable (by norm_num))]
    exact Finset.sum_eq_zero fun i _ => hY1 i
  have hY1' : ∀ n, ∫ ω, Y n ω ^ 1 ∂P = 0 := fun n => by simp only [pow_one]; exact hY1 n
  have hS2 : ∀ n : ℕ, ∫ ω, S n ω ^ 2 ∂P = n * ∫ ω, Y 0 ω ^ 2 ∂P := by
    intro n
    induction n with
    | zero => simp [S]
    | succ n ih =>
      have e : (fun ω => S (n+1) ω ^ 2) = fun ω =>
          (S n ω ^ 2 + 2 * (S n ω ^ 1 * Y n ω ^ 1)) + Y n ω ^ 2 := by
        funext ω; rw [hsucc]; ring
      have i2 : Integrable (fun ω => S n ω ^ 2) P := slln_integrable_pow (hSL n) (by norm_num)
      have i11 : Integrable (fun ω => 2 * (S n ω ^ 1 * Y n ω ^ 1)) P :=
        (hprodI n 1 1 (by norm_num) (by norm_num)).const_mul 2
      have iY2 : Integrable (fun ω => Y n ω ^ 2) P := slln_integrable_pow (hL n) (by norm_num)
      have iA : Integrable (fun ω => S n ω ^ 2 + 2 * (S n ω ^ 1 * Y n ω ^ 1)) P := i2.add i11
      rw [e, integral_add iA iY2, integral_add i2 i11, integral_const_mul, hprod, hS1, ih, hmom n 2]
      push_cast; ring
  show ∫ ω, S n ω ^ 4 ∂P = _
  induction n with
  | zero => simp [S]
  | succ n ih =>
    have e : (fun ω => S (n+1) ω ^ 4) = fun ω =>
        (((S n ω ^ 4 + 4 * (S n ω ^ 3 * Y n ω ^ 1)) + 6 * (S n ω ^ 2 * Y n ω ^ 2))
          + 4 * (S n ω ^ 1 * Y n ω ^ 3)) + Y n ω ^ 4 := by
      funext ω; rw [hsucc]; ring
    have i4 : Integrable (fun ω => S n ω ^ 4) P := slln_integrable_pow (hSL n) (le_refl 4)
    have i31 : Integrable (fun ω => 4 * (S n ω ^ 3 * Y n ω ^ 1)) P :=
      (hprodI n 3 1 (by norm_num) (by norm_num)).const_mul 4
    have i22 : Integrable (fun ω => 6 * (S n ω ^ 2 * Y n ω ^ 2)) P :=
      (hprodI n 2 2 (by norm_num) (by norm_num)).const_mul 6
    have i13 : Integrable (fun ω => 4 * (S n ω ^ 1 * Y n ω ^ 3)) P :=
      (hprodI n 1 3 (by norm_num) (by norm_num)).const_mul 4
    have iY : Integrable (fun ω => Y n ω ^ 4) P := slln_integrable_pow (hL n) (le_refl 4)
    have iA : Integrable (fun ω => S n ω ^ 4 + 4 * (S n ω ^ 3 * Y n ω ^ 1)) P := i4.add i31
    have iB : Integrable (fun ω => (S n ω ^ 4 + 4 * (S n ω ^ 3 * Y n ω ^ 1))
        + 6 * (S n ω ^ 2 * Y n ω ^ 2)) P := iA.add i22
    have iC : Integrable (fun ω => ((S n ω ^ 4 + 4 * (S n ω ^ 3 * Y n ω ^ 1))
        + 6 * (S n ω ^ 2 * Y n ω ^ 2)) + 4 * (S n ω ^ 1 * Y n ω ^ 3)) P := iB.add i13
    rw [e, integral_add iC iY, integral_add iB i13, integral_add iA i22,
      integral_add i4 i31, integral_const_mul, integral_const_mul, integral_const_mul,
      hprod, hprod, hprod, hS1, hY1', hS2, ih, hmom n 2, hmom n 4]
    push_cast; ring

/-- The centred total error has a finite fourth moment. -/
lemma slln_memLp_centered_sum {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P) (h4 : MemLp (X 0) 4 P) (n : ℕ) :
    MemLp (fun ω => (∑ i ∈ Finset.range n, X i ω) - n * ∫ ω', X 0 ω' ∂P) 4 P := by
  have := memLp_finsetSum' (Finset.range n)
    (fun i _ => ((hident i).memLp_iff.2 h4).sub (memLp_const (∫ ω', X 0 ω' ∂P)))
  convert this using 1
  ext ω
  simp [Finset.sum_sub_distrib]


/-- **The strong law of large numbers (Kolmogorov).** Let `X 0, X 1, X 2, …` be independent
random draws, all with the same law, with a finite mean `E|X 0| < ∞`. Then the set of
outcomes `ω` on which the running average `(X 0 ω + ⋯ + X (n-1) ω) / n` converges to the
mean `E[X 0]` has probability one. -/
theorem strong_law_of_large_numbers {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hint : Integrable (X 0) P) :
    P {ω | Tendsto (fun n : ℕ => (∑ i ∈ Finset.range n, X i ω) / n) atTop
        (𝓝 (∫ ω, X 0 ω ∂P))} = 1 := by
  have h := strong_law_ae_real X hint
    (fun i j hij => hind.indepFun hij) hident
  have hc : {ω | Tendsto (fun n : ℕ => (∑ i ∈ Finset.range n, X i ω) / n) atTop
      (𝓝 (∫ ω, X 0 ω ∂P))} =ᵐ[P] (Set.univ : Set Ω) := by
    rw [ae_eq_univ]
    exact ae_iff.1 h
  rw [measure_congr hc, measure_univ]

/-- **The fourth moment of the total error grows like n squared.** Let `X 0, X 1, …` be
independent draws, all with the same law, with a finite fourth moment. Write `μ = E[X 0]`,
`σ² = E[(X 0 - μ)²]` and `m₄ = E[(X 0 - μ)⁴]`. Then for every `n`, the sum `Sₙ` of the first
`n` draws satisfies `E[(Sₙ - nμ)⁴] = n m₄ + 3n(n - 1)σ⁴`. -/
theorem fourth_moment_of_sum {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (h4 : MemLp (X 0) 4 P) (n : ℕ) :
    ∫ ω, ((∑ i ∈ Finset.range n, X i ω) - n * ∫ ω', X 0 ω' ∂P) ^ 4 ∂P =
      n * ∫ ω, (X 0 ω - ∫ ω', X 0 ω' ∂P) ^ 4 ∂P
        + 3 * n * (n - 1) * (∫ ω, (X 0 ω - ∫ ω', X 0 ω' ∂P) ^ 2 ∂P) ^ 2 := by
  set μ0 := ∫ ω', X 0 ω' ∂P with hμ0
  set Y : ℕ → Ω → ℝ := fun i ω => X i ω - μ0 with hY
  have hYind : iIndepFun Y P := hind.comp (fun _ x => x - μ0) (fun _ => measurable_id.sub_const _)
  have hYid : ∀ i, IdentDistrib (Y i) (Y 0) P P := fun i =>
    (hident i).comp (measurable_id.sub_const μ0)
  have hY4 : MemLp (Y 0) 4 P := h4.sub (memLp_const μ0)
  have hint : Integrable (X 0) P := h4.integrable (by norm_num)
  have hmean : ∫ ω, Y 0 ω ∂P = 0 := by
    simp only [Y]
    rw [integral_sub hint (integrable_const _)]
    simp [μ0]
  have key := slln_fourth_moment_centered Y hYind hYid hY4 hmean n
  have e : (fun ω => ((∑ i ∈ Finset.range n, X i ω) - n * μ0) ^ 4)
      = fun ω => (∑ i ∈ Finset.range n, Y i ω) ^ 4 := by
    funext ω; simp [Y, Finset.sum_sub_distrib]
  rw [e, key]

/-- **The bad-average bound C/n².** Let `X 0, X 1, …` be independent draws, all with the
same law, with a finite fourth moment; let `μ`, `σ²`, `m₄` be as above. Then for every
`n ≥ 1` and every tolerance `ε > 0`, the chance that the average of the first `n` draws is
more than `ε` away from `μ` is at most `(m₄ + 3σ⁴) / (n² ε⁴)`. -/
theorem fourth_moment_tail_bound {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (h4 : MemLp (X 0) 4 P) (n : ℕ) (hn : 1 ≤ n) (ε : ℝ) (hε : 0 < ε) :
    P {ω | ε < |(∑ i ∈ Finset.range n, X i ω) / n - ∫ ω', X 0 ω' ∂P|} ≤
      ENNReal.ofReal
        ((∫ ω, (X 0 ω - ∫ ω', X 0 ω' ∂P) ^ 4 ∂P
            + 3 * (∫ ω, (X 0 ω - ∫ ω', X 0 ω' ∂P) ^ 2 ∂P) ^ 2) / (n ^ 2 * ε ^ 4)) := by
  set μ0 := ∫ ω', X 0 ω' ∂P with hμ0
  set m4 := ∫ ω, (X 0 ω - μ0) ^ 4 ∂P with hm4
  set σ2 := ∫ ω, (X 0 ω - μ0) ^ 2 ∂P with hσ2
  set T : Ω → ℝ := fun ω => (∑ i ∈ Finset.range n, X i ω) - n * μ0 with hT
  have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
  have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have hc : 0 < (n : ℝ) * ε := mul_pos hnpos hε
  -- the bad set sits inside a fourth-power set
  have hsub : {ω | ε < |(∑ i ∈ Finset.range n, X i ω) / n - μ0|}
      ⊆ {ω | ((n : ℝ) * ε) ^ 4 ≤ T ω ^ 4} := by
    intro ω hω
    simp only [Set.mem_ofPred_eq] at hω ⊢
    have h1 : (∑ i ∈ Finset.range n, X i ω) / n - μ0 = T ω / n := by
      simp only [T]; field_simp
    rw [h1, abs_div, abs_of_pos hnpos, lt_div_iff₀ hnpos] at hω
    have h2 : ((n : ℝ) * ε) ^ 4 ≤ |T ω| ^ 4 :=
      pow_le_pow_left₀ hc.le (by linarith) 4
    rw [pow_abs, abs_of_nonneg (by positivity)] at h2
    exact h2
  have hTint : Integrable (fun ω => T ω ^ 4) P :=
    slln_integrable_pow (slln_memLp_centered_sum X hident h4 n) (le_refl 4)
  have hmark := mul_meas_ge_le_integral_of_nonneg
    (Filter.Eventually.of_forall fun ω => by positivity) hTint (((n : ℝ) * ε) ^ 4)
  have hmom : ∫ ω, T ω ^ 4 ∂P = n * m4 + 3 * n * (n - 1) * σ2 ^ 2 :=
    fourth_moment_of_sum X hind hident h4 n
  rw [hmom] at hmark
  have hm4 : 0 ≤ m4 := integral_nonneg fun ω => by positivity
  have hσ : 0 ≤ σ2 ^ 2 := by positivity
  have hbound : (n : ℝ) * m4 + 3 * n * (n - 1) * σ2 ^ 2 ≤ (n : ℝ) ^ 2 * (m4 + 3 * σ2 ^ 2) := by
    nlinarith [mul_le_mul_of_nonneg_right (by nlinarith : (n : ℝ) ≤ n ^ 2) hm4]
  have hreal : P.real {ω | ((n : ℝ) * ε) ^ 4 ≤ T ω ^ 4}
      ≤ (m4 + 3 * σ2 ^ 2) / (n ^ 2 * ε ^ 4) := by
    have hc4 : 0 < ((n : ℝ) * ε) ^ 4 := by positivity
    rw [le_div_iff₀ (by positivity)]
    have : ((n : ℝ) * ε) ^ 4 * P.real {ω | ((n : ℝ) * ε) ^ 4 ≤ T ω ^ 4}
        ≤ (n : ℝ) ^ 2 * (m4 + 3 * σ2 ^ 2) := hmark.trans hbound
    have hP : 0 ≤ P.real {ω | ((n : ℝ) * ε) ^ 4 ≤ T ω ^ 4} := measureReal_nonneg
    have e : ((n : ℝ) * ε) ^ 4 = n ^ 2 * (n ^ 2 * ε ^ 4) := by ring
    rw [e] at this
    have hn2 : (0 : ℝ) < n ^ 2 := by positivity
    nlinarith
  calc P {ω | ε < |(∑ i ∈ Finset.range n, X i ω) / n - μ0|}
      ≤ P {ω | ((n : ℝ) * ε) ^ 4 ≤ T ω ^ 4} := measure_mono hsub
    _ = ENNReal.ofReal (P.real {ω | ((n : ℝ) * ε) ^ 4 ≤ T ω ^ 4}) :=
        (ofReal_measureReal).symm
    _ ≤ _ := ENNReal.ofReal_le_ofReal hreal

-- A fair die, centred faces ±1/2, ±3/2, ±5/2: σ² = 35/12 and m₄ = 707/48.
example : (2 * ((1 / 2) ^ 2 + (3 / 2) ^ 2 + (5 / 2) ^ 2) : ℚ) / 6 = 35 / 12 := by norm_num
example : (2 * ((1 / 2) ^ 4 + (3 / 2) ^ 4 + (5 / 2) ^ 4) : ℚ) / 6 = 707 / 48 := by norm_num
-- The closed forms (k² - 1)/12 and (k² - 1)(3k² - 7)/240 at k = 6.
example : ((6 ^ 2 - 1 : ℚ)) / 12 = 35 / 12 := by norm_num
example : ((6 ^ 2 - 1) * (3 * 6 ^ 2 - 7) : ℚ) / 240 = 707 / 48 := by norm_num
-- The formula at n = 2 gives 80.5 = 161/2, and at n = 8 gives 1547.
example : (2 * (707 / 48) + 3 * 2 * 1 * (35 / 12) ^ 2 : ℚ) = 161 / 2 := by norm_num
example : (8 * (707 / 48) + 3 * 8 * 7 * (35 / 12) ^ 2 : ℚ) = 1547 := by norm_num
-- Counting all 6² sequences of two rolls: the sum of (2S - 14)⁴ = 16 (S - 7)⁴ over the 36
-- sequences is 46368 = 16 · 36 · 161/2, the same 80.5.
example : (∑ a ∈ Finset.range 6, ∑ b ∈ Finset.range 6,
    ((2 * ((a : ℤ) + 1) + 2 * ((b : ℤ) + 1) - 14) ^ 4)) = 46368 := by decide
example : (46368 : ℚ) / (16 * 36) = 161 / 2 := by norm_num
-- The pairs-of-indices count: choose 2 of n indices, then 6 placements, is 3n(n - 1), at n = 8.
example : Nat.choose 8 2 * Nat.choose 4 2 = 3 * 8 * 7 := by decide
-- m₄ + 3σ⁴ = 40.25 = 161/4, and C = that / 0.1⁴ = 402,500.
example : (707 / 48 + 3 * (35 / 12) ^ 2 : ℚ) = 161 / 4 := by norm_num
example : ((161 / 4) / (1 / 10) ^ 4 : ℚ) = 402500 := by norm_num
-- At n = 1000: the bound C/n² is 0.4025 and Chebyshev's bound is 7/24.
example : (402500 / 1000 ^ 2 : ℚ) = 161 / 400 := by norm_num
example : ((35 / 12) / (1000 * (1 / 10) ^ 2) : ℚ) = 7 / 24 := by norm_num
-- At n = 500 even the middle form of the bound exceeds 1, so it says nothing.
example : (1 : ℚ) < (500 * (707 / 48) + 3 * 500 * 499 * (35 / 12) ^ 2) / (500 ^ 4 * (1 / 10) ^ 4) := by
  norm_num
-- The tail bound C/(N - 1) first drops below 1 at N = 402,502, and is at most 1/100 at
-- N = 40,250,002.
example : ¬ ((402500 : ℚ) / (402501 - 1) < 1) := by norm_num
example : (402500 : ℚ) / (402502 - 1) < 1 := by norm_num
example : (402500 : ℚ) / (40250002 - 1) ≤ 1 / 100 := by norm_num
-- The copied die: every face f has 5|2f - 7| > 1, i.e. is more than 0.1 from 3.5,
-- so P(|average - 3.5| > 0.1) = 1 at every n.
example : ∀ f ∈ Finset.Icc (1 : ℤ) 6, 1 < 5 * |2 * f - 7| := by decide

#print axioms slln_integrable_pow
#print axioms slln_fourth_moment_centered
#print axioms slln_memLp_centered_sum
#print axioms strong_law_of_large_numbers
#print axioms fourth_moment_of_sum
#print axioms fourth_moment_tail_bound
