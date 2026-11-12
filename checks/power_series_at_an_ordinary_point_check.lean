-- Series solutions: the coefficients that y'' + P y' + Q y = 0 forces on a power series converge at least as far as P and Q do, Airy's series solves the hanging rod's equation, and the arctan series has radius 1.
import Mathlib.Analysis.Analytic.OfScalars
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib

open Finset FormalMultilinearSeries

lemma series_solution_coeff_bound (p q a : ℕ → ℂ)
    (ha : ∀ n : ℕ, ((n : ℂ) + 2) * ((n : ℂ) + 1) * a (n + 2) =
      -∑ k ∈ range (n + 1), (((k : ℂ) + 1) * a (k + 1) * p (n - k) + a k * q (n - k)))
    (ρ r M : ℝ) (hρ : 0 < ρ) (hρr : ρ < r)
    (hp : ∀ n, ‖p n‖ * r ^ n ≤ M) (hq : ∀ n, ‖q n‖ * r ^ n ≤ M) :
    ∃ K, ∀ n, ‖a n‖ * ρ ^ n ≤ K := by
  have hr : 0 < r := hρ.trans hρr
  have hM : 0 ≤ M := le_trans (by positivity) (hp 0)
  set t : ℝ := ρ / r with ht
  have ht0 : 0 < t := by positivity
  have ht1 : t < 1 := by rw [ht, div_lt_one hr]; exact hρr
  set c : ℝ := M / (1 - t) with hc
  have hc0 : 0 ≤ c := div_nonneg hM (by linarith)
  obtain ⟨N, hN⟩ := exists_nat_ge (c * (ρ + ρ ^ 2))
  set K : ℝ := ∑ j ∈ range (N + 2), ‖a j‖ * ρ ^ j with hK
  have hK0 : 0 ≤ K := sum_nonneg (fun j _ => by positivity)
  refine ⟨K, fun n => ?_⟩
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    by_cases hn : n < N + 2
    · exact single_le_sum (f := fun j => ‖a j‖ * ρ ^ j) (fun j _ => by positivity)
        (mem_range.2 hn)
    obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
    have hm : N ≤ m := by omega
    have hmR : (N : ℝ) ≤ m := by exact_mod_cast hm
    -- termwise bound
    have hterm : ∀ k ∈ range (m + 1),
        ‖((k : ℂ) + 1) * a (k + 1) * p (m - k) + a k * q (m - k)‖ * ρ ^ (m + 2) ≤
          K * M * (((m : ℝ) + 1) * ρ + ρ ^ 2) * t ^ (m - k) := by
      intro k hk
      have hkm : k ≤ m := by rw [mem_range] at hk; omega
      obtain ⟨j, hj⟩ : ∃ j, m = k + j := ⟨m - k, by omega⟩
      have hmk : m - k = j := by omega
      rw [hmk]
      have hk1 : ‖(k : ℂ) + 1‖ = (k : ℝ) + 1 := by
        rw [show (k : ℂ) + 1 = ((k + 1 : ℕ) : ℂ) by push_cast; ring, Complex.norm_natCast]
        push_cast; ring
      have hA1 : ‖a (k + 1)‖ * ρ ^ (k + 1) ≤ K := ih (k + 1) (by omega)
      have hA0 : ‖a k‖ * ρ ^ k ≤ K := ih k (by omega)
      have hpj := hp j
      have hqj := hq j
      have hρj : ρ ^ j = t ^ j * r ^ j := by
        rw [ht, div_pow, div_mul_cancel₀ _ (by positivity)]
      have hkR : (k : ℝ) ≤ m := by exact_mod_cast hkm
      calc ‖((k : ℂ) + 1) * a (k + 1) * p j + a k * q j‖ * ρ ^ (m + 2)
          ≤ (((k : ℝ) + 1) * ‖a (k + 1)‖ * ‖p j‖ + ‖a k‖ * ‖q j‖) * ρ ^ (m + 2) := by
            gcongr
            refine (norm_add_le _ _).trans ?_
            rw [norm_mul, norm_mul, norm_mul, hk1]
        _ = ((k : ℝ) + 1) * (‖a (k + 1)‖ * ρ ^ (k + 1)) * (‖p j‖ * r ^ j) * ρ * t ^ j
            + (‖a k‖ * ρ ^ k) * (‖q j‖ * r ^ j) * ρ ^ 2 * t ^ j := by
            rw [hj, show ρ ^ (k + j + 2) = ρ ^ k * ρ ^ 2 * ρ ^ j by ring, hρj]
            ring
        _ ≤ ((k : ℝ) + 1) * K * M * ρ * t ^ j + K * M * ρ ^ 2 * t ^ j := by
            gcongr
        _ ≤ ((m : ℝ) + 1) * K * M * ρ * t ^ j + K * M * ρ ^ 2 * t ^ j := by
            gcongr
        _ = K * M * (((m : ℝ) + 1) * ρ + ρ ^ 2) * t ^ j := by ring
    have hgeom : ∑ k ∈ range (m + 1), t ^ (m - k) ≤ 1 / (1 - t) := by
      have := sum_range_reflect (fun k => t ^ k) (m + 1)
      simp only [Nat.add_sub_cancel] at this
      rw [this, ← Nat.Ico_zero_eq_range]
      simpa using geom_sum_Ico_le_of_lt_one (m := 0) (n := m + 1) ht0.le ht1
    have hsum : ‖∑ k ∈ range (m + 1),
        (((k : ℂ) + 1) * a (k + 1) * p (m - k) + a k * q (m - k))‖ * ρ ^ (m + 2) ≤
          K * (((m : ℝ) + 2) * ((m : ℝ) + 1)) := by
      calc _ ≤ (∑ k ∈ range (m + 1),
              ‖((k : ℂ) + 1) * a (k + 1) * p (m - k) + a k * q (m - k)‖) * ρ ^ (m + 2) := by
            gcongr; exact norm_sum_le _ _
        _ = ∑ k ∈ range (m + 1),
              ‖((k : ℂ) + 1) * a (k + 1) * p (m - k) + a k * q (m - k)‖ * ρ ^ (m + 2) := by
            rw [sum_mul]
        _ ≤ ∑ k ∈ range (m + 1), K * M * (((m : ℝ) + 1) * ρ + ρ ^ 2) * t ^ (m - k) :=
            sum_le_sum hterm
        _ = K * M * (((m : ℝ) + 1) * ρ + ρ ^ 2) * ∑ k ∈ range (m + 1), t ^ (m - k) := by
            rw [mul_sum]
        _ ≤ K * M * (((m : ℝ) + 1) * ρ + ρ ^ 2) * (1 / (1 - t)) := by gcongr
        _ = K * (c * (((m : ℝ) + 1) * ρ + ρ ^ 2)) := by rw [hc]; ring
        _ ≤ K * (((m : ℝ) + 2) * ((m : ℝ) + 1)) := by
            apply mul_le_mul_of_nonneg_left _ hK0
            have h1 : c * (((m : ℝ) + 1) * ρ + ρ ^ 2) ≤ ((m : ℝ) + 1) * (c * (ρ + ρ ^ 2)) := by
              have : (0 : ℝ) ≤ m := by positivity
              have : 0 ≤ c * ρ ^ 2 := by positivity
              nlinarith
            have h2 : c * (ρ + ρ ^ 2) ≤ (m : ℝ) + 2 := by linarith
            have : (0 : ℝ) ≤ m := by positivity
            nlinarith
    have heq := congrArg (fun z : ℂ => ‖z‖) (ha m)
    simp only [norm_neg] at heq
    have hm2 : ‖((m : ℂ) + 2) * ((m : ℂ) + 1)‖ = ((m : ℝ) + 2) * ((m : ℝ) + 1) := by
      rw [show ((m : ℂ) + 2) * ((m : ℂ) + 1) = (((m + 2) * (m + 1) : ℕ) : ℂ) by push_cast; ring,
        Complex.norm_natCast]
      push_cast; ring
    rw [norm_mul, hm2] at heq
    have hpos : (0 : ℝ) < ((m : ℝ) + 2) * ((m : ℝ) + 1) := by positivity
    rw [← heq] at hsum
    have : ((m : ℝ) + 2) * ((m : ℝ) + 1) * (‖a (m + 2)‖ * ρ ^ (m + 2)) ≤
        ((m : ℝ) + 2) * ((m : ℝ) + 1) * K := by
      linarith
    exact le_of_mul_le_mul_left this hpos


