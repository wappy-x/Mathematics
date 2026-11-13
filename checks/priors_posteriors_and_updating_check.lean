-- Bayesian updating: for a coin with h heads in n flips and a prior proportional to (θ(1-θ))^c, the posterior (prior times binomial likelihood, divided by the evidence) has area 1 and mean (c+h+1)/(2c+n+2), because the area under θ^a(1-θ)^b is a! b!/(a+b+1)!, and the flat and sceptic means differ by 10(2h-n)/((n+2)(n+22)).
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum

open intervalIntegral

lemma betaInt_succ (a b : ℕ) :
    ∫ θ in (0 : ℝ)..1, θ ^ a * (1 - θ) ^ (b + 1) =
      (∫ θ in (0 : ℝ)..1, θ ^ a * (1 - θ) ^ b) - ∫ θ in (0 : ℝ)..1, θ ^ (a + 1) * (1 - θ) ^ b := by
  rw [← integral_sub (Continuous.intervalIntegrable (by fun_prop) _ _)
    (Continuous.intervalIntegrable (by fun_prop) _ _)]
  congr 1; funext θ; ring

lemma betaInt (a b : ℕ) :
    ∫ θ in (0 : ℝ)..1, θ ^ a * (1 - θ) ^ b =
      ((Nat.factorial a * Nat.factorial b : ℕ) : ℝ) / (Nat.factorial (a + b + 1) : ℝ) := by
  induction b generalizing a with
  | zero =>
    simp only [pow_zero, mul_one, integral_pow, Nat.factorial_zero, add_zero, Nat.factorial_succ]
    push_cast
    field_simp
    simp
  | succ b ih =>
    rw [betaInt_succ, ih a, ih (a + 1), show a + 1 + b + 1 = a + b + 1 + 1 by omega,
      show a + (b + 1) + 1 = a + b + 1 + 1 by omega]
    rw [Nat.factorial_succ (a + b + 1), Nat.factorial_succ a, Nat.factorial_succ b]
    have h1 : ((a + b + 1).factorial : ℝ) ≠ 0 := by positivity
    push_cast
    field_simp
    ring

#print axioms betaInt_succ
#print axioms betaInt

