# Unbalanced Fault Analysis – Simulink Simulation

## 1. Overview

This Simulink model is used to simulate and analyse three types of unbalanced faults in a two-bus power system:

1. **AG Fault** – Single Line-to-Ground Fault (Phase A to Ground)
2. **BC Fault** – Line-to-Line Fault (Phase B to Phase C)
3. **BCG Fault** – Double Line-to-Ground Fault (Phases B and C to Ground)

Each fault is simulated separately by changing the parameters of the **Three-Phase Fault** block.

The simulation outputs are saved using To Workspace blocks and are later used in MATLAB to compare theoretical and simulated fault currents.

---

## 2. Simulation Configuration

Before running the simulation, ensure the following settings are maintained:

| Parameter | Value |
|---|---|
| Simulation type | Discrete |
| Sample time | 1e-5 s |
| Source frequency | 50 Hz |
| Source voltage | 11 kV |
| Fault resistance (Ron) | 0.01 Ω |
| Ground resistance (Rg) | 0.01 Ω |
| Switching times | [0.1 0.3] s |
| Initial status | 0 |

The fault occurs at 0.1 seconds and is cleared at 0.3 seconds.

## 3. Configuring the Three-Phase Fault Block

Double-click the **Three-Phase Fault** block to open its Block Parameters window.

Under the *Fault between* section, select or deselect the required phases and Ground according to the fault being simulated.

### A. AG Fault (Phase A to Ground)

Select:
- Phase A
- Ground

Deselect:
- Phase B
- Phase C

Set the To Workspace block variable name to:

`If_AG`

Run the simulation and save the resulting SimulationOutput object in MATLAB:

```matlab
outAG = out;
```

### B. BC Fault (Phase B to Phase C)

Select:
- Phase B
- Phase C

Deselect:
- Phase A
- Ground

Set the To Workspace block variable name to:

`If_BC`

Run the simulation and save the resulting SimulationOutput object:

```matlab
outBC = out;
```

### C. BCG Fault (Phases B and C to Ground)

Select:
- Phase B
- Phase C
- Ground

Deselect:
- Phase A

Set the To Workspace block variable name to:

`If_BCG`

Run the simulation and save the resulting SimulationOutput object:

```matlab
outBCG = out;
```

## 4. To Workspace Block Configuration

After configuring the fault, rename the To Workspace block's **Variable name** according to the fault being simulated.

| Fault type | Variable name |
|---|---|
| AG | If_AG |
| BC | If_BC |
| BCG | If_BCG |

Make sure the variable names match exactly, including uppercase and lowercase letters.

The output should be stored in the SimulationOutput object named `out`.

For example, after the BC simulation, the output can be accessed as:

```matlab
outBC.get('If_BC')
```

Use the same procedure for AG and BCG simulations.

## 5. Running the Simulations

Perform the following steps for each fault:

1. Open the Simulink model.
2. Double-click the Three-Phase Fault block.
3. Configure the phase and Ground selections for the required fault.
4. Rename the To Workspace block variable.
5. Click **Apply** and **OK**.
6. Run the simulation.
7. After completion, save the output object using the corresponding MATLAB command:

   - AG: `outAG = out;`
   - BC: `outBC = out;`
   - BCG: `outBCG = out;`

8. Repeat the procedure for the remaining faults.

**Important:** Save each simulation output before running the next fault, since the variable `out` will be overwritten by the next simulation.

## 6. Running the MATLAB Analysis Script

Once all three simulations are completed and their outputs are saved, run the MATLAB analysis script.

The script uses:

- `outAG` to extract AG fault currents.
- `outBC` to extract BC fault currents.
- `outBCG` to extract BCG fault currents.

It calculates:

- Theoretical fault currents using symmetrical components.
- Simulated RMS fault currents.
- Simulated peak fault currents.
- Absolute error between theoretical and simulated values.
- Percentage error.

It also generates plots for individual fault currents and theoretical-versus-simulated comparisons.

## 7. Generated Results

After successful execution, the MATLAB script generates the following files:

| File | Description |
|---|---|
| `Unbalanced_Fault_Complete_Results.mat` | Stores simulation data, theoretical results and system parameters. |
| `Unbalanced_Fault_Comparison.csv` | Contains the comparison of theoretical and simulated RMS fault currents. |

The script also generates the following plots:

1. AG Fault Current
2. BC Fault Current
3. BCG Fault Current
4. Theoretical vs Simulation Fault Current
5. Percentage Error

---

## 8. Important Notes

- Run each fault simulation separately.
- Ensure that the correct phases and Ground are selected.
- Do not change the fault switching times or resistance values unless required.
- Save each simulation output as `outAG`, `outBC` and `outBCG` before proceeding to the next simulation.
- Ensure that the To Workspace variable names match those expected by the MATLAB analysis script.
- Run the MATLAB analysis script only after completing all three simulations.
