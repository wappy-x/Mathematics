-- The sum-product problem: scaling a set of fractions by a common denominator keeps both its sum count and its product count, arithmetic modulo a prime gives no growth, and the runs 1 to n and 1, 2, 4, ..., 2^(n-1) have 2n - 1 sums, 2n - 1 products and n(n+1)/2 sums.
import Mathlib.Algebra.GroupWithZero.Action.Pointwise.Finset
import Mathlib.Algebra.Ring.Rat
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Data.ZMod.Defs
import Mathlib.NumberTheory.Zsqrtd.Basic
import Mathlib.Data.Finset.Sym

/-! Notation: for a finite set `A`, `A + A` and `A * A` are Mathlib's pointwise sumset and
product set (repeats counted once), `A.card` is `|A|`, and `D • A` is the set of all `D * a`
with `a` in `A`. The conjecture itself is open over the whole numbers and claimed refuted over
the reals, so it is not stated here as a theorem. -/

open scoped Pointwise

theorem two_pow_add_two_pow_ne_of_lt {a b c d : ℕ} (hab : a ≤ b) (hac : a < c) (hcd : c ≤ d) :
    2 ^ a + 2 ^ b ≠ 2 ^ c + 2 ^ d := by
  intro h
  obtain ⟨l, rfl⟩ := Nat.exists_eq_add_of_le hab
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_lt hac
  obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hcd
  have h2 : 1 + 2 ^ l = 2 * 2 ^ k + 2 * 2 ^ (k + m) := by
    have hpos : 0 < 2 ^ a := by positivity
    apply Nat.eq_of_mul_eq_mul_left hpos
    calc 2 ^ a * (1 + 2 ^ l) = 2 ^ a + 2 ^ (a + l) := by ring
      _ = 2 ^ (a + k + 1) + 2 ^ (a + k + 1 + m) := h
      _ = 2 ^ a * (2 * 2 ^ k + 2 * 2 ^ (k + m)) := by ring
  have hk : 0 < 2 ^ k := by positivity
  have hkm : 0 < 2 ^ (k + m) := by positivity
  rcases l with _ | l
  · simp at h2
    omega
  · rw [pow_succ] at h2
    omega

theorem two_pow_add_two_pow_inj_of_le {a b c d : ℕ} (hab : a ≤ b) (hcd : c ≤ d)
    (h : 2 ^ a + 2 ^ b = 2 ^ c + 2 ^ d) : a = c ∧ b = d := by
  rcases lt_trichotomy a c with hac | rfl | hca
  · exact absurd h (two_pow_add_two_pow_ne_of_lt hab hac hcd)
  · exact ⟨rfl, Nat.pow_right_injective le_rfl (Nat.add_left_cancel h)⟩
  · exact absurd h.symm (two_pow_add_two_pow_ne_of_lt hcd hca hab)

theorem two_pow_add_two_pow_inj {a b c d : ℕ} (h : 2 ^ a + 2 ^ b = 2 ^ c + 2 ^ d) :
    (a = c ∧ b = d) ∨ (a = d ∧ b = c) := by
  rcases le_total a b with hab | hba <;> rcases le_total c d with hcd | hdc
  · exact Or.inl (two_pow_add_two_pow_inj_of_le hab hcd h)
  · have := two_pow_add_two_pow_inj_of_le hab hdc (h.trans (add_comm _ _))
    exact Or.inr this
  · have := two_pow_add_two_pow_inj_of_le hba hcd ((add_comm _ _).trans h)
    exact Or.inr ⟨this.2, this.1⟩
  · have := two_pow_add_two_pow_inj_of_le hba hdc ((add_comm _ _).trans (h.trans (add_comm _ _)))
    exact Or.inl ⟨this.2, this.1⟩

#print axioms two_pow_add_two_pow_ne_of_lt
#print axioms two_pow_add_two_pow_inj_of_le
#print axioms two_pow_add_two_pow_inj