lemma airy_coeff_bound (a : ℕ → ℝ)
    (hrec : ∀ n : ℕ, a (n + 3) = a n / (((n : ℝ) + 3) * ((n : ℝ) + 2))) :
    ∀ R : ℝ, 0 < R → ∃ C, ∀ n, |a n| * R ^ n ≤ C := by
  intro R hR
  obtain ⟨N, hN⟩ := exists_nat_ge (R ^ 3)
  refine ⟨∑ j ∈ range (N + 3), |a j| * R ^ j, ?_⟩
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    by_cases hn : n < N + 3
    · exact single_le_sum (f := fun j => |a j| * R ^ j) (fun j _ => by positivity)
        (mem_range.2 hn)
    · obtain ⟨m, rfl⟩ : ∃ m, n = m + 3 := ⟨n - 3, by omega⟩
      have hm : N ≤ m := by omega
      have hih := ih m (by omega)
      have hmN : (N : ℝ) ≤ m := by exact_mod_cast hm
      have hpos : (0 : ℝ) < ((m : ℝ) + 3) * ((m : ℝ) + 2) := by positivity
      have hR3 : R ^ 3 ≤ ((m : ℝ) + 3) * ((m : ℝ) + 2) := by
        have : (0 : ℝ) ≤ m := by positivity
        nlinarith
      rw [hrec, abs_div, abs_of_pos hpos, pow_add]
      calc |a m| / (((m : ℝ) + 3) * ((m : ℝ) + 2)) * (R ^ m * R ^ 3)
          = |a m| * R ^ m * (R ^ 3 / (((m : ℝ) + 3) * ((m : ℝ) + 2))) := by ring
        _ ≤ |a m| * R ^ m * 1 := by
          gcongr
          rw [div_le_one hpos]; exact hR3
        _ ≤ _ := by rw [mul_one]; exact hih

