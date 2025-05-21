/*
================================================================================
STRATEGIC LENDING ACQUISITION ANALYSIS REPORT
================================================================================
Purpose:
    - Evaluate target micro-lender's portfolio health and growth potential.
    - Identify key risks and opportunities for acquisition.
	This analysis will support informed decision-making on whether acquiring this lending business aligns with
	our company’s goal of expanding financial inclusion while ensuring sustainable growth.

Highlights:
    1. Loan Product Segmentation:
        - Loan amounts, tenures, interest rates, and repayment frequencies.
    2. Portfolio Performance Metrics:
        - Disbursement trends, repayment rates, default rates.
    3. Risk Exposure:
        - Portfolio at Risk (PAR) by aging buckets.
    4. Forecasting:
        - 3-month profit/loss projections.
    5. Actionable Triggers:
        - Alerts for adverse portfolio shifts.

Objectives :
      1. Document key features of the lending product.

      2.Visualize performance insights using BI tools.

      3.Track KPIs with time-series trends.

      4.Forecast 3-month P&L for financial planning.

      5. Assess credit exposure and risk strategies.

      6. Set provisioning/write-off thresholds based on risk.

      7. Implement portfolio triggers for early risk alerts.

      8. Optimize product design for profitability and risk control.
*/

--  =============================================================================
-- Import & Initial Inspection
-- ===============================================================================
-- Import database containing two tables * Disbursements and Repayments tables* 
-- used Import Flatfiles to Database  method  to import tables

-- Check tables structure
SELECT TOP 10 * FROM Disbursements;
SELECT TOP 10 * FROM Repayments;

-- Check column data types
SELECT *, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Disbursements';

SELECT *, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Repayments';

-- Check summary stats (for numeric columns)
SELECT 
    COUNT(*) AS TotalRows,
    AVG(loan_amount) AS AvgValue,
    MIN(loan_fee) AS MinValue,
    MAX(loan_amount) AS MaxValue,
    STDEV(loan_amount) AS StdDev
FROM Disbursements;

SELECT 
    COUNT(*) AS TotalRows,
    AVG(amount) AS AvgValue,
    MIN(amount) AS MinValue,
    MAX(amount) AS MaxValue,
    STDEV(amount) AS StdDev
FROM Repayments;


-- ============================================================================
-- SECTION 1: DATA CLEANING & PREPARATION
-- ============================================================================

--Step 1: Clean Disbursements Table
-- =============================================================================
---a.Check for Missing Values

SELECT 
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN disb_date IS NULL THEN 1 ELSE 0 END) AS missing_disb_date,
    SUM(CASE WHEN tenure IS NULL THEN 1 ELSE 0 END) AS missing_tenure,
    SUM(CASE WHEN account_num IS NULL THEN 1 ELSE 0 END) AS missing_account_num,
    SUM(CASE WHEN loan_amount IS NULL THEN 1 ELSE 0 END) AS missing_loan_amount,
    SUM(CASE WHEN loan_fee IS NULL THEN 1 ELSE 0 END) AS missing_loan_fee,
    COUNT(*) AS total_records
FROM Disbursements;

-- Check for duplicate records

WITH DuplicateFinder AS (
    SELECT *,
           COUNT(*) OVER (
               PARTITION BY customer_id, disb_date, account_num, loan_amount, loan_fee, tenure
           ) AS duplicate_count
    FROM Disbursements
)
SELECT *
FROM DuplicateFinder
WHERE duplicate_count > 1
ORDER BY customer_id, disb_date;

-- Delete duplicates using ROW_NUMBER()

WITH DuplicateCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id, disb_date, account_num, loan_amount, loan_fee, tenure
               ORDER BY (SELECT NULL) -- or use a unique column if available and since it is a loan data we don't have a unique value
           ) AS row_num
    FROM Disbursements
)
DELETE FROM DuplicateCTE
WHERE row_num > 1;

-- Trim leading/trailing spaces from a string column(customer_id)

UPDATE Disbursements
SET customer_id = LTRIM(RTRIM(customer_id));


-- Converting loan_amount column to currency data type
UPDATE Disbursements
SET loan_amount = TRY_CONVERT(MONEY, loan_amount)
WHERE TRY_CONVERT(MONEY, loan_amount) IS NOT NULL;


