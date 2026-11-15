-- Feynman-Kac: on the coin-flip tree, the value stepped back through the equation with a killing rate and a stopping edge is exactly the average over all paths of what each path collects where it stops, discounted by survival; the price-linear killing rate is a Gaussian tilt of the plain solution; and the corner solution is a second solution with the same data.
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.List.OfFn
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Order.Filter.Basic
import Mathlib.Topology.Order.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Tactic

open Real Filter Topology

namespace FeynmanKacKolmogorov

/-! Notation, as on the card. On the coin-flip tree every step lasts `h` years and moves the
price up or down by `δ` (the card takes `δ = σ √h`). `k x` is the potential (the seller's failure
rate per year at price `x`), `b` the edge, `g i` the payment at the edge at step `i`, and `f` the
payoff at the end step `n`. A path is a list of coin flips, `true` for up and `false` for down. -/

/-- **What one path collects where it stops.** Starting at step `i` at price `x`, follow the coin
flips `cs`. At the first step where the price is at or below the edge `b`, the path stops and
collects the edge payment `g` at that step. If it never touches the edge, it collects the payoff
`f` at the end. Each step it survives in the region multiplies its weight by `1 - k(x) h`, the
chance the seller survives that step. -/
noncomputable def collect (k f : ℝ → ℝ) (g : ℕ → ℝ) (b δ h : ℝ) : ℕ → List Bool → ℝ → ℝ
  | i, [], x => if x ≤ b then g i else f x
  | i, c :: cs, x =>
      if x ≤ b then g i
      else (1 - k x * h) * collect k f g b δ h (i + 1) cs (x + if c then δ else -δ)

theorem sum_ofFn_succ (m : ℕ) (F : List Bool → ℝ) :
    ∑ ω : Fin (m + 1) → Bool, F (List.ofFn ω) =
      ∑ ω : Fin m → Bool, (F (true :: List.ofFn ω) + F (false :: List.ofFn ω)) := by
  rw [← (Fin.consEquiv (fun _ => Bool)).sum_comp]
  rw [Fintype.sum_prod_type]
  simp [Fin.consEquiv, List.ofFn_succ, Finset.sum_add_distrib, add_comm]

#print axioms sum_ofFn_succ

/-- Second derivative of `y ↦ exp (-α y + c) * G (y - s)` for a `C²` function `G`. -/
theorem tilt_space_deriv (G : ℝ → ℝ) (hG : ContDiff ℝ 2 G) (α c s x : ℝ) :
    iteratedDeriv 2 (fun y => exp (-α * y + c) * G (y - s)) x =
      exp (-α * x + c) * (α ^ 2 * G (x - s) - 2 * α * deriv G (x - s)
        + iteratedDeriv 2 G (x - s)) := by
  have hG1 : Differentiable ℝ G := hG.differentiable (by norm_num)
  have hG2 : ContDiff ℝ 1 (deriv G) := by
    have h := hG
    rw [show (2 : WithTop ℕ∞) = 1 + 1 by norm_num] at h
    exact (contDiff_succ_iff_deriv.mp h).2.2
  have hG2d : Differentiable ℝ (deriv G) := hG2.differentiable (by norm_num)
  have he : ∀ y, HasDerivAt (fun y => exp (-α * y + c)) (exp (-α * y + c) * (-α)) y := by
    intro y
    have := (((hasDerivAt_id y).const_mul (-α)).add_const c).exp
    simpa using this
  have hs : ∀ y, HasDerivAt (fun y => y - s) 1 y := fun y => (hasDerivAt_id y).sub_const s
  have h1 : ∀ y, HasDerivAt (fun y => exp (-α * y + c) * G (y - s))
      (exp (-α * y + c) * (-α * G (y - s) + deriv G (y - s))) y := by
    intro y
    have := (he y).mul ((hG1 (y - s)).hasDerivAt.comp y (hs y))
    refine this.congr_deriv ?_
    simp only [Function.comp_apply, mul_one]; ring
  rw [iteratedDeriv_succ, iteratedDeriv_one]
  have hd : deriv (fun y => exp (-α * y + c) * G (y - s)) =
      fun y => exp (-α * y + c) * (-α * G (y - s) + deriv G (y - s)) := by
    funext y; exact (h1 y).deriv
  rw [hd]
  have h2 : HasDerivAt (fun y => -α * G (y - s) + deriv G (y - s))
      (-α * deriv G (x - s) + deriv (deriv G) (x - s)) x := by
    have a1 := ((hG1 (x - s)).hasDerivAt.comp x (hs x)).const_mul (-α)
    have a2 := (hG2d (x - s)).hasDerivAt.comp x (hs x)
    refine (a1.add a2).congr_deriv ?_
    simp only [mul_one]
  have h3 : HasDerivAt (fun y => exp (-α * y + c) * (-α * G (y - s) + deriv G (y - s)))
      (exp (-α * x + c) * -α * (-α * G (x - s) + deriv G (x - s)) +
        exp (-α * x + c) * (-α * deriv G (x - s) + deriv (deriv G) (x - s))) x := (he x).mul h2
  rw [h3.deriv, iteratedDeriv_succ, iteratedDeriv_one]
  ring

