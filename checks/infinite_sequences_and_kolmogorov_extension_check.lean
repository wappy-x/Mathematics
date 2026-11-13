-- Infinitely many coin tosses: under length on [0, 1) the binary digits of a point are independent fair coins, dealing them into disjoint piles gives independent uniforms and hence independent draws of any law, and every consistent family of laws on the first n coordinates of a real sequence comes from exactly one probability on whole sequences.
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.CDF
import Mathlib.Data.Fin.Tuple.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Order.Floor.Semifield
import Mathlib.MeasureTheory.Function.Floor
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Probability.Independence.InfinitePi
import Mathlib.Probability.ProductMeasure
import Mathlib.Probability.Kernel.IonescuTulcea.Traj
import Mathlib.Probability.Kernel.Disintegration.StandardBorel

open MeasureTheory ProbabilityTheory
open scoped ENNReal

/-- The `n`-th binary digit of `x`: double `x` `n` times, keep the whole-number part, and
take its remainder on division by 2. This is the card's `d_n(x) = ⌊2^n x⌋ mod 2`. -/
noncomputable def binDigit (n : ℕ) (x : ℝ) : ℤ := ⌊(2 : ℝ) ^ n * x⌋ % 2

/-- Pile `k` of the splitting theorem, counted from 0: it takes as its `j`-th digit
(also counted from 0) the old digit at position `2^k (2j + 1)`. With `k` and `j` counted
from 1 this is the card's `U_k = Σ_j d_{2^(k-1)(2j-1)} 2^(-j)`. -/
noncomputable def pile (k : ℕ) (x : ℝ) : ℝ :=
  ∑' j : ℕ, (binDigit (2 ^ k * (2 * j + 1)) x : ℝ) / 2 ^ (j + 1)

namespace DigitAux

lemma binDigit_eq_nat (N i : ℕ) (hi : i < N) {x : ℝ} (hx : 0 ≤ x) :
    binDigit (i + 1) x = ((⌊(2:ℝ) ^ N * x⌋₊ / 2 ^ (N - 1 - i) % 2 : ℕ) : ℤ) := by
  have h2 : (2:ℝ) ^ N * x = (2:ℝ) ^ (i + 1) * x * ((2 ^ (N - 1 - i) : ℕ) : ℝ) := by
    push_cast
    rw [mul_right_comm, ← pow_add]
    congr 2
    omega
  have h3 : ⌊(2:ℝ) ^ (i + 1) * x⌋₊ = ⌊(2:ℝ) ^ N * x⌋₊ / 2 ^ (N - 1 - i) := by
    rw [← Nat.floor_div_natCast, h2, mul_div_cancel_right₀]
    positivity
  unfold binDigit
  rw [← Int.natCast_floor_eq_floor (by positivity), h3]
  push_cast
  rfl
#print axioms binDigit_eq_nat

lemma floor_set_eq (N m : ℕ) (hm : m < 2 ^ N) :
    {x ∈ Set.Ico (0:ℝ) 1 | ⌊(2:ℝ) ^ N * x⌋₊ = m}
      = Set.Ico ((m:ℝ) / 2 ^ N) (((m:ℝ) + 1) / 2 ^ N) := by
  have hpos : (0:ℝ) < 2 ^ N := by positivity
  have hm' : (m:ℝ) + 1 ≤ 2 ^ N := by exact_mod_cast hm
  ext x
  simp only [Set.mem_ofPred_eq, Set.mem_Ico]
  constructor
  · rintro ⟨⟨h0, h1⟩, hf⟩
    have := (Nat.floor_eq_iff (by positivity)).1 hf
    refine ⟨?_, ?_⟩
    · rw [div_le_iff₀ hpos]; linarith [this.1]
    · rw [lt_div_iff₀ hpos]; linarith [this.2]
  · rintro ⟨h1, h2⟩
    rw [div_le_iff₀ hpos] at h1
    rw [lt_div_iff₀ hpos] at h2
    have hx0 : 0 ≤ x := by
      have : (0:ℝ) ≤ m := Nat.cast_nonneg m
      nlinarith
    refine ⟨⟨hx0, ?_⟩, ?_⟩
    · nlinarith
    · rw [Nat.floor_eq_iff (by positivity)]
      constructor <;> linarith
#print axioms floor_set_eq

lemma vol_floor_eq (N : ℕ) (P : ℕ → Prop) [DecidablePred P] :
    volume {x ∈ Set.Ico (0:ℝ) 1 | P ⌊(2:ℝ) ^ N * x⌋₊} =
      ((Finset.range (2 ^ N)).filter P).card * ((2:ℝ≥0∞) ^ N)⁻¹ := by
  have hset : {x ∈ Set.Ico (0:ℝ) 1 | P ⌊(2:ℝ) ^ N * x⌋₊} =
      ⋃ m ∈ (Finset.range (2 ^ N)).filter P, {x ∈ Set.Ico (0:ℝ) 1 | ⌊(2:ℝ) ^ N * x⌋₊ = m} := by
    ext x
    simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_filter, Finset.mem_range,
      exists_prop]
    constructor
    · rintro ⟨hx, hP⟩
      refine ⟨_, ⟨?_, hP⟩, hx, rfl⟩
      rw [Nat.floor_lt (by have := hx.1; positivity)]
      have := hx.2
      push_cast
      have : (0:ℝ) < 2 ^ N := by positivity
      nlinarith
    · rintro ⟨m, ⟨_, hP⟩, hx, rfl⟩
      exact ⟨hx, hP⟩
  rw [hset, measure_biUnion_finset]
  · have : ∀ m ∈ (Finset.range (2 ^ N)).filter P,
        volume {x ∈ Set.Ico (0:ℝ) 1 | ⌊(2:ℝ) ^ N * x⌋₊ = m} = ((2:ℝ≥0∞) ^ N)⁻¹ := by
      intro m hm
      rw [Finset.mem_filter, Finset.mem_range] at hm
      rw [floor_set_eq N m hm.1, Real.volume_Ico]
      have : ((m:ℝ) + 1) / 2 ^ N - m / 2 ^ N = ((2:ℝ) ^ N)⁻¹ := by
        field_simp; ring
      rw [this, ENNReal.ofReal_inv_of_pos (by positivity), ENNReal.ofReal_pow (by norm_num)]
      simp
    rw [Finset.sum_congr rfl this, Finset.sum_const, nsmul_eq_mul]
  · intro a _ b _ hab
    simp only [Function.onFun]
    rw [Set.disjoint_left]
    rintro x ⟨_, hxa⟩ ⟨_, hxb⟩
    exact hab (hxa.symm.trans hxb)
  · intro m _
    exact measurableSet_Ico.inter
      (measurableSet_eq_fun (Nat.measurable_floor.comp (measurable_const.mul measurable_id))
        measurable_const)
#print axioms vol_floor_eq

/-- How many of the two digits 0, 1 lie in `A`. -/

noncomputable def cnt (A : Set ℤ) : ℕ := by
  classical exact ((Finset.univ : Finset (Fin 2)).filter (fun b : Fin 2 => ((b:ℕ):ℤ) ∈ A)).card
#print axioms cnt