-- ======================================================================
-- creating cleaned disbursements table called(Clean_Disbursements)
-- =======================================================================
SELECT 
    customer_id,
    TRIM(account_num) AS account_num,
    TRY_CAST(disb_date AS DATE) AS disb_date,
    CAST(loan_amount AS MONEY) AS loan_amount,
    CAST(loan_fee AS FLOAT) AS loan_fee,
    TRY_CAST(LEFT(tenure, PATINDEX('%[^0-9]%', tenure + '0') - 1) AS INT) AS tenure_days
INTO Clean_Disbursements
FROM Disbursements
WHERE TRY_CAST(disb_date AS DATE) IS NOT NULL;
-- updating loan_fee to 2 decimal places
UPDATE Clean_Disbursements
SET loan_fee = ROUND(loan_fee, 2);

-- to inspect the cleaned disbursement table
  SELECT * FROM Clean_Disbursements;

-- then drop the disbursements table to remain with clean_Disbursements table

--Step 2:Clean  Repayments  Table
-- ====================================================================================================

---a.Check for Missing Values

SELECT 
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN date_time IS NULL THEN 1 ELSE 0 END) AS missing_date_time,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS missing_amount,
    SUM(CASE WHEN rep_month IS NULL THEN 1 ELSE 0 END) AS missing_rep_month,
    SUM(CASE WHEN repayment_type IS NULL THEN 1 ELSE 0 END) AS missing_repayment_type,
    COUNT(*) AS total_records
FROM Repayments;

-- Check for duplicate records

 WITH DuplicateFinder AS (
    SELECT *,
           COUNT(*) OVER (
               PARTITION BY date_time, customer_id, amount, rep_month, repayment_type
           ) AS duplicate_count
    FROM Repayments
)
SELECT *
FROM DuplicateFinder
WHERE duplicate_count > 1
ORDER BY customer_id, date_time;

--  Delete duplicates using ROW_NUMBER()

WITH DuplicateCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id, date_time, amount, rep_month, repayment_type
               ORDER BY (SELECT NULL) -- or use a unique column if available and since it is a loan data we don't have a unique value
           ) AS row_num
    FROM Repayments
)
DELETE FROM DuplicateCTE
WHERE row_num > 1;

-- Trim leading/trailing spaces from a string column(customer_id)

UPDATE Repayments
SET customer_id = LTRIM(RTRIM(customer_id));

-- data type
SELECT *, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Repayments';

-- Formating string(date_time)to date
-- First, replace the dot (.) with colon (:) to match SQL datetime format
SELECT 
    TRY_CAST(
        REPLACE(LEFT(date_time, 20), '.', ':') + RIGHT(date_time, 3) 
        AS DATETIME
    ) AS converted_datetime
FROM Repayments;

-- Get only the date part
SELECT 
    CAST(
        TRY_CAST(
            REPLACE(LEFT(date_time, 20), '.', ':') + RIGHT(date_time, 3) 
            AS DATETIME
        ) AS DATE
    ) AS repayment_date
FROM Repayments;

-- =====================================================================================
-- creating cleaned  Repayments table called(Clean_Repayments)
-- ======================================================================================

-- Create Clean_Repayments table with formatted rep_month
SELECT 
    customer_id,
    
    -- Convert date_time to proper DATE 
    CAST(
        TRY_CAST(
            REPLACE(LEFT(date_time, 20), '.', ':') + RIGHT(date_time, 3)
            AS DATETIME
        ) AS DATE
    ) AS repayment_date,

    amount,

    -- Normalize rep_month to 'YYYY-MM-01' format
    CAST(
        FORMAT(CAST(rep_month AS DATE), 'yyyy-MM-01') AS DATE
    ) AS rep_month,

    repayment_type

INTO Clean_Repayments
FROM Repayments
WHERE 
    TRY_CAST(REPLACE(LEFT(date_time, 20), '.', ':') + RIGHT(date_time, 3) AS DATETIME) IS NOT NULL
    AND TRY_CAST(rep_month AS DATE) IS NOT NULL;

-- updating the year to 2024

UPDATE Clean_Repayments
SET rep_month = DATEFROMPARTS(2024, MONTH(rep_month), 1);