#print axioms tilt_space_deriv

theorem corner_hasDerivAt_x (b L A y : ℝ) :
    HasDerivAt (fun y => (y - b) * L * exp (-(y - b) ^ 2 / A))
      (L * exp (-(y - b) ^ 2 / A) * (1 - 2 * (y - b) ^ 2 / A)) y := by
  have h1 : HasDerivAt (fun y => y - b) 1 y := (hasDerivAt_id y).sub_const b
  have h2 : HasDerivAt (fun y => -(y - b) ^ 2 / A) (-(2 * (y - b)) / A) y := by
    have := ((h1.pow 2).neg).div_const A
    convert this using 1; simp
  have := (h1.mul_const L).mul h2.exp
  convert this using 1; ring

#print axioms corner_hasDerivAt_x

theorem corner_hasDerivAt_xx (b L A y : ℝ) :
    HasDerivAt (fun y => L * exp (-(y - b) ^ 2 / A) * (1 - 2 * (y - b) ^ 2 / A))
      (L * exp (-(y - b) ^ 2 / A) * ((-(2 * (y - b)) / A) * (1 - 2 * (y - b) ^ 2 / A)
        - 4 * (y - b) / A)) y := by
  have h1 : HasDerivAt (fun y => y - b) 1 y := (hasDerivAt_id y).sub_const b
  have h2 : HasDerivAt (fun y => -(y - b) ^ 2 / A) (-(2 * (y - b)) / A) y := by
    have := ((h1.pow 2).neg).div_const A
    convert this using 1; simp
  have h3 : HasDerivAt (fun y => 1 - 2 * (y - b) ^ 2 / A) (-(4 * (y - b) / A)) y := by
    have := (((h1.pow 2).const_mul 2).div_const A).const_sub 1
    convert this using 1; simp; ring
  have := (h2.exp.const_mul L).mul h3
  convert this using 1; ring

#print axioms corner_hasDerivAt_xx

theorem corner_iteratedDeriv_two (b L A x : ℝ) :
    iteratedDeriv 2 (fun y => (y - b) * L * exp (-(y - b) ^ 2 / A)) x =
      L * exp (-(x - b) ^ 2 / A) * ((-(2 * (x - b)) / A) * (1 - 2 * (x - b) ^ 2 / A)
        - 4 * (x - b) / A) := by
  rw [iteratedDeriv_succ, iteratedDeriv_one]
  have : deriv (fun y => (y - b) * L * exp (-(y - b) ^ 2 / A)) =
      fun y => L * exp (-(y - b) ^ 2 / A) * (1 - 2 * (y - b) ^ 2 / A) := by
    funext y; exact (corner_hasDerivAt_x b L A y).deriv
  rw [this]
  exact (corner_hasDerivAt_xx b L A x).deriv

#print axioms corner_iteratedDeriv_two

