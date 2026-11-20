-- The abc conjecture: if abc holds, Fermat's equation with exponents 4 and up and Catalan's equation have only finitely many solutions, the ε in abc cannot be dropped, and the card's whole-number examples are exact.
import Mathlib.RingTheory.Radical.NatInt
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.Simproc.Factors
import Mathlib.Tactic.NormNum.GCD

open UniqueFactorizationMonoid

/-- The abc conjecture in radical form (open; the card does not prove it): for every ε > 0
there is a constant K such that whenever a + b = c with a, b positive whole numbers and no
common factor, c < K · rad(abc)^(1 + ε), where rad(n) is the product of the distinct primes
dividing n. -/
def ABCConjecture : Prop :=
  ∀ ε : ℝ, 0 < ε → ∃ K : ℝ, ∀ a b c : ℕ, 0 < a → 0 < b → a + b = c → Nat.Coprime a b →
    (c : ℝ) < K * ((radical (a * b * c) : ℕ) : ℝ) ^ (1 + ε)


/-- If r^6 ≤ c^5 and c < K · r^(1 + 1/10), then c < K^12. -/
lemma abc_helper_bound (K : ℝ) (c r : ℕ) (hc : 0 < c) (hr : r ^ 6 ≤ c ^ 5)
    (h : (c : ℝ) < K * (r : ℝ) ^ (1 + 1 / 10 : ℝ)) : (c : ℝ) < K ^ 12 := by
  have hC : (0 : ℝ) < c := by exact_mod_cast hc
  have hR : (0 : ℝ) ≤ r := by positivity
  have h1 : (r : ℝ) ^ (1 + 1 / 10 : ℝ) ≤ (c : ℝ) ^ (11 / 12 : ℝ) := by
    have ha : (0 : ℝ) ≤ (r : ℝ) ^ (1 + 1 / 10 : ℝ) := by positivity
    have hb : (0 : ℝ) ≤ (c : ℝ) ^ (11 / 12 : ℝ) := by positivity
    rw [← pow_le_pow_iff_left₀ ha hb (by norm_num : (60 : ℕ) ≠ 0)]
    rw [← Real.rpow_mul_natCast hR, ← Real.rpow_mul_natCast hC.le]
    have e1 : (1 + 1 / 10 : ℝ) * ((60 : ℕ) : ℝ) = ((66 : ℕ) : ℝ) := by norm_num
    have e2 : (11 / 12 : ℝ) * ((60 : ℕ) : ℝ) = ((55 : ℕ) : ℝ) := by norm_num
    rw [e1, e2, Real.rpow_natCast, Real.rpow_natCast]
    have : r ^ 66 ≤ c ^ 55 := by
      calc r ^ 66 = (r ^ 6) ^ 11 := by ring
        _ ≤ (c ^ 5) ^ 11 := Nat.pow_le_pow_left hr 11
        _ = c ^ 55 := by ring
    exact_mod_cast this
  have hK : 0 < K := by
    by_contra hK
    rw [not_lt] at hK
    have : K * (r : ℝ) ^ (1 + 1 / 10 : ℝ) ≤ 0 :=
      mul_nonpos_of_nonpos_of_nonneg hK (by positivity)
    linarith
  have h2 : (c : ℝ) < K * (c : ℝ) ^ (11 / 12 : ℝ) :=
    lt_of_lt_of_le h (mul_le_mul_of_nonneg_left h1 hK.le)
  have hsplit : (c : ℝ) = (c : ℝ) ^ (11 / 12 : ℝ) * (c : ℝ) ^ (1 / 12 : ℝ) := by
    rw [← Real.rpow_add hC]; norm_num
  have hpos : 0 < (c : ℝ) ^ (11 / 12 : ℝ) := by positivity
  have h3 : (c : ℝ) ^ (1 / 12 : ℝ) < K := by
    nth_rewrite 1 [hsplit] at h2
    rw [mul_comm K] at h2
    exact lt_of_mul_lt_mul_left h2 hpos.le
  have h4 : ((c : ℝ) ^ (1 / 12 : ℝ)) ^ 12 < K ^ 12 :=
    pow_lt_pow_left₀ h3 (by positivity) (by norm_num)
  rwa [← Real.rpow_mul_natCast hC.le, show (1 / 12 : ℝ) * ((12 : ℕ) : ℝ) = 1 by norm_num,
    Real.rpow_one] at h4

#print axioms abc_helper_bound

