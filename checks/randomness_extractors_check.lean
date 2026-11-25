-- Randomness extractors: hashing a source of min-entropy k to m bits with a random universal hash lands within ½ · 2^(−(k − m)/2) of fair coins, no fixed rule without a seed can do this, and von Neumann's pairing rule gives exactly fair bits.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Prod
import Mathlib.Algebra.Order.Chebyshev
import Mathlib.Combinatorics.Pigeonhole

open Finset

/-- Sum of squared cell chances for one seed, as a double sum over pairs of inputs. -/
lemma lhl_sum_sq_seed {n m : ℕ} {S : Type*} (H : S → (Fin n → Bool) → (Fin m → Bool))
    (P : (Fin n → Bool) → ℝ) (s : S) :
    ∑ c : Fin m → Bool, (∑ x ∈ univ.filter (fun x => H s x = c), P x) ^ 2
      = ∑ x, ∑ x', P x * (if H s x' = H s x then P x' else 0) := by
  classical
  calc ∑ c : Fin m → Bool, (∑ x ∈ univ.filter (fun x => H s x = c), P x) ^ 2
      = ∑ c : Fin m → Bool, ∑ x ∈ univ.filter (fun x => H s x = c),
          P x * (∑ x' ∈ univ.filter (fun x' => H s x' = H s x), P x') := by
        refine Finset.sum_congr rfl fun c _ => ?_
        rw [sq, Finset.sum_mul]
        refine Finset.sum_congr rfl fun x hx => ?_
        rw [(Finset.mem_filter.1 hx).2]
    _ = ∑ x, P x * (∑ x' ∈ univ.filter (fun x' => H s x' = H s x), P x') :=
        Finset.sum_fiberwise univ (H s) _
    _ = ∑ x, ∑ x', P x * (if H s x' = H s x then P x' else 0) := by
        refine Finset.sum_congr rfl fun x _ => ?_
        rw [Finset.sum_filter, Finset.mul_sum]

#print axioms lhl_sum_sq_seed