/-- Bayesian updating for a coin. The bias θ runs over 0 to 1. Take the prior density
`f θ = (θ(1-θ))^c / ∫₀¹ (u(1-u))^c du` (the flat prior is `c = 0`, the sceptic `c = 10`), the
binomial likelihood of `h` heads and `t` tails, `L θ = C(h+t, h) θ^h (1-θ)^t`, the evidence
`P(D) = ∫₀¹ L(u) f(u) du`, and the posterior `L θ · f θ / P(D)`. Then the prior is a real
probability law (area 1), the data are possible (`P(D) > 0`), the posterior has area 1, and the
posterior mean is `(c + h + 1) / (2c + n + 2)` with `n = h + t`. -/
theorem bayesian_update_posterior_mean (c h t : ℕ) :
    let f : ℝ → ℝ := fun θ => (θ * (1 - θ)) ^ c / ∫ u in (0 : ℝ)..1, (u * (1 - u)) ^ c
    let L : ℝ → ℝ := fun θ => (Nat.choose (h + t) h : ℝ) * θ ^ h * (1 - θ) ^ t
    let PD : ℝ := ∫ u in (0 : ℝ)..1, L u * f u
    let post : ℝ → ℝ := fun θ => L θ * f θ / PD
    (∫ θ in (0 : ℝ)..1, f θ) = 1 ∧ 0 < PD ∧ (∫ θ in (0 : ℝ)..1, post θ) = 1 ∧
      (∫ θ in (0 : ℝ)..1, θ * post θ) =
        ((c + h + 1 : ℕ) : ℝ) / ((2 * c + (h + t) + 2 : ℕ) : ℝ) := by
  intro f L PD post
  set Z : ℝ := ∫ u in (0 : ℝ)..1, (u * (1 - u)) ^ c with hZ
  set C : ℝ := (Nat.choose (h + t) h : ℝ) with hC
  have hZpos : 0 < Z := by
    have : (fun u : ℝ => (u * (1 - u)) ^ c) = fun u => u ^ c * (1 - u) ^ c := by
      funext u; rw [mul_pow]
    rw [hZ, this, betaInt]; positivity
  have hCpos : 0 < C := by
    rw [hC]; exact_mod_cast Nat.choose_pos (Nat.le_add_right h t)
  have hf : ∫ θ in (0 : ℝ)..1, f θ = 1 := by
    simp only [f]; rw [integral_div, ← hZ]; exact div_self hZpos.ne'
  have hLf : ∀ θ, L θ * f θ = (C / Z) * (θ ^ (c + h) * (1 - θ) ^ (c + t)) := by
    intro θ; simp only [L, f]; rw [← hZ, ← hC, mul_pow]; ring
  have hPD : PD = C / Z * ∫ θ in (0 : ℝ)..1, θ ^ (c + h) * (1 - θ) ^ (c + t) := by
    simp only [PD]; simp_rw [hLf]; rw [integral_const_mul]
  have hPDpos : 0 < PD := by
    rw [hPD, betaInt]; positivity
  refine ⟨hf, hPDpos, ?_, ?_⟩
  · simp only [post]; rw [integral_div]; exact div_self hPDpos.ne'
  · have hp : ∀ θ, θ * post θ = (C / Z / PD) * (θ ^ (c + h + 1) * (1 - θ) ^ (c + t)) := by
      intro θ; simp only [post]; rw [hLf]; ring
    simp_rw [hp]
    rw [integral_const_mul, hPD, betaInt, betaInt,
      show c + h + 1 + (c + t) + 1 = c + h + (c + t) + 1 + 1 by omega,
      show 2 * c + (h + t) + 2 = c + h + (c + t) + 1 + 1 by omega,
      Nat.factorial_succ (c + h + (c + t) + 1), Nat.factorial_succ (c + h)]
    have h1 : ((c + h + (c + t) + 1).factorial : ℝ) ≠ 0 := by positivity
    have h2 : ((c + h).factorial : ℝ) ≠ 0 := by positivity
    have h3 : ((c + t).factorial : ℝ) ≠ 0 := by positivity
    push_cast
    field_simp

/-- The exact area (Claim 1): for whole numbers `a, b ≥ 0`, the area under `θ^a (1-θ)^b` from
0 to 1 is `a! b! / (a + b + 1)!`. -/
theorem integral_pow_mul_one_sub_pow (a b : ℕ) :
    ∫ θ in (0 : ℝ)..1, θ ^ a * (1 - θ) ^ b =
      ((Nat.factorial a * Nat.factorial b : ℕ) : ℝ) / (Nat.factorial (a + b + 1) : ℝ) := by
  exact betaInt a b

/-- The prior washes out (Claim 3): with `h` heads in `n` flips, the flat prior's posterior
mean `(h+1)/(n+2)` and the sceptic's `(h+11)/(n+22)` differ by `10(2h - n)/((n+2)(n+22))`, and
that gap is smaller in size than `10/(n+22)`. -/
theorem posterior_mean_gap (n h : ℕ) (hh : h ≤ n) :
    ((h : ℝ) + 1) / (n + 2) - ((h : ℝ) + 11) / (n + 22) =
        10 * (2 * (h : ℝ) - n) / ((n + 2) * (n + 22)) ∧
      |((h : ℝ) + 1) / (n + 2) - ((h : ℝ) + 11) / (n + 22)| < 10 / ((n : ℝ) + 22) := by
  have e : ((h : ℝ) + 1) / (n + 2) - ((h : ℝ) + 11) / (n + 22) =
        10 * (2 * (h : ℝ) - n) / ((n + 2) * (n + 22)) := by
    field_simp; ring
  refine ⟨e, ?_⟩
  rw [e]
  have hh' : (h : ℝ) ≤ n := by exact_mod_cast hh
  have h0 : (0 : ℝ) ≤ h := by positivity
  have hn : (0 : ℝ) ≤ n := by positivity
  rw [abs_lt]
  constructor
  · rw [← neg_div, div_lt_div_iff₀ (by positivity) (by positivity)]
    nlinarith
  · rw [div_lt_div_iff₀ (by positivity) (by positivity)]
    nlinarith