/-- For the ε-family: 3^(2^k) = 2^(k+1) · m + 1 for some m. -/
lemma abc_helper_three_pow (k : ℕ) : ∃ m : ℕ, 3 ^ (2 ^ k) = 2 ^ (k + 1) * m + 1 := by
  induction k with
  | zero => exact ⟨1, by norm_num⟩
  | succ k ih =>
    obtain ⟨m, hm⟩ := ih
    refine ⟨2 ^ k * m ^ 2 + m, ?_⟩
    rw [pow_succ 2 k, pow_mul, hm]
    ring

#print axioms abc_helper_three_pow

/-- The exponent count behind abc ⇒ Catalan: (y·x)^6 ≤ (x^m)^5. -/
lemma abc_helper_catalan_pow (x y m n : ℕ) (hx : 2 ≤ x) (hy : 2 ≤ y) (hm : 2 ≤ m)
    (hn : 2 ≤ n) (h : x ^ m = y ^ n + 1) : (y * x) ^ 6 ≤ (x ^ m) ^ 5 := by
  have hyn : y ^ n ≤ x ^ m := by omega
  rcases Nat.lt_or_ge 2 m with hm3 | hm2
  · have h1 : x ^ 6 ≤ (x ^ m) ^ 2 := by
      rw [← pow_mul]; exact Nat.pow_le_pow_right (by omega) (by omega)
    have h2 : y ^ 6 ≤ (x ^ m) ^ 3 := by
      calc y ^ 6 ≤ y ^ (n * 3) := Nat.pow_le_pow_right (by omega) (by omega)
        _ = (y ^ n) ^ 3 := by rw [pow_mul]
        _ ≤ (x ^ m) ^ 3 := Nat.pow_le_pow_left hyn 3
    calc (y * x) ^ 6 = y ^ 6 * x ^ 6 := by ring
      _ ≤ (x ^ m) ^ 3 * (x ^ m) ^ 2 := Nat.mul_le_mul h2 h1
      _ = (x ^ m) ^ 5 := by ring
  · have hm2' : m = 2 := by omega
    subst hm2'
    rcases Nat.lt_or_ge 2 n with hn3 | hn2
    · have h2 : y ^ 6 ≤ (x ^ 2) ^ 2 := by
        calc y ^ 6 ≤ y ^ (n * 2) := Nat.pow_le_pow_right (by omega) (by omega)
          _ = (y ^ n) ^ 2 := by rw [pow_mul]
          _ ≤ (x ^ 2) ^ 2 := Nat.pow_le_pow_left hyn 2
      calc (y * x) ^ 6 = y ^ 6 * (x ^ 2) ^ 3 := by ring
        _ ≤ (x ^ 2) ^ 2 * (x ^ 2) ^ 3 := Nat.mul_le_mul_right _ h2
        _ = (x ^ 2) ^ 5 := by ring
    · have hn2' : n = 2 := by omega
      subst hn2'
      exfalso
      have hyx : y < x := by nlinarith
      nlinarith

#print axioms abc_helper_catalan_pow

/-- abc bounds Fermat for exponents 4 and up: if the abc conjecture holds, then the equation
x^n + y^n = z^n with x, y positive, no common factor and n ≥ 4 has only finitely many
solutions (x, y, z, n), all exponents from 4 up taken together. -/
theorem abc_implies_fermat_finitely_many (habc : ABCConjecture) :
    {(x, y, z, n) : ℕ × ℕ × ℕ × ℕ |
      0 < x ∧ 0 < y ∧ 4 ≤ n ∧ Nat.Coprime x y ∧ x ^ n + y ^ n = z ^ n}.Finite := by
  obtain ⟨K, hK⟩ := habc (1 / 10) (by norm_num)
  set N := ⌈K ^ 12⌉₊
  refine ((Set.finite_Iic N).prod ((Set.finite_Iic N).prod
    ((Set.finite_Iic N).prod (Set.finite_Iic N)))).subset ?_
  rintro ⟨x, y, z, n⟩ ⟨hx, hy, hn, hxy, h⟩
  have hn0 : n ≠ 0 := by omega
  have hxn : 0 < x ^ n := by positivity
  have hyn : 0 < y ^ n := by positivity
  have hz : 2 ≤ z := by
    by_contra hz
    have : z ^ n ≤ 1 := by
      calc z ^ n ≤ 1 ^ n := Nat.pow_le_pow_left (by omega) n
        _ = 1 := one_pow n
    omega
  have hxz : x < z := lt_of_pow_lt_pow_left₀ n (by positivity) (by omega)
  have hyz : y < z := lt_of_pow_lt_pow_left₀ n (by positivity) (by omega)
  have key := hK (x ^ n) (y ^ n) (z ^ n) hxn hyn h (Nat.Coprime.pow n n hxy)
  have hr : radical (x ^ n * y ^ n * z ^ n) ≤ x * y * z := by
    rw [← mul_pow, ← mul_pow, radical_pow _ hn0]
    exact Nat.le_of_dvd (by positivity) radical_dvd_self
  have hr6 : radical (x ^ n * y ^ n * z ^ n) ^ 6 ≤ (z ^ n) ^ 5 := by
    calc radical (x ^ n * y ^ n * z ^ n) ^ 6 ≤ (x * y * z) ^ 6 := Nat.pow_le_pow_left hr 6
      _ ≤ (z * z * z) ^ 6 := Nat.pow_le_pow_left
          (Nat.mul_le_mul (Nat.mul_le_mul hxz.le hyz.le) le_rfl) 6
      _ = z ^ 18 := by ring
      _ ≤ z ^ (n * 5) := Nat.pow_le_pow_right (by omega) (by omega)
      _ = (z ^ n) ^ 5 := by rw [pow_mul]
  have hb := abc_helper_bound K (z ^ n) _ (by positivity) hr6 key
  have hzN : z ^ n ≤ N := by
    have : ((z ^ n : ℕ) : ℝ) ≤ (N : ℝ) := hb.le.trans (Nat.le_ceil _)
    exact_mod_cast this
  have h1 : z ≤ z ^ n := Nat.le_self_pow hn0 z
  have h2 : n < 2 ^ n := Nat.lt_two_pow_self
  have h3 : 2 ^ n ≤ z ^ n := Nat.pow_le_pow_left hz n
  simp only [Set.mem_prod, Set.mem_Iic]
  omega