lemma deriv_coeff_bound (c : ℕ → ℝ) (hc : ∀ R : ℝ, 0 < R → ∃ C, ∀ n, |c n| * R ^ n ≤ C) :
    ∀ R : ℝ, 0 < R → ∃ C, ∀ n : ℕ, |((n : ℝ) + 1) * c (n + 1)| * R ^ n ≤ C := by
  intro R hR
  obtain ⟨C, hC⟩ := hc (2 * R) (by positivity)
  refine ⟨C / R, fun n => ?_⟩
  rw [le_div_iff₀ hR, abs_mul, abs_of_pos (by positivity : (0 : ℝ) < (n : ℝ) + 1)]
  have h2 : ((n : ℝ) + 1) ≤ 2 ^ (n + 1) := by
    have := Nat.lt_two_pow_self (n := n + 1)
    exact_mod_cast this.le
  calc ((n : ℝ) + 1) * |c (n + 1)| * R ^ n * R
      = |c (n + 1)| * (((n : ℝ) + 1) * R ^ (n + 1)) := by ring
    _ ≤ |c (n + 1)| * (2 ^ (n + 1) * R ^ (n + 1)) := by gcongr
    _ = |c (n + 1)| * (2 * R) ^ (n + 1) := by ring
    _ ≤ C := hC (n + 1)