-- Update amount to 2 Decimal Places
UPDATE Clean_Repayments
SET amount = ROUND(amount, 2);

-- to inspect the cleaned Repayments table
SELECT * FROM Clean_Repayments;

-- then DROP the Repayments table to remain with Clean_Repayment table

-- =============================================================================
-- ✅ To Create a Final Combined Table
-- =============================================================================

SELECT 
  d.customer_id,
  d.account_num,
  d.disb_date,
  d.loan_amount,
  d.loan_fee,
  d.tenure_days,
  r.amount AS repayment_amount,
  r.repayment_date,
  r.rep_month,
  r.repayment_type
INTO Final_Loan_Records
FROM Clean_Disbursements d
LEFT JOIN Clean_Repayments r
  ON d.customer_id = r.customer_id;
  
  SELECT* FROM Final_Loan_Records;

    -- =============================================================================
-- 🧠 Now to Address the Case Study Objectives:
-- =============================================================================

  -- =============================================================================
-- SECTION 1: LENDING PRODUCT OVERVIEW
-- =============================================================================
-- Objective: Profile loan product features and target market.
 
--1.Key Features of the Lending Product

--Loan size distribution (min, avg, max)
SELECT 
    MIN(loan_amount) AS Min_Loan,
    AVG(loan_amount) AS Avg_Loan,
    MAX(loan_amount) AS Max_Loan
FROM Final_Loan_Records;


--Tenure patterns (e.g., how many days: 7, 14, etc.)
SELECT tenure_days, COUNT(*) AS frequency
FROM Final_Loan_Records
GROUP BY tenure_days
ORDER BY tenure_days;


--Frequency of disbursements per customer
SELECT customer_id, COUNT(*) AS num_loans
FROM Final_Loan_Records
GROUP BY customer_id
ORDER BY num_loans DESC;


--Fees vs. loan amounts
SELECT loan_amount, loan_fee, (loan_fee * 100/ loan_amount) AS fee_ratio
 FROM Final_Loan_Records;



/*
📌 Findings:
-- 1. The average loan size is KES 1110.5794, with most loans being small-ticket.
   This suggests the product is positioned for micro-borrowers..
-- 2. 3 tenure options: 7, 14 and 30 days.Most loans are short-term (7–14 days), 
   indicating a cash-flow smoothing product rather than long-term credit.
-- 3. High-frequency repeat borrowers exist. This highlights retention, but also raises questions about over-reliance and credit risk.
-- 4. Fees are relatively high (averaging 10-15%), suggesting strong revenue potential—but might affect repayment behavior.
*/

-- =============================================================================
-- SECTION 2:📊 BI Visualizations (Power BI)
-- =============================================================================
-- ✅ Prepare and aggregate the data using SQL
-- Using Power BI , build:

-- 1.Line Chart: Monthly disbursements & repayments


SELECT 
    loan_amount AS Total_Disbursed, 
    repayment_amount  AS Total_Repaid, 
    rep_month 
FROM Final_Loan_Records;


/*In Power BI:
Load this query result.

Use a line chart:

X-axis → rep_Month

Y-axis → both Total_Disbursed and Total_Repaid as separate lines.

Add Data Labels for better insight*/
-- ✅ Finding:

/*Disbursements are growing steadily, but repayments lag slightly behind,
particularly in between March and May—indicating rising delinquencies.

--✅Actionable Insights
1.Investigate Recent Months (Jun–Aug 2024):

--Why are repayments slowing? (e.g., macroeconomic factors, weaker underwriting?).

2.Adjust Lending Strategy:

--Tighten credit standards if delinquencies rise.

--Offer repayment incentives or restructuring for overdue loans.

3.Monitor Seasonality:

--Compare to historical trends—is this a temporary dip or a worsening trend?

--✅Rising Delinquencies (March-April 2025)
--The specific mention of between month of March and May  implies that more borrowers are missing payments.

--Possible reasons:

1.Economic downturn (e.g., job losses, inflation reducing borrowers’ repayment capacity).

2.Overextension of credit (lending to riskier borrowers).

3. Seasonal factors (e.g., post-holiday financial strain).*/

-- 2.Bar Chart: Default rate by loan size buckets (e.g., <1K, 1K-2K)