/-- abc bounds Catalan's equation: if the abc conjecture holds, then x^m - y^n = 1, written
x^m = y^n + 1, with all four of x, y, m, n at least 2 has only finitely many solutions. -/
theorem abc_implies_catalan_finitely_many (habc : ABCConjecture) :
    {(x, y, m, n) : ℕ × ℕ × ℕ × ℕ |
      2 ≤ x ∧ 2 ≤ y ∧ 2 ≤ m ∧ 2 ≤ n ∧ x ^ m = y ^ n + 1}.Finite := by
  obtain ⟨K, hK⟩ := habc (1 / 10) (by norm_num)
  set N := ⌈K ^ 12⌉₊
  refine ((Set.finite_Iic N).prod ((Set.finite_Iic N).prod
    ((Set.finite_Iic N).prod (Set.finite_Iic N)))).subset ?_
  rintro ⟨x, y, m, n⟩ ⟨hx, hy, hm, hn, h⟩
  have hyn : 0 < y ^ n := by positivity
  have key := hK 1 (y ^ n) (x ^ m) one_pos hyn (by omega) (Nat.coprime_one_left _)
  have hr : radical (1 * y ^ n * x ^ m) ≤ y * x := by
    rw [one_mul]
    refine Nat.le_of_dvd (by positivity) (radical_mul_dvd.trans (mul_dvd_mul ?_ ?_))
    · exact radical_pow_dvd.trans radical_dvd_self
    · exact radical_pow_dvd.trans radical_dvd_self
  have hr6 : radical (1 * y ^ n * x ^ m) ^ 6 ≤ (x ^ m) ^ 5 :=
    (Nat.pow_le_pow_left hr 6).trans (abc_helper_catalan_pow x y m n hx hy hm hn h)
  have hb := abc_helper_bound K (x ^ m) _ (by positivity) hr6 key
  have hxN : x ^ m ≤ N := by
    have : ((x ^ m : ℕ) : ℝ) ≤ (N : ℝ) := hb.le.trans (Nat.le_ceil _)
    exact_mod_cast this
  have h1 : x ≤ x ^ m := Nat.le_self_pow (by omega) x
  have h2 : y ≤ y ^ n := Nat.le_self_pow (by omega) y
  have h3 : m < 2 ^ m := Nat.lt_two_pow_self
  have h4 : 2 ^ m ≤ x ^ m := Nat.pow_le_pow_left hx m
  have h5 : n < 2 ^ n := Nat.lt_two_pow_self
  have h6 : 2 ^ n ≤ y ^ n := Nat.pow_le_pow_left hy n
  simp only [Set.mem_prod, Set.mem_Iic]
  omega

