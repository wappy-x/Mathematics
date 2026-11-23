-- The abc conjecture: the quality form and the constant form of abc say the same thing, a Fermat solution with exponent n has quality above n/3, and the card's whole-number examples are exact.
import Mathlib.RingTheory.Radical.NatInt
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Tactic.Simproc.Factors
import Mathlib.Tactic.NormNum.GCD

open UniqueFactorizationMonoid

/-- The quality of a triple: log c divided by log rad(abc), where rad(n) is the product of
the distinct primes dividing n and log is the natural logarithm. -/
noncomputable def quality (a b c : ℕ) : ℝ :=
  Real.log c / Real.log ((radical (a * b * c) : ℕ) : ℝ)

/-- The abc conjecture in quality form (open; the card does not prove it): for every ε > 0,
only finitely many triples a + b = c of positive whole numbers with no common factor have
quality above 1 + ε. -/
def ABCQualityForm : Prop :=
  ∀ ε : ℝ, 0 < ε →
    {t : ℕ × ℕ × ℕ | 0 < t.1 ∧ 0 < t.2.1 ∧ t.1 + t.2.1 = t.2.2 ∧ Nat.Coprime t.1 t.2.1 ∧
      1 + ε < quality t.1 t.2.1 t.2.2}.Finite

/-- The abc conjecture in constant form (open; the card does not prove it): for every ε > 0
there is a constant K such that c < K · rad(abc)^(1 + ε) for every triple a + b = c of
positive whole numbers with no common factor. -/
def ABCConstantForm : Prop :=
  ∀ ε : ℝ, 0 < ε → ∃ K : ℝ, ∀ a b c : ℕ, 0 < a → 0 < b → a + b = c → Nat.Coprime a b →
    (c : ℝ) < K * ((radical (a * b * c) : ℕ) : ℝ) ^ (1 + ε)

/-- For a triple a + b = c of positive whole numbers, the radical of abc is at least 2. -/
lemma abc_two_le_radical (a b c : ℕ) (ha : 0 < a) (hb : 0 < b) (hab : a + b = c) :
    (2 : ℝ) ≤ ((radical (a * b * c) : ℕ) : ℝ) := by
  have h : 2 ≤ radical (a * b * c) := by
    rw [Nat.two_le_radical_iff]
    calc 2 ≤ c := by omega
      _ = 1 * 1 * c := by ring
      _ ≤ a * b * c := by gcongr <;> omega
  exact_mod_cast h

/-- Quality above 1 + ε means c is above rad(abc)^(1 + ε). -/
lemma abc_rpow_lt_of_quality (a b c : ℕ) (ha : 0 < a) (hb : 0 < b) (hab : a + b = c)
    (ε : ℝ) (hq : 1 + ε < quality a b c) :
    ((radical (a * b * c) : ℕ) : ℝ) ^ (1 + ε) < (c : ℝ) := by
  have hr2 := abc_two_le_radical a b c ha hb hab
  have hr0 : (0 : ℝ) < ((radical (a * b * c) : ℕ) : ℝ) := by linarith
  have hlogr : 0 < Real.log ((radical (a * b * c) : ℕ) : ℝ) := Real.log_pos (by linarith)
  have hc0 : (0 : ℝ) < (c : ℝ) := by exact_mod_cast (show 0 < c by omega)
  unfold quality at hq
  rw [lt_div_iff₀ hlogr, ← Real.log_rpow hr0] at hq
  exact (Real.log_lt_log_iff (by positivity) hc0).1 hq

/-- Quality at most 1 + ε means c is at most rad(abc)^(1 + ε). -/
lemma abc_le_rpow_of_quality (a b c : ℕ) (ha : 0 < a) (hb : 0 < b) (hab : a + b = c)
    (ε : ℝ) (hq : quality a b c ≤ 1 + ε) :
    (c : ℝ) ≤ ((radical (a * b * c) : ℕ) : ℝ) ^ (1 + ε) := by
  have hr2 := abc_two_le_radical a b c ha hb hab
  have hr0 : (0 : ℝ) < ((radical (a * b * c) : ℕ) : ℝ) := by linarith
  have hlogr : 0 < Real.log ((radical (a * b * c) : ℕ) : ℝ) := Real.log_pos (by linarith)
  have hc0 : (0 : ℝ) < (c : ℝ) := by exact_mod_cast (show 0 < c by omega)
  unfold quality at hq
  rw [div_le_iff₀ hlogr, ← Real.log_rpow hr0] at hq
  exact (Real.log_le_log_iff hc0 (by positivity)).1 hq

