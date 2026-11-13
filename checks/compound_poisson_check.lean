-- Compound Poisson: a Poisson number of independent, identically distributed claims has total with mean "rate × time × average claim", variance "rate × time × average squared claim", and moment generating function exp(rate × time × (claim MGF − 1)).
import Mathlib.Probability.Distributions.Poisson.Basic
import Mathlib.Probability.HasLaw
import Mathlib.Probability.IdentDistrib
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Basic
import Mathlib.Probability.Moments.Variance

open MeasureTheory ProbabilityTheory Real
open scoped NNReal


variable {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]

lemma cp_hasSum_pow (r : ℝ≥0) (x : ℝ) :
    HasSum (fun n : ℕ => exp (-(r : ℝ)) * (r : ℝ) ^ n / (Nat.factorial n) * x ^ n)
      (exp ((r : ℝ) * (x - 1))) := by
  convert (NormedSpace.expSeries_div_hasSum_exp ((r : ℝ) * x)).mul_left (exp (-(r : ℝ))) using 1
  · funext n; rw [mul_pow]; ring
  · rw [← exp_eq_exp_ℝ, ← exp_add]; ring_nf

lemma cp_hasSum_one (r : ℝ≥0) :
    HasSum (fun n : ℕ => exp (-(r : ℝ)) * (r : ℝ) ^ n / (Nat.factorial n)) 1 := by
  simpa using cp_hasSum_pow r 1

lemma cp_succ (r : ℝ≥0) (n : ℕ) :
    exp (-(r : ℝ)) * (r : ℝ) ^ (n + 1) / (Nat.factorial (n + 1)) * ((n + 1 : ℕ) : ℝ)
      = (r : ℝ) * (exp (-(r : ℝ)) * (r : ℝ) ^ n / (Nat.factorial n)) := by
  rw [Nat.factorial_succ]; push_cast
  have : ((Nat.factorial n) : ℝ) ≠ 0 := by positivity
  field_simp; ring

