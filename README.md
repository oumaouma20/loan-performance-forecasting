# 📊 Strategic Lending Acquisition Analysis

## 🧠 Context

Our company seeks to expand its footprint in the unbanked and under-banked sectors by acquiring a strategic lending business. To assess the viability and profitability of this move, we analyzed historical data on **loan disbursements** and **repayments** from the target company.

This case study aims to provide data-driven recommendations by evaluating profitability, risk exposure, and performance trends of the lending product.

---

## 🎯 Objectives

- Identify and document the key features of the lending product.
- Use Power BI to create insightful dashboards from disbursement and repayment data.
- Analyze profit/loss trends over time.
- Build a 3-month profit/loss forecast.
- Assess credit exposure and risk.
- Recommend appropriate provisioning and write-off thresholds.
- Suggest early warning portfolio triggers.
- Propose product feature improvements backed by data.

---

## 🛠️ Tools Used

- **Microsoft Excel** – Data cleaning and transformation.
- **Power BI** – Dashboards and time-series visualizations.
- **Python (Pandas, Statsmodels)** – Profit/loss forecasting.
- **Jupyter Notebook** – Forecasting scripts and insights.

---

## 🗂️ Steps I Took

1. **Data Cleaning**  
   - Loaded disbursement and repayment CSV files in Python.
   - Converted `date` columns to `datetime` format.
   - Checked for null values and data integrity.

2. **Data Aggregation**  
   - Grouped disbursements and repayments by month.
   - Merged both datasets on `month` to analyze cash flow.

3. **Profit/Loss Calculation**  
   - Computed monthly `Profit/Loss = repaid_amount - disbursed_amount`.

4. **Forecasting**  
   - Used ARIMA model to predict the next 3 months of profit/loss.
   - Forecast values indicate continued negative trends.

5. **Insights Extraction**  
   - Created visuals and identified persistent losses.
   - Pinpointed irregular repayment patterns and cash flow issues.

6. **Recommendations**  
   - Suggested operational, product, and forecasting model improvements.

---

## 📈 Forecast Summary (3-Month Outlook)

| Month      | Forecasted Profit/Loss |
|------------|------------------------|
| 2024-09-01 | KES 883,211            |
| 2024-10-01 | KES 1,459,193          |
| 2024-11-01 | KES 1,668,654          |

---

## 💡 Key Insights

### Historical Trend (Jan 2024 - Aug 2024)
- All recorded monthly profit/loss values were negative.
- No significant upward trend — possible seasonal fluctuations.
- July 2024 showed NaN values due to incomplete data.

### 3-Month Forecast (Sep–Nov 2024)
- Forecast suggests recovery signs, but previous losses could offset gains.
- The business is still at risk of underperformance without strategic action.

### Risk Factors
- High operational costs and low repayment efficiency.
- No clear evidence of positive corrective measures so far.

---

## ✅ Recommendations

1. **Investigate Causes of Losses**
   - Break down costs to identify key expense drivers.
   - Evaluate underperforming loan segments or borrower categories.

2. **Refine Forecasting Approach**
   - Consider tools like Prophet or XGBoost for seasonality and external factor handling.
   - Incorporate customer behavior and macroeconomic indicators.

3. **Scenario Analysis**
   - Simulate cost reduction or increased repayments.
   - Use sensitivity and Monte Carlo simulations for risk forecasting.

4. **Cost & Revenue Strategies**
   - Reduce non-essential spending.
   - Improve collection efforts and offer repayment incentives.

5. **Data Enhancement**
   - Collect more granular data (e.g., weekly transactions).
   - Add customer segmentation, loan tenure, default reasons, etc.

---

## 📌 Conclusion

The Strategic Lending Acquisition case study reveals consistent monthly losses, limited recovery indicators, and significant repayment challenges. While short-term forecasts hint at potential improvements, the business requires **urgent strategic reforms** in cost management, customer targeting, and data-driven decision-making to achieve long-term sustainability.

---

## 📂 Project Deliverables

- ✔️ Excel cleaning files
- ✔️ Python forecasting notebook
- ✔️ Power BI dashboard
- ✔️ Forecast and insights documentation
- ✔️ Business recommendations summary

---