WITH Buckets AS (
    SELECT *,
        CASE 
            WHEN loan_amount < 1000 THEN '<1K'
            WHEN loan_amount BETWEEN 1000 AND 2000 THEN '1K-2K'
            ELSE '>2K'
        END AS Loan_Bucket,
        CASE 
            WHEN loan_amount < 1000 AND DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) > 7 THEN 1
            WHEN loan_amount BETWEEN 1000 AND 2000 AND DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) > 14 THEN 1
            WHEN loan_amount > 2000 AND DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) > 30 THEN 1
            ELSE 0
        END AS Is_Default
    FROM Final_Loan_Records
)
SELECT 
    Loan_Bucket,
    COUNT(*) AS Total_Loans,
    SUM(Is_Default) AS Defaulted_Loans,
    CAST(SUM(Is_Default) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Default_Rate
FROM Buckets
GROUP BY Loan_Bucket;

/*Tiered Repayment Periods:

--Loans < $1,000 must be repaid within 7 days

--Loans between 1,000−2,000 must be repaid within 14 days

--Loans > $2,000 must be repaid within 30 days
--Purpose
This query helps analyze how loan default rates vary by loan size, which can inform risk assessment and lending strategies. 
The results will show whether smaller or larger loans tend to have higher default rates.*/

/*🟢 Use in Power BI as a bar chart with:

X-axis: Loan_Bucket

Y-axis: Default_Rate */

/*✅ Insights :

1.Higher Defaults in Smaller Loans (<1K & 1K-2K):

--Loans under $2K show significantly higher default rates (potentially 30–50%, based on the graph scale).

Possible Reasons:

--Borrowers of small loans may be higher-risk (e.g., subprime, emergency use).

--Smaller loans might be perceived as "low priority" for repayment.

--Administrative costs of collections could outweigh the loan value, reducing recovery efforts.

2.Lower Defaults in Larger Loans (>2K):

--Loans above $2K default less frequently (likely below 10–20%).

Why?

--Borrowers may be more creditworthy (e.g., stricter underwriting for larger amounts).

--Larger loans often have collateral or longer terms, incentivizing repayment.

 ✅Recommendations
1. For High-Default Buckets (<1K, 1K-2K):
--Tighten Underwriting:

-Add stricter income/credit checks for small loans.

-Require proof of repayment capacity (e.g., bank statements).

--Behavioral Nudges:

-Automated reminders or penalties for late payments.

-Offer discounts for early repayment.



2. --For Low-Default Buckets (>2K):
Scale Responsibly:

--Expand lending in this segment cautiously—defaults are low, but larger losses per loan could hurt profitability.

--Maintain strong collateral requirements.

3. Portfolio-Level Actions:
Risk-Based Pricing:

-Charge higher interest rates for small loans to offset default risk.*/

-- 3.Donut Chart: Customer segmentation by loan tenure

SELECT 
    tenure_days,
    COUNT(DISTINCT customer_id) AS Customer_Count
FROM Final_Loan_Records
GROUP BY tenure_days;

/*🟢 Use in Power BI as a donut chart with:

Legend: tenure_days

Values: Customer_Count */

/* ✅Key Observation:

30-day loans dominate, representing nearly half of all loans. This suggests borrowers prefer longer repayment periods, 
possibly due to cash flow flexibility.

Short-term loans (7- and 14-day) are less common but still significant (~47% combined). These may cater to urgent needs (e.g., payday loans).*/

--4.Combo Chart: Fee revenue vs. repayments

SELECT 
    FORMAT(disb_date, 'yyyy-MM') AS Month,
    SUM(loan_fee) AS Total_Fee_Revenue,
    SUM(repayment_amount) AS Total_Repaid
FROM Final_Loan_Records
GROUP BY FORMAT(disb_date, 'yyyy-MM')
ORDER BY Month;

/*
📌
The graph compares fee revenue (income from loan fees) and repayments (principal + interest returned) over time (Jan–Aug 2024).

Trend Alignment: If fee revenue and repayments move together, it suggests fees are tied to loan activity .
*/

-- =============================================================================
-- SECTION 📈 3. KPIs & Time-Series Trends
-- =============================================================================
/*Key Performance Metrics Defined:
1. Volume Metrics
-- loan_count: Number of loans disbursed

-- disbursed_amount: Total value of loans issued

-- repaid_amount: Total principal repaid

2. Revenue Metrics
-- fee_revenue: Total fees collected

-- fee_yield: Fees as percentage of loan volume

3. Risk Metrics
-- default_count: Number of defaulted loans

-- default_rate: Percentage of loans defaulted

-- on_time_repayment_rate: Percentage repaid within terms

4. Efficiency Metrics
-- avg_repayment_days: Average time to repayment

-- repayment_ratio: Repaid amount vs disbursed amount

5. Liquidity Metrics
-- net_outflow: Cash flow position (disbursed - repaid) */

WITH LoanMetrics AS (
    SELECT 
        FORMAT(disb_date, 'yyyy-MM') AS month,
        loan_amount,
        repayment_amount,
        loan_fee,
        disb_date,
        repayment_date,
        CASE 
            WHEN loan_amount < 1000 THEN '<1K'
            WHEN loan_amount BETWEEN 1000 AND 2000 THEN '1K-2K'
            ELSE '>2K'
        END AS loan_bucket,
        CASE 
            WHEN loan_amount < 1000 AND DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) > 7 THEN 1
            WHEN loan_amount BETWEEN 1000 AND 2000 AND DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) > 14 THEN 1
            WHEN loan_amount > 2000 AND DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) > 30 THEN 1
            ELSE 0
        END AS is_default,
        DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) AS days_to_repay
    FROM Final_Loan_Records
),