/-- If c < K · rad^(1 + ε/2) and c > rad^(1 + ε), then c < K · (K^(2/ε))^(1 + ε/2). -/
lemma abc_bound_of_constant (ε K r c : ℝ) (hε : 0 < ε) (hr : 1 ≤ r)
    (hcK : c < K * r ^ (1 + ε / 2)) (hq : r ^ (1 + ε) < c) :
    c < K * (K ^ (2 / ε)) ^ (1 + ε / 2) := by
  have hr0 : 0 < r := by linarith
  have hA : 0 < r ^ (1 + ε / 2) := Real.rpow_pos_of_pos hr0 _
  have hB : 0 < r ^ (ε / 2) := Real.rpow_pos_of_pos hr0 _
  have hsplit : r ^ (1 + ε) = r ^ (1 + ε / 2) * r ^ (ε / 2) := by
    rw [← Real.rpow_add hr0]; ring_nf
  have h1 : r ^ (1 + ε / 2) * r ^ (ε / 2) < K * r ^ (1 + ε / 2) := by
    rw [← hsplit]; linarith
  have hrK : r ^ (ε / 2) < K := by
    have : r ^ (1 + ε / 2) * r ^ (ε / 2) < r ^ (1 + ε / 2) * K := by linarith
    exact lt_of_mul_lt_mul_left this hA.le
  have hK0 : 0 < K := lt_trans hB hrK
  have hrB : r < K ^ (2 / ε) := by
    have h := Real.rpow_lt_rpow hB.le hrK (show 0 < 2 / ε by positivity)
    rwa [← Real.rpow_mul hr0.le, show ε / 2 * (2 / ε) = 1 by field_simp, Real.rpow_one] at h
  have hle : r ^ (1 + ε / 2) ≤ (K ^ (2 / ε)) ^ (1 + ε / 2) :=
    Real.rpow_le_rpow hr0.le hrB.le (by positivity)
  calc c < K * r ^ (1 + ε / 2) := hcK
    _ ≤ K * (K ^ (2 / ε)) ^ (1 + ε / 2) := by gcongr

/-- The two forms of abc say the same thing: "for every ε > 0, only finitely many coprime
triples a + b = c have quality log c / log rad(abc) above 1 + ε" holds exactly when "for
every ε > 0 there is a constant K with c < K · rad(abc)^(1 + ε) for every coprime triple"
holds. Neither form is proved; only their equivalence is. -/
theorem abc_quality_form_iff_constant_form : ABCQualityForm ↔ ABCConstantForm := by
  constructor
  · intro hQ ε hε
    have hS := hQ ε hε
    refine ⟨2 + ∑ t ∈ hS.toFinset, (t.2.2 : ℝ), ?_⟩
    intro a b c ha hb hab hcop
    have hr2 := abc_two_le_radical a b c ha hb hab
    have hR1 : (1 : ℝ) ≤ ((radical (a * b * c) : ℕ) : ℝ) ^ (1 + ε) :=
      Real.one_le_rpow (by linarith) (by linarith)
    have hsum0 : (0 : ℝ) ≤ ∑ t ∈ hS.toFinset, (t.2.2 : ℝ) :=
      Finset.sum_nonneg (fun t _ => Nat.cast_nonneg _)
    by_cases hq : 1 + ε < quality a b c
    · have hmem : (a, b, c) ∈ hS.toFinset := by
        rw [Set.Finite.mem_toFinset]
        exact ⟨ha, hb, hab, hcop, hq⟩
      have hcle : (c : ℝ) ≤ ∑ t ∈ hS.toFinset, (t.2.2 : ℝ) :=
        Finset.single_le_sum (f := fun t : ℕ × ℕ × ℕ => (t.2.2 : ℝ))
          (fun t _ => Nat.cast_nonneg _) hmem
      nlinarith
    · have hcle := abc_le_rpow_of_quality a b c ha hb hab ε (not_lt.1 hq)
      nlinarith
  · intro hC ε hε
    obtain ⟨K, hK⟩ := hC (ε / 2) (by positivity)
    set N : ℕ := ⌈K * (K ^ (2 / ε)) ^ (1 + ε / 2)⌉₊ with hN
    apply (Finset.range N ×ˢ Finset.range N ×ˢ Finset.range N).finite_toSet.subset
    rintro ⟨a, b, c⟩ ⟨ha, hb, hab, hcop, hq⟩
    simp only at ha hb hab hcop hq
    have hr2 := abc_two_le_radical a b c ha hb hab
    have hc : (c : ℝ) < K * (K ^ (2 / ε)) ^ (1 + ε / 2) :=
      abc_bound_of_constant ε K _ c hε (by linarith) (hK a b c ha hb hab hcop)
        (abc_rpow_lt_of_quality a b c ha hb hab ε hq)
    have hcN : c < N := Nat.lt_ceil.2 hc
    simp only [Finset.coe_product, Set.mem_prod, Finset.mem_coe, Finset.mem_range]
    omega

