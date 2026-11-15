-- The Riemann problem: for Burgers' equation two constant states meeting at one point stay one jump moving at the average of their wave speeds when the left state's waves are faster, and open into the fan u = x/t, which solves the equation and is continuous, when the right state's waves are faster.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Topology.ContinuousOn
import Mathlib.Topology.Instances.Real.Lemmas

/-- The card's answer to the Riemann problem for Burgers' equation `u_t + (u^2/2)_x = 0`
with wave speed `uL` left of the point `x = 0` and `uR` right of it, at place `x` and
time `t`. If `uL > uR` it is one jump at the speed `(uL + uR)/2`; otherwise it is `uL`
up to the ray `x = uL t`, the fan `x/t` between the rays, and `uR` from the ray
`x = uR t` on. -/
noncomputable def riemannSol (uL uR x t : ℝ) : ℝ :=
  if uR < uL then (if x < (uL + uR) / 2 * t then uL else uR)
  else if x ≤ uL * t then uL
  else if uR * t ≤ x then uR
  else x / t

/-- Two constant states meeting at one point, under Burgers' equation
`u_t + (u^2/2)_x = 0` (written with the slices `s ↦ u (x, s)` and `y ↦ u (y, t)^2/2`).
The answer starts from the data: just after the start it equals `uL` at every place
left of the point and `uR` at every place right of it.
If the left state's waves are faster (`uL > uR`), the answer is one jump moving at the
average `s = (uL + uR)/2`: that speed is the Rankine–Hugoniot jump rule
`s = [u^2/2]/[u]`, the jump passes the entropy test `uL > s > uR`, and the equation holds
exactly everywhere off the jump line `x = s t`.
If the right state's waves are faster (`uL < uR`), the jump at that speed fails the
entropy test, and the answer is the fan instead: it equals `x/t` (wave speed equals
place divided by time) between the rays `x = uL t` and `x = uR t`, it is continuous for
`t > 0`, and the equation holds exactly everywhere off those two rays. -/
theorem riemann_problem_shock_or_fan (uL uR : ℝ) :
    (∀ x : ℝ, x < 0 → ∀ᶠ t in nhdsWithin (0 : ℝ) (Set.Ioi 0), riemannSol uL uR x t = uL) ∧
    (∀ x : ℝ, 0 < x → ∀ᶠ t in nhdsWithin (0 : ℝ) (Set.Ioi 0), riemannSol uL uR x t = uR) ∧
    (uR < uL →
      (uR ^ 2 / 2 - uL ^ 2 / 2) / (uR - uL) = (uL + uR) / 2 ∧
      uR < (uL + uR) / 2 ∧ (uL + uR) / 2 < uL ∧
      ∀ x t : ℝ, 0 < t → x ≠ (uL + uR) / 2 * t →
        deriv (fun s => riemannSol uL uR x s) t +
          deriv (fun y => riemannSol uL uR y t ^ 2 / 2) x = 0) ∧
    (uL < uR →
      ¬ (uR < (uL + uR) / 2 ∧ (uL + uR) / 2 < uL) ∧
      (∀ x t : ℝ, 0 < t → uL * t < x → x < uR * t → riemannSol uL uR x t = x / t) ∧
      ContinuousOn (fun p : ℝ × ℝ => riemannSol uL uR p.1 p.2) {p | 0 < p.2} ∧
      ∀ x t : ℝ, 0 < t → x ≠ uL * t → x ≠ uR * t →
        deriv (fun s => riemannSol uL uR x s) t +
          deriv (fun y => riemannSol uL uR y t ^ 2 / 2) x = 0) := by
  have ev_lt : ∀ (a b x0 : ℝ), a * x0 < b → ∀ᶠ s in nhds x0, a * s < b := by
    intro a b x0 h
    exact ((continuous_const.mul continuous_id).tendsto x0).eventually (gt_mem_nhds h)
  have ev_gt : ∀ (a b x0 : ℝ), b < a * x0 → ∀ᶠ s in nhds x0, b < a * s := by
    intro a b x0 h
    exact ((continuous_const.mul continuous_id).tendsto x0).eventually (lt_mem_nhds h)
  have ev0_gt : ∀ (a x : ℝ), x < 0 → ∀ᶠ t in nhdsWithin (0 : ℝ) (Set.Ioi 0), x < a * t := by
    intro a x hx
    apply nhdsWithin_le_nhds
    exact ev_gt a x 0 (by simpa using hx)
  have ev0_lt : ∀ (a x : ℝ), 0 < x → ∀ᶠ t in nhdsWithin (0 : ℝ) (Set.Ioi 0), a * t < x := by
    intro a x hx
    apply nhdsWithin_le_nhds
    exact ev_lt a x 0 (by simpa using hx)
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro x hx
    filter_upwards [ev0_gt ((uL + uR) / 2) x hx, ev0_gt uL x hx] with t h1 h2
    unfold riemannSol
    split_ifs <;> first | rfl | linarith
  · intro x hx
    filter_upwards [ev0_lt ((uL + uR) / 2) x hx, ev0_lt uL x hx, ev0_lt uR x hx] with t h1 h2 h3
    unfold riemannSol
    split_ifs <;> first | rfl | linarith
  · intro hLR
    refine ⟨?_, by linarith, by linarith, ?_⟩
    · have : uR - uL ≠ 0 := sub_ne_zero.mpr (ne_of_lt hLR)
      field_simp
      ring
    · intro x t ht hx
      rcases lt_or_gt_of_ne hx with hx | hx
      · have e1 : (fun s => riemannSol uL uR x s) =ᶠ[nhds t] fun _ => uL := by
          filter_upwards [ev_gt ((uL + uR) / 2) x t hx] with s hs
          simp [riemannSol, hLR, hs]
        have e2 : (fun y => riemannSol uL uR y t ^ 2 / 2) =ᶠ[nhds x] fun _ => uL ^ 2 / 2 := by
          filter_upwards [gt_mem_nhds hx] with y hy
          simp [riemannSol, hLR, hy]
        rw [e1.deriv_eq, e2.deriv_eq]
        simp
      · have e1 : (fun s => riemannSol uL uR x s) =ᶠ[nhds t] fun _ => uR := by
          filter_upwards [ev_lt ((uL + uR) / 2) x t hx] with s hs
          simp [riemannSol, hLR, not_lt.mpr hs.le]
        have e2 : (fun y => riemannSol uL uR y t ^ 2 / 2) =ᶠ[nhds x] fun _ => uR ^ 2 / 2 := by
          filter_upwards [lt_mem_nhds hx] with y hy
          simp [riemannSol, hLR, not_lt.mpr (le_of_lt hy)]
        rw [e1.deriv_eq, e2.deriv_eq]
        simp
  · intro hLR
    have hn : ¬ uR < uL := not_lt.mpr hLR.le
    refine ⟨fun h => by linarith [h.1, h.2], ?_, ?_, ?_⟩
    · intro x t ht h1 h2
      simp [riemannSol, hn, not_le.mpr h1, not_le.mpr h2]
    · have hg : ContinuousOn (fun p : ℝ × ℝ => max uL (min uR (p.1 / p.2))) {p | 0 < p.2} :=
        (continuous_const.max (continuous_const.min continuous_id)).comp_continuousOn
          (continuousOn_fst.div continuousOn_snd (fun p hp => ne_of_gt hp))
      refine hg.congr ?_
      intro p hp
      have hp' : (0 : ℝ) < p.2 := hp
      show riemannSol uL uR p.1 p.2 = max uL (min uR (p.1 / p.2))
      unfold riemannSol
      simp only [hn, ↓reduceIte]
      split_ifs with h1 h2
      · have : p.1 / p.2 ≤ uL := (div_le_iff₀ hp').mpr h1
        rw [min_eq_right (by linarith), max_eq_left this]
      · have : uR ≤ p.1 / p.2 := (le_div_iff₀ hp').mpr h2
        rw [min_eq_left this, max_eq_right hLR.le]
      · have a1 : uL < p.1 / p.2 := (lt_div_iff₀ hp').mpr (not_le.mp h1)
        have a2 : p.1 / p.2 < uR := (div_lt_iff₀ hp').mpr (not_le.mp h2)
        rw [min_eq_right a2.le, max_eq_right a1.le]
    · intro x t ht h1 h2
      have hLt : uL * t < uR * t := mul_lt_mul_of_pos_right hLR ht
      rcases lt_or_gt_of_ne h1 with h1 | h1
      · have e1 : (fun s => riemannSol uL uR x s) =ᶠ[nhds t] fun _ => uL := by
          filter_upwards [ev_gt uL x t h1] with s hs
          simp [riemannSol, hn, hs.le]
        have e2 : (fun y => riemannSol uL uR y t ^ 2 / 2) =ᶠ[nhds x] fun _ => uL ^ 2 / 2 := by
          filter_upwards [gt_mem_nhds h1] with y hy
          simp [riemannSol, hn, hy.le]
        rw [e1.deriv_eq, e2.deriv_eq]
        simp
      rcases lt_or_gt_of_ne h2 with h2 | h2
      · have e1 : (fun s => riemannSol uL uR x s) =ᶠ[nhds t] fun s => x / s := by
          filter_upwards [ev_lt uL x t h1, ev_gt uR x t h2] with s hs1 hs2
          simp [riemannSol, hn, not_le.mpr hs1, not_le.mpr hs2]
        have e2 : (fun y => riemannSol uL uR y t ^ 2 / 2) =ᶠ[nhds x]
            fun y => (y / t) ^ 2 / 2 := by
          filter_upwards [lt_mem_nhds h1,
            gt_mem_nhds h2] with y hy1 hy2
          simp [riemannSol, hn, not_le.mpr hy1, not_le.mpr hy2]
        have d1 : HasDerivAt (fun s => x / s) (-x / t ^ 2) t := by
          have := (hasDerivAt_inv ht.ne').const_mul x
          convert this using 1
          · ext s; simp [div_eq_mul_inv]
          · field_simp
        have d2 : HasDerivAt (fun y => (y / t) ^ 2 / 2) (x / t ^ 2) x := by
          have := (((hasDerivAt_id' x).div_const t).pow 2).div_const 2
          convert this using 1
          simp
          field_simp
        rw [e1.deriv_eq, e2.deriv_eq, d1.deriv, d2.deriv]
        ring
      · have e1 : (fun s => riemannSol uL uR x s) =ᶠ[nhds t] fun _ => uR := by
          filter_upwards [ev_lt uL x t (by linarith), ev_lt uR x t h2] with s hs1 hs2
          simp [riemannSol, hn, not_le.mpr hs1, hs2.le]
        have e2 : (fun y => riemannSol uL uR y t ^ 2 / 2) =ᶠ[nhds x] fun _ => uR ^ 2 / 2 := by
          filter_upwards [lt_mem_nhds (by linarith : uL * t < x),
            lt_mem_nhds h2] with y hy1 hy2
          simp [riemannSol, hn, not_le.mpr hy1, hy2.le]
        rw [e1.deriv_eq, e2.deriv_eq]
        simp

/-- Stretching place and time together reduces the equation to one variable: for an answer
of the form `u (x, t) = U (x/t)` with `U` differentiable, Burgers' equation
`u_t + u u_x = 0` holds at `(x, t)`, `t > 0`, exactly when `(U(ξ) - ξ) U'(ξ) = 0` at
`ξ = x/t`. So at each `ξ` either `U` is flat or `U(ξ) = ξ`, the fan. -/
theorem self_similar_burgers_iff (U : ℝ → ℝ) (hU : Differentiable ℝ U) (x t : ℝ)
    (ht : 0 < t) :
    deriv (fun s => U (x / s)) t + U (x / t) * deriv (fun y => U (y / t)) x = 0 ↔
      (U (x / t) - x / t) * deriv U (x / t) = 0 := by
  have ht' : t ≠ 0 := ht.ne'
  have h1 : deriv (fun s => U (x / s)) t = deriv U (x / t) * (-x / t ^ 2) := by
    have hd : HasDerivAt (fun s => x / s) (-x / t ^ 2) t := by
      have := (hasDerivAt_inv ht').const_mul x
      convert this using 1
      · ext s; simp [div_eq_mul_inv]
      · field_simp
    exact ((hU (x / t)).hasDerivAt.comp t hd).deriv
  have h2 : deriv (fun y => U (y / t)) x = deriv U (x / t) * (1 / t) := by
    have hd : HasDerivAt (fun y => y / t) (1 / t) x := (hasDerivAt_id x).div_const t
    exact ((hU (x / t)).hasDerivAt.comp x hd).deriv
  have key : deriv (fun s => U (x / s)) t + U (x / t) * deriv (fun y => U (y / t)) x =
      ((U (x / t) - x / t) * deriv U (x / t)) / t := by
    rw [h1, h2]
    field_simp
    ring
  rw [key, div_eq_zero_iff]
  simp [ht']

/-- Traffic is exactly Burgers' equation in the wave speed. With top speed `vmax > 0`, jam
density `ρmax > 0`, Greenshields' flow `q(ρ) = vmax ρ (1 - ρ/ρmax)` and wave speed
`u(ρ) = q'(ρ) = vmax (1 - 2ρ/ρmax)`: the flow is `ρmax/(4 vmax) (vmax^2 - u^2)`, so
`u_t + (u^2/2)_x = 0` follows from `ρ_t + q(ρ)_x = 0`; the traffic jump rule
`(q(ρR) - q(ρL))/(ρR - ρL)` equals the Burgers shock speed `(uL + uR)/2`; and a car's own
speed `vmax (1 - ρ/ρmax)` is `(vmax + u)/2`. -/
theorem traffic_is_burgers_in_wave_speed (vmax ρmax : ℝ) (hv : 0 < vmax) (hρ : 0 < ρmax) :
    let q : ℝ → ℝ := fun ρ => vmax * ρ * (1 - ρ / ρmax)
    let u : ℝ → ℝ := fun ρ => vmax * (1 - 2 * ρ / ρmax)
    (∀ ρ : ℝ, q ρ = ρmax / (4 * vmax) * (vmax ^ 2 - u ρ ^ 2)) ∧
    (∀ ρ : ℝ, HasDerivAt q (u ρ) ρ) ∧
    (∀ ρL ρR : ℝ, ρL ≠ ρR → (q ρR - q ρL) / (ρR - ρL) = (u ρL + u ρR) / 2) ∧
    (∀ ρ : ℝ, vmax * (1 - ρ / ρmax) = (vmax + u ρ) / 2) := by
  intro q u
  have hv' : vmax ≠ 0 := hv.ne'
  have hρ' : ρmax ≠ 0 := hρ.ne'
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro ρ
    simp only [q, u]
    field_simp
    ring
  · intro ρ
    have := ((hasDerivAt_id' ρ).const_mul vmax).mul
      (HasDerivAt.const_sub 1 ((hasDerivAt_id' ρ).div_const ρmax))
    convert this using 1
    · simp only [u]
      simp
      field_simp
      ring
  · intro ρL ρR h
    have hne : ρR - ρL ≠ 0 := sub_ne_zero.mpr (Ne.symm h)
    simp only [q, u]
    rw [div_eq_iff hne]
    field_simp
    ring
  · intro ρ
    simp only [u]
    field_simp
    ring

-- Green light, km/h and cars/km: queue 150 cars/km behind, empty road ahead.
example : (90 : ℚ) * (1 - 2 * 150 / 150) = -90 := by norm_num
example : (90 : ℚ) * (1 - 2 * 0 / 150) = 90 := by norm_num
-- at the light: wave speed 0, density 75 cars/km, car speed 45 km/h, flow 3,375 cars/h
example : riemannSol (-90) 90 0 1 = 0 := by norm_num [riemannSol]
example : (1 / 2 : ℚ) * 150 * (1 - 0 / 90) = 75 ∧ (1 / 2 : ℚ) * (90 + 0) = 45 ∧
    (75 : ℚ) * 45 = 3375 := by norm_num
-- 56.25 cars clear the light in the first minute
example : (3375 : ℚ) / 60 = 225 / 4 := by norm_num
-- fan edges at ±25 m/s after 10 s, and the density 112.5 cars/km at -500 m after 40 s
example : (-25 : ℚ) * 10 = -250 ∧ (25 : ℚ) * 10 = 250 := by norm_num
example : (1 / 2 : ℚ) * 150 * (1 - (-500) / (25 * 40)) = 225 / 2 := by norm_num
-- the car 100 m back starts at 4 s, crosses at 16 s, behind 15 cars that pass in 16 s
example : (100 : ℚ) / 25 = 4 ∧ 4 * (100 : ℚ) / 25 = 16 ∧ (100 : ℚ) * 150 / 1000 = 15 ∧
    (3375 : ℚ) * 16 / 3600 = 15 := by norm_num
-- Red light: 30 cars/km arrive at a 150 cars/km queue; wave speeds 54 and -90 km/h,
-- shock at -18 km/h by both jump rules, 300 m back after 60 s
example : (90 : ℚ) * (1 - 2 * 30 / 150) = 54 ∧ ((54 : ℚ) + -90) / 2 = -18 := by norm_num
example : ((90 : ℚ) * 150 * (1 - 150 / 150) - 90 * 30 * (1 - 30 / 150)) / (150 - 30) = -18 := by
  norm_num
example : (-18 : ℚ) * 1000 / 3600 * 60 = -300 := by norm_num
-- what breaks: the green-light jump kept moves at 0 km/h; the average car speed gives
-- +36 km/h; conserving u^2/2 (wave speeds 15 and -25 m/s) gives -95/3 m/s = -114 km/h
example : ((90 : ℚ) * 150 * (1 - 150 / 150) - 90 * 0 * (1 - 0 / 150)) / 150 = 0 := by norm_num
example : ((90 : ℚ) * (1 - 30 / 150) + 0) / 2 = 36 := by norm_num
example : (2 / 3 : ℚ) * (15 ^ 2 + 15 * (-25) + (-25) ^ 2) / (15 + -25) = -95 / 3 ∧
    (-95 / 3 : ℚ) * 18 / 5 = -114 := by norm_num
-- the red-light fan drawn wrongly: edges 15 and -25 m/s overlap by 400 m after 10 s
example : ((15 : ℚ) - (-25)) * 10 = 400 := by norm_num

#print axioms riemann_problem_shock_or_fan
#print axioms self_similar_burgers_iff
#print axioms traffic_is_burgers_in_wave_speed
