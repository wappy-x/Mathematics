-- Brun's sieve and Selberg's: the twin prime pairs up to x number at most a constant times x (log log x)² / (log x)², so the sum of their reciprocals converges, and inclusion-exclusion for the twin sieve cut off after an even number of layers still gives a ceiling.
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Tactic.NormNum.Prime
import Mathlib.NumberTheory.Primorial
import Mathlib.NumberTheory.EulerProduct.Basic
import Mathlib.NumberTheory.Harmonic.Bounds
import Mathlib.Data.ZMod.QuotientRing
import Mathlib.Analysis.Complex.ExponentialBounds
import Mathlib.Analysis.PSeries
import Mathlib.Tactic

open Filter Asymptotics Nat

section BrunHelpers

open Finset

lemma brun_card_roots_prime (p : ℕ) (hp : p.Prime) [NeZero p] :
    Fintype.card {a : ZMod p // a * (a + 2) = 0} = if p = 2 then 1 else 2 := by
  have := Fact.mk hp
  rw [Fintype.card_subtype]
  have hfil : (univ.filter fun a : ZMod p => a * (a + 2) = 0) = {0, -2} := by
    ext a; simp [_root_.mul_eq_zero, add_eq_zero_iff_eq_neg]
  rw [hfil]
  split_ifs with h2
  · have : (-2 : ZMod p) = 0 := by rw [neg_eq_zero]; subst h2; exact_mod_cast ZMod.natCast_self 2
    simp [this]
  · have h2' : (2 : ZMod p) ≠ 0 := by
      intro h
      have h' : ((2 : ℕ) : ZMod p) = 0 := by exact_mod_cast h
      rw [ZMod.natCast_eq_zero_iff] at h'
      exact h2 ((Nat.prime_dvd_prime_iff_eq hp Nat.prime_two).1 h')
    rw [card_insert_of_notMem (by simpa [eq_comm] using h2'), card_singleton]

#print axioms brun_card_roots_prime

lemma brun_card_roots (D : Finset ℕ) (hD : ∀ p ∈ D, p.Prime) [NeZero (∏ i : D, (i : ℕ))] :
    Fintype.card {a : ZMod (∏ i : D, (i : ℕ)) // a * (a + 2) = 0} =
      ∏ p ∈ D, (if p = 2 then 1 else 2) := by
  have cop : Pairwise (Function.onFun Nat.Coprime fun i : D => (i : ℕ)) := fun i j hij =>
    (Nat.coprime_primes (hD _ i.2) (hD _ j.2)).2 (fun h => hij (Subtype.ext h))
  have : ∀ i : D, NeZero (i : ℕ) := fun i => ⟨(hD _ i.2).ne_zero⟩
  let e := ZMod.prodEquivPi (fun i : D => (i : ℕ)) cop
  calc Fintype.card {a : ZMod (∏ i : D, (i : ℕ)) // a * (a + 2) = 0}
      = Fintype.card {f : Π i : D, ZMod (i : ℕ) // ∀ i, f i * (f i + 2) = 0} := by
        refine Fintype.card_congr (e.toEquiv.subtypeEquiv fun a => ?_)
        rw [← e.map_eq_zero_iff, map_mul, map_add, map_ofNat, funext_iff]
        simp
        rfl
    _ = Fintype.card (Π i : D, {b : ZMod (i : ℕ) // b * (b + 2) = 0}) :=
        Fintype.card_congr (Equiv.subtypePiEquivPi (p := fun (i : D) (b : ZMod (i : ℕ)) => b * (b + 2) = 0))
    _ = ∏ i : D, Fintype.card {b : ZMod (i : ℕ) // b * (b + 2) = 0} := Fintype.card_pi
    _ = ∏ i : D, (if (i : ℕ) = 2 then 1 else 2) := by
        refine Finset.prod_congr rfl fun i _ => brun_card_roots_prime (i : ℕ) (hD _ i.2)
    _ = ∏ p ∈ D, (if p = 2 then 1 else 2) := Finset.prod_coe_sort D (fun p => if p = 2 then 1 else 2)

#print axioms brun_card_roots

lemma brun_count_residue (d x : ℕ) [NeZero d] (a : ZMod d) :
    x / d ≤ ((Icc 1 x).filter (fun n : ℕ => (n : ZMod d) = a)).card ∧
      ((Icc 1 x).filter (fun n : ℕ => (n : ZMod d) = a)).card ≤ x / d + 1 := by
  have hd : 0 < d := Nat.pos_of_ne_zero (NeZero.ne d)
  constructor
  · set r := if a.val = 0 then d else a.val with hr
    have hr1 : 1 ≤ r := by
      simp only [hr]; split_ifs with h
      · exact hd
      · exact Nat.one_le_iff_ne_zero.mpr h
    have hr2 : r ≤ d := by
      simp only [hr]; split_ifs
      · exact le_rfl
      · exact (ZMod.val_lt a).le
    have hrc : (r : ZMod d) = a := by
      simp only [hr]; split_ifs with h
      · rw [ZMod.natCast_self]; exact ((ZMod.val_eq_zero a).1 h).symm
      · exact ZMod.natCast_zmod_val a
    have := Finset.card_le_card_of_injOn (s := range (x / d))
      (t := (Icc 1 x).filter (fun n : ℕ => (n : ZMod d) = a)) (fun q => d * q + r) ?_ ?_
    · simpa using this
    · intro q hq
      simp only [coe_range, Set.mem_Iio] at hq
      simp only [coe_filter, mem_Icc, Set.mem_ofPred_eq]
      refine ⟨⟨by omega, ?_⟩, ?_⟩
      · have h1 : d * (q + 1) ≤ d * (x / d) := Nat.mul_le_mul_left _ hq
        have h2 : d * (x / d) ≤ x := Nat.mul_div_le x d
        nlinarith
      · push_cast; rw [ZMod.natCast_self, zero_mul, zero_add, hrc]
    · intro q1 _ q2 _ h
      simp only at h
      have : d * q1 = d * q2 := by omega
      exact Nat.eq_of_mul_eq_mul_left hd this
  · have := Finset.card_le_card_of_injOn (t := range (x / d + 1))
      (s := (Icc 1 x).filter (fun n : ℕ => (n : ZMod d) = a)) (fun n => n / d) ?_ ?_
    · simpa using this
    · intro n hn
      simp only [coe_filter, mem_Icc, Set.mem_ofPred_eq] at hn
      simp only [coe_range, Set.mem_Iio]
      have := Nat.div_le_div_right (c := d) hn.1.2
      omega
    · intro n1 hn1 n2 hn2 h
      simp only [coe_filter, mem_Icc, Set.mem_ofPred_eq] at hn1 hn2
      simp only at h
      have hm : n1 % d = n2 % d := by
        rw [← ZMod.natCast_eq_natCast_iff', hn1.2, hn2.2]
      rw [← Nat.div_add_mod n1 d, ← Nat.div_add_mod n2 d, h, hm]

#print axioms brun_count_residue

lemma brun_count_dvd (D : Finset ℕ) (hD : ∀ p ∈ D, p.Prime) (x : ℕ) :
    (x : ℝ) * ∏ p ∈ D, ((if p = 2 then 1 else 2 : ℝ) / p) - ∏ p ∈ D, (if p = 2 then 1 else 2 : ℝ) ≤
      (((Icc 1 x).filter (fun n => ∀ p ∈ D, p ∣ n * (n + 2))).card : ℝ) ∧
    (((Icc 1 x).filter (fun n => ∀ p ∈ D, p ∣ n * (n + 2))).card : ℝ) ≤
      (x : ℝ) * ∏ p ∈ D, ((if p = 2 then 1 else 2 : ℝ) / p) + ∏ p ∈ D, (if p = 2 then 1 else 2 : ℝ) := by
  set d := ∏ i : D, (i : ℕ) with hd
  have hdD : d = ∏ p ∈ D, p := Finset.prod_coe_sort D (fun p => p)
  have hd0 : d ≠ 0 := by
    rw [hdD]; exact Finset.prod_ne_zero_iff.mpr fun p hp => (hD p hp).ne_zero
  have hdpos : 0 < d := Nat.pos_of_ne_zero hd0
  have : NeZero d := ⟨hd0⟩
  set R := (univ.filter fun a : ZMod d => a * (a + 2) = 0) with hR
  have hRc : R.card = ∏ p ∈ D, (if p = 2 then 1 else 2) := by
    rw [hR, ← Fintype.card_subtype]; exact brun_card_roots D hD
  have key : ∀ n : ℕ, (∀ p ∈ D, p ∣ n * (n + 2)) ↔ (n : ZMod d) ∈ R := by
    intro n
    simp only [hR, mem_filter, mem_univ, true_and]
    have : ((n : ZMod d) * ((n : ZMod d) + 2)) = ((n * (n + 2) : ℕ) : ZMod d) := by push_cast; ring
    rw [this, ZMod.natCast_eq_zero_iff, hdD]
    constructor
    · intro h; exact Finset.prod_primes_dvd _ (fun p hp => (hD p hp).prime) h
    · intro h p hp; exact (Finset.dvd_prod_of_mem _ hp).trans h
  have hcard : ((Icc 1 x).filter (fun n => ∀ p ∈ D, p ∣ n * (n + 2))).card =
      ∑ a ∈ R, ((Icc 1 x).filter (fun n : ℕ => (n : ZMod d) = a)).card := by
    rw [card_eq_sum_card_fiberwise (f := fun n : ℕ => (n : ZMod d)) (t := R)]
    · refine sum_congr rfl fun a ha => ?_
      rw [filter_filter]
      refine congrArg card (filter_congr fun n _ => ?_)
      constructor
      · exact And.right
      · intro h; exact ⟨(key n).2 (h ▸ ha), h⟩
    · intro n hn; exact (key n).1 (mem_filter.1 hn).2
  have hlo : R.card * (x / d) ≤ ((Icc 1 x).filter (fun n => ∀ p ∈ D, p ∣ n * (n + 2))).card := by
    rw [hcard, ← smul_eq_mul, ← sum_const]
    exact sum_le_sum fun a _ => (brun_count_residue d x a).1
  have hhi : ((Icc 1 x).filter (fun n => ∀ p ∈ D, p ∣ n * (n + 2))).card ≤ R.card * (x / d + 1) := by
    rw [hcard, ← smul_eq_mul, ← sum_const]
    exact sum_le_sum fun a _ => (brun_count_residue d x a).2
  have hxd : (x : ℝ) / d - 1 ≤ ((x / d : ℕ) : ℝ) := by
    have h1 := Nat.div_add_mod x d
    have h2 := Nat.mod_lt x hdpos
    have h3 : (x : ℝ) ≤ d * ((x / d : ℕ) : ℝ) + d := by
      exact_mod_cast (by nlinarith : x ≤ d * (x / d) + d)
    have hd' : (0 : ℝ) < d := by exact_mod_cast hdpos
    rw [div_sub_one hd'.ne', div_le_iff₀ hd']
    linarith
  have hxd2 : ((x / d : ℕ) : ℝ) ≤ (x : ℝ) / d := Nat.cast_div_le
  have hmain : (x : ℝ) * ∏ p ∈ D, ((if p = 2 then 1 else 2 : ℝ) / p) = (R.card : ℝ) * ((x : ℝ) / d) := by
    rw [prod_div_distrib, hRc, hdD]
    push_cast
    ring
  have hrem : (∏ p ∈ D, (if p = 2 then 1 else 2 : ℝ)) = (R.card : ℝ) := by
    rw [hRc]; push_cast; rfl
  rw [hmain, hrem]
  have hR0 : (0 : ℝ) ≤ R.card := Nat.cast_nonneg _
  constructor
  · have := (Nat.cast_le (α := ℝ)).2 hlo
    push_cast at this
    nlinarith
  · have := (Nat.cast_le (α := ℝ)).2 hhi
    push_cast at this
    nlinarith

#print axioms brun_count_dvd

lemma brun_alt_choose (a m : ℕ) (hm : Even m) :
    (if a = 0 then (1 : ℝ) else 0) ≤ ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j * (a.choose j : ℝ) := by
  cases a with
  | zero =>
    simp only [ite_true]
    rw [sum_range_succ']
    simp
  | succ k =>
    have h := congrArg (Int.cast : ℤ → ℝ) (Int.alternating_sum_range_choose_eq_choose (n := k) (m := m))
    push_cast at h
    rw [h, hm.neg_one_pow]
    simp

#print axioms brun_alt_choose

lemma brun_sieve_aux (x z m : ℕ) (hm : Even m) :
    ((Finset.filter (fun n => ∀ p ∈ primesBelow z, ¬ p ∣ n * (n + 2))
        (Finset.Icc 1 x)).card : ℝ) ≤
      (x : ℝ) * ∑ j ∈ Finset.range (m + 1), (-1 : ℝ) ^ j *
          ∑ D ∈ (primesBelow z).powersetCard j, ∏ p ∈ D, ((if p = 2 then 1 else 2 : ℝ) / p)
        + ∑ j ∈ Finset.range (m + 1),
          ∑ D ∈ (primesBelow z).powersetCard j, ∏ p ∈ D, (if p = 2 then 1 else 2 : ℝ) := by
  set P := primesBelow z with hP
  have hPp : ∀ p ∈ P, p.Prime := fun p hp => prime_of_mem_primesBelow hp
  have hpt : ∀ n, (if (∀ p ∈ P, ¬ p ∣ n * (n + 2)) then (1 : ℝ) else 0) ≤
      ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j *
        ∑ D ∈ P.powersetCard j, (if (∀ p ∈ D, p ∣ n * (n + 2)) then (1 : ℝ) else 0) := by
    intro n
    set A := P.filter (fun p => p ∣ n * (n + 2)) with hA
    have h1 : (∀ p ∈ P, ¬ p ∣ n * (n + 2)) ↔ A.card = 0 := by
      rw [Finset.card_eq_zero, hA, filter_eq_empty_iff]
    have h2 : ∀ j, (∑ D ∈ P.powersetCard j, (if (∀ p ∈ D, p ∣ n * (n + 2)) then (1 : ℝ) else 0))
        = (A.card.choose j : ℝ) := by
      intro j
      rw [← card_powersetCard, sum_boole]
      congr 2
      ext D
      simp only [mem_filter, mem_powersetCard, hA, subset_iff]
      constructor
      · rintro ⟨⟨hs, hc⟩, hd⟩; exact ⟨fun p hp => ⟨hs hp, hd p hp⟩, hc⟩
      · rintro ⟨hs, hc⟩; exact ⟨⟨fun p hp => (hs hp).1, hc⟩, fun p hp => (hs hp).2⟩
    simp_rw [h2]
    have := brun_alt_choose A.card m hm
    simpa only [h1] using this
  calc ((Finset.filter (fun n => ∀ p ∈ P, ¬ p ∣ n * (n + 2)) (Finset.Icc 1 x)).card : ℝ)
      = ∑ n ∈ Icc 1 x, (if (∀ p ∈ P, ¬ p ∣ n * (n + 2)) then (1 : ℝ) else 0) := by
        rw [sum_boole]
    _ ≤ ∑ n ∈ Icc 1 x, ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j *
          ∑ D ∈ P.powersetCard j, (if (∀ p ∈ D, p ∣ n * (n + 2)) then (1 : ℝ) else 0) :=
        sum_le_sum fun n _ => hpt n
    _ = ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j * ∑ D ∈ P.powersetCard j,
          (((Icc 1 x).filter (fun n => ∀ p ∈ D, p ∣ n * (n + 2))).card : ℝ) := by
        rw [sum_comm]
        refine sum_congr rfl fun j _ => ?_
        rw [← mul_sum, sum_comm]
        congr 1
        refine sum_congr rfl fun D _ => ?_
        rw [sum_boole]
    _ ≤ ∑ j ∈ range (m + 1), ∑ D ∈ P.powersetCard j,
          ((-1 : ℝ) ^ j * ((x : ℝ) * ∏ p ∈ D, ((if p = 2 then 1 else 2 : ℝ) / p)) +
            ∏ p ∈ D, (if p = 2 then 1 else 2 : ℝ)) := by
        refine sum_le_sum fun j _ => ?_
        rw [mul_sum]
        refine sum_le_sum fun D hD => ?_
        have hDp : ∀ p ∈ D, p.Prime := fun p hp => hPp p ((mem_powersetCard.1 hD).1 hp)
        obtain ⟨h1, h2⟩ := brun_count_dvd D hDp x
        rcases neg_one_pow_eq_or ℝ j with h | h <;> rw [h] <;> linarith
    _ = _ := by
        simp only [sum_add_distrib, mul_sum]
        congr 1
        refine sum_congr rfl fun j _ => sum_congr rfl fun D _ => by ring

#print axioms brun_sieve_aux

lemma brun_esymm_zero (g : ℕ → ℝ) (P : Finset ℕ) : (∑ D ∈ Finset.powersetCard 0 P, ∏ p ∈ D, g p) = 1 := by
  simp

#print axioms brun_esymm_zero

lemma brun_esymm_empty_succ (g : ℕ → ℝ) (j : ℕ) : (∑ D ∈ Finset.powersetCard (j + 1) ∅, ∏ p ∈ D, g p) = 0 := by
  rw [powersetCard_eq_empty.2 (by simp)]; simp

#print axioms brun_esymm_empty_succ

lemma brun_esymm_nonneg (g : ℕ → ℝ) (P : Finset ℕ) (hg : ∀ p ∈ P, 0 ≤ g p) (j : ℕ) :
    0 ≤ (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p) :=
  sum_nonneg fun _ hD => prod_nonneg fun p hp => hg p ((mem_powersetCard.1 hD).1 hp)

#print axioms brun_esymm_nonneg

lemma brun_esymm_insert (g : ℕ → ℝ) (P : Finset ℕ) (q : ℕ) (hq : q ∉ P) (j : ℕ) :
    (∑ D ∈ Finset.powersetCard (j + 1) (insert q P), ∏ p ∈ D, g p) = (∑ D ∈ Finset.powersetCard (j + 1) P, ∏ p ∈ D, g p) + g q * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p) := by
  rw [powersetCard_succ_insert hq, sum_union, sum_image, mul_sum]
  · congr 1
    refine sum_congr rfl fun D hD => ?_
    have : q ∉ D := fun h => hq ((mem_powersetCard.1 hD).1 h)
    rw [prod_insert this]
  · intro D1 hD1 D2 hD2 h
    have h1 : q ∉ D1 := fun h' => hq ((mem_powersetCard.1 hD1).1 h')
    have h2 : q ∉ D2 := fun h' => hq ((mem_powersetCard.1 hD2).1 h')
    rw [← erase_insert h1, ← erase_insert h2]
    exact congrArg (fun s => Finset.erase s q) h
  · rw [disjoint_left]
    intro D hD hD'
    obtain ⟨E, _, rfl⟩ := mem_image.1 hD'
    exact hq ((mem_powersetCard.1 hD).1 (mem_insert_self q E))

#print axioms brun_esymm_insert

lemma brun_trunc_insert (g : ℕ → ℝ) (P : Finset ℕ) (q : ℕ) (hq : q ∉ P) (m : ℕ) :
    ∑ j ∈ range (m + 2), (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j (insert q P), ∏ p ∈ D, g p) =
      ∑ j ∈ range (m + 2), (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p) -
        g q * ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p) := by
  induction m with
  | zero =>
    simp only [zero_add, sum_range_succ, sum_range_zero, brun_esymm_zero]
    rw [show (1 : ℕ) = 0 + 1 from rfl, brun_esymm_insert g P q hq 0, brun_esymm_zero]
    ring
  | succ m ih =>
    rw [sum_range_succ, ih, sum_range_succ (fun j => (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p)) (m + 2),
      sum_range_succ (fun j => (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p)) (m + 1),
      show m + 2 = (m + 1) + 1 from rfl, brun_esymm_insert g P q hq (m + 1)]
    simp only [pow_succ]
    ring

#print axioms brun_trunc_insert

/-- Bonferroni for products: truncating `∏ (1 - g p) = Σ (-1)^j e_j` errs by at most the next
term, with alternating sign. -/
lemma brun_bonferroni (g : ℕ → ℝ) (P : Finset ℕ) (hg : ∀ p ∈ P, 0 ≤ g p ∧ g p ≤ 1) (m : ℕ) :
    0 ≤ (-1 : ℝ) ^ (m + 1) * (∏ p ∈ P, (1 - g p) -
        ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p)) ∧
      (-1 : ℝ) ^ (m + 1) * (∏ p ∈ P, (1 - g p) -
        ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p)) ≤ (∑ D ∈ Finset.powersetCard (m + 1) P, ∏ p ∈ D, g p) := by
  induction P using Finset.induction_on generalizing m with
  | empty =>
    have : ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j ∅, ∏ p ∈ D, g p) = 1 := by
      rw [sum_range_succ']
      simp [brun_esymm_empty_succ]
    rw [this, brun_esymm_empty_succ]
    simp
  | insert q P hq ih =>
    have hg' : ∀ p ∈ P, 0 ≤ g p ∧ g p ≤ 1 := fun p hp => hg p (mem_insert_of_mem hp)
    have hgq := hg q (mem_insert_self q P)
    have hP0 : 0 ≤ ∏ p ∈ P, (1 - g p) := prod_nonneg fun p hp => by linarith [(hg' p hp).2]
    have hP1 : ∏ p ∈ P, (1 - g p) ≤ 1 :=
      prod_le_one₀ (fun p hp => by linarith [(hg' p hp).2]) fun p hp => by linarith [(hg' p hp).1]
    rw [prod_insert hq]
    cases m with
    | zero =>
      simp only [zero_add, sum_range_one, pow_zero, brun_esymm_zero, one_mul, pow_one]
      rw [show (1 : ℕ) = 0 + 1 from rfl, brun_esymm_insert g P q hq 0, brun_esymm_zero]
      have := ih hg' 0
      simp only [zero_add, sum_range_one, pow_zero, brun_esymm_zero, one_mul, pow_one] at this
      constructor <;> nlinarith [this.1, this.2]
    | succ m =>
      rw [brun_trunc_insert g P q hq m, brun_esymm_insert g P q hq (m + 1)]
      obtain ⟨a1, a2⟩ := ih hg' (m + 1)
      obtain ⟨b1, b2⟩ := ih hg' m
      set S1 := ∑ j ∈ range (m + 2), (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p)
      set S0 := ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p)
      set Pp := ∏ p ∈ P, (1 - g p)
      set s := (-1 : ℝ) ^ (m + 1)
      have hs : (-1 : ℝ) ^ (m + 1 + 1) = -s := by rw [pow_succ]; ring
      rw [hs] at a1 a2 ⊢
      have key : -s * ((1 - g q) * Pp - (S1 - g q * S0)) = -s * (Pp - S1) + g q * (s * (Pp - S0)) := by
        ring
      rw [key]
      constructor
      · nlinarith [mul_nonneg hgq.1 b1]
      · nlinarith [mul_le_mul_of_nonneg_left b2 hgq.1]

#print axioms brun_bonferroni

lemma brun_trunc_le (g : ℕ → ℝ) (P : Finset ℕ) (hg : ∀ p ∈ P, 0 ≤ g p ∧ g p ≤ 1) (m : ℕ)
    (hm : Even m) :
    ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p) ≤ ∏ p ∈ P, (1 - g p) + (∑ D ∈ Finset.powersetCard (m + 1) P, ∏ p ∈ D, g p) := by
  have := (brun_bonferroni g P hg m).2
  rw [pow_succ, hm.neg_one_pow] at this
  linarith

#print axioms brun_trunc_le

lemma brun_pow_bern (s g : ℝ) (hs : 0 ≤ s) (hg : 0 ≤ g) (k : ℕ) :
    s ^ (k + 1) + (k + 1) * g * s ^ k ≤ (s + g) ^ (k + 1) := by
  induction k with
  | zero => simp
  | succ k ih =>
    have h1 : 0 ≤ s + g := by linarith
    have h2 : 0 ≤ g * s ^ k := mul_nonneg hg (pow_nonneg hs k)
    calc s ^ (k + 1 + 1) + ((k + 1 : ℕ) + 1 : ℝ) * g * s ^ (k + 1)
        ≤ (s + g) * (s ^ (k + 1) + (k + 1) * g * s ^ k) := by
          push_cast
          have : 0 ≤ (k + 1 : ℝ) * g * g * s ^ k := by positivity
          have e : (s + g) * (s ^ (k + 1) + (k + 1) * g * s ^ k) = s ^ (k + 1 + 1) +
              ((k : ℝ) + 1 + 1) * g * s ^ (k + 1) + (k + 1) * g * g * s ^ k := by ring
          linarith
      _ ≤ (s + g) * (s + g) ^ (k + 1) := mul_le_mul_of_nonneg_left ih h1
      _ = (s + g) ^ (k + 1 + 1) := by ring

#print axioms brun_pow_bern

lemma brun_esymm_le (g : ℕ → ℝ) (P : Finset ℕ) (hg : ∀ p ∈ P, 0 ≤ g p) (k : ℕ) :
    (∑ D ∈ Finset.powersetCard k P, ∏ p ∈ D, g p) ≤ (∑ p ∈ P, g p) ^ k / (k ! : ℝ) := by
  induction P using Finset.induction_on generalizing k with
  | empty =>
    cases k with
    | zero => simp
    | succ k => simp [brun_esymm_empty_succ]
  | insert q P hq ih =>
    have hg' : ∀ p ∈ P, 0 ≤ g p := fun p hp => hg p (mem_insert_of_mem hp)
    have hgq := hg q (mem_insert_self q P)
    cases k with
    | zero => simp
    | succ k =>
      rw [brun_esymm_insert g P q hq k, sum_insert hq]
      have hs : 0 ≤ ∑ p ∈ P, g p := sum_nonneg hg'
      have h1 := ih hg' (k + 1)
      have h2 := ih hg' k
      have hb := brun_pow_bern (∑ p ∈ P, g p) (g q) hs hgq k
      have hf : ((k + 1) ! : ℝ) = (k + 1) * (k ! : ℝ) := by push_cast [Nat.factorial_succ]; ring
      have hk : (0 : ℝ) < k ! := by exact_mod_cast Nat.factorial_pos k
      rw [hf] at h1 ⊢
      rw [le_div_iff₀ (by positivity)] at h1 ⊢
      rw [le_div_iff₀ hk] at h2
      have : g q * (∑ D ∈ Finset.powersetCard k P, ∏ p ∈ D, g p) * ((k + 1) * k !) ≤ g q * (k + 1) * (∑ p ∈ P, g p) ^ k := by
        have := mul_le_mul_of_nonneg_left h2 hgq
        nlinarith [this]
      rw [add_mul, add_comm (g q)]
      linarith [this, h1, hb]

#print axioms brun_esymm_le

lemma brun_log_le_prod (n : ℕ) :
    Real.log ((n + 1 : ℕ) : ℝ) ≤ ∏ p ∈ primesBelow (n + 1), (1 - (p : ℝ)⁻¹)⁻¹ := by
  classical
  let f : ℕ →* ℝ :=
    { toFun := fun k => (k : ℝ)⁻¹, map_one' := by simp,
      map_mul' := fun a b => by push_cast; exact mul_inv (a : ℝ) b }
  have hf : ∀ {p : ℕ}, p.Prime → ‖f p‖ < 1 := by
    intro p hp
    simp only [f, MonoidHom.coe_mk, OneHom.coe_mk, norm_inv, Real.norm_natCast]
    exact inv_lt_one_of_one_lt₀ (by exact_mod_cast hp.one_lt)
  obtain ⟨-, hsum⟩ :=
    EulerProduct.summable_and_hasSum_smoothNumbers_prod_primesBelow_geometric hf (n + 1)
  have h1 := sum_le_hasSum ((Icc 1 n).subtype (· ∈ (n + 1).smoothNumbers))
    (fun i _ => by simp [f]) hsum
  rw [sum_subtype_eq_sum_filter (f := fun m => f m)] at h1
  have hfil : (Icc 1 n).filter (· ∈ (n + 1).smoothNumbers) = Icc 1 n :=
    filter_true_of_mem fun i hi => by
      rw [mem_Icc] at hi
      exact Nat.mem_smoothNumbers_of_lt (by omega) (by omega)
  rw [hfil] at h1
  have hlog := log_add_one_le_harmonic n
  rw [harmonic_eq_sum_Icc] at hlog
  push_cast at hlog
  calc Real.log ((n + 1 : ℕ) : ℝ) ≤ ∑ i ∈ Icc 1 n, (i : ℝ)⁻¹ := by push_cast; exact hlog
    _ = ∑ i ∈ Icc 1 n, f i := rfl
    _ ≤ ∏ p ∈ primesBelow (n + 1), (1 - f p)⁻¹ := h1
    _ = ∏ p ∈ primesBelow (n + 1), (1 - (p : ℝ)⁻¹)⁻¹ := rfl

#print axioms brun_log_le_prod

lemma brun_prod_le (z : ℕ) (hz : 2 ≤ z) :
    ∏ p ∈ primesBelow z, (1 - (if p = 2 then 1 else 2 : ℝ) / p) ≤ 2 / Real.log z ^ 2 := by
  set Q := ∏ p ∈ primesBelow z, (1 - (p : ℝ)⁻¹) with hQ
  have hp2 : ∀ p ∈ primesBelow z, (2 : ℝ) ≤ p := fun p hp => by
    exact_mod_cast (prime_of_mem_primesBelow hp).two_le
  have hQpos : 0 < Q := prod_pos fun p hp => by
    have := hp2 p hp
    have : (p : ℝ)⁻¹ < 1 := inv_lt_one_of_one_lt₀ (by linarith)
    linarith
  have hL : 0 < Real.log z := Real.log_pos (by exact_mod_cast hz)
  have hlog : Real.log z ≤ Q⁻¹ := by
    have := brun_log_le_prod (z - 1)
    rw [Nat.sub_add_cancel (by omega : 1 ≤ z), prod_inv_distrib] at this
    exact this
  have hQ1 : Q ≤ (Real.log z)⁻¹ := by
    rw [le_inv_comm₀ hQpos hL]; exact hlog
  have hpt : ∀ p ∈ primesBelow z, 0 ≤ 1 - (if p = 2 then 1 else 2 : ℝ) / p ∧
      1 - (if p = 2 then 1 else 2 : ℝ) / p ≤ (if p = 2 then 2 else 1 : ℝ) * (1 - (p : ℝ)⁻¹) ^ 2 := by
    intro p hp
    have hpp := prime_of_mem_primesBelow hp
    have h2 := hp2 p hp
    split_ifs with h
    · subst h; norm_num
    · have h3 : (3 : ℝ) ≤ p := by
        have := hpp.two_le
        have : 3 ≤ p := by omega
        exact_mod_cast this
      have hi : (p : ℝ)⁻¹ ≤ 1 / 3 := by
        rw [inv_eq_one_div]; exact one_div_le_one_div_of_le (by norm_num) h3
      have hi0 : 0 ≤ (p : ℝ)⁻¹ := by positivity
      rw [div_eq_mul_inv]
      constructor <;> nlinarith [sq_nonneg (p : ℝ)⁻¹]
  calc ∏ p ∈ primesBelow z, (1 - (if p = 2 then 1 else 2 : ℝ) / p)
      ≤ ∏ p ∈ primesBelow z, ((if p = 2 then 2 else 1 : ℝ) * (1 - (p : ℝ)⁻¹) ^ 2) :=
        prod_le_prod₀ (fun p hp => (hpt p hp).1) fun p hp => (hpt p hp).2
    _ = (∏ p ∈ primesBelow z, (if p = 2 then 2 else 1 : ℝ)) * Q ^ 2 := by
        rw [prod_mul_distrib, prod_pow]
    _ ≤ 2 * ((Real.log z)⁻¹) ^ 2 := by
        have hk : (∏ p ∈ primesBelow z, (if p = 2 then 2 else 1 : ℝ)) ≤ 2 := by
          rw [prod_ite_eq']; split_ifs <;> norm_num
        have hk0 : 0 ≤ (∏ p ∈ primesBelow z, (if p = 2 then 2 else 1 : ℝ)) :=
          prod_nonneg fun p _ => by split_ifs <;> norm_num
        have hq2 : Q ^ 2 ≤ ((Real.log z)⁻¹) ^ 2 := pow_le_pow_left₀ hQpos.le hQ1 2
        calc _ ≤ 2 * Q ^ 2 := mul_le_mul_of_nonneg_right hk (sq_nonneg _)
          _ ≤ _ := by linarith
    _ = 2 / Real.log z ^ 2 := by rw [inv_pow, div_eq_mul_inv]

#print axioms brun_prod_le

lemma brun_block (k : ℕ) (hk : 1 ≤ k) :
    ∑ p ∈ (Ico (2 ^ k) (2 ^ (k + 1))).filter Nat.Prime, (p : ℝ)⁻¹ ≤ 4 / k := by
  set B := (Ico (2 ^ k) (2 ^ (k + 1))).filter Nat.Prime with hB
  have hc : k * B.card ≤ 4 * 2 ^ k := by
    have h1 : (2 ^ k) ^ B.card ≤ ∏ p ∈ B, p :=
      Finset.pow_card_le_prod B (fun p => p) (2 ^ k)
        (fun p hp => (mem_Ico.1 (mem_filter.1 hp).1).1)
    have h2 : ∏ p ∈ B, p ≤ primorial (2 ^ (k + 1)) := by
      rw [primorial_eq_prod_primesLE]
      apply prod_le_prod_of_subset_of_one_le
      · intro p hp
        rw [mem_primesLE]
        exact ⟨(mem_Ico.1 (mem_filter.1 hp).1).2.le, (mem_filter.1 hp).2⟩
      · intro p hp _
        exact (prime_of_mem_primesBelow hp).one_lt.le
    have h3 := primorial_le_four_pow (2 ^ (k + 1))
    have h4 : 2 ^ (k * B.card) ≤ 2 ^ (2 * 2 ^ (k + 1)) := by
      rw [pow_mul, pow_mul]
      calc (2 ^ k) ^ B.card ≤ _ := h1
        _ ≤ _ := h2
        _ ≤ 4 ^ (2 ^ (k + 1)) := h3
        _ = (2 ^ 2) ^ (2 ^ (k + 1)) := by norm_num
    have h5 := (Nat.pow_le_pow_iff_right (by norm_num : 1 < 2)).1 h4
    rw [pow_succ] at h5
    linarith
  have h2k : (0 : ℝ) < 2 ^ k := by positivity
  calc ∑ p ∈ B, (p : ℝ)⁻¹ ≤ ∑ p ∈ B, ((2 : ℝ) ^ k)⁻¹ := by
        refine sum_le_sum fun p hp => ?_
        apply inv_anti₀ h2k
        exact_mod_cast (mem_Ico.1 (mem_filter.1 hp).1).1
    _ = B.card / 2 ^ k := by rw [sum_const, nsmul_eq_mul, div_eq_mul_inv]
    _ ≤ 4 / k := by
        have hk' : (0 : ℝ) < k := by exact_mod_cast hk
        rw [div_le_div_iff₀ h2k hk']
        have : ((k * B.card : ℕ) : ℝ) ≤ ((4 * 2 ^ k : ℕ) : ℝ) := by exact_mod_cast hc
        push_cast at this
        linarith

#print axioms brun_block

lemma brun_sum_inv_primes (K : ℕ) :
    ∑ p ∈ primesBelow (2 ^ (K + 1)), (p : ℝ)⁻¹ ≤ 4 * ∑ k ∈ Icc 1 K, (k : ℝ)⁻¹ := by
  induction K with
  | zero =>
    have : primesBelow (2 ^ (0 + 1)) = ∅ := by decide
    rw [this]; simp
  | succ K ih =>
    have hsplit : ∑ p ∈ primesBelow (2 ^ (K + 1 + 1)), (p : ℝ)⁻¹ =
        ∑ p ∈ primesBelow (2 ^ (K + 1)), (p : ℝ)⁻¹ +
          ∑ p ∈ (Ico (2 ^ (K + 1)) (2 ^ (K + 1 + 1))).filter Nat.Prime, (p : ℝ)⁻¹ := by
      simp only [primesBelow, sum_filter]
      rw [sum_range_add_sum_Ico _ (Nat.pow_le_pow_right (by norm_num) (by omega))]
    rw [hsplit, sum_Icc_succ_top (by omega), mul_add]
    have := brun_block (K + 1) (by omega)
    push_cast at this ⊢
    rw [div_eq_mul_inv] at this
    linarith

#print axioms brun_sum_inv_primes

lemma brun_sum_inv_primes' (K : ℕ) (hK : 1 ≤ K) :
    ∑ p ∈ primesBelow (2 ^ K), (p : ℝ)⁻¹ ≤ 4 * (1 + Real.log K) := by
  obtain ⟨K', rfl⟩ : ∃ K', K = K' + 1 := ⟨K - 1, by omega⟩
  have h1 := brun_sum_inv_primes K'
  have h2 := harmonic_le_one_add_log K'
  rw [harmonic_eq_sum_Icc] at h2
  push_cast at h2
  have h3 : Real.log K' ≤ Real.log ((K' + 1 : ℕ) : ℝ) := by
    rcases Nat.eq_zero_or_pos K' with h | h
    · subst h; simp
    · exact Real.log_le_log (by exact_mod_cast h) (by push_cast; linarith)
  linarith

#print axioms brun_sum_inv_primes'

lemma brun_twin_subset (N z : ℕ) :
    ((Finset.range (N + 1)).filter (fun p => p.Prime ∧ (p + 2).Prime)).card ≤
      z + ((Finset.Icc 1 N).filter (fun n => ∀ p ∈ primesBelow z, ¬ p ∣ n * (n + 2))).card := by
  calc _ ≤ (range z ∪ (Finset.Icc 1 N).filter (fun n => ∀ p ∈ primesBelow z, ¬ p ∣ n * (n + 2))).card := by
        apply card_le_card
        intro p hp
        rw [mem_filter, mem_range] at hp
        obtain ⟨hpN, hp1, hp2⟩ := hp
        rw [mem_union, mem_range, mem_filter, mem_Icc]
        by_cases hpz : p < z
        · exact Or.inl hpz
        · right
          refine ⟨⟨hp1.one_lt.le, by omega⟩, fun q hq hdvd => ?_⟩
          have hqp := prime_of_mem_primesBelow hq
          have hqz := lt_of_mem_primesBelow hq
          rcases (Nat.Prime.dvd_mul hqp).1 hdvd with h | h
          · have := (Nat.prime_dvd_prime_iff_eq hqp hp1).1 h; omega
          · have := (Nat.prime_dvd_prime_iff_eq hqp hp2).1 h; omega
    _ ≤ (range z).card + _ := card_union_le _ _
    _ = _ := by rw [card_range]

#print axioms brun_twin_subset

lemma brun_pi2_explicit (x : ℝ) (hx : 0 ≤ x) (K m : ℕ) (hm : Even m) (hK : 1 ≤ K) :
    (((Finset.range (⌊x⌋₊ + 1)).filter (fun p => p.Prime ∧ (p + 2).Prime)).card : ℝ) ≤
      2 ^ K + x * (2 / (K * Real.log 2) ^ 2 + (8 * (1 + Real.log K)) ^ (m + 1) / ((m + 1)! : ℝ)) +
        (m + 1) * (2 * 2 ^ K) ^ m := by
  set N := ⌊x⌋₊ with hN
  set z := 2 ^ K with hz
  have hz2 : 2 ≤ z := by
    calc 2 = 2 ^ 1 := rfl
      _ ≤ 2 ^ K := Nat.pow_le_pow_right (by norm_num) hK
  set P := primesBelow z with hP
  set g : ℕ → ℝ := fun p => (if p = 2 then 1 else 2 : ℝ) / p with hg
  set ρ : ℕ → ℝ := fun p => (if p = 2 then 1 else 2 : ℝ) with hρ
  have ha := brun_twin_subset N z
  have hb : (((Finset.Icc 1 N).filter (fun n => ∀ p ∈ P, ¬ p ∣ n * (n + 2))).card : ℝ) ≤
      (N : ℝ) * ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p) +
        ∑ j ∈ range (m + 1), (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, ρ p) :=
    brun_sieve_aux N z m hm
  have hPp : ∀ p ∈ P, (2 : ℝ) ≤ p := fun p hp => by
    exact_mod_cast (prime_of_mem_primesBelow hp).two_le
  have hg01 : ∀ p ∈ P, 0 ≤ g p ∧ g p ≤ 1 := by
    intro p hp
    have := hPp p hp
    simp only [hg]
    constructor
    · split_ifs <;> positivity
    · rw [div_le_one (by linarith)]; split_ifs <;> linarith
  have hc := brun_trunc_le g P hg01 m hm
  have hd := brun_prod_le z hz2
  have hlogz : Real.log (z : ℝ) = K * Real.log 2 := by
    rw [hz]; push_cast; rw [Real.log_pow]
  rw [hlogz] at hd
  have hE := brun_esymm_le g P (fun p hp => (hg01 p hp).1) (m + 1)
  have hsg : ∑ p ∈ P, g p ≤ 8 * (1 + Real.log K) := by
    have h1 : ∑ p ∈ P, g p ≤ ∑ p ∈ P, 2 * (p : ℝ)⁻¹ := by
      refine sum_le_sum fun p hp => ?_
      have := hPp p hp
      simp only [hg]
      rw [div_eq_mul_inv]
      apply mul_le_mul_of_nonneg_right _ (by positivity)
      split_ifs <;> norm_num
    rw [← mul_sum] at h1
    have h2 := brun_sum_inv_primes' K hK
    linarith
  have hsg0 : 0 ≤ ∑ p ∈ P, g p := sum_nonneg fun p hp => (hg01 p hp).1
  have hE' : (∑ D ∈ Finset.powersetCard (m + 1) P, ∏ p ∈ D, g p) ≤ (8 * (1 + Real.log K)) ^ (m + 1) / ((m + 1)! : ℝ) := by
    refine hE.trans (div_le_div_of_nonneg_right (pow_le_pow_left₀ hsg0 hsg _) (by positivity))
  have hR : ∑ j ∈ range (m + 1), (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, ρ p) ≤ (m + 1) * (2 * 2 ^ K) ^ m := by
    have hρ0 : ∀ p ∈ P, 0 ≤ ρ p := fun p _ => by simp only [hρ]; split_ifs <;> norm_num
    have hsr : ∑ p ∈ P, ρ p ≤ 2 * 2 ^ K := by
      calc ∑ p ∈ P, ρ p ≤ ∑ p ∈ P, (2 : ℝ) := sum_le_sum fun p _ => by
            simp only [hρ]; split_ifs <;> norm_num
        _ = 2 * P.card := by rw [sum_const, nsmul_eq_mul, mul_comm]
        _ ≤ 2 * 2 ^ K := by
            have : P.card ≤ z := by
              rw [hP, primesBelow]; exact (card_filter_le _ _).trans (card_range z).le
            have : (P.card : ℝ) ≤ (2 : ℝ) ^ K := by rw [hz] at this; exact_mod_cast this
            linarith
    have hsr0 : 0 ≤ ∑ p ∈ P, ρ p := sum_nonneg hρ0
    have h1 : (1 : ℝ) ≤ 2 * 2 ^ K := by
      have : (1 : ℝ) ≤ 2 ^ K := one_le_pow₀ (by norm_num)
      linarith
    calc ∑ j ∈ range (m + 1), (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, ρ p) ≤ ∑ j ∈ range (m + 1), (2 * (2 : ℝ) ^ K) ^ m := by
          refine sum_le_sum fun j hj => ?_
          have hjm : j ≤ m := Nat.lt_succ_iff.1 (mem_range.1 hj)
          calc (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, ρ p) ≤ (∑ p ∈ P, ρ p) ^ j / (j ! : ℝ) := brun_esymm_le ρ P hρ0 j
            _ ≤ (∑ p ∈ P, ρ p) ^ j :=
                div_le_self (pow_nonneg hsr0 _) (by exact_mod_cast Nat.one_le_iff_ne_zero.2 (Nat.factorial_ne_zero j))
            _ ≤ (2 * 2 ^ K) ^ j := pow_le_pow_left₀ hsr0 hsr _
            _ ≤ (2 * 2 ^ K) ^ m := pow_le_pow_right₀ h1 hjm
      _ = (m + 1) * (2 * 2 ^ K) ^ m := by rw [sum_const, card_range, nsmul_eq_mul]; push_cast; ring
  have hPi0 : 0 ≤ ∏ p ∈ P, (1 - g p) := prod_nonneg fun p hp => by linarith [(hg01 p hp).2]
  have hE0 : 0 ≤ (∑ D ∈ Finset.powersetCard (m + 1) P, ∏ p ∈ D, g p) := brun_esymm_nonneg g P (fun p hp => (hg01 p hp).1) _
  have hNx : (N : ℝ) ≤ x := Nat.floor_le hx
  have hN0 : (0 : ℝ) ≤ N := Nat.cast_nonneg _
  have hmain : (N : ℝ) * ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p) ≤
      x * (2 / (K * Real.log 2) ^ 2 + (8 * (1 + Real.log K)) ^ (m + 1) / ((m + 1)! : ℝ)) := by
    calc (N : ℝ) * ∑ j ∈ range (m + 1), (-1 : ℝ) ^ j * (∑ D ∈ Finset.powersetCard j P, ∏ p ∈ D, g p)
        ≤ N * (∏ p ∈ P, (1 - g p) + (∑ D ∈ Finset.powersetCard (m + 1) P, ∏ p ∈ D, g p)) := mul_le_mul_of_nonneg_left hc hN0
      _ ≤ x * (∏ p ∈ P, (1 - g p) + (∑ D ∈ Finset.powersetCard (m + 1) P, ∏ p ∈ D, g p)) :=
          mul_le_mul_of_nonneg_right hNx (by linarith)
      _ ≤ _ := by
          apply mul_le_mul_of_nonneg_left _ hx
          have : ∏ p ∈ P, (1 - g p) ≤ 2 / (K * Real.log 2) ^ 2 := hd
          linarith
  have ha' : (((Finset.range (N + 1)).filter (fun p => p.Prime ∧ (p + 2).Prime)).card : ℝ) ≤
      (2 : ℝ) ^ K + (((Finset.Icc 1 N).filter (fun n => ∀ p ∈ P, ¬ p ∣ n * (n + 2))).card : ℝ) := by
    have := (Nat.cast_le (α := ℝ)).2 ha
    push_cast at this
    rw [hz] at this; push_cast at this
    exact this
  linarith

#print axioms brun_pi2_explicit

lemma brun_final (x : ℝ) (hx0 : 0 < x) (hT : 1000 ≤ Real.log x)
    (hu : Real.log (Real.log x) ≤ Real.log x / 1000) :
    (((Finset.range (⌊x⌋₊ + 1)).filter (fun p => p.Prime ∧ (p + 2).Prime)).card : ℝ) ≤
      627203 * (x * Real.log (Real.log x) ^ 2 / Real.log x ^ 2) := by
  set T := Real.log x with hTdef
  set u := Real.log T with hudef
  have hT0 : 0 < T := by linarith
  have hu1 : 1 ≤ u := by
    have h1 : Real.log 1000 ≤ u := Real.log_le_log (by norm_num) hT
    have h2 : 1 < Real.log 1000 := by
      rw [Real.lt_log_iff_exp_lt (by norm_num)]
      have := Real.exp_one_lt_d9; linarith
    linarith
  set a : ℕ := ⌊u⌋₊ + 1 with ha
  have ha1 : u < a := by rw [ha]; push_cast; exact Nat.lt_floor_add_one u
  have ha2 : (a : ℝ) ≤ u + 1 := by
    rw [ha]; push_cast; linarith [Nat.floor_le (by linarith : 0 ≤ u)]
  have ha0 : (1 : ℝ) ≤ a := by linarith
  set m : ℕ := 26 * a + 24 with hm
  have hmeven : Even m := ⟨13 * a + 12, by omega⟩
  have hmr : (m : ℝ) = 26 * a + 24 := by rw [hm]; push_cast; ring
  clear_value m
  set K : ℕ := ⌊T / (70 * a)⌋₊ with hK
  have hTa : 140 * (a : ℝ) ≤ T := by linarith
  have hK1 : (K : ℝ) ≤ T / (70 * a) := Nat.floor_le (by positivity)
  have hK2 : T / (70 * a) - 1 < K := by
    have := Nat.lt_floor_add_one (T / (70 * a)); linarith
  have hTa2 : 2 ≤ T / (70 * a) := by
    rw [le_div_iff₀ (by positivity)]; linarith
  have hKpos : 1 ≤ K := by
    rw [hK, Nat.one_le_floor_iff]; linarith
  have hKr : (1 : ℝ) ≤ K := by exact_mod_cast hKpos
  clear_value K
  have hKT : (K : ℝ) ≤ T / 70 :=
    hK1.trans (div_le_div_of_nonneg_left hT0.le (by norm_num) (by linarith))
  have hKlow : T / (280 * u) ≤ K := by
    have h1 : T / (140 * a) = T / (70 * a) / 2 := by field_simp; ring
    have h2 : T / (280 * u) ≤ T / (140 * a) :=
      div_le_div_of_nonneg_left hT0.le (by positivity) (by linarith)
    linarith
  have hmain := brun_pi2_explicit x hx0.le K m hmeven hKpos
  set B := Real.exp (T - 2 * u) with hB
  have hexpT : Real.exp T = x := Real.exp_log hx0
  have hexpu : Real.exp u = T := Real.exp_log hT0
  have hBx : B = x / T ^ 2 := by
    rw [hB, Real.exp_sub, hexpT, show 2 * u = u + u by ring, Real.exp_add, hexpu]; ring
  have hxe : x * Real.exp (-2 * u) = B := by
    rw [hB, ← hexpT, ← Real.exp_add]; ring_nf
  have he1 : (2 : ℝ) ≤ Real.exp 1 := by linarith [Real.add_one_le_exp (1 : ℝ)]
  have hpow2 : ∀ n : ℕ, (2 : ℝ) ^ n ≤ Real.exp n := fun n => by
    rw [← Real.exp_one_pow]; exact pow_le_pow_left₀ (by norm_num) he1 n
  -- piece 1
  have hP1 : (2 : ℝ) ^ K ≤ B := by
    refine (hpow2 K).trans (Real.exp_le_exp.2 ?_)
    linarith
  -- piece 2
  have hlogK : Real.log K ≤ u := Real.log_le_log (by linarith) (by linarith)
  have hlogK0 : 0 ≤ Real.log K := Real.log_nonneg hKr
  set σ := 8 * (1 + Real.log K) with hσ
  have hσ0 : 0 ≤ σ := by positivity
  have hP2 : σ ^ (m + 1) / ((m + 1)! : ℝ) ≤ Real.exp (-2 * u) := by
    have h1 := Real.pow_div_factorial_le_exp (3 * σ) (by positivity) (m + 1)
    rw [mul_pow] at h1
    have h3 : Real.exp ((m + 1 : ℕ) : ℝ) ≤ 3 ^ (m + 1) := by
      rw [← Real.exp_one_pow]
      exact pow_le_pow_left₀ (Real.exp_pos 1).le (by linarith [Real.exp_one_lt_d9]) _
    have hf : (0 : ℝ) < (m + 1)! := by exact_mod_cast Nat.factorial_pos _
    have hq0 : 0 ≤ σ ^ (m + 1) / ((m + 1)! : ℝ) := by positivity
    have h4 : σ ^ (m + 1) / ((m + 1)! : ℝ) ≤ Real.exp (3 * σ) / Real.exp ((m + 1 : ℕ) : ℝ) := by
      rw [le_div_iff₀ (Real.exp_pos _)]
      calc _ ≤ σ ^ (m + 1) / ((m + 1)! : ℝ) * 3 ^ (m + 1) := mul_le_mul_of_nonneg_left h3 hq0
        _ = 3 ^ (m + 1) * σ ^ (m + 1) / ((m + 1)! : ℝ) := by ring
        _ ≤ _ := h1
    refine h4.trans ?_
    rw [← Real.exp_sub, Real.exp_le_exp]
    push_cast
    rw [hmr]
    linarith
  -- piece 3
  have hP3 : ((m : ℝ) + 1) * (2 * 2 ^ K) ^ m ≤ B := by
    have h1 : ((m : ℝ) + 1) ≤ 2 ^ m := by
      have := Nat.lt_two_pow_self (n := m)
      have : m + 1 ≤ 2 ^ m := this
      exact_mod_cast this
    have h2 : ((m : ℝ) + 1) * (2 * 2 ^ K) ^ m ≤ 2 ^ ((K + 2) * m) := by
      calc ((m : ℝ) + 1) * (2 * 2 ^ K) ^ m ≤ 2 ^ m * (2 * 2 ^ K) ^ m :=
            mul_le_mul_of_nonneg_right h1 (by positivity)
        _ = 2 ^ ((K + 2) * m) := by
            rw [← mul_pow, pow_mul]; congr 1; ring
    refine h2.trans ((hpow2 _).trans (Real.exp_le_exp.2 ?_))
    push_cast
    have h3 : ((K : ℝ) + 2) * m ≤ (T / (70 * a) + 2) * (50 * a) :=
      mul_le_mul (by linarith) (by rw [hmr]; linarith) (by positivity) (by positivity)
    have h4 : (T / (70 * a) + 2) * (50 * a) = 5 / 7 * T + 100 * a := by
      field_simp; ring
    linarith
  -- main term
  have hP4 : 2 / ((K : ℝ) * Real.log 2) ^ 2 ≤ 627200 * u ^ 2 / T ^ 2 := by
    have hl2 : 1 / 2 ≤ Real.log 2 := by linarith [Real.log_two_gt_d9]
    have hu0 : 0 < u := by linarith
    have h1 : T / (560 * u) ≤ K * Real.log 2 := by
      have : T / (560 * u) = T / (280 * u) * (1 / 2) := by field_simp; ring
      rw [this]
      exact mul_le_mul hKlow hl2 (by norm_num) (by linarith)
    have h2 : 0 < T / (560 * u) := by positivity
    calc 2 / ((K : ℝ) * Real.log 2) ^ 2 ≤ 2 / (T / (560 * u)) ^ 2 :=
          div_le_div_of_nonneg_left (by norm_num) (by positivity) (pow_le_pow_left₀ h2.le h1 2)
      _ = 627200 * u ^ 2 / T ^ 2 := by field_simp; ring
  have hBu : B ≤ x * u ^ 2 / T ^ 2 := by
    rw [hBx]
    have : x / T ^ 2 * 1 ≤ x / T ^ 2 * u ^ 2 := mul_le_mul_of_nonneg_left (by nlinarith) (by positivity)
    rw [mul_one] at this
    calc x / T ^ 2 ≤ x / T ^ 2 * u ^ 2 := this
      _ = x * u ^ 2 / T ^ 2 := by ring
  have hx1 : x * (2 / ((K : ℝ) * Real.log 2) ^ 2 + σ ^ (m + 1) / ((m + 1)! : ℝ)) ≤
      x * (627200 * u ^ 2 / T ^ 2) + B := by
    rw [← hxe, ← mul_add]
    exact mul_le_mul_of_nonneg_left (by linarith) hx0.le
  have hxu : x * (627200 * u ^ 2 / T ^ 2) = 627200 * (x * u ^ 2 / T ^ 2) := by ring
  calc _ ≤ _ := hmain
    _ ≤ B + (x * (627200 * u ^ 2 / T ^ 2) + B) + B := by
        have := hx1
        simp only [hσ] at this
        linarith
    _ ≤ 627203 * (x * u ^ 2 / T ^ 2) := by rw [hxu]; linarith

#print axioms brun_final

lemma brun_isBigO_aux :
    (fun x : ℝ => ((Finset.filter (fun p => p.Prime ∧ (p + 2).Prime)
        (Finset.range (⌊x⌋₊ + 1))).card : ℝ))
      =O[atTop] (fun x : ℝ => x * Real.log (Real.log x) ^ 2 / Real.log x ^ 2) := by
  have h1 : ∀ᶠ x : ℝ in atTop, 0 < x := eventually_gt_atTop 0
  have h2 : ∀ᶠ x : ℝ in atTop, 1000 ≤ Real.log x := Real.tendsto_log_atTop.eventually_ge_atTop 1000
  have h3 : ∀ᶠ x : ℝ in atTop, ‖Real.log (Real.log x)‖ ≤ 1 / 1000 * ‖Real.log x‖ :=
    Real.tendsto_log_atTop.eventually (Real.isLittleO_log_id_atTop.bound (by norm_num))
  refine Asymptotics.IsBigO.of_bound 627203 ?_
  filter_upwards [h1, h2, h3] with x hx0 hT hu
  have hT0 : 0 < Real.log x := by linarith
  have hu' : Real.log (Real.log x) ≤ Real.log x / 1000 := by
    rw [Real.norm_of_nonneg hT0.le] at hu
    have := le_abs_self (Real.log (Real.log x))
    rw [Real.norm_eq_abs] at hu
    linarith
  rw [Real.norm_of_nonneg (Nat.cast_nonneg _), Real.norm_of_nonneg (by positivity)]
  exact brun_final x hx0 hT hu'

#print axioms brun_isBigO_aux

lemma brun_summable_aux :
    Summable (fun p : {p : ℕ // p.Prime ∧ (p + 2).Prime} =>
      (1 / (p : ℝ) + 1 / ((p : ℝ) + 2))) := by
  set f : ℕ → ℝ := fun n =>
    if n.Prime ∧ (n + 2).Prime then 1 / (n : ℝ) + 1 / ((n : ℝ) + 2) else 0 with hf
  have hf0 : ∀ n, 0 ≤ f n := fun n => by simp only [hf]; split_ifs <;> positivity
  set tw : ℝ → ℝ := fun x =>
    (((Finset.range (⌊x⌋₊ + 1)).filter (fun p => p.Prime ∧ (p + 2).Prime)).card : ℝ) with htw
  obtain ⟨C, hC0, hC⟩ := brun_isBigO_aux.exists_nonneg
  have hev : ∀ᶠ k : ℕ in atTop, tw (2 ^ (k + 1)) ≤
      C * ((2 : ℝ) ^ (k + 1) * Real.log (Real.log (2 ^ (k + 1))) ^ 2 / Real.log (2 ^ (k + 1)) ^ 2) := by
    have ht : Tendsto (fun k : ℕ => (2 : ℝ) ^ (k + 1)) atTop atTop :=
      (tendsto_pow_atTop_atTop_of_one_lt (by norm_num : (1 : ℝ) < 2)).comp (tendsto_add_atTop_nat 1)
    filter_upwards [ht.eventually hC.bound] with k hk
    rw [Real.norm_of_nonneg (Nat.cast_nonneg _), Real.norm_of_nonneg (by positivity)] at hk
    exact hk
  set g : ℕ → ℝ := fun k => ∑ i ∈ Ico (2 ^ k) (2 ^ (k + 1)), f i with hg
  have hg0 : ∀ k, 0 ≤ g k := fun k => sum_nonneg fun i _ => hf0 i
  have hgle : ∀ k, g k ≤ 2 / 2 ^ k * tw (2 ^ (k + 1)) := by
    intro k
    have h2k : (0 : ℝ) < 2 ^ k := by positivity
    have hpt : ∀ i ∈ Ico (2 ^ k) (2 ^ (k + 1)),
        f i ≤ (if i.Prime ∧ (i + 2).Prime then 2 / (2 : ℝ) ^ k else 0) := by
      intro i hi
      have hik : (2 : ℝ) ^ k ≤ i := by exact_mod_cast (mem_Ico.1 hi).1
      simp only [hf]
      split_ifs
      · have h1 : 1 / (i : ℝ) ≤ 1 / 2 ^ k := one_div_le_one_div_of_le h2k hik
        have h2 : 1 / ((i : ℝ) + 2) ≤ 1 / 2 ^ k := one_div_le_one_div_of_le h2k (by linarith)
        have : 2 / (2 : ℝ) ^ k = 1 / 2 ^ k + 1 / 2 ^ k := by ring
        linarith
      · exact le_rfl
    have hfloor : ⌊(2 : ℝ) ^ (k + 1)⌋₊ = 2 ^ (k + 1) := by
      rw [show (2 : ℝ) ^ (k + 1) = ((2 ^ (k + 1) : ℕ) : ℝ) by push_cast; ring, Nat.floor_natCast]
    calc g k ≤ ∑ i ∈ Ico (2 ^ k) (2 ^ (k + 1)),
          (if i.Prime ∧ (i + 2).Prime then 2 / (2 : ℝ) ^ k else 0) := sum_le_sum hpt
      _ = 2 / 2 ^ k * (((Ico (2 ^ k) (2 ^ (k + 1))).filter
            (fun p => p.Prime ∧ (p + 2).Prime)).card : ℝ) := by
          rw [← sum_filter, sum_const, nsmul_eq_mul]; ring
      _ ≤ 2 / 2 ^ k * tw (2 ^ (k + 1)) := by
          apply mul_le_mul_of_nonneg_left _ (by positivity)
          simp only [htw, hfloor]
          exact_mod_cast card_le_card (filter_subset_filter _ fun i hi => by
            rw [mem_range]; have := (mem_Ico.1 hi).2; omega)
  have hl2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have hgsum : Summable g := by
    have hs0 : Summable (fun n : ℕ => (((n : ℝ)) ^ (3 / 2 : ℝ))⁻¹) :=
      Real.summable_nat_rpow_inv.2 (by norm_num)
    have hs1 : Summable (fun n : ℕ => (((n + 1 : ℕ) : ℝ) ^ (3 / 2 : ℝ))⁻¹) :=
      (summable_nat_add_iff 1).2 hs0
    have hs : Summable (fun k : ℕ =>
        4 * C * (16 / Real.log 2 ^ (3 / 2 : ℝ)) * (((k + 1 : ℕ) : ℝ) ^ (3 / 2 : ℝ))⁻¹) :=
      hs1.mul_left _
    refine hs.of_norm_bounded_eventually_nat ?_
    filter_upwards [hev, eventually_ge_atTop 1] with k hk hk1
    rw [Real.norm_of_nonneg (hg0 k)]
    set v := Real.log ((2 : ℝ) ^ (k + 1)) with hv
    have hv' : v = ((k + 1 : ℕ) : ℝ) * Real.log 2 := by rw [hv, Real.log_pow]
    have hk2 : (2 : ℝ) ≤ ((k + 1 : ℕ) : ℝ) := by exact_mod_cast (by omega : 2 ≤ k + 1)
    have hv1 : 1 ≤ v := by
      rw [hv']; have := Real.log_two_gt_d9; nlinarith
    have hv0 : 0 < v := by linarith
    set L := Real.log v with hL
    have hL0 : 0 ≤ L := Real.log_nonneg hv1
    have hL1 : L ≤ v ^ (1 / 4 : ℝ) / (1 / 4) := Real.log_le_rpow_div hv0.le (by norm_num)
    have hL2 : L ^ 2 ≤ 16 * v ^ (1 / 2 : ℝ) := by
      have h4 : (v ^ (1 / 4 : ℝ)) ^ 2 = v ^ (1 / 2 : ℝ) := by
        rw [← Real.rpow_natCast, ← Real.rpow_mul hv0.le]; norm_num
      have : L ^ 2 ≤ (v ^ (1 / 4 : ℝ) / (1 / 4)) ^ 2 := pow_le_pow_left₀ hL0 hL1 2
      rw [div_pow, h4] at this
      have e : v ^ (1 / 2 : ℝ) / (1 / 4 : ℝ) ^ 2 = 16 * v ^ (1 / 2 : ℝ) := by ring
      linarith
    have hvsplit : v ^ 2 = v ^ (1 / 2 : ℝ) * v ^ (3 / 2 : ℝ) := by
      rw [← Real.rpow_add hv0, show (1 / 2 : ℝ) + 3 / 2 = ((2 : ℕ) : ℝ) by norm_num,
        Real.rpow_natCast]
    have hvh : 0 < v ^ (1 / 2 : ℝ) := Real.rpow_pos_of_pos hv0 _
    have hv32 : 0 < v ^ (3 / 2 : ℝ) := Real.rpow_pos_of_pos hv0 _
    have hratio : L ^ 2 / v ^ 2 ≤ 16 / v ^ (3 / 2 : ℝ) := by
      rw [hvsplit, div_le_div_iff₀ (by positivity) hv32]
      nlinarith
    have hv32' : v ^ (3 / 2 : ℝ) = ((k + 1 : ℕ) : ℝ) ^ (3 / 2 : ℝ) * Real.log 2 ^ (3 / 2 : ℝ) := by
      rw [hv', Real.mul_rpow (by positivity) hl2.le]
    have hk32 : 0 < ((k + 1 : ℕ) : ℝ) ^ (3 / 2 : ℝ) := Real.rpow_pos_of_pos (by positivity) _
    have hl32 : 0 < Real.log 2 ^ (3 / 2 : ℝ) := Real.rpow_pos_of_pos hl2 _
    calc g k ≤ 2 / 2 ^ k * tw (2 ^ (k + 1)) := hgle k
      _ ≤ 2 / 2 ^ k * (C * ((2 : ℝ) ^ (k + 1) * L ^ 2 / v ^ 2)) :=
          mul_le_mul_of_nonneg_left hk (by positivity)
      _ = 4 * C * (L ^ 2 / v ^ 2) := by
          rw [pow_succ]; field_simp; ring
      _ ≤ 4 * C * (16 / v ^ (3 / 2 : ℝ)) :=
          mul_le_mul_of_nonneg_left hratio (by positivity)
      _ = 4 * C * (16 / Real.log 2 ^ (3 / 2 : ℝ)) * (((k + 1 : ℕ) : ℝ) ^ (3 / 2 : ℝ))⁻¹ := by
          rw [hv32']; field_simp
  have hpart : ∀ n, ∑ i ∈ range (2 ^ n), f i = ∑ k ∈ range n, g k := by
    intro n
    induction n with
    | zero =>
      simp only [pow_zero, sum_range_one, sum_range_zero, hf]
      simp [Nat.not_prime_zero]
    | succ n ih =>
      rw [sum_range_succ, ← ih, ← sum_range_add_sum_Ico f
        (show 2 ^ n ≤ 2 ^ (n + 1) from Nat.pow_le_pow_right (by norm_num) (by omega))]
  have hfs : Summable f := by
    refine summable_of_sum_range_le hf0 (c := ∑' k, g k) fun n => ?_
    calc ∑ i ∈ range n, f i ≤ ∑ i ∈ range (2 ^ n), f i :=
          sum_le_sum_of_subset_of_nonneg (range_subset_range.2 (Nat.lt_two_pow_self).le)
            (fun i _ _ => hf0 i)
      _ = ∑ k ∈ range n, g k := hpart n
      _ ≤ ∑' k, g k := hgsum.sum_le_tsum _ (fun k _ => hg0 k)
  refine (hfs.subtype (fun p => p.Prime ∧ (p + 2).Prime)).congr fun p => ?_
  simp [hf, p.2.1, p.2.2]

#print axioms brun_summable_aux


end BrunHelpers

/-- Brun's theorem (1919). Let π₂(x) count the twin prime pairs p, p + 2 with p ≤ x.
There is a constant C with π₂(x) ≤ C · x (log log x)² / (log x)² for all large x:
π₂(x) = O(x (log log x)² / (log x)²) as x → ∞. -/
theorem twin_prime_count_isBigO :
    (fun x : ℝ => ((Finset.filter (fun p => p.Prime ∧ (p + 2).Prime)
        (Finset.range (⌊x⌋₊ + 1))).card : ℝ))
      =O[atTop] (fun x : ℝ => x * Real.log (Real.log x) ^ 2 / Real.log x ^ 2) := by
  exact brun_isBigO_aux

/-- Brun's convergence. Twin primes are thin enough that the sum of 1/p + 1/(p + 2) over all
twin prime pairs p, p + 2 is finite: the series converges (to Brun's constant B). -/
theorem summable_twin_prime_reciprocals :
    Summable (fun p : {p : ℕ // p.Prime ∧ (p + 2).Prime} =>
      (1 / (p : ℝ) + 1 / ((p : ℝ) + 2))) := by
  exact brun_summable_aux

/-- Brun's sieve for twin primes. Let S(x, z) count the n from 1 to x for which n(n + 2) has no
prime factor below z. Put ρ(2) = 1 and ρ(p) = 2 for odd p, multiply ρ(p) and g(p) = ρ(p)/p
over the primes of each set D of sifting primes, and let layer j hold the sets of j primes.
If the number of layers kept, m, is even, then
S(x, z) ≤ x · Σ_{j ≤ m} (−1)^j e_j(g) + Σ_{j ≤ m} e_j(ρ). -/
theorem twin_sieve_le_truncated_inclusion_exclusion (x z m : ℕ) (hm : Even m) :
    ((Finset.filter (fun n => ∀ p ∈ primesBelow z, ¬ p ∣ n * (n + 2))
        (Finset.Icc 1 x)).card : ℝ) ≤
      (x : ℝ) * ∑ j ∈ Finset.range (m + 1), (-1 : ℝ) ^ j *
          ∑ D ∈ (primesBelow z).powersetCard j, ∏ p ∈ D, ((if p = 2 then 1 else 2 : ℝ) / p)
        + ∑ j ∈ Finset.range (m + 1),
          ∑ D ∈ (primesBelow z).powersetCard j, ∏ p ∈ D, (if p = 2 then 1 else 2 : ℝ) := by
  exact brun_sieve_aux x z m hm

-- Twin pairs from the card: 11 and 13, and the largest pair below a million, 999,959 and 999,961.
example : Nat.Prime 11 ∧ Nat.Prime 13 := by norm_num
example : Nat.Prime 999959 ∧ Nat.Prime 999961 := by norm_num

-- ρ(2) = 1 and ρ(3) = 2: the remainder classes r mod p with p ∣ r(r + 2).
example : (Finset.filter (fun r => 2 ∣ r * (r + 2)) (Finset.range 2)).card = 1 := by decide
example : (Finset.filter (fun r => 3 ∣ r * (r + 2)) (Finset.range 3)).card = 2 := by decide

-- 8 sifting primes below 23, 25 below 101 and 46 below 200.
example : (primesBelow 23).card = 8 := by decide
example : (primesBelow 101).card = 25 := by decide
set_option maxRecDepth 4000 in
example : (primesBelow 200).card = 46 := by decide

-- Legendre's full allowance at z = 23: the product of 1 + ρ(p) over the 8 primes is 2 · 3^7 = 4,374.
example : 2 * 3 ^ 7 = 4374 := by norm_num

#print axioms twin_prime_count_isBigO
#print axioms summable_twin_prime_reciprocals
#print axioms twin_sieve_le_truncated_inclusion_exclusion