theorem corner_hasDerivAt_t (x b σ T t : ℝ) (hσ : σ ≠ 0) (ht : t < T) :
    HasDerivAt (fun s => (x - b) * (T - s) ^ (-(3 / 2 : ℝ)) * exp (-(x - b) ^ 2 / (2 * σ ^ 2 * (T - s))))
      ((x - b) * exp (-(x - b) ^ 2 / (2 * σ ^ 2 * (T - t))) *
        ((3 / 2) * (T - t) ^ (-(3 / 2 : ℝ)) / (T - t)
          - (T - t) ^ (-(3 / 2 : ℝ)) * (x - b) ^ 2 / (2 * σ ^ 2 * (T - t) ^ 2))) t := by
  have hl : 0 < T - t := sub_pos.mpr ht
  have h1 : HasDerivAt (fun s => T - s) (-1) t := by
    simpa using (hasDerivAt_id t).const_sub T
  have h2 := h1.rpow_const (p := -(3 / 2 : ℝ)) (Or.inl hl.ne')
  have h3 : HasDerivAt (fun s => -(x - b) ^ 2 / (2 * σ ^ 2 * (T - s)))
      (-(-(x - b) ^ 2 * (2 * σ ^ 2 * (-1))) / (2 * σ ^ 2 * (T - t)) ^ 2) t := by
    have := (hasDerivAt_const t (-(x - b) ^ 2)).div (h1.const_mul (2 * σ ^ 2))
      (by have : 0 < σ ^ 2 * (T - t) := by positivity
          positivity)
    convert this using 1; ring
  have := (h2.const_mul (x - b)).mul h3.exp
  convert this using 1
  rw [rpow_sub_one hl.ne']
  field_simp
  ring

#print axioms corner_hasDerivAt_t

/-- **Feynman-Kac on the coin-flip tree: the equation and the path average are the same sum**
(Why it works, Step 1, with the potential of Step 2 and the edge of Step 3). Let `u i x` be the
bet's value at step `i` of `n` at price `x`, worked backward through the tree:
* at or below the edge it is the edge payment, `u i x = g i`;
* above the edge on the end step it is the payoff, `u n x = f x`;
* above the edge before the end it is one step of the backward equation with the potential,
  `u i x = (1 - k(x) h) · ½ [u (i+1) (x + δ) + u (i+1) (x - δ)]`.
Then at every step `i ≤ n` and every price `x`, the value is the average, over all `2^(n-i)`
coin-flip paths from `x`, of what each path collects where it stops (the payoff if it reaches
the end, the edge payment if it touches the edge first), times its survival factor along the
way. On the tree no growth or continuity condition is needed: the minus sign of the potential
is the factor `1 - k h`, and stopping (not bouncing) at the edge is built into `collect`. -/
theorem tree_value_eq_path_average
    (k f : ℝ → ℝ) (g : ℕ → ℝ) (b δ h : ℝ) (n : ℕ) (u : ℕ → ℝ → ℝ)
    (hedge : ∀ i ≤ n, ∀ x, x ≤ b → u i x = g i)
    (hend : ∀ x, b < x → u n x = f x)
    (hstep : ∀ i < n, ∀ x, b < x →
      u i x = (1 - k x * h) * ((u (i + 1) (x + δ) + u (i + 1) (x - δ)) / 2)) :
    ∀ i ≤ n, ∀ x,
      u i x = (∑ ω : Fin (n - i) → Bool, collect k f g b δ h i (List.ofFn ω) x) / 2 ^ (n - i) := by
  suffices H : ∀ m i, n - i = m → i ≤ n → ∀ x,
      u i x = (∑ ω : Fin m → Bool, collect k f g b δ h i (List.ofFn ω) x) / 2 ^ m by
    intro i hi x
    exact H (n - i) i rfl hi x
  intro m
  induction m with
  | zero =>
    intro i hm hi x
    have hin : i = n := by omega
    subst hin
    simp only [Finset.univ_unique, Finset.sum_singleton, pow_zero, div_one]
    rw [List.ofFn_zero]
    simp only [collect]
    split_ifs with hx
    · exact hedge i le_rfl x hx
    · exact hend x (lt_of_not_ge hx)
  | succ m ih =>
    intro i hm hi x
    have hlt : i < n := by omega
    have hm' : n - (i + 1) = m := by omega
    rw [sum_ofFn_succ m (fun l => collect k f g b δ h i l x)]
    by_cases hx : x ≤ b
    · simp only [collect, hx, ite_true]
      rw [hedge i hi x hx]
      simp only [Finset.sum_const, Finset.card_univ, Fintype.card_pi, Fintype.card_bool,
        Finset.prod_const, Fintype.card_fin, nsmul_eq_mul]
      push_cast
      field_simp
      ring
    · have hbx : b < x := lt_of_not_ge hx
      simp only [collect, hx, ite_false, ite_true, Bool.false_eq_true, ← sub_eq_add_neg]
      rw [hstep i hlt x hbx, ih (i + 1) hm' hlt (x + δ), ih (i + 1) hm' hlt (x - δ)]
      rw [Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum]
      rw [pow_succ]
      field_simp

/-- **A potential that rises in a straight line is a Gaussian tilt** (the closed form, and the
fold under Step 2). Write `C (x, ℓ)` for a solution of the plain backward equation in the time
left `ℓ > 0`, so `C_ℓ = ½ σ² C_xx`. Then
`u (x, ℓ) = e^{-β x ℓ + β² σ² ℓ³ / 6} · C (x - ½ β σ² ℓ², ℓ)`
solves the equation with the failure rate `k(x) = β x` as a potential,
`u_ℓ = ½ σ² u_xx - β x u`: the discount at today's rate, the small credit for luck, and the
shift of the price down by `½ β σ² ℓ²`. -/
theorem hazard_tilt_solves_equation_with_potential
    (σ β : ℝ) (C : ℝ × ℝ → ℝ)
    (hC : ContDiffOn ℝ 2 C {p : ℝ × ℝ | 0 < p.2})
    (hheat : ∀ x ℓ, 0 < ℓ →
      deriv (fun s => C (x, s)) ℓ = σ ^ 2 / 2 * iteratedDeriv 2 (fun y => C (y, ℓ)) x) :
    let u : ℝ → ℝ → ℝ := fun x ℓ =>
      exp (-β * x * ℓ + β ^ 2 * σ ^ 2 * ℓ ^ 3 / 6) * C (x - β * σ ^ 2 * ℓ ^ 2 / 2, ℓ)
    ∀ x ℓ, 0 < ℓ →
      DifferentiableAt ℝ (fun s => u x s) ℓ ∧ ContDiffAt ℝ 2 (fun y => u y ℓ) x ∧
      deriv (fun s => u x s) ℓ = σ ^ 2 / 2 * iteratedDeriv 2 (fun y => u y ℓ) x - β * x * u x ℓ := by
  intro u x ℓ hℓ
  have hU : IsOpen {p : ℝ × ℝ | 0 < p.2} := isOpen_lt continuous_const continuous_snd
  have hCat : ∀ p : ℝ × ℝ, 0 < p.2 → ContDiffAt ℝ 2 C p :=
    fun p hp => hC.contDiffAt (hU.mem_nhds hp)
  have hCd : ∀ p : ℝ × ℝ, 0 < p.2 → DifferentiableAt ℝ C p :=
    fun p hp => (hCat p hp).differentiableAt (by norm_num)
  set G : ℝ → ℝ := fun y => C (y, ℓ) with hGdef
  have hG : ContDiff ℝ 2 G := by
    rw [contDiff_iff_contDiffAt]
    intro y
    exact (hCat (y, ℓ) hℓ).comp y (contDiffAt_id.prodMk contDiffAt_const)
  set x' := x - β * σ ^ 2 * ℓ ^ 2 / 2 with hx'
  set p0 : ℝ × ℝ := (x', ℓ) with hp0
  have hp0pos : 0 < p0.2 := hℓ
  -- partial derivatives of `C` at `p0`
  set L := fderiv ℝ C p0 with hL
  have hCp0 : HasFDerivAt C L p0 := (hCd p0 hp0pos).hasFDerivAt
  have hGx : deriv G x' = L (1, 0) := by
    have := hCp0.comp_hasDerivAt x' ((hasDerivAt_id x').prodMk (hasDerivAt_const x' ℓ))
    exact this.deriv
  have hCt : deriv (fun s => C (x', s)) ℓ = L (0, 1) := by
    have := hCp0.comp_hasDerivAt ℓ ((hasDerivAt_const ℓ x').prodMk (hasDerivAt_id ℓ))
    exact this.deriv
  -- time derivative
  have hpath : HasDerivAt (fun s => (x - β * σ ^ 2 * s ^ 2 / 2, s))
      ((-(β * σ ^ 2 * ℓ), 1) : ℝ × ℝ) ℓ := by
    have a1 : HasDerivAt (fun s => x - β * σ ^ 2 * s ^ 2 / 2) (-(β * σ ^ 2 * ℓ)) ℓ := by
      have := ((hasDerivAt_pow 2 ℓ).const_mul (β * σ ^ 2)).div_const 2 |>.const_sub x
      refine this.congr_deriv ?_
      push_cast; ring
    exact a1.prodMk (hasDerivAt_id ℓ)
  have hpath' : HasDerivAt (fun s => C (x - β * σ ^ 2 * s ^ 2 / 2, s))
      (L (-(β * σ ^ 2 * ℓ), 1)) ℓ :=
    hCp0.comp_hasDerivAt (f := fun s => (x - β * σ ^ 2 * s ^ 2 / 2, s)) ℓ hpath
  have hE : HasDerivAt (fun s => exp (-β * x * s + β ^ 2 * σ ^ 2 * s ^ 3 / 6))
      (exp (-β * x * ℓ + β ^ 2 * σ ^ 2 * ℓ ^ 3 / 6) * (-β * x + β ^ 2 * σ ^ 2 * ℓ ^ 2 / 2)) ℓ := by
    have := (((hasDerivAt_id ℓ).const_mul (-β * x)).add
      ((hasDerivAt_pow 3 ℓ).const_mul (β ^ 2 * σ ^ 2) |>.div_const 6)).exp
    refine this.congr_deriv ?_
    simp only [id, Pi.add_apply]; push_cast; ring
  have htime : HasDerivAt (fun s => u x s)
      (exp (-β * x * ℓ + β ^ 2 * σ ^ 2 * ℓ ^ 3 / 6) * (-β * x + β ^ 2 * σ ^ 2 * ℓ ^ 2 / 2) *
        C (x - β * σ ^ 2 * ℓ ^ 2 / 2, ℓ) +
        exp (-β * x * ℓ + β ^ 2 * σ ^ 2 * ℓ ^ 3 / 6) * L (-(β * σ ^ 2 * ℓ), 1)) ℓ :=
    hE.mul hpath'
  have hLsplit : L (-(β * σ ^ 2 * ℓ), 1) = -(β * σ ^ 2 * ℓ) * L (1, 0) + L (0, 1) := by
    have : ((-(β * σ ^ 2 * ℓ), 1) : ℝ × ℝ) = (-(β * σ ^ 2 * ℓ)) • ((1, 0) : ℝ × ℝ) + (0, 1) := by
      ext <;> simp
    rw [this, map_add, map_smul, smul_eq_mul]
  refine ⟨htime.differentiableAt, ?_, ?_⟩
  · show ContDiffAt ℝ 2 (fun y => exp (-β * y * ℓ + β ^ 2 * σ ^ 2 * ℓ ^ 3 / 6) *
      G (y - β * σ ^ 2 * ℓ ^ 2 / 2)) x
    have : ContDiff ℝ 2 (fun y => G (y - β * σ ^ 2 * ℓ ^ 2 / 2)) :=
      hG.comp (contDiff_id.sub contDiff_const)
    exact ((by fun_prop : ContDiff ℝ 2 fun y => exp (-β * y * ℓ + β ^ 2 * σ ^ 2 * ℓ ^ 3 / 6)).mul
      this).contDiffAt
  · have hsp := tilt_space_deriv G hG (β * ℓ) (β ^ 2 * σ ^ 2 * ℓ ^ 3 / 6)
      (β * σ ^ 2 * ℓ ^ 2 / 2) x
    have hfun : (fun y => u y ℓ) = fun y => exp (-(β * ℓ) * y + β ^ 2 * σ ^ 2 * ℓ ^ 3 / 6) *
        G (y - β * σ ^ 2 * ℓ ^ 2 / 2) := by
      funext y; simp only [u, G]; ring_nf
    rw [hfun, hsp, htime.deriv]
    rw [hLsplit, ← hGx, ← hCt, hheat x' ℓ hℓ]
    simp only [u, G, x']
    ring_nf

/-- **The corner solution: without continuity at the corner, uniqueness fails** (Step 5). With
spread `σ > 0`, edge `b` and end date `T`, the function
`v (t, x) = (x - b) ℓ^{-3/2} e^{-(x - b)² / (2 σ² ℓ)}`, with `ℓ = T - t`,
1. solves the plain backward equation `v_t + ½ σ² v_xx = 0` before the end date,
2. is zero on the edge `x = b`,
3. tends to zero at every price as the end date nears,
4. yet is not zero: it is positive at every price above the edge before the end date,
5. and it is unbounded near the corner `(T, b)`, so it is not continuous there and lies outside
   the class in which the Feynman-Kac average is the only solution. -/
theorem corner_solution_breaks_uniqueness (σ b T : ℝ) (hσ : 0 < σ) :
    let v : ℝ → ℝ → ℝ := fun t x =>
      (x - b) * (T - t) ^ (-(3 / 2 : ℝ)) * exp (-(x - b) ^ 2 / (2 * σ ^ 2 * (T - t)))
    (∀ t x, t < T →
      ContDiffAt ℝ 2 (fun y => v t y) x ∧
      HasDerivAt (fun s => v s x) (-(σ ^ 2 / 2) * iteratedDeriv 2 (fun y => v t y) x) t) ∧
    (∀ t, t < T → v t b = 0) ∧
    (∀ x, Tendsto (fun t => v t x) (𝓝[<] T) (𝓝 0)) ∧
    (∀ t x, t < T → b < x → 0 < v t x) ∧
    (∀ M ε : ℝ, 0 < ε → ∃ t x, T - ε < t ∧ t < T ∧ b < x ∧ x < b + ε ∧ M < v t x) := by
  intro v
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · intro t x ht
    refine ⟨?_, ?_⟩
    · simp only [v]
      fun_prop
    · simp only [v]
      rw [corner_iteratedDeriv_two]
      convert corner_hasDerivAt_t x b σ T t hσ.ne' ht using 1
      have hl : 0 < T - t := sub_pos.mpr ht
      field_simp
      ring
  · intro t ht
    simp [v]
  · intro x
    by_cases hx : x = b
    · have : (fun t => v t x) = fun _ => 0 := by funext t; simp [v, hx]
      rw [this]; exact tendsto_const_nhds
    have hc : 0 < (x - b) ^ 2 / (2 * σ ^ 2) := by
      have : x - b ≠ 0 := sub_ne_zero.mpr hx
      positivity
    have hT : Tendsto (fun t => T - t) (𝓝[<] T) (𝓝[>] 0) := by
      rw [tendsto_nhdsWithin_iff]
      refine ⟨?_, eventually_nhdsWithin_of_forall (fun t ht => Set.mem_Ioi.mpr (sub_pos.mpr ht))⟩
      have : Tendsto (fun t => T - t) (𝓝 T) (𝓝 (T - T)) :=
        tendsto_const_nhds.sub tendsto_id
      rw [sub_self] at this
      exact this.mono_left nhdsWithin_le_nhds
    have hlim := ((tendsto_rpow_mul_exp_neg_mul_atTop_nhds_zero (3 / 2) _ hc).comp
      (tendsto_inv_nhdsGT_zero.comp hT)).const_mul (x - b)
    rw [mul_zero] at hlim
    refine hlim.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with t ht
    have hl : 0 < T - t := sub_pos.mpr ht
    simp only [Function.comp_apply, v]
    rw [inv_rpow hl.le, rpow_neg hl.le]
    have : -((x - b) ^ 2 / (2 * σ ^ 2)) * (T - t)⁻¹ = -(x - b) ^ 2 / (2 * σ ^ 2 * (T - t)) := by
      field_simp
    rw [this]; ring
  · intro t x ht hx
    simp only [v]
    have hl : 0 < T - t := sub_pos.mpr ht
    have := sub_pos.mpr hx
    positivity
  · intro M ε hε
    set K := exp (-1 / (2 * σ ^ 2)) with hK
    have hKpos : 0 < K := exp_pos _
    set z := min (min (ε / 2) (1 / 2)) (K / (2 * (|M| + 1))) with hz
    have hz1 : z ≤ ε / 2 := le_trans (min_le_left _ _) (min_le_left _ _)
    have hz2 : z ≤ 1 / 2 := le_trans (min_le_left _ _) (min_le_right _ _)
    have hz3 : z ≤ K / (2 * (|M| + 1)) := min_le_right _ _
    have hzpos : 0 < z := by
      rw [hz]; refine lt_min (lt_min (by linarith) (by norm_num)) (by positivity)
    have hval : v (T - z ^ 2) (b + z) = K / z ^ 2 := by
      simp only [v]
      rw [sub_sub_cancel, add_sub_cancel_left]
      have e1 : -z ^ 2 / (2 * σ ^ 2 * z ^ 2) = -1 / (2 * σ ^ 2) := by field_simp
      rw [e1, ← hK]
      have e2 : (z ^ 2) ^ (-(3 / 2 : ℝ)) = (z ^ 3)⁻¹ := by
        rw [← rpow_natCast z 2, ← rpow_mul hzpos.le,
          show ((2 : ℕ) : ℝ) * -(3 / 2 : ℝ) = -((3 : ℕ) : ℝ) by norm_num,
          rpow_neg hzpos.le, rpow_natCast]
      rw [e2]
      field_simp
    have hMz : M * z ^ 2 < K := by
      have hA : |M| * z ≤ K / 2 := by
        have h1 : (|M| + 1) * z ≤ K / 2 := by
          rw [le_div_iff₀ (by positivity)] at hz3
          nlinarith
        nlinarith [abs_nonneg M]
      have hzz : z ^ 2 ≤ z := by nlinarith
      have : M * z ^ 2 ≤ |M| * z :=
        calc M * z ^ 2 ≤ |M| * z ^ 2 := mul_le_mul_of_nonneg_right (le_abs_self M) (sq_nonneg z)
          _ ≤ |M| * z := mul_le_mul_of_nonneg_left hzz (abs_nonneg M)
      linarith
    refine ⟨T - z ^ 2, b + z, ?_, ?_, ?_, ?_, ?_⟩
    · nlinarith
    · nlinarith
    · linarith
    · linarith
    · rw [hval, lt_div_iff₀ (by positivity)]; exact hMz

/-! The card's exact worked numbers (Worked numbers, by hand; the tree; the uniqueness table),
in exact rationals: `σ = 20` dollars per root-year, `β = 1/1000` per dollar per year, one year
left, strike 100 dollars, edge 90 dollars. -/

/-- Step 1: the price shift `½ β σ² ℓ²` is 20 cents. -/
example : (1 / 2 : ℚ) * (1 / 1000) * 20 ^ 2 * 1 ^ 2 = 1 / 5 := by norm_num

/-- Step 2: the luck credit `β² σ² ℓ³ / 6` is `1/15000` (0.00006667). -/
example : (1 / 1000 : ℚ) ^ 2 * 20 ^ 2 * 1 ^ 3 / 6 = 1 / 15000 := by norm_num

/-- Step 3: the exponent of the discount, `β x ℓ - β² σ² ℓ³ / 6`, is `1499/15000` (0.09993333). -/
example : (1 / 1000 : ℚ) * 100 * 1 - (1 / 1000) ^ 2 * 20 ^ 2 * 1 ^ 3 / 6 = 1499 / 15000 := by
  norm_num

/-- The failure rate at 100 dollars is 0.1 per year. -/
example : (1 / 1000 : ℚ) * 100 = 1 / 10 := by norm_num

/-- The mirror point of 100 dollars in the edge at 90 dollars is 80 dollars. -/
example : (2 * 90 - 100 : ℤ) = 80 := by norm_num

/-- The shifted start price for the plain bet is 99.80 dollars. -/
example : (100 : ℚ) - 1 / 5 = 499 / 5 := by norm_num

/-- The tree's price step `δ = σ √h` at `h = 0.0025` years is 1 dollar: `δ² = σ² h = 1`. -/
example : (20 : ℚ) ^ 2 * (1 / 400) = 1 ^ 2 := by norm_num

/-- The uniqueness table: the far edge at 150 dollars is `z = 2.5` spreads above 100 dollars. -/
example : ((150 : ℚ) - 100) / 20 = 5 / 2 := by norm_num

/-- The tree extrapolation weights `(4 · tree₁₆₀₀ - tree₄₀₀)/3` sum to one. -/
example : (4 : ℚ) / 3 - 1 / 3 = 1 := by norm_num

#print axioms tree_value_eq_path_average
#print axioms hazard_tilt_solves_equation_with_potential
#print axioms corner_solution_breaks_uniqueness

end FeynmanKacKolmogorov