/-- The ε cannot be dropped: there is no fixed constant K with c < K · rad(abc) for every
a + b = c with a, b positive and no common factor. (The family 1 + (3^(2^k) - 1) = 3^(2^k)
has c/rad(abc) > 2^(k+1)/3, which grows without bound.) -/
theorem epsilon_cannot_be_dropped :
    ¬ ∃ K : ℝ, ∀ a b c : ℕ, 0 < a → 0 < b → a + b = c → Nat.Coprime a b →
      (c : ℝ) < K * ((radical (a * b * c) : ℕ) : ℝ) := by
  rintro ⟨K, hK⟩
  set k := ⌈6 * K⌉₊
  obtain ⟨m, hm⟩ := abc_helper_three_pow k
  have hmpos : 0 < m := by
    rcases Nat.eq_zero_or_pos m with h0 | h0
    · subst h0
      have : 3 ≤ 3 ^ (2 ^ k) := Nat.le_self_pow (by positivity) 3
      omega
    · exact h0
  have key := hK 1 (2 ^ (k + 1) * m) (3 ^ (2 ^ k)) one_pos (by positivity) (by rw [hm]; ring)
    (Nat.coprime_one_left _)
  have hrad2 : radical (2 : ℕ) = 2 := by
    rw [Nat.radical_eq_prod_primeFactors, Nat.prime_two.primeFactors, Finset.prod_singleton]
  have hrad3 : radical (3 : ℕ) = 3 := by
    rw [Nat.radical_eq_prod_primeFactors, Nat.prime_three.primeFactors, Finset.prod_singleton]
  have hr : radical (1 * (2 ^ (k + 1) * m) * 3 ^ (2 ^ k)) ≤ 6 * m := by
    rw [one_mul]
    refine Nat.le_of_dvd (by positivity) ?_
    have hd : radical (2 ^ (k + 1) * m * 3 ^ (2 ^ k)) ∣ 2 * m * 3 := by
      refine radical_mul_dvd.trans (mul_dvd_mul (radical_mul_dvd.trans (mul_dvd_mul ?_ ?_)) ?_)
      · rw [radical_pow _ (by omega), hrad2]
      · exact radical_dvd_self
      · rw [radical_pow _ (by positivity), hrad3]
    simpa [mul_comm, mul_left_comm, mul_assoc] using hd
  have hrR : ((radical (1 * (2 ^ (k + 1) * m) * 3 ^ (2 ^ k)) : ℕ) : ℝ) ≤ 6 * m := by
    exact_mod_cast hr
  have hcR : ((3 ^ (2 ^ k) : ℕ) : ℝ) = 2 ^ (k + 1) * m + 1 := by rw [hm]; push_cast; ring
  have hk : 6 * K ≤ (k : ℝ) := Nat.le_ceil _
  have hk2 : (k : ℝ) ≤ 2 ^ (k + 1) := by
    have : k < 2 ^ (k + 1) := (Nat.lt_two_pow_self).trans (Nat.pow_lt_pow_right (by norm_num) (by omega))
    exact_mod_cast this.le
  have hmR : (0 : ℝ) < m := by exact_mod_cast hmpos
  rw [hcR] at key
  rcases le_or_gt K 0 with hK0 | hK0
  · have : K * ((radical (1 * (2 ^ (k + 1) * m) * 3 ^ (2 ^ k)) : ℕ) : ℝ) ≤ 0 :=
      mul_nonpos_of_nonpos_of_nonneg hK0 (by positivity)
    have : (0 : ℝ) ≤ 2 ^ (k + 1) * m := by positivity
    linarith
  · have h1 : K * ((radical (1 * (2 ^ (k + 1) * m) * 3 ^ (2 ^ k)) : ℕ) : ℝ) ≤ K * (6 * m) :=
      mul_le_mul_of_nonneg_left hrR hK0.le
    have h2 : K * (6 * m) ≤ 2 ^ (k + 1) * (m : ℝ) := by
      have : 6 * K ≤ (2 : ℝ) ^ (k + 1) := hk.trans hk2
      nlinarith
    linarith

-- rad(72) = rad(2^3 · 3^2) = 6.
example : radical (72 : ℕ) = 6 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
-- 1 + 8 = 9 is a hit: rad(1 · 8 · 9) = 6 < 9; 3^2 - 2^3 = 1 is the same sum read as Catalan.
example : 1 + 8 = 9 ∧ radical (1 * 8 * 9 : ℕ) = 6 ∧ 6 < 9 ∧ 3 ^ 2 - 2 ^ 3 = 1 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
-- 2 + 3 = 5 is typical: rad(2 · 3 · 5) = 30, far above 5.
example : radical (2 * 3 * 5 : ℕ) = 30 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
-- The family c = 3^(2^k), b = c - 1, k = 1 to 5: rad(abc) as printed, and 3c > 2^(k+1) rad(abc).
example : radical (1 * (3 ^ 2 - 1) * 3 ^ 2 : ℕ) = 6 ∧ 3 * 3 ^ 2 > 2 ^ 2 * 6 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
example : radical (1 * (3 ^ 4 - 1) * 3 ^ 4 : ℕ) = 30 ∧ 3 * 3 ^ 4 > 2 ^ 3 * 30 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
example : radical (1 * (3 ^ 8 - 1) * 3 ^ 8 : ℕ) = 1230 ∧ 3 * 3 ^ 8 > 2 ^ 4 * 1230 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
example : radical (1 * (3 ^ 16 - 1) * 3 ^ 16 : ℕ) = 4035630 ∧
    3 * 3 ^ 16 > 2 ^ 5 * 4035630 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