lemma series_summable_and_deriv (c : ℕ → ℝ)
    (hc : ∀ R : ℝ, 0 < R → ∃ C, ∀ n, |c n| * R ^ n ≤ C) (x : ℝ) :
    Summable (fun n => c n * x ^ n) ∧
      HasDerivAt (fun z => ∑' n, c n * z ^ n) (∑' n, c n * ((n : ℝ) * x ^ (n - 1))) x := by
  set S : ℝ := |x| + 1 with hS
  have hSpos : 0 < S := by positivity
  obtain ⟨C, hC⟩ := hc (2 * S) (by positivity)
  have hC0 : 0 ≤ C := le_trans (by positivity) (hC 0)
  have hsum : ∀ y : ℝ, |y| < S → Summable (fun n => c n * y ^ n) := by
    intro y hy
    refine Summable.of_norm_bounded (summable_geometric_two.mul_left C) (fun n => ?_)
    rw [Real.norm_eq_abs, abs_mul, abs_pow]
    have h1 : |c n| * |y| ^ n ≤ |c n| * S ^ n := by gcongr
    have h2 : |c n| * S ^ n = |c n| * (2 * S) ^ n * (1 / 2) ^ n := by
      rw [mul_assoc, ← mul_pow, show 2 * S * (1 / 2) = S by ring]
    have h3 : |c n| * (2 * S) ^ n * (1 / 2) ^ n ≤ C * (1 / 2) ^ n := by
      gcongr; exact hC n
    linarith
  refine ⟨hsum x (by rw [hS]; linarith), ?_⟩
  refine hasDerivAt_tsum_of_isPreconnected (t := Metric.ball 0 S) (y₀ := 0)
    (u := fun n : ℕ => C / S * ((n : ℝ) ^ 1 * (1 / 2) ^ n))
    ((summable_pow_mul_geometric_of_norm_lt_one 1 (by norm_num)).mul_left (C / S))
    Metric.isOpen_ball (convex_ball 0 S).isPreconnected
    (fun (n : ℕ) y _ => (hasDerivAt_pow n y).const_mul (c n)) ?_ (Metric.mem_ball_self hSpos)
    (hsum 0 (by simpa using hSpos)) (by rw [Metric.mem_ball, dist_zero_right, Real.norm_eq_abs, hS]; linarith)
  intro n y hy
  rw [Metric.mem_ball, dist_zero_right, Real.norm_eq_abs] at hy
  rw [Real.norm_eq_abs]
  rcases n with _ | n
  · simp
  · simp only [Nat.add_sub_cancel, pow_one]
    rw [abs_mul, abs_mul, abs_pow, abs_of_pos (by positivity : (0 : ℝ) < ((n + 1 : ℕ) : ℝ))]
    have h1 : |y| ^ n ≤ S ^ n := by gcongr
    have hcS := hC (n + 1)
    rw [div_mul_eq_mul_div, le_div_iff₀ hSpos]
    calc |c (n + 1)| * (((n + 1 : ℕ) : ℝ) * |y| ^ n) * S
        ≤ |c (n + 1)| * (((n + 1 : ℕ) : ℝ) * S ^ n) * S := by gcongr
      _ = (|c (n + 1)| * (2 * S) ^ (n + 1)) * (((n + 1 : ℕ) : ℝ) * (1 / 2) ^ (n + 1)) := by
        have key : (2 * S) ^ (n + 1) * (1 / 2) ^ (n + 1) = S ^ (n + 1) := by
          rw [← mul_pow]; ring_nf
        rw [show (|c (n + 1)| * (2 * S) ^ (n + 1)) * (((n + 1 : ℕ) : ℝ) * (1 / 2) ^ (n + 1))
            = |c (n + 1)| * ((n + 1 : ℕ) : ℝ) * ((2 * S) ^ (n + 1) * (1 / 2) ^ (n + 1)) by ring,
          key]
        ring
      _ ≤ C * (((n + 1 : ℕ) : ℝ) * (1 / 2) ^ (n + 1)) := by gcongr


lemma arctan_coeff_closed (b : ℕ → ℝ)
    (h0 : b 0 = 0) (h1 : b 1 = 1)
    (hrec : ∀ n : ℕ, b (n + 2) = -(n : ℝ) * b n / ((n : ℝ) + 2)) (k : ℕ) :
    b (2 * k) = 0 ∧ b (2 * k + 1) = (-1) ^ k / (2 * (k : ℝ) + 1) := by
  induction k with
  | zero => simp [h0, h1]
  | succ k ih =>
    obtain ⟨he, ho⟩ := ih
    constructor
    · rw [show 2 * (k + 1) = 2 * k + 2 by ring, hrec, he]; simp
    · rw [show 2 * (k + 1) + 1 = (2 * k + 1) + 2 by ring, hrec, ho]
      push_cast
      field_simp
      ring

#print axioms series_solution_coeff_bound
#print axioms airy_coeff_bound
#print axioms deriv_coeff_bound
#print axioms series_summable_and_deriv
#print axioms arctan_coeff_closed


