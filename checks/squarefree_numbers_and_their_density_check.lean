-- Squarefree numbers: the Mobius sieve over the squares d² ≤ x counts the squarefree numbers up to x exactly, the count is 6x/π² with an error at most ⌊√x⌋ + x/⌊√x⌋ ≤ 3√x, and so the squarefree numbers have natural density 6/π².
import Mathlib.Data.Nat.Squarefree
import Mathlib.NumberTheory.ArithmeticFunction.Moebius
import Mathlib.NumberTheory.ArithmeticFunction.Misc
import Mathlib.NumberTheory.ZetaValues
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.NumberTheory.LSeries.Dirichlet
import Mathlib.NumberTheory.LSeries.HurwitzZetaValues
import Mathlib.Algebra.Order.Floor.Semifield

open ArithmeticFunction Filter Topology
open scoped ArithmeticFunction.Moebius ArithmeticFunction.Omega

/-- `d² ∣ b² a` with `a` squarefree forces `d ∣ b`. -/
theorem sqfree_sq_dvd_iff {a b d : ℕ} (ha : Squarefree a) (hb : 0 < b) :
    d ^ 2 ∣ b ^ 2 * a ↔ d ∣ b := by
  constructor
  · intro h
    obtain ⟨g, d', b', hg, hcop, rfl, rfl⟩ := Nat.exists_coprime' (Nat.gcd_pos_of_pos_right d hb)
    have h2 : d' ^ 2 ∣ b' ^ 2 * a := by
      have : g ^ 2 * d' ^ 2 ∣ g ^ 2 * (b' ^ 2 * a) := by
        have e1 : (d' * g) ^ 2 = g ^ 2 * d' ^ 2 := by ring
        have e2 : (b' * g) ^ 2 * a = g ^ 2 * (b' ^ 2 * a) := by ring
        rw [← e1, ← e2]; exact h
      exact Nat.dvd_of_mul_dvd_mul_left (by positivity) this
    have h3 : d' ^ 2 ∣ a :=
      (Nat.Coprime.pow 2 2 hcop).dvd_of_dvd_mul_left h2
    have h4 : IsUnit d' := ha d' (by simpa [sq] using h3)
    rw [Nat.isUnit_iff.mp h4, one_mul]
    exact Dvd.intro_left _ rfl
  · intro h
    exact Dvd.dvd.mul_right (pow_dvd_pow_of_dvd h 2) a

#print axioms sqfree_sq_dvd_iff

/-- The sum of `μ d` over `d` with `d² ∣ n`, `d ≤ D`, is the indicator of squarefree `n`,
whenever `n ≤ x` and `D = ⌊√x⌋`. -/
theorem sum_moebius_sq_dvd {n x : ℕ} (hn : 0 < n) (hnx : n ≤ x) :
    ∑ d ∈ Finset.Icc 1 (Nat.sqrt x), (if d ^ 2 ∣ n then μ d else 0) =
      if Squarefree n then 1 else 0 := by
  obtain ⟨a, b, ha, hb, rfl, hsq⟩ := Nat.sq_mul_squarefree_of_pos hn
  rw [← Finset.sum_filter]
  have hset : (Finset.Icc 1 (Nat.sqrt x)).filter (fun d => d ^ 2 ∣ b ^ 2 * a) = b.divisors := by
    ext d
    simp only [Finset.mem_filter, Finset.mem_Icc, Nat.mem_divisors, sqfree_sq_dvd_iff hsq hb]
    constructor
    · rintro ⟨_, h⟩; exact ⟨h, hb.ne'⟩
    · rintro ⟨h, -⟩
      have hd : 0 < d := Nat.pos_of_dvd_of_pos h hb
      have hdb : d ≤ b := Nat.le_of_dvd hb h
      refine ⟨⟨hd, ?_⟩, h⟩
      rw [Nat.le_sqrt']
      calc d ^ 2 ≤ b ^ 2 := Nat.pow_le_pow_left hdb 2
        _ ≤ b ^ 2 * a := Nat.le_mul_of_pos_right _ ha
        _ ≤ x := hnx
  rw [hset]
  have key : ∑ d ∈ b.divisors, μ d = (1 : ArithmeticFunction ℤ) b := by
    rw [← moebius_mul_coe_zeta, coe_mul_zeta_apply]
  rw [key, ArithmeticFunction.one_apply]
  have : Squarefree (b ^ 2 * a) ↔ b = 1 := by
    constructor
    · intro h
      have : IsUnit b := h b (Dvd.dvd.mul_right (by rw [sq]) a)
      exact Nat.isUnit_iff.mp this
    · rintro rfl; simpa using hsq
  by_cases h1 : b = 1
  · simp [h1, hsq]
  · simp [h1, show ¬ Squarefree (b ^ 2 * a) from fun h => h1 (this.mp h)]

#print axioms sum_moebius_sq_dvd

theorem sieve_identity (x : ℕ) :
    ((((Finset.Icc 1 x).filter Squarefree).card : ℕ) : ℤ) =
        ∑ d ∈ Finset.Icc 1 (Nat.sqrt x), μ d * ((x / d ^ 2 : ℕ) : ℤ) := by
  have hI : Finset.Icc 1 x = Finset.Ioc 0 x := by ext; simp; omega
  have h1 : ∀ d, ((x / d ^ 2 : ℕ) : ℤ) = ∑ n ∈ Finset.Icc 1 x, if d ^ 2 ∣ n then (1 : ℤ) else 0 := by
    intro d
    rw [Finset.sum_boole, hI, Nat.Ioc_filter_dvd_card_eq_div]
  simp_rw [h1, Finset.mul_sum, mul_boole]
  rw [Finset.sum_comm]
  rw [Finset.card_filter, Nat.cast_sum]
  apply Finset.sum_congr rfl
  intro n hn
  rw [Finset.mem_Icc] at hn
  rw [sum_moebius_sq_dvd (by omega) hn.2]
  split_ifs <;> simp

#print axioms sieve_identity

theorem hasSum_moebius_div_sq :
    HasSum (fun n : ℕ => (μ n : ℝ) / (n : ℝ) ^ 2) (6 / Real.pi ^ 2) := by
  have hs : (1 : ℝ) < (2 : ℂ).re := by norm_num
  have h1 := LSeries_zeta_mul_Lseries_moebius hs
  rw [LSeries_zeta_eq_riemannZeta hs, riemannZeta_two] at h1
  have hL : LSeries (fun n => (μ n : ℂ)) 2 = ((6 / Real.pi ^ 2 : ℝ) : ℂ) := by
    have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
    push_cast
    field_simp
    linear_combination 6 * h1
  have hsum : LSeriesHasSum (fun n => (μ n : ℂ)) 2 (LSeries (fun n => (μ n : ℂ)) 2) :=
    (LSeriesSummable_moebius_iff.mpr hs).LSeriesHasSum
  rw [hL] at hsum
  unfold LSeriesHasSum at hsum
  rw [← Complex.hasSum_ofReal]
  convert hsum using 1
  funext n
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  · rw [LSeries.term_of_ne_zero hn.ne', Complex.cpow_two]
    push_cast
    rfl

#print axioms hasSum_moebius_div_sq

theorem telescope_bound (D : ℕ) (hD : 1 ≤ D) (m : ℕ) :
    ∑ k ∈ Finset.range m, 1 / ((D + 1 + k : ℕ) : ℝ) ^ 2 ≤ 1 / (D : ℝ) - 1 / ((D + m : ℕ) : ℝ) := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ]
    have hDm : (1 : ℝ) ≤ ((D + m : ℕ) : ℝ) := by exact_mod_cast (by omega : 1 ≤ D + m)
    have step : 1 / ((D + 1 + m : ℕ) : ℝ) ^ 2 ≤ 1 / ((D + m : ℕ) : ℝ) - 1 / ((D + (m + 1) : ℕ) : ℝ) := by
      have e1 : ((D + 1 + m : ℕ) : ℝ) = ((D + m : ℕ) : ℝ) + 1 := by push_cast; ring
      have e2 : ((D + (m + 1) : ℕ) : ℝ) = ((D + m : ℕ) : ℝ) + 1 := by push_cast; ring
      rw [e1, e2]
      set y := ((D + m : ℕ) : ℝ)
      rw [div_sub_div _ _ (by positivity) (by positivity), div_le_div_iff₀ (by positivity) (by positivity)]
      nlinarith
    linarith

#print axioms telescope_bound

theorem tail_bound (D : ℕ) (hD : 1 ≤ D) :
    |6 / Real.pi ^ 2 - ∑ d ∈ Finset.Icc 1 D, (μ d : ℝ) / (d : ℝ) ^ 2| ≤ 1 / (D : ℝ) := by
  set f : ℕ → ℝ := fun n => (μ n : ℝ) / (n : ℝ) ^ 2 with hf
  have hIcc : ∑ d ∈ Finset.Icc 1 D, f d = ∑ d ∈ Finset.range (D + 1), f d := by
    apply Finset.sum_subset
    · intro d hd; simp at hd ⊢; omega
    · intro d hd hnot
      have : d = 0 := by simp at hd hnot; omega
      subst this; simp [hf]
  rw [hIcc]
  have ht := (hasSum_moebius_div_sq.tendsto_sum_nat).comp (tendsto_add_atTop_nat (D + 1))
  have ht2 : Tendsto (fun m => |(∑ i ∈ Finset.range (m + (D + 1)), f i) -
      ∑ d ∈ Finset.range (D + 1), f d|) atTop
      (𝓝 |6 / Real.pi ^ 2 - ∑ d ∈ Finset.range (D + 1), f d|) :=
    ((ht.sub tendsto_const_nhds).abs)
  refine le_of_tendsto ht2 (Eventually.of_forall fun m => ?_)
  rw [add_comm m, Finset.sum_range_add, add_sub_cancel_left]
  calc |∑ k ∈ Finset.range m, f (D + 1 + k)|
      ≤ ∑ k ∈ Finset.range m, |f (D + 1 + k)| := Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ k ∈ Finset.range m, 1 / ((D + 1 + k : ℕ) : ℝ) ^ 2 := by
        apply Finset.sum_le_sum
        intro k _
        rw [hf]
        simp only
        rw [abs_div, abs_of_nonneg (by positivity : (0:ℝ) ≤ ((D + 1 + k : ℕ) : ℝ) ^ 2)]
        apply div_le_div_of_nonneg_right _ (by positivity)
        exact_mod_cast abs_moebius_le_one
    _ ≤ 1 / (D : ℝ) - 1 / ((D + m : ℕ) : ℝ) := telescope_bound D hD m
    _ ≤ 1 / (D : ℝ) := by
        have : (0 : ℝ) ≤ 1 / ((D + m : ℕ) : ℝ) := by positivity
        linarith

#print axioms tail_bound

theorem floor_div_sq_close (x d : ℕ) (hd : 1 ≤ d) :
    |((x / d ^ 2 : ℕ) : ℝ) - (x : ℝ) / (d : ℝ) ^ 2| ≤ 1 := by
  have hd' : (0 : ℝ) < ((d ^ 2 : ℕ) : ℝ) := by
    have : 0 < d ^ 2 := by positivity
    exact_mod_cast this
  have h1 := Nat.floor_le (a := (x : ℝ) / ((d ^ 2 : ℕ) : ℝ)) (by positivity)
  have h2 := Nat.lt_floor_add_one ((x : ℝ) / ((d ^ 2 : ℕ) : ℝ))
  rw [Nat.floor_div_eq_div] at h1 h2
  push_cast at h1 h2
  rw [abs_le]
  constructor <;> linarith

#print axioms floor_div_sq_close

/-- The Mobius sieve and its error. Let Q(x) be the count of squarefree numbers from 1 to x,
and D = ⌊√x⌋. For every whole number x ≥ 1, the signed sum over d up to √x of μ(d) times the
number of multiples of d² up to x counts the squarefree numbers exactly:
Q(x) = ∑_{d ≤ √x} μ(d) ⌊x/d²⌋.
And Q(x) is six over pi squared times x, with an error E(x) no bigger than D + x/D:
|Q(x) − (6/π²) x| ≤ D + x/D. -/
theorem squarefree_count_mobius_sieve_and_error (x : ℕ) (hx : 1 ≤ x) :
    ((((Finset.Icc 1 x).filter Squarefree).card : ℕ) : ℤ) =
        ∑ d ∈ Finset.Icc 1 (Nat.sqrt x), μ d * ((x / d ^ 2 : ℕ) : ℤ) ∧
      |((((Finset.Icc 1 x).filter Squarefree).card : ℕ) : ℝ) - 6 / Real.pi ^ 2 * (x : ℝ)| ≤
        (Nat.sqrt x : ℝ) + (x : ℝ) / (Nat.sqrt x : ℝ) := by
  refine ⟨sieve_identity x, ?_⟩
  set D := Nat.sqrt x with hDdef
  have hD : 1 ≤ D := Nat.sqrt_pos.mpr hx
  have hQ := congrArg (Int.cast : ℤ → ℝ) (sieve_identity x)
  simp only [Int.cast_natCast, Int.cast_sum, Int.cast_mul] at hQ
  rw [← hDdef] at hQ
  rw [hQ]
  set c := 6 / Real.pi ^ 2
  have e : ∀ d : ℕ, (μ d : ℝ) * (((x / d ^ 2 : ℕ) : ℝ) - (x : ℝ) / (d : ℝ) ^ 2) =
      (μ d : ℝ) * ((x / d ^ 2 : ℕ) : ℝ) - (x : ℝ) * ((μ d : ℝ) / (d : ℝ) ^ 2) := fun d => by ring
  have hsplit : ∑ d ∈ Finset.Icc 1 D, (μ d : ℝ) * ((x / d ^ 2 : ℕ) : ℝ) - c * (x : ℝ) =
      ∑ d ∈ Finset.Icc 1 D, (μ d : ℝ) * (((x / d ^ 2 : ℕ) : ℝ) - (x : ℝ) / (d : ℝ) ^ 2) -
        (x : ℝ) * (c - ∑ d ∈ Finset.Icc 1 D, (μ d : ℝ) / (d : ℝ) ^ 2) := by
    rw [Finset.sum_congr rfl (fun d _ => e d), Finset.sum_sub_distrib, ← Finset.mul_sum]
    ring
  rw [hsplit]
  have hA : |∑ d ∈ Finset.Icc 1 D, (μ d : ℝ) * (((x / d ^ 2 : ℕ) : ℝ) - (x : ℝ) / (d : ℝ) ^ 2)|
      ≤ (D : ℝ) := by
    calc _ ≤ ∑ d ∈ Finset.Icc 1 D, |(μ d : ℝ) * (((x / d ^ 2 : ℕ) : ℝ) - (x : ℝ) / (d : ℝ) ^ 2)| :=
          Finset.abs_sum_le_sum_abs _ _
      _ ≤ ∑ d ∈ Finset.Icc 1 D, (1 : ℝ) := by
          apply Finset.sum_le_sum
          intro d hd
          rw [Finset.mem_Icc] at hd
          rw [abs_mul]
          have hm : |(μ d : ℝ)| ≤ 1 := by exact_mod_cast abs_moebius_le_one
          have hf := floor_div_sq_close x d hd.1
          calc |(μ d : ℝ)| * _ ≤ 1 * 1 :=
                mul_le_mul hm hf (abs_nonneg _) zero_le_one
            _ = 1 := one_mul 1
      _ = (D : ℝ) := by simp
  have hB : |c - ∑ d ∈ Finset.Icc 1 D, (μ d : ℝ) / (d : ℝ) ^ 2| ≤ 1 / (D : ℝ) := tail_bound D hD
  have hx0 : (0 : ℝ) ≤ (x : ℝ) := by positivity
  calc _ ≤ |∑ d ∈ Finset.Icc 1 D, (μ d : ℝ) * (((x / d ^ 2 : ℕ) : ℝ) - (x : ℝ) / (d : ℝ) ^ 2)| +
        |(x : ℝ) * (c - ∑ d ∈ Finset.Icc 1 D, (μ d : ℝ) / (d : ℝ) ^ 2)| := abs_sub _ _
    _ ≤ (D : ℝ) + (x : ℝ) * (1 / (D : ℝ)) := by
        rw [abs_mul, abs_of_nonneg hx0]
        gcongr
    _ = (D : ℝ) + (x : ℝ) / (D : ℝ) := by ring

#print axioms squarefree_count_mobius_sieve_and_error

/-- The error is O(√x) with the constant written out: for every whole number x ≥ 1, the count
Q(x) of squarefree numbers from 1 to x is within three square roots of x of (6/π²) x. -/
theorem squarefree_count_error_le_three_sqrt (x : ℕ) (hx : 1 ≤ x) :
    |((((Finset.Icc 1 x).filter Squarefree).card : ℕ) : ℝ) - 6 / Real.pi ^ 2 * (x : ℝ)| ≤
      3 * Real.sqrt (x : ℝ) := by
  refine (squarefree_count_mobius_sieve_and_error x hx).2.trans ?_
  have hD1 : (1 : ℝ) ≤ (Nat.sqrt x : ℝ) := by exact_mod_cast Nat.sqrt_pos.mpr hx
  have hle : (Nat.sqrt x : ℝ) ≤ Real.sqrt x := Real.nat_sqrt_le_real_sqrt
  have hlt : Real.sqrt x < (Nat.sqrt x : ℝ) + 1 := Real.real_sqrt_lt_nat_sqrt_succ
  have hs0 : 0 ≤ Real.sqrt x := Real.sqrt_nonneg _
  have hsq : Real.sqrt x ^ 2 = (x : ℝ) := Real.sq_sqrt (by positivity)
  have h2 : (x : ℝ) / (Nat.sqrt x : ℝ) ≤ 2 * Real.sqrt x := by
    rw [div_le_iff₀ (by linarith)]
    nlinarith
  linarith

#print axioms squarefree_count_error_le_three_sqrt

/-- The squarefree numbers have natural density 6/π²: the share Q(x)/x of the numbers
1, 2, …, x that are squarefree tends to six over pi squared as x grows without end. -/
theorem squarefree_natural_density :
    Tendsto (fun x : ℕ => ((((Finset.Icc 1 x).filter Squarefree).card : ℕ) : ℝ) / (x : ℝ))
      atTop (𝓝 (6 / Real.pi ^ 2)) := by
  rw [tendsto_iff_norm_sub_tendsto_zero]
  have hlim : Tendsto (fun x : ℕ => 3 / Real.sqrt (x : ℝ)) atTop (𝓝 0) :=
    tendsto_const_nhds.div_atTop (Real.tendsto_sqrt_atTop.comp tendsto_natCast_atTop_atTop)
  refine squeeze_zero' (Eventually.of_forall fun _ => norm_nonneg _) ?_ hlim
  filter_upwards [eventually_ge_atTop 1] with x hx
  have hE := squarefree_count_error_le_three_sqrt x hx
  have hxpos : (0 : ℝ) < (x : ℝ) := by exact_mod_cast hx
  have hs : 0 < Real.sqrt (x : ℝ) := Real.sqrt_pos.mpr hxpos
  have hsq : Real.sqrt x ^ 2 = (x : ℝ) := Real.sq_sqrt hxpos.le
  set Q := ((((Finset.Icc 1 x).filter Squarefree).card : ℕ) : ℝ)
  have e : Q / (x : ℝ) - 6 / Real.pi ^ 2 = (Q - 6 / Real.pi ^ 2 * (x : ℝ)) / (x : ℝ) := by
    field_simp
  rw [Real.norm_eq_abs, e, abs_div, abs_of_pos hxpos, div_le_div_iff₀ hxpos hs]
  nlinarith [abs_nonneg (Q - 6 / Real.pi ^ 2 * (x : ℝ))]

#print axioms squarefree_natural_density

-- 608 of the numbers 1 to 1,000 are squarefree.
example : ((Finset.Icc 1 1000).filter Squarefree).card = 608 := by decide +kernel

-- The Mobius sieve at 1,000: D = 31, and the signed sum over d ≤ 31 gives the same 608.
example : Nat.sqrt 1000 = 31 := by decide +kernel
example : ∑ d ∈ Finset.Icc 1 (Nat.sqrt 1000), μ d * ((1000 / d ^ 2 : ℕ) : ℤ) = 608 := by decide +kernel

-- The ten blocks of 100 up to 1,000 hold 61, 61, 61, 60, 63, 60, 62, 61, 58, 61.
example : (List.range 10).map (fun k => ((Finset.Icc (100 * k + 1) (100 * k + 100)).filter
    Squarefree).card) = [61, 61, 61, 60, 63, 60, 62, 61, 58, 61] := by decide +kernel

-- Worked numbers: the prime squares strike 442 (leaving 558); two-prime squares add back 51;
-- 30² strikes 1 more.
example : ∑ p ∈ (Finset.Icc 2 31).filter Nat.Prime, 1000 / p ^ 2 = 442 := by decide +kernel
example : 1000 - 442 + 51 - 1 = 608 := by decide +kernel

-- The mistake with no signs: striking every square's multiples once each leaves 399.
example : 1000 - ∑ d ∈ Finset.Icc 2 31, 1000 / d ^ 2 = 399 := by decide +kernel

-- The house number: 720720 = 12² × 5005, with 5005 squarefree and 720720 not.
example : 720720 = 12 ^ 2 * 5005 ∧ Squarefree 5005 ∧ ¬ Squarefree 720720 := by decide +kernel

-- Short windows: 48 to 50 and 242 to 245 hold no squarefree number.
example : ∀ n ∈ Finset.Icc 48 50, ¬ Squarefree n := by decide +kernel
example : ∀ n ∈ Finset.Icc 242 245, ¬ Squarefree n := by decide +kernel

-- Liouville's sign λ(n) = (−1)^Ω(n): λ(12) = −1 while μ(12) = 0; λ(720720) = +1, μ(720720) = 0.
example : (-1 : ℤ) ^ Ω 12 = -1 ∧ μ 12 = 0 := by decide +kernel
example : (-1 : ℤ) ^ Ω 720720 = 1 ∧ μ 720720 = 0 := by decide +kernel
