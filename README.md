SLA Tracking and Automation System

Overview

This project is an end-to-end data automation and business intelligence solution designed to track supplier delivery performances, detect Service Level Agreement (SLA) violations, and automatically calculate penalties based on dynamic supplier contracts.

The system transitions from manual tracking to a reliable, automated Batch Processing architecture, minimizing human error and providing actionable insights for supply chain management.

Project Architecture

The system consists of three integrated layers:

Data Layer (Microsoft SQL Server)

A fully relational database structure maintaining Suppliers, Orders, SLA Criteria, and Violation logs.

Utilizes a consolidated SQL View (vw_SLA_YoneticiRaporu) optimized specifically for rapid BI reporting.

Automation Engine (C# / .NET)

A console application engineered to run as a scheduled batch job (e.g., nightly routines).

Automatically scans for recently completed deliveries that have not yet been evaluated (SLA_HesaplandiMi = 0).

Evaluates expected vs. actual delivery dates, applies supplier-specific tolerance hours, and calculates precise financial penalties dynamically.

Flags processed orders to ensure idempotency and prevent redundant calculations.

Visualization Layer (Power BI)

Connects directly to the SQL Server View.

Transforms raw execution data into an interactive, high-level management dashboard.

Key Metrics displayed: Overall SLA Success Rate, Total Financial Penalties by Supplier, and Average Delay Durations.

Technologies Used

Backend / Business Logic: C# (.NET)

Database Management: Microsoft SQL Server (T-SQL, Relational Design, Views)

Business Intelligence: Microsoft Power BI

How to Run the Project

Database Setup: Execute the provided Database_Setup.sql script in SQL Server Management Studio (SSMS) to construct the database schema, insert dummy data, and create the reporting View.

Bot Execution: Open the C# project in Visual Studio. Update the connection string in Program.cs to match your local SQL Server instance name. Run the application to process the raw delivery data and calculate penalties.

Dashboard Reporting: Open the .pbix file in Power BI Desktop and click "Refresh" to load the processed data from the database into the interactive dashboard.