lemma count_eq (N : ℕ) (A : Fin N → Set ℤ) [DecidablePred
    (fun m : ℕ => ∀ i : Fin N, ((m / 2 ^ (N - 1 - i) % 2 : ℕ) : ℤ) ∈ A i)] :
    ((Finset.range (2 ^ N)).filter
      (fun m => ∀ i : Fin N, ((m / 2 ^ (N - 1 - i) % 2 : ℕ) : ℤ) ∈ A i)).card
      = ∏ i, cnt (A i) := by
  classical
  have h1 : ((Finset.range (2 ^ N)).filter
      (fun m => ∀ i : Fin N, ((m / 2 ^ (N - 1 - i) % 2 : ℕ) : ℤ) ∈ A i)).card
      = ((Finset.univ : Finset (Fin N → Fin 2)).filter
          (fun f => ∀ j, ((f j : ℕ) : ℤ) ∈ A (Fin.rev j))).card := by
    symm
    refine Finset.card_bij (fun f _ => (finFunctionFinEquiv f : ℕ)) ?_ ?_ ?_
    · intro f hf
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hf
      simp only [Finset.mem_filter, Finset.mem_range]
      refine ⟨(finFunctionFinEquiv f).2, fun i => ?_⟩
      have := finFunctionFinEquiv_symm_apply_val (finFunctionFinEquiv f) (Fin.rev i)
      rw [Equiv.symm_apply_apply, Fin.val_rev] at this
      have hN : N - 1 - (i : ℕ) = N - ((i : ℕ) + 1) := by omega
      rw [hN, ← this]
      simpa using hf (Fin.rev i)
    · intro f _ g _ hfg
      exact finFunctionFinEquiv.injective (Fin.ext hfg)
    · intro m hm
      simp only [Finset.mem_filter, Finset.mem_range] at hm
      refine ⟨finFunctionFinEquiv.symm ⟨m, hm.1⟩, ?_, by simp⟩
      simp only [Finset.mem_filter, Finset.mem_univ, true_and]
      intro j
      rw [finFunctionFinEquiv_symm_apply_val]
      have := hm.2 (Fin.rev j)
      have hN : N - 1 - ((Fin.rev j : Fin N) : ℕ) = (j : ℕ) := by
        rw [Fin.val_rev]; omega
      rwa [hN] at this
  rw [h1]
  have h2 : (Finset.univ : Finset (Fin N → Fin 2)).filter
      (fun f => ∀ j, ((f j : ℕ) : ℤ) ∈ A (Fin.rev j))
      = Fintype.piFinset (fun j => (Finset.univ : Finset (Fin 2)).filter
          (fun b : Fin 2 => ((b:ℕ):ℤ) ∈ A (Fin.rev j))) := by
    ext f
    simp [Fintype.mem_piFinset]
  rw [h2, Fintype.card_piFinset]
  rw [← Equiv.prod_comp Fin.revPerm (fun i => cnt (A i))]
  apply Finset.prod_congr rfl
  intro j _
  simp only [cnt, Fin.revPerm_apply]
#print axioms count_eq

lemma vol_digits (N : ℕ) (A : Fin N → Set ℤ) :
    volume {x ∈ Set.Ico (0:ℝ) 1 | ∀ i : Fin N, binDigit ((i:ℕ) + 1) x ∈ A i}
      = ∏ i, ((cnt (A i) : ℝ≥0∞) * 2⁻¹) := by
  classical
  have hset : {x ∈ Set.Ico (0:ℝ) 1 | ∀ i : Fin N, binDigit ((i:ℕ) + 1) x ∈ A i}
      = {x ∈ Set.Ico (0:ℝ) 1 | (fun m : ℕ => ∀ i : Fin N,
          ((m / 2 ^ (N - 1 - i) % 2 : ℕ) : ℤ) ∈ A i) ⌊(2:ℝ) ^ N * x⌋₊} := by
    ext x
    simp only [Set.mem_ofPred_eq]
    constructor
    · rintro ⟨hx, h⟩
      refine ⟨hx, fun i => ?_⟩
      rw [← binDigit_eq_nat N i i.2 hx.1]
      exact h i
    · rintro ⟨hx, h⟩
      refine ⟨hx, fun i => ?_⟩
      rw [binDigit_eq_nat N i i.2 hx.1]
      exact h i
  rw [hset, vol_floor_eq N (fun m : ℕ => ∀ i : Fin N, ((m / 2 ^ (N - 1 - i) % 2 : ℕ) : ℤ) ∈ A i),
    count_eq, Finset.prod_mul_distrib, Finset.prod_const,
    Finset.card_univ, Fintype.card_fin, ENNReal.inv_pow]
  push_cast
  rfl
#print axioms vol_digits

lemma cnt_univ : cnt Set.univ = 2 := by
  simp [cnt]
#print axioms cnt_univ

lemma vol_digit (n : ℕ) (B : Set ℤ) :
    volume {x ∈ Set.Ico (0:ℝ) 1 | binDigit (n + 1) x ∈ B} = (cnt B : ℝ≥0∞) * 2⁻¹ := by
  classical
  have h := vol_digits (n + 1) (fun i => if (i:ℕ) = n then B else Set.univ)
  have hset : {x ∈ Set.Ico (0:ℝ) 1 | ∀ i : Fin (n + 1), binDigit ((i:ℕ) + 1) x ∈
      (fun i : Fin (n + 1) => if (i:ℕ) = n then B else Set.univ) i}
      = {x ∈ Set.Ico (0:ℝ) 1 | binDigit (n + 1) x ∈ B} := by
    ext x
    simp only [Set.mem_ofPred_eq]
    constructor
    · rintro ⟨hx, h⟩
      refine ⟨hx, ?_⟩
      have := h (Fin.last n)
      simpa using this
    · rintro ⟨hx, h⟩
      refine ⟨hx, fun i => ?_⟩
      by_cases hi : (i:ℕ) = n
      · simp only [hi, ite_true]; exact h
      · simp [hi]
  rw [hset] at h
  rw [h, Fin.prod_univ_castSucc]
  simp only [Fin.val_castSucc, Fin.val_last, ite_true]
  have : ∀ i : Fin n, (if (i:ℕ) = n then B else Set.univ) = Set.univ := by
    intro i; simp [i.2.ne]
  simp only [this, cnt_univ]
  rw [Finset.prod_eq_one, one_mul]
  intro i _
  push_cast
  exact ENNReal.mul_inv_cancel (by norm_num) (by norm_num)
#print axioms vol_digit

lemma cnt_singleton (z : ℤ) (hz : z = 0 ∨ z = 1) : cnt {z} = 1 := by
  rcases hz with rfl | rfl
  · rw [cnt, Finset.card_eq_one]; exact ⟨0, by ext b; fin_cases b <;> simp⟩
  · rw [cnt, Finset.card_eq_one]; exact ⟨1, by ext b; fin_cases b <;> simp⟩
#print axioms cnt_singleton

instance isProbabilityMeasure_Ico : IsProbabilityMeasure (volume.restrict (Set.Ico (0:ℝ) 1)) :=
  ⟨by simp [Real.volume_Ico]⟩
#print axioms isProbabilityMeasure_Ico

end DigitAux

namespace PileAux

open DigitAux Filter Topology

lemma measurable_binDigit (n : ℕ) : Measurable (binDigit n) := by
  have h1 : Measurable (fun z : ℤ => z % 2) := Measurable.of_discrete
  exact h1.comp ((measurable_const.mul measurable_id).floor)
#print axioms measurable_binDigit

lemma binDigit_mod_two (n : ℕ) (x : ℝ) : binDigit n x % 2 = binDigit n x := by
  simp [binDigit]
#print axioms binDigit_mod_two