/-- What abc would decide for Fermat: if x^n + y^n = z^n with x, y positive and n ≥ 1, then
the triple (x^n, y^n, z^n) has quality above n/3, because rad(x^n y^n z^n) ≤ xyz < z^3. -/
theorem fermat_solution_quality_gt (x y z n : ℕ) (hx : 0 < x) (hy : 0 < y) (hn : 1 ≤ n)
    (h : x ^ n + y ^ n = z ^ n) : (n : ℝ) / 3 < quality (x ^ n) (y ^ n) (z ^ n) := by
  have hn0 : n ≠ 0 := by omega
  have hxn : 0 < x ^ n := pow_pos hx n
  have hyn : 0 < y ^ n := pow_pos hy n
  have hxz : x < z := by
    have : x ^ n < z ^ n := by omega
    exact (Nat.pow_lt_pow_iff_left hn0).1 this
  have hyz : y < z := by
    have : y ^ n < z ^ n := by omega
    exact (Nat.pow_lt_pow_iff_left hn0).1 this
  have hrad : radical (x ^ n * y ^ n * z ^ n) = radical (x * y * z) := by
    rw [← mul_pow, ← mul_pow, radical_pow _ hn0]
  have hz' : 0 < z := by omega
  have hxyz0 : x * y * z ≠ 0 := by positivity
  have hle : radical (x * y * z) ≤ x * y * z := Nat.radical_le_self_iff.2 hxyz0
  have hlt : x * y * z < z ^ 3 := by
    have h1 : x * y < z * z := Nat.mul_lt_mul'' hxz hyz
    have : x * y * z < z * z * z := Nat.mul_lt_mul_of_pos_right h1 (by omega)
    simpa [pow_succ, pow_zero, one_mul] using this
  have h2 : 2 ≤ radical (x * y * z) := by
    rw [Nat.two_le_radical_iff]
    have : 2 ≤ z := by omega
    calc 2 ≤ z := this
      _ = 1 * 1 * z := by ring
      _ ≤ x * y * z := by gcongr <;> omega
  unfold quality
  rw [hrad]
  set r := radical (x * y * z) with hr
  have hr1 : (1 : ℝ) < (r : ℝ) := by exact_mod_cast h2
  have hlogr : 0 < Real.log (r : ℝ) := Real.log_pos hr1
  have hz0 : (0 : ℝ) < (z : ℝ) := by exact_mod_cast (show 0 < z by omega)
  have hrz : (r : ℝ) < (z : ℝ) ^ 3 := by exact_mod_cast lt_of_le_of_lt hle hlt
  have hlog : Real.log (r : ℝ) < 3 * Real.log (z : ℝ) := by
    rw [show (3:ℝ) * Real.log (z:ℝ) = Real.log ((z:ℝ)^3) by rw [Real.log_pow]; norm_num]
    exact Real.log_lt_log (by positivity) hrz
  rw [lt_div_iff₀ hlogr]
  push_cast
  rw [Real.log_pow]
  have hnpos : (0 : ℝ) < n := by exact_mod_cast (show 0 < n by omega)
  nlinarith