/-- **Fractions add nothing.** Multiply every member of a finite set `A` of fractions by a
nonzero number `D`, such as a common denominator: sums are multiplied by `D` and products by
`D²`, so the new set has exactly as many different sums and exactly as many different
products as `A`. -/
theorem card_add_and_card_mul_of_smul (A : Finset ℚ) (D : ℚ) (hD : D ≠ 0) :
    ((D • A) + (D • A)).card = (A + A).card ∧ ((D • A) * (D • A)).card = (A * A).card := by
  constructor
  · have h : (D • A) + (D • A) = (A + A).image (D * ·) := by
      ext x
      simp only [Finset.mem_add, Finset.mem_smul_finset, Finset.mem_image, smul_eq_mul]
      constructor
      · rintro ⟨_, ⟨a, ha, rfl⟩, _, ⟨b, hb, rfl⟩, rfl⟩
        exact ⟨a + b, ⟨a, ha, b, hb, rfl⟩, by ring⟩
      · rintro ⟨_, ⟨a, ha, b, hb, rfl⟩, rfl⟩
        exact ⟨_, ⟨a, ha, rfl⟩, _, ⟨b, hb, rfl⟩, by ring⟩
    rw [h, Finset.card_image_of_injective _ (mul_right_injective₀ hD)]
  · have h : (D • A) * (D • A) = (A * A).image (D * D * ·) := by
      ext x
      simp only [Finset.mem_mul, Finset.mem_smul_finset, Finset.mem_image, smul_eq_mul]
      constructor
      · rintro ⟨_, ⟨a, ha, rfl⟩, _, ⟨b, hb, rfl⟩, rfl⟩
        exact ⟨a * b, ⟨a, ha, b, hb, rfl⟩, by ring⟩
      · rintro ⟨_, ⟨a, ha, b, hb, rfl⟩, rfl⟩
        exact ⟨_, ⟨a, ha, rfl⟩, _, ⟨b, hb, rfl⟩, by ring⟩
    rw [h, Finset.card_image_of_injective _ (mul_right_injective₀ (mul_ne_zero hD hD))]

/-- **Wrap-round numbers do not grow.** In arithmetic modulo a prime `p`, the set of all `p`
remainders has exactly `p` different sums and exactly `p` different products. -/
theorem zmod_univ_card_add_and_card_mul (p : ℕ) [Fact p.Prime] :
    ((Finset.univ : Finset (ZMod p)) + Finset.univ).card = p ∧
      ((Finset.univ : Finset (ZMod p)) * Finset.univ).card = p := by
  have : NeZero p := ⟨(Fact.out : p.Prime).ne_zero⟩
  simp [Finset.univ_add_univ, Finset.univ_mul_univ, ZMod.card]

/-- **The two opening sets, for any length `n`.** The run `1, 2, …, n` has `2n − 1` different
sums. The `n` powers of 2, `1, 2, 4, …, 2^(n−1)`, have only `2n − 1` different products but
`n(n + 1)/2` different sums, one for every pair. -/
theorem run_and_powers_of_two_counts (n : ℕ) :
    (Finset.Icc 1 n + Finset.Icc 1 n : Finset ℕ).card = 2 * n - 1 ∧
      ((Finset.range n).image (2 ^ ·) * (Finset.range n).image (2 ^ ·) : Finset ℕ).card =
        2 * n - 1 ∧
      ((Finset.range n).image (2 ^ ·) + (Finset.range n).image (2 ^ ·) : Finset ℕ).card =
        n * (n + 1) / 2 := by
  refine ⟨?_, ?_, ?_⟩
  · have h : (Finset.Icc 1 n + Finset.Icc 1 n : Finset ℕ) = Finset.Icc 2 (2 * n) := by
      ext x
      simp only [Finset.mem_add, Finset.mem_Icc]
      constructor
      · rintro ⟨a, ha, b, hb, rfl⟩
        omega
      · intro hx
        exact ⟨min (x - 1) n, by omega, x - min (x - 1) n, by omega, by omega⟩
    rw [h, Nat.card_Icc]
    omega
  · have h : ((Finset.range n).image (2 ^ ·) * (Finset.range n).image (2 ^ ·) : Finset ℕ) =
        (Finset.range (2 * n - 1)).image (2 ^ ·) := by
      ext x
      simp only [Finset.mem_mul, Finset.mem_image, Finset.mem_range]
      constructor
      · rintro ⟨_, ⟨i, hi, rfl⟩, _, ⟨j, hj, rfl⟩, rfl⟩
        exact ⟨i + j, by omega, by rw [pow_add]⟩
      · rintro ⟨k, hk, rfl⟩
        refine ⟨_, ⟨min k (n - 1), by omega, rfl⟩, _, ⟨k - min k (n - 1), by omega, rfl⟩, ?_⟩
        rw [← pow_add]
        congr 1
        omega
    rw [h, Finset.card_image_of_injective _ (Nat.pow_right_injective le_rfl), Finset.card_range]
  · let f : Sym2 ℕ → ℕ := Sym2.lift ⟨fun i j => 2 ^ i + 2 ^ j, fun i j => add_comm _ _⟩
    have h : ((Finset.range n).image (2 ^ ·) + (Finset.range n).image (2 ^ ·) : Finset ℕ) =
        (Finset.range n).sym2.image f := by
      ext x
      simp only [Finset.mem_add, Finset.mem_image, Finset.mem_range]
      constructor
      · rintro ⟨_, ⟨i, hi, rfl⟩, _, ⟨j, hj, rfl⟩, rfl⟩
        exact ⟨s(i, j), Finset.mk_mem_sym2_iff.2 ⟨Finset.mem_range.2 hi, Finset.mem_range.2 hj⟩,
          rfl⟩
      · rintro ⟨z, hz, rfl⟩
        induction z using Sym2.ind with
        | h i j =>
          rw [Finset.mk_mem_sym2_iff, Finset.mem_range, Finset.mem_range] at hz
          exact ⟨_, ⟨i, hz.1, rfl⟩, _, ⟨j, hz.2, rfl⟩, rfl⟩
    have hinj : Function.Injective f := by
      intro z w hzw
      induction z using Sym2.ind with
      | h a b =>
        induction w using Sym2.ind with
        | h c d =>
          rw [Sym2.eq_iff]
          exact two_pow_add_two_pow_inj hzw
    rw [h, Finset.card_image_of_injective _ hinj, Finset.card_sym2, Finset.card_range,
      Nat.choose_two_right]
    congr 1
    rw [Nat.add_sub_cancel, Nat.mul_comm]

