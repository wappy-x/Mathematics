-- The law of the iterated logarithm: for a fair ±1 random walk, with probability 1 the walk divided by its envelope √(2n ln ln n) has largest limit point 1 and smallest limit point -1, its running maximum passes a level a ≥ 0 by step n with chance at most 2e^(-a²/2n), and for a whole level a ≥ 1 that chance equals P(S_n ≥ a) + P(S_n > a).
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Data.EReal.Basic
import Mathlib.Order.LiminfLimsup
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open MeasureTheory ProbabilityTheory Filter

/-! ### Helper lemmas -/
/-- The value `±1` of a step written as a Boolean (`true` is `+1`). -/
def lilSgn (c : Bool) : ℤ := if c then 1 else -1

/-- The walk of a Boolean path `b` of `n` steps after `k` steps. -/
def lilPS {n : ℕ} (b : Fin n → Bool) (k : ℕ) : ℤ :=
  ∑ i ∈ Finset.range k, if h : i < n then lilSgn (b ⟨i, h⟩) else 0

lemma lilPS_zero {n : ℕ} (b : Fin n → Bool) : lilPS b 0 = 0 := by simp [lilPS]

lemma lilPS_cons {n : ℕ} (c : Bool) (b : Fin n → Bool) (k : ℕ) :
    lilPS (Fin.cons c b : Fin (n + 1) → Bool) (k + 1) = lilSgn c + lilPS b k := by
  unfold lilPS
  rw [Finset.sum_range_succ', add_comm]
  have hs : (∑ i ∈ Finset.range k, if h : i + 1 < n + 1 then
      lilSgn ((Fin.cons c b : Fin (n + 1) → Bool) ⟨i + 1, h⟩) else 0) =
      ∑ i ∈ Finset.range k, if h : i < n then lilSgn (b ⟨i, h⟩) else 0 := by
    apply Finset.sum_congr rfl
    intro i _
    by_cases h : i < n
    · have h' : i + 1 < n + 1 := by omega
      simp only [h, h', ↓reduceDIte]
      have : (⟨i + 1, h'⟩ : Fin (n + 1)) = Fin.succ ⟨i, h⟩ := rfl
      rw [this, Fin.cons_succ]
    · have h' : ¬ i + 1 < n + 1 := by omega
      simp only [h, h', ↓reduceDIte]
  rw [hs]
  simp

lemma lil_card_cons {n : ℕ} (p : (Fin (n + 1) → Bool) → Prop) [DecidablePred p] :
    (Finset.univ.filter p).card =
      (Finset.univ.filter (fun b : Fin n → Bool => p (Fin.cons true b))).card +
      (Finset.univ.filter (fun b : Fin n → Bool => p (Fin.cons false b))).card := by
  simp only [Finset.card_filter]
  rw [← (Fin.consEquiv (fun _ => Bool)).sum_comp, Fintype.sum_prod_type, Fintype.sum_bool]
  rfl

lemma lilPS_abs_le {n : ℕ} (b : Fin n → Bool) (k : ℕ) : |lilPS b k| ≤ k := by
  unfold lilPS
  calc |∑ i ∈ Finset.range k, (if h : i < n then lilSgn (b ⟨i, h⟩) else 0)|
      ≤ ∑ i ∈ Finset.range k, |(if h : i < n then lilSgn (b ⟨i, h⟩) else 0)| :=
        Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ i ∈ Finset.range k, (1 : ℤ) := by
        apply Finset.sum_le_sum; intro i _
        split_ifs <;> simp [lilSgn]; split_ifs <;> simp
    _ = k := by simp

/-- `h n a`: paths of `n` steps ending at or above `a`. -/
lemma lil_h_succ (n : ℕ) (a : ℤ) :
    (Finset.univ.filter (fun b : Fin (n + 1) → Bool => a ≤ lilPS b (n + 1))).card =
      (Finset.univ.filter (fun b : Fin n → Bool => a - 1 ≤ lilPS b n)).card +
      (Finset.univ.filter (fun b : Fin n → Bool => a + 1 ≤ lilPS b n)).card := by
  rw [lil_card_cons]
  congr 2 <;> ext b <;> simp [lilPS_cons, lilSgn] <;> omega

lemma lil_g_succ (n : ℕ) (a : ℤ) (ha : 1 ≤ a) :
    (Finset.univ.filter (fun b : Fin (n + 1) → Bool => ∃ k ≤ n + 1, a ≤ lilPS b k)).card =
      (Finset.univ.filter (fun b : Fin n → Bool => ∃ k ≤ n, a - 1 ≤ lilPS b k)).card +
      (Finset.univ.filter (fun b : Fin n → Bool => ∃ k ≤ n, a + 1 ≤ lilPS b k)).card := by
  rw [lil_card_cons]
  congr 2 <;> ext b <;> simp only [Finset.mem_filter, Finset.mem_univ, true_and] <;>
    constructor
  · rintro ⟨k, hk, hak⟩
    rcases k with _ | k
    · rw [lilPS_zero] at hak; omega
    · refine ⟨k, by omega, ?_⟩; rw [lilPS_cons] at hak; simp [lilSgn] at hak; omega
  · rintro ⟨k, hk, hak⟩
    refine ⟨k + 1, by omega, ?_⟩; rw [lilPS_cons]; simp [lilSgn]; omega
  · rintro ⟨k, hk, hak⟩
    rcases k with _ | k
    · rw [lilPS_zero] at hak; omega
    · refine ⟨k, by omega, ?_⟩; rw [lilPS_cons] at hak; simp [lilSgn] at hak; omega
  · rintro ⟨k, hk, hak⟩
    refine ⟨k + 1, by omega, ?_⟩; rw [lilPS_cons]; simp [lilSgn]; omega

lemma lil_h_symm (n : ℕ) (a : ℤ) :
    (Finset.univ.filter (fun b : Fin n → Bool => a ≤ lilPS b n)).card +
      (Finset.univ.filter (fun b : Fin n → Bool => 1 - a ≤ lilPS b n)).card = 2 ^ n := by
  induction n generalizing a with
  | zero =>
    by_cases h : a ≤ 0
    · have h2 : ¬ (1 - a ≤ 0) := by omega
      simp [lilPS_zero, h, h2]
    · have h2 : 1 - a ≤ 0 := by omega
      simp [lilPS_zero, h, h2]
  | succ n ih =>
    rw [lil_h_succ, lil_h_succ, pow_succ]
    have e1 := ih (a - 1)
    have e2 := ih (a + 1)
    have r1 : 1 - (a - 1) = 1 - a + 1 := by ring
    have r2 : 1 - (a + 1) = 1 - a - 1 := by ring
    rw [r1] at e1; rw [r2] at e2
    omega

lemma lil_g_zero (n : ℕ) (a : ℤ) (ha : a ≤ 0) :
    (Finset.univ.filter (fun b : Fin n → Bool => ∃ k ≤ n, a ≤ lilPS b k)).card = 2 ^ n := by
  rw [Finset.filter_true_of_mem]
  · simp
  · intro b _; exact ⟨0, by omega, by rw [lilPS_zero]; exact ha⟩

lemma lil_reflection_count (n : ℕ) (a : ℤ) (ha : 1 ≤ a) :
    (Finset.univ.filter (fun b : Fin n → Bool => ∃ k ≤ n, a ≤ lilPS b k)).card =
      (Finset.univ.filter (fun b : Fin n → Bool => a ≤ lilPS b n)).card +
      (Finset.univ.filter (fun b : Fin n → Bool => a + 1 ≤ lilPS b n)).card := by
  induction n generalizing a with
  | zero =>
    have h1 : ¬ a ≤ 0 := by omega
    have h2 : ¬ a + 1 ≤ 0 := by omega
    simp [lilPS_zero, h1, h2]
  | succ n ih =>
    rw [lil_g_succ n a ha, lil_h_succ, lil_h_succ]
    rw [ih (a + 1) (by omega)]
    by_cases ha2 : 2 ≤ a
    · rw [ih (a - 1) (by omega)]
      have : a - 1 + 1 = a := by ring
      rw [this]; ring_nf
    · have ha1 : a = 1 := by omega
      subst ha1
      rw [lil_g_zero n (1 - 1) (by norm_num)]
      have := lil_h_symm n 0
      norm_num at this ⊢
      omega

lemma lil_law {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) (n : ℕ) (A : Finset (Fin n → Bool)) :
    P {ω | (fun i : Fin n => decide (X i ω = 1)) ∈ A} = A.card / 2 ^ n := by
  classical
  have hv : Measurable (fun ω (i : Fin n) => decide (X i ω = 1)) := by
    apply Measurable.of_eval
    intro i
    apply measurable_to_countable'
    intro c
    cases c
    · have : (fun ω => decide (X i ω = 1)) ⁻¹' {false} = (X i ⁻¹' {1})ᶜ := by
        ext ω; simp
      rw [this]; exact ((hmeas i) (measurableSet_singleton 1)).compl
    · have : (fun ω => decide (X i ω = 1)) ⁻¹' {true} = X i ⁻¹' {1} := by
        ext ω; simp
      rw [this]; exact (hmeas i) (measurableSet_singleton 1)
  have hcyl : ∀ b : Fin n → Bool,
      P {ω | (fun i : Fin n => decide (X i ω = 1)) = b} = (2 ^ n)⁻¹ := by
    intro b
    let sets : ℕ → Set ℝ := fun i =>
      if h : i < n then (if b ⟨i, h⟩ then {1} else {1}ᶜ) else Set.univ
    have hset : {ω | (fun i : Fin n => decide (X i ω = 1)) = b} =
        ⋂ i ∈ Finset.range n, X i ⁻¹' sets i := by
      ext ω
      simp only [Set.mem_iInter, Set.mem_preimage, Finset.mem_range,
        funext_iff]
      constructor
      · intro h i hi
        have := h ⟨i, hi⟩
        simp only [sets, hi, ↓reduceDIte]
        cases hb : b ⟨i, hi⟩ <;> simp_all
      · intro h i
        have := h i i.2
        simp only [sets, i.2, ↓reduceDIte] at this
        cases hb : b i <;> simp_all
    have hmeas_sets : ∀ i, MeasurableSet (sets i) := by
      intro i; simp only [sets]; split_ifs
      · exact measurableSet_singleton 1
      · exact (measurableSet_singleton 1).compl
      · exact MeasurableSet.univ
    rw [hset, hind.measure_inter_preimage_eq_mul (Finset.range n) (fun i _ => hmeas_sets i)]
    have : ∀ i ∈ Finset.range n, P (X i ⁻¹' sets i) = 2⁻¹ := by
      intro i hi
      have hi' : i < n := Finset.mem_range.mp hi
      simp only [sets, hi', ↓reduceDIte]
      split_ifs
      · have := hfair i; simpa [Set.preimage, one_div] using this
      · rw [Set.preimage_compl, measure_compl ((hmeas i) (measurableSet_singleton 1))
          (measure_ne_top _ _), measure_univ]
        have := hfair i
        simp only [Set.preimage, Set.mem_singleton_iff]
        rw [this, one_div, ENNReal.one_sub_inv_two]
    rw [Finset.prod_congr rfl this]
    simp [ENNReal.inv_pow]
  have hU : {ω | (fun i : Fin n => decide (X i ω = 1)) ∈ A} =
      ⋃ b ∈ A, {ω | (fun i : Fin n => decide (X i ω = 1)) = b} := by
    ext ω; simp
  rw [hU, measure_biUnion_finset]
  · simp only [hcyl, Finset.sum_const, nsmul_eq_mul]
    rw [div_eq_mul_inv]
  · intro b _ c _ hbc
    rw [Function.onFun, Set.disjoint_left]
    intro ω h1 h2
    exact hbc ((Set.mem_ofPred_eq.mp h1).symm.trans (Set.mem_ofPred_eq.mp h2))
  · intro b _
    exact hv (measurableSet_singleton b)

lemma lil_ae_sign {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (X : ℕ → Ω → ℝ)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1) :
    ∀ᵐ ω ∂P, ∀ n k, k ≤ n → ∑ i ∈ Finset.range k, X i ω =
      (lilPS (fun i : Fin n => decide (X i ω = 1)) k : ℝ) := by
  filter_upwards [ae_all_iff.mpr hstep] with ω hω
  intro n k hk
  unfold lilPS
  push_cast
  apply Finset.sum_congr rfl
  intro i hi
  have hin : i < n := lt_of_lt_of_le (Finset.mem_range.mp hi) hk
  simp only [hin, ↓reduceDIte, lilSgn]
  rcases hω i with h | h <;> simp [h]

lemma lil_reflection_aux {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) (n a : ℕ) (ha : 1 ≤ a) :
    P {ω | ∃ k ∈ Finset.Icc 1 n, (a : ℝ) ≤ ∑ i ∈ Finset.range k, X i ω} =
      P {ω | (a : ℝ) ≤ ∑ i ∈ Finset.range n, X i ω} +
        P {ω | (a : ℝ) < ∑ i ∈ Finset.range n, X i ω} := by
  classical
  have hs := lil_ae_sign P X hstep
  set v : Ω → Fin n → Bool := fun ω i => decide (X i ω = 1) with hvdef
  have e1 : P {ω | ∃ k ∈ Finset.Icc 1 n, (a : ℝ) ≤ ∑ i ∈ Finset.range k, X i ω} =
      P {ω | v ω ∈ Finset.univ.filter (fun b : Fin n → Bool => ∃ k ≤ n, (a : ℤ) ≤ lilPS b k)} := by
    apply measure_congr
    rw [Filter.eventuallyEqSet_iff]
    filter_upwards [hs] with ω hω
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_Icc]
    constructor
    · rintro ⟨k, ⟨_, hk⟩, hak⟩
      refine ⟨k, hk, ?_⟩
      rw [hω n k hk] at hak
      exact_mod_cast hak
    · rintro ⟨k, hk, hak⟩
      have hk1 : 1 ≤ k := by
        rcases Nat.eq_zero_or_pos k with h | h
        · subst h; rw [lilPS_zero] at hak; omega
        · exact h
      refine ⟨k, ⟨hk1, hk⟩, ?_⟩
      rw [hω n k hk]
      exact_mod_cast hak
  have e2 : P {ω | (a : ℝ) ≤ ∑ i ∈ Finset.range n, X i ω} =
      P {ω | v ω ∈ Finset.univ.filter (fun b : Fin n → Bool => (a : ℤ) ≤ lilPS b n)} := by
    apply measure_congr
    rw [Filter.eventuallyEqSet_iff]
    filter_upwards [hs] with ω hω
    simp only [Finset.mem_filter, Finset.mem_univ, true_and]
    rw [hω n n le_rfl]
    exact_mod_cast Iff.rfl
  have e3 : P {ω | (a : ℝ) < ∑ i ∈ Finset.range n, X i ω} =
      P {ω | v ω ∈ Finset.univ.filter (fun b : Fin n → Bool => (a : ℤ) + 1 ≤ lilPS b n)} := by
    apply measure_congr
    rw [Filter.eventuallyEqSet_iff]
    filter_upwards [hs] with ω hω
    simp only [Finset.mem_filter, Finset.mem_univ, true_and]
    rw [hω n n le_rfl]
    constructor
    · intro h; have : (a : ℤ) < lilPS (v ω) n := by exact_mod_cast h
      omega
    · intro h; have : (a : ℤ) < lilPS (v ω) n := by omega
      exact_mod_cast this
  rw [e1, e2, e3, lil_law P X hmeas hind hfair, lil_law P X hmeas hind hfair,
    lil_law P X hmeas hind hfair, lil_reflection_count n (a : ℤ) (by exact_mod_cast ha),
    Nat.cast_add, ENNReal.add_div]

lemma lil_subG {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i))
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) (i : ℕ) :
    HasSubgaussianMGF (X i) 1 P := by
  have hae : X i =ᵐ[P] fun ω => ({ω | X i ω = 1}.indicator (fun _ => (2 : ℝ)) ω) - 1 := by
    filter_upwards [hstep i] with ω hω
    rcases hω with h | h <;> simp [Set.indicator, h] <;> norm_num
  have hm1 : MeasurableSet {ω | X i ω = 1} := (hmeas i) (measurableSet_singleton 1)
  have hmean : P[X i] = 0 := by
    rw [integral_congr_ae hae, integral_sub _ (integrable_const _),
      integral_indicator_const _ hm1]
    · simp [measureReal_def, hfair i]
    · exact (integrable_const _).indicator hm1
  have hb : ∀ᵐ ω ∂P, X i ω ∈ Set.Icc (-1 : ℝ) 1 := by
    filter_upwards [hstep i] with ω hω
    rcases hω with h | h <;> simp [h]
  have := hasSubgaussianMGF_of_mem_Icc_of_integral_eq_zero (hmeas i).aemeasurable hb hmean
  convert this using 1
  ext
  simp only [NNReal.coe_one, NNReal.coe_pow, NNReal.coe_div, coe_nnnorm, sub_neg_eq_add]
  norm_num

lemma lil_hoeffding {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) (n : ℕ) (a : ℝ) (ha : 0 ≤ a) :
    P {ω | a ≤ ∑ i ∈ Finset.range n, X i ω} ≤ ENNReal.ofReal (Real.exp (-a ^ 2 / (2 * n))) := by
  have h := HasSubgaussianMGF.measure_sum_range_ge_le_of_iIndepFun (c := 1) (n := n) hind
    (fun i _ => lil_subG P X hmeas hstep hfair i) ha
  rw [← ofReal_measureReal]
  apply ENNReal.ofReal_le_ofReal
  simpa using h

lemma lil_maximal_aux {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) (n : ℕ) (a : ℝ) (ha : 0 ≤ a) :
    P {ω | ∃ k ∈ Finset.Icc 1 n, a ≤ ∑ i ∈ Finset.range k, X i ω} ≤
      ENNReal.ofReal (2 * Real.exp (-a ^ 2 / (2 * n))) := by
  rcases eq_or_lt_of_le ha with ha0 | hapos
  · subst ha0
    calc _ ≤ 1 := prob_le_one
      _ ≤ _ := by
        rw [← ENNReal.ofReal_one]; apply ENNReal.ofReal_le_ofReal; simp
  set a' : ℕ := ⌈a⌉₊ with ha'
  have ha'1 : 1 ≤ a' := Nat.one_le_iff_ne_zero.mpr (by
    rw [ha']; exact (Nat.ceil_pos.mpr hapos).ne')
  have hceil : ((a' : ℤ)) = ⌈a⌉ := by rw [ha']; exact Int.natCast_ceil_eq_ceil ha
  have hs := lil_ae_sign P X hstep
  have e1 : P {ω | ∃ k ∈ Finset.Icc 1 n, a ≤ ∑ i ∈ Finset.range k, X i ω} =
      P {ω | ∃ k ∈ Finset.Icc 1 n, (a' : ℝ) ≤ ∑ i ∈ Finset.range k, X i ω} := by
    apply measure_congr
    rw [Filter.eventuallyEqSet_iff]
    filter_upwards [hs] with ω hω
    simp only [Finset.mem_Icc]
    apply exists_congr; intro k
    apply and_congr_right; intro hk
    rw [hω n k hk.2]
    have : (a' : ℝ) = ((a' : ℤ) : ℝ) := by norm_cast
    rw [this, Int.cast_le, hceil, Int.ceil_le]
  have hle : ∀ s : Set Ω, s ⊆ {ω | a ≤ ∑ i ∈ Finset.range n, X i ω} →
      P s ≤ ENNReal.ofReal (Real.exp (-a ^ 2 / (2 * n))) := fun s hs =>
    (measure_mono hs).trans (lil_hoeffding P X hmeas hind hstep hfair n a ha)
  rw [e1, lil_reflection_aux P X hmeas hind hstep hfair n a' ha'1]
  have h1 := hle {ω | (a' : ℝ) ≤ ∑ i ∈ Finset.range n, X i ω} (by
    intro ω hω; exact le_trans (Nat.le_ceil a) hω)
  have h2 := hle {ω | (a' : ℝ) < ∑ i ∈ Finset.range n, X i ω} (by
    intro ω hω; exact le_trans (Nat.le_ceil a) hω.le)
  calc _ ≤ ENNReal.ofReal (Real.exp (-a ^ 2 / (2 * n))) +
        ENNReal.ofReal (Real.exp (-a ^ 2 / (2 * n))) := add_le_add h1 h2
    _ = _ := by
        rw [← ENNReal.ofReal_add (Real.exp_pos _).le (Real.exp_pos _).le]; ring_nf

lemma lil_log3 : 1 < Real.log 3 := by
  rw [Real.lt_log_iff_exp_lt (by norm_num)]
  have := Real.exp_one_lt_d9; linarith

lemma lil_h_mono {m n : ℕ} (hm : 3 ≤ m) (hmn : m ≤ n) :
    Real.sqrt (2 * m * Real.log (Real.log m)) ≤ Real.sqrt (2 * n * Real.log (Real.log n)) := by
  apply Real.sqrt_le_sqrt
  have hm' : (3:ℝ) ≤ m := by exact_mod_cast hm
  have hmn' : (m:ℝ) ≤ n := by exact_mod_cast hmn
  have hlm : 1 < Real.log m := lt_of_lt_of_le lil_log3 (Real.log_le_log (by norm_num) hm')
  have hll : 0 ≤ Real.log (Real.log m) := Real.log_nonneg hlm.le
  have hlmn : Real.log (Real.log m) ≤ Real.log (Real.log n) :=
    Real.log_le_log (by linarith) (Real.log_le_log (by linarith) hmn')
  have : (2:ℝ) * m ≤ 2 * n := by linarith
  exact mul_le_mul this hlmn hll (by linarith)

lemma lil_upper {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) (c : ℝ) (hc : 1 < c) :
    ∀ᵐ ω ∂P, ∀ᶠ n in atTop,
      ∑ i ∈ Finset.range n, X i ω ≤ c * Real.sqrt (2 * n * Real.log (Real.log n)) := by
  set θ : ℝ := Real.sqrt c with hθ
  have hθ1 : 1 < θ := by
    rw [hθ, Real.lt_sqrt (by norm_num)]; linarith
  have hθsq : θ ^ 2 = c := Real.sq_sqrt (by linarith)
  set nk : ℕ → ℕ := fun k => ⌊θ ^ k⌋₊ with hnk
  have hnk_mono : Monotone nk := fun a b hab => Nat.floor_mono (pow_le_pow_right₀ hθ1.le hab)
  have hnk_le : ∀ k, (nk k : ℝ) ≤ θ ^ k := fun k => Nat.floor_le (by positivity)
  have hnk_gt : ∀ k, θ ^ k - 1 < nk k := fun k => by
    have := Nat.lt_floor_add_one (θ ^ k); simp only [hnk]; linarith
  have hpow := tendsto_pow_atTop_atTop_of_one_lt hθ1
  have hnk_tendsto : Tendsto nk atTop atTop := tendsto_nat_floor_atTop.comp hpow
  have hlogθ : 0 < Real.log θ := Real.log_pos hθ1
  have hev : ∀ᶠ k : ℕ in atTop, 4 ≤ θ ^ k ∧ c / (θ - 1) ≤ θ ^ k ∧
      2 * Real.log 2 ≤ k * Real.log θ :=
    (hpow.eventually_ge_atTop 4).and ((hpow.eventually_ge_atTop _).and
      ((tendsto_natCast_atTop_atTop.atTop_mul_const hlogθ).eventually_ge_atTop _))
  obtain ⟨K, hK⟩ := eventually_atTop.mp hev
  set κ : ℝ := Real.log θ / 2 with hκ
  have hκpos : 0 < κ := by positivity
  set f : ℕ → ℝ := fun k => 2 * (κ ^ (-c) * (k : ℝ) ^ (-c)) with hf
  have hf_nonneg : ∀ k, 0 ≤ f k := fun k => by positivity
  have hf_sum : Summable f :=
    ((Real.summable_nat_rpow.mpr (by linarith)).mul_left (κ ^ (-c))).mul_left 2
  set B : ℕ → Set Ω := fun k => {ω | ∃ j ∈ Finset.Icc 1 (nk (k + 1)),
    c * Real.sqrt (2 * (nk k : ℕ) * Real.log (Real.log (nk k : ℕ))) ≤
      ∑ i ∈ Finset.range j, X i ω} with hB
  -- facts for k ≥ K
  have hK3 : ∀ k ≥ K, 3 ≤ nk k := by
    intro k hk
    have h1 := (hK k hk).1
    have : (3 : ℝ) ≤ nk k := by have := hnk_gt k; linarith
    exact_mod_cast this
  have hBk : ∀ k ≥ K, P (B k) ≤ ENNReal.ofReal (f k) := by
    intro k hk
    obtain ⟨h4, hcθ, hlg⟩ := hK k hk
    set Nk : ℝ := (nk k : ℝ) with hNk
    set Nk1 : ℝ := (nk (k + 1) : ℝ) with hNk1
    have hN3 : (3 : ℝ) ≤ Nk := by rw [hNk]; exact_mod_cast hK3 k hk
    have hN1N : Nk ≤ Nk1 := by rw [hNk, hNk1]; exact_mod_cast hnk_mono (Nat.le_succ k)
    have hlogN : 1 < Real.log Nk := lt_of_lt_of_le lil_log3 (Real.log_le_log (by norm_num) hN3)
    set ℓ : ℝ := Real.log (Real.log Nk) with hℓ
    have hℓ0 : 0 ≤ ℓ := Real.log_nonneg hlogN.le
    have hθm1 : 0 < θ - 1 := by linarith
    -- c * Nk ≥ Nk1
    have hcN : Nk1 ≤ c * Nk := by
      have e1 : Nk1 ≤ θ ^ (k + 1) := hnk_le (k + 1)
      have e2 : θ ^ k - 1 < Nk := hnk_gt k
      have e3 : c ≤ θ ^ k * (θ - 1) := by rwa [div_le_iff₀ hθm1] at hcθ
      have e4 : c * θ ^ k = θ ^ (k + 2) := by rw [← hθsq]; ring
      have e5 : c * (θ ^ k - 1) ≤ c * Nk := mul_le_mul_of_nonneg_left e2.le (by linarith)
      have e6 : θ ^ (k + 2) - θ ^ (k + 1) = θ ^ k * θ * (θ - 1) := by ring
      have e7 : θ ^ k * (θ - 1) ≤ θ ^ k * θ * (θ - 1) := by
        have : 0 ≤ θ ^ k * (θ - 1) := by positivity
        nlinarith
      nlinarith
    -- log Nk ≥ k log θ / 2
    have hkpos : (0 : ℝ) < k := by
      by_contra hk0; replace hk0 := not_lt.mp hk0
      have : (k : ℝ) * Real.log θ ≤ 0 := mul_nonpos_of_nonpos_of_nonneg hk0 hlogθ.le
      have : 0 < Real.log 2 := Real.log_pos (by norm_num)
      linarith
    have hlogNk : κ * k ≤ Real.log Nk := by
      have e2 : θ ^ k / 2 ≤ Nk := by have := hnk_gt k; linarith
      have e5 : Real.log (θ ^ k / 2) ≤ Real.log Nk :=
        Real.log_le_log (by positivity) e2
      rw [Real.log_div (by positivity) (by norm_num), Real.log_pow] at e5
      rw [hκ]; linarith
    have hℓκ : Real.log (κ * k) ≤ ℓ := Real.log_le_log (by positivity) hlogNk
    -- the bound
    have hmax := lil_maximal_aux P X hmeas hind hstep hfair (nk (k + 1))
      (c * Real.sqrt (2 * (nk k : ℕ) * Real.log (Real.log (nk k : ℕ)))) (by positivity)
    refine hmax.trans (ENNReal.ofReal_le_ofReal ?_)
    simp only [hf]
    apply mul_le_mul_of_nonneg_left _ (by norm_num)
    rw [← Real.mul_rpow hκpos.le hkpos.le, Real.rpow_def_of_pos (by positivity)]
    apply Real.exp_le_exp.mpr
    rw [mul_pow, Real.sq_sqrt (by positivity)]
    have hN1pos : 0 < Nk1 := by linarith
    show -(c ^ 2 * (2 * Nk * ℓ)) / (2 * Nk1) ≤ Real.log (κ * k) * -c
    rw [neg_div]
    have hc0 : 0 < c := by linarith
    have key : c * Real.log (κ * k) ≤ c ^ 2 * (2 * Nk * ℓ) / (2 * Nk1) := by
      rw [le_div_iff₀ (by positivity)]
      have h1 : c * Real.log (κ * k) * (2 * Nk1) ≤ c * ℓ * (2 * Nk1) :=
        mul_le_mul_of_nonneg_right (mul_le_mul_of_nonneg_left hℓκ hc0.le) (by positivity)
      have h2 : c * ℓ * (2 * Nk1) ≤ c * ℓ * (2 * (c * Nk)) :=
        mul_le_mul_of_nonneg_left (by linarith) (by positivity)
      nlinarith
    linarith
  have hsum : ∑' k, P (B (k + K)) ≠ ⊤ := by
    apply ne_top_of_le_ne_top (ENNReal.ofReal_ne_top (r := ∑' k, f (k + K)))
    rw [ENNReal.ofReal_tsum_of_nonneg (fun k => hf_nonneg _) ((summable_nat_add_iff K).mpr hf_sum)]
    exact tsum_le_tsum (fun k => hBk (k + K) (by omega))
  filter_upwards [ae_eventually_notMem hsum] with ω hω
  obtain ⟨K1, hK1⟩ := eventually_atTop.mp hω
  rw [eventually_atTop]
  refine ⟨nk (K1 + K), fun n hn => ?_⟩
  have hex : ∃ k, n < nk k := (hnk_tendsto.eventually_gt_atTop n).exists
  have hk1 : K1 + K < Nat.find hex := by
    by_contra hcon; replace hcon := not_lt.mp hcon
    have := Nat.find_spec hex
    have := hnk_mono hcon
    omega
  obtain ⟨k, hk⟩ : ∃ k, Nat.find hex = k + 1 := ⟨Nat.find hex - 1, by omega⟩
  have h1 : nk k ≤ n := not_lt.mp (Nat.find_min hex (by omega : k < Nat.find hex))
  have h2 : n < nk (k + 1) := by rw [← hk]; exact Nat.find_spec hex
  have hnot := hK1 (k - K) (by omega)
  have hkK : k - K + K = k := by omega
  simp only [hB, hkK, Set.mem_ofPred_eq, not_exists, not_and, not_le] at hnot
  have hn3 : 3 ≤ nk k := hK3 k (by omega)
  have := hnot n (Finset.mem_Icc.mpr ⟨by omega, h2.le⟩)
  refine this.le.trans ?_
  have hc0 : 0 ≤ c := by linarith
  exact mul_le_mul_of_nonneg_left (lil_h_mono hn3 h1) hc0

lemma lil_count_eq (m j : ℕ) :
    (Finset.univ.filter (fun b : Fin m → Bool => lilPS b m = 2 * (j : ℤ) - m)).card =
      m.choose j := by
  induction m generalizing j with
  | zero =>
    rcases j with _ | j
    · simp [lilPS_zero]
    · have : ∀ b : Fin 0 → Bool, ¬ (lilPS b 0 = 2 * ((j + 1 : ℕ) : ℤ) - ((0 : ℕ) : ℤ)) := by
        intro b; rw [lilPS_zero]; push_cast; omega
      rw [Finset.filter_false_of_mem (fun b _ => this b)]; simp
  | succ m ih =>
    rw [lil_card_cons]
    rcases j with _ | j
    · have e1 : (Finset.univ.filter (fun b : Fin m → Bool =>
          lilPS (Fin.cons true b : Fin (m + 1) → Bool) (m + 1) =
            2 * ((0 : ℕ) : ℤ) - ((m + 1 : ℕ) : ℤ))) = ∅ := by
        apply Finset.filter_false_of_mem
        intro b _
        rw [lilPS_cons]
        have := lilPS_abs_le b m
        simp only [lilSgn]; push_cast
        intro h; rw [abs_le] at this; omega
      have e2 : (Finset.univ.filter (fun b : Fin m → Bool =>
          lilPS (Fin.cons false b : Fin (m + 1) → Bool) (m + 1) =
            2 * ((0 : ℕ) : ℤ) - ((m + 1 : ℕ) : ℤ))) =
          Finset.univ.filter (fun b : Fin m → Bool => lilPS b m = 2 * ((0 : ℕ) : ℤ) - m) := by
        apply Finset.filter_congr
        intro b _
        rw [lilPS_cons]; simp only [lilSgn]; push_cast; omega
      rw [e1, e2, ih 0]; simp
    · have e1 : (Finset.univ.filter (fun b : Fin m → Bool =>
          lilPS (Fin.cons true b : Fin (m + 1) → Bool) (m + 1) =
            2 * ((j + 1 : ℕ) : ℤ) - ((m + 1 : ℕ) : ℤ))) =
          Finset.univ.filter (fun b : Fin m → Bool => lilPS b m = 2 * (j : ℤ) - m) := by
        apply Finset.filter_congr
        intro b _
        rw [lilPS_cons]; simp only [lilSgn]; push_cast; omega
      have e2 : (Finset.univ.filter (fun b : Fin m → Bool =>
          lilPS (Fin.cons false b : Fin (m + 1) → Bool) (m + 1) =
            2 * ((j + 1 : ℕ) : ℤ) - ((m + 1 : ℕ) : ℤ))) =
          Finset.univ.filter (fun b : Fin m → Bool => lilPS b m = 2 * ((j + 1 : ℕ) : ℤ) - m) := by
        apply Finset.filter_congr
        intro b _
        rw [lilPS_cons]; simp only [lilSgn]; push_cast; omega
      rw [e1, e2, ih j, ih (j + 1), Nat.choose_succ_succ']

lemma lil_centralBinom (N : ℕ) (hN : 1 ≤ N) : 16 ^ N ≤ 4 * N * (Nat.centralBinom N) ^ 2 := by
  induction N, hN using Nat.le_induction with
  | base => simp [Nat.centralBinom, Nat.choose]
  | succ n hn ih =>
    have hb := Nat.succ_mul_centralBinom_succ n
    set a := Nat.centralBinom n
    set b := Nat.centralBinom (n + 1)
    have h1 : (n + 1) * 16 ^ (n + 1) ≤ (n + 1) * (4 * (n + 1) * b ^ 2) := by
      have e : (n + 1) * (4 * (n + 1) * b ^ 2) = 4 * ((n + 1) * b) ^ 2 := by ring
      rw [e, hb]
      have e2 : (n + 1) * 16 ^ (n + 1) = 16 * ((n + 1) * 16 ^ n) := by ring
      rw [e2]
      have : (n + 1) * 16 ^ n ≤ (n + 1) * (4 * n * a ^ 2) := Nat.mul_le_mul_left _ ih
      have h3 : (n + 1) * (4 * n * a ^ 2) ≤ (2 * n + 1) ^ 2 * a ^ 2 := by
        have : (n + 1) * (4 * n) ≤ (2 * n + 1) ^ 2 := by nlinarith
        calc (n + 1) * (4 * n * a ^ 2) = ((n + 1) * (4 * n)) * a ^ 2 := by ring
          _ ≤ (2 * n + 1) ^ 2 * a ^ 2 := Nat.mul_le_mul_right _ this
      calc 16 * ((n + 1) * 16 ^ n) ≤ 16 * ((2 * n + 1) ^ 2 * a ^ 2) :=
            Nat.mul_le_mul_left _ (this.trans h3)
        _ = 4 * (2 * (2 * n + 1) * a) ^ 2 := by ring
    exact Nat.le_of_mul_le_mul_left h1 (Nat.succ_pos n)

lemma lil_factor (N l D : ℝ) (hl : 0 ≤ l) (hD : 0 < D) (hDl : D ≤ N - l) :
    Real.exp (-(2 * l + 1) / D) ≤ (N - l) / (N + l + 1) := by
  have hNl : 0 < N - l := lt_of_lt_of_le hD hDl
  have hw : 0 ≤ (2 * l + 1) / (N - l) := by positivity
  have h1 : Real.exp (-(2 * l + 1) / D) ≤ Real.exp (-((2 * l + 1) / (N - l))) := by
    apply Real.exp_le_exp.mpr
    rw [neg_div, neg_le_neg_iff]
    exact div_le_div_of_nonneg_left (by linarith) hD hDl
  refine h1.trans ?_
  rw [Real.exp_neg]
  have h2 : 1 + (2 * l + 1) / (N - l) ≤ Real.exp ((2 * l + 1) / (N - l)) := by
    have := Real.add_one_le_exp ((2 * l + 1) / (N - l)); linarith
  have h3 : 1 + (2 * l + 1) / (N - l) = (N + l + 1) / (N - l) := by
    field_simp; ring
  rw [h3] at h2
  have h4 : 0 < (N + l + 1) / (N - l) := div_pos (by linarith) hNl
  calc (Real.exp ((2 * l + 1) / (N - l)))⁻¹ ≤ ((N + l + 1) / (N - l))⁻¹ :=
        inv_anti₀ h4 h2
    _ = (N - l) / (N + l + 1) := by rw [inv_div]

lemma lil_choose_ratio (N L l : ℕ) (hl : l ≤ L) (hL : 2 * L < N) :
    ((2 * N).choose N : ℝ) * Real.exp (-(l : ℝ) ^ 2 / ((N : ℝ) - 2 * L)) ≤
      ((2 * N).choose (N + l) : ℝ) := by
  have hD : (0 : ℝ) < (N : ℝ) - 2 * L := by
    have : ((2 * L : ℕ) : ℝ) < N := by exact_mod_cast hL
    push_cast at this; linarith
  induction l with
  | zero => simp
  | succ l ih =>
    have ih := ih (by omega)
    have hrec := Nat.choose_succ_right_eq (2 * N) (N + l)
    have hsub : 2 * N - (N + l) = N - l := by omega
    rw [hsub] at hrec
    have hrec' : ((2 * N).choose (N + l + 1) : ℝ) * ((N : ℝ) + l + 1) =
        ((2 * N).choose (N + l) : ℝ) * ((N : ℝ) - l) := by
      have := congrArg (fun t : ℕ => (t : ℝ)) hrec
      simp only [Nat.cast_mul, Nat.cast_add, Nat.cast_one] at this
      rw [Nat.cast_sub (by omega)] at this
      linarith
    have hf := lil_factor N l ((N : ℝ) - 2 * L) (by positivity) hD (by
      have : (l : ℝ) + 1 ≤ L := by exact_mod_cast hl
      linarith)
    have hpos : (0 : ℝ) < (N : ℝ) + l + 1 := by positivity
    have hexp : Real.exp (-((l + 1 : ℕ) : ℝ) ^ 2 / ((N : ℝ) - 2 * L)) =
        Real.exp (-(l : ℝ) ^ 2 / ((N : ℝ) - 2 * L)) *
          Real.exp (-(2 * l + 1) / ((N : ℝ) - 2 * L)) := by
      rw [← Real.exp_add]; congr 1; push_cast; field_simp; ring
    rw [hexp, show N + (l + 1) = N + l + 1 by ring]
    have hC : ((2 * N).choose (N + l + 1) : ℝ) =
        ((2 * N).choose (N + l) : ℝ) * (((N : ℝ) - l) / ((N : ℝ) + l + 1)) := by
      rw [mul_div_assoc', eq_div_iff hpos.ne', hrec']
    rw [hC, ← mul_assoc]
    apply mul_le_mul ih hf (Real.exp_pos _).le (by positivity)

lemma lil_tail_lower {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) (N L0 W : ℕ) (x : ℝ)
    (hx : x ≤ 2 * L0) (hN : 2 * (L0 + W) < N) (hW : N ≤ W ^ 2) :
    ENNReal.ofReal (Real.exp (-((L0 + W : ℕ) : ℝ) ^ 2 / ((N : ℝ) - 2 * (L0 + W : ℕ))) / 2) ≤
      P {ω | x ≤ ∑ i ∈ Finset.range (2 * N), X i ω} := by
  classical
  set F := Finset.univ.filter (fun b : Fin (2 * N) → Bool => x ≤ (lilPS b (2 * N) : ℝ)) with hF
  have e1 : P {ω | x ≤ ∑ i ∈ Finset.range (2 * N), X i ω} =
      P {ω | (fun i : Fin (2 * N) => decide (X i ω = 1)) ∈ F} := by
    apply measure_congr; rw [Filter.eventuallyEqSet_iff]
    filter_upwards [lil_ae_sign P X hstep] with ω hω
    simp only [hF, Finset.mem_filter, Finset.mem_univ, true_and]
    rw [hω (2 * N) (2 * N) le_rfl]
  rw [e1, lil_law P X hmeas hind hfair]
  have hcard : ∑ l ∈ Finset.range W, (2 * N).choose (N + (L0 + l)) ≤ F.card := by
    have hsub : (Finset.range W).biUnion (fun l => Finset.univ.filter
        (fun b : Fin (2 * N) → Bool =>
          lilPS b (2 * N) = 2 * ((N + (L0 + l) : ℕ) : ℤ) - ((2 * N : ℕ) : ℤ))) ⊆ F := by
      intro b hb
      simp only [Finset.mem_biUnion, Finset.mem_filter, Finset.mem_univ, true_and,
        Finset.mem_range] at hb
      obtain ⟨l, _, hb⟩ := hb
      simp only [hF, Finset.mem_filter, Finset.mem_univ, true_and]
      rw [hb]; push_cast
      have hl0 : (0:ℝ) ≤ l := by positivity
      linarith
    calc ∑ l ∈ Finset.range W, (2 * N).choose (N + (L0 + l))
        = ((Finset.range W).biUnion (fun l => Finset.univ.filter
          (fun b : Fin (2 * N) → Bool =>
            lilPS b (2 * N) = 2 * ((N + (L0 + l) : ℕ) : ℤ) - ((2 * N : ℕ) : ℤ)))).card := by
          rw [Finset.card_biUnion]
          · apply Finset.sum_congr rfl; intro l _
            exact (lil_count_eq (2 * N) (N + (L0 + l))).symm
          · intro l1 _ l2 _ hne
            simp only [Function.onFun]
            rw [Finset.disjoint_filter]
            intro b _ h1 h2; apply hne; rw [h1] at h2; push_cast at h2; omega
      _ ≤ F.card := Finset.card_le_card hsub
  -- central binomial
  have hN1 : 1 ≤ N := by omega
  set C0 := (2 * N).choose N with hC0
  have hcb : 4 ^ N ≤ 2 * W * C0 := by
    have h1 := lil_centralBinom N hN1
    rw [Nat.centralBinom_eq_two_mul_choose] at h1
    have h2 : (4 ^ N) ^ 2 ≤ (2 * W * C0) ^ 2 := by
      calc (4 ^ N) ^ 2 = 16 ^ N := by rw [← pow_mul, mul_comm, pow_mul]; norm_num
        _ ≤ 4 * N * C0 ^ 2 := h1
        _ ≤ 4 * W ^ 2 * C0 ^ 2 := by
            apply Nat.mul_le_mul_right; exact Nat.mul_le_mul_left _ hW
        _ = (2 * W * C0) ^ 2 := by ring
    exact (Nat.pow_le_pow_iff_left (by norm_num)).mp h2
  have hcbR : (4 : ℝ) ^ N ≤ 2 * W * C0 := by exact_mod_cast hcb
  set L := L0 + W with hL
  set D : ℝ := (N : ℝ) - 2 * (L : ℕ) with hD
  set E := Real.exp (-((L : ℕ) : ℝ) ^ 2 / D) with hE
  have hsumR : (W : ℝ) * C0 * E ≤ (F.card : ℝ) := by
    calc (W : ℝ) * C0 * E = ∑ l ∈ Finset.range W, (C0 : ℝ) * E := by
          simp [Finset.sum_const]; ring
      _ ≤ ∑ l ∈ Finset.range W, ((2 * N).choose (N + (L0 + l)) : ℝ) := by
          apply Finset.sum_le_sum
          intro l hl
          have hl' : L0 + l ≤ L := by rw [Finset.mem_range] at hl; omega
          have hr := lil_choose_ratio N L (L0 + l) hl' (by omega)
          refine le_trans ?_ hr
          apply mul_le_mul_of_nonneg_left _ (by positivity)
          apply Real.exp_le_exp.mpr
          have hDpos : (0 : ℝ) < D := by
            have : ((2 * L : ℕ) : ℝ) < N := by exact_mod_cast (by omega : 2 * L < N)
            push_cast at this; rw [hD]; linarith
          rw [neg_div, neg_div, neg_le_neg_iff]
          apply div_le_div_of_nonneg_right _ hDpos.le
          have : ((L0 + l : ℕ) : ℝ) ≤ (L : ℝ) := by exact_mod_cast hl'
          have h0 : (0 : ℝ) ≤ ((L0 + l : ℕ) : ℝ) := by positivity
          rw [hD] at *
          nlinarith
      _ = ((∑ l ∈ Finset.range W, (2 * N).choose (N + (L0 + l)) : ℕ) : ℝ) := by push_cast; rfl
      _ ≤ (F.card : ℝ) := by exact_mod_cast hcard
  have hconv : (F.card : ENNReal) / 2 ^ (2 * N) =
      ENNReal.ofReal ((F.card : ℝ) / 2 ^ (2 * N)) := by
    rw [ENNReal.ofReal_div_of_pos (by positivity)]
    simp
  rw [hconv]
  apply ENNReal.ofReal_le_ofReal
  have h4 : (2 : ℝ) ^ (2 * N) = 4 ^ N := by rw [pow_mul]; norm_num
  rw [h4, le_div_iff₀ (by positivity)]
  have hEpos : 0 < E := Real.exp_pos _
  nlinarith

lemma lil_blocks_indep {Ω : Type*} [mΩ : MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (s : ℕ → ℕ) (hs : Monotone s) (x : ℕ → ℝ) :
    iIndepSet (fun k => {ω | x k ≤ ∑ i ∈ Finset.Ico (s k) (s (k + 1)), X i ω}) P := by
  set m : ℕ → MeasurableSpace Ω := fun i => MeasurableSpace.comap (X i) inferInstance with hmdef
  have hm : iIndep m P := (iIndepFun_iff_iIndep _ X P).mp hind
  have hle : ∀ i, m i ≤ mΩ := fun i => (hmeas i).comap_le
  have key : ∀ (T : Set ℕ) (F : Finset ℕ), (↑F : Set ℕ) ⊆ T → ∀ y : ℝ,
      MeasurableSet[⨆ i ∈ T, m i] {ω | y ≤ ∑ i ∈ F, X i ω} := by
    intro T F hF y
    have hf : Measurable[⨆ i ∈ T, m i] (fun ω => ∑ i ∈ F, X i ω) := by
      apply Finset.measurable_sum (m := ⨆ i ∈ T, m i) F
      intro i hi
      exact (comap_measurable (X i)).mono (le_iSup₂ (f := fun j (_ : j ∈ T) => m j) i (hF hi))
        le_rfl
    exact measurableSet_le measurable_const hf
  have hmeasE : ∀ k, MeasurableSet {ω | x k ≤ ∑ i ∈ Finset.Ico (s k) (s (k + 1)), X i ω} :=
    fun k => measurableSet_le measurable_const (Finset.measurable_sum _ (fun i _ => hmeas i))
  rw [iIndepSet_iff_meas_biInter hmeasE]
  intro S
  induction S using Finset.induction_on_max with
  | empty => simp
  | insert a S hlt ih =>
    have haS : a ∉ S := fun h => lt_irrefl a (hlt a h)
    rw [Finset.set_biInter_insert, Finset.prod_insert haS, ← ih]
    have hI := indep_iSup_of_disjoint hle hm (S := Set.Ico (s a) (s (a + 1)))
      (T := Set.Iio (s a)) (by
        rw [Set.disjoint_left]; intro i h1 h2
        exact absurd h1.1 (not_le.mpr h2))
    apply (Indep_iff _ _ _).mp hI
    · exact key _ _ (by rw [Finset.coe_Ico]) _
    · apply MeasurableSet.biInter (Finset.countable_toSet S)
      intro k hk
      apply key
      intro i hi
      rw [Finset.coe_Ico] at hi
      have := hs (Nat.succ_le_of_lt (hlt k hk))
      exact lt_of_lt_of_le hi.2 this

lemma lil_core (c r s T ℓ x L : ℝ) (hr : 0 < r) (hr8 : r ≤ 1 / 8) (hc : 0 < c)
    (hcr : c ≤ 1 - 8 * r) (hs : 2 / r ≤ s) (hT : 0 < T) (hℓ : 0 ≤ ℓ) (hx0 : 0 ≤ x)
    (hx : x ≤ (c * s + 2) * Real.sqrt (2 * T * ℓ)) (hL0 : 0 ≤ L)
    (hL : L ≤ x / 2 + Real.sqrt (T * (s ^ 2 - 1) / 2) + 2)
    (hsmall : 16 * ℓ + 1024 ≤ r ^ 2 * (T * (s ^ 2 - 1) / 2)) :
    2 * L < T * (s ^ 2 - 1) / 2 ∧
      L ^ 2 / (T * (s ^ 2 - 1) / 2 - 2 * L) ≤ ℓ + 4 * (1 + 1 / r) / (1 - r) := by
  have hs16 : 16 ≤ s := by
    have : 16 ≤ 2 / r := by rw [le_div_iff₀ hr]; linarith
    linarith
  have hrs : 2 ≤ r * s := by rw [div_le_iff₀ hr] at hs; linarith
  obtain ⟨N, hN⟩ : ∃ N, N = T * (s ^ 2 - 1) / 2 := ⟨_, rfl⟩
  rw [← hN] at hL hsmall ⊢
  have hs21 : 0 < s ^ 2 - 1 := by nlinarith
  have hNpos : 0 < N := by rw [hN]; positivity
  obtain ⟨u, hu⟩ : ∃ u, u = Real.sqrt N := ⟨_, rfl⟩
  rw [← hu] at hL
  have hu2 : u ^ 2 = N := by rw [hu]; exact Real.sq_sqrt hNpos.le
  have hu0 : 0 ≤ u := by rw [hu]; exact Real.sqrt_nonneg _
  obtain ⟨A, hA⟩ : ∃ A, A = x / 2 := ⟨_, rfl⟩
  rw [← hA] at hL
  have hA0 : 0 ≤ A := by rw [hA]; positivity
  -- A² bound
  have hsq : Real.sqrt (2 * T * ℓ) ^ 2 = 2 * T * ℓ := Real.sq_sqrt (by positivity)
  have hA2 : A ^ 2 ≤ (c * s + 2) ^ 2 * (T * ℓ / 2) := by
    have h1 : x ^ 2 ≤ ((c * s + 2) * Real.sqrt (2 * T * ℓ)) ^ 2 :=
      pow_le_pow_left₀ hx0 hx 2
    rw [mul_pow, hsq] at h1
    have : A ^ 2 = x ^ 2 / 4 := by rw [hA]; ring
    rw [this]; linarith
  have hkey : (1 + r) * (c * s + 2) ^ 2 ≤ (1 - r) * (s ^ 2 - 1) := by
    have e0 : c * s ≤ (1 - 8 * r) * s := mul_le_mul_of_nonneg_right hcr (by linarith)
    have e1 : c * s + 2 ≤ (1 - 7 * r) * s := by linarith
    have e1' : 0 ≤ c * s + 2 := by positivity
    have e2 : (c * s + 2) ^ 2 ≤ (1 - 7 * r) ^ 2 * s ^ 2 := by
      have := pow_le_pow_left₀ e1' e1 2; rw [mul_pow] at this; exact this
    have e3 : (1 + r) * (1 - 7 * r) ^ 2 ≤ 1 - 6 * r := by
      have h7 : 0 ≤ 1 - 7 * r := by linarith
      have : (1 + r) * (1 - 7 * r) = 1 - 6 * r - 7 * r ^ 2 := by ring
      have h8 : (1 + r) * (1 - 7 * r) ≤ 1 - 6 * r := by nlinarith
      calc (1 + r) * (1 - 7 * r) ^ 2 = ((1 + r) * (1 - 7 * r)) * (1 - 7 * r) := by ring
        _ ≤ (1 - 6 * r) * (1 - 7 * r) := mul_le_mul_of_nonneg_right h8 h7
        _ ≤ (1 - 6 * r) * 1 := mul_le_mul_of_nonneg_left (by linarith) (by linarith)
        _ = 1 - 6 * r := by ring
    have e4 : 1 - r ≤ 5 * r * s ^ 2 := by
      have : 2 * s ≤ r * s * s := mul_le_mul_of_nonneg_right hrs (by linarith)
      have : r * s * s = r * s ^ 2 := by ring
      linarith
    have e5 : (1 + r) * (c * s + 2) ^ 2 ≤ (1 - 6 * r) * s ^ 2 := by
      calc (1 + r) * (c * s + 2) ^ 2 ≤ (1 + r) * ((1 - 7 * r) ^ 2 * s ^ 2) :=
            mul_le_mul_of_nonneg_left e2 (by linarith)
        _ = ((1 + r) * (1 - 7 * r) ^ 2) * s ^ 2 := by ring
        _ ≤ (1 - 6 * r) * s ^ 2 := mul_le_mul_of_nonneg_right e3 (by positivity)
    have : (1 - r) * (s ^ 2 - 1) = (1 - 6 * r) * s ^ 2 + (5 * r * s ^ 2 - (1 - r)) := by ring
    linarith
  have hA2' : (1 + r) * A ^ 2 ≤ (1 - r) * ℓ * N := by
    calc (1 + r) * A ^ 2 ≤ (1 + r) * ((c * s + 2) ^ 2 * (T * ℓ / 2)) :=
          mul_le_mul_of_nonneg_left hA2 (by linarith)
      _ = ((1 + r) * (c * s + 2) ^ 2) * (T * ℓ / 2) := by ring
      _ ≤ ((1 - r) * (s ^ 2 - 1)) * (T * ℓ / 2) :=
          mul_le_mul_of_nonneg_right hkey (by positivity)
      _ = (1 - r) * ℓ * N := by rw [hN]; ring
  have hA2'' : A ^ 2 ≤ ℓ * N := by
    have h1 : 0 ≤ r * A ^ 2 := by positivity
    have h2 : 0 ≤ r * ℓ * N := by positivity
    have : (1 + r) * A ^ 2 = A ^ 2 + r * A ^ 2 := by ring
    have : (1 - r) * ℓ * N = ℓ * N - r * ℓ * N := by ring
    linarith
  have hℓN : ℓ ≤ r ^ 2 * N / 16 := by linarith
  have hAr : A ≤ r * N / 4 := by
    have : A ^ 2 ≤ (r * N / 4) ^ 2 := by
      calc A ^ 2 ≤ ℓ * N := hA2''
        _ ≤ r ^ 2 * N / 16 * N := mul_le_mul_of_nonneg_right hℓN hNpos.le
        _ = (r * N / 4) ^ 2 := by ring
    exact (pow_le_pow_iff_left₀ hA0 (by positivity) two_ne_zero).mp this
  have hu32 : 32 ≤ r * u := by
    have : (32 : ℝ) ^ 2 ≤ (r * u) ^ 2 := by rw [mul_pow, hu2]; linarith
    exact (pow_le_pow_iff_left₀ (by norm_num) (by positivity) two_ne_zero).mp this
  have hNu : N = u * u := by rw [← hu2]; ring
  have hu_le : 2 * u ≤ r * N / 16 := by
    have : 32 * u ≤ r * u * u := mul_le_mul_of_nonneg_right hu32 hu0
    have : r * N = r * u * u := by rw [hNu]; ring
    linarith
  have hLA : L ≤ A + 2 * u := by
    have : r * u ≤ 1 / 8 * u := mul_le_mul_of_nonneg_right hr8 hu0
    linarith
  have h2L : 2 * L ≤ r * N := by linarith
  have hrN : r * N < N := by
    have : r * N < 1 * N := mul_lt_mul_of_pos_right (by linarith) hNpos
    linarith
  refine ⟨by linarith, ?_⟩
  have hden : (1 - r) * N ≤ N - 2 * L := by linarith
  have hden0 : 0 < (1 - r) * N := by
    have : 0 < 1 - r := by linarith
    positivity
  have hL2 : L ^ 2 ≤ (1 - r) * ℓ * N + 4 * (1 + 1 / r) * N := by
    have h1 : L ^ 2 ≤ (A + 2 * u) ^ 2 := pow_le_pow_left₀ hL0 hLA 2
    have hy : 2 * A * (2 * u) ≤ r * A ^ 2 + (2 * u) ^ 2 / r := by
      have : r * A ^ 2 + (2 * u) ^ 2 / r - 2 * A * (2 * u) = (r * A - 2 * u) ^ 2 / r := by
        field_simp; ring
      have : 0 ≤ (r * A - 2 * u) ^ 2 / r := by positivity
      linarith
    have h5 : (2 * u) ^ 2 = 4 * N := by rw [mul_pow, hu2]; ring
    have h6 : (A + 2 * u) ^ 2 = A ^ 2 + 2 * A * (2 * u) + (2 * u) ^ 2 := by ring
    have h7 : (2 * u) ^ 2 / r = 4 * (1 / r) * N := by rw [h5]; ring
    have h8 : 4 * (1 + 1 / r) * N = 4 * N + 4 * (1 / r) * N := by ring
    linarith
  calc L ^ 2 / (N - 2 * L) ≤ L ^ 2 / ((1 - r) * N) :=
        div_le_div_of_nonneg_left (by positivity) hden0 hden
    _ ≤ ((1 - r) * ℓ * N + 4 * (1 + 1 / r) * N) / ((1 - r) * N) :=
        div_le_div_of_nonneg_right hL2 hden0.le
    _ = ℓ + 4 * (1 + 1 / r) / (1 - r) := by
        have : (1 - r) ≠ 0 := by linarith
        field_simp

lemma lil_neg_hyps {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) :
    (∀ i, Measurable (fun ω => -X i ω)) ∧ iIndepFun (fun i ω => -X i ω) P ∧
      (∀ i, ∀ᵐ ω ∂P, -X i ω = 1 ∨ -X i ω = -1) ∧ (∀ i, P {ω | -X i ω = 1} = 1 / 2) := by
  refine ⟨fun i => (hmeas i).neg, hind.comp (fun _ x => -x) (fun _ => measurable_neg),
    fun i => ?_, fun i => ?_⟩
  · filter_upwards [hstep i] with ω h; rcases h with h | h <;> simp [h]
  · have hm1 : MeasurableSet {ω | X i ω = 1} := (hmeas i) (measurableSet_singleton 1)
    have : {ω | -X i ω = 1} =ᵐ[P] ({ω | X i ω = 1}ᶜ : Set Ω) := by
      rw [Filter.eventuallyEqSet_iff]
      filter_upwards [hstep i] with ω h
      rcases h with h | h <;> simp [h] <;> norm_num
    rw [measure_congr this, measure_compl hm1 (measure_ne_top _ _), measure_univ, hfair i,
      one_div, ENNReal.one_sub_inv_two]

lemma lil_block_prob {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2)
    (c r : ℝ) (hr0 : 0 < r) (hr8 : r ≤ 1 / 8) (hc0 : 0 < c) (hcr : c ≤ 1 - 8 * r)
    (q θ : ℕ) (hqr : 1 / r ≤ (q : ℝ)) (hθ : θ = 4 * q ^ 2) (k : ℕ) (hk1 : 1 ≤ k)
    (hkθ : (k : ℝ) * (1072 * θ) ≤ r ^ 2 * (θ : ℝ) ^ k) :
    ENNReal.ofReal (Real.exp (-(4 * (1 + 1 / r) / (1 - r))) / 2 /
        ((k + 2) * Real.log θ)) ≤
      P {ω | c * Real.sqrt (2 * ((θ ^ (k + 1 + 1) : ℕ) : ℝ) *
              Real.log (Real.log ((θ ^ (k + 1 + 1) : ℕ) : ℝ))) +
            2 * Real.sqrt (2 * ((θ ^ (k + 1) : ℕ) : ℝ) *
              Real.log (Real.log ((θ ^ (k + 1) : ℕ) : ℝ))) ≤
        ∑ i ∈ Finset.Ico (θ ^ (k + 1)) (θ ^ (k + 1 + 1)), X i ω} := by
  have h8r : 8 ≤ 1 / r := by rw [le_div_iff₀ hr0]; linarith
  have hq8 : (8 : ℝ) ≤ q := le_trans h8r hqr
  have hq1 : 1 ≤ q := by
    have : (1 : ℝ) ≤ q := by linarith
    exact_mod_cast this
  have hθ4 : 4 ≤ θ := by rw [hθ]; nlinarith
  have hθR : (θ : ℝ) = 4 * (q : ℝ) ^ 2 := by rw [hθ]; push_cast; ring
  have hθ4R : (4 : ℝ) ≤ θ := by exact_mod_cast hθ4
  have hlogθ : 1 < Real.log θ :=
    lt_of_lt_of_le lil_log3 (Real.log_le_log (by norm_num) (by linarith))
  -- the block length
  set N : ℕ := 2 * q ^ 2 * θ ^ k * (θ - 1) with hN
  have hlen : θ ^ (k + 1 + 1) - θ ^ (k + 1) = 2 * N := by
    have h1 : θ ^ (k + 1) ≤ θ ^ (k + 1 + 1) := Nat.pow_le_pow_right (by omega) (by omega)
    have h2 : 1 ≤ θ := by omega
    rw [hN]
    zify [h1, h2]
    rw [hθ]; push_cast; ring
  set T : ℝ := (θ : ℝ) ^ (k + 1) with hT
  have hTpos : 0 < T := by positivity
  set s : ℝ := 2 * (q : ℝ) with hs
  have hNR : (N : ℝ) = T * (s ^ 2 - 1) / 2 := by
    rw [hN, hT, hs]
    push_cast [Nat.cast_sub (by omega : 1 ≤ θ)]
    rw [hθR]; ring
  set ℓ : ℝ := Real.log ((k + 2) * Real.log θ) with hℓ
  have hkl : 1 ≤ ((k : ℝ) + 2) * Real.log θ := by
    have : (1 : ℝ) ≤ (k : ℝ) + 2 := by linarith [(Nat.cast_nonneg k : (0 : ℝ) ≤ k)]
    nlinarith
  have hℓ0 : 0 ≤ ℓ := Real.log_nonneg hkl
  set x : ℝ := c * Real.sqrt (2 * ((θ ^ (k + 1 + 1) : ℕ) : ℝ) *
              Real.log (Real.log ((θ ^ (k + 1 + 1) : ℕ) : ℝ))) +
            2 * Real.sqrt (2 * ((θ ^ (k + 1) : ℕ) : ℝ) *
              Real.log (Real.log ((θ ^ (k + 1) : ℕ) : ℝ))) with hxdef
  have hx0 : 0 ≤ x := by positivity
  have hx : x ≤ (c * s + 2) * Real.sqrt (2 * T * ℓ) := by
    have e1 : Real.sqrt (2 * ((θ ^ (k + 1 + 1) : ℕ) : ℝ) *
        Real.log (Real.log ((θ ^ (k + 1 + 1) : ℕ) : ℝ))) = s * Real.sqrt (2 * T * ℓ) := by
      have hlog : Real.log ((θ ^ (k + 1 + 1) : ℕ) : ℝ) = ((k : ℝ) + 2) * Real.log θ := by
        push_cast; rw [Real.log_pow]; push_cast; ring
      rw [hlog]
      have : 2 * ((θ ^ (k + 1 + 1) : ℕ) : ℝ) * ℓ = s ^ 2 * (2 * T * ℓ) := by
        rw [hT, hs]; push_cast; rw [hθR]; ring
      rw [this, Real.sqrt_mul (sq_nonneg s), Real.sqrt_sq (by positivity)]
    have e2 : Real.sqrt (2 * ((θ ^ (k + 1) : ℕ) : ℝ) *
        Real.log (Real.log ((θ ^ (k + 1) : ℕ) : ℝ))) ≤ Real.sqrt (2 * T * ℓ) := by
      apply Real.sqrt_le_sqrt
      have hlog : Real.log ((θ ^ (k + 1) : ℕ) : ℝ) = ((k : ℝ) + 1) * Real.log θ := by
        push_cast; rw [Real.log_pow]; push_cast; ring
      rw [hlog]
      have hT' : ((θ ^ (k + 1) : ℕ) : ℝ) = T := by rw [hT]; push_cast; ring
      rw [hT']
      apply mul_le_mul_of_nonneg_left _ (by positivity)
      apply Real.log_le_log (by positivity)
      nlinarith
    rw [hxdef, e1]
    have : 2 * Real.sqrt (2 * ((θ ^ (k + 1) : ℕ) : ℝ) *
        Real.log (Real.log ((θ ^ (k + 1) : ℕ) : ℝ))) ≤ 2 * Real.sqrt (2 * T * ℓ) := by linarith
    nlinarith
  -- smallness
  have hθk : (θ : ℝ) ^ k ≤ (N : ℝ) := by
    rw [hNR, hT, pow_succ]
    have hs2 : s ^ 2 = θ := by rw [hs, hθR]; ring
    rw [hs2]
    have : 1 ≤ (θ : ℝ) * (θ - 1) / 2 := by nlinarith
    have hp : 0 ≤ (θ : ℝ) ^ k := by positivity
    nlinarith
  have hℓθ : ℓ ≤ ((k : ℝ) + 2) * θ := by
    have h1 : ℓ ≤ ((k : ℝ) + 2) * Real.log θ - 1 := Real.log_le_sub_one_of_pos (by linarith)
    have h2 : Real.log θ ≤ θ := by
      have := Real.log_le_sub_one_of_pos (by linarith : (0 : ℝ) < θ); linarith
    have : ((k : ℝ) + 2) * Real.log θ ≤ ((k : ℝ) + 2) * θ :=
      mul_le_mul_of_nonneg_left h2 (by positivity)
    linarith
  have hsmall : 16 * ℓ + 1024 ≤ r ^ 2 * (T * (s ^ 2 - 1) / 2) := by
    rw [← hNR]
    have hk1R : (1 : ℝ) ≤ k := by exact_mod_cast hk1
    have h1 : 16 * ℓ + 1024 ≤ (k : ℝ) * (1072 * θ) := by nlinarith
    have h2 : r ^ 2 * (θ : ℝ) ^ k ≤ r ^ 2 * N := mul_le_mul_of_nonneg_left hθk (by positivity)
    linarith
  -- the window
  set L0 : ℕ := ⌈x / 2⌉₊ with hL0
  set W : ℕ := Nat.sqrt N + 1 with hW
  have hxL0 : x ≤ 2 * (L0 : ℝ) := by have := Nat.le_ceil (x / 2); rw [hL0]; linarith
  have hWN : N ≤ W ^ 2 := (Nat.lt_succ_sqrt' N).le
  have hLle : ((L0 + W : ℕ) : ℝ) ≤ x / 2 + Real.sqrt (T * (s ^ 2 - 1) / 2) + 2 := by
    have h1 : (L0 : ℝ) < x / 2 + 1 := Nat.ceil_lt_add_one (by positivity)
    have h2 : (Nat.sqrt N : ℝ) ≤ Real.sqrt N := Real.nat_sqrt_le_real_sqrt
    rw [← hNR]; push_cast; rw [hW]; push_cast; linarith
  obtain ⟨hcore1, hcore2⟩ := lil_core c r s T ℓ x ((L0 + W : ℕ) : ℝ) hr0 hr8 hc0 hcr
    (by rw [hs, div_le_iff₀ hr0]; rw [div_le_iff₀ hr0] at hqr; linarith)
    hTpos hℓ0 hx0 hx (by positivity) hLle hsmall
  rw [← hNR] at hcore1 hcore2
  have hNnat : 2 * (L0 + W) < N := by
    have : ((2 * (L0 + W) : ℕ) : ℝ) < N := by push_cast at hcore1 ⊢; linarith
    exact_mod_cast this
  -- the shifted walk
  set Y : ℕ → Ω → ℝ := fun i => X (θ ^ (k + 1) + i) with hY
  have hindY : iIndepFun Y P := hind.precomp (add_right_injective _)
  have htail := lil_tail_lower P Y (fun i => hmeas _) hindY (fun i => hstep _) (fun i => hfair _)
    N L0 W x hxL0 hNnat hWN
  have hset : {ω | x ≤ ∑ i ∈ Finset.Ico (θ ^ (k + 1)) (θ ^ (k + 1 + 1)), X i ω} =
      {ω | x ≤ ∑ i ∈ Finset.range (2 * N), Y i ω} := by
    ext ω; simp only [Set.mem_ofPred_eq]
    rw [Finset.sum_Ico_eq_sum_range, hlen]
  rw [hset]
  refine le_trans (ENNReal.ofReal_le_ofReal ?_) htail
  -- real inequality
  set C : ℝ := 4 * (1 + 1 / r) / (1 - r)
  have hpos : 0 < ((k : ℝ) + 2) * Real.log θ := by linarith
  have e1 : Real.exp (-C) / 2 / (((k : ℝ) + 2) * Real.log θ) = Real.exp (-(ℓ + C)) / 2 := by
    rw [neg_add, Real.exp_add, Real.exp_neg ℓ, hℓ, Real.exp_log hpos]
    field_simp
  rw [e1]
  apply div_le_div_of_nonneg_right _ (by norm_num)
  apply Real.exp_le_exp.mpr
  rw [neg_div]
  exact neg_le_neg hcore2

lemma lil_lower {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) (c : ℝ) (hc0 : 0 < c) (hc1 : c < 1) :
    ∀ᵐ ω ∂P, ∃ᶠ n : ℕ in atTop,
      c * Real.sqrt (2 * n * Real.log (Real.log n)) ≤ ∑ i ∈ Finset.range n, X i ω := by
  set r : ℝ := (1 - c) / 8 with hr
  have hr0 : 0 < r := by rw [hr]; linarith
  have hr8 : r ≤ 1 / 8 := by rw [hr]; linarith
  have hcr : c ≤ 1 - 8 * r := by rw [hr]; linarith
  set q : ℕ := ⌈1 / r⌉₊ + 1 with hq
  have hqr : 1 / r ≤ (q : ℝ) := by
    have := Nat.le_ceil (1 / r); rw [hq]; push_cast; linarith
  set θ : ℕ := 4 * q ^ 2 with hθ
  have hθ2 : 2 ≤ θ := by
    have : 1 ≤ q := by omega
    rw [hθ]; nlinarith
  have hθR1 : (1 : ℝ) < θ := by exact_mod_cast (by omega : 1 < θ)
  have hlogθ : 0 < Real.log θ := Real.log_pos hθR1
  set A : ℕ → Set Ω := fun k => {ω |
      c * Real.sqrt (2 * ((θ ^ (k + 1 + 1) : ℕ) : ℝ) *
          Real.log (Real.log ((θ ^ (k + 1 + 1) : ℕ) : ℝ))) +
        2 * Real.sqrt (2 * ((θ ^ (k + 1) : ℕ) : ℝ) *
          Real.log (Real.log ((θ ^ (k + 1) : ℕ) : ℝ))) ≤
      ∑ i ∈ Finset.Ico (θ ^ (k + 1)) (θ ^ (k + 1 + 1)), X i ω} with hA
  have hAind : iIndepSet A P := lil_blocks_indep P X hmeas hind (fun k => θ ^ (k + 1))
      (fun a b hab => Nat.pow_le_pow_right (by omega) (by omega)) _
  have hAmeas : ∀ k, MeasurableSet (A k) := fun k =>
      measurableSet_le measurable_const (Finset.measurable_sum _ (fun i _ => hmeas i))
  set C : ℝ := 4 * (1 + 1 / r) / (1 - r) with hC
  set g : ℕ → ℝ := fun k => Real.exp (-C) / 2 / ((k + 2) * Real.log θ) with hg
  have hev : ∀ᶠ k : ℕ in atTop, 1 ≤ k ∧ (k : ℝ) * (1072 * θ) ≤ r ^ 2 * (θ : ℝ) ^ k := by
    have ht := tendsto_pow_const_div_const_pow_of_one_lt 1 hθR1
    have hpos : (0 : ℝ) < r ^ 2 / (1072 * θ) := by positivity
    filter_upwards [eventually_ge_atTop 1, ht.eventually (gt_mem_nhds hpos)] with k hk1 hk
    refine ⟨hk1, ?_⟩
    simp only [pow_one] at hk
    rw [div_lt_div_iff₀ (by positivity) (by positivity)] at hk
    linarith
  obtain ⟨K, hK⟩ := eventually_atTop.mp hev
  have hPA : ∀ k ≥ K, ENNReal.ofReal (g k) ≤ P (A k) := fun k hk =>
    lil_block_prob P X hmeas hind hstep hfair c r hr0 hr8 hc0 hcr q θ hqr rfl k
      (hK k hk).1 (hK k hk).2
  have hdiv : ∑' k, P (A k) = ⊤ := by
    by_contra hne
    have hsum := ENNReal.summable_toReal hne
    have hgs : Summable (fun k => g (k + K)) := by
      refine Summable.of_nonneg_of_le (fun k => ?_) (fun k => ?_)
        ((summable_nat_add_iff K).mpr hsum)
      · simp only [hg]; positivity
      · have := hPA (k + K) (by omega)
        rw [← ENNReal.ofReal_toReal (measure_ne_top P (A (k + K)))] at this
        exact (ENNReal.ofReal_le_ofReal_iff ENNReal.toReal_nonneg).mp this
    have hg' : Summable g := (summable_nat_add_iff K).mp hgs
    have h2 : Summable (fun k : ℕ => 1 / ((k + 2 : ℕ) : ℝ)) := by
      have := hg'.mul_left (Real.exp (-C) / 2 / Real.log θ)⁻¹
      convert this using 1
      ext k
      simp only [hg]
      push_cast
      field_simp
    exact Real.not_summable_one_div_natCast ((summable_nat_add_iff 2).mp h2)
  have hlim := measure_limsup_eq_one hAmeas hAind hdiv
  have hae1 : ∀ᵐ ω ∂P, ∃ᶠ k in atTop, ω ∈ A k := by
    have : ∀ᵐ ω ∂P, ω ∈ limsup A atTop := by
      rw [ae_mem_iff_measure_eq (MeasurableSet.measurableSet_limsup hAmeas).nullMeasurableSet, hlim,
        measure_univ]
    filter_upwards [this] with ω hω
    exact mem_limsup_iff_frequently_mem.mp hω
  obtain ⟨hm', hi', hs', hf'⟩ := lil_neg_hyps P X hmeas hind hstep hfair
  have hup := lil_upper P (fun i ω => -X i ω) hm' hi' hs' hf' 2 (by norm_num)
  filter_upwards [hae1, hup] with ω hω1 hω2
  have hge : ∀ k : ℕ, k ≤ θ ^ k := fun k => (Nat.lt_pow_self (by omega)).le
  have htend : Tendsto (fun k : ℕ => θ ^ (k + 1)) atTop atTop :=
    tendsto_atTop_mono (fun k => le_trans (Nat.le_succ k) (hge (k + 1))) tendsto_id
  have htend2 : Tendsto (fun k : ℕ => θ ^ (k + 1 + 1)) atTop atTop :=
    tendsto_atTop_mono (fun k => le_trans (Nat.le_add_right k 2) (hge (k + 1 + 1))) tendsto_id
  have hev2 := htend.eventually hω2
  apply htend2.frequently
  refine (hω1.and_eventually hev2).mono ?_
  rintro k ⟨hAk, hneg⟩
  simp only [hA, Set.mem_ofPred_eq] at hAk
  have hle : θ ^ (k + 1) ≤ θ ^ (k + 1 + 1) := Nat.pow_le_pow_right (by omega) (by omega)
  rw [← Finset.sum_range_add_sum_Ico _ hle]
  have hneg' : -∑ i ∈ Finset.range (θ ^ (k + 1)), X i ω ≤
      2 * Real.sqrt (2 * ((θ ^ (k + 1) : ℕ) : ℝ) *
          Real.log (Real.log ((θ ^ (k + 1) : ℕ) : ℝ))) := by
    rw [← Finset.sum_neg_distrib]; exact hneg
  linarith

lemma lil_limsup {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) :
    ∀ᵐ ω ∂P, limsup (fun n : ℕ => (((∑ i ∈ Finset.range n, X i ω) /
        Real.sqrt (2 * n * Real.log (Real.log n)) : ℝ) : EReal)) atTop = 1 := by
  have hU : ∀ᵐ ω ∂P, ∀ j : ℕ, ∀ᶠ n : ℕ in atTop, ∑ i ∈ Finset.range n, X i ω ≤
      (1 + 1 / ((j : ℝ) + 1)) * Real.sqrt (2 * n * Real.log (Real.log n)) := by
    rw [ae_all_iff]; intro j
    have : (0 : ℝ) < 1 / ((j : ℝ) + 1) := by positivity
    exact lil_upper P X hmeas hind hstep hfair _ (by linarith)
  have hL : ∀ᵐ ω ∂P, ∀ j : ℕ, ∃ᶠ n : ℕ in atTop,
      (1 - 1 / ((j : ℝ) + 1) / 2) * Real.sqrt (2 * n * Real.log (Real.log n)) ≤
        ∑ i ∈ Finset.range n, X i ω := by
    rw [ae_all_iff]; intro j
    have h0 : (0 : ℝ) < 1 / ((j : ℝ) + 1) := by positivity
    have h1 : 1 / ((j : ℝ) + 1) ≤ 1 := by
      rw [div_le_one (by positivity)]; linarith [(Nat.cast_nonneg j : (0 : ℝ) ≤ j)]
    exact lil_lower P X hmeas hind hstep hfair _ (by linarith) (by linarith)
  filter_upwards [hU, hL] with ω hU hL
  have hpos : ∀ᶠ n : ℕ in atTop, 0 < Real.sqrt (2 * n * Real.log (Real.log n)) := by
    filter_upwards [eventually_ge_atTop 3] with n hn
    apply Real.sqrt_pos.mpr
    have h3 : (3 : ℝ) ≤ n := by exact_mod_cast hn
    have : 1 < Real.log n := lt_of_lt_of_le lil_log3 (Real.log_le_log (by norm_num) h3)
    have : 0 < Real.log (Real.log n) := Real.log_pos this
    positivity
  have ht0 : Tendsto (fun n : ℕ => 1 / ((n : ℝ) + 1)) atTop (nhds 0) :=
    tendsto_one_div_add_atTop_nhds_zero_nat
  apply le_antisymm
  · have hj : ∀ j : ℕ, limsup (fun n : ℕ => (((∑ i ∈ Finset.range n, X i ω) /
        Real.sqrt (2 * n * Real.log (Real.log n)) : ℝ) : EReal)) atTop ≤
          ((1 + 1 / ((j : ℝ) + 1) : ℝ) : EReal) := by
      intro j
      refine limsup_le_of_le (by isBoundedDefault) ?_
      filter_upwards [hU j, hpos] with n h1 h2
      rw [EReal.coe_le_coe_iff, div_le_iff₀ h2]; exact h1
    have ht : Tendsto (fun j : ℕ => ((1 + 1 / ((j : ℝ) + 1) : ℝ) : EReal)) atTop (nhds 1) := by
      rw [← EReal.coe_one, EReal.tendsto_coe]
      simpa using (tendsto_const_nhds (x := (1 : ℝ))).add ht0
    exact ge_of_tendsto' ht hj
  · have hj : ∀ j : ℕ, ((1 - 1 / ((j : ℝ) + 1) / 2 : ℝ) : EReal) ≤
        limsup (fun n : ℕ => (((∑ i ∈ Finset.range n, X i ω) /
          Real.sqrt (2 * n * Real.log (Real.log n)) : ℝ) : EReal)) atTop := by
      intro j
      refine le_limsup_of_frequently_le (((hL j).and_eventually hpos).mono ?_) (by isBoundedDefault)
      rintro n ⟨h1, h2⟩
      rw [EReal.coe_le_coe_iff, le_div_iff₀ h2]; exact h1
    have ht : Tendsto (fun j : ℕ => ((1 - 1 / ((j : ℝ) + 1) / 2 : ℝ) : EReal)) atTop (nhds 1) := by
      rw [← EReal.coe_one, EReal.tendsto_coe]
      simpa using (tendsto_const_nhds (x := (1 : ℝ))).sub (ht0.div_const 2)
    exact le_of_tendsto' ht hj

/-- **The law of the iterated logarithm for a fair walk (Khinchin, 1924).** Let the steps
`X 0, X 1, X 2, …` be independent random variables, each equal to +1 or -1 with chance 1/2.
Let `S n = X 0 + ⋯ + X (n-1)` be the walk after `n` steps and `h n = √(2 n ln ln n)` its
envelope. Then with probability 1 the ratio `S n / h n` has largest limit point 1 and
smallest limit point -1: for every `c > 1` the walk is above `c h n` only finitely often,
and for every `c < 1` it is above `c h n` infinitely often (and the same below, for `-S n`). -/
theorem law_of_the_iterated_logarithm {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) :
    ∀ᵐ ω ∂P,
      limsup (fun n : ℕ => (((∑ i ∈ Finset.range n, X i ω) /
          Real.sqrt (2 * n * Real.log (Real.log n)) : ℝ) : EReal)) atTop = 1 ∧
      liminf (fun n : ℕ => (((∑ i ∈ Finset.range n, X i ω) /
          Real.sqrt (2 * n * Real.log (Real.log n)) : ℝ) : EReal)) atTop = -1 := by
  obtain ⟨hm', hi', hs', hf'⟩ := lil_neg_hyps P X hmeas hind hstep hfair
  filter_upwards [lil_limsup P X hmeas hind hstep hfair, lil_limsup P _ hm' hi' hs' hf']
    with ω h1 h2
  refine ⟨h1, ?_⟩
  have h2' : limsup (fun n : ℕ => (((∑ i ∈ Finset.range n, -X i ω) /
      Real.sqrt (2 * n * Real.log (Real.log n)) : ℝ) : EReal)) atTop = 1 := h2
  have e : (fun n : ℕ => (((∑ i ∈ Finset.range n, X i ω) /
      Real.sqrt (2 * n * Real.log (Real.log n)) : ℝ) : EReal)) =
      -(fun n : ℕ => (((∑ i ∈ Finset.range n, -X i ω) /
        Real.sqrt (2 * n * Real.log (Real.log n)) : ℝ) : EReal)) := by
    ext n
    simp only [Pi.neg_apply, Finset.sum_neg_distrib, neg_div, EReal.coe_neg, neg_neg]
  rw [e, EReal.liminf_neg, h2']

/-- **The maximal bound (Steps 1 and 2).** For the same fair walk, every number of steps `n`
and every level `a ≥ 0`, the chance that the running maximum `max (S 1, …, S n)` reaches `a`
is at most `2 e^(-a²/2n)`. -/
theorem fair_walk_maximal_bound {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) (n : ℕ) (a : ℝ) (ha : 0 ≤ a) :
    P {ω | ∃ k ∈ Finset.Icc 1 n, a ≤ ∑ i ∈ Finset.range k, X i ω} ≤
      ENNReal.ofReal (2 * Real.exp (-a ^ 2 / (2 * n))) := by
  exact lil_maximal_aux P X hmeas hind hstep hfair n a ha

/-- **The reflection principle (Step 2).** For the same fair walk and a whole-number level
`a ≥ 1`, the chance that the running maximum `max (S 1, …, S n)` reaches `a` equals the chance
that the walk ends at or above `a` plus the chance that it ends above `a`. -/
theorem fair_walk_reflection_principle {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (hind : iIndepFun X P)
    (hstep : ∀ i, ∀ᵐ ω ∂P, X i ω = 1 ∨ X i ω = -1)
    (hfair : ∀ i, P {ω | X i ω = 1} = 1 / 2) (n a : ℕ) (ha : 1 ≤ a) :
    P {ω | ∃ k ∈ Finset.Icc 1 n, (a : ℝ) ≤ ∑ i ∈ Finset.range k, X i ω} =
      P {ω | (a : ℝ) ≤ ∑ i ∈ Finset.range n, X i ω} +
        P {ω | (a : ℝ) < ∑ i ∈ Finset.range n, X i ω} := by
  exact lil_reflection_aux P X hmeas hind hstep hfair n a ha

/-! ### The card's whole-number checks -/

/-- Add `c` paths to the entry with key `k` (position, maximum so far) of a count table. -/
def walkAdd (k : ℤ × ℤ) (c : ℕ) : List ((ℤ × ℤ) × ℕ) → List ((ℤ × ℤ) × ℕ)
  | [] => [(k, c)]
  | e :: es => if e.1 = k then (k, e.2 + c) :: es else e :: walkAdd k c es

/-- The exact table over (position, maximum so far, from 0) of all ±1 paths of `n` steps. -/
def walkTable : ℕ → List ((ℤ × ℤ) × ℕ)
  | 0 => [((0, 0), 1)]
  | n + 1 => (walkTable n).foldl (fun acc e =>
      walkAdd (e.1.1 - 1, e.1.2) e.2 (walkAdd (e.1.1 + 1, max e.1.2 (e.1.1 + 1)) e.2 acc)) []

/-- The number of paths of `n` steps whose (position, maximum) pair passes the test `q`. -/
def walkCount (n : ℕ) (q : (ℤ × ℤ) → Bool) : ℕ :=
  ((walkTable n).filter (fun e => q e.1)).foldl (· + ·.2) 0

-- The table for 14 steps holds all 2^14 = 16384 paths.
example : walkCount 14 (fun _ => true) = 16384 := by decide +kernel
-- Reflection on every path of 14 steps: for each whole level a = 1, …, 14, the paths whose
-- maximum reaches a number those ending at or above a plus those ending above a.
example : ∀ a ∈ List.range' 1 14,
    walkCount 14 (fun e => decide (a ≤ e.2)) =
      walkCount 14 (fun e => decide (a ≤ e.1)) + walkCount 14 (fun e => decide (a < e.1)) := by
  decide +kernel
-- cosh t ≤ e^(t²/2) term by term: (2r)! ≥ 2^r r!, for r = 0, …, 12.
example : ∀ r ∈ List.range 13, 2 ^ r * Nat.factorial r ≤ Nat.factorial (2 * r) := by
  decide +kernel
-- The CLT scale at a million steps: √(10^6) = 1000.
example : (1000 : ℕ) ^ 2 = 10 ^ 6 := by norm_num
-- The worked case c = 1.5, θ = 2: the power c²/θ is 9/8, which is above 1.
example : ((3 / 2 : ℚ) ^ 2 / 2 = 9 / 8) ∧ (1 : ℚ) < 9 / 8 := by norm_num
-- The checkpoint n_20 = 2^20 = 1,048,576.
example : (2 : ℕ) ^ 20 = 1048576 := by norm_num
-- The shelf's die: mean 7/2 and variance 35/12.
example : (∑ k ∈ Finset.range 6, ((k : ℚ) + 1)) / 6 = 7 / 2 := by
  simp [Finset.sum_range_succ]; norm_num
example : (∑ k ∈ Finset.range 6, ((k : ℚ) + 1 - 7 / 2) ^ 2) / 6 = 35 / 12 := by
  simp [Finset.sum_range_succ]; norm_num

#print axioms lilPS_zero
#print axioms lilPS_cons
#print axioms lil_card_cons
#print axioms lilPS_abs_le
#print axioms lil_h_succ
#print axioms lil_g_succ
#print axioms lil_h_symm
#print axioms lil_g_zero
#print axioms lil_reflection_count
#print axioms lil_law
#print axioms lil_ae_sign
#print axioms lil_reflection_aux
#print axioms lil_subG
#print axioms lil_hoeffding
#print axioms lil_maximal_aux
#print axioms lil_log3
#print axioms lil_h_mono
#print axioms lil_upper
#print axioms lil_count_eq
#print axioms lil_centralBinom
#print axioms lil_factor
#print axioms lil_choose_ratio
#print axioms lil_tail_lower
#print axioms lil_blocks_indep
#print axioms lil_core
#print axioms lil_neg_hyps
#print axioms lil_block_prob
#print axioms lil_lower
#print axioms lil_limsup
#print axioms law_of_the_iterated_logarithm
#print axioms fair_walk_maximal_bound
#print axioms fair_walk_reflection_principle
