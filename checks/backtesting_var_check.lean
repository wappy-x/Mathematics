-- Backtesting VaR: if each day is an independent exception with the same chance p, the count of exceptions in n days is binomial, the observed rate K/n is the rate that best explains the record (so Kupiec's statistic is never negative), and a run of k exceptions in n days can sit in exactly n - k + 1 places.
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Fintype.Fin
import Mathlib.Data.Finset.Powerset
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Measure.Real

open MeasureTheory ProbabilityTheory

/-- A correct model's exception count is binomial. Over `n` days, day `t` is an exception when
the loss `L t` is strictly bigger than the morning's VaR `V t`. If the exception events of the
days are independent and each has the same chance `p`, then the chance of exactly `k` exceptions,
`K = I_1 + … + I_n = k`, is `C(n, k) p^k (1 - p)^(n - k)`. -/
theorem exception_count_binomial {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (n : ℕ) (L V : Fin n → Ω → ℝ)
    (hL : ∀ t, Measurable (L t)) (hV : ∀ t, Measurable (V t))
    (hindep : iIndepSet (fun t => {ω | V t ω < L t ω}) P)
    (p : ℝ) (hp : ∀ t, P.real {ω | V t ω < L t ω} = p) (k : ℕ) :
    P.real {ω | (∑ t, if V t ω < L t ω then 1 else 0 : ℕ) = k}
      = (n.choose k : ℝ) * p ^ k * (1 - p) ^ (n - k) := by
  classical
  set A : Fin n → Set Ω := fun t => {ω | V t ω < L t ω} with hA
  have hmeas : ∀ t, MeasurableSet (A t) := fun t => measurableSet_lt (hV t) (hL t)
  have hind := (iIndepSet_iff_iIndep _ _).1 hindep
  let B : Finset (Fin n) → Set Ω := fun s => ⋂ t, (if t ∈ s then A t else (A t)ᶜ)
  have hBmeas : ∀ s, MeasurableSet (B s) := fun s => MeasurableSet.iInter fun t => by
    by_cases h : t ∈ s
    · simp only [h, ite_true]; exact hmeas t
    · simp only [h, ite_false]; exact (hmeas t).compl
  have hBmem : ∀ s ω, ω ∈ B s ↔ s = Finset.univ.filter (fun t => V t ω < L t ω) := by
    intro s ω
    simp only [B, Set.mem_iInter]
    constructor
    · intro h
      ext t
      have ht := h t
      by_cases hts : t ∈ s
      · simp only [hts, ite_true] at ht
        simp only [hts, true_iff, Finset.mem_filter, Finset.mem_univ, true_and]
        exact ht
      · simp only [hts, ite_false] at ht
        simp only [hts, false_iff, Finset.mem_filter, Finset.mem_univ, true_and]
        exact ht
    · rintro rfl t
      by_cases ht : V t ω < L t ω
      · simp only [Finset.mem_filter, Finset.mem_univ, true_and, ht, ite_true]
        exact ht
      · simp only [Finset.mem_filter, Finset.mem_univ, true_and, ht, ite_false]
        exact ht
  have hBprob : ∀ s : Finset (Fin n), P.real (B s) = p ^ s.card * (1 - p) ^ (n - s.card) := by
    intro s
    have h1 : P (B s) = ∏ t, P (if t ∈ s then A t else (A t)ᶜ) := by
      apply hind.meas_iInter
      intro t
      by_cases h : t ∈ s
      · simp only [h, ite_true]; exact MeasurableSpace.measurableSet_generateFrom (Set.mem_singleton _)
      · simp only [h, ite_false]; exact (MeasurableSpace.measurableSet_generateFrom (Set.mem_singleton _)).compl
    have h2 : P.real (B s) = ∏ t, P.real (if t ∈ s then A t else (A t)ᶜ) := by
      simp only [measureReal_def, h1, ENNReal.toReal_prod]
    rw [h2]
    have h3 : ∀ t, P.real (if t ∈ s then A t else (A t)ᶜ) = if t ∈ s then p else 1 - p := by
      intro t
      by_cases h : t ∈ s
      · simp only [h, ite_true]; exact hp t
      · simp only [h, ite_false]
        rw [measureReal_compl (hmeas t), probReal_univ, hp t]
    simp_rw [h3]
    rw [Finset.prod_ite, Finset.prod_const, Finset.prod_const, Finset.filter_mem_eq_inter,
      Finset.univ_inter]
    congr 2
    rw [Finset.filter_not, Finset.filter_mem_eq_inter, Finset.univ_inter, Finset.card_sdiff,
      Finset.card_univ, Fintype.card_fin]
    simp
  have hset : {ω | (∑ t, if V t ω < L t ω then 1 else 0 : ℕ) = k}
      = ⋃ s ∈ (Finset.univ : Finset (Fin n)).powersetCard k, B s := by
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_powersetCard, exists_prop, hBmem]
    rw [← Finset.card_filter]
    constructor
    · intro h
      exact ⟨_, ⟨Finset.subset_univ _, h⟩, rfl⟩
    · rintro ⟨s, ⟨_, hs⟩, rfl⟩
      exact hs
  rw [hset, measureReal_biUnion_finset]
  · rw [Finset.sum_congr rfl (fun s hs => by
      rw [hBprob s, (Finset.mem_powersetCard.1 hs).2])]
    rw [Finset.sum_const, Finset.card_powersetCard, Finset.card_univ, Fintype.card_fin,
      nsmul_eq_mul]
    ring
  · intro s _ s' _ hss'
    rw [Function.onFun, Set.disjoint_left]
    intro ω h1 h2
    exact hss' (((hBmem s ω).1 h1).trans ((hBmem s' ω).1 h2).symm)
  · intro s _
    exact hBmeas s

