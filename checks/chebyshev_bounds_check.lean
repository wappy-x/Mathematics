-- Chebyshev's bounds: for every real x ≥ 2 the prime count π(x) lies between (log 2/2)·x/log x and 4 log 2·x/log x, every prime power in C(2n, n) is at most 2n, and there is always a prime between n and 2n.
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.NumberTheory.Padics.PadicVal.Basic
import Mathlib.Data.Nat.Choose.Central
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic.NormNum.Prime
import Mathlib.NumberTheory.Chebyshev
import Mathlib.NumberTheory.Bertrand
import Mathlib.Analysis.Convex.SpecificFunctions.Basic
import Mathlib.Analysis.Complex.ExponentialBounds

open Real Finset Chebyshev in
/-- Splitting the primes up to x at y: π(x) · log y ≤ log 4 · x + y · log y. -/
lemma cheb_pi_mul_log_le {x y : ℝ} (hx : 1 ≤ x) (hy : 1 ≤ y) :
    (Nat.primeCounting ⌊x⌋₊ : ℝ) * log y ≤ log 4 * x + y * log y := calc
  _ = ∑ p ∈ Nat.primesLE ⌊x⌋₊, log y := by simp
  _ ≤ ∑ p ∈ Nat.primesLE ⌊x⌋₊, (log p + (if (p : ℝ) ≤ y then log y else 0)) := by
    refine sum_le_sum fun p _ ↦ ?_
    split_ifs with h
    · simp [log_natCast_nonneg]
    have : log y < log p := log_lt_log (by linarith) (not_le.mp h)
    linarith
  _ ≤ _ := by
    grw [← theta_le_log4_mul_x (by linarith)]
    rw [sum_add_distrib, theta_eq_theta_coe_floor, theta_eq_sum_primesLE_log, ← sum_filter]
    simp only [sum_const, nsmul_eq_mul]
    gcongr
    · exact log_nonneg hy
    refine le_trans ?_ <| Nat.floor_le (by linarith : (0 : ℝ) ≤ y)
    norm_cast
    rw [show ⌊y⌋₊ = #(Icc 1 ⌊y⌋₊) by simp]
    refine card_le_card fun p hp ↦ ?_
    simp only [mem_filter, mem_Icc, Nat.mem_primesLE] at hp ⊢
    exact ⟨hp.1.2.one_le, Nat.le_floor hp.2⟩

#print axioms cheb_pi_mul_log_le

/-- The upper bound for x ≥ 1024, splitting at y = x^(3/5). -/
lemma cheb_upper_large {x : ℝ} (hx : 1024 ≤ x) :
    (Nat.primeCounting ⌊x⌋₊ : ℝ) ≤ 4 * Real.log 2 * (x / Real.log x) := by
  set L := Real.log x with hL
  set l := Real.log 2 with hl
  have hx0 : 0 < x := by linarith
  have hl0 : 0 < l := Real.log_pos (by norm_num)
  have hl1 := Real.log_two_gt_d9
  have hl2 := Real.log_two_lt_d9
  have hL10 : 10 * l ≤ L := by
    have : Real.log 1024 = 10 * l := by
      rw [show (1024 : ℝ) = 2 ^ 10 by norm_num, Real.log_pow]; push_cast; ring
    rw [← this]; exact Real.log_le_log (by norm_num) hx
  have hLpos : 0 < L := by linarith
  set y := Real.exp (3 * L / 5) with hy
  have hy1 : 1 ≤ y := Real.one_le_exp (by linarith)
  have hlogy : Real.log y = 3 * L / 5 := Real.log_exp _
  have h4 : Real.log 4 = 2 * l := by
    rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.log_pow]; push_cast; ring
  have key := cheb_pi_mul_log_le (x := x) (y := y) (by linarith) hy1
  rw [hlogy, h4] at key
  -- y · L ≤ (2/3) l x
  have hxexp : x = Real.exp L := (Real.exp_log hx0).symm
  set u := 2 * L / 5 with hu
  have hu4 : 4 * l ≤ u := by rw [hu]; linarith
  have hexp4 : Real.exp (4 * l) = 16 := by
    rw [hl, show 4 * Real.log 2 = Real.log (2 ^ 4) by rw [Real.log_pow]; push_cast; ring,
      Real.exp_log (by norm_num)]; norm_num
  have hexpu : 16 * (1 + (u - 4 * l)) ≤ Real.exp u := by
    have h1 := Real.add_one_le_exp (u - 4 * l)
    have h2 : Real.exp u = Real.exp (4 * l) * Real.exp (u - 4 * l) := by
      rw [← Real.exp_add]; ring_nf
    rw [h2, hexp4]; linarith
  have hLu : L ≤ 2 / 3 * l * Real.exp u := by
    have : (5 / 2) * u ≤ 2 / 3 * l * (16 * (1 + (u - 4 * l))) := by
      nlinarith [mul_le_mul_of_nonneg_left hu4 (by linarith : (0:ℝ) ≤ 32 * l / 3 - 5 / 2)]
    have h3 : 2 / 3 * l * (16 * (1 + (u - 4 * l))) ≤ 2 / 3 * l * Real.exp u :=
      mul_le_mul_of_nonneg_left hexpu (by positivity)
    rw [hu] at this h3 ⊢; linarith
  have hyL : y * L ≤ 2 / 3 * l * x := by
    have hxy : x = y * Real.exp u := by
      rw [hxexp, hy, hu, ← Real.exp_add]; ring_nf
    rw [hxy]
    have := mul_le_mul_of_nonneg_left hLu (Real.exp_pos (3 * L / 5)).le
    rw [← hy] at this; linarith
  rw [mul_div_assoc', le_div_iff₀ hLpos]
  nlinarith

#print axioms cheb_upper_large

/-- The prime counts at powers of two used for the small range. -/
lemma cheb_pi_pow_two_table :
    ∀ k < 10, 1 ≤ k → Nat.primeCounting (2 ^ (k + 1)) * (k + 1) ≤ 2 ^ (k + 2) := by
  decide +kernel

#print axioms cheb_pi_pow_two_table

/-- The upper bound for 2 ≤ x < 1024, one binary octave at a time. -/
lemma cheb_upper_small {x : ℝ} (hx : 2 ≤ x) (hx' : x < 1024) :
    (Nat.primeCounting ⌊x⌋₊ : ℝ) ≤ 4 * Real.log 2 * (x / Real.log x) := by
  set n := ⌊x⌋₊ with hn
  have hn2 : 2 ≤ n := Nat.le_floor (by exact_mod_cast hx)
  have hnx : (n : ℝ) ≤ x := Nat.floor_le (by linarith)
  have hxn : x < n + 1 := Nat.lt_floor_add_one x
  have hn1024 : n < 1024 := by
    have : (n : ℝ) < 1024 := lt_of_le_of_lt hnx hx'
    exact_mod_cast this
  set k := Nat.log 2 n with hk
  have hk1 : 2 ^ k ≤ n := Nat.pow_log_le_self 2 (by omega)
  have hk2 : n < 2 ^ (k + 1) := Nat.lt_pow_succ_log_self (by norm_num) n
  have hk_ge : 1 ≤ k := by
    rw [hk]; exact Nat.le_log_of_pow_le (by norm_num) (by simpa using hn2)
  have hk_lt : k < 10 := by
    by_contra h
    push Not at h
    have : 2 ^ 10 ≤ 2 ^ k := Nat.pow_le_pow_right (by norm_num) h
    omega
  have htab := cheb_pi_pow_two_table k hk_lt hk_ge
  have hmono : Nat.primeCounting n ≤ Nat.primeCounting (2 ^ (k + 1)) :=
    Nat.monotone_primeCounting hk2.le
  have hnat : Nat.primeCounting n * (k + 1) ≤ 2 ^ (k + 2) :=
    le_trans (Nat.mul_le_mul_right _ hmono) htab
  have hreal : (Nat.primeCounting n : ℝ) * (k + 1) ≤ 4 * 2 ^ k := by
    have : ((Nat.primeCounting n * (k + 1) : ℕ) : ℝ) ≤ ((2 ^ (k + 2) : ℕ) : ℝ) := by
      exact_mod_cast hnat
    push_cast at this
    rw [pow_succ, pow_succ] at this
    linarith
  have hx2k : (2 : ℝ) ^ k ≤ x := le_trans (by exact_mod_cast hk1) hnx
  have hxk : x < (2 : ℝ) ^ (k + 1) := by
    have : ((n : ℕ) : ℝ) + 1 ≤ ((2 ^ (k + 1) : ℕ) : ℝ) := by exact_mod_cast hk2
    push_cast at this
    linarith
  have hl0 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have hLpos : 0 < Real.log x := Real.log_pos (by linarith)
  have hLk : Real.log x ≤ (k + 1) * Real.log 2 := by
    have := Real.log_le_log (by linarith) hxk.le
    rw [Real.log_pow] at this; push_cast at this; linarith
  rw [mul_div_assoc', le_div_iff₀ hLpos]
  have hpi0 : (0 : ℝ) ≤ Nat.primeCounting n := Nat.cast_nonneg _
  calc (Nat.primeCounting n : ℝ) * Real.log x
      ≤ (Nat.primeCounting n : ℝ) * ((k + 1) * Real.log 2) :=
        mul_le_mul_of_nonneg_left hLk hpi0
    _ = ((Nat.primeCounting n : ℝ) * (k + 1)) * Real.log 2 := by ring
    _ ≤ (4 * 2 ^ k) * Real.log 2 := mul_le_mul_of_nonneg_right hreal hl0.le
    _ ≤ 4 * Real.log 2 * x := by nlinarith

#print axioms cheb_upper_small

/-- On [2, 4]: x log 2 ≤ 2 log x (the chord of the concave log). -/
lemma cheb_log_chord {x : ℝ} (hx : 2 ≤ x) (hx' : x ≤ 4) :
    x * Real.log 2 ≤ 2 * Real.log x := by
  set s := x / 2 with hs
  have hs1 : 1 ≤ s := by rw [hs]; linarith
  have hs2 : s ≤ 2 := by rw [hs]; linarith
  have h1 : (1 : ℝ) ∈ Set.Ioi 0 := by norm_num
  have h2 : (2 : ℝ) ∈ Set.Ioi 0 := by norm_num
  have ha : (0 : ℝ) ≤ 2 - s := by linarith
  have hb : (0 : ℝ) ≤ s - 1 := by linarith
  have hab : (2 - s) + (s - 1) = 1 := by ring
  have hc := strictConcaveOn_log_Ioi.concaveOn.2 h1 h2 ha hb hab
  simp only [smul_eq_mul, Real.log_one, mul_zero, zero_add, mul_one] at hc
  have hsx : (2 - s) + (s - 1) * 2 = s := by ring
  rw [hsx] at hc
  have hx2 : x = 2 * s := by rw [hs]; ring
  rw [hx2, Real.log_mul (by norm_num) (by linarith)]
  nlinarith

#print axioms cheb_log_chord

/-- The lower bound. -/
lemma cheb_lower {x : ℝ} (hx : 2 ≤ x) :
    Real.log 2 / 2 * (x / Real.log x) ≤ (Nat.primeCounting ⌊x⌋₊ : ℝ) := by
  set n := ⌊x⌋₊ with hn
  have hnx : (n : ℝ) ≤ x := Nat.floor_le (by linarith)
  have hxn : x < n + 1 := Nat.lt_floor_add_one x
  have hl0 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have hLpos : 0 < Real.log x := Real.log_pos (by linarith)
  rcases lt_or_ge x 4 with h4 | h4
  · have hn2 : 2 ≤ n := Nat.le_floor (by exact_mod_cast hx)
    have hpi : 1 ≤ Nat.primeCounting n := by
      have : Nat.primeCounting 2 ≤ Nat.primeCounting n := Nat.monotone_primeCounting hn2
      have h2 : Nat.primeCounting 2 = 1 := by decide
      omega
    have hpi' : (1 : ℝ) ≤ Nat.primeCounting n := by exact_mod_cast hpi
    have hc := cheb_log_chord hx h4.le
    have : Real.log 2 / 2 * (x / Real.log x) ≤ 1 := by
      rw [mul_div_assoc', div_le_one hLpos]
      linarith
    linarith
  · have hn4 : 4 ≤ n := Nat.le_floor (by exact_mod_cast h4)
    have hge := Chebyshev.pi_ge_of_four_le hn4
    have hnpos : (0 : ℝ) < n := by exact_mod_cast (by omega : 0 < n)
    have hlogn : 0 < Real.log n := Real.log_pos (by exact_mod_cast (by omega : 1 < n))
    have hlognx : Real.log n ≤ Real.log x := Real.log_le_log hnpos hnx
    have hx2n : x / 2 ≤ n := by
      have : (1 : ℝ) ≤ n := by exact_mod_cast (by omega : 1 ≤ n)
      linarith
    refine le_trans ?_ hge
    rw [div_mul_div_comm, div_le_div_iff₀ (by positivity) hlogn]
    have h1 : Real.log 2 * x * Real.log n ≤ Real.log 2 * x * Real.log x :=
      mul_le_mul_of_nonneg_left hlognx (by positivity)
    have h2 : Real.log 2 * x * Real.log x ≤ (n * Real.log 2) * (2 * Real.log x) := by
      nlinarith [mul_le_mul_of_nonneg_left hx2n (mul_pos hl0 hLpos).le]
    linarith

#print axioms cheb_lower

/-- Chebyshev's bounds. For every real number x from 2 up, the number of primes up to x is
at least (log 2 / 2) times x / log x and at most 4 log 2 times x / log x:
(log 2 / 2) · x / log x ≤ π(x) ≤ 4 log 2 · x / log x. -/
theorem chebyshev_bounds (x : ℝ) (hx : 2 ≤ x) :
    Real.log 2 / 2 * (x / Real.log x) ≤ (Nat.primeCounting ⌊x⌋₊ : ℝ) ∧
      (Nat.primeCounting ⌊x⌋₊ : ℝ) ≤ 4 * Real.log 2 * (x / Real.log x) := by
  refine ⟨cheb_lower hx, ?_⟩
  rcases lt_or_ge x 1024 with h | h
  · exact cheb_upper_small hx h
  · exact cheb_upper_large h

/-- No prime power in the middle coefficient exceeds 2n: for every prime p and every whole
number n ≥ 1, the full power of p dividing C(2n, n), namely p ^ v_p(C(2n, n)), is at most 2n. -/
theorem central_binom_prime_power_le_two_mul (p n : ℕ) (hp : p.Prime) (hn : 1 ≤ n) :
    p ^ padicValNat p (Nat.centralBinom n) ≤ 2 * n := by
  rw [← Nat.factorization_def _ hp, Nat.centralBinom_eq_two_mul_choose]
  exact Nat.pow_factorization_choose_le (by omega)

/-- Bertrand's postulate. For every whole number n ≥ 1 there is a prime p with n < p ≤ 2n. -/
theorem bertrand_postulate (n : ℕ) (hn : 1 ≤ n) :
    ∃ p, p.Prime ∧ n < p ∧ p ≤ 2 * n := by
  exact Nat.exists_prime_lt_and_le_two_mul n (by omega)

-- The card's example: 503 is the first prime above 500.
example : Nat.Prime 503 ∧ ∀ m ∈ Finset.Ioo 500 503, ¬ m.Prime := by
  refine ⟨by norm_num, ?_⟩
  decide +kernel

-- 168 primes up to 1,000, and 168 − 95 = 73 of them lie between 500 and 1,000.
example : Nat.primeCounting 1000 = 168 ∧ Nat.primeCounting 1000 - Nat.primeCounting 500 = 73 := by
  decide +kernel

-- The primes up to 31 in C(1000, 500): 2^6 3^4 5^1 7^0 11^0 13^1 17^1 19^0 23^2 29^1 31^1.
example : [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31].map (fun p => padicValNat p (Nat.centralBinom 500))
    = [6, 4, 1, 0, 0, 1, 1, 0, 2, 1, 1] := by
  decide +kernel

-- Landau's chain: each is prime and each is less than twice the one before.
example : [2, 3, 5, 7, 13, 23, 43, 83, 163, 317, 631].all Nat.Prime ∧
    [(2, 3), (3, 5), (5, 7), (7, 13), (13, 23), (23, 43), (43, 83), (83, 163), (163, 317),
      (317, 631)].all (fun q => q.2 < 2 * q.1) := by
  decide +kernel

-- For n = 1 the prime is 2 = 2n.
example : Nat.Prime 2 ∧ 1 < 2 ∧ 2 ≤ 2 * 1 := by norm_num

-- What breaks: a fixed window n to n + 30 fails, since nothing lies between 1,327 and 1,361.
example : Nat.Prime 1327 ∧ Nat.Prime 1361 ∧ ∀ m ∈ Finset.Ioo 1327 1361, ¬ m.Prime := by
  refine ⟨by norm_num, by norm_num, ?_⟩
  decide +kernel

#print axioms chebyshev_bounds
#print axioms central_binom_prime_power_le_two_mul
#print axioms bertrand_postulate