/-! The card's worked numbers, as exact fractions. -/

-- A fair coin shows 7 or more heads in 10 flips in 176 of the 1024 outcomes.
example : ∑ j ∈ Finset.Icc 7 10, Nat.choose 10 j = 176 ∧ 2 ^ 10 = 1024 := by decide

-- The number of orders of 7 heads among 10 flips is 120.
example : Nat.choose 10 7 = 120 := by decide

-- Step 3: θ^7(1-θ)^3 = θ^7 - 3θ^8 + 3θ^9 - θ^10 has area 1/8 - 3/9 + 3/10 - 1/11 = 1/1320.
example : (1 / 8 : ℚ) - 3 / 9 + 3 / 10 - 1 / 11 = 1 / 1320 := by norm_num

-- Claim 1 check: I(7, 3) = 7! 3! / 11! = 1/1320, and I(8, 3) = 8! 3! / 12! = 1/1980.
example : ((Nat.factorial 7 * Nat.factorial 3 : ℕ) : ℚ) / (Nat.factorial 11 : ℕ) = 1 / 1320 := by
  norm_num [Nat.factorial]
example : ((Nat.factorial 8 * Nat.factorial 3 : ℕ) : ℚ) / (Nat.factorial 12 : ℕ) = 1 / 1980 := by
  norm_num [Nat.factorial]

-- The evidence is 120/1320 = 1/11, and the posterior mean is 1320/1980 = 2/3.
example : (120 : ℚ) / 1320 = 1 / 11 ∧ (1320 : ℚ) / 1980 = 2 / 3 := by norm_num

-- The chance the coin favours heads: 1320 times the area under θ^7(1-θ)^3 from 1/2 to 1,
-- term by term, is 227/256.
example : 1320 * (((1 : ℚ) - (1 / 2) ^ 8) / 8 - 3 * ((1 - (1 / 2) ^ 9) / 9)
    + 3 * ((1 - (1 / 2) ^ 10) / 10) - (1 - (1 / 2) ^ 11) / 11) = 227 / 256 := by norm_num

-- Claim 2: flat prior (c = 0) gives (7+1)/(10+2) = 2/3; the sceptic (c = 10) gives 18/32 = 9/16.
example : ((0 + 7 + 1 : ℕ) : ℚ) / (2 * 0 + 10 + 2 : ℕ) = 2 / 3 := by norm_num
example : ((10 + 7 + 1 : ℕ) : ℚ) / (2 * 10 + 10 + 2 : ℕ) = 9 / 16 := by norm_num

-- Claim 3: (h+1)(n+22) - (h+11)(n+2) = 20h - 10n at h = 7, n = 10 is 40; the gap is 40/384,
-- and at n = 1000, h = 700 it is 4000/1024044.
example : ((7 + 1) * (10 + 22) : ℤ) - (7 + 11) * (10 + 2) = 20 * 7 - 10 * 10 := by norm_num
example : (8 : ℚ) / 12 - 18 / 32 = 40 / 384 := by norm_num
example : (701 : ℚ) / 1002 - 711 / 1022 = 4000 / 1024044 := by norm_num

-- Try changing, ten heads in ten: the flat-prior mean is (10+1)/(10+2) = 11/12.
-- What breaks, the same flips fed in twice (14 heads in 20): the mean is 15/22, not 2/3.
example : ((10 + 1 : ℕ) : ℚ) / (10 + 2 : ℕ) = 11 / 12 ∧ ((14 + 1 : ℕ) : ℚ) / (20 + 2 : ℕ) = 15 / 22 := by
  norm_num

#print axioms bayesian_update_posterior_mean
#print axioms integral_pow_mul_one_sub_pow
#print axioms posterior_mean_gap
