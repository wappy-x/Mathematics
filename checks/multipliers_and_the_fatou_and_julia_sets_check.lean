-- Attracting and repelling cycles: for the rule z ↦ z² + c, a cycle whose multiplier (the slope of the rule repeated round the cycle) is smaller than 1 in size pulls nearby starts in and one larger than 1 pushes them out, the multiplier is 2^k times the product of the cycle's points and is the same from every point of the cycle, and it is 0 exactly when the critical point 0 lies on the cycle.
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecificLimits.Basic

/-! Setting, in the card's notation.
* The rule is `f z = z ^ 2 + c` on the complex numbers, written `fun z : ℂ => z ^ 2 + c`.
* `f^[n]` is `f` applied `n` times (Mathlib's `Nat.iterate`), not a power.
* A cycle of period `k` through `z₀` is `f^[k] z₀ = z₀`; its points are `zⱼ = f^[j] z₀`.
* The multiplier is the slope of `f^[k]` at `z₀`: `λ = deriv (f^[k]) z₀`.
* "Attracts" means every start near `z₀` has its `f^[k]`-orbit converge to `z₀`; "repels"
  means every start other than `z₀` itself is pushed out of a fixed disc round `z₀`.

Not stated here: the Fatou and Julia sets are defined by normal families that may run off to
infinity, which Mathlib does not define, and the theorem that every attracting cycle pulls in
the orbit of 0 needs inverse branches beyond what Mathlib has. Its super-attracting case
(multiplier 0 puts 0 on the cycle) is the second half of `multiplier_eq_two_pow_mul_prod`. -/

open Filter Topology

namespace MultipliersAndTheFatouAndJuliaSets

/-- Chain rule along the orbit: the slope of `f^[k]` at `z` is `2^k` times the product of the
first `k` points of the orbit of `z`. -/
theorem hasDerivAt_iterate_sq_add (c : ℂ) (k : ℕ) (z : ℂ) :
    HasDerivAt ((fun z : ℂ => z ^ 2 + c)^[k])
      (2 ^ k * ∏ j ∈ Finset.range k, (fun z : ℂ => z ^ 2 + c)^[j] z) z := by
  induction k with
  | zero => simpa using hasDerivAt_id z
  | succ k ih =>
    have hf : HasDerivAt (fun z : ℂ => z ^ 2 + c) (2 * (fun z : ℂ => z ^ 2 + c)^[k] z)
        ((fun z : ℂ => z ^ 2 + c)^[k] z) := by
      have := (hasDerivAt_pow 2 ((fun z : ℂ => z ^ 2 + c)^[k] z)).add_const c
      have e : ((2 : ℕ) : ℂ) * ((fun z : ℂ => z ^ 2 + c)^[k] z) ^ (2 - 1) =
          2 * (fun z : ℂ => z ^ 2 + c)^[k] z := by norm_num
      rw [e] at this
      exact this
    rw [Function.iterate_succ']
    convert hf.comp z ih using 1
    rw [Finset.prod_range_succ, pow_succ]
    ring

/-- Products of a `k`-periodic sequence over any `k` consecutive places agree. -/
theorem prod_shift_of_periodic (a : ℕ → ℂ) (k : ℕ) (ha : ∀ m, a (k + m) = a m) (m : ℕ) :
    ∏ j ∈ Finset.range k, a (j + m) = ∏ j ∈ Finset.range k, a j := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [← ih]
    cases k with
    | zero => simp
    | succ k =>
      rw [Finset.prod_range_succ, Finset.prod_range_succ' (fun j => a (j + m))]
      have h1 : k + (m + 1) = (k + 1) + m := by ring
      have h2 : ∀ j, j + (m + 1) = j + 1 + m := fun j => by ring
      rw [h1, ha m, zero_add]
      simp only [h2]

/-- **The multiplier decides.** Let `z₀` be a point of a cycle of period `k` of
`f(z) = z² + c`, so `f^[k] z₀ = z₀`, and let `λ` be the slope of `f^[k]` at `z₀`. If `λ` is
smaller than 1 in size, there is a disc round `z₀` from which every start has its
`f^[k]`-orbit converge to `z₀` (the cycle attracts). If `λ` is larger than 1 in size, there is
a disc of radius `δ > 0` round `z₀` that the `f^[k]`-orbit of every other start eventually
leaves (the cycle repels). -/
theorem cycle_attracts_or_repels_by_multiplier (c z₀ : ℂ) (k : ℕ)
    (hcycle : (fun z : ℂ => z ^ 2 + c)^[k] z₀ = z₀) :
    (‖deriv ((fun z : ℂ => z ^ 2 + c)^[k]) z₀‖ < 1 →
      ∃ δ > 0, ∀ z : ℂ, ‖z - z₀‖ < δ →
        Tendsto (fun n : ℕ => ((fun z : ℂ => z ^ 2 + c)^[k])^[n] z) atTop (𝓝 z₀)) ∧
    (1 < ‖deriv ((fun z : ℂ => z ^ 2 + c)^[k]) z₀‖ →
      ∃ δ > 0, ∀ z : ℂ, z ≠ z₀ →
        ∃ n : ℕ, δ < ‖((fun z : ℂ => z ^ 2 + c)^[k])^[n] z - z₀‖) := by
  set g := (fun z : ℂ => z ^ 2 + c)^[k] with hgdef
  set L := deriv g z₀ with hL
  have hd : HasDerivAt g L z₀ := (hasDerivAt_iterate_sq_add c k z₀).differentiableAt.hasDerivAt
  have ho := hasDerivAt_iff_isLittleO.mp hd
  -- local linear estimate
  have key : ∀ ε > 0, ∃ r > 0, ∀ w : ℂ, ‖w - z₀‖ < r →
      ‖(g w - z₀) - (w - z₀) * L‖ ≤ ε * ‖w - z₀‖ := by
    intro ε hε
    have := ho.def hε
    obtain ⟨r, hr, hball⟩ := Metric.eventually_nhds_iff.mp this
    refine ⟨r, hr, fun w hw => ?_⟩
    have := hball (by rwa [dist_eq_norm])
    simpa [hcycle, smul_eq_mul] using this
  constructor
  · intro hlt
    obtain ⟨r, hr, hb⟩ := key ((1 - ‖L‖) / 2) (by linarith)
    set μ := ‖L‖ + (1 - ‖L‖) / 2 with hμ
    have hμ0 : 0 ≤ μ := by have := norm_nonneg L; linarith
    have hμ1 : μ < 1 := by linarith
    have step : ∀ w : ℂ, ‖w - z₀‖ < r → ‖g w - z₀‖ ≤ μ * ‖w - z₀‖ := by
      intro w hw
      have h1 := hb w hw
      have h2 : g w - z₀ = (w - z₀) * L + ((g w - z₀) - (w - z₀) * L) := by ring
      have h3 := norm_add_le ((w - z₀) * L) ((g w - z₀) - (w - z₀) * L)
      rw [← h2, norm_mul] at h3
      rw [hμ]; nlinarith [norm_nonneg (w - z₀)]
    refine ⟨r, hr, fun z hz => ?_⟩
    have bound : ∀ n : ℕ, ‖g^[n] z - z₀‖ ≤ μ ^ n * ‖z - z₀‖ := by
      intro n
      induction n with
      | zero => simp
      | succ n ih =>
        rw [Function.iterate_succ_apply']
        have hpow : μ ^ n ≤ 1 := pow_le_one₀ hμ0 hμ1.le
        have hin : ‖g^[n] z - z₀‖ < r := by
          calc ‖g^[n] z - z₀‖ ≤ μ ^ n * ‖z - z₀‖ := ih
            _ ≤ 1 * ‖z - z₀‖ := by gcongr
            _ < r := by linarith
        calc ‖g (g^[n] z) - z₀‖ ≤ μ * ‖g^[n] z - z₀‖ := step _ hin
          _ ≤ μ * (μ ^ n * ‖z - z₀‖) := by gcongr
          _ = μ ^ (n + 1) * ‖z - z₀‖ := by ring
    rw [tendsto_iff_norm_sub_tendsto_zero]
    have hlim : Tendsto (fun n : ℕ => μ ^ n * ‖z - z₀‖) atTop (𝓝 0) := by
      simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hμ0 hμ1).mul_const ‖z - z₀‖
    exact squeeze_zero (fun n => norm_nonneg _) bound hlim
  · intro hgt
    obtain ⟨r, hr, hb⟩ := key ((‖L‖ - 1) / 2) (by linarith)
    set μ := ‖L‖ - (‖L‖ - 1) / 2 with hμ
    have hμ1 : 1 < μ := by linarith
    have step : ∀ w : ℂ, ‖w - z₀‖ < r → μ * ‖w - z₀‖ ≤ ‖g w - z₀‖ := by
      intro w hw
      have h1 := hb w hw
      have h2 : (w - z₀) * L = (g w - z₀) - ((g w - z₀) - (w - z₀) * L) := by ring
      have h3 := norm_sub_le (g w - z₀) ((g w - z₀) - (w - z₀) * L)
      rw [← h2, norm_mul] at h3
      rw [hμ]; nlinarith [norm_nonneg (w - z₀)]
    refine ⟨r / 2, by linarith, fun z hz => ?_⟩
    by_contra hcon
    push Not at hcon
    have hpos : 0 < ‖z - z₀‖ := norm_pos_iff.mpr (sub_ne_zero.mpr hz)
    have bound : ∀ n : ℕ, μ ^ n * ‖z - z₀‖ ≤ ‖g^[n] z - z₀‖ := by
      intro n
      induction n with
      | zero => simp
      | succ n ih =>
        rw [Function.iterate_succ_apply']
        have hin : ‖g^[n] z - z₀‖ < r := by linarith [hcon n]
        calc μ ^ (n + 1) * ‖z - z₀‖ = μ * (μ ^ n * ‖z - z₀‖) := by ring
          _ ≤ μ * ‖g^[n] z - z₀‖ := by gcongr
          _ ≤ ‖g (g^[n] z) - z₀‖ := step _ hin
    obtain ⟨n, hn⟩ := ((tendsto_pow_atTop_atTop_of_one_lt hμ1).eventually_gt_atTop
      ((r / 2) / ‖z - z₀‖)).exists
    have : r / 2 < μ ^ n * ‖z - z₀‖ := by
      rw [div_lt_iff₀ hpos] at hn; exact hn
    linarith [bound n, hcon n]

/-- **The multiplier is a product round the cycle.** By the chain rule, the slope of `f^[k]` at
`z₀` is the product of the slopes `f'(zⱼ) = 2 zⱼ` along the orbit, that is `2^k` times the
product of the points `z₀, z₁, …, z_{k-1}`. In particular it is 0 exactly when one of those
points is the critical point 0: a super-attracting cycle passes through 0. -/
theorem multiplier_eq_two_pow_mul_prod (c z₀ : ℂ) (k : ℕ) :
    deriv ((fun z : ℂ => z ^ 2 + c)^[k]) z₀ =
        2 ^ k * ∏ j ∈ Finset.range k, (fun z : ℂ => z ^ 2 + c)^[j] z₀ ∧
    (deriv ((fun z : ℂ => z ^ 2 + c)^[k]) z₀ = 0 ↔
        ∃ j < k, (fun z : ℂ => z ^ 2 + c)^[j] z₀ = 0) := by
  have hd := (hasDerivAt_iterate_sq_add c k z₀).deriv
  refine ⟨hd, ?_⟩
  rw [hd, mul_eq_zero, Finset.prod_eq_zero_iff]
  simp

/-- **The multiplier belongs to the whole cycle.** If `f^[k] z₀ = z₀`, then the slope of
`f^[k]` is the same at every point `zⱼ = f^[j] z₀` of the cycle as at `z₀`. -/
theorem multiplier_same_round_cycle (c z₀ : ℂ) (k j : ℕ)
    (hcycle : (fun z : ℂ => z ^ 2 + c)^[k] z₀ = z₀) :
    deriv ((fun z : ℂ => z ^ 2 + c)^[k]) ((fun z : ℂ => z ^ 2 + c)^[j] z₀) =
      deriv ((fun z : ℂ => z ^ 2 + c)^[k]) z₀ := by
  rw [(hasDerivAt_iterate_sq_add c k _).deriv, (hasDerivAt_iterate_sq_add c k _).deriv]
  congr 1
  have hrw : ∀ i : ℕ, (fun z : ℂ => z ^ 2 + c)^[i] ((fun z : ℂ => z ^ 2 + c)^[j] z₀) =
      (fun z : ℂ => z ^ 2 + c)^[i + j] z₀ := fun i => (Function.iterate_add_apply _ _ _ _).symm
  simp only [hrw]
  apply prod_shift_of_periodic (fun i => (fun z : ℂ => z ^ 2 + c)^[i] z₀)
  intro m
  show (fun z : ℂ => z ^ 2 + c)^[k + m] z₀ = (fun z : ℂ => z ^ 2 + c)^[m] z₀
  rw [add_comm, Function.iterate_add_apply, hcycle]

/-! The card's worked numbers for `c = -1`, exactly. -/

-- The orbit of 0 under z² − 1: 0 goes to −1 and back, a cycle of period 2.
example : (fun z : ℤ => z ^ 2 - 1) 0 = -1 ∧ (fun z : ℤ => z ^ 2 - 1) (-1) = 0 := by norm_num

-- The orbit of 2 runs off: 2, 3, 8, 63, 3968.
example : (fun z : ℤ => z ^ 2 - 1)^[1] 2 = 3 ∧ (fun z : ℤ => z ^ 2 - 1)^[2] 2 = 8 ∧
    (fun z : ℤ => z ^ 2 - 1)^[3] 2 = 63 ∧ (fun z : ℤ => z ^ 2 - 1)^[4] 2 = 3968 := by
  decide

-- The multiplier of the cycle 0, −1 is f'(0) f'(−1) = 0 × (−2) = 0: super-attracting.
example : (2 * 0 : ℤ) * (2 * (-1)) = 0 := by norm_num

-- One point's slope misleads: f'(−1) = −2 is larger than 1 in size.
example : |(2 * (-1) : ℤ)| = 2 := by norm_num

-- The fixed points (1 ± √5)/2 of z² − 1, with multipliers 2p = 1 ± √5.
example : ((1 + Real.sqrt 5) / 2) ^ 2 - 1 = (1 + Real.sqrt 5) / 2 ∧
    ((1 - Real.sqrt 5) / 2) ^ 2 - 1 = (1 - Real.sqrt 5) / 2 := by
  constructor <;> ring_nf <;> norm_num <;> ring

-- Both multipliers are larger than 1 in size, so both fixed points repel.
example : 1 < |2 * ((1 + Real.sqrt 5) / 2)| ∧ 1 < |2 * ((1 - Real.sqrt 5) / 2)| := by
  have h : (2 : ℝ) < Real.sqrt 5 := by
    rw [show (2 : ℝ) = Real.sqrt 4 by rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]]
    exact Real.sqrt_lt_sqrt (by norm_num) (by norm_num)
  constructor
  · rw [abs_of_pos (by positivity)]; linarith
  · rw [abs_of_neg (by linarith)]; linarith

-- Two steps round the cycle from a gap h: f²(h) = (h² − 1)² − 1 = h⁴ − 2h², so the gap is squared.
example (h : ℂ) : (h ^ 2 - 1) ^ 2 - 1 = h ^ 4 - 2 * h ^ 2 := by ring

-- Step 0: near a fixed point p (p² + c = p) one step sends p + h to p + 2p·h + h², exactly.
example (c p h : ℂ) (hp : p ^ 2 + c = p) : (p + h) ^ 2 + c = p + 2 * p * h + h ^ 2 := by
  linear_combination hp

#print axioms hasDerivAt_iterate_sq_add
#print axioms prod_shift_of_periodic
#print axioms cycle_attracts_or_repels_by_multiplier
#print axioms multiplier_eq_two_pow_mul_prod
#print axioms multiplier_same_round_cycle

end MultipliersAndTheFatouAndJuliaSets