-- The record triple 2 + 3^10 · 109 = 23^5: no common factor, rad(abc) = 2 · 3 · 109 · 23 = 15,042.
example : 3 ^ 10 * 109 = 6436341 ∧ 23 ^ 5 = 6436343 ∧ 2 + 3 ^ 10 * 109 = 23 ^ 5 ∧
    Nat.gcd 2 6436341 = 1 ∧ 2 * 3 * 109 * 23 = 15042 ∧
    radical (2 * (3 ^ 10 * 109) * 23 ^ 5 : ℕ) = 15042 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
-- The exact bracket: 15,042^16299 < 6,436,343^10000 < 15,042^16300, so 1.6299 < quality < 1.6300.
example : 15042 ^ 16299 < 6436343 ^ 10000 ∧ 6436343 ^ 10000 < 15042 ^ 16300 := by
  decide +kernel
-- c over rad is between 427 and 428 (the card's 427.8914).
example : 427 * 15042 < 6436343 ∧ 6436343 < 428 * 15042 := by norm_num
-- 1 + 8 = 9: rad(1 · 8 · 9) = 6.
example : 1 + 8 = 9 ∧ radical (1 * 8 * 9 : ℕ) = 6 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
-- The constant is needed: with ε = 0.2 and no constant, 1 + 8 = 9 fails, since 6^1.2 < 9
-- (in whole numbers, 6^6 = 46,656 < 9^5 = 59,049).
example : 6 ^ 6 < 9 ^ 5 := by norm_num
-- The top two hits below 100,000: 1 + 4,374 = 4,375 with radical 210, and
-- 343 + 59,049 = 59,392 with radical 1,218; both radicals are below c.
example : 1 + 4374 = 4375 ∧ radical (1 * 4374 * 4375 : ℕ) = 210 ∧ 210 < 4375 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
example : 343 + 59049 = 59392 ∧ Nat.gcd 343 59049 = 1 ∧
    radical (343 * 59049 * 59392 : ℕ) = 1218 ∧ 1218 < 59392 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
-- The top hit's quality in exact powers: 210^15678 < 4,375^10000 < 210^15679, so it rounds to 1.5679.
example : 210 ^ 15678 < 4375 ^ 10000 ∧ 4375 ^ 10000 < 210 ^ 15679 := by decide +kernel
-- The ε is needed: the family 1 + 8 = 9, 1 + 80 = 81, 1 + 6,560 = 6,561 has
-- c / rad = 9/6 = 1.5, 81/30 = 2.7 and 6,561/1,230 (≈ 5.3341).
example : radical (1 * 80 * 81 : ℕ) = 30 ∧ radical (1 * 6560 * 6561 : ℕ) = 1230 ∧
    (9 : ℚ) / 6 = 3 / 2 ∧ (81 : ℚ) / 30 = 27 / 10 := by
  simp only [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
-- A common factor breaks it: 512 + 512 = 1024 = 2^10 has radical 2, so quality 10.
example : 512 + 512 = 1024 ∧ Nat.gcd 512 512 = 512 ∧ 1024 = 2 ^ 10 ∧
    radical (512 * 512 * 1024 : ℕ) = 2 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
-- Fermat thresholds n/3: 4/3 is below the record 1.6299, 5/3 is above 1.6300.
example : (4 : ℚ) / 3 < 16299 / 10000 ∧ (16300 : ℚ) / 10000 < 5 / 3 := by norm_num

#print axioms abc_two_le_radical
#print axioms abc_rpow_lt_of_quality
#print axioms abc_le_rpow_of_quality
#print axioms abc_bound_of_constant
#print axioms abc_quality_form_iff_constant_form
#print axioms fermat_solution_quality_gt