/-- The radius promise at an ordinary point. Let P = Σ p_k x^k and Q = Σ q_k x^k be power series,
and let the coefficients a_n of y = Σ a_n x^n obey the rule that matching each power of x in
y'' + P y' + Q y = 0 gives:
(n + 2)(n + 1) a_(n+2) = −Σ_{k=0}^{n} [(k + 1) a_(k+1) p_(n−k) + a_k q_(n−k)].
Then the series for y converges at least as far out (in the complex plane) as both P and Q do,
whatever the starting value a_0 and rate a_1. -/
theorem series_solution_radius_ge_coefficient_radius (p q a : ℕ → ℂ)
    (ha : ∀ n : ℕ, ((n : ℂ) + 2) * ((n : ℂ) + 1) * a (n + 2) =
      -∑ k ∈ range (n + 1), (((k : ℂ) + 1) * a (k + 1) * p (n - k) + a k * q (n - k))) :
    min (ofScalars ℂ p).radius (ofScalars ℂ q).radius ≤ (ofScalars ℂ a).radius := by
  apply ENNReal.le_of_forall_nnreal_lt
  intro ρ hρ
  rcases eq_or_ne ρ 0 with h | h
  · simp [h]
  obtain ⟨r, hρr, hr⟩ := ENNReal.lt_iff_exists_nnreal_btwn.1 hρ
  obtain ⟨Cp, -, hCp⟩ := (ofScalars ℂ p).norm_mul_pow_le_of_lt_radius (hr.trans_le (min_le_left _ _))
  obtain ⟨Cq, -, hCq⟩ := (ofScalars ℂ q).norm_mul_pow_le_of_lt_radius (hr.trans_le (min_le_right _ _))
  simp only [ofScalars_norm] at hCp hCq
  have hρr' : (ρ : ℝ) < r := by exact_mod_cast hρr
  have hρ0 : (0 : ℝ) < ρ := by positivity
  obtain ⟨K, hK⟩ := series_solution_coeff_bound p q a ha ρ r (max Cp Cq) hρ0 hρr'
    (fun n => (hCp n).trans (le_max_left _ _)) (fun n => (hCq n).trans (le_max_right _ _))
  exact (ofScalars ℂ a).le_radius_of_bound K (fun n => by rw [ofScalars_norm]; exact hK n)

