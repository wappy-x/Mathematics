-- Birth-and-death processes: a row of shares solves the balance equations of a birth-and-death chain and adds to 1 exactly when the path products have a finite total, and then it is the path product over the total; a linear population dies out for sure unless births are faster; and a pure birth chain reaches infinity in finite time exactly when its mean stays add to a finite total.
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Independence.Integration
import Mathlib.MeasureTheory.Constructions.Polish.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp

open Finset Filter Topology MeasureTheory ProbabilityTheory

/-! States are the counts `0, 1, 2, …`. `lam n` is the birth rate `λ_n` (step up from `n`) and
`mu n` the death rate `μ_n` (step down from `n`), with `μ_0 = 0`.

`bdGenerator lam mu i j` is the card's rate matrix entry `g_{ij}`:
`g_{n,n+1} = λ_n`, `g_{n,n-1} = μ_n`, `g_{nn} = -(λ_n + μ_n)`, every other entry 0.

`pathProduct lam mu n` is the card's `θ_n = λ_0 ⋯ λ_{n-1} / (μ_1 ⋯ μ_n)`, with `θ_0 = 1`.

A row `π` solves `π G = 0` when `∑_i π_i g_{ij} = 0` for every state `j`; each of these sums has
at most three non-zero terms. -/

/-- The birth-and-death rate matrix `G`: up at `λ_n`, down at `μ_n`, minus the total rate of
leaving on the diagonal, and 0 everywhere else. -/
noncomputable def bdGenerator (lam mu : ℕ → ℝ) (i j : ℕ) : ℝ :=
  if j = i + 1 then lam i
  else if j + 1 = i then mu i
  else if j = i then -(lam i + mu i)
  else 0

/-- The path product `θ_n = ∏_{k < n} λ_k / μ_{k+1}`: up-rates over down-rates along the path
from 0 to `n`. -/
noncomputable def pathProduct (lam mu : ℕ → ℝ) (n : ℕ) : ℝ :=
  ∏ k ∈ range n, lam k / mu (k + 1)

lemma bd_tsum_zero (lam mu : ℕ → ℝ) (hmu0 : mu 0 = 0) (π : ℕ → ℝ) :
    ∑' i, π i * bdGenerator lam mu i 0 = π 1 * mu 1 - π 0 * lam 0 := by
  rw [tsum_eq_sum (s := range 2)]
  · simp [sum_range_succ, bdGenerator, hmu0]
    ring
  · intro i hi
    simp only [mem_range, not_lt] at hi
    simp only [bdGenerator]
    split_ifs <;> first | omega | contradiction | simp

lemma bd_tsum_succ (lam mu : ℕ → ℝ) (π : ℕ → ℝ) (j : ℕ) :
    ∑' i, π i * bdGenerator lam mu i (j + 1)
      = (π (j + 2) * mu (j + 2) - π (j + 1) * lam (j + 1))
        - (π (j + 1) * mu (j + 1) - π j * lam j) := by
  rw [tsum_eq_sum (s := range (j + 3))]
  · rw [sum_range_succ, sum_range_succ, sum_range_succ, sum_eq_zero]
    · simp [bdGenerator]
      ring
    · intro i hi
      simp only [mem_range] at hi
      simp only [bdGenerator]
      split_ifs <;> first | omega | simp
  · intro i hi
    simp only [mem_range, not_lt] at hi
    simp only [bdGenerator]
    split_ifs <;> first | omega | simp

