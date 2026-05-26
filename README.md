# Mistline

**Studio:** RidgeFall  
**Engine:** Unity 6.4 (URP)  
**Genre:** Simcade Driving / Jank-Sim / Life Sim  

## The Pitch
Mistline is a first-person indie game set in the Serra Gaúcha (Southern Brazil). Think *My Summer Car* meets *Initial D*, but you are making artisanal wine to fund your underground drift addiction.

The game is built on a sharp contrast: 
- **Daytime:** Slow-paced, rural work. Driving a beat-up utility truck, tending to the vineyard, making wine, and doing local freight runs to pay the bills.
- **Nighttime:** Taking your unfinished, RWD project car to the foggy mountain passes for underground car meets and drift runs.

## Development Approach
Developed as a solo project focusing on maintainable architecture. No overengineering, no ECS/DOTS. Just clean, modular C# scripts. 
- **Input:** 100% reliant on Unity's modern Input System (`Input Actions`).
- **Physics:** Simcade philosophy. Heavy focus on weight transfer and suspension tuning rather than hardcore mechanical simulation. Accessible but skill-based.
- **Interaction:** Tactile "jank-sim" style. No magical global inventory. You carry one car part or wine box at a time.

---

## Detailed Roadmap

### Phase 1: Player Foundation [Done]
- [x] FPS Movement (Walk/Sprint/Crouch)
- [x] First-Person Camera constraints
- [x] `IInteractable` Raycast system
- [x] Modern Input System binding

### Phase 2: Vehicle Foundation [WIP]
- [ ] Enter/Exit vehicle logic & camera switching
- [ ] `WheelCollider` base implementation
- [ ] Drivetrain logic (RWD motor torque, braking, steering)
- [ ] Center of Mass overrides (preventing arcade flips)

### Phase 3: Drift & Handling
- [ ] Forward/Sideways friction curve tuning (Grip vs. Slip)
- [ ] Handbrake logic and rear-wheel lockup
- [ ] Suspension & weight transfer tweaking (Forza-like baseline)
- [ ] Input smoothing for Keyboard/Gamepad/Wheel

### Phase 4: Atmosphere & Audio
- [ ] URP Post-Processing (Serrana cold lighting)
- [ ] Dense volumetric fog and rain systems
- [ ] Dynamic physics (wet roads = less grip)
- [ ] High-fidelity engine, turbo flutter, and tire screeching audio
- [ ] In-game radio with custom MP3 folder support

### Phase 5: Economy & Routine
- [ ] Freight loop (load truck -> deliver -> get paid)
- [ ] Artisanal wine production loop (harvest -> process -> bottle -> sell)
- [ ] Physical object carrying system (parts, boxes)
- [ ] Parts Shop (buying local used parts vs. importing online)
- [ ] In-game phone/messaging system for night event invites

### Phase 6: World & Progression
- [ ] Map blockout (Vineyard, Town, Mountain Pass)
- [ ] Underground reputation system
- [ ] Occasional police presence (event interruption)
- [ ] Basic vehicle wear and visual damage