/-- Airy's equation for the hanging rod. With a_0 = 1, a_1 = 0, a_2 = 0 and
a_(n+3) = a_n / ((n + 3)(n + 2)), the series Σ a_n x^n converges for every real x, and its sum y
solves y'' = x y with y(0) = 1 and y'(0) = 0. -/
theorem airy_series_solves_airy_equation (a : ℕ → ℝ)
    (h0 : a 0 = 1) (h1 : a 1 = 0) (h2 : a 2 = 0)
    (hrec : ∀ n : ℕ, a (n + 3) = a n / (((n : ℝ) + 3) * ((n : ℝ) + 2))) :
    ∃ y y' : ℝ → ℝ, (∀ x : ℝ, HasSum (fun n => a n * x ^ n) (y x)) ∧
      (∀ x : ℝ, HasDerivAt y (y' x) x) ∧ (∀ x : ℝ, HasDerivAt y' (x * y x) x) ∧
      y 0 = 1 ∧ y' 0 = 0 := by
  have ha := airy_coeff_bound a hrec
  set a' : ℕ → ℝ := fun n => ((n : ℝ) + 1) * a (n + 1) with ha'def
  have ha' := deriv_coeff_bound a ha
  refine ⟨fun z => ∑' n, a n * z ^ n, fun z => ∑' n, a' n * z ^ n, ?_, ?_, ?_, ?_, ?_⟩
  · intro x; exact (series_summable_and_deriv a ha x).1.hasSum
  · intro x
    obtain ⟨-, hd⟩ := series_summable_and_deriv a ha x
    convert hd using 1
    symm
    apply HasSum.tsum_eq
    rw [← hasSum_nat_add_iff' 1]
    simp only [range_one, sum_singleton, Nat.cast_zero, zero_mul, mul_zero, sub_zero]
    convert (series_summable_and_deriv a' ha' x).1.hasSum using 1
    funext n
    simp only [ha'def, Nat.add_sub_cancel]
    push_cast; ring
  · intro x
    obtain ⟨-, hd⟩ := series_summable_and_deriv a' ha' x
    convert hd using 1
    symm
    apply HasSum.tsum_eq
    rw [← hasSum_nat_add_iff' 2]
    have hz : ∑ i ∈ range 2, a' i * ((i : ℝ) * x ^ (i - 1)) = 0 := by
      simp [sum_range_succ, ha'def, h2]
    rw [hz, sub_zero]
    have hs := ((series_summable_and_deriv a ha x).1.hasSum).mul_left x
    convert hs using 1
    funext n
    simp only [ha'def]
    rw [show n + 2 + 1 = n + 3 by ring, hrec n, show n + 2 - 1 = n + 1 by omega]
    have hpos : ((n : ℝ) + 3) * ((n : ℝ) + 2) ≠ 0 := by positivity
    push_cast
    field_simp
    ring
  · simp only
    rw [tsum_eq_single 0 (fun n hn => by simp [zero_pow hn])]
    simp [h0]
  · simp only
    rw [tsum_eq_single 0 (fun n hn => by simp [zero_pow hn])]
    simp [ha'def, h1]

/-- The arctan case: the coefficients from (1 + x^2) y'' + 2x y' = 0 with y(0) = 0, y'(0) = 1,
namely a_0 = 0, a_1 = 1 and a_(n+2) = −n a_n / (n + 2), give a power series of radius exactly 1,
the distance from 0 to the bad points ±i. -/
theorem arctan_series_radius_eq_one (b : ℕ → ℝ)
    (h0 : b 0 = 0) (h1 : b 1 = 1)
    (hrec : ∀ n : ℕ, b (n + 2) = -(n : ℝ) * b n / ((n : ℝ) + 2)) :
    (ofScalars ℝ b).radius = 1 := by
  have hc := arctan_coeff_closed b h0 h1 hrec
  have hle : ∀ n, |b n| ≤ 1 := by
    intro n
    obtain ⟨k, rfl | rfl⟩ := Nat.even_or_odd' n
    · rw [(hc k).1]; simp
    · rw [(hc k).2, abs_div, abs_pow, abs_neg, abs_one, one_pow]
      rw [abs_of_pos (by positivity)]
      rw [div_le_one (by positivity)]
      have : (0 : ℝ) ≤ k := by positivity
      linarith
  apply le_antisymm
  · by_contra hcon
    rw [not_le] at hcon
    obtain ⟨r, hr1, hr⟩ := ENNReal.lt_iff_exists_nnreal_btwn.1 hcon
    obtain ⟨C, hC, hb⟩ := (ofScalars ℝ b).norm_mul_pow_le_of_lt_radius hr
    have hr1' : (1 : ℝ) < r := by exact_mod_cast hr1
    have ht := tendsto_pow_const_div_const_pow_of_one_lt 1 hr1'
    have hev := (ht.eventually (gt_mem_nhds (show (0:ℝ) < 1 / (C + 1) by positivity)))
    obtain ⟨N, hN⟩ := Filter.eventually_atTop.1 hev
    have h1 := hN (2 * N + 1) (by omega)
    have h2 := hb (2 * N + 1)
    rw [ofScalars_norm, Real.norm_eq_abs, (hc N).2, abs_div, abs_pow, abs_neg, abs_one,
      one_pow, abs_of_pos (by positivity)] at h2
    have hx : (0 : ℝ) < (r : ℝ) ^ (2 * N + 1) := by positivity
    set x := (r : ℝ) ^ (2 * N + 1)
    have hy : (0 : ℝ) < 2 * (N : ℝ) + 1 := by positivity
    simp only [pow_one] at h1
    push_cast at h1
    rw [div_lt_div_iff₀ hx (by positivity)] at h1
    rw [div_mul_eq_mul_div, div_le_iff₀ hy] at h2
    nlinarith
  · have := (ofScalars ℝ b).le_radius_of_bound 1 (r := 1) (fun n => by
      rw [ofScalars_norm, Real.norm_eq_abs]; simpa using hle n)
    simpa using this

-- Worked numbers: a_3 = 1/6, a_6 = 1/180, a_9 = 1/12960, a_12 = 1/1710720.
example : (1 : ℚ) / (3 * 2) = 1 / 6 := by norm_num
example : ((1 : ℚ) / 6) / (6 * 5) = 1 / 180 := by norm_num
example : ((1 : ℚ) / 180) / (9 * 8) = 1 / 12960 := by norm_num
example : ((1 : ℚ) / 12960) / (12 * 11) = 1 / 1710720 := by norm_num
-- Arctan coefficients: a_3 = −1/3, a_5 = 1/5.
example : -(1 : ℚ) * 1 / (1 + 2) = -1 / 3 := by norm_num
example : -(3 : ℚ) * (-1 / 3) / (3 + 2) = 1 / 5 := by norm_num

#print axioms series_solution_radius_ge_coefficient_radius
#print axioms airy_series_solves_airy_equation
#print axioms arctan_series_radius_eq_one