/-- Kupiec's test: the best rate is the observed rate. For a record of `K` exceptions in `n` days,
the log-chance `K ln q + (n - K) ln(1 - q)` of the record under any trial rate `q` strictly between
0 and 1 is at most its value at the observed rate `p̂ = K / n` (with `0 ln 0 = 0`). Taking `q = p`
shows that Kupiec's statistic `LR_uc` is never negative. -/
theorem kupiec_best_rate_is_observed_rate (n K : ℕ) (hK : K ≤ n) (q : ℝ)
    (hq0 : 0 < q) (hq1 : q < 1) :
    (K : ℝ) * Real.log q + ((n : ℝ) - K) * Real.log (1 - q)
      ≤ (K : ℝ) * Real.log ((K : ℝ) / n) + ((n : ℝ) - K) * Real.log (1 - (K : ℝ) / n) := by
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn
    have : K = 0 := by omega
    subst this
    simp
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  have key : ∀ a x : ℝ, 0 ≤ a → 0 < x →
      a * Real.log x ≤ a * Real.log (a / n) + (x * n - a) := by
    intro a x ha hx
    rcases ha.eq_or_lt with h | h
    · subst h; simp; positivity
    · have h1 : Real.log x - Real.log (a / n) = Real.log (x * n / a) := by
        rw [← Real.log_div hx.ne' (by positivity)]
        congr 1
        field_simp
      have h2 := Real.log_le_sub_one_of_pos (show 0 < x * n / a by positivity)
      have h3 : a * (Real.log x - Real.log (a / n)) ≤ a * (x * n / a - 1) :=
        mul_le_mul_of_nonneg_left (h1 ▸ h2) h.le
      have h4 : a * (x * n / a - 1) = x * n - a := by field_simp
      nlinarith
  have hKR : (K : ℝ) ≤ n := by exact_mod_cast hK
  have e1 := key K q (by positivity) hq0
  have e2 := key ((n : ℝ) - K) (1 - q) (by linarith) (by linarith)
  have h1 : 1 - (K : ℝ) / n = ((n : ℝ) - K) / n := by field_simp
  rw [h1]
  nlinarith

/-- A run of `k` exceptions in a row can start on any of `n - k + 1` days. Among the sets of `k`
days out of `n` (`1 ≤ k ≤ n`), exactly `n - k + 1` are runs of consecutive days; for four days out
of 250 that is 247 of the `C(250, 4)` equally likely choices. -/
theorem run_count_eq (n k : ℕ) (hk1 : 1 ≤ k) (hkn : k ≤ n) :
    ((Finset.univ : Finset (Fin n)).powersetCard k |>.filter
        (fun s => ∃ a : Fin n, ∀ i : Fin n, i ∈ s ↔ (a ≤ i ∧ i.val < a.val + k))).card
      = n - k + 1 := by
  classical
  set I : ℕ → Finset (Fin n) :=
    fun a => Finset.univ.filter (fun i : Fin n => a ≤ i.val ∧ i.val < a + k) with hI
  have hcard : ∀ a, a + k ≤ n → (I a).card = k := by
    intro a ha
    have hIcc : I a = Finset.Icc (⟨a, by omega⟩ : Fin n) ⟨a + k - 1, by omega⟩ := by
      ext i
      simp only [hI, Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_Icc,
        Fin.le_iff_val_le_val]
      omega
    rw [hIcc, Fin.card_Icc]
    simp
    omega
  have heq : ((Finset.univ : Finset (Fin n)).powersetCard k |>.filter
        (fun s => ∃ a : Fin n, ∀ i : Fin n, i ∈ s ↔ (a ≤ i ∧ i.val < a.val + k)))
      = (Finset.range (n - k + 1)).image I := by
    ext s
    simp only [Finset.mem_filter, Finset.mem_powersetCard, Finset.mem_image, Finset.mem_range]
    constructor
    · rintro ⟨⟨_, hs⟩, a, ha⟩
      have hsI : s = I a.val := by
        ext i
        rw [ha i]
        simp only [hI, Finset.mem_filter, Finset.mem_univ, true_and, Fin.le_iff_val_le_val]
      refine ⟨a.val, ?_, hsI.symm⟩
      by_contra hlt
      have hsub : s ⊆ Finset.Ici a := by
        intro i hi
        rw [Finset.mem_Ici]
        exact ((ha i).1 hi).1
      have := Finset.card_le_card hsub
      rw [Fin.card_Ici] at this
      omega
    · rintro ⟨a, ha, rfl⟩
      refine ⟨⟨Finset.subset_univ _, hcard a (by omega)⟩, ⟨a, by omega⟩, ?_⟩
      intro i
      simp only [hI, Finset.mem_filter, Finset.mem_univ, true_and, Fin.le_iff_val_le_val]
  rw [heq, Finset.card_image_of_injOn, Finset.card_range]
  intro a ha b hb hab
  simp only [Finset.coe_range, Set.mem_Iio] at ha hb
  have ha' : (⟨a, by omega⟩ : Fin n) ∈ I a := by
    simp [hI]; omega
  have hb' : (⟨b, by omega⟩ : Fin n) ∈ I b := by
    simp [hI]; omega
  rw [hab] at ha'
  rw [← hab] at hb'
  simp [hI] at ha' hb'
  omega

-- The desk's two records (days 1 to 250): exceptions on days 40, 90, 140, 200, or on 40 to 43.
-- Both have K = 4 exceptions.
example : ((Finset.univ : Finset (Fin 250)).filter
    (fun t => t.val + 1 ∈ ({40, 90, 140, 200} : Finset ℕ))).card = 4 := by decide +kernel
example : ((Finset.univ : Finset (Fin 250)).filter
    (fun t => t.val + 1 ∈ ({40, 41, 42, 43} : Finset ℕ))).card = 4 := by decide +kernel

-- Pair counts n00, n01, n10, n11 over the 249 neighbouring pairs: 241, 4, 4, 0 spread out.
example :
    let E : Finset ℕ := {40, 90, 140, 200}
    let c := fun (a b : Bool) => ((Finset.univ : Finset (Fin 249)).filter
      (fun t => decide (t.val + 1 ∈ E) = a ∧ decide (t.val + 2 ∈ E) = b)).card
    (c false false, c false true, c true false, c true true) = (241, 4, 4, 0) := by decide +kernel

-- Pair counts 244, 1, 1, 3 for the bunched year.
example :
    let E : Finset ℕ := {40, 41, 42, 43}
    let c := fun (a b : Bool) => ((Finset.univ : Finset (Fin 249)).filter
      (fun t => decide (t.val + 1 ∈ E) = a ∧ decide (t.val + 2 ∈ E) = b)).card
    (c false false, c false true, c true false, c true true) = (244, 1, 1, 3) := by decide +kernel

-- There are C(250, 4) = 158,882,750 ways to place four exceptions, and 247 of them are runs.
example : Nat.choose 250 4 = 158882750 := by
  rw [Nat.choose_eq_descFactorial_div_factorial]; norm_num [Nat.descFactorial, Nat.factorial]
example : 250 - 4 + 1 = 247 := by norm_num

-- A correct model gives exactly 4 exceptions in 13.41% of years:
-- 158,882,750 (1/100)^4 (99/100)^246 lies between 0.1340 and 0.1342.
example : (1340 : ℚ) / 10000 < 158882750 * (1 / 100) ^ 4 * (99 / 100) ^ 246 ∧
    (158882750 : ℚ) * (1 / 100) ^ 4 * (99 / 100) ^ 246 < 1342 / 10000 := by
  norm_num

#print axioms exception_count_binomial
#print axioms kupiec_best_rate_is_observed_rate
#print axioms run_count_eq
