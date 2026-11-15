-- Hamilton-Jacobi: the Hopf-Lax minimum solves u_t + H(u_x) = 0 wherever it has a slope, the characteristics of u_t + H(u_x, x) = 0 are Hamilton's equations, and the truck's least fuel k x³/t² + B(x) solves the hill equation.
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Data.Real.Archimedean
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.ContDiff.Comp
import Mathlib.Analysis.Calculus.FDeriv.Symmetric

/-! Points of the route-and-time plane are pairs `(x, t)` in `ℝ × ℝ`. For a function `u` of
`(x, t)`, its slope in place is `u_x = fderiv ℝ u (x, t) (1, 0)` and its slope in time is
`u_t = fderiv ℝ u (x, t) (0, 1)`.

The Lagrangian `L v` is the cost per hour at speed `v`. Its slope transform, the Hamiltonian,
is `H p = sup_v (p v - L v)`. The Hopf-Lax value from a starting cost `g` is
`u(x, t) = min_y (g y + t L((x - y)/t))`. -/

/-- The Hamiltonian of a Lagrangian `L`: the most `p v - L v` can be, over all speeds `v`. -/
noncomputable def hamiltonian (L : ℝ → ℝ) (p : ℝ) : ℝ := ⨆ v : ℝ, (p * v - L v)

/-- The Hopf-Lax value at `(x, t)`: the least of `g y + t L((x - y)/t)` over starting places `y`. -/
noncomputable def hopfLax (g L : ℝ → ℝ) (z : ℝ × ℝ) : ℝ := ⨅ y : ℝ, (g y + z.2 * L ((z.1 - y) / z.2))