lemma cp_hasSum_mean (r : ℝ≥0) :
    HasSum (fun n : ℕ => exp (-(r : ℝ)) * (r : ℝ) ^ n / (Nat.factorial n) * (n : ℝ)) (r : ℝ) := by
  rw [← hasSum_nat_add_iff' 1]
  simp only [Finset.range_one, Finset.sum_singleton, Nat.cast_zero]
  convert (cp_hasSum_one r).mul_left (r : ℝ) using 1
  · funext n; exact cp_succ r n
  · ring

lemma cp_hasSum_sq (r : ℝ≥0) :
    HasSum (fun n : ℕ => exp (-(r : ℝ)) * (r : ℝ) ^ n / (Nat.factorial n) * (n : ℝ) ^ 2)
      ((r : ℝ) + (r : ℝ) ^ 2) := by
  rw [← hasSum_nat_add_iff' 1]
  simp only [Finset.range_one, Finset.sum_singleton, Nat.cast_zero]
  convert ((cp_hasSum_mean r).add (cp_hasSum_one r)).mul_left (r : ℝ) using 1
  · funext n
    have h := cp_succ r n
    rw [pow_two, ← mul_assoc, h]; push_cast; ring
  · simp; ring

lemma cp_key (r : ℝ≥0) (N : Ω → ℕ) (Z : Ω → ℕ → ℝ) (hN_meas : Measurable N)
    (hZ : Measurable Z) (hN : HasLaw N (poissonMeasure r) P) (hind : IndepFun N Z P)
    (F : ℕ → (ℕ → ℝ) → ℝ) (hF : ∀ n, Measurable (F n))
    (hFi : ∀ n, Integrable (fun ω => F n (Z ω)) P)
    (hsum : Summable (fun n : ℕ => exp (-(r : ℝ)) * (r : ℝ) ^ n / (Nat.factorial n) *
      ∫ ω, ‖F n (Z ω)‖ ∂P)) :
    Integrable (fun ω => F (N ω) (Z ω)) P ∧
      ∫ ω, F (N ω) (Z ω) ∂P
        = ∑' n : ℕ, exp (-(r : ℝ)) * (r : ℝ) ^ n / (Nat.factorial n) * ∫ ω, F n (Z ω) ∂P := by
  have hNZ : Measurable (fun ω => (N ω, Z ω)) := hN_meas.prodMk hZ
  have hmap : P.map (fun ω => (N ω, Z ω)) = (poissonMeasure r).prod (P.map Z) := by
    rw [(indepFun_iff_map_prod_eq_prod_map_map hN_meas.aemeasurable hZ.aemeasurable).1 hind,
      hN.map_eq]
  have hFm : Measurable (fun p : ℕ × (ℕ → ℝ) => F p.1 p.2) :=
    measurable_from_prod_countable_right (fun n => hF n)
  have hprod : Integrable (fun p : ℕ × (ℕ → ℝ) => F p.1 p.2)
      ((poissonMeasure r).prod (P.map Z)) := by
    refine (integrable_prod_iff hFm.aestronglyMeasurable).2 ⟨ae_of_all _ fun n => ?_, ?_⟩
    · exact (integrable_map_measure (hF n).aestronglyMeasurable hZ.aemeasurable).2 (hFi n)
    · rw [integrable_poissonMeasure_iff]
      refine hsum.congr fun n => ?_
      simp only
      rw [integral_map hZ.aemeasurable (hF n).norm.aestronglyMeasurable,
        Real.norm_of_nonneg (integral_nonneg fun _ => norm_nonneg _)]
  refine ⟨?_, ?_⟩
  · rw [← hmap] at hprod
    exact (integrable_map_measure hFm.aestronglyMeasurable hNZ.aemeasurable).1 hprod
  · calc ∫ ω, F (N ω) (Z ω) ∂P
        = ∫ p, F p.1 p.2 ∂(P.map (fun ω => (N ω, Z ω))) :=
          (integral_map hNZ.aemeasurable hFm.aestronglyMeasurable).symm
      _ = ∫ p, F p.1 p.2 ∂((poissonMeasure r).prod (P.map Z)) := by rw [hmap]
      _ = ∫ n, ∫ y, F n y ∂(P.map Z) ∂(poissonMeasure r) := integral_prod _ hprod
      _ = ∑' n : ℕ, exp (-(r : ℝ)) * (r : ℝ) ^ n / (Nat.factorial n) * ∫ ω, F n (Z ω) ∂P := by
          rw [integral_poissonMeasure]
          congr with n
          rw [smul_eq_mul, integral_map hZ.aemeasurable (hF n).aestronglyMeasurable]

#print axioms cp_hasSum_pow
#print axioms cp_hasSum_one
#print axioms cp_succ
#print axioms cp_hasSum_mean
#print axioms cp_hasSum_sq
#print axioms cp_key

/-- Mean of a compound Poisson total. Let the claim count `N` by time `t` follow the Poisson law
with mean `λ t`, and let the claim sizes `Y 0, Y 1, …` be independent, share one law, and be
independent of the count. If the average claim is finite, then the total
`S = Y 0 + … + Y (N - 1)` (zero when `N = 0`) has a finite mean, equal to `λ t` times the
average claim. -/
theorem compound_poisson_mean (lam t : ℝ≥0) (N : Ω → ℕ) (Y : ℕ → Ω → ℝ)
    (hN_meas : Measurable N) (hY_meas : ∀ i, Measurable (Y i))
    (hN : HasLaw N (poissonMeasure (lam * t)) P)
    (hY_ident : ∀ i, IdentDistrib (Y i) (Y 0) P P)
    (hY_indep : iIndepFun Y P)
    (hNY_indep : IndepFun N (fun ω i => Y i ω) P)
    (hY_int : Integrable (Y 0) P) :
    Integrable (fun ω => ∑ i ∈ Finset.range (N ω), Y i ω) P ∧
      ∫ ω, (∑ i ∈ Finset.range (N ω), Y i ω) ∂P = (lam * t : ℝ) * ∫ ω, Y 0 ω ∂P := by
  have hZ : Measurable (fun ω i => Y i ω) := Measurable.of_eval hY_meas
  have hYi : ∀ i, Integrable (Y i) P := fun i => (hY_ident i).integrable_iff.2 hY_int
  have hnorm : ∀ i, ∫ ω, ‖Y i ω‖ ∂P = ∫ ω, ‖Y 0 ω‖ ∂P := fun i => (hY_ident i).norm.integral_eq
  have hmean : ∀ i, ∫ ω, Y i ω ∂P = ∫ ω, Y 0 ω ∂P := fun i => (hY_ident i).integral_eq
  have hbound : ∀ n : ℕ, ∫ ω, ‖∑ i ∈ Finset.range n, Y i ω‖ ∂P ≤ n * ∫ ω, ‖Y 0 ω‖ ∂P := by
    intro n
    calc ∫ ω, ‖∑ i ∈ Finset.range n, Y i ω‖ ∂P
        ≤ ∫ ω, ∑ i ∈ Finset.range n, ‖Y i ω‖ ∂P :=
          integral_mono (integrable_finsetSum _ fun i _ => hYi i).norm
            (integrable_finsetSum _ fun i _ => (hYi i).norm) fun ω => norm_sum_le _ _
      _ = n * ∫ ω, ‖Y 0 ω‖ ∂P := by
          rw [integral_finsetSum _ fun i _ => (hYi i).norm, Finset.sum_congr rfl fun i _ => hnorm i]
          simp
  obtain ⟨h1, h2⟩ := cp_key (lam * t) N (fun ω i => Y i ω) hN_meas hZ hN hNY_indep
    (fun n y => ∑ i ∈ Finset.range n, y i)
    (fun n => Finset.measurable_sum _ fun i _ => measurable_pi_apply i)
    (fun n => integrable_finsetSum _ fun i _ => hYi i)
    (Summable.of_nonneg_of_le (fun n => mul_nonneg (by positivity)
      (integral_nonneg fun _ => norm_nonneg _))
      (fun n => by
        rw [mul_assoc]
        exact mul_le_mul_of_nonneg_left (hbound n) (by positivity))
      ((cp_hasSum_mean (lam * t)).summable.mul_right (∫ ω, ‖Y 0 ω‖ ∂P)))
  refine ⟨h1, ?_⟩
  rw [h2]
  have : ∀ n : ℕ, ∫ ω, ∑ i ∈ Finset.range n, Y i ω ∂P = n * ∫ ω, Y 0 ω ∂P := by
    intro n; rw [integral_finsetSum _ fun i _ => hYi i]; simp [hmean]
  simp_rw [this, ← mul_assoc]
  rw [tsum_mul_right, (cp_hasSum_mean _).tsum_eq]
  push_cast; ring

/-- Variance of a compound Poisson total. Under the same setting, if the average squared claim
`E[Y²]` is finite, then the total has a finite variance, equal to `λ t` times the average
squared claim (not the claim's variance). -/
theorem compound_poisson_variance (lam t : ℝ≥0) (N : Ω → ℕ) (Y : ℕ → Ω → ℝ)
    (hN_meas : Measurable N) (hY_meas : ∀ i, Measurable (Y i))
    (hN : HasLaw N (poissonMeasure (lam * t)) P)
    (hY_ident : ∀ i, IdentDistrib (Y i) (Y 0) P P)
    (hY_indep : iIndepFun Y P)
    (hNY_indep : IndepFun N (fun ω i => Y i ω) P)
    (hY_sq : MemLp (Y 0) 2 P) :
    MemLp (fun ω => ∑ i ∈ Finset.range (N ω), Y i ω) 2 P ∧
      variance (fun ω => ∑ i ∈ Finset.range (N ω), Y i ω) P
        = (lam * t : ℝ) * ∫ ω, (Y 0 ω) ^ 2 ∂P := by
  have hZ : Measurable (fun ω i => Y i ω) := Measurable.of_eval hY_meas
  have hY2 : ∀ i, MemLp (Y i) 2 P := fun i => (hY_ident i).memLp_iff.2 hY_sq
  have hYi : ∀ i, Integrable (Y i) P := fun i => (hY2 i).integrable one_le_two
  have hmeanS := compound_poisson_mean lam t N Y hN_meas hY_meas hN hY_ident hY_indep hNY_indep
    (hYi 0)
  set m := ∫ ω, Y 0 ω ∂P with hm
  set v := variance (Y 0) P with hv
  have hmean : ∀ i, ∫ ω, Y i ω ∂P = m := fun i => (hY_ident i).integral_eq
  have hvar : ∀ i, variance (Y i) P = v := fun i => (hY_ident i).variance_eq
  have hsq : ∀ n : ℕ, ∫ ω, (∑ i ∈ Finset.range n, Y i ω) ^ 2 ∂P = n * v + (n * m) ^ 2 := by
    intro n
    have hmem : MemLp (∑ i ∈ Finset.range n, Y i) 2 P := memLp_finsetSum' _ fun i _ => hY2 i
    have h := variance_eq_sub hmem
    rw [IndepFun.variance_sum (fun i _ => hY2 i)
      (fun i _ j _ hij => hY_indep.indepFun hij)] at h
    simp only [hvar, Finset.sum_const, Finset.card_range, nsmul_eq_mul] at h
    have e1 : ∫ ω, (∑ i ∈ Finset.range n, Y i) ω ∂P = n * m := by
      simp only [Finset.sum_apply]
      rw [integral_finsetSum _ fun i _ => hYi i]; simp [hmean]
    have e2 : ∫ ω, ((∑ i ∈ Finset.range n, Y i) ^ 2) ω ∂P
        = ∫ ω, (∑ i ∈ Finset.range n, Y i ω) ^ 2 ∂P := by
      simp only [Pi.pow_apply, Finset.sum_apply]
    rw [← e2]
    rw [e1] at h
    linarith
  have hsum := (((cp_hasSum_mean (lam * t)).mul_right v).add
      ((cp_hasSum_sq (lam * t)).mul_right (m ^ 2)))
  obtain ⟨h1, h2⟩ := cp_key (lam * t) N (fun ω i => Y i ω) hN_meas hZ hN hNY_indep
    (fun n y => (∑ i ∈ Finset.range n, y i) ^ 2)
    (fun n => (Finset.measurable_sum _ fun i _ => measurable_pi_apply i).pow_const 2)
    (fun n => (memLp_finsetSum _ fun i _ => hY2 i).integrable_sq)
    (hsum.summable.congr fun n => by
      simp only [Real.norm_of_nonneg (sq_nonneg _)]
      rw [hsq]; ring)
  have hS : MemLp (fun ω => ∑ i ∈ Finset.range (N ω), Y i ω) 2 P :=
    (memLp_two_iff_integrable_sq hmeanS.1.aestronglyMeasurable).2 h1
  refine ⟨hS, ?_⟩
  rw [variance_eq_sub hS]
  have e3 : P[(fun ω => ∑ i ∈ Finset.range (N ω), Y i ω) ^ 2]
      = ∫ ω, (∑ i ∈ Finset.range (N ω), Y i ω) ^ 2 ∂P := rfl
  have hY0 := variance_eq_sub hY_sq
  have e4 : P[Y 0 ^ 2] = ∫ ω, (Y 0 ω) ^ 2 ∂P := rfl
  rw [e3, h2, hmeanS.2]
  simp_rw [hsq]
  have hs : HasSum (fun n : ℕ => exp (-((lam * t : ℝ≥0) : ℝ)) * ((lam * t : ℝ≥0) : ℝ) ^ n / (Nat.factorial n)
      * (n * v + (n * m) ^ 2)) (((lam * t : ℝ≥0) : ℝ) * v
        + (((lam * t : ℝ≥0) : ℝ) + ((lam * t : ℝ≥0) : ℝ) ^ 2) * m ^ 2) := by
    convert hsum using 1
    funext n; ring
  rw [hs.tsum_eq, ← e4]
  rw [← hm, ← hv] at hY0
  rw [show P[Y 0 ^ 2] = v + m ^ 2 by linarith]
  push_cast; ring

/-- Moment generating function of a compound Poisson total. Under the same setting, at any dial
`s` where the claim's generating function `M_Y(s) = E[exp(s Y)]` is finite, the total's
generating function is finite too and equals `exp(λ t (M_Y(s) - 1))`. -/
theorem compound_poisson_mgf (lam t : ℝ≥0) (N : Ω → ℕ) (Y : ℕ → Ω → ℝ)
    (hN_meas : Measurable N) (hY_meas : ∀ i, Measurable (Y i))
    (hN : HasLaw N (poissonMeasure (lam * t)) P)
    (hY_ident : ∀ i, IdentDistrib (Y i) (Y 0) P P)
    (hY_indep : iIndepFun Y P)
    (hNY_indep : IndepFun N (fun ω i => Y i ω) P)
    (s : ℝ) (hY_exp : Integrable (fun ω => exp (s * Y 0 ω)) P) :
    Integrable (fun ω => exp (s * ∑ i ∈ Finset.range (N ω), Y i ω)) P ∧
      mgf (fun ω => ∑ i ∈ Finset.range (N ω), Y i ω) P s
        = exp ((lam * t : ℝ) * (mgf (Y 0) P s - 1)) := by
  have hZ : Measurable (fun ω i => Y i ω) := Measurable.of_eval hY_meas
  set M := mgf (Y 0) P s with hM
  have hexp : ∀ i, Integrable (fun ω => exp (s * Y i ω)) P := fun i =>
    ((hY_ident i).comp (measurable_const_mul s).exp).integrable_iff.2 hY_exp
  have hint : ∀ n : ℕ, Integrable (fun ω => exp (s * ∑ i ∈ Finset.range n, Y i ω)) P := by
    intro n
    have := hY_indep.integrable_exp_mul_sum hY_meas (t := s) (s := Finset.range n)
      (fun i _ => hexp i)
    simpa [Finset.sum_apply] using this
  have hmgf : ∀ n : ℕ, ∫ ω, exp (s * ∑ i ∈ Finset.range n, Y i ω) ∂P = M ^ n := by
    intro n
    have h := hY_indep.mgf_sum hY_meas (Finset.range n) (t := s)
    rw [Finset.prod_eq_pow_card (fun i _ => mgf_congr_of_identDistrib (Y i) (Y 0) (hY_ident i) s),
      Finset.card_range] at h
    rw [← h, mgf]
    simp [Finset.sum_apply]
  obtain ⟨h1, h2⟩ := cp_key (lam * t) N (fun ω i => Y i ω) hN_meas hZ hN hNY_indep
    (fun n y => exp (s * ∑ i ∈ Finset.range n, y i))
    (fun n => ((Finset.measurable_sum _ fun i _ => measurable_pi_apply i).const_mul s).exp)
    hint (by
      simp_rw [Real.norm_of_nonneg (exp_pos _).le, hmgf]
      exact (cp_hasSum_pow _ M).summable)
  refine ⟨h1, ?_⟩
  rw [mgf, h2]
  simp_rw [hmgf]
  rw [(cp_hasSum_pow _ M).tsum_eq]
  push_cast; rfl

/-! The card's worked numbers: claims of $100, $500, $2,000 with chances 1/2, 3/10, 1/5,
at 4 claims an hour. -/

-- average claim: $600
example : (1/2 : ℚ) * 100 + 3/10 * 500 + 1/5 * 2000 = 600 := by norm_num
-- average squared claim: 880,000
example : (1/2 : ℚ) * 100 ^ 2 + 3/10 * 500 ^ 2 + 1/5 * 2000 ^ 2 = 880000 := by norm_num
-- claim variance: 880,000 − 600² = 520,000
example : (880000 : ℤ) - 600 ^ 2 = 520000 := by norm_num
-- average cubed claim: 1,638,000,000
example : (1/2 : ℚ) * 100 ^ 3 + 3/10 * 500 ^ 3 + 1/5 * 2000 ^ 3 = 1638000000 := by norm_num
-- one hour: mean 4 × 600 = 2,400; variance 4 × 880,000 = 3,520,000
example : (4 : ℕ) * 600 = 2400 := by norm_num
example : (4 : ℕ) * 880000 = 3520000 := by norm_num
-- the two sources of variance: claims' own spread plus the count's spread
example : (4 : ℕ) * 520000 + 4 * 600 ^ 2 = 3520000 := by norm_num
-- third cumulant for one hour: 4 × 1,638,000,000 = 6,552,000,000
example : (4 : ℕ) * 1638000000 = 6552000000 := by norm_num
-- one 8-hour shift: mean 32 × 600 = 19,200; variance 32 × 880,000 = 28,160,000
example : (32 : ℕ) * 600 = 19200 := by norm_num
example : (32 : ℕ) * 880000 = 28160000 := by norm_num
-- another road: split by size into Poisson streams at rates 2, 6/5 and 4/5 an hour
example : (100 : ℚ) ^ 2 * 2 + 500 ^ 2 * (6/5) + 2000 ^ 2 * (4/5) = 3520000 := by norm_num
example : (100 : ℚ) ^ 2 * 2 = 20000 ∧ (500 : ℚ) ^ 2 * (6/5) = 300000 ∧
    (2000 : ℚ) ^ 2 * (4/5) = 3200000 := by norm_num
-- random rate (2 or 6 an hour): E[N] Var(Y) + Var(N) μ² = 4 × 520,000 + 8 × 600² = 4,960,000
example : (4 : ℕ) * 520000 + 8 * 600 ^ 2 = 4960000 := by norm_num
-- slot model with m = 10: variance short by λ² μ² / m = 16 × 360,000 / 10 = 576,000
example : (4 : ℕ) ^ 2 * 600 ^ 2 / 10 = 576000 := by norm_num
-- chance of no claims in one hour is e^(-4)
example : (poissonMeasure 4).real {0} = exp (-4) := by
  norm_num [poissonMeasure_real_singleton]


#print axioms compound_poisson_mean
#print axioms compound_poisson_variance
#print axioms compound_poisson_mgf