/-- The collision bound: summed over every seed, the squared cell chances add to at most
N / 2^m + N · 2^(−k), where N is the number of seeds. -/
lemma lhl_collision {n m : ℕ} {S : Type*} [Fintype S]
    (H : S → (Fin n → Bool) → (Fin m → Bool))
    (huniv : ∀ x x' : Fin n → Bool, x ≠ x' →
      ((univ.filter fun s => H s x = H s x').card : ℝ) / Fintype.card S ≤ 1 / 2 ^ m)
    (P : (Fin n → Bool) → ℝ) (hP0 : ∀ x, 0 ≤ P x) (hP1 : ∑ x, P x = 1)
    (k : ℝ) (hk : ∀ x, P x ≤ (2 : ℝ) ^ (-k)) :
    ∑ sc : S × (Fin m → Bool), (∑ x ∈ univ.filter (fun x => H sc.1 x = sc.2), P x) ^ 2
      ≤ (Fintype.card S : ℝ) / 2 ^ m + Fintype.card S * (2 : ℝ) ^ (-k) := by
  classical
  have hN0 : (0 : ℝ) ≤ Fintype.card S := Nat.cast_nonneg _
  have hM : (0 : ℝ) < 2 ^ m := by positivity
  rw [Fintype.sum_prod_type]
  simp only [lhl_sum_sq_seed]
  have hswap : ∑ s : S, ∑ x, ∑ x', P x * (if H s x' = H s x then P x' else 0)
      = ∑ x, ∑ x', P x * P x' * ((univ.filter fun s => H s x' = H s x).card : ℝ) := by
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun x _ => ?_
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun x' _ => ?_
    rw [← Finset.mul_sum, ← Finset.sum_filter, Finset.sum_const, nsmul_eq_mul]
    ring
  rw [hswap]
  have hpt : ∀ x x' : Fin n → Bool,
      P x * P x' * ((univ.filter fun s => H s x' = H s x).card : ℝ)
        ≤ P x * P x' * ((Fintype.card S : ℝ) / 2 ^ m)
          + (if x' = x then (Fintype.card S : ℝ) * (P x * P x') else 0) := by
    intro x x'
    have hxx : 0 ≤ P x * P x' := mul_nonneg (hP0 x) (hP0 x')
    by_cases h : x' = x
    · subst h
      simp only [↓reduceIte, Finset.filter_true, Finset.card_univ]
      have : 0 ≤ P x' * P x' * ((Fintype.card S : ℝ) / 2 ^ m) := by positivity
      nlinarith
    · simp only [h, ↓reduceIte, add_zero]
      have hc := huniv x' x h
      by_cases hS : (Fintype.card S : ℝ) = 0
      · have : ((univ.filter fun s => H s x' = H s x).card : ℝ) = 0 := by
          have h0 : Fintype.card S = 0 := by exact_mod_cast hS
          have : IsEmpty S := Fintype.card_eq_zero_iff.1 h0
          simp
        rw [this, hS]; simp
      · have hNpos : (0 : ℝ) < Fintype.card S := lt_of_le_of_ne hN0 (Ne.symm hS)
        have : ((univ.filter fun s => H s x' = H s x).card : ℝ) ≤ (Fintype.card S : ℝ) / 2 ^ m := by
          rw [div_le_iff₀ hNpos] at hc
          calc _ ≤ 1 / 2 ^ m * (Fintype.card S : ℝ) := hc
            _ = _ := by ring
        exact mul_le_mul_of_nonneg_left this hxx
  calc ∑ x, ∑ x', P x * P x' * ((univ.filter fun s => H s x' = H s x).card : ℝ)
      ≤ ∑ x, ∑ x', (P x * P x' * ((Fintype.card S : ℝ) / 2 ^ m)
          + (if x' = x then (Fintype.card S : ℝ) * (P x * P x') else 0)) :=
        Finset.sum_le_sum fun x _ => Finset.sum_le_sum fun x' _ => hpt x x'
    _ = (Fintype.card S : ℝ) / 2 ^ m * ((∑ x, P x) * (∑ x, P x))
          + (Fintype.card S : ℝ) * ∑ x, P x * P x := by
        simp only [Finset.sum_add_distrib, Finset.sum_ite_eq', Finset.mem_univ, ite_true]
        rw [Finset.sum_mul_sum, Finset.mul_sum, Finset.mul_sum (s := univ) (a := (Fintype.card S : ℝ))]
        congr 1
        refine Finset.sum_congr rfl fun x _ => ?_
        rw [Finset.mul_sum]
        refine Finset.sum_congr rfl fun x' _ => ?_
        ring
    _ ≤ (Fintype.card S : ℝ) / 2 ^ m + Fintype.card S * (2 : ℝ) ^ (-k) := by
        rw [hP1, mul_one, mul_one]
        have : ∑ x, P x * P x ≤ (2 : ℝ) ^ (-k) := by
          calc ∑ x, P x * P x ≤ ∑ x, (2 : ℝ) ^ (-k) * P x :=
                Finset.sum_le_sum fun x _ => mul_le_mul_of_nonneg_right (hk x) (hP0 x)
            _ = (2 : ℝ) ^ (-k) := by rw [← Finset.mul_sum, hP1, mul_one]
        gcongr

#print axioms lhl_collision

/-- The leftover hash lemma. Let the source X be a random n-bit string, given by its chances
P x ≥ 0 adding to 1, with min-entropy at least k: no n-bit string has chance above 2^(−k).
Let the seed s be drawn fairly from a finite family of hashes H s from n bits to m bits that is
universal: for any two different inputs x ≠ x′, the chance over the seed that H s x = H s x′ is
at most 2^(−m). Then the pair (seed, H seed (X)) is within statistical distance ½ · 2^(−(k − m)/2)
of the pair (seed, m fair coins). The statistical distance is half the total gap
½ ∑ |Pr[pair = (s, c)] − Pr[(s, U_m) = (s, c)]| over every seed s and every m-bit output c. -/
theorem leftover_hash_lemma {n m : ℕ} {S : Type*} [Fintype S] [Nonempty S]
    (H : S → (Fin n → Bool) → (Fin m → Bool))
    (huniv : ∀ x x' : Fin n → Bool, x ≠ x' →
      ((univ.filter fun s => H s x = H s x').card : ℝ) / Fintype.card S ≤ 1 / 2 ^ m)
    (P : (Fin n → Bool) → ℝ) (hP0 : ∀ x, 0 ≤ P x) (hP1 : ∑ x, P x = 1)
    (k : ℝ) (hk : ∀ x, P x ≤ (2 : ℝ) ^ (-k)) :
    (1 / 2 : ℝ) * ∑ sc : S × (Fin m → Bool),
        |(1 / Fintype.card S : ℝ) * (∑ x ∈ univ.filter (fun x => H sc.1 x = sc.2), P x)
          - (1 / Fintype.card S : ℝ) * (1 / 2 ^ m)|
      ≤ (1 / 2 : ℝ) * (2 : ℝ) ^ (-(k - m) / 2) := by
  classical
  have hNpos : (0 : ℝ) < Fintype.card S := by exact_mod_cast Fintype.card_pos
  have hM : (0 : ℝ) < 2 ^ m := by positivity
  -- each output fiber sum over c is 1
  have hsum1 : ∀ s : S, ∑ c : Fin m → Bool, (∑ x ∈ univ.filter (fun x => H s x = c), P x) = 1 :=
    fun s => by rw [Finset.sum_fiberwise univ (H s) P, hP1]
  have hcardC : ((Fintype.card (Fin m → Bool) : ℕ) : ℝ) = 2 ^ m := by simp
  -- sum of squared gaps
  have hgap : ∑ sc : S × (Fin m → Bool),
      ((∑ x ∈ univ.filter (fun x => H sc.1 x = sc.2), P x) - 1 / 2 ^ m) ^ 2
        ≤ Fintype.card S * (2 : ℝ) ^ (-k) := by
    have hexp : ∑ sc : S × (Fin m → Bool),
        ((∑ x ∈ univ.filter (fun x => H sc.1 x = sc.2), P x) - 1 / 2 ^ m) ^ 2
          = ∑ sc : S × (Fin m → Bool), (∑ x ∈ univ.filter (fun x => H sc.1 x = sc.2), P x) ^ 2
            - (Fintype.card S : ℝ) / 2 ^ m := by
      have e1 : ∀ sc : S × (Fin m → Bool),
          ((∑ x ∈ univ.filter (fun x => H sc.1 x = sc.2), P x) - 1 / 2 ^ m) ^ 2
            = (∑ x ∈ univ.filter (fun x => H sc.1 x = sc.2), P x) ^ 2
              - 2 / 2 ^ m * (∑ x ∈ univ.filter (fun x => H sc.1 x = sc.2), P x)
              + 1 / (2 ^ m) ^ 2 := fun sc => by ring
      simp only [e1, Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum,
        Finset.sum_const, Finset.card_univ, nsmul_eq_mul]
      simp only [Fintype.sum_prod_type, hsum1, Finset.sum_const, Finset.card_univ, nsmul_eq_mul,
        Fintype.card_prod, Nat.cast_mul, hcardC, mul_one]
      field_simp
      ring
    rw [hexp]
    have := lhl_collision H huniv P hP0 hP1 k hk
    linarith
  -- Cauchy-Schwarz
  set T := ∑ sc : S × (Fin m → Bool),
      |(∑ x ∈ univ.filter (fun x => H sc.1 x = sc.2), P x) - 1 / 2 ^ m| with hT
  have hT0 : 0 ≤ T := Finset.sum_nonneg fun _ _ => abs_nonneg _
  have hCS : T ^ 2 ≤ (Fintype.card S * 2 ^ m : ℝ) * (Fintype.card S * (2 : ℝ) ^ (-k)) := by
    have h := sq_sum_le_card_mul_sum_sq (s := (univ : Finset (S × (Fin m → Bool))))
      (f := fun sc => |(∑ x ∈ univ.filter (fun x => H sc.1 x = sc.2), P x) - 1 / 2 ^ m|)
    simp only [sq_abs, Finset.card_univ, Fintype.card_prod, Nat.cast_mul, hcardC] at h
    calc T ^ 2 ≤ _ := h
      _ ≤ _ := by gcongr
  -- the target radius
  set R : ℝ := (2 : ℝ) ^ (-(k - m) / 2) with hR
  have hR0 : 0 ≤ R := by positivity
  have hR2 : R ^ 2 = 2 ^ m * (2 : ℝ) ^ (-k) := by
    rw [hR, ← Real.rpow_natCast, ← Real.rpow_mul (by norm_num), ← Real.rpow_natCast (2 : ℝ) m,
      ← Real.rpow_add (by norm_num)]
    congr 1
    push_cast
    ring
  have hTR : T ≤ Fintype.card S * R := by
    have h2 : T ^ 2 ≤ (Fintype.card S * R) ^ 2 := by
      rw [mul_pow, hR2]; nlinarith [hCS]
    exact (pow_le_pow_iff_left₀ hT0 (by positivity) two_ne_zero).1 h2
  have hrw : ∀ sc : S × (Fin m → Bool),
      |(1 / Fintype.card S : ℝ) * (∑ x ∈ univ.filter (fun x => H sc.1 x = sc.2), P x)
          - (1 / Fintype.card S : ℝ) * (1 / 2 ^ m)|
        = (1 / Fintype.card S : ℝ) *
          |(∑ x ∈ univ.filter (fun x => H sc.1 x = sc.2), P x) - 1 / 2 ^ m| := by
    intro sc
    rw [← mul_sub, abs_mul, abs_of_pos (by positivity)]
  simp only [hrw, ← Finset.mul_sum]
  rw [← hT]
  have : (1 / Fintype.card S : ℝ) * T ≤ R := by
    rw [div_mul_eq_mul_div, one_mul, div_le_iff₀ hNpos]
    linarith
  linarith

/-- No fixed rule is an extractor without a seed. For every fixed function f from n bits to
m bits, and every k with k + m ≤ n, some source with min-entropy at least k (no n-bit string
has chance above 2^(−k)) makes f's output constant: every string the source can produce is
sent by f to the same m-bit output c. On the card, n = 16, m = 2 and k = 8. -/
theorem no_seedless_extractor {n m k : ℕ} (hkm : k + m ≤ n)
    (f : (Fin n → Bool) → (Fin m → Bool)) :
    ∃ P : (Fin n → Bool) → ℝ, (∀ x, 0 ≤ P x) ∧ ∑ x, P x = 1 ∧
      (∀ x, P x ≤ 1 / (2 : ℝ) ^ k) ∧ ∃ c, ∀ x, P x ≠ 0 → f x = c := by
  classical
  have hcard : Fintype.card (Fin m → Bool) * 2 ^ k ≤ Fintype.card (Fin n → Bool) := by
    simp only [Fintype.card_fun, Fintype.card_bool, Fintype.card_fin, ← pow_add]
    exact Nat.pow_le_pow_right (by norm_num) (by omega)
  obtain ⟨c, hc⟩ := Fintype.exists_le_card_fiber_of_mul_le_card f hcard
  obtain ⟨T, hTsub, hTcard⟩ := Finset.exists_subset_card_eq hc
  refine ⟨fun x => if x ∈ T then 1 / (2 : ℝ) ^ k else 0, ?_, ?_, ?_, c, ?_⟩
  · intro x; dsimp only; split_ifs <;> positivity
  · rw [← Finset.sum_filter, Finset.filter_mem_eq_inter, Finset.univ_inter, Finset.sum_const,
      hTcard, nsmul_eq_mul]
    push_cast
    field_simp
  · intro x; dsimp only; split_ifs <;> simp
  · intro x hx
    by_cases h : x ∈ T
    · exact (Finset.mem_filter.1 (hTsub h)).2
    · simp [h] at hx

/-- Von Neumann's rule is exactly fair. Flip a coin with heads chance p and tails chance
q = 1 − p twice, independently and with the same bias, so a pair's chance is the product of the
two flips' chances. Heads then tails (bit 0) has chance p · q, tails then heads (bit 1) has
chance q · p, and these are equal. When 0 < p < 1, a pair gives a bit with chance 2pq, the bit
is 1 with chance exactly 1/2 given that a bit comes out, and the rule yields p · q fair bits
per flip on average. -/
theorem von_neumann_exactly_fair (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) :
    p * (1 - p) = (1 - p) * p ∧
      p * (1 - p) + (1 - p) * p = 2 * p * (1 - p) ∧
      ((1 - p) * p) / (p * (1 - p) + (1 - p) * p) = 1 / 2 ∧
      (p * (1 - p) + (1 - p) * p) / 2 = p * (1 - p) := by
  have hq : 0 < 1 - p := by linarith
  have hpq : 0 < p * (1 - p) := mul_pos hp0 hq
  refine ⟨by ring, by ring, ?_, by ring⟩
  rw [div_eq_iff (by linarith)]
  ring

-- The card's coin, heads 7 in 10: HT and TH each have chance 21/100, a pair gives a bit
-- with chance 42/100, the bit is 1 with chance 1/2, and the rate is 21/100 fair bits per flip.
example : (7 / 10 : ℚ) * (3 / 10) = 21 / 100 ∧ (3 / 10 : ℚ) * (7 / 10) = 21 / 100 := by norm_num
example : (21 / 100 : ℚ) + 21 / 100 = 42 / 100 ∧ (21 / 100 : ℚ) / (42 / 100) = 1 / 2 := by norm_num
example : (42 / 100 : ℚ) / 2 = 21 / 100 := by norm_num
-- Discarded pairs: HH and TT have chance 49/100 + 9/100 = 58/100.
example : (7 / 10 : ℚ) * (7 / 10) + (3 / 10) * (3 / 10) = 58 / 100 := by norm_num
-- What breaks: bias drifting from 7/10 to 6/10 inside a pair gives a 0 with chance 14/23, not 1/2.
example : (7 / 10 * (4 / 10) : ℚ) / (7 / 10 * (4 / 10) + 3 / 10 * (6 / 10)) = 14 / 23 := by norm_num

-- The sensor reads 32,768 + a − b with a, b uniform on 0 to 255: reading 32,768 + d has weight
-- 256 − |d| out of 65,536 = 2^16, over 511 readings, and the top chance is 256/65,536 = 1/256.
example : ((List.range 511).map fun j => 256 - Int.natAbs ((j : ℤ) - 255)).sum = 65536 := by decide +kernel
example : (2 : ℕ) ^ 16 = 65536 ∧ (256 : ℚ) / 65536 = 1 / 256 := by norm_num
-- The bound for k = 8 bits in and m = 2 bits out: ½ · 2^(−(8 − 2)/2) = ½ · 1/8 = 1/16.
example : (1 / 2 : ℚ) * (1 / 2 ^ ((8 - 2) / 2)) = 1 / 16 := by norm_num
-- The seed has 17 bits: 2^17 = 131,072 seeds.
example : (2 : ℕ) ^ 17 = 131072 := by norm_num
-- Universality checked exactly: the squared cell weights summed over every seed equal
-- 2^17 · (12 · ∑ (weight)² + 4 · 65,536²) = 2,269,392,133,947,392.
example : ((List.range 511).map fun j => (256 - Int.natAbs ((j : ℤ) - 255)) ^ 2).sum = 11184896 := by
  decide +kernel
example : 2 ^ 17 * (12 * 11184896 + 4 * 65536 ^ 2) = 2269392133947392 := by norm_num
-- The worked seed 1 0110 0100 1100 0101: row 0 is its low 16 bits, row 1 is bits 1 to 16.
example : 0b10110010011000101 &&& 0xFFFF = 0b0110010011000101 := by decide
example : (0b10110010011000101 >>> 1) &&& 0xFFFF = 0b1011001001100010 := by decide
-- Reading 32,805 = 32,768 + 37: AND row 0 keeps two 1s, AND row 1 keeps two 1s, so cell 00.
example : 32768 + 37 = 32805 ∧ 32805 = 0b1000000000100101 := by decide
example : 32805 &&& 0b0110010011000101 = 0b0000000000000101 := by decide
example : 32805 &&& 0b1011001001100010 = 0b1000000000100000 := by decide
-- No fixed rule: 65,536 inputs in 4 cells leave some cell with at least 16,384 ≥ 256 inputs,
-- and a source uniform on 256 of them sits at distance 1 − 1/4 = 3/4 from fair.
example : 65536 / 4 = 16384 ∧ 256 ≤ 16384 := by decide
example : (1 : ℚ) - 1 / 4 = 3 / 4 := by norm_num

#print axioms leftover_hash_lemma
#print axioms no_seedless_extractor
#print axioms von_neumann_exactly_fair