MonthlyKPIs AS (
    SELECT
        month,
        -- Volume Metrics
        COUNT(*) AS loan_count,
        SUM(loan_amount) AS disbursed_amount,
        SUM(repayment_amount) AS repaid_amount,
        
        -- Revenue Metrics
        SUM(loan_fee) AS fee_revenue,
        SUM(loan_fee) * 100.0 / NULLIF(SUM(loan_amount), 0) AS fee_yield,
        
        -- Risk Metrics
        SUM(is_default) AS default_count,
        SUM(is_default) * 100.0 / COUNT(*) AS default_rate,
        
        -- Efficiency Metrics
        AVG(days_to_repay) AS avg_repayment_days,
        SUM(CASE WHEN days_to_repay <= 
            CASE 
                WHEN loan_amount < 1000 THEN 7
                WHEN loan_amount BETWEEN 1000 AND 2000 THEN 14
                ELSE 30
            END THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS on_time_repayment_rate
    FROM LoanMetrics
    GROUP BY month
)

SELECT 
    month,
    loan_count,
    disbursed_amount,
    repaid_amount,
    fee_revenue,
    fee_yield,
    default_count,
    default_rate,
    avg_repayment_days,
    on_time_repayment_rate,
    -- Liquidity Metrics
    disbursed_amount - repaid_amount AS net_outflow,
    repaid_amount * 100.0 / NULLIF(disbursed_amount, 0) AS repayment_ratio
FROM MonthlyKPIs
ORDER BY month;

/*LOAD QUERY TO Power BI FOR Visualization OF TIME SERIES*/

/*
📌 Findings:

*/
-- =============================================================================
-- SECTION 📉 4. 3-Month Forecast (Python)
-- =============================================================================
---Use libraries like pandas, statsmodels, or prophet:

---Forecast repayment cashflows
SELECT 
    CAST(repayment_date AS DATE) AS rep_date,
    SUM(repayment_amount) AS total_repaid
FROM Final_Loan_Records
WHERE repayment_date IS NOT NULL
GROUP BY CAST(repayment_date AS DATE)
ORDER BY rep_date;

SELECT
   customer_id,
   rep_month,
   loan_amount,
   repayment_amount
FROM Final_Loan_Records;
--Forecast disbursement growth
SELECT 
    CAST(disb_date AS DATE) AS disb_date,
    SUM(loan_amount) AS total_disbursed
FROM Final_Loan_Records
WHERE disb_date IS NOT NULL
GROUP BY CAST(disb_date AS DATE)
ORDER BY disb_date;

-- 🐍 final Step: Load CSVs & Forecast in Python and Calculate Projected Profit/Loss

-- =============================================================================
-- SECTION 💰 5. Credit Exposure & Risk
-- =============================================================================
---Analyze:

--Outstanding balances = loan_amount - repayment_amount (aggregated)
SELECT 
    SUM(loan_amount - repayment_amount) AS total_outstanding_balance,
    COUNT(DISTINCT customer_id) AS active_customers
FROM Final_Loan_Records
WHERE repayment_amount < loan_amount;
/*Purpose: Measures the total amount at risk if borrowers default.
Risk Indicator: A high outstanding balance relative to the company's capital indicates higher exposure.*/

SELECT 
    customer_id,
    loan_amount,
    disb_date,
    repayment_date,
    DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) AS Days_Overdue,

    CASE 
        WHEN loan_amount < 1000 AND DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) > 7 THEN 1
        WHEN loan_amount BETWEEN 1000 AND 2000 AND DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) > 14 THEN 1
        WHEN loan_amount > 2000 AND DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) > 30 THEN 1
        ELSE 0
    END AS is_default,

    CASE 
        WHEN loan_amount < 1000 AND DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) > 7 THEN 'Defaulted: Small Loan > 7 days'
        WHEN loan_amount BETWEEN 1000 AND 2000 AND DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) > 14 THEN 'Defaulted: Medium Loan > 14 days'
        WHEN loan_amount > 2000 AND DATEDIFF(DAY, disb_date, ISNULL(repayment_date, GETDATE())) > 30 THEN 'Defaulted: Large Loan > 30 days'
        ELSE 'Not in Default'
    END AS default_status,

    CASE
        WHEN loan_amount < 1000 THEN '<1K'
        WHEN loan_amount BETWEEN 1000 AND 2000 THEN '1K-2K'
        ELSE '>2K'
    END AS loan_bucket