lemma bd_balance_iff (lam mu : ℕ → ℝ) (hmu0 : mu 0 = 0) (π : ℕ → ℝ) :
    (∀ j, ∑' i, π i * bdGenerator lam mu i j = 0) ↔
      ∀ n, π (n + 1) * mu (n + 1) = π n * lam n := by
  constructor
  · intro h n
    induction n with
    | zero => have := h 0; rw [bd_tsum_zero lam mu hmu0] at this; linarith
    | succ n ih => have := h (n + 1); rw [bd_tsum_succ] at this; linarith
  · intro h j
    cases j with
    | zero => rw [bd_tsum_zero lam mu hmu0]; linarith [h 0]
    | succ j => rw [bd_tsum_succ]; linarith [h j, h (j + 1)]

lemma bd_pathProduct_succ (lam mu : ℕ → ℝ) (n : ℕ) :
    pathProduct lam mu (n + 1) = pathProduct lam mu n * (lam n / mu (n + 1)) := by
  rw [pathProduct, pathProduct, prod_range_succ]

lemma bd_pathProduct_pos (lam mu : ℕ → ℝ) (hlam : ∀ n, 0 < lam n) (hmu : ∀ n, 0 < mu (n + 1))
    (n : ℕ) : 0 < pathProduct lam mu n :=
  prod_pos (fun k _ => div_pos (hlam k) (hmu k))

lemma bd_balance_iff_multiple (lam mu : ℕ → ℝ) (hmu : ∀ n, 0 < mu (n + 1)) (π : ℕ → ℝ) :
    (∀ n, π (n + 1) * mu (n + 1) = π n * lam n) ↔
      ∀ n, π n = π 0 * pathProduct lam mu n := by
  constructor
  · intro h n
    induction n with
    | zero => simp [pathProduct]
    | succ n ih =>
      have hm := (hmu n).ne'
      rw [bd_pathProduct_succ, ← mul_assoc, ← ih]
      field_simp
      linarith [h n]
  · intro h n
    have hm := (hmu n).ne'
    rw [h (n + 1), h n, bd_pathProduct_succ]
    field_simp

lemma bd_lintegral_expMeasure {r : ℝ} (f : ℝ → ENNReal) (hf : Measurable f) :
    ∫⁻ x, f x ∂ expMeasure r
      = ∫⁻ x in Set.Ioi 0, ENNReal.ofReal (r * Real.exp (-(r * x))) * f x := by
  rw [expMeasure, gammaMeasure,
    lintegral_withDensity_eq_lintegral_mul _
      (show Measurable (gammaPDF 1 r) from (measurable_gammaPDFReal 1 r).ennreal_ofReal) hf,
    ← lintegral_add_compl _ (measurableSet_Ici (a := (0:ℝ))), Set.compl_Ici,
    setLIntegral_congr_fun measurableSet_Iio
      (fun x (hx : x < 0) => by rw [Pi.mul_apply, gammaPDF_of_neg hx, zero_mul]),
    lintegral_zero, add_zero, setLIntegral_congr Ioi_ae_eq_Ici.symm]
  refine setLIntegral_congr_fun measurableSet_Ioi (fun x (hx : 0 < x) => ?_)
  rw [Pi.mul_apply, gammaPDF_of_nonneg hx.le]
  simp

lemma bd_expMeasure_Iio {r : ℝ} : expMeasure r (Set.Iio 0) = 0 := by
  rw [expMeasure, gammaMeasure, withDensity_apply _ measurableSet_Iio]
  exact lintegral_gammaPDF_of_nonpos le_rfl

lemma bd_lintegral_expMeasure_id {r : ℝ} (hr : 0 < r) :
    ∫⁻ x, ENNReal.ofReal x ∂ expMeasure r = ENNReal.ofReal (1 / r) := by
  rw [bd_lintegral_expMeasure _ ENNReal.measurable_ofReal]
  have hG2 : Real.Gamma 2 = 1 := by
    rw [show (2:ℝ) = 1 + 1 by norm_num, Real.Gamma_add_one one_ne_zero, Real.Gamma_one, one_mul]
  have hint : ∫ x in Set.Ioi 0, x ^ ((2:ℝ) - 1) * Real.exp (-(r * x))
      = (1 / r) ^ (2:ℝ) * Real.Gamma 2 := Real.integral_rpow_mul_exp_neg_mul_Ioi two_pos hr
  rw [setLIntegral_congr_fun measurableSet_Ioi
    (g := fun x => ENNReal.ofReal (r * (x ^ ((2:ℝ) - 1) * Real.exp (-(r * x)))))
    (fun x (hx : 0 < x) => by
      rw [← ENNReal.ofReal_mul (by positivity)]
      congr 1
      norm_num
      ring)]
  rw [← ofReal_integral_eq_lintegral_ofReal, integral_const_mul, hint, hG2,
    Real.rpow_two]
  · congr 1
    field_simp
  · refine Integrable.const_mul (Integrable.of_integral_ne_zero ?_) r
    rw [hint]; positivity
  · refine (ae_restrict_iff' measurableSet_Ioi).2 (ae_of_all _ (fun x (hx : 0 < x) => ?_))
    positivity

lemma bd_lintegral_expMeasure_exp {r : ℝ} (hr : 0 < r) :
    ∫⁻ x, ENNReal.ofReal (Real.exp (-x)) ∂ expMeasure r = ENNReal.ofReal (r / (r + 1)) := by
  rw [bd_lintegral_expMeasure _ (by fun_prop)]
  have hint : ∫ x in Set.Ioi 0, x ^ ((1:ℝ) - 1) * Real.exp (-((r + 1) * x))
      = (1 / (r + 1)) ^ (1:ℝ) * Real.Gamma 1 :=
    Real.integral_rpow_mul_exp_neg_mul_Ioi one_pos (by positivity)
  rw [setLIntegral_congr_fun measurableSet_Ioi
    (g := fun x => ENNReal.ofReal (r * (x ^ ((1:ℝ) - 1) * Real.exp (-((r + 1) * x)))))
    (fun x (hx : 0 < x) => by
      rw [← ENNReal.ofReal_mul (by positivity)]
      congr 1
      rw [sub_self, Real.rpow_zero, one_mul, mul_assoc, ← Real.exp_add]
      ring_nf)]
  rw [← ofReal_integral_eq_lintegral_ofReal, integral_const_mul, hint, Real.Gamma_one,
    Real.rpow_one]
  · congr 1
    field_simp
  · refine Integrable.const_mul (Integrable.of_integral_ne_zero ?_) r
    rw [hint]; positivity
  · refine (ae_restrict_iff' measurableSet_Ioi).2 (ae_of_all _ (fun x (hx : 0 < x) => ?_))
    positivity

lemma bd_prod_le (lam : ℕ → ℝ) (hlam : ∀ n, 0 < lam n) (N : ℕ) :
    ∏ n ∈ range N, lam n / (lam n + 1) ≤ 1 / (1 + ∑ n ∈ range N, 1 / lam n) := by
  induction N with
  | zero => simp
  | succ N ih =>
    rw [prod_range_succ, sum_range_succ]
    have hl := hlam N
    have hs : 0 ≤ ∑ n ∈ range N, 1 / lam n := sum_nonneg fun n _ => (one_div_pos.2 (hlam n)).le
    calc (∏ n ∈ range N, lam n / (lam n + 1)) * (lam N / (lam N + 1))
        ≤ 1 / (1 + ∑ n ∈ range N, 1 / lam n) * (lam N / (lam N + 1)) :=
          mul_le_mul_of_nonneg_right ih (by positivity)
      _ ≤ 1 / (1 + (∑ n ∈ range N, 1 / lam n + 1 / lam N)) := by
          rw [div_mul_div_comm, one_mul, div_le_div_iff₀ (by positivity) (by positivity)]
          field_simp
          nlinarith

#print axioms bd_tsum_zero
#print axioms bd_tsum_succ
#print axioms bd_balance_iff
#print axioms bd_pathProduct_succ
#print axioms bd_pathProduct_pos
#print axioms bd_balance_iff_multiple
#print axioms bd_lintegral_expMeasure
#print axioms bd_expMeasure_Iio
#print axioms bd_lintegral_expMeasure_id
#print axioms bd_lintegral_expMeasure_exp
#print axioms bd_prod_le

/-- The long-run law of a birth-and-death chain. Take a chain whose states all reach each other:
every birth rate `λ_n > 0`, every death rate `μ_n > 0` for `n ≥ 1`, and `μ_0 = 0`. A row `π` of
non-negative shares adding to 1 solves the balance equations `π G = 0` exactly when the path
products `θ_n` have a finite total `S = ∑ θ_n`, and then `π_n = θ_n / S` for every `n`.
So a long-run law exists exactly when `S < ∞`, and it is the path product over the total. -/
theorem stationary_law_iff_finite_total (lam mu : ℕ → ℝ)
    (hlam : ∀ n, 0 < lam n) (hmu0 : mu 0 = 0) (hmu : ∀ n, 0 < mu (n + 1)) (π : ℕ → ℝ) :
    ((∀ n, 0 ≤ π n) ∧ HasSum π 1 ∧ ∀ j, ∑' i, π i * bdGenerator lam mu i j = 0) ↔
      (Summable (pathProduct lam mu) ∧
        ∀ n, π n = pathProduct lam mu n / ∑' k, pathProduct lam mu k) := by
  rw [bd_balance_iff lam mu hmu0, bd_balance_iff_multiple lam mu hmu]
  constructor
  · rintro ⟨-, hsum, hmul⟩
    have h0 : π 0 ≠ 0 := by
      intro h0
      have : π = 0 := funext fun n => by rw [hmul n, h0, zero_mul]; rfl
      rw [this] at hsum
      exact one_ne_zero (hasSum_zero.unique hsum).symm
    have hθ : pathProduct lam mu = fun n => (π 0)⁻¹ * π n := funext fun n => by
      rw [hmul n]; field_simp
    have hS : HasSum (pathProduct lam mu) (π 0)⁻¹ := by
      rw [hθ]; simpa using hsum.mul_left (π 0)⁻¹
    refine ⟨hS.summable, fun n => ?_⟩
    rw [hS.tsum_eq, hmul n]
    field_simp
  · rintro ⟨hs, hπ⟩
    set S := ∑' k, pathProduct lam mu k with hSdef
    have hpos := bd_pathProduct_pos lam mu hlam hmu
    have hS : 0 < S := hs.tsum_pos (fun n => (hpos n).le) 0 (hpos 0)
    refine ⟨fun n => by rw [hπ n]; exact div_nonneg (hpos n).le hS.le, ?_, fun n => ?_⟩
    · have := hs.hasSum.div_const S
      rw [div_self hS.ne'] at this
      convert this using 1
      exact funext hπ
    · rw [hπ n, hπ 0]
      simp [pathProduct]
      ring

/-- Extinction of a linear population is gambler's ruin. Each member gives birth at rate `b > 0`
and dies at rate `d > 0`. Between events the count is a walk with ratio `d/b`, and the chance of
hitting 0 before a height `L`, from `i` members, is `((d/b)^i - (d/b)^L) / (1 - (d/b)^L)`, or
`1 - i/L` when `b = d`. As `L` grows this tends to `(d/b)^i` if `b > d` and to 1 if `b ≤ d`:
dying out is certain unless births are faster. -/
theorem linear_population_extinction_chance (b d : ℝ) (hb : 0 < b) (hd : 0 < d) (i : ℕ) :
    Tendsto
      (fun L : ℕ => if b = d then 1 - (i : ℝ) / L
        else ((d / b) ^ i - (d / b) ^ L) / (1 - (d / b) ^ L))
      atTop (𝓝 (if d < b then (d / b) ^ i else 1)) := by
  by_cases hbd : b = d
  · subst hbd
    simp only [ite_true, lt_irrefl, ite_false]
    simpa using (tendsto_const_div_atTop_nhds_zero_nat (i : ℝ)).const_sub 1
  · simp only [hbd, ite_false]
    rcases lt_or_gt_of_ne hbd with hlt | hgt
    · -- b < d: ratio above 1
      have hnot : ¬ d < b := not_lt.2 hlt.le
      simp only [hnot, ite_false]
      have hs0 : 0 ≤ b / d := by positivity
      have hs1 : b / d < 1 := (div_lt_one hd).2 hlt
      have hkey : ∀ L : ℕ, (d / b) ^ L * (b / d) ^ L = 1 := fun L => by
        rw [← mul_pow, div_mul_div_comm, mul_comm d b, div_self (by positivity), one_pow]
      have heq : ∀ L : ℕ, ((d / b) ^ i - (d / b) ^ L) / (1 - (d / b) ^ L)
          = ((d / b) ^ i * (b / d) ^ L - 1) / ((b / d) ^ L - 1) := fun L => by
        rw [← mul_div_mul_right _ _ (pow_ne_zero L (by positivity : b / d ≠ 0)), sub_mul,
          sub_mul, one_mul, hkey]
      simp_rw [heq]
      have ht := tendsto_pow_atTop_nhds_zero_of_lt_one hs0 hs1
      have := ((ht.const_mul ((d / b) ^ i)).sub_const 1).div (ht.sub_const 1) (by norm_num)
      simpa [Pi.div_def] using this
    · -- d < b: ratio below 1
      simp only [hgt, ite_true]
      have ht := tendsto_pow_atTop_nhds_zero_of_lt_one (by positivity : 0 ≤ d / b)
        ((div_lt_one hb).2 hgt)
      have := (ht.const_sub ((d / b) ^ i)).div (ht.const_sub 1) (by norm_num)
      simpa [Pi.div_def] using this

/-- Explosion of a pure birth chain. The chain stays at its `n`-th state for an exponential time
`H n` with rate `λ_n > 0`, the stays independent, and `T = H 0 + H 1 + ⋯` is the time to pass
every count. If `∑ 1/λ_n` is finite, then `T` is finite with chance 1 (the chain explodes);
if `∑ 1/λ_n` is endless, then `T` is endless with chance 1. -/
theorem pure_birth_explodes_iff_finite_mean_stays
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (lam : ℕ → ℝ) (hlam : ∀ n, 0 < lam n) (H : ℕ → Ω → ℝ)
    (hmeas : ∀ n, Measurable (H n)) (hind : iIndepFun H P)
    (hlaw : ∀ n, P.map (H n) = expMeasure (lam n)) :
    (Summable (fun n => 1 / lam n) → ∀ᵐ ω ∂P, Summable (fun n => H n ω)) ∧
      (¬ Summable (fun n => 1 / lam n) → ∀ᵐ ω ∂P, ¬ Summable (fun n => H n ω)) := by
  have hnn : ∀ᵐ ω ∂P, ∀ n, 0 ≤ H n ω := by
    refine ae_all_iff.2 fun n => ?_
    rw [ae_iff]
    have h := (Measure.map_apply (hmeas n) measurableSet_Iio).symm.trans
      (by rw [hlaw n]; exact bd_expMeasure_Iio : P.map (H n) (Set.Iio 0) = 0)
    simp only [not_le]
    exact h
  have hinv : ∀ n, 0 ≤ 1 / lam n := fun n => (one_div_pos.2 (hlam n)).le
  constructor
  · intro hs
    have hmean : ∀ n, ∫⁻ ω, ENNReal.ofReal (H n ω) ∂P = ENNReal.ofReal (1 / lam n) := fun n => by
      rw [← lintegral_map ENNReal.measurable_ofReal (hmeas n), hlaw n,
        bd_lintegral_expMeasure_id (hlam n)]
    have hfin : ∫⁻ ω, ∑' n, ENNReal.ofReal (H n ω) ∂P ≠ ⊤ := by
      rw [lintegral_tsum (fun n => (hmeas n).ennreal_ofReal.aemeasurable)]
      simp_rw [hmean]
      rw [← ENNReal.ofReal_tsum_of_nonneg hinv hs]
      exact ENNReal.ofReal_ne_top
    filter_upwards [hnn, ae_lt_top (Measurable.tsum fun n => (hmeas n).ennreal_ofReal) hfin]
      with ω h1 h2
    exact (ENNReal.summable_toReal h2.ne).congr fun n => ENNReal.toReal_ofReal (h1 n)
  · intro hns
    set Y : ℕ → Ω → ENNReal := fun N ω => ∏ n ∈ range N, ENNReal.ofReal (Real.exp (-H n ω))
      with hYdef
    have hindY : iIndepFun (fun n ω => ENNReal.ofReal (Real.exp (-H n ω))) P :=
      hind.comp (fun _ x => ENNReal.ofReal (Real.exp (-x))) (fun _ => by fun_prop)
    have hYint : ∀ N, ∫⁻ ω, Y N ω ∂P
        = ENNReal.ofReal (∏ n ∈ range N, lam n / (lam n + 1)) := fun N => by
      rw [hYdef, lintegral_prod_eq_prod_lintegral_of_indepFun _ _ hindY
        (fun n => by fun_prop), ENNReal.ofReal_prod_of_nonneg
          (fun n _ => (div_pos (hlam n) (by linarith [hlam n])).le)]
      refine prod_congr rfl fun n _ => ?_
      rw [← lintegral_map (f := fun x => ENNReal.ofReal (Real.exp (-x))) (by fun_prop) (hmeas n),
        hlaw n, bd_lintegral_expMeasure_exp (hlam n)]
    have hlim : Tendsto (fun N => ENNReal.ofReal (1 / (1 + ∑ n ∈ range N, 1 / lam n)))
        atTop (𝓝 0) := by
      have h1 := (not_summable_iff_tendsto_nat_atTop_of_nonneg hinv).1 hns
      have h2 := (tendsto_atTop_add_const_left atTop 1 h1).inv_tendsto_atTop
      rw [← ENNReal.ofReal_zero]
      exact ENNReal.tendsto_ofReal (h2.congr fun N => by rw [Pi.inv_apply, one_div])
    have hZmeas : Measurable (fun ω => ⨅ N, Y N ω) :=
      Measurable.iInf fun N => Finset.measurable_prod _ fun n _ => by fun_prop
    have hZ : ∫⁻ ω, ⨅ N, Y N ω ∂P = 0 := by
      refine le_antisymm (ge_of_tendsto' hlim fun N => ?_) bot_le
      calc ∫⁻ ω, ⨅ N, Y N ω ∂P ≤ ∫⁻ ω, Y N ω ∂P := lintegral_mono fun ω => iInf_le _ N
        _ = _ := hYint N
        _ ≤ _ := ENNReal.ofReal_le_ofReal (bd_prod_le lam hlam N)
    filter_upwards [hnn, (lintegral_eq_zero_iff hZmeas).1 hZ] with ω h1 h2 hsum
    have hle : ENNReal.ofReal (Real.exp (-∑' n, H n ω)) ≤ ⨅ N, Y N ω := le_iInf fun N => by
      rw [hYdef]
      simp only
      rw [← ENNReal.ofReal_prod_of_nonneg (fun n _ => (Real.exp_pos _).le), ← Real.exp_sum,
        sum_neg_distrib]
      exact ENNReal.ofReal_le_ofReal (Real.exp_le_exp.2 (neg_le_neg
        (hsum.sum_le_tsum _ (fun i _ => h1 i))))
    have hpos : 0 < ENNReal.ofReal (Real.exp (-∑' n, H n ω)) := ENNReal.ofReal_pos.2 (Real.exp_pos _)
    have h2' : (⨅ N, Y N ω) = 0 := h2
    rw [h2'] at hle
    exact absurd (lt_of_lt_of_le hpos hle) (lt_irrefl 0)

/-! The switchboard: 3 lines, calls at `λ = 4` an hour, each line freed at `μ = 2` an hour,
so `λ_n = 4` and `μ_n = 2n`, offered load `a = 2`. -/

-- The path products are 1, 2, 2, 4/3.
example : pathProduct (fun _ => 4) (fun n => 2 * n) 0 = 1 := by
  norm_num [pathProduct]
example : pathProduct (fun _ => 4) (fun n => 2 * n) 1 = 2 := by
  norm_num [pathProduct]
example : pathProduct (fun _ => 4) (fun n => 2 * n) 2 = 2 := by
  norm_num [pathProduct, prod_range_succ]
example : pathProduct (fun _ => 4) (fun n => 2 * n) 3 = 4 / 3 := by
  norm_num [pathProduct, prod_range_succ]

-- Their total is 19/3, and the long-run shares are 3/19, 6/19, 6/19, 4/19.
example : (1 : ℚ) + 2 + 2 + 4 / 3 = 19 / 3 := by norm_num
example : ((1 : ℚ) / (19 / 3), (2 : ℚ) / (19 / 3), (2 : ℚ) / (19 / 3), (4 / 3 : ℚ) / (19 / 3))
    = (3 / 19, 6 / 19, 6 / 19, 4 / 19) := by norm_num

-- Erlang's loss formula: B(3) = (a^3/3!) / (1 + a + a^2/2! + a^3/3!) = 4/19 with a = 2.
example : ((2 : ℚ) ^ 3 / 6) / (1 + 2 + 2 ^ 2 / 2 + 2 ^ 3 / 6) = 4 / 19 := by norm_num

-- Erlang's recursion B(c) = a B(c-1) / (c + a B(c-1)) from B(0) = 1: 2/3, 2/5, 4/19.
example : (2 * 1 : ℚ) / (1 + 2 * 1) = 2 / 3 := by norm_num
example : (2 * (2 / 3) : ℚ) / (2 + 2 * (2 / 3)) = 2 / 5 := by norm_num
example : (2 * (2 / 5) : ℚ) / (3 + 2 * (2 / 5)) = 4 / 19 := by norm_num

-- Lost calls 4 × 4/19 = 16/19 an hour; mean lines busy (6 + 12 + 12)/19 = 30/19 = a (1 - B).
example : (4 : ℚ) * (4 / 19) = 16 / 19 := by norm_num
example : ((0 : ℚ) * 3 + 1 * 6 + 2 * 6 + 3 * 4) / 19 = 30 / 19 := by norm_num
example : (2 : ℚ) * (1 - 4 / 19) = 30 / 19 := by norm_num

-- M/M/3 with a waiting room, r = 4/6 = 2/3: total S = 5 + (4/3)/(1 - r) = 9,
-- chance to wait (4/3)/(1 - r)/9 = 4/9, mean on hold (4/3)/9 × r/(1 - r)^2 = 8/9,
-- mean wait (8/9 + 4/9)/6 hours = 40/3 minutes; those who wait wait 30 minutes on average.
example : (5 : ℚ) + (4 / 3) / (1 - 2 / 3) = 9 := by norm_num
example : (4 / 3 : ℚ) / (1 - 2 / 3) / 9 = 4 / 9 := by norm_num
example : (4 / 3 : ℚ) / 9 * (2 / 3) / (1 - 2 / 3) ^ 2 = 8 / 9 := by norm_num
example : ((8 / 9 : ℚ) + 4 / 9) / 6 * 60 = 40 / 3 := by norm_num
example : ((8 / 9 : ℚ) + 4 / 9) / 6 / (4 / 9) * 60 = 30 := by norm_num

-- The usual mistake: one death rate of 2 in every state gives path products 1, 2, 4, 8
-- and a loss chance of 8/15.
example : pathProduct (fun _ => 4) (fun _ => 2) 3 = 8 := by
  norm_num [pathProduct, prod_range_succ]
example : (8 : ℚ) / (1 + 2 + 4 + 8) = 8 / 15 := by norm_num

-- The outbreak: b = 3/10, d = 1/5 a day. One case dies out with chance d/b = 2/3,
-- which solves the branching equation x = d/(b+d) + b/(b+d) x^2; three cases with chance 8/27.
example : ((1 / 5 : ℚ) / (3 / 10)) = 2 / 3 := by norm_num
example : (2 / 3 : ℚ) = (1 / 5) / (3 / 10 + 1 / 5) + (3 / 10) / (3 / 10 + 1 / 5) * (2 / 3) ^ 2 := by
  norm_num
example : ((2 : ℚ) / 3) ^ 3 = 8 / 27 := by norm_num

#print axioms stationary_law_iff_finite_total
#print axioms linear_population_extinction_chance
#print axioms pure_birth_explodes_iff_finite_mean_stays