/-- The Hopf-Lax formula solves the Hamilton-Jacobi equation. Let the cost per hour `L` depend
only on the speed and curve upward (convex), and let `H` be its slope transform. Suppose the
minimum over starting places in `u(x, t) = min_y (g y + t L((x - y)/t))` is reached at every
place and every time `t > 0`. Then wherever `u` has a slope at a time `t > 0`,
`u_t + H(u_x) = 0`. -/
theorem hopf_lax_solves_hamilton_jacobi {L g : ℝ → ℝ} (hL : ConvexOn ℝ Set.univ L)
    (hmin : ∀ x t : ℝ, 0 < t → ∃ y : ℝ, ∀ y' : ℝ,
      g y + t * L ((x - y) / t) ≤ g y' + t * L ((x - y') / t))
    {x t : ℝ} (ht : 0 < t) (hdiff : DifferentiableAt ℝ (hopfLax g L) (x, t)) :
    fderiv ℝ (hopfLax g L) (x, t) (0, 1)
      + hamiltonian L (fderiv ℝ (hopfLax g L) (x, t) (1, 0)) = 0 := by
  -- upper bound at any point with positive time
  have hA : ∀ a s : ℝ, 0 < s → ∀ y' : ℝ, hopfLax g L (a, s) ≤ g y' + s * L ((a - y') / s) := by
    intro a s hs y'
    obtain ⟨y, hy⟩ := hmin a s hs
    exact ciInf_le ⟨_, by rintro _ ⟨w, rfl⟩; exact hy w⟩ y'
  obtain ⟨y, hy⟩ := hmin x t ht
  have hB : hopfLax g L (x, t) = g y + t * L ((x - y) / t) :=
    le_antisymm (hA x t ht y) (le_ciInf hy)
  set D := fderiv ℝ (hopfLax g L) (x, t) with hD
  set p := D (1, 0)
  set q := D (0, 1)
  have hphi : ∀ v : ℝ, HasDerivAt (fun h : ℝ => hopfLax g L (x + h * v, t + h)) (v * p + q) 0 := by
    intro v
    have hpath : HasDerivAt (fun h : ℝ => (x + h * v, t + h)) ((v, 1) : ℝ × ℝ) 0 := by
      refine HasDerivAt.prodMk ?_ ?_
      · simpa using ((hasDerivAt_id (0:ℝ)).mul_const v).const_add x
      · simpa using (hasDerivAt_id (0:ℝ)).const_add t
    have h0 : ((x, t) : ℝ × ℝ) = (x + (0:ℝ) * v, t + 0) := by simp
    have := hdiff.hasFDerivAt.comp_hasDerivAt_of_eq (0:ℝ) hpath h0
    have hv : ((v, 1) : ℝ × ℝ) = v • ((1, 0) : ℝ × ℝ) + ((0, 1) : ℝ × ℝ) := by
      ext <;> simp
    rw [hv, map_add, map_smul, smul_eq_mul] at this
    exact this
  -- Step 1: v p + q ≤ L v for all v
  have h1 : ∀ v : ℝ, v * p + q ≤ L v := by
    intro v
    have key : ∀ h : ℝ, 0 < h → hopfLax g L (x + h * v, t + h) ≤ hopfLax g L (x, t) + h * L v := by
      intro h hh
      have hth : 0 < t + h := by linarith
      refine (hA _ _ hth y).trans ?_
      rw [hB]
      have hc := hL.2 (Set.mem_univ ((x - y) / t)) (Set.mem_univ v)
        (div_pos ht hth).le (div_pos hh hth).le (by field_simp)
      have he : (x + h * v - y) / (t + h) = t / (t + h) * ((x - y) / t) + h / (t + h) * v := by
        have e1 : t / (t + h) * ((x - y) / t) = (x - y) / (t + h) := by
          rw [div_mul_div_comm, mul_comm t, mul_div_mul_right _ _ ht.ne']
        rw [e1, div_mul_eq_mul_div, ← add_div]
        congr 1; ring
      rw [he]
      have := mul_le_mul_of_nonneg_left hc hth.le
      simp only [smul_eq_mul] at this
      have e2 : (t + h) * (t / (t + h) * L ((x - y) / t) + h / (t + h) * L v)
          = t * L ((x - y) / t) + h * L v := by field_simp
      linarith
    have ht' := (hphi v).tendsto_slope_zero_right
    refine le_of_tendsto ht' ?_
    filter_upwards [self_mem_nhdsWithin] with h hh
    have hh' : (0:ℝ) < h := hh
    have := key h hh'
    simp only [zero_add, zero_mul, add_zero, smul_eq_mul]
    rw [inv_mul_le_iff₀ hh']
    linarith
  -- Step 2: at v0 the reverse inequality
  set v0 := (x - y) / t
  have h2 : L v0 ≤ v0 * p + q := by
    have key : ∀ h : ℝ, -t < h → hopfLax g L (x + h * v0, t + h) ≤ hopfLax g L (x, t) + h * L v0 := by
      intro h hh
      have hth : 0 < t + h := by linarith
      refine (hA _ _ hth y).trans ?_
      rw [hB]
      have he : (x + h * v0 - y) / (t + h) = v0 := by
        simp only [v0]; field_simp; ring
      rw [he]; simp only [v0]; ring_nf; rfl
    have ht' := (hphi v0).tendsto_slope_zero_left
    refine ge_of_tendsto ht' ?_
    have hm : Set.Ioi (-t) ∈ nhdsWithin (0:ℝ) (Set.Iio 0) :=
      nhdsWithin_le_nhds (Ioi_mem_nhds (by linarith))
    filter_upwards [self_mem_nhdsWithin, hm] with h hh hh2
    have hh' : h < 0 := hh
    have := key h hh2
    simp only [zero_add, zero_mul, add_zero, smul_eq_mul]
    rw [inv_mul_eq_div, le_div_iff_of_neg hh']
    linarith
  have hbdd : BddAbove (Set.range fun v : ℝ => p * v - L v) := by
    refine ⟨-q, ?_⟩
    rintro _ ⟨v, rfl⟩
    have := h1 v
    simp only; linarith
  have hH1 : hamiltonian L p ≤ -q := ciSup_le fun v => by have := h1 v; linarith
  have hH2 : p * v0 - L v0 ≤ hamiltonian L p := le_ciSup hbdd v0
  show q + hamiltonian L p = 0
  linarith

/-- The characteristics of a Hamilton-Jacobi equation are Hamilton's equations. Let `u(x, t)`
have continuous second derivatives and solve `u_t + H(u_x, x) = 0` everywhere, with `H(p, x)`
continuously differentiable. Follow a path `x(t)` whose speed is `ẋ = ∂H/∂p` at the price
`p = u_x` it meets. Then along the path the price moves by `ṗ = -∂H/∂x`, and the value
`u(x(t), t)` grows at the rate `p ∂H/∂p - H`. -/
theorem characteristics_are_hamiltons_equations {H u : ℝ × ℝ → ℝ}
    (hH : ContDiff ℝ 1 H) (hu : ContDiff ℝ 2 u)
    (hHJ : ∀ z : ℝ × ℝ, fderiv ℝ u z (0, 1) + H (fderiv ℝ u z (1, 0), z.1) = 0)
    {X : ℝ → ℝ}
    (hX : ∀ s : ℝ, HasDerivAt X (fderiv ℝ H (fderiv ℝ u (X s, s) (1, 0), X s) (1, 0)) s)
    (s : ℝ) :
    HasDerivAt (fun r => fderiv ℝ u (X r, r) (1, 0))
        (-fderiv ℝ H (fderiv ℝ u (X s, s) (1, 0), X s) (0, 1)) s ∧
      HasDerivAt (fun r => u (X r, r))
        (fderiv ℝ u (X s, s) (1, 0) * fderiv ℝ H (fderiv ℝ u (X s, s) (1, 0), X s) (1, 0)
          - H (fderiv ℝ u (X s, s) (1, 0), X s)) s := by
  have hdec : ∀ a b : ℝ, ((a, b) : ℝ × ℝ) = a • ((1, 0) : ℝ × ℝ) + b • ((0, 1) : ℝ × ℝ) := by
    intro a b; ext <;> simp
  have hud : Differentiable ℝ u := hu.differentiable (by norm_num)
  have hDu : Differentiable ℝ (fderiv ℝ u) :=
    (hu.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  have hHd : Differentiable ℝ H := hH.differentiable (by norm_num)
  set z : ℝ × ℝ := (X s, s) with hz
  set p := fderiv ℝ u z (1, 0) with hp
  set D2 := fderiv ℝ (fderiv ℝ u) z with hD2
  set DH := fderiv ℝ H (p, X s) with hDH
  -- derivative of z ↦ u_x z
  have hP : ∀ w : ℝ × ℝ, HasFDerivAt (fun w => fderiv ℝ u w (1, 0))
      ((ContinuousLinearMap.apply ℝ ℝ ((1, 0) : ℝ × ℝ)).comp (fderiv ℝ (fderiv ℝ u) w)) w := by
    intro w
    exact (ContinuousLinearMap.apply ℝ ℝ ((1, 0) : ℝ × ℝ)).hasFDerivAt.comp w (hDu w).hasFDerivAt
  have hQ : ∀ w : ℝ × ℝ, HasFDerivAt (fun w => fderiv ℝ u w (0, 1))
      ((ContinuousLinearMap.apply ℝ ℝ ((0, 1) : ℝ × ℝ)).comp (fderiv ℝ (fderiv ℝ u) w)) w := by
    intro w
    exact (ContinuousLinearMap.apply ℝ ℝ ((0, 1) : ℝ × ℝ)).hasFDerivAt.comp w (hDu w).hasFDerivAt
  -- differentiate the equation in x
  have hPhi : HasFDerivAt (fun w : ℝ × ℝ => fderiv ℝ u w (0, 1) + H (fderiv ℝ u w (1, 0), w.1))
      ((ContinuousLinearMap.apply ℝ ℝ ((0, 1) : ℝ × ℝ)).comp D2 +
        DH.comp (((ContinuousLinearMap.apply ℝ ℝ ((1, 0) : ℝ × ℝ)).comp D2).prod
          (ContinuousLinearMap.fst ℝ ℝ ℝ))) z := by
    refine (hQ z).add ?_
    have hin : HasFDerivAt (fun w : ℝ × ℝ => (fderiv ℝ u w (1, 0), w.1))
        (((ContinuousLinearMap.apply ℝ ℝ ((1, 0) : ℝ × ℝ)).comp D2).prod
          (ContinuousLinearMap.fst ℝ ℝ ℝ)) z :=
      (hP z).prodMk (hasFDerivAt_fst)
    exact (hHd (p, X s)).hasFDerivAt.comp z hin
  have hzero : HasFDerivAt (fun w : ℝ × ℝ => fderiv ℝ u w (0, 1) + H (fderiv ℝ u w (1, 0), w.1))
      (0 : ℝ × ℝ →L[ℝ] ℝ) z := by
    have : (fun w : ℝ × ℝ => fderiv ℝ u w (0, 1) + H (fderiv ℝ u w (1, 0), w.1)) = fun _ => 0 := by
      funext w; exact hHJ w
    rw [this]; exact hasFDerivAt_const _ _
  have hE := congrArg (fun L : ℝ × ℝ →L[ℝ] ℝ => L (1, 0)) (hPhi.unique hzero)
  simp only [add_apply, ContinuousLinearMap.comp_apply,
    ContinuousLinearMap.apply_apply, ContinuousLinearMap.prod_apply,
    ContinuousLinearMap.coe_fst', zero_apply] at hE
  rw [hdec (D2 (1, 0) (1, 0)) 1, map_add, map_smul, map_smul, smul_eq_mul, smul_eq_mul, one_mul] at hE
  have hsym : D2 (0, 1) (1, 0) = D2 (1, 0) (0, 1) :=
    (hu.contDiffAt.isSymmSndFDerivAt (by simp)) _ _
  -- the path
  have hpath : HasDerivAt (fun r : ℝ => ((X r, r) : ℝ × ℝ)) ((DH (1, 0), 1) : ℝ × ℝ) s :=
    (hX s).prodMk (hasDerivAt_id s)
  constructor
  · have h := (hP z).comp_hasDerivAt_of_eq s hpath rfl
    simp only [ContinuousLinearMap.comp_apply, ContinuousLinearMap.apply_apply] at h
    rw [hdec (DH (1, 0)) 1, map_add, map_smul, map_smul, one_smul] at h
    simp only [add_apply, smul_apply, smul_eq_mul] at h
    refine h.congr_deriv ?_
    rw [← hD2, hsym]
    linarith
  · have h := (hud z).hasFDerivAt.comp_hasDerivAt_of_eq s hpath rfl
    rw [hdec (DH (1, 0)) 1, map_add, map_smul, map_smul, one_smul, smul_eq_mul] at h
    refine h.congr_deriv ?_
    have := hHJ z
    simp only [hz] at this ⊢
    linarith

/-- The truck's least fuel over the hills is a classical solution. With drag coefficient
`k > 0` and speed-free fuel per km `b(x)`, whose total from km 0 is `B(x)` (so `B' = b`), the
cost per hour at speed `v ≥ 0` is `k v³ + b(x) v` and the Hamiltonian is
`H(p, x) = sup_{v ≥ 0} (p v - k v³ - b(x) v)`. Then `u(x, t) = k x³/t² + B(x)` solves
`u_t + H(u_x, x) = 0` at every `x > 0` and `t > 0`. -/
theorem hills_least_fuel_solves_hamilton_jacobi {k : ℝ} (hk : 0 < k) {B b : ℝ → ℝ}
    (hB : ∀ x, HasDerivAt B (b x) x) {x t : ℝ} (hx : 0 < x) (ht : 0 < t) :
    fderiv ℝ (fun z : ℝ × ℝ => k * z.1 ^ 3 / z.2 ^ 2 + B z.1) (x, t) (0, 1)
      + ⨆ v : Set.Ici (0 : ℝ),
          (fderiv ℝ (fun z : ℝ × ℝ => k * z.1 ^ 3 / z.2 ^ 2 + B z.1) (x, t) (1, 0) * v
            - (k * (v : ℝ) ^ 3 + b x * v)) = 0 := by
  set f := fun z : ℝ × ℝ => k * z.1 ^ 3 / z.2 ^ 2 + B z.1 with hf
  have hBd : Differentiable ℝ B := fun y => (hB y).differentiableAt
  have hdiff : DifferentiableAt ℝ f (x, t) := by
    have h1 : DifferentiableAt ℝ (fun z : ℝ × ℝ => k * z.1 ^ 3) (x, t) := by fun_prop
    have h2 : DifferentiableAt ℝ (fun z : ℝ × ℝ => z.2 ^ 2) (x, t) := by fun_prop
    have h3 : DifferentiableAt ℝ (fun z : ℝ × ℝ => B z.1) (x, t) := by fun_prop
    have hne : (fun z : ℝ × ℝ => z.2 ^ 2) (x, t) ≠ 0 := by simp; exact ht.ne'
    have h2' : DifferentiableAt ℝ (fun z : ℝ × ℝ => (z.2 ^ 2)⁻¹) (x, t) :=
      DifferentiableAt.fun_inv h2 hne
    have hfe : f = fun z : ℝ × ℝ => k * z.1 ^ 3 * (z.2 ^ 2)⁻¹ + B z.1 := by
      funext z; simp only [hf, div_eq_mul_inv]
    rw [hfe]
    exact (h1.fun_mul h2').fun_add h3
  -- slope in time
  have hq : fderiv ℝ f (x, t) (0, 1) = -2 * k * x ^ 3 / t ^ 3 := by
    have hpath : HasDerivAt (fun h : ℝ => ((x, t + h) : ℝ × ℝ)) ((0, 1) : ℝ × ℝ) 0 := by
      refine HasDerivAt.prodMk (hasDerivAt_const _ _) ?_
      simpa using HasDerivAt.const_add t (hasDerivAt_id (0:ℝ))
    have h1 := hdiff.hasFDerivAt.comp_hasDerivAt_of_eq (0:ℝ) hpath (by simp)
    have h2 : HasDerivAt (fun h : ℝ => f (x, t + h)) (-2 * k * x ^ 3 / t ^ 3) 0 := by
      simp only [hf]
      have hd : HasDerivAt (fun h : ℝ => (t + h) ^ 2) (2 * t) 0 := by
        have := HasDerivAt.pow (HasDerivAt.const_add t (hasDerivAt_id (0:ℝ))) 2
        convert this using 1
        · funext h; simp
        · simp
      have := HasDerivAt.add_const (B x)
        (HasDerivAt.fun_div (hasDerivAt_const (0:ℝ) (k * x ^ 3)) hd (by simp; exact ht.ne'))
      convert this using 1
      field_simp; ring
    exact h1.unique h2
  have hp : fderiv ℝ f (x, t) (1, 0) = 3 * k * x ^ 2 / t ^ 2 + b x := by
    have hpath : HasDerivAt (fun h : ℝ => ((x + h, t) : ℝ × ℝ)) ((1, 0) : ℝ × ℝ) 0 := by
      refine HasDerivAt.prodMk ?_ (hasDerivAt_const _ _)
      simpa using HasDerivAt.const_add x (hasDerivAt_id (0:ℝ))
    have h1 := hdiff.hasFDerivAt.comp_hasDerivAt_of_eq (0:ℝ) hpath (by simp)
    have h2 : HasDerivAt (fun h : ℝ => f (x + h, t)) (3 * k * x ^ 2 / t ^ 2 + b x) 0 := by
      simp only [hf]
      have hx1 : HasDerivAt (fun h : ℝ => x + h) 1 0 := by
        simpa using HasDerivAt.const_add x (hasDerivAt_id (0:ℝ))
      have hBc : HasDerivAt (fun h : ℝ => B (x + h)) (b x * 1) 0 := by
        have := HasDerivAt.comp (0:ℝ) (by simpa using hB x) hx1
        exact this
      have hp3 : HasDerivAt (fun h : ℝ => (x + h) ^ 3) (3 * x ^ 2) 0 := by
        have := HasDerivAt.pow hx1 3
        convert this using 1
        simp
      have := HasDerivAt.fun_add (HasDerivAt.div_const (HasDerivAt.const_mul k hp3) (t ^ 2)) hBc
      convert this using 1
      ring
    exact h1.unique h2
  rw [hq, hp]
  set a := x / t with ha
  have ha0 : 0 < a := div_pos hx ht
  have e2 : x ^ 2 / t ^ 2 = a ^ 2 := by rw [ha, div_pow]
  have e3 : x ^ 3 / t ^ 3 = a ^ 3 := by rw [ha, div_pow]
  have hP : 3 * k * x ^ 2 / t ^ 2 = 3 * k * a ^ 2 := by rw [mul_div_assoc, e2]
  have hQ : -2 * k * x ^ 3 / t ^ 3 = -(2 * k * a ^ 3) := by rw [mul_div_assoc, e3]; ring
  rw [hP, hQ]
  have hbound : ∀ v : Set.Ici (0 : ℝ),
      (3 * k * a ^ 2 + b x) * v - (k * (v : ℝ) ^ 3 + b x * v) ≤ 2 * k * a ^ 3 := by
    rintro ⟨v, hv⟩
    have hv' : (0:ℝ) ≤ v := hv
    simp only
    have := mul_nonneg (mul_nonneg hk.le (sq_nonneg (v - a))) (by linarith : (0:ℝ) ≤ v + 2 * a)
    nlinarith [this]
  have : Nonempty (Set.Ici (0:ℝ)) := ⟨⟨0, Set.mem_Ici.2 le_rfl⟩⟩
  have hS : (⨆ v : Set.Ici (0 : ℝ),
      ((3 * k * a ^ 2 + b x) * v - (k * (v : ℝ) ^ 3 + b x * v))) = 2 * k * a ^ 3 := by
    refine le_antisymm (ciSup_le hbound) ?_
    have := le_ciSup ⟨_, by rintro _ ⟨w, rfl⟩; exact hbound w⟩ (⟨a, ha0.le⟩ : Set.Ici (0:ℝ))
    refine le_trans (le_of_eq ?_) this
    simp only; ring
  rw [hS]; ring

-- Steady speed: 100 km in 5/4 h is 80 km/h.
example : (100 : ℚ) / (5 / 4) = 80 := by norm_num
-- Drag price 3 k v² with k = 1/40000: 3 × (1/40000) × 80² = 12/25 L/km (0.48).
example : 3 * (1 / 40000 : ℚ) * 80 ^ 2 = 12 / 25 := by norm_num
-- H at that price: (12/25) × 80 - (1/40000) × 80³ = 192/5 - 64/5 = 128/5 L/h (25.60).
example : (12 / 25 : ℚ) * 80 = 192 / 5 ∧ (1 / 40000 : ℚ) * 80 ^ 3 = 64 / 5 ∧
    (12 / 25 : ℚ) * 80 - (1 / 40000) * 80 ^ 3 = 128 / 5 := by norm_num
-- Least fuel: drag (1/40000) × 100³ / (5/4)² = 16, rolling (7/50) × 100 = 14,
-- climb (27/1000) × 40 = 27/25 (1.08); total 777/25 L (31.08).
example : (1 / 40000 : ℚ) * 100 ^ 3 / (5 / 4) ^ 2 = 16 ∧ (7 / 50 : ℚ) * 100 = 14 ∧
    (27 / 1000 : ℚ) * 40 = 27 / 25 ∧ (16 : ℚ) + 14 + 27 / 25 = 777 / 25 := by norm_num
-- u_t = -2 × (1/40000) × 100³ / (5/4)³ = -128/5 L/h (-25.60).
example : -2 * (1 / 40000 : ℚ) * 100 ^ 3 / (5 / 4) ^ 3 = -128 / 5 := by norm_num
-- A 1 h deadline: 25 + 14 + 27/25 L, which is 9 L more than at 5/4 h; at 3/2 h drag is 100/9 L.
example : ((1 / 40000 : ℚ) * 100 ^ 3 / 1 ^ 2 + 14 + 27 / 25) - 777 / 25 = 9 ∧
    (1 / 40000 : ℚ) * 100 ^ 3 / (3 / 2) ^ 2 = 100 / 9 := by norm_num
-- Hopf-Lax replan at 1/2 h from km 40: (1/40000) × 40³ / (1/4) = 32/5 so far,
-- (3/4) × (1/40000) × (60 / (3/4))³ = 48/5 to go, 16 L in all.
example : (1 / 40000 : ℚ) * 40 ^ 3 / (1 / 4) = 32 / 5 ∧
    (3 / 4 : ℚ) * ((1 / 40000) * (60 / (3 / 4)) ^ 3) = 48 / 5 ∧ (32 / 5 : ℚ) + 48 / 5 = 16 := by
  norm_num
-- Two depots at km 70: west 686/125 L (5.488), east 54/125 L (0.432); the minimum is the east one.
example : (1 / 40000 : ℚ) * 70 ^ 3 / (5 / 4) ^ 2 = 686 / 125 ∧
    (1 / 40000 : ℚ) * 30 ^ 3 / (5 / 4) ^ 2 = 54 / 125 ∧
    min ((686 : ℚ) / 125) (54 / 125) = 54 / 125 := by norm_num
-- The kink at km 50: value 2 L, slopes ±3/25 L/km (±0.120).
example : (1 / 40000 : ℚ) * 50 ^ 3 / (5 / 4) ^ 2 = 2 ∧
    3 * (1 / 40000 : ℚ) * 50 ^ 2 / (5 / 4) ^ 2 = 3 / 25 := by norm_num
-- Mistake 1, fuel per km taken as per hour: (5/4) × (1/40000) × 80² = 1/5 L (0.20).
example : (5 / 4 : ℚ) * (1 / 40000) * 80 ^ 2 = 1 / 5 := by norm_num

#print axioms hopf_lax_solves_hamilton_jacobi
#print axioms characteristics_are_hamiltons_equations
#print axioms hills_least_fuel_solves_hamilton_jacobi