FROM Final_Loan_Records;


	
-- =============================================================================
-- SECTION ⚠️ 6. Provisioning & Write-Offs
-- =============================================================================






--Provision 50% after 7 days late, 100% after 14

--Write-off anything unpaid after 30 days

-- =============================================================================
-- SECTION 🚨 7. Triggers / Alerts
-- =============================================================================
--- 🔔 1. Repayment Behavior Triggers
/*
| Trigger/Alert             | Threshold                                 | Action                                                       |
|---------------------------|-------------------------------------------|--------------------------------------------------------------|
| 📉 Repayment Rate Drop     | >20% drop month-over-month                | Send alert to Credit Risk Team for investigation             |
| 🕒 Late Repayments Spike   | >15% of loans overdue >7 days             | Trigger soft reminder SMS/email to borrowers                 |
| 🔁 Repeat Late Payers      | Customers late >2 times in 3 months       | Flag for tighter credit control or adjusted limits           |


-- 📊 2. Disbursement/Loan Growth Triggers

| Trigger/Alert                     | Threshold                                           | Action                                                    |
|----------------------------------|-----------------------------------------------------|-----------------------------------------------------------|
| 🚀 Sudden Disbursement Spike      | >30% month-over-month increase                      | Validate source: marketing campaign vs. fraud            |
| ⚠️ Loan Concentration Alert       | >25% of loan volume from top 5% of borrowers         | Flag for review to avoid concentration risk              |
| 💸 Loan Amount Increase by Tier   | >20% rise in average loan size in any customer tier | Reassess borrower affordability model                    |

*/
-- =============================================================================
-- SECTION 4: RECOMMENDATIONS
-- =============================================================================

-- =============================================================================
-- SECTION 🧪 8. Product Design Recommendations
-- =============================================================================
/*
Based on findings:

Adjust tenure or amount caps

Introduce penalties for late payment

Reward early repayments

Build customer credit score model
*/
-- =============================================================================
-- SECTION 9: Deliverables Checklist:
-- =============================================================================
--✅ SQL cleaning scripts

--✅ Final SQL merged table

--✅ Power BI Dashboard (.pbix)

--✅ Python Jupyter Notebook for forecasting

--✅ Word or PDF report with:

--Methodology

--Key findings

--Business recommendations

-- =============================================================================
-- FOOTER: REPORT METADATA
-- =============================================================================
/*
Report generated on: 2025-05-20
Author: Emmanuel Ouma
Data source: Target lender database (2023-2024)
Tools used: SQL Server, Power BI, Python (Prophet)
*/ 