example : radical (1 * (3 ^ 32 - 1) * 3 ^ 32 : ℕ) = 86860321352430 ∧
    3 ^ 32 = 1853020188851841 ∧ 3 * 3 ^ 32 > 2 ^ 6 * 86860321352430 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
-- The best triples below 100,000 and the 1987 record: radicals 210, 1,218, 30 and 15,042.
example : 1 + 4374 = 4375 ∧ radical (1 * 4374 * 4375 : ℕ) = 210 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
example : 343 + 59049 = 59392 ∧ radical (343 * 59049 * 59392 : ℕ) = 1218 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
example : 3 + 125 = 128 ∧ radical (3 * 125 * 128 : ℕ) = 30 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
example : 2 + 3 ^ 10 * 109 = 23 ^ 5 ∧ 23 ^ 5 = 6436343 ∧
    radical (2 * (3 ^ 10 * 109) * 23 ^ 5 : ℕ) = 15042 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
-- A common factor breaks it: 512 + 512 = 1024 has radical 2.
example : 512 + 512 = 1024 ∧ Nat.gcd 512 512 = 512 ∧ radical (512 * 512 * 1024 : ℕ) = 2 := by
  rw [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
-- The largest 1/l + 1/m + 1/n below 1 is reached at (2, 3, 7): 41/42.
example : (1 / 2 + 1 / 3 + 1 / 7 : ℚ) = 41 / 42 := by norm_num
-- The Fermat-Catalan solutions found, and Beal's 27 + 216 = 243 with a shared prime 3.
example : 2 ^ 5 + 7 ^ 2 = 3 ^ 4 ∧ 2 ^ 7 + 17 ^ 3 = 71 ^ 2 ∧ 13 ^ 2 + 7 ^ 3 = 2 ^ 9 ∧
    3 ^ 5 + 11 ^ 4 = 122 ^ 2 ∧ 3 ^ 3 + 6 ^ 3 = 3 ^ 5 := by norm_num
-- Frey curve of 1 + 8 = 9: Δ = 16 · 72^2 = 82,944, c4 = 16(1 + 8 + 64) = 1,168, gcd 16.
example : 16 * (1 * 8 * 9) ^ 2 = 82944 ∧ 16 * (1 ^ 2 + 1 * 8 + 8 ^ 2) = 1168 ∧
    Nat.gcd 1168 82944 = 16 := by norm_num
-- Frey curve of 1 + 80 = 81 (A = -81, B = 80): first Δ 671,846,400, minimal Δ 164,025,
-- c4 = 16(A^2 + AB + B^2)/2^4 = 6,481, gcd(c4, Δmin) = 1, conductor rad(Δmin) = 15, rad(abc) = 30.
example : 16 * (1 * 80 * 81) ^ 2 = 671846400 ∧ (1 * 80 * 81) ^ 2 / 2 ^ 8 = 164025 ∧
    16 * ((-81 : ℤ) ^ 2 + (-81) * 80 + 80 ^ 2) / 2 ^ 4 = 6481 ∧ Nat.gcd 6481 164025 = 1 ∧
    radical (164025 : ℕ) = 15 ∧ radical (1 * 80 * 81 : ℕ) = 30 := by
  simp only [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]
-- Frey curve of 1 + 6560 = 6561: minimal Δ 7,236,153,800,100, conductor 1,230 = rad(abc).
example : (1 * 6560 * 6561) ^ 2 / 2 ^ 8 = 7236153800100 ∧
    radical (7236153800100 : ℕ) = 1230 ∧ radical (1 * 6560 * 6561 : ℕ) = 1230 := by
  simp only [Nat.radical_eq_prod_primeFactors]; norm_num [Nat.primeFactors]

#print axioms abc_implies_fermat_finitely_many
#print axioms abc_implies_catalan_finitely_many
#print axioms epsilon_cannot_be_dropped
