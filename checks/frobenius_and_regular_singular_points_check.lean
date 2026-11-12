-- Frobenius: at a regular singular point, a root r of the indicial equation with no other root a whole number above it gives a series x^r Σ aₙ xⁿ, built by the recurrence, that converges and solves the equation for 0 < x < R; the larger root never jams while the smaller jams exactly when the gap is a whole number; and the wire 2x y'' + y' + y = 0 has the solutions cos √(2x) and sin √(2x)/√2 with Wronskian ½ x^(-1/2).
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.SmoothSeries

open Set

theorem frobenius_coeff_vanishes (P Q a : ℕ → ℝ) (r x : ℝ)
    (hroot : r * (r - 1) + P 0 * r + Q 0 = 0)
    (hrec : ∀ n : ℕ, 1 ≤ n →
      ((r + n) * (r + n - 1) + P 0 * (r + n) + Q 0) * a n =
        -∑ k ∈ Finset.Icc 1 n, ((r + n - k) * P k + Q k) * a (n - k)) (n : ℕ) :
    (r + n) * (r + n - 1) * a n * x ^ n
      + ∑ k ∈ Finset.range (n + 1), P k * x ^ k * ((r + ((n - k : ℕ) : ℝ)) * a (n - k) * x ^ (n - k))
      + ∑ k ∈ Finset.range (n + 1), Q k * x ^ k * (a (n - k) * x ^ (n - k)) = 0 := by
  have hsum : ∑ k ∈ Finset.range (n + 1), P k * x ^ k * ((r + ((n - k : ℕ) : ℝ)) * a (n - k) * x ^ (n - k))
      + ∑ k ∈ Finset.range (n + 1), Q k * x ^ k * (a (n - k) * x ^ (n - k))
      = x ^ n * ∑ k ∈ Finset.range (n + 1), ((r + ((n - k : ℕ) : ℝ)) * P k + Q k) * a (n - k) := by
    rw [← Finset.sum_add_distrib, Finset.mul_sum]
    refine Finset.sum_congr rfl fun k hk => ?_
    have hkn : k ≤ n := Nat.lt_succ_iff.mp (Finset.mem_range.mp hk)
    rw [← pow_mul_pow_sub x hkn]
    ring
  rw [add_assoc, hsum, Finset.sum_range_succ']
  simp only [Nat.sub_zero]
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp only [Finset.range_zero, Finset.sum_empty, zero_add, CharP.cast_eq_zero, add_zero, pow_zero]
    linear_combination a 0 * hroot
  · have h := hrec n hn
    have hI : ∑ k ∈ Finset.Icc 1 n, ((r + n - (k : ℝ)) * P k + Q k) * a (n - k)
        = ∑ k ∈ Finset.range n, ((r + n - ((k + 1 : ℕ) : ℝ)) * P (k + 1) + Q (k + 1)) * a (n - (k + 1)) := by
      rw [Finset.range_eq_Ico,
        Finset.sum_Ico_add' (fun k : ℕ => ((r + n - (k : ℝ)) * P k + Q k) * a (n - k)) 0 n 1]
      rfl
    have hrw : ∑ k ∈ Finset.range n, ((r + ((n - (k + 1) : ℕ) : ℝ)) * P (k + 1) + Q (k + 1)) * a (n - (k + 1))
        = ∑ k ∈ Finset.range n, ((r + n - ((k + 1 : ℕ) : ℝ)) * P (k + 1) + Q (k + 1)) * a (n - (k + 1)) := by
      refine Finset.sum_congr rfl fun k hk => ?_
      have hkn : k + 1 ≤ n := Finset.mem_range.mp hk
      rw [Nat.cast_sub hkn]
      ring
    rw [hI] at h
    rw [hrw]
    linear_combination x ^ n * h

#print axioms frobenius_coeff_vanishes

theorem frobenius_coeff_bound (P Q a : ℕ → ℝ) (r ρ : ℝ) (hρ : 0 < ρ)
    (hPs : Summable (fun k => P k * ρ ^ k)) (hQs : Summable (fun k => Q k * ρ ^ k))
    (hroot : r * (r - 1) + P 0 * r + Q 0 = 0)
    (hrec : ∀ n : ℕ, 1 ≤ n →
      ((r + n) * (r + n - 1) + P 0 * (r + n) + Q 0) * a n =
        -∑ k ∈ Finset.Icc 1 n, ((r + n - k) * P k + Q k) * a (n - k)) :
    ∃ A : ℝ, 0 ≤ A ∧ ∀ n : ℕ, |a n| * ρ ^ n ≤ A := by
  have habs : ∀ (c : ℕ → ℝ) (k : ℕ), |c k * ρ ^ k| = |c k| * ρ ^ k := fun c k => by
    rw [abs_mul, abs_pow, abs_of_pos hρ]
  have hPa : Summable (fun k => |P k| * ρ ^ k) := by
    simpa only [habs] using hPs.abs
  have hQa : Summable (fun k => |Q k| * ρ ^ k) := by
    simpa only [habs] using hQs.abs
  set SP := ∑' k, |P k| * ρ ^ k with hSP
  set SQ := ∑' k, |Q k| * ρ ^ k with hSQ
  have hSP0 : 0 ≤ SP := tsum_nonneg fun k => by positivity
  have hSQ0 : 0 ≤ SQ := tsum_nonneg fun k => by positivity
  set c := 2 * r - 1 + P 0 with hc
  set B := |c| + SP + |r| * SP + SQ with hB
  set N := ⌈B⌉₊ + 1 with hN
  set A := ∑ j ∈ Finset.range N, |a j| * ρ ^ j with hA
  have hA0 : 0 ≤ A := Finset.sum_nonneg fun j _ => by positivity
  refine ⟨A, hA0, fun n => ?_⟩
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  by_cases hnN : n < N
  · exact Finset.single_le_sum (f := fun j => |a j| * ρ ^ j) (fun j _ => by positivity)
      (Finset.mem_range.mpr hnN)
  push Not at hnN
  have hn1 : 1 ≤ n := le_trans (by omega) hnN
  have hn1' : (1 : ℝ) ≤ n := by exact_mod_cast hn1
  have hBn : B < n := by
    have h1 : B ≤ (⌈B⌉₊ : ℝ) := Nat.le_ceil B
    have h2 : ((⌈B⌉₊ : ℕ) : ℝ) + 1 ≤ n := by exact_mod_cast hnN
    linarith
  have hI : (r + n) * (r + n - 1) + P 0 * (r + n) + Q 0 = n ^ 2 + c * n := by
    rw [hc]; linear_combination hroot
  have hcn : -|c| * n ≤ c * n := by
    have := neg_abs_le c
    nlinarith
  have hbound : (|r| + n) * SP + SQ ≤ n ^ 2 + c * n := by
    have h3 : n * (SP + |r| * SP + SQ) ≤ n * (n - |c|) := by
      apply mul_le_mul_of_nonneg_left _ (by linarith)
      linarith
    have h4 : |r| * SP + SQ ≤ n * (|r| * SP + SQ) := by
      have : 0 ≤ |r| * SP + SQ := by positivity
      nlinarith
    nlinarith
  have hIpos : 0 < (n : ℝ) ^ 2 + c * n := by
    have : 0 < (n : ℝ) ^ 2 - |c| * n + 0 := by
      have : |c| ≤ B := by rw [hB]; linarith [mul_nonneg (abs_nonneg r) hSP0]
      have h5 : 0 < (n : ℝ) - |c| := by linarith
      have h6 : 0 < (n : ℝ) * (n - |c|) := mul_pos (by linarith) h5
      nlinarith
    linarith
  have hterm : ∀ k ∈ Finset.Icc 1 n,
      |((r + n - k) * P k + Q k) * a (n - k)| * ρ ^ n
        ≤ ((|r| + n) * (|P k| * ρ ^ k) + |Q k| * ρ ^ k) * A := by
    intro k hk
    have hk1 : 1 ≤ k := (Finset.mem_Icc.mp hk).1
    have hkn : k ≤ n := (Finset.mem_Icc.mp hk).2
    have hkn' : (k : ℝ) ≤ n := by exact_mod_cast hkn
    have hk1' : (1 : ℝ) ≤ k := by exact_mod_cast hk1
    have hih : |a (n - k)| * ρ ^ (n - k) ≤ A := ih (n - k) (by omega)
    have hcoef : |(r + n - k) * P k + Q k| ≤ (|r| + n) * |P k| + |Q k| := by
      calc |(r + n - k) * P k + Q k| ≤ |(r + n - k) * P k| + |Q k| := abs_add_le _ _
        _ = |r + (n - k)| * |P k| + |Q k| := by rw [abs_mul]; ring_nf
        _ ≤ (|r| + n) * |P k| + |Q k| := by
          have h7 : |r + ((n : ℝ) - k)| ≤ |r| + n := by
            calc |r + ((n : ℝ) - k)| ≤ |r| + |(n : ℝ) - k| := abs_add_le _ _
              _ ≤ |r| + n := by
                rw [abs_of_nonneg (show (0 : ℝ) ≤ n - k by linarith)]; linarith
          have h8 := mul_le_mul_of_nonneg_right h7 (abs_nonneg (P k))
          linarith
    calc |((r + n - k) * P k + Q k) * a (n - k)| * ρ ^ n
        = (|(r + n - k) * P k + Q k| * ρ ^ k) * (|a (n - k)| * ρ ^ (n - k)) := by
          rw [abs_mul, ← pow_mul_pow_sub ρ hkn]; ring
      _ ≤ (((|r| + n) * |P k| + |Q k|) * ρ ^ k) * A :=
          mul_le_mul (mul_le_mul_of_nonneg_right hcoef (by positivity)) hih (by positivity)
            (by positivity)
      _ = ((|r| + n) * (|P k| * ρ ^ k) + |Q k| * ρ ^ k) * A := by ring
  have hPsum : ∑ k ∈ Finset.Icc 1 n, |P k| * ρ ^ k ≤ SP :=
    hPa.sum_le_tsum _ (fun k _ => by positivity)
  have hQsum : ∑ k ∈ Finset.Icc 1 n, |Q k| * ρ ^ k ≤ SQ :=
    hQa.sum_le_tsum _ (fun k _ => by positivity)
  have key : |a n| * ρ ^ n * (n ^ 2 + c * n) ≤ A * (n ^ 2 + c * n) := by
    calc |a n| * ρ ^ n * (n ^ 2 + c * n)
        = |((r + n) * (r + n - 1) + P 0 * (r + n) + Q 0) * a n| * ρ ^ n := by
          rw [hI, abs_mul, abs_of_pos hIpos]; ring
      _ = |∑ k ∈ Finset.Icc 1 n, ((r + n - k) * P k + Q k) * a (n - k)| * ρ ^ n := by
          rw [hrec n hn1, abs_neg]
      _ ≤ (∑ k ∈ Finset.Icc 1 n, |((r + n - k) * P k + Q k) * a (n - k)|) * ρ ^ n := by
          gcongr
          exact Finset.abs_sum_le_sum_abs _ _
      _ = ∑ k ∈ Finset.Icc 1 n, |((r + n - k) * P k + Q k) * a (n - k)| * ρ ^ n := by
          rw [Finset.sum_mul]
      _ ≤ ∑ k ∈ Finset.Icc 1 n, ((|r| + n) * (|P k| * ρ ^ k) + |Q k| * ρ ^ k) * A :=
          Finset.sum_le_sum hterm
      _ = A * ((|r| + n) * ∑ k ∈ Finset.Icc 1 n, |P k| * ρ ^ k
            + ∑ k ∈ Finset.Icc 1 n, |Q k| * ρ ^ k) := by
          rw [← Finset.sum_mul, Finset.sum_add_distrib, ← Finset.mul_sum]; ring
      _ ≤ A * ((|r| + n) * SP + SQ) := by
          gcongr
      _ ≤ A * (n ^ 2 + c * n) := by gcongr
  exact le_of_mul_le_mul_right key hIpos

#print axioms frobenius_coeff_bound

/-- Frobenius's method works. Write the equation as x² y'' + x P(x) y' + Q(x) y = 0, where
P(x) = Σ Pₖ xᵏ and Q(x) = Σ Qₖ xᵏ are power series that converge for |x| < R: then x = 0 is a
regular singular point. Let r be a real root of the indicial equation
I(r) = r(r - 1) + P₀ r + Q₀ = 0 such that no root of I lies a whole number N ≥ 1 above r (this
is always true of the larger root, and true of the smaller root when the gap is not a whole
number). Let the coefficients aₙ obey the recurrence
I(r + n) aₙ = -Σ_{k=1}^{n} [(r + n - k) Pₖ + Qₖ] aₙ₋ₖ for n ≥ 1.
Then for every x with 0 < x < R the series Σ aₙ xⁿ converges, and y(x) = x^r Σ aₙ xⁿ is twice
differentiable there and solves x² y'' + x P(x) y' + Q(x) y = 0. -/
theorem frobenius_series_solves_at_regular_singular_point
    (P Q : ℕ → ℝ) (R : ℝ)
    (hP : ∀ x : ℝ, |x| < R → Summable (fun k => P k * x ^ k))
    (hQ : ∀ x : ℝ, |x| < R → Summable (fun k => Q k * x ^ k))
    (r : ℝ) (hroot : r * (r - 1) + P 0 * r + Q 0 = 0)
    (hno_jam : ∀ N : ℕ, 1 ≤ N →
      (r + N) * (r + N - 1) + P 0 * (r + N) + Q 0 ≠ 0)
    (a : ℕ → ℝ)
    (hrec : ∀ n : ℕ, 1 ≤ n →
      ((r + n) * (r + n - 1) + P 0 * (r + n) + Q 0) * a n =
        -∑ k ∈ Finset.Icc 1 n, ((r + n - k) * P k + Q k) * a (n - k)) :
    ∀ x ∈ Ioo 0 R,
      Summable (fun n => a n * x ^ n) ∧
      DifferentiableAt ℝ (fun t => t ^ r * ∑' n, a n * t ^ n) x ∧
      DifferentiableAt ℝ (deriv (fun t => t ^ r * ∑' n, a n * t ^ n)) x ∧
      x ^ 2 * deriv (deriv (fun t => t ^ r * ∑' n, a n * t ^ n)) x
        + x * (∑' k, P k * x ^ k) * deriv (fun t => t ^ r * ∑' n, a n * t ^ n) x
        + (∑' k, Q k * x ^ k) * (x ^ r * ∑' n, a n * x ^ n) = 0 := by
  intro x hx
  obtain ⟨hx0, hxR⟩ := hx
  obtain ⟨ρ, hxρ, hρR⟩ : ∃ ρ, x < ρ ∧ ρ < R := ⟨(x + R) / 2, by linarith, by linarith⟩
  obtain ⟨s, hxs, hsρ⟩ : ∃ s, x < s ∧ s < ρ := ⟨(x + ρ) / 2, by linarith, by linarith⟩
  have hρ0 : 0 < ρ := by linarith
  have hs0 : 0 < s := by linarith
  have hPs := hP ρ (by rw [abs_of_pos hρ0]; exact hρR)
  have hQs := hQ ρ (by rw [abs_of_pos hρ0]; exact hρR)
  obtain ⟨A, hA0, hA⟩ := frobenius_coeff_bound P Q a r ρ hρ0 hPs hQs hroot hrec
  set q := s / ρ with hq
  have hq0 : 0 ≤ q := by positivity
  have hq1 : q < 1 := by rw [hq, div_lt_one hρ0]; exact hsρ
  have hsq : s = ρ * q := by rw [hq]; field_simp
  have hkey : ∀ n : ℕ, |a n| * s ^ n ≤ A * q ^ n := fun n => by
    calc |a n| * s ^ n = (|a n| * ρ ^ n) * q ^ n := by rw [hsq, mul_pow]; ring
      _ ≤ A * q ^ n := mul_le_mul_of_nonneg_right (hA n) (pow_nonneg hq0 n)
  obtain ⟨g1, hg1⟩ : ∃ g1 : ℕ → ℝ → ℝ, g1 = fun n t => a n * ((n : ℝ) * t ^ (n - 1)) := ⟨_, rfl⟩
  obtain ⟨g2, hg2⟩ : ∃ g2 : ℕ → ℝ → ℝ,
      g2 = fun n t => a n * ((n : ℝ) * (((n - 1 : ℕ) : ℝ) * t ^ (n - 1 - 1))) := ⟨_, rfl⟩
  have hmem : ∀ t : ℝ, t ∈ Metric.ball (0 : ℝ) s → |t| ≤ s := fun t ht => by
    rw [mem_ball_zero_iff, Real.norm_eq_abs] at ht; exact ht.le
  have b0 : ∀ n (t : ℝ), |t| ≤ s → ‖a n * t ^ n‖ ≤ A * q ^ n := fun n t ht => by
    rw [Real.norm_eq_abs, abs_mul, abs_pow]
    calc |a n| * |t| ^ n ≤ |a n| * s ^ n := by gcongr
      _ ≤ A * q ^ n := hkey n
  have b1 : ∀ n (t : ℝ), |t| ≤ s → ‖g1 n t‖ ≤ A / s * ((n : ℝ) * q ^ n) := fun n t ht => by
    rw [hg1, Real.norm_eq_abs]
    rcases n with _ | m
    · simp
    · simp only [Nat.add_sub_cancel, abs_mul, abs_pow]
      push_cast
      rw [abs_of_nonneg (by positivity : (0 : ℝ) ≤ m + 1)]
      calc |a (m + 1)| * ((m + 1) * |t| ^ m) ≤ |a (m + 1)| * ((m + 1) * s ^ m) := by gcongr
        _ = (|a (m + 1)| * s ^ (m + 1)) * (m + 1) / s := by field_simp; ring
        _ ≤ (A * q ^ (m + 1)) * (m + 1) / s := by gcongr ?_ * _ / _; exact hkey (m + 1)
        _ = A / s * ((m + 1) * q ^ (m + 1)) := by ring
  have b2 : ∀ n (t : ℝ), |t| ≤ s → ‖g2 n t‖ ≤ A / s ^ 2 * ((n : ℝ) ^ 2 * q ^ n) :=
    fun n t ht => by
    rw [hg2, Real.norm_eq_abs]
    rcases n with _ | _ | m
    · simp
    · simp; positivity
    · simp only [Nat.add_sub_cancel, abs_mul, abs_pow, show m + 1 + 1 - 1 = m + 1 by omega]
      push_cast
      rw [abs_of_nonneg (by positivity : (0 : ℝ) ≤ m + 1 + 1),
        abs_of_nonneg (by positivity : (0 : ℝ) ≤ m + 1)]
      have hqm : 0 ≤ A * q ^ (m + 2) := by positivity
      calc |a (m + 2)| * ((m + 1 + 1) * ((m + 1) * |t| ^ m))
          ≤ |a (m + 2)| * ((m + 1 + 1) * ((m + 1) * s ^ m)) := by gcongr
        _ = (|a (m + 2)| * s ^ (m + 2)) * ((m + 2) * (m + 1)) / s ^ 2 := by field_simp; ring
        _ ≤ (A * q ^ (m + 2)) * ((m + 2) * (m + 1)) / s ^ 2 := by
          gcongr ?_ * _ / _; exact hkey (m + 2)
        _ ≤ (A * q ^ (m + 2)) * ((m + 2) * (m + 2)) / s ^ 2 := by gcongr; linarith
        _ = A / s ^ 2 * ((m + 1 + 1) ^ 2 * q ^ (m + 1 + 1)) := by ring
  have hqn : ‖q‖ < 1 := by rw [Real.norm_eq_abs, abs_of_nonneg hq0]; exact hq1
  have hu0 : Summable (fun n : ℕ => A * q ^ n) := (summable_geometric_of_lt_one hq0 hq1).mul_left A
  have hu1 : Summable (fun n : ℕ => A / s * ((n : ℝ) * q ^ n)) := by
    have := summable_pow_mul_geometric_of_norm_lt_one 1 hqn
    simp only [pow_one] at this
    exact this.mul_left _
  have hu2 : Summable (fun n : ℕ => A / s ^ 2 * ((n : ℝ) ^ 2 * q ^ n)) :=
    (summable_pow_mul_geometric_of_norm_lt_one 2 hqn).mul_left _
  have hxU : x ∈ Metric.ball (0 : ℝ) s := by
    rw [mem_ball_zero_iff, Real.norm_eq_abs, abs_of_pos hx0]; exact hxs
  have hxs' : |x| ≤ s := hmem x hxU
  have hF : ∀ t ∈ Metric.ball (0 : ℝ) s,
      HasDerivAt (fun z => ∑' n, a n * z ^ n) (∑' n, g1 n t) t := fun t ht =>
    hasDerivAt_tsum_of_isPreconnected (g := fun n z => a n * z ^ n) hu1 Metric.isOpen_ball
      (convex_ball (0 : ℝ) s).isPreconnected
      (fun n y _ => by rw [hg1]; exact (hasDerivAt_pow n y).const_mul (a n))
      (fun n y hy => b1 n y (hmem y hy)) (Metric.mem_ball_self hs0)
      (hu0.of_norm_bounded fun n => b0 n 0 (by simp [hs0.le])) ht
  have hF1 : ∀ t ∈ Metric.ball (0 : ℝ) s,
      HasDerivAt (fun z => ∑' n, g1 n z) (∑' n, g2 n t) t := fun t ht =>
    hasDerivAt_tsum_of_isPreconnected (g := g1) hu2 Metric.isOpen_ball
      (convex_ball (0 : ℝ) s).isPreconnected
      (fun n y _ => by
        rw [hg1, hg2]
        exact ((hasDerivAt_pow (n - 1) y).const_mul (n : ℝ)).const_mul (a n))
      (fun n y hy => b2 n y (hmem y hy)) (Metric.mem_ball_self hs0)
      (hu1.of_norm_bounded fun n => b1 n 0 (by simp [hs0.le])) ht
  have hs0x : Summable (fun n => a n * x ^ n) := hu0.of_norm_bounded fun n => b0 n x hxs'
  have hs1x : Summable (fun n => g1 n x) := hu1.of_norm_bounded fun n => b1 n x hxs'
  have hs2x : Summable (fun n => g2 n x) := hu2.of_norm_bounded fun n => b2 n x hxs'
  have hball : ∀ t, 0 < t → t < s → t ∈ Metric.ball (0 : ℝ) s := fun t ht hts => by
    rw [mem_ball_zero_iff, Real.norm_eq_abs, abs_of_pos ht]; exact hts
  have hy : ∀ t, 0 < t → t < s → HasDerivAt (fun t => t ^ r * ∑' n, a n * t ^ n)
      (r * t ^ (r - 1) * (∑' n, a n * t ^ n) + t ^ r * ∑' n, g1 n t) t := fun t ht hts =>
    (Real.hasDerivAt_rpow_const (Or.inl ht.ne')).mul (hF t (hball t ht hts))
  have hev : deriv (fun t => t ^ r * ∑' n, a n * t ^ n) =ᶠ[nhds x]
      fun t => r * t ^ (r - 1) * (∑' n, a n * t ^ n) + t ^ r * ∑' n, g1 n t := by
    filter_upwards [Ioo_mem_nhds hx0 hxs] with t ht
    exact (hy t ht.1 ht.2).deriv
  have hY1 := ((((Real.hasDerivAt_rpow_const (p := r - 1) (Or.inl hx0.ne')).const_mul r).mul
      (hF x hxU)).add ((Real.hasDerivAt_rpow_const (p := r) (Or.inl hx0.ne')).mul
      (hF1 x hxU))).congr_of_eventuallyEq hev
  refine ⟨hs0x, (hy x hx0 hxs).differentiableAt, hY1.differentiableAt, ?_⟩
  -- the bracket identity from the series
  have hF0s := hs0x.hasSum
  have hF1s := hs1x.hasSum
  have hF2s := hs2x.hasSum
  have hG : HasSum (fun n : ℕ => (r + n) * a n * x ^ n)
      (r * (∑' n, a n * x ^ n) + x * ∑' n, g1 n x) := by
    convert (hF0s.mul_left r).add (hF1s.mul_left x) using 1
    funext n
    rw [hg1]
    rcases n with _ | m
    · simp
    · simp only [Nat.add_sub_cancel]; push_cast; ring
  have hE : HasSum (fun n : ℕ => (r + n) * (r + n - 1) * a n * x ^ n)
      (r * (r - 1) * (∑' n, a n * x ^ n) + 2 * r * x * (∑' n, g1 n x)
        + x ^ 2 * ∑' n, g2 n x) := by
    convert ((hF0s.mul_left (r * (r - 1))).add (hF1s.mul_left (2 * r * x))).add
      (hF2s.mul_left (x ^ 2)) using 1
    funext n
    rw [hg1, hg2]
    rcases n with _ | _ | m
    · simp
    · simp; ring
    · simp only [Nat.add_sub_cancel, show m + 1 + 1 - 1 = m + 1 by omega]
      push_cast; ring
  have hxabs : |x| < R := by rw [abs_of_pos hx0]; exact hxR
  have hPn : Summable (fun k => ‖P k * x ^ k‖) := by
    simpa only [Real.norm_eq_abs] using (hP x hxabs).abs
  have hQn : Summable (fun k => ‖Q k * x ^ k‖) := by
    simpa only [Real.norm_eq_abs] using (hQ x hxabs).abs
  have hGn : Summable (fun n : ℕ => ‖(r + n) * a n * x ^ n‖) := by
    simpa only [Real.norm_eq_abs] using hG.summable.abs
  have hFn : Summable (fun n : ℕ => ‖a n * x ^ n‖) := by
    simpa only [Real.norm_eq_abs] using hs0x.abs
  have hPG := hasSum_sum_range_mul_of_summable_norm hPn hGn
  have hQF := hasSum_sum_range_mul_of_summable_norm hQn hFn
  rw [hG.tsum_eq] at hPG
  have htot := (hE.add hPG).add hQF
  have hfun : (fun n : ℕ => (r + n) * (r + n - 1) * a n * x ^ n
      + ∑ k ∈ Finset.range (n + 1), P k * x ^ k * ((r + ((n - k : ℕ) : ℝ)) * a (n - k) * x ^ (n - k))
      + ∑ k ∈ Finset.range (n + 1), Q k * x ^ k * (a (n - k) * x ^ (n - k))) = fun _ => 0 := by
    funext n
    exact frobenius_coeff_vanishes P Q a r x hroot hrec n
  rw [hfun] at htot
  have hbr := htot.unique hasSum_zero
  rw [hY1.deriv, (hy x hx0 hxs).deriv, Real.rpow_sub_one hx0.ne' (r - 1),
    Real.rpow_sub_one hx0.ne' r]
  generalize (∑' n, a n * x ^ n) = F0 at hbr ⊢
  generalize (∑' n, g1 n x) = F1 at hbr ⊢
  generalize (∑' n, g2 n x) = F2 at hbr ⊢
  generalize (∑' n, P n * x ^ n) = Pv at hbr ⊢
  generalize (∑' n, Q n * x ^ n) = Qv at hbr ⊢
  field_simp
  linear_combination x ^ r * hbr

/-- When the recurrence jams. Let r₁ ≥ r₂ be the two real roots of the indicial polynomial,
so r(r - 1) + P₀ r + Q₀ = (r - r₁)(r - r₂) for every r. The larger root never jams:
I(r₁ + n) = n (n + r₁ - r₂) > 0 for every n ≥ 1. The smaller root jams, I(r₂ + n) = 0 for
some n ≥ 1, exactly when the gap r₁ - r₂ is a whole number N ≥ 1. -/
theorem larger_root_never_jams_smaller_jams_iff_whole_gap
    (P₀ Q₀ r₁ r₂ : ℝ) (hfactor : ∀ r : ℝ, r * (r - 1) + P₀ * r + Q₀ = (r - r₁) * (r - r₂))
    (horder : r₂ ≤ r₁) :
    (∀ n : ℕ, 1 ≤ n →
      (r₁ + n) * (r₁ + n - 1) + P₀ * (r₁ + n) + Q₀ = n * (n + (r₁ - r₂)) ∧
      0 < (r₁ + n) * (r₁ + n - 1) + P₀ * (r₁ + n) + Q₀) ∧
    ((∃ n : ℕ, 1 ≤ n ∧ (r₂ + n) * (r₂ + n - 1) + P₀ * (r₂ + n) + Q₀ = 0) ↔
      ∃ N : ℕ, 1 ≤ N ∧ r₁ - r₂ = N) := by
  refine ⟨fun n hn => ?_, ?_⟩
  · have h := hfactor (r₁ + n)
    have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
    refine ⟨by rw [h]; ring, ?_⟩
    rw [h]
    have : (r₁ + n - r₁) * (r₁ + n - r₂) = n * (n + (r₁ - r₂)) := by ring
    rw [this]
    have : 0 < (n : ℝ) + (r₁ - r₂) := by linarith
    positivity
  · constructor
    · rintro ⟨n, hn, h0⟩
      refine ⟨n, hn, ?_⟩
      have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
      rw [hfactor] at h0
      have : (n : ℝ) * (r₂ + n - r₁) = 0 := by rw [← h0]; ring
      rcases mul_eq_zero.mp this with h | h
      · linarith
      · linarith
    · rintro ⟨N, hN, h⟩
      refine ⟨N, hN, ?_⟩
      rw [hfactor]
      have : r₂ + N - r₁ = 0 := by linarith
      rw [this]; ring

/-- The tapered wire 2x y'' + y' + y = 0. For every x > 0, both y₁ = cos √(2x) and
y₂ = sin √(2x) / √2 solve it, and their Wronskian y₁ y₂' - y₁' y₂ equals ½ x^(-1/2),
which is never 0, so the two solutions are independent. -/
theorem wire_solutions_and_wronskian (x : ℝ) (hx : 0 < x) :
    2 * x * deriv (deriv (fun t => Real.cos (Real.sqrt (2 * t)))) x
        + deriv (fun t => Real.cos (Real.sqrt (2 * t))) x + Real.cos (Real.sqrt (2 * x)) = 0 ∧
    2 * x * deriv (deriv (fun t => Real.sin (Real.sqrt (2 * t)) / Real.sqrt 2)) x
        + deriv (fun t => Real.sin (Real.sqrt (2 * t)) / Real.sqrt 2) x
        + Real.sin (Real.sqrt (2 * x)) / Real.sqrt 2 = 0 ∧
    Real.cos (Real.sqrt (2 * x)) * deriv (fun t => Real.sin (Real.sqrt (2 * t)) / Real.sqrt 2) x
        - deriv (fun t => Real.cos (Real.sqrt (2 * t))) x
            * (Real.sin (Real.sqrt (2 * x)) / Real.sqrt 2)
      = 1 / 2 * x ^ (-(1 / 2 : ℝ)) := by
  -- s(t) = √(2t), s' = 1/s
  have hs : ∀ t : ℝ, 0 < t → HasDerivAt (fun t => Real.sqrt (2 * t)) (1 / Real.sqrt (2 * t)) t := by
    intro t ht
    have h1 : HasDerivAt (fun t : ℝ => 2 * t) 2 t := by
      simpa using (hasDerivAt_id t).const_mul (2 : ℝ)
    have h2 := h1.sqrt (by positivity)
    have hpos : 0 < Real.sqrt (2 * t) := Real.sqrt_pos.mpr (by positivity)
    convert h2 using 1
    field_simp
  have hspos : ∀ t : ℝ, 0 < t → 0 < Real.sqrt (2 * t) := fun t ht => Real.sqrt_pos.mpr (by positivity)
  have hsq : ∀ t : ℝ, 0 < t → Real.sqrt (2 * t) ^ 2 = 2 * t := fun t ht =>
    Real.sq_sqrt (by positivity)
  have hr2 : 0 < Real.sqrt 2 := by positivity
  -- first derivatives
  have hc1 : ∀ t : ℝ, 0 < t → HasDerivAt (fun t => Real.cos (Real.sqrt (2 * t)))
      (-Real.sin (Real.sqrt (2 * t)) / Real.sqrt (2 * t)) t := by
    intro t ht
    convert (hs t ht).cos using 1
    ring
  have hs1 : ∀ t : ℝ, 0 < t → HasDerivAt (fun t => Real.sin (Real.sqrt (2 * t)) / Real.sqrt 2)
      (Real.cos (Real.sqrt (2 * t)) / Real.sqrt (2 * t) / Real.sqrt 2) t := by
    intro t ht
    convert ((hs t ht).sin).div_const (Real.sqrt 2) using 1
    ring
  have hev : ∀ᶠ t in nhds x, 0 < t := lt_mem_nhds hx
  have hdc : deriv (fun t => Real.cos (Real.sqrt (2 * t))) =ᶠ[nhds x]
      (fun t => -Real.sin (Real.sqrt (2 * t)) / Real.sqrt (2 * t)) :=
    hev.mono fun t ht => (hc1 t ht).deriv
  have hds : deriv (fun t => Real.sin (Real.sqrt (2 * t)) / Real.sqrt 2) =ᶠ[nhds x]
      (fun t => Real.cos (Real.sqrt (2 * t)) / Real.sqrt (2 * t) / Real.sqrt 2) :=
    hev.mono fun t ht => (hs1 t ht).deriv
  -- second derivatives
  set s := Real.sqrt (2 * x) with hs_def
  have hsx := hspos x hx
  have hc2 : HasDerivAt (fun t => -Real.sin (Real.sqrt (2 * t)) / Real.sqrt (2 * t))
      ((-(Real.cos s * (1 / s)) * s - (-Real.sin s) * (1 / s)) / s ^ 2) x :=
    ((hs x hx).sin.neg).div (hs x hx) hsx.ne'
  have hs2 : HasDerivAt (fun t => Real.cos (Real.sqrt (2 * t)) / Real.sqrt (2 * t) / Real.sqrt 2)
      (((-Real.sin s * (1 / s)) * s - Real.cos s * (1 / s)) / s ^ 2 / Real.sqrt 2) x :=
    (((hs x hx).cos).div (hs x hx) hsx.ne').div_const _
  rw [(hc2.congr_of_eventuallyEq hdc).deriv, (hs2.congr_of_eventuallyEq hds).deriv,
    (hc1 x hx).deriv, (hs1 x hx).deriv, ← hs_def]
  have hs0 : s ≠ 0 := by rw [hs_def]; exact hsx.ne'
  have h2x : 2 * x = s ^ 2 := (hsq x hx).symm
  have hxs : x = s ^ 2 / 2 := by linarith
  refine ⟨?_, ?_, ?_⟩
  · rw [hxs]; field_simp; ring
  · rw [hxs]; field_simp; ring
  · have hcs := Real.sin_sq_add_cos_sq s
    have hrp : x ^ (-(1 / 2 : ℝ)) = 1 / Real.sqrt x := by
      rw [Real.rpow_neg hx.le, Real.sqrt_eq_rpow]; exact (one_div _).symm
    have hsx' : s = Real.sqrt 2 * Real.sqrt x := by
      rw [hs_def, Real.sqrt_mul (by norm_num)]
    rw [hrp, hsx']
    have hsqx : 0 < Real.sqrt x := Real.sqrt_pos.mpr hx
    have h22 : Real.sqrt 2 * Real.sqrt 2 = 2 := Real.mul_self_sqrt (by norm_num)
    field_simp
    rw [← hsx']
    nlinarith [hcs, h22]

-- The wire: P = x p = 1/2 and Q = x² q = x/2, so P₀ = 1/2, Q₀ = 0, Q₁ = 1/2.
-- Indicial r(r - 1) + r/2 = 0 has the roots 0 and 1/2.
example : (0 : ℚ) * (0 - 1) + 1 / 2 * 0 + 0 = 0 := by norm_num
example : (1 / 2 : ℚ) * (1 / 2 - 1) + 1 / 2 * (1 / 2) + 0 = 0 := by norm_num
-- On the wire the recurrence is I(r + n) aₙ = -(1/2) aₙ₋₁ with I(s) = s(s - 1/2).
-- r = 0: the coefficients 1, -1, 1/6, -1/90, 1/2520.
example : ((0 + 1 : ℚ) * (0 + 1 - 1 / 2)) * (-1) = -(1 / 2) * 1 := by norm_num
example : ((0 + 2 : ℚ) * (0 + 2 - 1 / 2)) * (1 / 6) = -(1 / 2) * (-1) := by norm_num
example : ((0 + 3 : ℚ) * (0 + 3 - 1 / 2)) * (-1 / 90) = -(1 / 2) * (1 / 6) := by norm_num
example : ((0 + 4 : ℚ) * (0 + 4 - 1 / 2)) * (1 / 2520) = -(1 / 2) * (-1 / 90) := by norm_num
-- r = 1/2: the coefficients 1, -1/3, 1/30, -1/630, 1/22680.
example : ((1 / 2 + 1 : ℚ) * (1 / 2 + 1 - 1 / 2)) * (-1 / 3) = -(1 / 2) * 1 := by norm_num
example : ((1 / 2 + 2 : ℚ) * (1 / 2 + 2 - 1 / 2)) * (1 / 30) = -(1 / 2) * (-1 / 3) := by norm_num
example : ((1 / 2 + 3 : ℚ) * (1 / 2 + 3 - 1 / 2)) * (-1 / 630) = -(1 / 2) * (1 / 30) := by
  norm_num
example : ((1 / 2 + 4 : ℚ) * (1 / 2 + 4 - 1 / 2)) * (1 / 22680) = -(1 / 2) * (-1 / 630) := by
  norm_num
-- Five terms at x = 1: 1 - 1 + 1/6 - 1/90 + 1/2520 = 131/840 (= 0.155952380952...).
example : (1 : ℚ) - 1 + 1 / 6 - 1 / 90 + 1 / 2520 = 131 / 840 := by norm_num
-- The "by hand" divisors 1·1, 2·3, 3·5, 4·7 multiply to 2520.
example : (1 * 1) * (2 * 3) * (3 * 5) * (4 * 7) = 2520 := by decide
-- Log case x(1 - x) y'' + x y' - y = 0: P₀ = Q₀ = 0, P₁ = 1, Q₁ = -1, roots 0 and 1.
-- At r = 0, n = 1 the recurrence asks I(1) a₁ = -[(0 + 1 - 1) P₁ + Q₁] a₀, that is 0 · a₁ = 1.
example : (1 : ℚ) * (1 - 1) + 0 * 1 + 0 = 0 := by norm_num
example : -(((0 : ℚ) + 1 - 1) * 1 + (-1)) * 1 = 1 := by norm_num
-- x² y'' - 2x y' + 2y = 0: r(r - 1) - 2r + 2 = (r - 1)(r - 2), roots 1 and 2.
example : ∀ r : ℚ, r * (r - 1) + (-2) * r + 2 = (r - 1) * (r - 2) := by intro r; ring
-- Mistake, forgetting the -r: r² + r/2 = 0 has the roots 0 and -1/2,
-- and x^(-1/2) leaves (2 r (r - 1) + r) x^(r - 1) = 1 · x^(-3/2) in 2x y'' + y'.
example : (-1 / 2 : ℚ) ^ 2 + 1 / 2 * (-1 / 2) = 0 := by norm_num
example : 2 * (-1 / 2 : ℚ) * (-1 / 2 - 1) + (-1 / 2) = 1 := by norm_num
-- Mistake, a log forced on x² y'' - 2x y' + 2y = 0: y = x ln x leaves x - 2x = -x, so -1 at x = 1.
example : (1 : ℚ) - 2 * (0 + 1) + 2 * 0 = -1 := by norm_num

#print axioms frobenius_series_solves_at_regular_singular_point
#print axioms larger_root_never_jams_smaller_jams_iff_whole_gap
#print axioms wire_solutions_and_wronskian
