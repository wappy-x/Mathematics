-- Cointegration: only the true tying ratio turns a random walk and its tied partner into a mix of bounded variance, pulls on yesterday's gap make the gap follow an autoregression with carry-over 1 + αN - β αS, and a one-off gap is split between the two stations in the ratio of their pulls.
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Finset

/-- The tying ratio is unique. South is a random walk: `S t = S₀ + η 0 + … + η (t-1)`, with
independent daily changes `η i` of the same variance `v > 0`. North is tied to it:
`N t = c + β S t + z t`, where the leftover `z t` has a fixed variance `w` and is independent of
South's wander. Then for a trial ratio `b`, the variance of the mix `N t - b S t` (which is
`(β - b)² t v + w`) stays bounded over all days `t` exactly when `b = β`: any other ratio leaves
a mix that wanders without limit. -/
theorem tying_ratio_unique {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (η z : ℕ → Ω → ℝ) (S₀ c β b v w : ℝ)
    (hη : ∀ i, MemLp (η i) 2 μ) (hηind : iIndepFun η μ)
    (hv : ∀ i, variance (η i) μ = v) (hvpos : 0 < v)
    (hz : ∀ t, MemLp (z t) 2 μ) (hw : ∀ t, variance (z t) μ = w)
    (hzS : ∀ t, IndepFun (z t) (fun ω => ∑ i ∈ range t, η i ω) μ) :
    BddAbove (Set.range fun t : ℕ =>
        variance (fun ω => (c + β * (S₀ + ∑ i ∈ range t, η i ω) + z t ω)
          - b * (S₀ + ∑ i ∈ range t, η i ω)) μ) ↔ b = β := by
  set T : ℕ → Ω → ℝ := fun t ω => ∑ i ∈ range t, η i ω with hT
  have hTmem : ∀ t, MemLp (T t) 2 μ := fun t => memLp_finsetSum _ (fun i _ => hη i)
  have hTvar : ∀ t, variance (T t) μ = t * v := by
    intro t
    have h1 : T t = ∑ i ∈ range t, η i := by
      ext ω; simp [hT, Finset.sum_apply]
    rw [h1, IndepFun.variance_sum (fun i _ => hη i)
      (fun i _ j _ hij => hηind.indepFun hij)]
    simp [hv]
  have hvar : ∀ t, variance (fun ω => (c + β * (S₀ + ∑ i ∈ range t, η i ω) + z t ω)
          - b * (S₀ + ∑ i ∈ range t, η i ω)) μ = (β - b) ^ 2 * (t * v) + w := by
    intro t
    have hf : (fun ω => (c + β * (S₀ + ∑ i ∈ range t, η i ω) + z t ω)
          - b * (S₀ + ∑ i ∈ range t, η i ω))
        = fun ω => ((fun ω => (β - b) * T t ω) + z t) ω + (c + (β - b) * S₀) := by
      ext ω; simp only [hT, Pi.add_apply]; ring
    have hA : MemLp (fun ω => (β - b) * T t ω) 2 μ := (hTmem t).const_mul _
    have hind : IndepFun (fun ω => (β - b) * T t ω) (z t) μ := by
      have h2 : IndepFun (T t) (z t) μ := (hzS t).symm
      exact h2.comp (φ := fun x => (β - b) * x) (ψ := id) (by fun_prop) measurable_id
    rw [hf, variance_add_const (hA.add (hz t)).aestronglyMeasurable,
      hind.variance_add hA (hz t), variance_const_mul, hTvar, hw]
  simp_rw [hvar]
  constructor
  · intro hbdd
    by_contra hne
    have hk : 0 < (β - b) ^ 2 * v := by
      have : β - b ≠ 0 := sub_ne_zero.mpr (Ne.symm hne)
      positivity
    obtain ⟨M, hM⟩ := hbdd
    obtain ⟨n, hn⟩ := exists_nat_gt ((M - w) / ((β - b) ^ 2 * v))
    have := hM ⟨n, rfl⟩
    simp only at this
    rw [div_lt_iff₀ hk] at hn
    nlinarith
  · rintro rfl
    refine ⟨w, ?_⟩
    rintro _ ⟨t, rfl⟩
    simp

/-- Pulls on yesterday's gap make the gap an autoregression of order one. If each day North's
price changes by `αN` times yesterday's gap plus news, and South's by `αS` times yesterday's gap
plus news, where the gap is `z t = N t - c - β S t`, then every day
`z (t+1) = φ z t + u (t+1)` with carry-over `φ = 1 + αN - β αS` and combined news
`u (t+1) = εN (t+1) - β εS (t+1)`. -/
theorem error_correction_gap_is_ar1 (N S εN εS : ℕ → ℝ) (c β αN αS : ℝ)
    (hN : ∀ t, N (t + 1) - N t = αN * (N t - c - β * S t) + εN (t + 1))
    (hS : ∀ t, S (t + 1) - S t = αS * (N t - c - β * S t) + εS (t + 1)) :
    ∀ t, N (t + 1) - c - β * S (t + 1)
      = (1 + αN - β * αS) * (N t - c - β * S t) + (εN (t + 1) - β * εS (t + 1)) := by
  intro t
  linear_combination hN t - β * hS t

/-- How a one-off gap is closed (tie ratio 1, no news after the jump). The gap starts at `g₀`
and each day shrinks to `φ = 1 + αN - αS` times itself, with `-1 < φ < 1`. North moves by `αN`
times each day's gap and South by `αS` times it. Summed over every day, North moves
`αN g₀ / (αS - αN)` in all and South `αS g₀ / (αS - αN)`. -/
theorem shock_split_by_pulls (αN αS g₀ : ℝ) (g : ℕ → ℝ)
    (hg0 : g 0 = g₀) (hg : ∀ t, g (t + 1) = (1 + αN - αS) * g t)
    (hφ : |1 + αN - αS| < 1) :
    HasSum (fun t => αN * g t) (αN * g₀ / (αS - αN)) ∧
      HasSum (fun t => αS * g t) (αS * g₀ / (αS - αN)) := by
  have hne : αS - αN ≠ 0 := by
    intro h
    have : 1 + αN - αS = 1 := by linarith
    rw [this] at hφ
    simp at hφ
  have hgt : ∀ t, g t = (1 + αN - αS) ^ t * g₀ := by
    intro t
    induction t with
    | zero => simp [hg0]
    | succ n ih => rw [hg, ih, pow_succ]; ring
  have hgeo := hasSum_geometric_of_abs_lt_one hφ
  have h1 : (1 - (1 + αN - αS))⁻¹ = (αS - αN)⁻¹ := by ring_nf
  rw [h1] at hgeo
  constructor
  · have := hgeo.mul_left (αN * g₀)
    convert this using 1
    · ext t; rw [hgt]; ring
    · field_simp
  · have := hgeo.mul_left (αS * g₀)
    convert this using 1
    · ext t; rw [hgt]; ring
    · field_simp

/-! The card's whole-number and exact worked numbers. -/

-- The week by hand, in cents: leftover 4, 3, 1, 2, 0, -1, 0.
-- Sum of yesterday's gap times today's change is -14; sum of yesterday's gap squared is 31.
example :
    let toy : Fin 7 → ℤ := ![4, 3, 1, 2, 0, -1, 0]
    (∑ i : Fin 6, toy i.castSucc * (toy i.succ - toy i.castSucc)) = -14 ∧
      (∑ i : Fin 6, toy i.castSucc ^ 2) = 31 := by
  decide

-- The week's fitted pull-back is -14 / 31.
example :
    let toy : Fin 7 → ℚ := ![4, 3, 1, 2, 0, -1, 0]
    (∑ i : Fin 6, toy i.castSucc * (toy i.succ - toy i.castSucc)) /
      (∑ i : Fin 6, toy i.castSucc ^ 2) = -14 / 31 := by
  norm_num [Fin.sum_univ_succ]

-- The build: αN = -0.12, αS = 0.03, β = 1, so φ = 1 - 0.12 - 0.03 = 0.85.
example : (1 + (-12 / 100) - 1 * (3 / 100) : ℚ) = 85 / 100 := by norm_num

-- A 10-cent jump: day 0 moves North -1.20 and South +0.30; the gap on day 1 is 8.50.
example : (-12 / 100 : ℚ) * 10 = -6 / 5 ∧ (3 / 100 : ℚ) * 10 = 3 / 10 ∧
    (85 / 100 : ℚ) * 10 = 17 / 2 := by norm_num

-- Summed over every day: North gives back 8 cents, South rises 2, so both end 2 cents dearer.
example : (-12 / 100 : ℚ) * 10 / (3 / 100 - (-12 / 100)) = -8 ∧
    (3 / 100 : ℚ) * 10 / (3 / 100 - (-12 / 100)) = 2 ∧ (10 : ℚ) + (-8) = 2 := by norm_num

#print axioms tying_ratio_unique
#print axioms error_correction_gap_is_ar1
#print axioms shock_split_by_pulls
