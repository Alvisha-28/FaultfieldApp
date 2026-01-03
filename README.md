# FaultfieldApp
MATLAB App Designer–based simulator for modeling electric field, potential, and current flow in soil due to underground cable ground faults.
📌 Overview

FaultEFieldApp is an interactive MATLAB App Designer–based tool developed to simulate and visualize the electric field and electric potential distribution around an underground cable fault.
The application helps in understanding how fault current spreads through soil and how electric field intensity varies with distance, soil properties, and fault parameters.

This project bridges basic field theory concepts with practical power engineering applications, making it suitable for students, educators, and researchers.

🎯 Motivation

Underground cable faults inject large currents into the surrounding soil, creating dangerous voltage gradients that can lead to step and touch voltage hazards.
However, these effects are often difficult to visualize using equations alone.

This project was developed to:

Convert abstract field-theory equations into clear visual plots

Help students understand current spreading and electric field behavior

Provide an interactive learning tool for grounding and fault analysis

🧠 Core Concept

When a ground fault occurs:

Fault current flows from the cable into the soil

Soil, being resistive, causes voltage to drop with distance

This voltage gradient produces an electric field

The electric field is strongest near the fault and weakens with distance

The app models this behavior using quasi-static field theory assumptions and standard grounding equations.

🧮 Theoretical Basis

The simulation is based on:

Ohm’s law for fault current estimation

Current spreading in homogeneous soil

Relationship between electric field and potential

Key relationships used:

Electric field decreases inversely with distance from the fault

Electric potential varies logarithmically with distance

Field direction follows the voltage gradient

These assumptions are commonly used in grounding and earthing studies.

📊 Features

Interactive GUI built using MATLAB App Designer

User-controlled parameters:

Cable length, depth, and radius

Fault location and resistance

Applied voltage

Soil resistivity

Multiple visualization modes:

Electric field magnitude contour plot

Electric field vector (direction) plot

3D electric field surface

Field variation along cable axis

Electric potential contour plot

Touch / drag mode to interactively move the fault location

Option to save simulation data for further analysis

🛠️ How It Works

User inputs physical and electrical parameters

A 2D grid around the fault location is generated

Fault current is calculated using applied voltage and fault resistance

Electric field and potential are computed at each grid point

Results are visualized using contour, vector, and surface plots

🎓 Applications

Understanding underground cable fault behavior

Learning electric field and potential distribution in soil

Grounding system analysis

Step and touch voltage studies

Educational demonstrations of field theory concepts

📦 Requirements

MATLAB (R2020b or later recommended)

App Designer (included with MATLAB)

🚀 How to Run

Clone or download the repository

Open MATLAB

Run:

app = FaultEFieldApp;


Adjust parameters and click Run Simulation
