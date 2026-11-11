-- Euler's product: multiplying one geometric bracket 1/(1 - x^k) for every part size k gives the power series whose coefficient of x^n is the number of partitions of n, and the product of the brackets 1 + x^k equals the product of 1/(1 - x^k) over odd k, so partitions into distinct parts and into odd parts are equally many for every n.
import Mathlib.Combinatorics.Enumerative.Partition.GenFun
import Mathlib.Combinatorics.Enumerative.Partition.Glaisher
import Mathlib.Combinatorics.Enumerative.Composition
import Mathlib.RingTheory.PowerSeries.Inverse
import Mathlib.Topology.Instances.Rat

open PowerSeries Nat Nat.Partition
open scoped PowerSeries.WithPiTopology

theorem tsum_X_pow_mul_eq_inv (k : ℕ) (hk : 0 < k) :
    (∑' j : ℕ, (X : ℚ⟦X⟧) ^ (k * j)) = (1 - X ^ k)⁻¹ := by
  rw [PowerSeries.eq_inv_iff_mul_eq_one (by simp [hk.ne'])]
  simp_rw [pow_mul]
  exact PowerSeries.WithPiTopology.tsum_pow_mul_one_sub_of_constantCoeff_eq_zero (by simp [hk.ne'])

#print axioms tsum_X_pow_mul_eq_inv

theorem hasProd_restricted_inv (p : ℕ → Prop) [DecidablePred p] :
    HasProd (fun i : ℕ => if p (i + 1) then (1 - X ^ (i + 1) : ℚ⟦X⟧)⁻¹ else 1)
      (PowerSeries.mk fun n => ((restricted n p).card : ℚ)) := by
  convert hasProd_powerSeriesMk_card_restricted ℚ p using 2 with i
  split_ifs
  · exact (tsum_X_pow_mul_eq_inv (i + 1) i.succ_pos).symm
  · rfl

#print axioms hasProd_restricted_inv

/-- The multisets with every part in `1, …, k` and total `n`, listed by how many copies of the
largest allowed part they use. -/

def genParts : ℕ → ℕ → List (Multiset ℕ)
  | n, 0 => if n = 0 then [0] else []
  | n, k + 1 => (List.range (n / (k + 1) + 1)).flatMap fun c =>
      (genParts (n - c * (k + 1)) k).map fun m => Multiset.replicate c (k + 1) + m

theorem mem_genParts (k : ℕ) : ∀ (n : ℕ) (m : Multiset ℕ), (∀ x ∈ m, 0 < x ∧ x ≤ k) →
    m.sum = n → m ∈ genParts n k := by
  induction k with
  | zero =>
    intro n m hm hsum
    have h0 : m = 0 := Multiset.eq_zero_of_forall_notMem fun x hx => by
      have := hm x hx; omega
    subst h0
    simp only [Multiset.sum_zero] at hsum
    subst hsum
    simp [genParts]
  | succ k ih =>
    intro n m hm hsum
    set c := m.count (k + 1)
    set m' := m.filter (· ≠ k + 1)
    have hsplit : m = Multiset.replicate c (k + 1) + m' := by
      rw [← Multiset.filter_eq' m (k + 1), Multiset.filter_add_not]
    have hsum' : n = c * (k + 1) + m'.sum := by
      rw [← hsum, hsplit, Multiset.sum_add, Multiset.sum_replicate, smul_eq_mul]
    have hm' : ∀ x ∈ m', 0 < x ∧ x ≤ k := by
      intro x hx
      rw [Multiset.mem_filter] at hx
      have := hm x hx.1
      omega
    simp only [genParts, List.mem_flatMap, List.mem_range, List.mem_map]
    refine ⟨c, ?_, m', ih _ m' hm' ?_, hsplit.symm⟩
    · rw [Nat.lt_succ_iff, Nat.le_div_iff_mul_le (by omega : 0 < k + 1)]
      omega
    · omega

#print axioms mem_genParts

/-- The multisets of parts of all partitions of `n`, found by `genParts`. -/

def partsFinset (n : ℕ) : Finset (Multiset ℕ) :=
  (genParts n n).toFinset.filter fun m => (∀ x ∈ m, 0 < x) ∧ m.sum = n

theorem image_parts_univ (n : ℕ) :
    (Finset.univ : Finset (Partition n)).image Partition.parts = partsFinset n := by
  ext m
  simp only [Finset.mem_image, Finset.mem_univ, true_and, partsFinset, Finset.mem_filter,
    List.mem_toFinset]
  constructor
  · rintro ⟨p, rfl⟩
    exact ⟨mem_genParts n n p.parts (fun x hx => ⟨p.parts_pos hx, le_of_mem_parts hx⟩)
      p.parts_sum, fun x hx => p.parts_pos hx, p.parts_sum⟩
  · rintro ⟨_, hpos, hsum⟩
    exact ⟨⟨m, fun hx => hpos _ hx, hsum⟩, rfl⟩

#print axioms image_parts_univ

theorem parts_injective (n : ℕ) : Function.Injective (Partition.parts (n := n)) :=
  fun _ _ h => Partition.ext h

#print axioms parts_injective

theorem card_partition_eq (n : ℕ) : Fintype.card (Partition n) = (partsFinset n).card := by
  rw [← image_parts_univ, Finset.card_image_of_injective _ (parts_injective n), Finset.card_univ]

#print axioms card_partition_eq

theorem card_filter_partition (n : ℕ) (P : Multiset ℕ → Prop) [DecidablePred P] :
    ((Finset.univ : Finset (Partition n)).filter (fun p => P p.parts)).card =
      ((partsFinset n).filter P).card := by
  rw [← image_parts_univ, Finset.filter_image,
    Finset.card_image_of_injective _ (parts_injective n)]

#print axioms card_filter_partition

/-- Euler's product. Take one endless bracket `1/(1 - x^k)` for every part size `k = 1, 2, 3, …`
and multiply them all. Read coefficient by coefficient (`x` is a mark, not a number), the product
exists and equals the series whose coefficient of `x^n` is `p(n)`, the number of partitions of `n`. -/
theorem partition_series_eq_euler_product :
    HasProd (fun i : ℕ => (1 - X ^ (i + 1) : ℚ⟦X⟧)⁻¹)
      (PowerSeries.mk fun n => (Fintype.card n.Partition : ℚ)) := by
  have h := hasProd_restricted_inv (fun _ => True)
  simp only [ite_true] at h
  convert h using 3 with n
  simp [restricted]

/-- Each coefficient settles after finitely many brackets: for every total `n` and every `m ≥ n`,
the coefficient of `x^n` in the product of the first `m` brackets `1/(1 - x^k)`, `k = 1, …, m`,
is already `p(n)`. -/
theorem coeff_finite_euler_product_eq_card_partition (n m : ℕ) (hm : n ≤ m) :
    coeff n (∏ k ∈ Finset.Icc 1 m, (1 - X ^ k : ℚ⟦X⟧)⁻¹) = (Fintype.card n.Partition : ℚ) := by
  have h := hasProd_restricted_inv (· ≤ m)
  have h2 := hasProd_prod_of_ne_finset_one (s := Finset.range m)
    (f := fun i : ℕ => if i + 1 ≤ m then (1 - X ^ (i + 1) : ℚ⟦X⟧)⁻¹ else 1)
    (L := SummationFilter.unconditional ℕ) (fun b hb => by
      simp only [Finset.mem_range, not_lt] at hb
      simp only [ite_eq_right_iff]; omega)
  have h3 := h.unique h2
  have e : ∏ k ∈ Finset.Icc 1 m, (1 - X ^ k : ℚ⟦X⟧)⁻¹ =
      ∏ b ∈ Finset.range m, (fun i : ℕ => if i + 1 ≤ m then (1 - X ^ (i + 1) : ℚ⟦X⟧)⁻¹ else 1) b := by
    rw [← Finset.Ico_add_one_right_eq_Icc, Finset.prod_Ico_eq_prod_range, Nat.add_sub_cancel]
    refine Finset.prod_congr rfl fun k hk => ?_
    simp only [Finset.mem_range] at hk
    simp only [show k + 1 ≤ m by omega, ite_true, add_comm]
  rw [e, ← h3, coeff_mk]
  congr 1
  simp only [restricted]
  rw [Finset.filter_true_of_mem, Finset.card_univ]
  intro p _ i hi
  exact (le_of_mem_parts hi).trans hm

/-- Trimming every bracket to `1 + x^k` counts partitions with no part size used twice, and that
product equals the product of `1/(1 - x^(2k-1))` over the odd sizes alone, which counts partitions
into odd parts. Both products exist coefficient by coefficient; the first has coefficients `d(n)`,
the partitions of `n` into distinct parts, the second `o(n)`, the partitions of `n` into odd parts,
and `d(n) = o(n)` for every `n`, so the two products are one series. -/
theorem distinct_parts_product_eq_odd_parts_product :
    HasProd (fun i : ℕ => (1 + X ^ (i + 1) : ℚ⟦X⟧))
        (PowerSeries.mk fun n => ((distincts n).card : ℚ)) ∧
      HasProd (fun i : ℕ => (1 - X ^ (2 * i + 1) : ℚ⟦X⟧)⁻¹)
        (PowerSeries.mk fun n => ((odds n).card : ℚ)) ∧
      ∀ n : ℕ, (distincts n).card = (odds n).card := by
  refine ⟨?_, ?_, fun n => (card_odds_eq_card_distincts n).symm⟩
  · have h := hasProd_powerSeriesMk_card_countRestricted ℚ (m := 2) (by norm_num)
    simp_rw [countRestricted_two] at h
    convert h using 2 with i
    simp [Finset.sum_range_succ]
  · have h := hasProd_restricted_inv (fun k => ¬ Even k)
    have hinj : Function.Injective (fun i : ℕ => 2 * i) := fun a b h => by simpa using h
    rw [← hinj.hasProd_iff] at h
    · convert h using 2 with i
      all_goals first | rfl | simp [Function.comp]
    · intro x hx
      have hx' : ¬ Even x := fun ⟨r, hr⟩ => hx ⟨r, by simp only; omega⟩
      have : Even (x + 1) := by rw [Nat.even_add_one]; exact hx'
      simp [this]

-- The partition counts below are exact whole-number checks of the card's worked numbers.
-- `decide` cannot evaluate Mathlib's `Fintype (Nat.Partition n)` instance (it is built through
-- `Finset.sort`, which does not reduce), so these four stay open for the proof step.

-- Eight marbles into unmarked cups: p(8) = 22.
example : Fintype.card (Partition 8) = 22 := by rw [card_partition_eq]; decide +kernel

-- The x^8 place as sizes 1 to 8 go in: 1, 5, 10, 15, 18, 20, 21, 22.
example : (List.range 8).map (fun j => ((Finset.univ : Finset (Partition 8)).filter
    (fun p => ∀ i ∈ p.parts, i ≤ j + 1)).card) = [1, 5, 10, 15, 18, 20, 21, 22] := by
  rw [show (fun j => ((Finset.univ : Finset (Partition 8)).filter
      (fun p => ∀ i ∈ p.parts, i ≤ j + 1)).card) =
      fun j => ((partsFinset 8).filter (fun m => ∀ i ∈ m, i ≤ j + 1)).card from
    funext fun j => card_filter_partition 8 (fun m => ∀ i ∈ m, i ≤ j + 1)]
  decide +kernel

-- Eight marbles with no size twice: 6 ways; all sizes odd: 6 ways.
example : (distincts 8).card = 6 ∧ (odds 8).card = 6 := by
  rw [distincts, odds, restricted, card_filter_partition 8 Multiset.Nodup,
    card_filter_partition 8 (fun m => ∀ i ∈ m, ¬ Even i)]
  decide +kernel

-- The pentagonal recurrence at 8: p(7) + p(6) - p(3) - p(1) = 15 + 11 - 3 - 1 = 22.
example : Fintype.card (Partition 7) + Fintype.card (Partition 6) - Fintype.card (Partition 3)
    - Fintype.card (Partition 1) = Fintype.card (Partition 8) := by
  simp only [card_partition_eq]
  decide +kernel

-- Counting the order of the cups instead gives 128 writings of 8.
example : Fintype.card (Composition 8) = 128 := by simp [composition_card]

#print axioms partition_series_eq_euler_product
#print axioms coeff_finite_euler_product_eq_card_partition
#print axioms distinct_parts_product_eq_odd_parts_product