lemma vol_preimage (n : ℕ) (B : Set ℤ) :
    (volume.restrict (Set.Ico (0:ℝ) 1)) (binDigit (n + 1) ⁻¹' B) = (cnt B : ℝ≥0∞) * 2⁻¹ := by
  rw [Measure.restrict_apply' measurableSet_Ico, ← vol_digit n B]
  congr 1
  ext x
  simp [and_comm]
#print axioms vol_preimage

lemma law_digit (n : ℕ) :
    (volume.restrict (Set.Ico (0:ℝ) 1)).map (binDigit (n + 1))
      = (volume.restrict (Set.Ico (0:ℝ) 1)).map (binDigit (0 + 1)) := by
  ext B hB
  rw [Measure.map_apply (measurable_binDigit _) hB, Measure.map_apply (measurable_binDigit _) hB,
    vol_preimage, vol_preimage]
#print axioms law_digit

/-- The binary number read from a 0-1 sequence (reading each entry modulo 2). -/

noncomputable def Φ (ω : ℕ → ℤ) : ℝ := ∑' j : ℕ, ((ω j % 2 : ℤ) : ℝ) / 2 ^ (j + 1)
#print axioms Φ

lemma term_nonneg (ω : ℕ → ℤ) (j : ℕ) : 0 ≤ ((ω j % 2 : ℤ) : ℝ) / 2 ^ (j + 1) := by
  have : (0:ℤ) ≤ ω j % 2 := Int.emod_nonneg _ (by norm_num)
  positivity
#print axioms term_nonneg

lemma term_le (ω : ℕ → ℤ) (j : ℕ) : ((ω j % 2 : ℤ) : ℝ) / 2 ^ (j + 1) ≤ (1 / 2) ^ j := by
  have h1 : ω j % 2 < 2 := Int.emod_lt_of_pos _ (by norm_num)
  have h2 : ((ω j % 2 : ℤ) : ℝ) ≤ 1 := by exact_mod_cast (show ω j % 2 ≤ 1 by omega)
  rw [div_le_iff₀ (by positivity), one_div, inv_pow, pow_succ]
  have : ((2:ℝ) ^ j)⁻¹ * (2 ^ j * 2) = 2 := by field_simp
  rw [this]
  linarith
#print axioms term_le

lemma summable_term (ω : ℕ → ℤ) : Summable (fun j : ℕ => ((ω j % 2 : ℤ) : ℝ) / 2 ^ (j + 1)) :=
  Summable.of_nonneg_of_le (term_nonneg ω) (term_le ω) summable_geometric_two
#print axioms summable_term

lemma measurable_Φ : Measurable Φ := by
  refine measurable_of_tendsto_metrizable (f := fun N ω => ∑ j ∈ Finset.range N,
    ((ω j % 2 : ℤ) : ℝ) / 2 ^ (j + 1)) (fun N => ?_) ?_
  · refine Finset.measurable_sum _ (fun j _ => ?_)
    have h1 : Measurable (fun z : ℤ => ((z % 2 : ℤ) : ℝ) / 2 ^ (j + 1)) := Measurable.of_discrete
    exact h1.comp (measurable_pi_apply j)
  · rw [tendsto_pi_nhds]
    intro ω
    exact (summable_term ω).hasSum.tendsto_sum_nat
#print axioms measurable_Φ

lemma partial_sum (x : ℝ) (hx : x ∈ Set.Ico (0:ℝ) 1) (N : ℕ) :
    ∑ j ∈ Finset.range N, ((binDigit (j + 1) x % 2 : ℤ) : ℝ) / 2 ^ (j + 1)
      = (⌊(2:ℝ) ^ N * x⌋₊ : ℝ) / 2 ^ N := by
  induction N with
  | zero =>
    simp only [Finset.range_zero, Finset.sum_empty, pow_zero, one_mul, div_one]
    rw [Nat.floor_eq_zero.2 hx.2]
    simp
  | succ N ih =>
    rw [Finset.sum_range_succ, ih, binDigit_mod_two, binDigit_eq_nat (N + 1) N (by omega) hx.1]
    have hsub : N + 1 - 1 - N = 0 := by omega
    rw [hsub, pow_zero, Nat.div_one]
    set m := ⌊(2:ℝ) ^ (N + 1) * x⌋₊ with hm
    have hhalf : ⌊(2:ℝ) ^ N * x⌋₊ = m / 2 := by
      rw [hm, ← Nat.floor_div_natCast]
      congr 1
      push_cast
      ring
    rw [hhalf]
    have hdm : ((m:ℕ):ℝ) = 2 * ((m / 2 : ℕ) : ℝ) + ((m % 2 : ℕ) : ℝ) := by
      exact_mod_cast (Nat.div_add_mod m 2).symm
    rw [Int.cast_natCast, hdm]
    field_simp
    ring
#print axioms partial_sum

lemma hasSum_digits (x : ℝ) (hx : x ∈ Set.Ico (0:ℝ) 1) :
    HasSum (fun j : ℕ => ((binDigit (j + 1) x % 2 : ℤ) : ℝ) / 2 ^ (j + 1)) x := by
  rw [hasSum_iff_tendsto_nat_of_nonneg (fun j => term_nonneg (fun j => binDigit (j + 1) x) j)]
  simp_rw [partial_sum x hx]
  have hlow : Tendsto (fun N : ℕ => x - (1 / 2 : ℝ) ^ N) atTop (𝓝 x) := by
    have := (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num : (0:ℝ) ≤ 1 / 2)
      (by norm_num : (1 / 2 : ℝ) < 1)).const_sub x
    simpa using this
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le hlow tendsto_const_nhds (fun N => ?_)
    (fun N => ?_)
  · have hpos : (0:ℝ) < 2 ^ N := by positivity
    have := Nat.lt_floor_add_one ((2:ℝ) ^ N * x)
    simp only
    rw [le_div_iff₀ hpos, sub_mul, one_div, inv_pow, inv_mul_cancel₀ hpos.ne']
    linarith
  · have hpos : (0:ℝ) < 2 ^ N := by positivity
    have := Nat.floor_le (show 0 ≤ (2:ℝ) ^ N * x by have := hx.1; positivity)
    simp only
    rw [div_le_iff₀ hpos]
    linarith
#print axioms hasSum_digits

lemma Φ_digits (x : ℝ) (hx : x ∈ Set.Ico (0:ℝ) 1) :
    Φ (fun n => binDigit (n + 1) x) = x :=
  (hasSum_digits x hx).tsum_eq
#print axioms Φ_digits

/-- The odd-part decomposition `2^a (2b+1)` is unique. -/

lemma odd_part_inj {a b c d : ℕ} (h : 2 ^ a * (2 * b + 1) = 2 ^ c * (2 * d + 1)) (hac : a ≤ c) :
    a = c ∧ b = d := by
  obtain ⟨t, rfl⟩ := Nat.exists_eq_add_of_le hac
  rw [pow_add, mul_assoc] at h
  have h2 := Nat.eq_of_mul_eq_mul_left (by positivity) h
  cases t with
  | zero =>
    simp only [pow_zero, one_mul] at h2
    omega
  | succ t =>
    have : 2 * b + 1 = 2 * (2 ^ t * (2 * d + 1)) := by rw [h2]; ring
    omega
#print axioms odd_part_inj

def slot (q : ℕ × ℕ) : ℕ := 2 ^ q.1 * (2 * q.2 + 1) - 1
#print axioms slot

lemma slot_add_one (q : ℕ × ℕ) : slot q + 1 = 2 ^ q.1 * (2 * q.2 + 1) := by
  have : 1 ≤ 2 ^ q.1 * (2 * q.2 + 1) := Nat.one_le_iff_ne_zero.2 (by positivity)
  unfold slot
  omega
#print axioms slot_add_one

lemma slot_injective : Function.Injective slot := by
  intro q r h
  have h' : 2 ^ q.1 * (2 * q.2 + 1) = 2 ^ r.1 * (2 * r.2 + 1) := by
    rw [← slot_add_one, ← slot_add_one, h]
  rcases le_total q.1 r.1 with hle | hle
  · obtain ⟨h1, h2⟩ := odd_part_inj h' hle
    exact Prod.ext h1 h2
  · obtain ⟨h1, h2⟩ := odd_part_inj h'.symm hle
    exact Prod.ext h1.symm h2.symm
#print axioms slot_injective

/-- The generalized inverse of the distribution function. -/

noncomputable def quant (ν : Measure ℝ) (u : ℝ) : ℝ := sInf {t : ℝ | u ≤ cdf ν t}
#print axioms quant

lemma quant_le_iff (ν : Measure ℝ) [IsProbabilityMeasure ν] {u : ℝ} (hu0 : 0 < u) (hu1 : u < 1)
    (t : ℝ) : quant ν u ≤ t ↔ u ≤ cdf ν t := by
  have hne : {t : ℝ | u ≤ cdf ν t}.Nonempty := by
    obtain ⟨s, hs⟩ := ((tendsto_cdf_atTop ν).eventually (lt_mem_nhds hu1)).exists
    exact ⟨s, hs.le⟩
  have hbdd : BddBelow {t : ℝ | u ≤ cdf ν t} := by
    obtain ⟨t0, ht0⟩ := Filter.eventually_atBot.1
      ((tendsto_cdf_atBot ν).eventually (gt_mem_nhds hu0))
    refine ⟨t0, fun s hs => ?_⟩
    by_contra hlt
    push Not at hlt
    have := ht0 s hlt.le
    simp only [Set.mem_ofPred_eq] at hs
    linarith
  constructor
  · intro h
    have hall : ∀ s, t < s → u ≤ cdf ν s := by
      intro s hs
      obtain ⟨r, hr, hrs⟩ := exists_lt_of_csInf_lt hne (lt_of_le_of_lt h hs)
      exact hr.trans (monotone_cdf ν hrs.le)
    have hcont : Tendsto (cdf ν) (𝓝[>] t) (𝓝 (cdf ν t)) :=
      ((cdf ν).right_continuous t).tendsto.mono_left (nhdsWithin_mono _ Set.Ioi_subset_Ici_self)
    exact ge_of_tendsto hcont (eventually_nhdsWithin_of_forall hall)
  · intro h
    exact csInf_le hbdd h
#print axioms quant_le_iff

lemma quant_of_nonpos (ν : Measure ℝ) [IsProbabilityMeasure ν] {u : ℝ} (hu : u ≤ 0) :
    quant ν u = 0 := by
  have : {t : ℝ | u ≤ cdf ν t} = Set.univ := by
    ext t
    simp only [Set.mem_ofPred_eq, Set.mem_univ, iff_true]
    exact hu.trans (cdf_nonneg ν t)
  rw [quant, this, Real.sInf_of_not_bddBelow]
  rintro ⟨b, hb⟩
  have := hb (Set.mem_univ (b - 1))
  linarith
#print axioms quant_of_nonpos

lemma quant_of_one_lt (ν : Measure ℝ) [IsProbabilityMeasure ν] {u : ℝ} (hu : 1 < u) :
    quant ν u = 0 := by
  have : {t : ℝ | u ≤ cdf ν t} = ∅ := by
    ext t
    simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false, not_le]
    exact (cdf_le_one ν t).trans_lt hu
  rw [quant, this, Real.sInf_empty]
#print axioms quant_of_one_lt

lemma measurable_quant (ν : Measure ℝ) [IsProbabilityMeasure ν] : Measurable (quant ν) := by
  refine measurable_of_Iic (fun t => ?_)
  set E := quant ν ⁻¹' Set.Iic t
  have hsplit : E = (E ∩ Set.Ioo 0 1) ∪ (E ∩ Set.Iic 0) ∪ (E ∩ Set.Ioi 1) ∪ (E ∩ {1}) := by
    ext u
    simp only [Set.mem_union, Set.mem_inter_iff, Set.mem_Ioo, Set.mem_Iic, Set.mem_Ioi,
      Set.mem_singleton_iff]
    constructor
    · intro hu
      rcases le_or_gt u 0 with h0 | h0
      · exact Or.inl (Or.inl (Or.inr ⟨hu, h0⟩))
      rcases lt_trichotomy u 1 with h1 | h1 | h1
      · exact Or.inl (Or.inl (Or.inl ⟨hu, h0, h1⟩))
      · exact Or.inr ⟨hu, h1⟩
      · exact Or.inl (Or.inr ⟨hu, h1⟩)
    · rintro (((⟨hu, _⟩ | ⟨hu, _⟩) | ⟨hu, _⟩) | ⟨hu, _⟩) <;> exact hu
  have h1 : E ∩ Set.Ioo 0 1 = Set.Iic (cdf ν t) ∩ Set.Ioo 0 1 := by
    ext u
    simp only [Set.mem_inter_iff, Set.mem_Ioo, Set.mem_Iic, Set.mem_preimage, E]
    constructor
    · rintro ⟨h, h0, h1⟩
      exact ⟨(quant_le_iff ν h0 h1 t).1 h, h0, h1⟩
    · rintro ⟨h, h0, h1⟩
      exact ⟨(quant_le_iff ν h0 h1 t).2 h, h0, h1⟩
  have h2 : E ∩ Set.Iic 0 = Set.Iic 0 ∩ {_u | 0 ≤ t} := by
    ext u
    simp only [Set.mem_inter_iff, Set.mem_Iic, Set.mem_preimage, E, Set.mem_ofPred_eq]
    constructor
    · rintro ⟨h, h0⟩
      rw [quant_of_nonpos ν h0] at h
      exact ⟨h0, h⟩
    · rintro ⟨h0, h⟩
      rw [quant_of_nonpos ν h0]
      exact ⟨h, h0⟩
  have h3 : E ∩ Set.Ioi 1 = Set.Ioi 1 ∩ {_u | 0 ≤ t} := by
    ext u
    simp only [Set.mem_inter_iff, Set.mem_Ioi, Set.mem_Iic, Set.mem_preimage, E,
      Set.mem_ofPred_eq]
    constructor
    · rintro ⟨h, h0⟩
      rw [quant_of_one_lt ν h0] at h
      exact ⟨h0, h⟩
    · rintro ⟨h0, h⟩
      rw [quant_of_one_lt ν h0]
      exact ⟨h, h0⟩
  have h4 : MeasurableSet (E ∩ {1}) :=
    (Set.subsingleton_singleton.anti Set.inter_subset_right).measurableSet
  rw [hsplit, h1, h2, h3]
  exact (((measurableSet_Iic.inter measurableSet_Ioo).union
    (measurableSet_Iic.inter (MeasurableSet.const _))).union
    (measurableSet_Ioi.inter (MeasurableSet.const _))).union h4
#print axioms measurable_quant

lemma map_quant (ν : Measure ℝ) [IsProbabilityMeasure ν] :
    (volume.restrict (Set.Ico (0:ℝ) 1)).map (quant ν) = ν := by
  refine Measure.ext_of_Iic _ _ (fun t => ?_)
  rw [Measure.map_apply (measurable_quant ν) measurableSet_Iic,
    Measure.restrict_apply' measurableSet_Ico, ← ofReal_cdf]
  set c := cdf ν t
  have hc0 : 0 ≤ c := cdf_nonneg ν t
  have hc1 : c ≤ 1 := cdf_le_one ν t
  apply le_antisymm
  · calc volume (quant ν ⁻¹' Set.Iic t ∩ Set.Ico 0 1) ≤ volume (Set.Icc 0 c) := by
          apply measure_mono
          rintro u ⟨hu, hu0, hu1⟩
          rcases eq_or_lt_of_le hu0 with h | h
          · subst h; exact ⟨le_rfl, hc0⟩
          · exact ⟨hu0, (quant_le_iff ν h hu1 t).1 hu⟩
      _ = ENNReal.ofReal c := by rw [Real.volume_Icc, sub_zero]
  · calc ENNReal.ofReal c = volume (Set.Ioo 0 c) := by rw [Real.volume_Ioo, sub_zero]
      _ ≤ volume (quant ν ⁻¹' Set.Iic t ∩ Set.Ico 0 1) := by
          apply measure_mono
          rintro u ⟨hu0, huc⟩
          have hu1 : u < 1 := lt_of_lt_of_le huc hc1
          exact ⟨(quant_le_iff ν hu0 hu1 t).2 huc.le, hu0.le, hu1⟩
#print axioms map_quant

end PileAux

namespace KolmoAux

/-- From the first `n + 1` terms as a `Fin`-tuple to the `Iic n` form. -/

def toIic (n : ℕ) (y : Fin (n + 1) → ℝ) : (Π _i : Finset.Iic n, ℝ) :=
  fun i => y ⟨i.1, Nat.lt_succ_of_le (Finset.mem_Iic.1 i.2)⟩
#print axioms toIic

def ofIic (n : ℕ) (z : Π _i : Finset.Iic n, ℝ) : Fin (n + 1) → ℝ :=
  fun i => z ⟨i.1, Finset.mem_Iic.2 (Nat.le_of_lt_succ i.2)⟩
#print axioms ofIic

lemma measurable_toIic (n : ℕ) : Measurable (toIic n) :=
  Measurable.of_eval (fun _ => measurable_pi_apply _)
#print axioms measurable_toIic

lemma measurable_ofIic (n : ℕ) : Measurable (ofIic n) :=
  Measurable.of_eval (fun _ => measurable_pi_apply _)
#print axioms measurable_ofIic

lemma measurable_init (n : ℕ) : Measurable (fun y : Fin (n + 1) → ℝ => Fin.init y) :=
  Measurable.of_eval (fun _ => measurable_pi_apply _)
#print axioms measurable_init

lemma measurable_firstN (n : ℕ) : Measurable (fun (ω : ℕ → ℝ) (i : Fin n) => ω i) :=
  Measurable.of_eval (fun _ => measurable_pi_apply _)
#print axioms measurable_firstN

lemma ofIic_toIic (n : ℕ) : ofIic n ∘ toIic n = id := by
  funext y i; rfl
#print axioms ofIic_toIic

lemma frestrictLe_eq (n : ℕ) :
    (Preorder.frestrictLe n : (ℕ → ℝ) → _) = toIic n ∘ (fun (ω : ℕ → ℝ) (i : Fin (n + 1)) => ω i) := by
  funext ω i; rfl
#print axioms frestrictLe_eq

lemma firstN_eq (n : ℕ) :
    (fun (ω : ℕ → ℝ) (i : Fin (n + 1)) => ω i) = ofIic n ∘ Preorder.frestrictLe n := by
  funext ω i; rfl
#print axioms firstN_eq

/-- If `Q` has the right finite-dimensional laws, its restriction to `Iic n` is determined. -/

lemma map_frestrictLe_of_prop (μ : ∀ n : ℕ, Measure (Fin n → ℝ)) (Q : Measure (ℕ → ℝ))
    (hQ : ∀ (n : ℕ) (A : Set (Fin n → ℝ)), MeasurableSet A →
        Q {ω : ℕ → ℝ | (fun i : Fin n => ω i) ∈ A} = μ n A) (n : ℕ) :
    Q.map (Preorder.frestrictLe n) = (μ (n + 1)).map (toIic n) := by
  have h1 : Q.map (fun (ω : ℕ → ℝ) (i : Fin (n + 1)) => ω i) = μ (n + 1) := by
    ext A hA
    rw [Measure.map_apply (measurable_firstN _) hA]
    exact hQ (n + 1) A hA
  rw [frestrictLe_eq, ← Measure.map_map (measurable_toIic n) (measurable_firstN _), h1]
#print axioms map_frestrictLe_of_prop

end KolmoAux

open DigitAux PileAux KolmoAux

/-- The digit theorem. Let a dart land on the interval `[0, 1)`, with chances given by
length. For every `n` and every pattern `e_1, …, e_n` of 0s and 1s, the set of points
whose first `n` binary digits are `e_1, …, e_n` has length `2^(-n)`, and that equals the
product of the lengths of the separate sets `{x : d_i(x) = e_i}`. Moreover, under length
on `[0, 1)` the digits `d_1, d_2, d_3, …` are independent, and each one equals 1 with
chance one half: they are independent fair coin tosses. -/
theorem binary_digits_are_independent_fair_coins :
    (∀ (n : ℕ) (e : Fin n → ℤ), (∀ i, e i = 0 ∨ e i = 1) →
      volume {x ∈ Set.Ico (0 : ℝ) 1 | ∀ i : Fin n, binDigit ((i : ℕ) + 1) x = e i}
          = (2⁻¹ : ℝ≥0∞) ^ n ∧
      volume {x ∈ Set.Ico (0 : ℝ) 1 | ∀ i : Fin n, binDigit ((i : ℕ) + 1) x = e i}
          = ∏ i : Fin n, volume {x ∈ Set.Ico (0 : ℝ) 1 | binDigit ((i : ℕ) + 1) x = e i}) ∧
    iIndepFun (fun (n : ℕ) (x : ℝ) => binDigit (n + 1) x) (volume.restrict (Set.Ico (0 : ℝ) 1)) ∧
    ∀ n : ℕ, volume.restrict (Set.Ico (0 : ℝ) 1) {x | binDigit (n + 1) x = 1} = 2⁻¹ := by
  refine ⟨?_, ?_, ?_⟩
  · intro n e he
    have hK := vol_digits n (fun i => {e i})
    simp only [Set.mem_singleton_iff] at hK
    have hc : ∀ i, cnt {e i} = 1 := fun i => cnt_singleton _ (he i)
    simp only [hc, Nat.cast_one, one_mul, Finset.prod_const, Finset.card_univ,
      Fintype.card_fin] at hK
    refine ⟨hK, ?_⟩
    rw [hK]
    have : ∀ i : Fin n, volume {x ∈ Set.Ico (0:ℝ) 1 | binDigit ((i:ℕ) + 1) x = e i} = 2⁻¹ := by
      intro i
      have := vol_digit (i:ℕ) {e i}
      simp only [Set.mem_singleton_iff, cnt_singleton _ (he i), Nat.cast_one, one_mul] at this
      exact this
    rw [Finset.prod_congr rfl (fun i _ => this i), Finset.prod_const, Finset.card_univ,
      Fintype.card_fin]
  · rw [iIndepFun_iff_measure_inter_preimage_eq_mul]
    intro S sets _
    classical
    let N := S.sup id + 1
    let A : Fin N → Set ℤ := fun i => if (i:ℕ) ∈ S then sets i else Set.univ
    have hS : ∀ i ∈ S, i < N := fun i hi => Nat.lt_succ_of_le (Finset.le_sup (f := id) hi)
    rw [Measure.restrict_apply' measurableSet_Ico]
    have hset : (⋂ i ∈ S, (fun x => binDigit (i + 1) x) ⁻¹' sets i) ∩ Set.Ico 0 1
        = {x ∈ Set.Ico (0:ℝ) 1 | ∀ i : Fin N, binDigit ((i:ℕ) + 1) x ∈ A i} := by
      ext x
      simp only [Set.mem_inter_iff, Set.mem_iInter, Set.mem_preimage, Set.mem_ofPred_eq, A]
      constructor
      · rintro ⟨h, hx⟩
        refine ⟨hx, fun i => ?_⟩
        split_ifs with hi
        · exact h i hi
        · trivial
      · rintro ⟨hx, h⟩
        refine ⟨fun i hi => ?_, hx⟩
        have := h ⟨i, hS i hi⟩
        simpa [hi] using this
    rw [hset, vol_digits]
    have hsingle : ∀ i, (volume.restrict (Set.Ico (0:ℝ) 1))
        ((fun x => binDigit (i + 1) x) ⁻¹' sets i) = cnt (sets i) * 2⁻¹ := by
      intro i
      rw [Measure.restrict_apply' measurableSet_Ico, ← vol_digit i (sets i)]
      congr 1
      ext x
      simp [and_comm]
    simp only [hsingle]
    rw [Fin.prod_univ_eq_prod_range
      (fun i => (cnt (if i ∈ S then sets i else Set.univ) : ℝ≥0∞) * 2⁻¹) N]
    have hsub : S ⊆ Finset.range N := fun i hi => Finset.mem_range.2 (hS i hi)
    rw [← Finset.prod_subset hsub]
    · apply Finset.prod_congr rfl
      intro i hi
      simp [hi]
    · intro i _ hi
      simp only [hi, ite_false, cnt_univ]
      push_cast
      exact ENNReal.mul_inv_cancel (by norm_num) (by norm_num)
  · intro n
    rw [Measure.restrict_apply' measurableSet_Ico]
    have := vol_digit n {1}
    rw [cnt_singleton 1 (Or.inr rfl)] at this
    simp only [Set.mem_singleton_iff, Nat.cast_one, one_mul] at this
    rw [← this]
    congr 1
    ext x
    simp [and_comm]

/-- The splitting theorem. Deal the digits of a uniform point of `[0, 1)` into piles, the
`j`-th digit of pile `k` being the old digit at position `2^(k-1)(2j - 1)`, and read each
pile as a binary number `U_k`. Then `U_1, U_2, U_3, …` are independent, and each is uniform
on the unit interval. Hence for every distribution function `F` (here the distribution
function `cdf μ` of a probability `μ` on the line), with quantile map
`Q(u) = inf {t : F(t) ≥ u}`, the draws `X_k = Q(U_k)` are independent and each has law `F`. -/
theorem piles_of_digits_are_independent_uniforms :
    iIndepFun pile (volume.restrict (Set.Ico (0 : ℝ) 1)) ∧
    (∀ k : ℕ, (volume.restrict (Set.Ico (0 : ℝ) 1)).map (pile k)
        = volume.restrict (Set.Ico (0 : ℝ) 1)) ∧
    ∀ (μ : Measure ℝ) [IsProbabilityMeasure μ],
      iIndepFun (fun (k : ℕ) (x : ℝ) => sInf {t : ℝ | pile k x ≤ cdf μ t})
          (volume.restrict (Set.Ico (0 : ℝ) 1)) ∧
      ∀ k : ℕ, (volume.restrict (Set.Ico (0 : ℝ) 1)).map
          (fun x => sInf {t : ℝ | pile k x ≤ cdf μ t}) = μ := by
  let β : Measure ℤ := (volume.restrict (Set.Ico (0:ℝ) 1)).map (binDigit (0 + 1))
  have hind := binary_digits_are_independent_fair_coins.2.1
  let D : ℝ → ℕ → ℤ := fun x n => binDigit (n + 1) x
  have hD : Measurable D := Measurable.of_eval (fun n => measurable_binDigit (n + 1))
  have hlawD : (volume.restrict (Set.Ico (0:ℝ) 1)).map D
      = Measure.infinitePi (fun _ : ℕ => β) := by
    have := hind.map_fun_eq_infinitePi_map (fun n => measurable_binDigit (n + 1))
    refine this.trans ?_
    congr 1
    funext n
    exact law_digit n
  let M : (ℕ → ℤ) → (ℕ × ℕ → ℤ) := fun ω q => ω (slot q)
  have hMm : Measurable M := Measurable.of_eval (fun q => measurable_pi_apply _)
  have hM : (Measure.infinitePi (fun _ : ℕ => β)).map M
      = Measure.infinitePi (fun _ : ℕ × ℕ => β) :=
    Measure.map_infinitePi_infinitePi_of_inj slot_injective
  let C := MeasurableEquiv.curry ℕ ℕ ℤ
  have hC : (Measure.infinitePi (fun _ : ℕ × ℕ => β)).map C
      = Measure.infinitePi (fun _ : ℕ => Measure.infinitePi (fun _ : ℕ => β)) :=
    Measure.infinitePi_map_curry (fun _ _ => β)
  let G : ℝ → ℕ → ℕ → ℤ := C ∘ M ∘ D
  have hGm : Measurable G := C.measurable.comp (hMm.comp hD)
  have hG : (volume.restrict (Set.Ico (0:ℝ) 1)).map G
      = Measure.infinitePi (fun _ : ℕ => Measure.infinitePi (fun _ : ℕ => β)) := by
    rw [← Measure.map_map C.measurable (hMm.comp hD), ← Measure.map_map hMm hD, hlawD, hM, hC]
  have hpile : ∀ k, pile k = Φ ∘ (fun ω => ω k) ∘ G := by
    intro k
    funext x
    simp only [pile, Φ, Function.comp_apply, G, C, M, D, MeasurableEquiv.curry_apply]
    congr 1
    funext j
    rw [binDigit_mod_two, slot_add_one]
  have hpm : ∀ k, Measurable (pile k) := by
    intro k
    rw [hpile]
    exact measurable_Φ.comp ((measurable_pi_apply k).comp hGm)
  have hΦlaw : (Measure.infinitePi (fun _ : ℕ => β)).map Φ = volume.restrict (Set.Ico (0:ℝ) 1) := by
    rw [← hlawD, Measure.map_map measurable_Φ hD]
    have : Φ ∘ D =ᵐ[volume.restrict (Set.Ico (0:ℝ) 1)] id :=
      (ae_restrict_mem measurableSet_Ico).mono (fun x hx => Φ_digits x hx)
    rw [Measure.map_congr this, Measure.map_id]
  have hlaw : ∀ k, (volume.restrict (Set.Ico (0:ℝ) 1)).map (pile k)
      = volume.restrict (Set.Ico (0:ℝ) 1) := by
    intro k
    rw [hpile, ← Measure.map_map measurable_Φ ((measurable_pi_apply k).comp hGm),
      ← Measure.map_map (measurable_pi_apply k) hGm, hG, Measure.infinitePi_map_eval, hΦlaw]
  have hindP : iIndepFun pile (volume.restrict (Set.Ico (0 : ℝ) 1)) := by
    rw [iIndepFun_iff_map_fun_eq_infinitePi_map hpm]
    have h1 : (fun k => (volume.restrict (Set.Ico (0:ℝ) 1)).map (pile k))
        = fun _ => volume.restrict (Set.Ico (0:ℝ) 1) := funext hlaw
    have h2 : (fun x k => pile k x) = (fun (ω : ℕ → ℕ → ℤ) k => Φ (ω k)) ∘ G := by
      funext x k
      rw [hpile]
      rfl
    have h3 : Measurable (fun (ω : ℕ → ℕ → ℤ) k => Φ (ω k)) :=
      Measurable.of_eval (fun k => measurable_Φ.comp (measurable_pi_apply k))
    rw [h1, h2, ← Measure.map_map h3 hGm, hG,
      Measure.infinitePi_map_pi _ (fun _ => measurable_Φ), hΦlaw]
  refine ⟨hindP, hlaw, fun ν _ => ⟨?_, fun k => ?_⟩⟩
  · exact hindP.comp (fun _ => quant ν) (fun _ => measurable_quant ν)
  · rw [show (fun x => sInf {t : ℝ | pile k x ≤ cdf ν t}) = quant ν ∘ pile k from rfl,
      ← Measure.map_map (measurable_quant ν) (hpm k), hlaw k, map_quant]

/-- Kolmogorov's extension theorem. For every `n` let `μ_n` be a probability on the Borel
sets of `ℝ^n`, the `n`-long lists of reals. Suppose the family is consistent: adding a
coordinate and asking nothing of it changes nothing, `μ_{n+1}(A × ℝ) = μ_n(A)` for every
`n` and every Borel set `A`. Then there is exactly one probability `P` on the whole
sequences `ℝ^ℕ`, with the product sigma-algebra, such that the chance that the first `n`
terms lie in `A` is `μ_n(A)`, for every `n` and every Borel set `A ⊆ ℝ^n`. -/
theorem kolmogorov_extension_theorem (μ : ∀ n : ℕ, Measure (Fin n → ℝ))
    [∀ n, IsProbabilityMeasure (μ n)]
    (hcons : ∀ (n : ℕ) (A : Set (Fin n → ℝ)), MeasurableSet A →
      μ (n + 1) {y : Fin (n + 1) → ℝ | Fin.init y ∈ A} = μ n A) :
    ∃! P : Measure (ℕ → ℝ), IsProbabilityMeasure P ∧
      ∀ (n : ℕ) (A : Set (Fin n → ℝ)), MeasurableSet A →
        P {ω : ℕ → ℝ | (fun i : Fin n => ω i) ∈ A} = μ n A := by
  -- consistency as an equality of measures
  have hc : ∀ n, (μ (n + 1)).map (fun y => Fin.init y) = μ n := by
    intro n
    ext A hA
    rw [Measure.map_apply (measurable_init n) hA]
    exact hcons n A hA
  -- the laws on `Iic n`
  let ν : ∀ n : ℕ, Measure (Π _i : Finset.Iic n, ℝ) := fun n => (μ (n + 1)).map (toIic n)
  -- the joint laws of (first n+1 terms, next term)
  let h : ∀ n : ℕ, (Fin (n + 2) → ℝ) → (Π _i : Finset.Iic n, ℝ) × ℝ :=
    fun n y => (toIic n (Fin.init y), y (Fin.last (n + 1)))
  have hmeas : ∀ n, Measurable (h n) := fun n =>
    ((measurable_toIic n).comp (measurable_init (n + 1))).prodMk (measurable_pi_apply _)
  let ρ : ∀ n : ℕ, Measure ((Π _i : Finset.Iic n, ℝ) × ℝ) := fun n => (μ (n + 2)).map (h n)
  have hρfst : ∀ n, (ρ n).fst = ν n := by
    intro n
    have h1 : (ρ n).fst = (μ (n + 2)).map (toIic n ∘ fun y => Fin.init y) :=
      Measure.fst_map_prodMk ((measurable_toIic n).comp (measurable_init (n + 1)))
        (measurable_pi_apply _)
    rw [h1, ← Measure.map_map (measurable_toIic n) (measurable_init (n + 1)), hc (n + 1)]
  let κ : ∀ n : ℕ, Kernel (Π _i : Finset.Iic n, ℝ) ℝ := fun n => (ρ n).condKernel
  let μ₀ : Measure ℝ := (μ 1).map (fun y => y 0)
  let P : Measure (ℕ → ℝ) := Kernel.trajMeasure (X := fun _ => ℝ) μ₀ κ
  have hP : ∀ a, P.map (Preorder.frestrictLe a) = ν a := by
    intro a
    induction a with
    | zero =>
      simp only [P, Kernel.trajMeasure]
      rw [Measure.map_comp _ _ (Preorder.measurable_frestrictLe 0), Kernel.traj_map_frestrictLe,
        Kernel.partialTraj_self, Measure.id_comp]
      simp only [μ₀, ν]
      rw [Measure.map_map (MeasurableEquiv.measurable _) (by fun_prop)]
      congr 1
      funext y i
      have hi : i = default := Subsingleton.elim _ _
      subst hi
      rfl
    | succ a ih =>
      let g : (Π _i : Finset.Iic a, ℝ) × ℝ → (Π _i : Finset.Iic (a + 1), ℝ) :=
        fun p i => if hi : i.1 ≤ a then p.1 ⟨i.1, Finset.mem_Iic.2 hi⟩ else p.2
      have hg : Measurable g := by
        refine Measurable.of_eval (fun i => ?_)
        by_cases hi : i.1 ≤ a
        · simp only [g, hi, dite_true]
          exact (measurable_pi_apply _).comp measurable_fst
        · simp only [g, hi, dite_false]
          exact measurable_snd
      have hsplit : (Preorder.frestrictLe (a + 1) : (ℕ → ℝ) → _)
          = g ∘ (fun x : ℕ → ℝ => (Preorder.frestrictLe a x, x (a + 1))) := by
        funext x i
        simp only [g, Function.comp_apply, Preorder.frestrictLe_apply]
        split_ifs with hi
        · rfl
        · have : i.1 = a + 1 := by
            have := Finset.mem_Iic.1 i.2
            omega
          simp [this]
      have hcomp : g ∘ h a = toIic (a + 1) := by
        funext y i
        simp only [g, h, Function.comp_apply, toIic]
        split_ifs with hi
        · rfl
        · have : i.1 = a + 1 := by
            have := Finset.mem_Iic.1 i.2
            omega
          congr 1
          ext
          simp [this]
      rw [hsplit, ← Measure.map_map hg (by fun_prop),
        ← Kernel.map_frestrictLe_trajMeasure_compProd_eq_map_trajMeasure, ih, ← hρfst,
        Measure.disintegrate, Measure.map_map hg (hmeas a), hcomp]
  have hprop : ∀ (n : ℕ) (A : Set (Fin n → ℝ)), MeasurableSet A →
      P {ω : ℕ → ℝ | (fun i : Fin n => ω i) ∈ A} = μ n A := by
    intro n A hA
    cases n with
    | zero =>
      by_cases hne : A.Nonempty
      · have hA' : A = Set.univ := by
          obtain ⟨y, hy⟩ := hne
          ext z
          simp only [Set.mem_univ, iff_true]
          rwa [Subsingleton.elim z y]
        subst hA'
        simp
      · rw [Set.not_nonempty_iff_eq_empty] at hne
        subst hne
        simp
    | succ a =>
      have : {ω : ℕ → ℝ | (fun i : Fin (a + 1) => ω i) ∈ A}
          = (fun (ω : ℕ → ℝ) (i : Fin (a + 1)) => ω i) ⁻¹' A := rfl
      rw [this, ← Measure.map_apply (measurable_firstN _) hA, firstN_eq,
        ← Measure.map_map (measurable_ofIic a) (Preorder.measurable_frestrictLe a), hP a]
      simp only [ν]
      rw [Measure.map_map (measurable_ofIic a) (measurable_toIic a), ofIic_toIic, Measure.map_id]
  refine ⟨P, ⟨inferInstance, hprop⟩, ?_⟩
  rintro Q ⟨hQprob, hQ⟩
  let F : ∀ I : Finset ℕ, Measure (Π _i : I, ℝ) := fun I => P.map I.restrict
  have hF : IsProjectiveMeasureFamily (α := fun _ : ℕ => ℝ) F := by
    intro I J hJI
    simp only [F]
    rw [Measure.map_map (Finset.measurable_restrict₂ hJI) (Finset.measurable_restrict I),
      Finset.restrict₂_comp_restrict]
  have hPlim : IsProjectiveLimit (α := fun _ : ℕ => ℝ) P F := fun I => rfl
  have hQlim : IsProjectiveLimit (α := fun _ : ℕ => ℝ) Q F := by
    rw [isProjectiveLimit_nat_iff hF]
    intro n
    simp only [F]
    rw [map_frestrictLe_of_prop μ Q hQ n]
    exact (map_frestrictLe_of_prop μ P hprop n).symm
  exact hQlim.unique hPlim

/-! The card's worked numbers, exactly. The dart is at 0.7236 = 1809/2500, so its `n`-th
binary digit is `⌊2^n · 1809 / 2500⌋ mod 2`, a whole-number computation. -/

-- The dart's first sixteen binary digits: 1 0 1 1 1 0 0 1 0 0 1 1 1 1 0 1.
example : (List.range 16).map (fun i => 2 ^ (i + 1) * 1809 / 2500 % 2)
    = [1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1] := by decide

-- The same digits through the card's real definition, for the first three: 1, 0, 1.
example : binDigit 1 (1809 / 2500) = 1 ∧ binDigit 2 (1809 / 2500) = 0 ∧
    binDigit 3 (1809 / 2500) = 1 := by
  have h1 : ⌊(2 : ℝ) ^ 1 * (1809 / 2500)⌋ = 1 := by rw [Int.floor_eq_iff]; norm_num
  have h2 : ⌊(2 : ℝ) ^ 2 * (1809 / 2500)⌋ = 2 := by rw [Int.floor_eq_iff]; norm_num
  have h3 : ⌊(2 : ℝ) ^ 3 * (1809 / 2500)⌋ = 5 := by rw [Int.floor_eq_iff]; norm_num
  simp only [binDigit, h1, h2, h3]; decide

-- Step 1: the pattern 1, 0, 1 is m = 5 with n = 3, and the dart lies in [5/8, 6/8).
example : 2 ^ 3 * 1809 / 2500 = 5 ∧ (5 : ℚ) / 8 ≤ 1809 / 2500 ∧ (1809 : ℚ) / 2500 < 6 / 8 := by
  norm_num

-- Step 2: digits 2, 5, 7 fixed to 1, 0, 1 among the first seven: 16 of the 128 cells of
-- length 1/128, chance 16/128 = (1/2)^3. (Cell i has digit p equal to i / 2^(7-p) mod 2.)
example : ((Finset.range 128).filter
    (fun i => i / 2 ^ 5 % 2 = 1 ∧ i / 2 ^ 2 % 2 = 0 ∧ i % 2 = 1)).card = 16 := by decide
example : (16 : ℚ) / 128 = (1 / 2) ^ 3 := by norm_num

-- The code's count: all patterns of lengths 1 to 12 number 8,190.
example : ∑ n ∈ Finset.Icc 1 12, 2 ^ n = 8190 := by decide

-- Step 3: positions 1 to 16 go to piles 1 2 1 3 1 2 1 4 1 2 1 3 1 2 1 5; position n goes to
-- pile k exactly when 2^(k-1) divides n and leaves an odd number.
example : (List.range 16).zip [1, 2, 1, 3, 1, 2, 1, 4, 1, 2, 1, 3, 1, 2, 1, 5] |>.all
    (fun p => (p.1 + 1) % 2 ^ (p.2 - 1) = 0 ∧ (p.1 + 1) / 2 ^ (p.2 - 1) % 2 = 1) := by decide

-- The slot s(2, 3) = 2^(2-1) (2·3 - 1) = 10.
example : 2 ^ (2 - 1) * (2 * 3 - 1) = 10 := by norm_num

-- Step 5: twelve old digits give the four piles 6, 3, 2 and 1 digits: 64 × 8 × 4 × 2 = 4096.
example : 2 ^ 6 * 2 ^ 3 * 2 ^ 2 * 2 ^ 1 = 4096 ∧ 4096 = 2 ^ 12 := by norm_num

-- Step 6: the die rolls ⌊6 U_k⌋ + 1 from 20 digits of each of the first four piles are
-- 6, 1, 6, 5. Pile k (from 1) reads the dart's digits at positions 2^(k-1)(2j - 1).
set_option exponentiation.threshold 400 in
example : (List.range 4).map (fun k => 6 * (∑ j ∈ Finset.range 20,
    (2 ^ (2 ^ k * (2 * j + 1)) * 1809 / 2500 % 2) * 2 ^ (19 - j)) / 2 ^ 20 + 1)
    = [6, 1, 6, 5] := by decide

-- Step 7: the sticky coin gives three heads the chance (1/2)(4/5)(4/5) = 8/25 = 0.32.
example : (1 : ℚ) / 2 * (4 / 5) * (4 / 5) = 32 / 100 := by norm_num

-- When it holds: a dart with density 2x has P(d_1 = 1) = 1 - (1/2)^2 = 3/4,
-- P(d_2 = 1) = (1/2)^2 - (1/4)^2 + 1 - (3/4)^2 = 5/8, and P(both) = 1 - (3/4)^2 = 7/16,
-- which is not the product 3/4 × 5/8 = 15/32.
example : (1 : ℚ) - (1 / 2) ^ 2 = 3 / 4 ∧
    (1 / 2 : ℚ) ^ 2 - (1 / 4) ^ 2 + 1 - (3 / 4) ^ 2 = 5 / 8 ∧
    (1 : ℚ) - (3 / 4) ^ 2 = 7 / 16 ∧ (3 / 4 : ℚ) * (5 / 8) = 15 / 32 ∧
    (7 / 16 : ℚ) ≠ 15 / 32 := by norm_num

-- Shared digits: Var U = 1/12, Cov(U, d_1) = 3/8 - 1/4 = 1/8, Cov(U, V) = 2/12 - 1/8 = 1/24,
-- correlation (1/24) / (1/12) = 1/2.
example : (3 : ℚ) / 8 - 1 / 4 = 1 / 8 ∧ 2 * (1 / 12 : ℚ) - 1 / 8 = 1 / 24 ∧
    (1 / 24 : ℚ) / (1 / 12) = 1 / 2 := by norm_num

#print axioms binary_digits_are_independent_fair_coins
#print axioms piles_of_digits_are_independent_uniforms
#print axioms kolmogorov_extension_theorem