/-! The card's worked counts. -/

-- 1 to 10: 19 sums and 42 products.
example : (Finset.Icc 1 10 + Finset.Icc 1 10 : Finset ℕ).card = 19 := by decide +kernel
example : (Finset.Icc 1 10 * Finset.Icc 1 10 : Finset ℕ).card = 42 := by decide +kernel

-- 1, 2, 4, ..., 512: 19 products and 55 sums.
example : ((Finset.range 10).image (2 ^ ·) * (Finset.range 10).image (2 ^ ·) : Finset ℕ).card =
    19 := by decide +kernel
example : ((Finset.range 10).image (2 ^ ·) + (Finset.range 10).image (2 ^ ·) : Finset ℕ).card =
    55 := by decide +kernel

-- Ordered pairs from ten numbers: 100, not the 19 sums of 1 to 10.
example : ((Finset.Icc 1 10 : Finset ℕ) ×ˢ (Finset.Icc 1 10 : Finset ℕ)).card = 100 := by decide +kernel

-- Fractions 1/2, 1/3, 2/3, 3/4, 5/6, 1 times 12 give 6, 4, 8, 9, 10, 12;
-- both sets have 14 sums and 18 products.
example : (12 : ℚ) • ({1/2, 1/3, 2/3, 3/4, 5/6, 1} : Finset ℚ) = {6, 4, 8, 9, 10, 12} := by
  decide +kernel
example : (({1/2, 1/3, 2/3, 3/4, 5/6, 1} : Finset ℚ) + {1/2, 1/3, 2/3, 3/4, 5/6, 1}).card =
    14 := by decide +kernel
example : (({1/2, 1/3, 2/3, 3/4, 5/6, 1} : Finset ℚ) * {1/2, 1/3, 2/3, 3/4, 5/6, 1}).card =
    18 := by decide +kernel
example : (({6, 4, 8, 9, 10, 12} : Finset ℕ) + {6, 4, 8, 9, 10, 12}).card = 14 := by decide +kernel
example : (({6, 4, 8, 9, 10, 12} : Finset ℕ) * {6, 4, 8, 9, 10, 12}).card = 18 := by decide +kernel

-- The unit u = 1 + √2: (1 + √2)(−1 + √2) = 1, and its norm 1 − 2 = −1.
example : (⟨1, 1⟩ : ℤ√2) * ⟨-1, 1⟩ = 1 := by decide +kernel
example : Zsqrtd.norm (⟨1, 1⟩ : ℤ√2) = -1 := by decide +kernel

-- The model's set A = G · P has 7 × 318 = 2,226 members.
example : 7 * 318 = 2226 := by norm_num

#print axioms card_add_and_card_mul_of_smul
#print axioms zmod_univ_card_add_and_card_mul
#print axioms run_and_powers_of_two_counts
